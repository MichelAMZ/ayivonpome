"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error("Émulateur requis.");
if (!admin.apps.length) admin.initializeApp({projectId: "demo-ayivon-staging"});
const db = admin.firestore();
const queue = require("../operation_queue");

function payload(memberId, familyId) {
  return {
    public: {id: memberId, familyId, firstName: "Recovery", lastName: "Test"},
    private: {memberId, familyId, email: null},
  };
}

async function seed({
  id, familyId, memberId, status = "pending", attemptCount = 0,
  sequence = 1, nextToProcess = sequence, lockedBy = null, lockedAt = null,
}) {
  const stateId = `state-${id}`;
  await db.doc(`operation_resource_state/${stateId}`).set({
    resourceKey: `${familyId}:member:${memberId}`,
    nextSequenceToAssign: sequence + 1,
    nextSequenceToProcess: nextToProcess,
    currentVersion: 0,
    activeOperationId: lockedBy ? id : null,
  });
  await db.doc(`operation_queue/${id}`).set({
    operationId: id, familyId, type: "member.create", resourceType: "member",
    resourceId: memberId, resourceStateId: stateId, resourceSequence: sequence,
    baseVersion: 0, payload: payload(memberId, familyId), status, createdBy: "admin",
    attemptCount, lockedBy, lockedAt, schemaVersion: 1,
  });
  return stateId;
}

test("stale processing lock is recovered and business write occurs once", async () => {
  const suffix = Date.now();
  const id = `stale-${suffix}`;
  const familyId = `recovery-${suffix}`;
  const memberId = `member-${suffix}`;
  await seed({
    id, familyId, memberId, status: "processing", attemptCount: 1,
    lockedBy: "crashed-worker",
    lockedAt: admin.firestore.Timestamp.fromMillis(
        Date.now() - queue.constants.LOCK_TTL_MS - 1000,
    ),
  });
  await queue.recoverOperations();
  await queue.processOperation(id, "duplicate-worker");
  const op = await db.doc(`operation_queue/${id}`).get();
  const audits = await db.collection(`families/${familyId}/admin_audit_logs`)
      .where("operationId", "==", id).get();
  assert.equal(op.data().status, "completed");
  assert.equal((await db.doc(`families/${familyId}/members_public/${memberId}`).get())
      .data().version, 1);
  assert.equal(audits.size, 1);
});

test("transient failure schedules retry, scanner waits, then succeeds", async () => {
  const suffix = Date.now() + 1;
  const id = `retry-${suffix}`;
  const familyId = `retry-family-${suffix}`;
  const memberId = `member-${suffix}`;
  await seed({
    id, familyId, memberId, status: "processing", attemptCount: 1,
    lockedBy: "worker-retry", lockedAt: admin.firestore.Timestamp.now(),
  });
  const operation = (await db.doc(`operation_queue/${id}`).get()).data();
  const transient = new Error("private connection detail");
  transient.operationCode = "unavailable";
  await queue.finalizeFailure(
      db.doc(`operation_queue/${id}`), operation, "worker-retry", transient,
  );
  let op = await db.doc(`operation_queue/${id}`).get();
  assert.equal(op.data().status, "retryScheduled");
  assert.ok(op.data().nextAttemptAt.toMillis() > Date.now());
  await queue.recoverOperations();
  assert.equal((await db.doc(`operation_queue/${id}`).get()).data().status, "retryScheduled");
  await db.doc(`operation_queue/${id}`).update({
    nextAttemptAt: admin.firestore.Timestamp.fromMillis(Date.now() - 1),
  });
  await queue.recoverOperations();
  op = await db.doc(`operation_queue/${id}`).get();
  assert.equal(op.data().status, "completed");
  assert.equal(op.data().lastErrorMessage, "Erreur technique transitoire.");
});

test("eighth transient failure creates a minimal dead letter and stops", async () => {
  const suffix = Date.now() + 2;
  const id = `max-${suffix}`;
  const familyId = `max-family-${suffix}`;
  const memberId = `member-${suffix}`;
  await seed({
    id, familyId, memberId, status: "processing", attemptCount: 8,
    lockedBy: "worker-max", lockedAt: admin.firestore.Timestamp.now(),
  });
  const operation = {
    ...(await db.doc(`operation_queue/${id}`).get()).data(),
    attemptCount: 7,
  };
  const transient = new Error("email=secret@example.test phone=123");
  transient.operationCode = "internal";
  await queue.finalizeFailure(
      db.doc(`operation_queue/${id}`), operation, "worker-max", transient,
  );
  const op = await db.doc(`operation_queue/${id}`).get();
  const dead = await db.doc(`operation_dead_letters/${id}`).get();
  assert.equal(op.data().status, "failed");
  assert.equal(op.data().attemptCount, 8);
  assert.deepEqual(
      Object.keys(dead.data()).sort(),
      ["errorCode", "failedAt", "familyId", "operationId", "resourceId", "type"].sort(),
  );
  assert.equal((await queue.processOperation(id, "ninth-worker")).status, "ignored");
});

