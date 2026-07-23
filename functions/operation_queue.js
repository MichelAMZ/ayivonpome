"use strict";

const crypto = require("crypto");
const admin = require("firebase-admin");
const {
  FieldValue,
  Timestamp,
  getFirestore,
} = require("firebase-admin/firestore");
const {HttpsError} = require("firebase-functions/v2/https");

const db = getFirestore();
const MAX_PAYLOAD_BYTES = 64 * 1024;
const MAX_ATTEMPTS = 8;
const LOCK_TTL_MS = 5 * 60 * 1000;
const MAX_PARENT_DEPTH = 500;
const MAX_GRAPH_DOCUMENTS = 1000;
const TERMINAL = new Set(["completed", "rejected", "conflict", "failed"]);
const TYPES = new Set([
  "member.create",
  "member.update",
  "member.softDelete",
  "relationship.create",
  "relationship.update",
  "relationship.delete",
  "familyTreeLink.create",
  "familyTreeLink.update",
  "familyTreeLink.delete",
]);
const MEMBER_PUBLIC_FIELDS = new Set([
  "id", "familyId", "firstName", "lastName", "gender", "fatherId", "motherId",
  "spouseIds", "birthYear", "birthCity", "isDeceased", "isPatriarch",
  "photoUrl", "displayOrder", "childrenIds", "parents", "spouses", "children",
  "generation", "deletedAt", "schemaVersion",
]);
const MEMBER_PRIVATE_FIELDS = new Set([
  "memberId", "familyId", "ownerUid", "fullBirthDate", "email", "phone",
  "fullAddress", "privateNotes", "visibilitySettings", "schemaVersion",
  "birthLastName", "originalLastName", "birthPlace", "birthCountry",
  "deathDate", "deathPlace", "burialPlace", "publicMapLocation",
  "currentAddress", "currentCity", "currentRegion", "currentCountry",
  "latitude", "longitude", "importantPlaces", "whatsapp", "allowContact",
  "emailVisibility", "phoneVisibility", "whatsappVisibility", "originFamilyId",
  "linkedTreeEnabled", "familyCode", "marriageType", "history",
  "isTemporaryProfile", "profileNeedsCompletion",
]);
const RELATIONSHIP_FIELDS = new Set([
  "id", "familyId", "type", "sourceId", "targetId", "personId", "relatedPersonId",
  "spouseId", "partner1Id", "partner2Id", "marriageType", "status",
  "marriageDate", "traditionalMarriageDate", "civilMarriageDate",
  "religiousMarriageDate", "divorceDate", "marriagePlace", "marriageCountry",
  "startDate", "endDate", "active", "notes", "order", "deletedAt",
  "schemaVersion",
]);
const FAMILY_LINK_FIELDS = new Set([
  "id", "familyId", "fromPersonId", "toPersonId", "relationshipType",
  "linkedFamilyCode", "status", "notes", "deletedAt", "schemaVersion",
]);

function canonicalize(value) {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value && typeof value === "object") {
    return Object.keys(value).sort().reduce((result, key) => {
      result[key] = canonicalize(value[key]);
      return result;
    }, {});
  }
  return value;
}

function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function safeId(value, label) {
  const text = String(value || "").trim();
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(text)) {
    throw new HttpsError("invalid-argument", `${label} invalide.`);
  }
  return text;
}

function assertPlainObject(value, label) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new HttpsError("invalid-argument", `${label} invalide.`);
  }
}

function assertAllowedFields(value, allowed, label) {
  assertPlainObject(value, label);
  for (const key of Object.keys(value)) {
    if (!allowed.has(key)) {
      throw new HttpsError("invalid-argument", `Champ ${label}.${key} interdit.`);
    }
  }
}

