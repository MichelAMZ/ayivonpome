const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");

let environment;

test.before(async () => {
  environment = await initializeTestEnvironment({
    projectId: "ayivon-delete-rules-test",
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, "..", "..", "firestore.rules"),
        "utf8",
      ),
    },
  });
});

test.after(async () => {
  await environment.cleanup();
});

async function seed() {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc("user_roles/admin-ayivon").set({
      active: true,
      role: "admin",
      familyIds: ["ayivon"],
    });
    await db.doc("user_roles/super-ayivon").set({
      active: true,
      role: "superAdmin",
      familyIds: ["ayivon"],
    });
    await db.doc("user_roles/editor-ayivon").set({
      active: true,
      role: "editor",
      familyIds: ["ayivon"],
    });
    await db.doc("user_roles/admin-other").set({
      active: true,
      role: "admin",
      familyIds: ["other-family"],
    });
    await db.doc("members/member-test").set({
      familyId: "ayivon",
      deletedAt: "",
      version: 1,
    });
    await db.doc("activity_logs/activity-test").set({
      familyId: "ayivon",
      action: "update_person",
    });
  });
}

function softDelete(uid) {
  return environment
    .authenticatedContext(uid)
    .firestore()
    .doc("members/member-test")
    .set(
      {
        familyId: "ayivon",
        deletedAt: "2026-07-20T10:00:00.000Z",
        version: 2,
      },
      { merge: true },
    );
}

test("authorized admin and superAdmin may soft-delete their family member", async () => {
  await seed();
  await assertSucceeds(softDelete("admin-ayivon"));
  await seed();
  await assertSucceeds(softDelete("super-ayivon"));
});

test("editor, unauthenticated user, and another-family admin are denied", async () => {
  await seed();
  await assertFails(softDelete("editor-ayivon"));
  await assertFails(
    environment
      .unauthenticatedContext()
      .firestore()
      .doc("members/member-test")
      .set(
        { familyId: "ayivon", deletedAt: "deleted", version: 2 },
        { merge: true },
      ),
  );
  await assertFails(softDelete("admin-other"));
});

test("editor may update ordinary fields but cannot change deletedAt", async () => {
  await seed();
  const editorDocument = environment
    .authenticatedContext("editor-ayivon")
    .firestore()
    .doc("members/member-test");
  await assertSucceeds(editorDocument.set({ firstName: "Test", version: 2 }, { merge: true }));
  await seed();
  await assertFails(softDelete("editor-ayivon"));
  assert.ok(true);
});

test("only an authorized family admin may delete activity logs", async () => {
  for (const uid of ["admin-ayivon", "super-ayivon"]) {
    await seed();
    await assertSucceeds(
      environment
        .authenticatedContext(uid)
        .firestore()
        .doc("activity_logs/activity-test")
        .delete(),
    );
  }
  for (const uid of ["editor-ayivon", "admin-other"]) {
    await seed();
    await assertFails(
      environment
        .authenticatedContext(uid)
        .firestore()
        .doc("activity_logs/activity-test")
        .delete(),
    );
  }
  await seed();
  await assertFails(
    environment
      .unauthenticatedContext()
      .firestore()
      .doc("activity_logs/activity-test")
      .delete(),
  );
});
