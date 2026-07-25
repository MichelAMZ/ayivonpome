const test = require("node:test");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");

let environment;

test.before(async () => {
  environment = await initializeTestEnvironment({
    projectId: "demo-ayivon-staging",
    firestore: {
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

test.after(async () => {
  await environment.cleanup();
});

async function seedRoles() {
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc("user_roles/admin").set({
      active: true,
      role: "admin",
      familyIds: ["ayivon"],
    });
    await db.doc("user_roles/super").set({
      active: true,
      role: "superAdmin",
      familyIds: ["ayivon"],
    });
    await db.doc("user_roles/editor").set({
      active: true,
      role: "editor",
      familyIds: ["ayivon"],
    });
  });
}

function publicMember(db) {
  return db.doc("families/ayivon/members_public/member-1");
}

function privateMember(db) {
  return db.doc("families/ayivon/members_private/member-1");
}

async function createMember(uid) {
  const db = environment.authenticatedContext(uid).firestore();
  await publicMember(db).set({
    id: "member-1",
    familyId: "ayivon",
    firstName: "Koffi",
    deletedAt: "",
  });
  await privateMember(db).set({
    memberId: "member-1",
    familyId: "ayivon",
    phone: null,
  });
}

test("admin and superAdmin can create and update a member directly", async () => {
  for (const uid of ["admin", "super"]) {
    await seedRoles();
    await assertSucceeds(createMember(uid));
    const db = environment.authenticatedContext(uid).firestore();
    await assertSucceeds(
        publicMember(db).set({firstName: "Kossi"}, {merge: true}),
    );
  }
});

test("editor and unauthenticated users cannot write members", async () => {
  await seedRoles();
  await assertFails(createMember("editor"));
  const db = environment.unauthenticatedContext().firestore();
  await assertFails(
      publicMember(db).set({
        id: "member-1",
        familyId: "ayivon",
        firstName: "Koffi",
        deletedAt: "",
      }),
  );
});

test("admin can soft-delete but cannot physically delete a member", async () => {
  await seedRoles();
  await createMember("admin");
  const db = environment.authenticatedContext("admin").firestore();
  await assertSucceeds(
      publicMember(db).set(
          {deletedAt: "2026-07-25T00:00:00.000Z"},
          {merge: true},
      ),
  );
  await assertFails(publicMember(db).delete());
});
