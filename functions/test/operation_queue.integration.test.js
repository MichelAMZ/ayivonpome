"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error("FIRESTORE_EMULATOR_HOST requis.");
}
if (!admin.apps.length) admin.initializeApp({projectId: "demo-ayivon-staging"});
const db = admin.firestore();
const queue = require("../operation_queue");

function memberPayload(id, familyId, firstName = "Koffi") {
  return {
    public: {id, familyId, firstName, lastName: "Ayivon", schemaVersion: 2},
    private: {memberId: id, familyId, email: null, schemaVersion: 2},
  };
}

async function seedOperation({
  operationId,
  familyId,
  memberId,
  type = "member.create",
  baseVersion = 0,
  sequence = 1,
  payload = memberPayload(memberId, familyId),
}) {
  const resourceStateId = `state-${operationId}`;
  await db.collection("operation_resource_state").doc(resourceStateId).set({
    resourceKey: `${familyId}:member:${memberId}`,
    nextSequenceToAssign: sequence + 1,
    nextSequenceToProcess: sequence,
    currentVersion: baseVersion,
    activeOperationId: null,
  });
  await db.collection("operation_queue").doc(operationId).set({
    operationId,
    localOperationId: `local-${operationId}`,
    familyId,
    type,
    resourceType: "member",
    resourceId: memberId,
    resourceKey: `${familyId}:member:${memberId}`,
    resourceStateId,
    resourceSequence: sequence,
    baseVersion,
    payload,
    status: "pending",
    createdBy: "super-admin",
    attemptCount: 0,
    schemaVersion: 1,
  });
}

test("double worker trigger commits one member and one audit", async () => {
  const suffix = Date.now();
  const familyId = `double-${suffix}`;
  const memberId = `member-${suffix}`;
  const operationId = `op-${suffix}`;
  await seedOperation({operationId, familyId, memberId});

  const results = await Promise.all([
    queue.processOperation(operationId, "worker-A"),
    queue.processOperation(operationId, "worker-B"),
  ]);

  const operation = await db.collection("operation_queue").doc(operationId).get();
  const publicMember = await db.doc(
      `families/${familyId}/members_public/${memberId}`,
  ).get();
  const privateMember = await db.doc(
      `families/${familyId}/members_private/${memberId}`,
  ).get();
  const audits = await db.collection(
      `families/${familyId}/admin_audit_logs`,
  ).where("operationId", "==", operationId).get();
  assert.equal(operation.data().status, "completed");
  assert.equal(operation.data().attemptCount, 1);
  assert.equal(publicMember.data().version, 1);
  assert.equal(privateMember.data().version, 1);
  assert.equal(audits.size, 1);
  assert.equal(results.filter((result) => result.status === "completed").length, 1);
});

test("soft delete is atomic and preserves but hides relations and links", async () => {
  const suffix = Date.now() + 1;
  const familyId = `delete-${suffix}`;
  const memberId = `member-${suffix}`;
  const operationId = `op-delete-${suffix}`;
  const publicRef = db.doc(`families/${familyId}/members_public/${memberId}`);
  const privateRef = db.doc(`families/${familyId}/members_private/${memberId}`);
  await publicRef.set({...memberPayload(memberId, familyId).public, version: 1});
  await privateRef.set({...memberPayload(memberId, familyId).private, version: 1});
  await db.collection("relationships").doc(`rel-${suffix}`).set({
    familyId, personId: memberId, spouseId: "other", active: true,
  });
  await db.collection("family_tree_links").doc(`link-${suffix}`).set({
    familyId, fromPersonId: memberId, toPersonId: "other",
  });
  await seedOperation({
    operationId,
    familyId,
    memberId,
    type: "member.softDelete",
    baseVersion: 1,
    payload: {},
  });

  await queue.processOperation(operationId, "delete-worker");
  const [publicDoc, privateDoc, relation, link] = await Promise.all([
    publicRef.get(),
    privateRef.get(),
    db.collection("relationships").doc(`rel-${suffix}`).get(),
    db.collection("family_tree_links").doc(`link-${suffix}`).get(),
  ]);
  assert.equal(publicDoc.data().isDeleted, true);
  assert.equal(privateDoc.data().isDeleted, true);
  assert.equal(publicDoc.data().version, 2);
  assert.equal(relation.data().active, false);
  assert.equal(relation.data().hiddenFromCurrentTree, true);
  assert.equal(link.data().hiddenFromCurrentTree, true);
});
