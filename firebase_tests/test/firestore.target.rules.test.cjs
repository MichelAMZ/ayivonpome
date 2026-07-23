const fs = require('node:fs');
const path = require('node:path');
const {after, before, beforeEach, describe, it, test} = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {deleteDoc, doc, getDoc, setDoc, updateDoc} = require('firebase/firestore');

const projectId = 'demo-ayivon-staging';
const rules = fs.readFileSync(
  path.join(__dirname, '..', '..', 'firestore.rules.target'),
  'utf8',
);
let env;

const client = (uid) => uid
  ? env.authenticatedContext(uid).firestore()
  : env.unauthenticatedContext().firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {host: '127.0.0.1', port: 8080, rules},
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const roles = {
      authorA: ['member', ['familyA'], true],
      otherA: ['member', ['familyA'], true],
      adminA: ['admin', ['familyA'], true],
      adminB: ['admin', ['familyB'], true],
      inactiveA: ['admin', ['familyA'], false],
      superAdmin: ['superAdmin', [], true],
    };
    for (const [uid, [role, familyIds, active]] of Object.entries(roles)) {
      await setDoc(doc(db, `user_roles/${uid}`), {uid, role, familyIds, active});
    }
    await setDoc(doc(db, 'operation_queue/opA'), {
      operationId: 'opA', familyId: 'familyA', createdBy: 'authorA', status: 'pending',
    });
    await setDoc(doc(db, 'families/familyA/members_public/memberA'), {
      id: 'memberA', familyId: 'familyA',
    });
    await setDoc(doc(db, 'families/familyA/members_private/memberA'), {
      memberId: 'memberA', familyId: 'familyA', ownerUid: 'authorA',
    });
    await setDoc(doc(db, 'families/familyB/members_private/memberB'), {
      memberId: 'memberB', familyId: 'familyB', ownerUid: null,
    });
  });
});

after(async () => env.cleanup());

describe('règles cibles operation_queue', () => {
  it('isole les lectures par auteur, famille et rôle actif', async () => {
    await assertFails(getDoc(doc(client(), 'operation_queue/opA')));
    await assertSucceeds(getDoc(doc(client('authorA'), 'operation_queue/opA')));
    await assertFails(getDoc(doc(client('otherA'), 'operation_queue/opA')));
    await assertSucceeds(getDoc(doc(client('adminA'), 'operation_queue/opA')));
    await assertFails(getDoc(doc(client('adminB'), 'operation_queue/opA')));
    await assertFails(getDoc(doc(client('inactiveA'), 'operation_queue/opA')));
    await assertSucceeds(getDoc(doc(client('superAdmin'), 'operation_queue/opA')));
  });

  it('refuse create update delete pour tous les clients', async () => {
    await assertFails(setDoc(doc(client('adminA'), 'operation_queue/new'), {
      familyId: 'familyA', createdBy: 'adminA', status: 'completed',
    }));
    await assertFails(updateDoc(doc(client('authorA'), 'operation_queue/opA'), {status: 'completed'}));
    await assertFails(deleteDoc(doc(client('superAdmin'), 'operation_queue/opA')));
  });
});

describe('règles cibles collections finales et techniques', () => {
  it('refuse toutes les écritures finales', async () => {
    const paths = [
      'families/familyA/members_public/memberA',
      'families/familyA/members_private/memberA',
      'relationships/relationA',
      'family_tree_links/linkA',
      'user_roles/authorA',
    ];
    for (const target of paths) {
      await assertFails(setDoc(doc(client('superAdmin'), target), {familyId: 'familyA'}));
      await assertFails(updateDoc(doc(client('superAdmin'), target), {blocked: true}));
      await assertFails(deleteDoc(doc(client('superAdmin'), target)));
    }
  });

  it('interdit toute lecture et écriture des collections techniques', async () => {
    for (const collection of [
      'operation_idempotency',
      'operation_payloads',
      'operation_resource_state',
      'operation_dead_letters',
      'system_health_checks',
    ]) {
      const ref = doc(client('superAdmin'), `${collection}/technical`);
      await assertFails(getDoc(ref));
      await assertFails(setDoc(ref, {secret: true}));
    }
  });

  it('isole les données privées entre familles', async () => {
    await assertSucceeds(getDoc(doc(client('adminA'), 'families/familyA/members_private/memberA')));
    await assertFails(getDoc(doc(client('adminA'), 'families/familyB/members_private/memberB')));
  });

  it('la graine Admin SDK contourne les règles strictes', async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      const ref = doc(context.firestore(), 'operation_queue/adminCreated');
      await setDoc(ref, {familyId: 'familyA', createdBy: 'authorA', status: 'pending'});
      const snapshot = await getDoc(ref);
      if (!snapshot.exists()) throw new Error('Écriture Admin SDK absente.');
    });
  });
});