test("a rejected sequence advances and the next two operations complete in order", async () => {
  const suffix = Date.now() + 3;
  const familyId = `sequence-family-${suffix}`;
  const relationId = `relation-${suffix}`;
  const stateId = `sequence-state-${suffix}`;
  await Promise.all([
    db.doc(`families/${familyId}/members_public/a`).set({
      id: "a", familyId, firstName: "A", version: 1,
    }),
    db.doc(`families/${familyId}/members_public/b`).set({
      id: "b", familyId, firstName: "B", version: 1,
    }),
  ]);
  await db.doc(`operation_resource_state/${stateId}`).set({
    resourceKey: `${familyId}:relationship:${relationId}`,
    nextSequenceToAssign: 13,
    nextSequenceToProcess: 10,
    currentVersion: 0,
    activeOperationId: null,
  });
  const common = {
    familyId,
    resourceType: "relationship",
    resourceId: relationId,
    resourceStateId: stateId,
    resourceKey: `${familyId}:relationship:${relationId}`,
    createdBy: "admin",
    attemptCount: 0,
    status: "pending",
    schemaVersion: 1,
  };
  await Promise.all([
    db.doc(`operation_queue/sequence-10-${suffix}`).set({
      ...common,
      operationId: `sequence-10-${suffix}`,
      type: "relationship.create",
      resourceSequence: 10,
      baseVersion: 0,
      payload: {type: "spouse", sourceId: "a", targetId: "a"},
    }),
    db.doc(`operation_queue/sequence-11-${suffix}`).set({
      ...common,
      operationId: `sequence-11-${suffix}`,
      type: "relationship.create",
      resourceSequence: 11,
      baseVersion: 0,
      payload: {type: "spouse", sourceId: "a", targetId: "b"},
    }),
    db.doc(`operation_queue/sequence-12-${suffix}`).set({
      ...common,
      operationId: `sequence-12-${suffix}`,
      type: "relationship.update",
      resourceSequence: 12,
      baseVersion: 1,
      payload: {
        type: "spouse", sourceId: "a", targetId: "b", notes: "sequence 12",
      },
    }),
  ]);

  assert.equal(
      (await queue.processOperation(`sequence-10-${suffix}`, "worker-10")).status,
      "rejected",
  );
  assert.equal(
      (await queue.processOperation(`sequence-11-${suffix}`, "worker-11")).status,
      "completed",
  );
  assert.equal(
      (await queue.processOperation(`sequence-12-${suffix}`, "worker-12")).status,
      "completed",
  );

  const [state, operation10, operation11, operation12, relation, audits] =
    await Promise.all([
      db.doc(`operation_resource_state/${stateId}`).get(),
      db.doc(`operation_queue/sequence-10-${suffix}`).get(),
      db.doc(`operation_queue/sequence-11-${suffix}`).get(),
      db.doc(`operation_queue/sequence-12-${suffix}`).get(),
      db.doc(`relationships/${relationId}`).get(),
      db.collection(`families/${familyId}/admin_audit_logs`).get(),
    ]);
  assert.equal(operation10.data().status, "rejected");
  assert.equal(operation11.data().status, "completed");
  assert.equal(operation12.data().status, "completed");
  assert.equal(state.data().nextSequenceToProcess, 13);
  assert.equal(state.data().activeOperationId, null);
  assert.equal(relation.data().version, 2);
  assert.equal(audits.size, 2);
});

test("replay after an atomically committed business transaction is a no-op", async () => {
  const suffix = Date.now() + 4;
  const id = `post-commit-${suffix}`;
  const familyId = `post-commit-family-${suffix}`;
  const memberId = `member-${suffix}`;
  await seed({id, familyId, memberId});

  assert.equal((await queue.processOperation(id, "first-worker")).status, "completed");
  assert.equal((await queue.processOperation(id, "restarted-worker")).status, "ignored");

  const [operation, publicMember, privateMember, audits] = await Promise.all([
    db.doc(`operation_queue/${id}`).get(),
    db.doc(`families/${familyId}/members_public/${memberId}`).get(),
    db.doc(`families/${familyId}/members_private/${memberId}`).get(),
    db.collection(`families/${familyId}/admin_audit_logs`)
        .where("operationId", "==", id).get(),
  ]);
  assert.equal(operation.data().status, "completed");
  assert.equal(operation.data().attemptCount, 1);
  assert.equal(publicMember.data().version, 1);
  assert.equal(privateMember.data().version, 1);
  assert.equal(audits.size, 1);
});
