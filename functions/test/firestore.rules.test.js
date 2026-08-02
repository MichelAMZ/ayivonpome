const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const firebase = require("firebase/compat/app");
require("firebase/compat/firestore");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");

const familyId = "ayivon";
const memberId = "member-1";
let environment;

test.before(async () => {
  environment = await initializeTestEnvironment({
    projectId: "demo-ayivon-staging",
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, "..", "..", "firestore.rules"),
        "utf8",
      ),
    },
  });
});

test.after(async () => environment.cleanup());
test.beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc("user_roles/editor").set({
      active: true,
      role: "editor",
      familyIds: [familyId],
    });
    await db.doc("user_roles/admin").set({
      active: true,
      role: "admin",
      familyIds: [familyId],
    });
    await db.doc("user_roles/viewer").set({
      active: true,
      role: "member",
      familyIds: [familyId],
    });
    await db.doc("user_roles/editor-other").set({
      active: true,
      role: "editor",
      familyIds: ["other-family"],
    });
  });
});

function serverTimestamp() {
  return firebase.firestore.FieldValue.serverTimestamp();
}

function publicPayload(overrides = {}) {
  return {
    id: memberId,
    familyId,
    firstName: "Koffi",
    lastName: "Ayivon",
    gender: "male",
    fatherId: "",
    motherId: "",
    spouseIds: [],
    childrenIds: [],
    parents: [],
    spouses: [],
    children: [],
    birthCity: "Lomé",
    isDeceased: false,
    generation: 1,
    schemaVersion: 2,
    deletedAt: "",
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

function privatePayload(overrides = {}) {
  return {
    memberId,
    familyId,
    schemaVersion: 2,
    deletedAt: "",
    updatedBy: "editor",
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

function editorDb() {
  return environment.authenticatedContext("editor").firestore();
}

function childGraphBatch(
  uid,
  parentId = "parent-1",
  childId = "child-1",
  parentCreatedAt = null,
) {
  const db = environment.authenticatedContext(uid).firestore();
  const batch = db.batch();
  batch.set(
    db.doc(`families/${familyId}/members_public/${parentId}`),
    publicPayload({
      id: parentId,
      firstName: "Parent",
      childrenIds: [childId],
      children: [childId],
      ...(parentCreatedAt ? {createdAt: parentCreatedAt} : {}),
    }),
  );
  batch.set(
    db.doc(`families/${familyId}/members_public/${childId}`),
    publicPayload({
      id: childId,
      firstName: "Enfant",
      fatherId: parentId,
      parents: [parentId],
    }),
  );
  batch.set(
    db.doc(`families/${familyId}/members_private/${parentId}`),
    privatePayload({memberId: parentId, updatedBy: uid}),
    {merge: true},
  );
  batch.set(
    db.doc(`families/${familyId}/members_private/${childId}`),
    privatePayload({memberId: childId, updatedBy: uid}),
  );
  return batch.commit();
}

test("editor peut créer members_public seul", async () => {
  await assertSucceeds(
    editorDb()
      .doc(`families/${familyId}/members_public/${memberId}`)
      .set(publicPayload()),
  );
});

test("editor peut remplacer et assainir members_public legacy", async () => {
  const createdAt = new Date("2026-01-01T00:00:00.000Z");
  await environment.withSecurityRulesDisabled(async (context) => {
    await context
      .firestore()
      .doc(`families/${familyId}/members_public/${memberId}`)
      .set({
        ...publicPayload({
          familyId: "family-ayivon",
          createdAt,
          updatedAt: createdAt,
        }),
        privateNotes: "champ legacy à retirer",
      });
  });

  await assertFails(
    editorDb()
      .doc(`families/${familyId}/members_public/${memberId}`)
      .set(publicPayload({createdAt}), {merge: true}),
  );
  await assertSucceeds(
    editorDb()
      .doc(`families/${familyId}/members_public/${memberId}`)
      .set(publicPayload({createdAt})),
  );
});

test("editor peut créer members_private seul", async () => {
  await assertSucceeds(
    editorDb()
      .doc(`families/${familyId}/members_private/${memberId}`)
      .set(privatePayload()),
  );
});

test("editor peut mettre à jour members_private seul", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await context
      .firestore()
      .doc(`families/${familyId}/members_private/${memberId}`)
      .set(privatePayload({updatedAt: new Date()}));
  });
  await assertSucceeds(
    editorDb()
      .doc(`families/${familyId}/members_private/${memberId}`)
      .set(privatePayload({phone: "+22800000000"}), {merge: true}),
  );
});

test("editor peut créer activity_logs seul", async () => {
  await assertSucceeds(
    editorDb().collection("activity_logs").add({
      familyId,
      action: "member_updated",
      entityType: "member",
      entityId: memberId,
      performedByUid: "editor",
      createdAt: serverTimestamp(),
    }),
  );
});

test("le batch public, privé et activity_logs est autorisé", async () => {
  const db = editorDb();
  const batch = db.batch();
  batch.set(
    db.doc(`families/${familyId}/members_public/${memberId}`),
    publicPayload(),
  );
  batch.set(
    db.doc(`families/${familyId}/members_private/${memberId}`),
    privatePayload(),
  );
  batch.set(db.collection("activity_logs").doc(), {
    familyId,
    action: "member_created",
    entityType: "member",
    entityId: memberId,
    performedByUid: "editor",
    createdAt: serverTimestamp(),
  });
  await assertSucceeds(batch.commit());
});

test("editor et admin peuvent créer atomiquement un enfant et sa parenté", async () => {
  await assertSucceeds(childGraphBatch("editor"));
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc("user_roles/admin").set({
      active: true,
      role: "admin",
      familyIds: [familyId],
    });
  });
  await assertSucceeds(childGraphBatch("admin"));
});

