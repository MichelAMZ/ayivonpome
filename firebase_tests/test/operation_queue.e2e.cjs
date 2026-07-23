const assert = require('node:assert/strict');
const admin = require('../../functions/node_modules/firebase-admin');
const {initializeApp} = require('firebase/app');
const {
  connectAuthEmulator,
  createUserWithEmailAndPassword,
  getAuth,
  signOut,
} = require('firebase/auth');
const {
  connectFunctionsEmulator,
  getFunctions,
  httpsCallable,
} = require('firebase/functions');

const projectId = 'demo-ayivon-staging';
process.env.GCLOUD_PROJECT = projectId;
if (!admin.apps.length) admin.initializeApp({projectId});
const db = admin.firestore();
const client = initializeApp({
  apiKey: 'demo-key',
  appId: '1:123:web:demo',
  authDomain: 'demo-ayivon-staging.firebaseapp.com',
  projectId,
});
const auth = getAuth(client);
connectAuthEmulator(auth, 'http://127.0.0.1:9099', {disableWarnings: true});
const functions = getFunctions(client);
connectFunctionsEmulator(functions, '127.0.0.1', 5001);

async function waitFor(ref, predicate, timeout = 15000) {
  const limit = Date.now() + timeout;
  while (Date.now() < limit) {
    const snapshot = await ref.get();
    if (snapshot.exists && predicate(snapshot.data())) return snapshot;
    await new Promise((resolve) => setTimeout(resolve, 150));
  }
  throw new Error(`Timeout ${ref.path}`);
}

(async () => {
  const suffix = Date.now();
  const familyId = `e2e-${suffix}`;
  const memberId = `member-${suffix}`;
  const credential = await createUserWithEmailAndPassword(
    auth,
    `super-${suffix}@example.test`,
    'Local-only-password-123!',
  );
  await db.collection('user_roles').doc(credential.user.uid).set({
    uid: credential.user.uid,
    role: 'superAdmin',
    familyIds: [],
    active: true,
  });
  await db.collection('families').doc(familyId).set({
    id: familyId,
    name: 'Famille fictive',
    isPublic: true,
  });
  const submit = httpsCallable(functions, 'submitFamilyOperation');
  const request = {
    localOperationId: `local-${suffix}`,
    idempotencyKey: `browser-installation-${suffix}:local-${suffix}`,
    familyId,
    type: 'member.create',
    resourceId: memberId,
    baseVersion: 0,
    schemaVersion: 1,
    payload: {
      public: {
        id: memberId,
        familyId,
        firstName: 'Test',
        lastName: 'Ayivon',
        schemaVersion: 2,
      },
      private: {
        memberId,
        familyId,
        email: 'private@example.test',
        privateNotes: 'secret-e2e',
        schemaVersion: 2,
      },
    },
  };
  const first = await submit(request);
  assert.ok(first.data.operationId);
  await waitFor(
    db.collection('operation_queue').doc(first.data.operationId),
    (data) => data.status === 'completed',
  );
  const [publicDoc, privateDoc, audits, operations, privatePayload] = await Promise.all([
    db.doc(`families/${familyId}/members_public/${memberId}`).get(),
    db.doc(`families/${familyId}/members_private/${memberId}`).get(),
    db.collection(`families/${familyId}/admin_audit_logs`)
      .where('operationId', '==', first.data.operationId).get(),
    db.collection('operation_queue').where('localOperationId', '==', request.localOperationId).get(),
    db.doc(`operation_payloads/${first.data.operationId}`).get(),
  ]);
  assert.equal(publicDoc.data().firstName, 'Test');
  assert.equal(publicDoc.data().email, undefined);
  assert.equal(privateDoc.data().email, 'private@example.test');
  assert.equal(audits.size, 1);
  assert.equal(operations.size, 1);
  assert.equal(Object.hasOwn(operations.docs[0].data(), 'payload'), false);
  assert.equal(Object.hasOwn(operations.docs[0].data(), 'payloadHash'), false);
  assert.equal(privatePayload.data().payload.private.email, 'private@example.test');
  const second = await submit(request);
  assert.equal(second.data.operationId, first.data.operationId);
  assert.equal(second.data.duplicate, true);

  async function securityUser(label, role) {
    const result = await createUserWithEmailAndPassword(
      auth,
      `${label}-${suffix}@example.test`,
      'Local-only-password-123!',
    );
    if (role) {
      await db.doc(`user_roles/${result.user.uid}`).set({
        uid: result.user.uid,
        ...role,
      });
    }
  }

  async function expectCode(data, code) {
    await assert.rejects(
      () => submit(data),
      (error) => error && error.code === `functions/${code}`,
    );
  }

  await securityUser('no-role');
  await expectCode({...request, idempotencyKey: `no-role-${suffix}`}, 'permission-denied');

  await securityUser('inactive', {
    role: 'admin', familyIds: [familyId], active: false,
  });
  await expectCode({...request, idempotencyKey: `inactive-${suffix}`}, 'permission-denied');

  await securityUser('member', {
    role: 'member', familyIds: [familyId], active: true,
  });
  await expectCode({...request, idempotencyKey: `member-${suffix}`}, 'permission-denied');

  await securityUser('other-admin', {
    role: 'admin', familyIds: ['another-family'], active: true,
  });
  await expectCode(
    {...request, idempotencyKey: `other-family-${suffix}`},
    'permission-denied',
  );
  await expectCode(
    {
      ...request,
      idempotencyKey: `forged-role-${suffix}`,
      payload: {...request.payload, role: 'superAdmin'},
    },
    'invalid-argument',
  );
  await expectCode(
    {
      ...request,
      idempotencyKey: `reserved-${suffix}`,
      payload: {...request.payload, createdBy: 'forged'},
    },
    'invalid-argument',
  );

  await signOut(auth);
  await expectCode(request, 'unauthenticated');
  process.stdout.write('E2E Auth + Functions + Firestore: PASS\n');
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
