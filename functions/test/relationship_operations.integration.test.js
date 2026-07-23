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

async function member(familyId, id, deleted = false) {
  await db.doc(`families/${familyId}/members_public/${id}`).set({
    id, familyId, firstName: id, isDeleted: deleted, version: 1,
  });
}

async function operation({
  id, familyId, relationId, type, payload, baseVersion = 0, sequence = 1,
}) {
  const stateId = `state-${id}`;
  await db.doc(`operation_resource_state/${stateId}`).set({
    resourceKey: `${familyId}:relationship:${relationId}`,
    nextSequenceToAssign: sequence + 1,
    nextSequenceToProcess: sequence,
    currentVersion: baseVersion,
    activeOperationId: null,
  });
  await db.doc(`operation_queue/${id}`).set({
    operationId: id,
    localOperationId: `local-${id}`,
    familyId,
    type,
    resourceType: "relationship",
    resourceId: relationId,
    resourceKey: `${familyId}:relationship:${relationId}`,
    resourceStateId: stateId,
    resourceSequence: sequence,
    baseVersion,
    payload,
    status: "pending",
    createdBy: "admin",
    attemptCount: 0,
    schemaVersion: 1,
  });
}

async function auditCount(familyId, operationId) {
  return (await db.collection(`families/${familyId}/admin_audit_logs`)
      .where("operationId", "==", operationId).get()).size;
}

test("relationship.create writes relation, link and one audit atomically", async () => {
  const suffix = Date.now();
  const familyId = `rel-create-${suffix}`;
  const id = `op-${suffix}`;
  await Promise.all([member(familyId, "parent"), member(familyId, "child")]);
  await operation({
    id, familyId, relationId: "relation", type: "relationship.create",
    payload: {type: "parentChild", sourceId: "parent", targetId: "child"},
  });

  assert.equal((await queue.processOperation(id, "worker-create")).status, "completed");
  const relation = await db.doc("relationships/relation").get();
  const link = await db.doc("family_tree_links/relation").get();
  assert.equal(relation.data().version, 1);
  assert.equal(link.data().relationshipType, "parentChild");
  assert.equal(link.data().hiddenFromCurrentTree, false);
  assert.equal(await auditCount(familyId, id), 1);
});

test("relationship.create refuses duplicate, self, missing, deleted and cycle without partial writes", async () => {
  const cases = [
    {name: "self", payload: {type: "spouse", sourceId: "a", targetId: "a"}},
    {name: "missing", payload: {type: "spouse", sourceId: "a", targetId: "missing"}},
    {name: "deleted", payload: {type: "spouse", sourceId: "a", targetId: "deleted"}},
    {name: "cycle", payload: {type: "parentChild", sourceId: "b", targetId: "a"}},
    {name: "duplicate", payload: {type: "parentChild", sourceId: "a", targetId: "b"}},
  ];
  for (const item of cases) {
    const suffix = `${Date.now()}-${item.name}`;
    const familyId = `rel-invalid-${suffix}`;
    await Promise.all([
      member(familyId, "a"),
      member(familyId, "b"),
      member(familyId, "deleted", true),
    ]);
    if (item.name === "cycle" || item.name === "duplicate") {
      await db.doc(`relationships/existing-${suffix}`).set({
        familyId,
        type: "parentChild",
        sourceId: "a",
        targetId: "b",
        active: true,
      });
    }
    const id = `op-${suffix}`;
    const relationId = `candidate-${suffix}`;
    await operation({
      id, familyId, relationId, type: "relationship.create", payload: item.payload,
    });
    assert.equal((await queue.processOperation(id, `worker-${item.name}`)).status, "rejected");
    assert.equal((await db.doc(`relationships/${relationId}`).get()).exists, false);
    assert.equal((await db.doc(`family_tree_links/${relationId}`).get()).exists, false);
    assert.equal(await auditCount(familyId, id), 0);
  }
});

test("relationship.update is atomic and rejects version conflict and type mutation", async () => {
  const suffix = Date.now() + 10;
  const familyId = `rel-update-${suffix}`;
  await Promise.all([member(familyId, "a"), member(familyId, "b")]);
  await db.doc("relationships/update-relation").set({
    familyId, type: "spouse", sourceId: "a", targetId: "b", active: true, version: 1,
  });
  await db.doc("family_tree_links/update-relation").set({
    familyId, fromPersonId: "a", toPersonId: "b", relationshipType: "spouse", version: 1,
  });
  await operation({
    id: `update-${suffix}`, familyId, relationId: "update-relation",
    type: "relationship.update", baseVersion: 1,
    payload: {type: "spouse", sourceId: "a", targetId: "b", notes: "valid"},
  });
  assert.equal(
      (await queue.processOperation(`update-${suffix}`, "worker-update")).status,
      "completed",
  );
  assert.equal((await db.doc("relationships/update-relation").get()).data().version, 2);
  assert.equal((await db.doc("family_tree_links/update-relation").get()).data().version, 2);

  await operation({
    id: `conflict-${suffix}`, familyId, relationId: "update-relation",
    type: "relationship.update", baseVersion: 1,
    payload: {type: "spouse", sourceId: "a", targetId: "b", notes: "stale"},
  });
  assert.equal(
      (await queue.processOperation(`conflict-${suffix}`, "worker-conflict")).status,
      "conflict",
  );
  assert.equal((await db.doc("relationships/update-relation").get()).data().notes, "valid");
});

test("relationship.delete is logical, hides its link and is idempotently rejected", async () => {
  const suffix = Date.now() + 20;
  const familyId = `rel-delete-${suffix}`;
  const relationId = `delete-relation-${suffix}`;
  await db.doc(`relationships/${relationId}`).set({
    familyId, type: "spouse", sourceId: "a", targetId: "b", active: true, version: 1,
  });
  await db.doc(`family_tree_links/${relationId}`).set({
    familyId, fromPersonId: "a", toPersonId: "b", active: true, version: 1,
  });
  const id = `delete-${suffix}`;
  await operation({
    id, familyId, relationId, type: "relationship.delete", payload: {}, baseVersion: 1,
  });
  assert.equal((await queue.processOperation(id, "worker-delete")).status, "completed");
  const relation = await db.doc(`relationships/${relationId}`).get();
  const link = await db.doc(`family_tree_links/${relationId}`).get();
  assert.equal(relation.data().isDeleted, true);
  assert.equal(relation.data().active, false);
  assert.equal(link.data().hiddenFromCurrentTree, true);
  assert.equal(await auditCount(familyId, id), 1);
});