test("l'ajout assainit un ancien parent et conserve son createdAt", async () => {
  const createdAt = new Date("2025-01-01T00:00:00.000Z");
  await environment.withSecurityRulesDisabled(async (context) => {
    await context
      .firestore()
      .doc(`families/${familyId}/members_public/parent-1`)
      .set({
        ...publicPayload({
          id: "parent-1",
          familyId: "family-ayivon",
          createdAt,
          updatedAt: createdAt,
        }),
        privateNotes: "champ historique interdit",
      });
  });
  await assertSucceeds(
    childGraphBatch("editor", "parent-1", "child-1", createdAt),
  );
});

test("viewer et editor d'une autre famille ne peuvent pas ajouter un enfant", async () => {
  await assertFails(childGraphBatch("viewer"));
  await assertFails(childGraphBatch("editor-other"));
});

test("le listener actif reçoit l'enfant complet depuis un second client", async () => {
  await assertSucceeds(childGraphBatch("editor"));
  const secondClient = environment.unauthenticatedContext().firestore();
  const snapshot = await secondClient
    .collection(`families/${familyId}/members_public`)
    .where("deletedAt", "==", "")
    .get();
  const ids = snapshot.docs.map((document) => document.id);
  if (!ids.includes("child-1") || !ids.includes("parent-1")) {
    throw new Error("Le snapshot actif doit contenir le parent et l'enfant.");
  }
});

test("le listener exclut un enfant sans deletedAt", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await context
      .firestore()
      .doc(`families/${familyId}/members_public/hidden-child`)
      .set({id: "hidden-child", familyId, firstName: "Invisible"});
  });
  const snapshot = await environment
    .unauthenticatedContext()
    .firestore()
    .collection(`families/${familyId}/members_public`)
    .where("deletedAt", "==", "")
    .get();
  if (snapshot.docs.some((document) => document.id === "hidden-child")) {
    throw new Error("Un document sans deletedAt ne doit pas être actif.");
  }
});
