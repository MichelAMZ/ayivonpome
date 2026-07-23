"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const FORBIDDEN_KEYS = new Set([
  "email", "phone", "whatsapp", "fullAddress", "currentAddress",
  "privateNotes", "documents", "administrativeInformation", "payload",
]);

function findForbiddenKeys(value, path = "$", found = []) {
  if (Array.isArray(value)) {
    value.forEach((item, index) => findForbiddenKeys(item, `${path}[${index}]`, found));
  } else if (value && typeof value === "object") {
    for (const [key, child] of Object.entries(value)) {
      if (FORBIDDEN_KEYS.has(key)) found.push(`${path}.${key}`);
      findForbiddenKeys(child, `${path}.${key}`, found);
    }
  }
  return found;
}

test("recursive private-key detector finds nested forbidden fields", () => {
  assert.deepEqual(
      findForbiddenKeys({safe: [{nested: {privateNotes: "secret"}}]}),
      ["$.safe[0].nested.privateNotes"],
  );
});

test("public, audit, queue, dead-letter, idempotency and callable shapes are clean", () => {
  const documents = [
    {id: "member", familyId: "family", firstName: "Koffi", birthYear: 1950},
    {action: "member.update", operationId: "op", performedBy: "uid"},
    {operationId: "op", familyId: "family", status: "failed",
      lastErrorMessage: "Erreur technique transitoire."},
    {operationId: "op", familyId: "family", type: "member.update",
      errorCode: "internal", attemptCount: 8},
    {operationId: "op", payloadHash: "sha256", createdBy: "uid"},
    {operationId: "op", status: "pending", duplicate: false, resourceSequence: 1},
  ];
  for (const document of documents) {
    assert.deepEqual(findForbiddenKeys(document), []);
    assert.doesNotMatch(JSON.stringify(document), /secret@example|private note|123456/);
  }
});

module.exports = {findForbiddenKeys, FORBIDDEN_KEYS};