function validatePayload(type, payload) {
  assertPlainObject(payload, "payload");
  if ("role" in payload || "createdBy" in payload || "status" in payload) {
    throw new HttpsError("invalid-argument", "Champ serveur interdit.");
  }
  const bytes = Buffer.byteLength(JSON.stringify(payload), "utf8");
  if (bytes > MAX_PAYLOAD_BYTES) {
    throw new HttpsError("invalid-argument", "Payload trop volumineux.");
  }
  if (type.startsWith("member.")) {
    const allowedSections = new Set(["public", "private", "relationships", "links"]);
    assertAllowedFields(payload, allowedSections, "payload");
    if (payload.public) assertAllowedFields(payload.public, MEMBER_PUBLIC_FIELDS, "public");
    if (payload.private) assertAllowedFields(payload.private, MEMBER_PRIVATE_FIELDS, "private");
    if (payload.relationships && !Array.isArray(payload.relationships)) {
      throw new HttpsError("invalid-argument", "relationships invalide.");
    }
    if (payload.links && !Array.isArray(payload.links)) {
      throw new HttpsError("invalid-argument", "links invalide.");
    }
    for (const relation of payload.relationships || []) {
      assertAllowedFields(relation, RELATIONSHIP_FIELDS, "relationship");
    }
    for (const link of payload.links || []) {
      assertAllowedFields(link, FAMILY_LINK_FIELDS, "link");
    }
  } else {
    assertAllowedFields(
        payload,
        type.startsWith("familyTreeLink.") ? FAMILY_LINK_FIELDS : RELATIONSHIP_FIELDS,
        "payload",
    );
  }
}

function assertNoParentCycle(relations, parentId, childId, {
  maxDepth = MAX_PARENT_DEPTH,
  maxDocuments = MAX_GRAPH_DOCUMENTS,
} = {}) {
  if (parentId === childId) {
    throw permanentError("genealogy-cycle", "Cycle parental direct.");
  }
  if (relations.length > maxDocuments) {
    throw permanentError("genealogy-check-limit", "Graphe parental trop volumineux.");
  }
  const childrenByParent = new Map();
  for (const relation of relations) {
    if (relation.isDeleted === true || relation.active === false ||
        relation.type !== "parentChild") continue;
    const parent = relation.sourceId || relation.parentId;
    const child = relation.targetId || relation.childId;
    if (!parent || !child) continue;
    childrenByParent.set(parent, [...(childrenByParent.get(parent) || []), child]);
  }
  const queue = [{id: childId, depth: 0}];
  const visited = new Set();
  while (queue.length) {
    const {id, depth} = queue.shift();
    if (id === parentId) {
      throw permanentError("genealogy-cycle", "Cycle parental indirect.");
    }
    if (depth >= maxDepth) {
      throw permanentError("genealogy-check-limit", "Profondeur parentale maximale atteinte.");
    }
    if (visited.has(id)) continue;
    visited.add(id);
    for (const child of childrenByParent.get(id) || []) {
      queue.push({id: child, depth: depth + 1});
    }
  }
}

async function requireRole(uid, familyId) {
  const snapshot = await db.collection("user_roles").doc(uid).get();
  const role = snapshot.data();
  if (!snapshot.exists || role.active !== true) {
    throw new HttpsError("permission-denied", "Rôle actif requis.");
  }
  const familyIds = Array.isArray(role.familyIds) ? role.familyIds : [];
  if (role.role !== "superAdmin" && !familyIds.includes(familyId)) {
    throw new HttpsError("permission-denied", "Famille non autorisée.");
  }
  if (!["admin", "superAdmin"].includes(role.role)) {
    throw new HttpsError("permission-denied", "Rôle administrateur requis.");
  }
  return role;
}

