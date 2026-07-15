const crypto = require("crypto");
const bcrypt = require("bcryptjs");
const admin = require("firebase-admin");
const {HttpsError, onCall} = require("firebase-functions/v2/https");

admin.initializeApp();

const db = admin.firestore();
const allowedRoles = new Set(["viewer", "editor", "admin"]);
const manageableRoles = new Set(["admin", "superAdmin"]);

exports.authenticateWithAccessCode = onCall(async (request) => {
  const familyId = normalizeFamilyId(request.data && request.data.familyId);
  const accessCode = String((request.data && request.data.accessCode) || "");
  const deviceId = String((request.data && request.data.deviceId) || "");
  const appVersion = safeString(request.data && request.data.appVersion);

  if (!familyId || !accessCode.trim()) {
    throw publicAuthError();
  }

  const deviceHash = hashValue(deviceId || request.rawRequest.ip || "unknown");
  const config = await findMatchingAccessCodeConfig(familyId, accessCode);
  if (!config) {
    await auditAccessCode({
      familyId,
      action: "authenticationFailure",
      role: "",
      success: false,
      deviceFingerprintHash: deviceHash,
      appVersion,
    });
    throw publicAuthError();
  }

  const {id: accessCodeId, data} = config;
  if (!allowedRoles.has(data.role)) {
    throw new HttpsError("failed-precondition", "Configuration de rôle invalide.");
  }

  const uid = stableTechnicalUid(familyId, data.role, accessCodeId, deviceHash);
  await ensureFirebaseUser(uid, familyId, data.role);
  await upsertUserRole({
    uid,
    role: data.role,
    familyId,
    accessCodeId,
    authMethod: "accessCode",
    deviceFingerprintHash: deviceHash,
  });

  const customToken = await admin.auth().createCustomToken(uid, {
    familyId,
    role: data.role,
    authMethod: "accessCode",
  });

  await auditAccessCode({
    familyId,
    action: "authenticationSuccess",
    role: data.role,
    performedBy: uid,
    success: true,
    deviceFingerprintHash: deviceHash,
    appVersion,
  });

  return {
    customToken,
    role: data.role,
    familyId,
    expiresAt: data.expiresAt ? data.expiresAt.toDate().toISOString() : null,
  };
});

exports.updateFamilyAccessCode = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Connexion Firebase requise.");
  }
  const familyId = normalizeFamilyId(request.data && request.data.familyId);
  const codeId = safeString(request.data && request.data.codeId);
  const newCode = String((request.data && request.data.newCode) || "");
  const revokeExistingSessions =
    Boolean(request.data && request.data.revokeExistingSessions);

  if (!familyId || !codeId || !isStrongAccessCode(newCode)) {
    throw new HttpsError("invalid-argument", "Code invalide.");
  }

  const actorRole = await getActiveRole(auth.uid, familyId);
  if (!manageableRoles.has(actorRole)) {
    throw new HttpsError("permission-denied", "Droits insuffisants.");
  }

  const doc = db.collection("access_code_configs").doc(codeId);
  const snapshot = await doc.get();
  if (!snapshot.exists || snapshot.get("familyId") !== familyId) {
    throw new HttpsError("not-found", "Configuration introuvable.");
  }

  const codeHash = await bcrypt.hash(newCode, 12);
  await doc.set(
    {
      codeHash,
      active: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedBy: auth.uid,
    },
    {merge: true},
  );

  if (revokeExistingSessions) {
    await revokeSessionsForCode(codeId);
  }

  await auditAccessCode({
    familyId,
    action: revokeExistingSessions ? "sessionsRevoked" : "codeUpdated",
    role: snapshot.get("role") || "",
    performedBy: auth.uid,
    success: true,
  });

  return {success: true};
});

async function findMatchingAccessCodeConfig(familyId, accessCode) {
  const snapshot = await db
    .collection("access_code_configs")
    .where("familyId", "==", familyId)
    .where("active", "==", true)
    .get();
  const now = admin.firestore.Timestamp.now();
  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (data.expiresAt && data.expiresAt.toMillis() <= now.toMillis()) {
      continue;
    }
    if (!data.codeHash || typeof data.codeHash !== "string") {
      continue;
    }
    const matches = await bcrypt.compare(accessCode, data.codeHash);
    if (matches) {
      return {id: doc.id, data};
    }
  }
  return null;
}

async function getActiveRole(uid, familyId) {
  const snapshot = await db.collection("user_roles").doc(uid).get();
  const data = snapshot.data();
  if (!data || data.active !== true) {
    throw new HttpsError("permission-denied", "Utilisateur inactif.");
  }
  const familyIds = Array.isArray(data.familyIds) ? data.familyIds : [];
  if (!familyIds.includes(familyId)) {
    throw new HttpsError("permission-denied", "Famille non autorisée.");
  }
  return data.role;
}

async function ensureFirebaseUser(uid, familyId, role) {
  try {
    await admin.auth().getUser(uid);
  } catch (error) {
    if (error.code !== "auth/user-not-found") {
      throw error;
    }
    await admin.auth().createUser({
      uid,
      displayName: `${familyId} ${role}`,
      disabled: false,
    });
  }
}

async function upsertUserRole({
  uid,
  role,
  familyId,
  accessCodeId,
  authMethod,
  deviceFingerprintHash,
}) {
  await db.collection("user_roles").doc(uid).set(
    {
      role,
      familyIds: [familyId],
      active: true,
      authMethod,
      accessCodeId,
      deviceFingerprintHash,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastAuthenticatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}

async function revokeSessionsForCode(accessCodeId) {
  const snapshot = await db
    .collection("user_roles")
    .where("accessCodeId", "==", accessCodeId)
    .get();
  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.set(
      doc.ref,
      {
        active: false,
        revokedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
  });
  await batch.commit();
}

async function auditAccessCode({
  familyId,
  action,
  role,
  performedBy = "",
  success,
  deviceFingerprintHash = "",
  appVersion = "",
}) {
  await db.collection("access_code_audit_logs").add({
    familyId,
    action,
    role,
    performedBy,
    success,
    deviceFingerprintHash,
    appVersion,
    occurredAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function normalizeFamilyId(value) {
  const normalized = safeString(value).trim().toLowerCase();
  return normalized === "family-ayivon" ? "ayivon" : normalized;
}

function safeString(value) {
  return typeof value === "string" ? value : "";
}

function stableTechnicalUid(familyId, role, codeId, deviceHash) {
  const digest = hashValue(`${familyId}:${role}:${codeId}:${deviceHash}`).slice(
    0,
    40,
  );
  return `family_${familyId}_${role}_${digest}`;
}

function hashValue(value) {
  return crypto.createHash("sha256").update(String(value)).digest("hex");
}

function isStrongAccessCode(value) {
  return typeof value === "string" && value.trim().length >= 8;
}

function publicAuthError() {
  return new HttpsError(
    "permission-denied",
    "Code incorrect ou accès temporairement bloqué.",
  );
}
