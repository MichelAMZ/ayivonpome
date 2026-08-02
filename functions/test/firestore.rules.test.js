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
    await context.firestore().doc("user_roles/editor").set({
      active: true,
      role: "editor",
      familyIds: [familyId],
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