async function submitFamilyOperation(request) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
  const data = request.data || {};
  const familyId = safeId(data.familyId, "familyId");
  const localOperationId = safeId(data.localOperationId, "localOperationId");
  const resourceId = safeId(data.resourceId, "resourceId");
  const idempotencyKey = String(data.idempotencyKey || "");
  if (idempotencyKey.length < 8 || idempotencyKey.length > 256) {
    throw new HttpsError("invalid-argument", "Clé d’idempotence invalide.");
  }
  const type = String(data.type || "");
  if (!TYPES.has(type)) throw new HttpsError("invalid-argument", "Type inconnu.");
  const baseVersion = Number(data.baseVersion ?? 0);
  if (!Number.isInteger(baseVersion) || baseVersion < 0) {
    throw new HttpsError("invalid-argument", "baseVersion invalide.");
  }
  const schemaVersion = Number(data.schemaVersion || 1);
  if (schemaVersion !== 1) {
    throw new HttpsError("failed-precondition", "Schéma non pris en charge.");
  }
  validatePayload(type, data.payload);
  await requireRole(request.auth.uid, familyId);

  const canonical = JSON.stringify(canonicalize({
    familyId, type, resourceId, baseVersion, payload: data.payload, schemaVersion,
  }));
  const payloadHash = sha256(canonical);
  const idempotencyHash = sha256(`${request.auth.uid}:${idempotencyKey}`);
  const resourceType = type.split(".")[0];
  const resourceKey = `${familyId}:${resourceType}:${resourceId}`;
  const resourceHash = sha256(resourceKey);
  const idempotencyRef = db.collection("operation_idempotency").doc(idempotencyHash);
  const stateRef = db.collection("operation_resource_state").doc(resourceHash);
  const operationRef = db.collection("operation_queue").doc();
  const payloadRef = db.collection("operation_payloads").doc(operationRef.id);

  return db.runTransaction(async (transaction) => {
    const existing = await transaction.get(idempotencyRef);
    if (existing.exists) {
      const stored = existing.data();
      if (stored.payloadHash !== payloadHash) {
        throw new HttpsError("already-exists", "Clé réutilisée avec un autre contenu.");
      }
      const operation = await transaction.get(
          db.collection("operation_queue").doc(stored.operationId),
      );
      const op = operation.data() || {};
      return {
        operationId: stored.operationId,
        status: op.status || "pending",
        duplicate: true,
        resourceSequence: op.resourceSequence || 0,
      };
    }
    const state = await transaction.get(stateRef);
    const sequence = state.exists ? Number(state.data().nextSequenceToAssign || 1) : 1;
    const now = FieldValue.serverTimestamp();
    transaction.set(stateRef, {
      resourceKey,
      nextSequenceToAssign: sequence + 1,
      nextSequenceToProcess: state.exists ?
        Number(state.data().nextSequenceToProcess || 1) : 1,
      currentVersion: state.exists ? Number(state.data().currentVersion || 0) : 0,
      activeOperationId: state.exists ? state.data().activeOperationId || null : null,
      updatedAt: now,
    }, {merge: true});
    transaction.create(operationRef, {
      operationId: operationRef.id,
      localOperationId,
      familyId,
      type,
      resourceType,
      resourceId,
      resourceKey,
      resourceStateId: resourceHash,
      resourceSequence: sequence,
      baseVersion,
      status: "pending",
      createdBy: request.auth.uid,
      createdAt: now,
      updatedAt: now,
      attemptCount: 0,
      nextAttemptAt: null,
      lockedAt: null,
      lockedBy: null,
      lastErrorCode: null,
      lastErrorMessage: null,
      completedAt: null,
      resultVersion: null,
      schemaVersion,
    });
    transaction.create(payloadRef, {
      operationId: operationRef.id,
      payload: data.payload,
      createdAt: now,
    });
    transaction.create(idempotencyRef, {
      operationId: operationRef.id,
      familyId,
      createdBy: request.auth.uid,
      payloadHash,
      createdAt: now,
    });
    return {
      operationId: operationRef.id,
      status: "pending",
      duplicate: false,
      resourceSequence: sequence,
    };
  });
}

function versionOf(snapshot) {
  return snapshot.exists ? Number(snapshot.data().version || 0) : 0;
}

