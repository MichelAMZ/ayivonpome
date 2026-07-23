"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({projectId: "demo-ayivon-staging"});
}
const queue = require("../operation_queue");

test("canonicalize produces stable nested objects", () => {
  const first = JSON.stringify(queue.canonicalize({b: 2, a: {d: 4, c: 3}}));
  const second = JSON.stringify(queue.canonicalize({a: {c: 3, d: 4}, b: 2}));
  assert.equal(first, second);
});

test("member payload rejects server-controlled fields", () => {
  assert.throws(
      () => queue.validatePayload("member.update", {
        role: "superAdmin",
        public: {},
        private: {},
      }),
      /Champ serveur interdit/,
  );
});

test("member payload rejects fields outside the whitelist", () => {
  assert.throws(
      () => queue.validatePayload("member.update", {
        public: {firstName: "Koffi", secret: "no"},
        private: {},
      }),
      /interdit/,
  );
});

test("supported member payload is accepted", () => {
  assert.doesNotThrow(() => queue.validatePayload("member.create", {
    public: {id: "member-1", firstName: "Koffi", schemaVersion: 2},
    private: {memberId: "member-1", email: null, schemaVersion: 2},
  }));
});

test("family links use their own explicit whitelist", () => {
  assert.doesNotThrow(() => queue.validatePayload("familyTreeLink.create", {
    id: "link-1",
    fromPersonId: "member-1",
    toPersonId: "member-2",
    relationshipType: "branch",
  }));
  assert.throws(
      () => queue.validatePayload("familyTreeLink.create", {privateNotes: "no"}),
      /interdit/,
  );
});

test("parent cycle detection rejects direct and indirect cycles", () => {
  assert.throws(
      () => queue.assertNoParentCycle([], "a", "a"),
      /Cycle parental direct/,
  );
  assert.throws(
      () => queue.assertNoParentCycle([
        {type: "parentChild", sourceId: "a", targetId: "b", active: true},
        {type: "parentChild", sourceId: "b", targetId: "c", active: true},
      ], "c", "a"),
      /Cycle parental indirect/,
  );
  assert.doesNotThrow(() => queue.assertNoParentCycle([
    {type: "parentChild", sourceId: "a", targetId: "b", active: true},
  ], "a", "c"));
});