async function applyBusinessTransaction(operationRef, operation, workerId) {
  return db.runTransaction(async (transaction) => {
    const freshOp = await transaction.get(operationRef);
    if (!freshOp.exists || freshOp.data().status !== "processing" ||
        freshOp.data().lockedBy !== workerId) return "ignored";
    const stateRef = db.collection("operation_resource_state")
        .doc(operation.resourceStateId);
    const state = await transaction.get(stateRef);
    if (!state.exists ||
        Number(state.data().nextSequenceToProcess) !== operation.resourceSequence) {
      return "waiting";
    }
    const familyRef = db.collection("families").doc(operation.familyId);
    const publicRef = familyRef.collection("members_public").doc(operation.resourceId);
    const privateRef = familyRef.collection("members_private").doc(operation.resourceId);
    const memberOperation = operation.type.startsWith("member.");
    let publicDoc;
    let privateDoc;
    let target;
    let targetDoc;
    let relationLinkRef;
    let relationLinkDoc;
    if (memberOperation) {
      publicDoc = await transaction.get(publicRef);
      privateDoc = await transaction.get(privateRef);
    } else {
      const collection = operation.type.startsWith("familyTreeLink.") ?
        "family_tree_links" : "relationships";
      target = db.collection(collection).doc(operation.resourceId);
      targetDoc = await transaction.get(target);
      if (operation.type.startsWith("relationship.")) {
        const deleting = operation.type.endsWith(".delete");
        const relationType = operation.payload.type || targetDoc.data()?.type;
        const sourceId = operation.payload.sourceId || targetDoc.data()?.sourceId;
        const targetId = operation.payload.targetId || targetDoc.data()?.targetId;
        relationLinkRef = db.collection("family_tree_links").doc(operation.resourceId);
        relationLinkDoc = await transaction.get(relationLinkRef);
        if (!deleting) {
          safeId(sourceId, "sourceId");
          safeId(targetId, "targetId");
          if (sourceId === targetId) {
            throw permanentError("self-relationship", "Auto-relation interdite.");
          }
          const [sourceMember, targetMember] = await Promise.all([
            transaction.get(familyRef.collection("members_public").doc(sourceId)),
            transaction.get(familyRef.collection("members_public").doc(targetId)),
          ]);
          if (!sourceMember.exists || !targetMember.exists ||
              sourceMember.data().isDeleted === true ||
              targetMember.data().isDeleted === true) {
            throw permanentError("invalid-member", "Membre absent ou supprimé.");
          }
          if (operation.type.endsWith(".update") && targetDoc.exists &&
              operation.payload.type && operation.payload.type !== targetDoc.data().type) {
            throw permanentError("immutable-type", "Le type de relation est immuable.");
          }
        }
        const relationsSnapshot = await transaction.get(
            db.collection("relationships")
                .where("familyId", "==", operation.familyId)
                .limit(MAX_GRAPH_DOCUMENTS + 1),
        );
        const relations = relationsSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        if (!deleting) {
          const duplicate = relations.some((relation) =>
            relation.id !== operation.resourceId &&
            relation.isDeleted !== true &&
            relation.active !== false &&
            relation.type === relationType &&
            relation.sourceId === sourceId &&
            relation.targetId === targetId,
          );
          if (duplicate) {
            throw permanentError("duplicate-relationship", "Relation déjà existante.");
          }
          if (relationType === "parentChild") {
            assertNoParentCycle(relations, sourceId, targetId);
          }
        }
      }
    }
    const currentVersion = memberOperation ?
      Math.max(versionOf(publicDoc), versionOf(privateDoc),
          Number(state.data().currentVersion || 0)) :
      Math.max(versionOf(targetDoc), Number(state.data().currentVersion || 0));
    const isCreate = operation.type === "member.create";
    const createOperation = operation.type.endsWith(".create");
    const resourceExists = memberOperation ?
      (publicDoc.exists || privateDoc.exists) : targetDoc.exists;
    if ((createOperation && (resourceExists || operation.baseVersion !== 0)) ||
        (!createOperation && operation.baseVersion !== currentVersion)) {
      transaction.update(operationRef, {
        status: "conflict",
        lastErrorCode: "version-conflict",
        lastErrorMessage: "La ressource a changé.",
        expectedVersion: operation.baseVersion,
        currentVersion,
        resultVersion: currentVersion,
        completedAt: FieldValue.serverTimestamp(),
        lockedAt: null,
        lockedBy: null,
        updatedAt: FieldValue.serverTimestamp(),
      });
      transaction.update(stateRef, {
        nextSequenceToProcess: operation.resourceSequence + 1,
        activeOperationId: null,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return "conflict";
    }
    const nextVersion = currentVersion + 1;
    if (memberOperation) {
      if (operation.type === "member.softDelete") {
        if (!publicDoc.exists || !privateDoc.exists) {
          throw permanentError("not-found", "Membre introuvable.");
        }
        const deleted = {
          isDeleted: true,
          deletedAt: FieldValue.serverTimestamp(),
          deletedBy: operation.createdBy,
          visibility: "hidden",
          updatedAt: FieldValue.serverTimestamp(),
          version: nextVersion,
        };
        const relations = await transaction.get(
            db.collection("relationships")
                .where("familyId", "==", operation.familyId)
                .limit(MAX_GRAPH_DOCUMENTS + 1),
        );
        const links = await transaction.get(
            db.collection("family_tree_links")
                .where("familyId", "==", operation.familyId)
                .limit(MAX_GRAPH_DOCUMENTS + 1),
        );
        if (relations.size > MAX_GRAPH_DOCUMENTS || links.size > MAX_GRAPH_DOCUMENTS) {
          throw permanentError("genealogy-check-limit", "Trop de liens à vérifier.");
        }
        transaction.set(publicRef, deleted, {merge: true});
        transaction.set(privateRef, deleted, {merge: true});
        for (const document of relations.docs) {
          const value = document.data();
          const involvesMember = [
            value.sourceId, value.targetId, value.parentId, value.childId,
            value.personId, value.spouseId, value.partner1Id, value.partner2Id,
          ].includes(operation.resourceId);
          if (involvesMember) {
            transaction.set(document.ref, {
              active: false,
              hiddenFromCurrentTree: true,
              updatedAt: FieldValue.serverTimestamp(),
            }, {merge: true});
          }
        }
        for (const document of links.docs) {
          const value = document.data();
          if ([value.fromPersonId, value.toPersonId].includes(operation.resourceId)) {
            transaction.set(document.ref, {
              hiddenFromCurrentTree: true,
              updatedAt: FieldValue.serverTimestamp(),
            }, {merge: true});
          }
        }
      } else {
        const publicData = operation.payload.public || {};
        const privateData = operation.payload.private || {};
        if (!Object.keys(publicData).length || !Object.keys(privateData).length) {
          throw permanentError("invalid-argument", "Parties publique et privée requises.");
        }
        transaction.set(publicRef, {
          ...publicData,
          id: operation.resourceId,
          familyId: operation.familyId,
          version: nextVersion,
          updatedAt: FieldValue.serverTimestamp(),
          ...(isCreate ? {createdAt: FieldValue.serverTimestamp()} : {}),
        }, {merge: !isCreate});
        transaction.set(privateRef, {
          ...privateData,
          memberId: operation.resourceId,
          familyId: operation.familyId,
          version: nextVersion,
          updatedAt: FieldValue.serverTimestamp(),
          ...(isCreate ? {createdAt: FieldValue.serverTimestamp()} : {}),
        }, {merge: !isCreate});
      }
      for (const relation of operation.payload.relationships || []) {
        const relationId = safeId(relation.id, "relationshipId");
        transaction.set(db.collection("relationships").doc(relationId), {
          ...relation,
          id: relationId,
          familyId: operation.familyId,
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      }
      for (const link of operation.payload.links || []) {
        const linkId = safeId(link.id, "linkId");
        transaction.set(db.collection("family_tree_links").doc(linkId), {
          ...link,
          id: linkId,
          familyId: operation.familyId,
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      }
    } else {
      if (operation.type.endsWith(".delete")) {
        if (!targetDoc.exists || targetDoc.data().isDeleted === true) {
          throw permanentError("not-found", "Relation ou lien introuvable.");
        }
        transaction.set(target, {
          active: false,
          isDeleted: true,
          deletedAt: FieldValue.serverTimestamp(),
          deletedBy: operation.createdBy,
          version: nextVersion,
        }, {merge: true});
        if (relationLinkRef) {
          transaction.set(relationLinkRef, {
            active: false,
            isDeleted: true,
            hiddenFromCurrentTree: true,
            deletedAt: FieldValue.serverTimestamp(),
            deletedBy: operation.createdBy,
            version: nextVersion,
          }, {merge: true});
        }
      } else {
        transaction.set(target, {
          ...operation.payload,
          id: operation.resourceId,
          familyId: operation.familyId,
          version: nextVersion,
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: operation.type.endsWith(".update")});
        if (relationLinkRef) {
          const relation = operation.payload;
          transaction.set(relationLinkRef, {
            id: operation.resourceId,
            familyId: operation.familyId,
            fromPersonId: relation.sourceId,
            toPersonId: relation.targetId,
            relationshipType: relation.type,
            active: relation.active !== false,
            hiddenFromCurrentTree: false,
            version: nextVersion,
            updatedAt: FieldValue.serverTimestamp(),
          }, {merge: relationLinkDoc.exists});
        }
      }
    }
    const auditRef = familyRef.collection("admin_audit_logs").doc();
    transaction.create(auditRef, {
      action: operation.type,
      resourceId: operation.resourceId,
      operationId: operation.operationId,
      performedBy: operation.createdBy,
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.update(stateRef, {
      currentVersion: nextVersion,
      nextSequenceToProcess: operation.resourceSequence + 1,
      activeOperationId: null,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(operationRef, {
      status: "completed",
      resultVersion: nextVersion,
      completedAt: FieldValue.serverTimestamp(),
      lockedAt: null,
      lockedBy: null,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return "completed";
  });
}

function permanentError(code, message) {
  const error = new Error(message);
  error.operationCode = code;
  error.permanent = true;
  return error;
}

function retryDelay(attempt) {
  return [10, 30, 60, 300, 900, 1800][Math.min(attempt - 1, 5)] * 1000;
}

async function finalizeFailure(operationRef, operation, workerId, error) {
  const attempt = Number(operation.attemptCount || 0) + 1;
  const retryable = !error.permanent && attempt < MAX_ATTEMPTS;
  const status = retryable ? "retryScheduled" :
    (error.permanent ? "rejected" : "failed");
  await db.runTransaction(async (transaction) => {
    const fresh = await transaction.get(operationRef);
    if (!fresh.exists || fresh.data().lockedBy !== workerId ||
        TERMINAL.has(fresh.data().status)) return;
    const stateRef = db.collection("operation_resource_state")
        .doc(operation.resourceStateId);
    transaction.update(operationRef, {
      status,
      nextAttemptAt: retryable ?
        Timestamp.fromMillis(Date.now() + retryDelay(attempt)) : null,
      lastErrorCode: error.operationCode || "internal",
      lastErrorMessage: error.permanent ? error.message : "Erreur technique transitoire.",
      lockedAt: null,
      lockedBy: null,
      completedAt: retryable ? null : FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    if (!retryable) {
      transaction.set(stateRef, {
        nextSequenceToProcess: operation.resourceSequence + 1,
        activeOperationId: null,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      if (status === "failed") {
        transaction.set(db.collection("operation_dead_letters").doc(operation.operationId), {
          operationId: operation.operationId,
          familyId: operation.familyId,
          type: operation.type,
          resourceId: operation.resourceId,
          errorCode: error.operationCode || "internal",
          failedAt: FieldValue.serverTimestamp(),
        });
      }
    } else {
      transaction.set(stateRef, {
        activeOperationId: null,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    }
  });
}

async function processOperation(operationId, workerId = `worker-${crypto.randomUUID()}`) {
  const operationRef = db.collection("operation_queue").doc(operationId);
  let operation;
  const acquired = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(operationRef);
    if (!snapshot.exists) return false;
    operation = snapshot.data();
    if (TERMINAL.has(operation.status) || operation.status === "processing") return false;
    if (!["pending", "retryScheduled"].includes(operation.status)) return false;
    if (operation.nextAttemptAt && operation.nextAttemptAt.toMillis() > Date.now()) return false;
    const stateRef = db.collection("operation_resource_state").doc(operation.resourceStateId);
    const state = await transaction.get(stateRef);
    if (!state.exists ||
        Number(state.data().nextSequenceToProcess) !== operation.resourceSequence) return false;
    const lockedAt = operation.lockedAt && operation.lockedAt.toMillis();
    if (lockedAt && Date.now() - lockedAt < LOCK_TTL_MS) return false;
    transaction.update(operationRef, {
      status: "processing",
      lockedBy: workerId,
      lockedAt: FieldValue.serverTimestamp(),
      attemptCount: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(stateRef, {
      activeOperationId: operationId,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return true;
  });
  if (!acquired) return {status: "ignored"};
  try {
    if (!operation.payload) {
      const payloadSnapshot = await db.collection("operation_payloads")
          .doc(operationId).get();
      if (!payloadSnapshot.exists) {
        throw permanentError("payload-missing", "Contenu de l’opération introuvable.");
      }
      operation = {...operation, payload: payloadSnapshot.data().payload};
    }
    const status = await applyBusinessTransaction(operationRef, operation, workerId);
    return {status};
  } catch (error) {
    await finalizeFailure(operationRef, operation, workerId, error);
    return {status: error.permanent ? "rejected" : "retryScheduled"};
  }
}

async function recoverOperations() {
  const now = Timestamp.now();
  const retrySnapshot = await db.collection("operation_queue")
      .where("status", "==", "retryScheduled")
      .where("nextAttemptAt", "<=", now).limit(100).get();
  for (const document of retrySnapshot.docs) await processOperation(document.id);
  const lockLimit = Timestamp.fromMillis(Date.now() - LOCK_TTL_MS);
  const lockedSnapshot = await db.collection("operation_queue")
      .where("status", "==", "processing")
      .where("lockedAt", "<=", lockLimit).limit(100).get();
  for (const document of lockedSnapshot.docs) {
    await document.ref.update({
      status: "retryScheduled",
      nextAttemptAt: now,
      lockedAt: null,
      lockedBy: null,
      updatedAt: FieldValue.serverTimestamp(),
    });
    await processOperation(document.id);
  }
}

async function authorizeOperationControl(request, operation) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
  const roleSnapshot = await db.collection("user_roles").doc(request.auth.uid).get();
  const role = roleSnapshot.data();
  if (!roleSnapshot.exists || role.active !== true) {
    throw new HttpsError("permission-denied", "Rôle actif requis.");
  }
  const familyIds = Array.isArray(role.familyIds) ? role.familyIds : [];
  const allowed = operation.createdBy === request.auth.uid ||
    role.role === "superAdmin" ||
    (role.role === "admin" && familyIds.includes(operation.familyId));
  if (!allowed) throw new HttpsError("permission-denied", "Opération non autorisée.");
}

async function cancelFamilyOperation(request) {
  const operationId = safeId(request.data && request.data.operationId, "operationId");
  const operationRef = db.collection("operation_queue").doc(operationId);
  const initial = await operationRef.get();
  if (!initial.exists) throw new HttpsError("not-found", "Opération introuvable.");
  await authorizeOperationControl(request, initial.data());
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(operationRef);
    const operation = snapshot.data();
    if (!snapshot.exists || operation.status !== "pending" ||
        operation.lockedAt || operation.lockedBy || Number(operation.attemptCount || 0) > 0) {
      throw new HttpsError("failed-precondition", "Opération non annulable.");
    }
    const stateRef = db.collection("operation_resource_state").doc(operation.resourceStateId);
    const state = await transaction.get(stateRef);
    transaction.update(operationRef, {
      status: "cancelled",
      cancelledAt: FieldValue.serverTimestamp(),
      cancelledBy: request.auth.uid,
      updatedAt: FieldValue.serverTimestamp(),
    });
    if (state.exists &&
        Number(state.data().nextSequenceToProcess) === operation.resourceSequence) {
      transaction.update(stateRef, {
        nextSequenceToProcess: operation.resourceSequence + 1,
        activeOperationId: null,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    transaction.create(
        db.collection("families").doc(operation.familyId)
            .collection("admin_audit_logs").doc(),
        {
          action: "operation.cancelled",
          operationId,
          resourceId: operation.resourceId,
          performedBy: request.auth.uid,
          createdAt: FieldValue.serverTimestamp(),
        },
    );
    return {operationId, status: "cancelled"};
  });
}

async function retryFamilyOperation(request) {
  const operationId = safeId(request.data && request.data.operationId, "operationId");
  const operationRef = db.collection("operation_queue").doc(operationId);
  const initial = await operationRef.get();
  if (!initial.exists) throw new HttpsError("not-found", "Opération introuvable.");
  await authorizeOperationControl(request, initial.data());
  const allowedCodes = new Set(["internal", "unavailable", "deadline-exceeded",
    "aborted", "resource-exhausted"]);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(operationRef);
    const operation = snapshot.data();
    const eligibleStatus = operation.status === "retryScheduled" ||
      operation.status === "failed";
    if (!eligibleStatus || !allowedCodes.has(operation.lastErrorCode) ||
        operation.lockedAt || operation.lockedBy ||
        Number(operation.attemptCount || 0) >= MAX_ATTEMPTS) {
      throw new HttpsError("failed-precondition", "Opération non relançable.");
    }
    transaction.update(operationRef, {
      status: "pending",
      nextAttemptAt: null,
      lockedAt: null,
      lockedBy: null,
      updatedAt: FieldValue.serverTimestamp(),
      retryRequestedAt: FieldValue.serverTimestamp(),
      retryRequestedBy: request.auth.uid,
    });
  });
  return {operationId, status: "pending"};
}

module.exports = {
  submitFamilyOperation,
  processOperation,
  recoverOperations,
  cancelFamilyOperation,
  retryFamilyOperation,
  finalizeFailure,
  applyBusinessTransaction,
  assertNoParentCycle,
  canonicalize,
  validatePayload,
  constants: {MAX_ATTEMPTS, LOCK_TTL_MS, MAX_PARENT_DEPTH, MAX_GRAPH_DOCUMENTS},
};
