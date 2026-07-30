const fs = require('node:fs');
const path = require('node:path');
const {after, before, beforeEach, describe, it, test} = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  collection,
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
} = require('firebase/firestore');

const projectId = 'demo-ayivon-staging';
const rulesFile = process.env.FIRESTORE_RULES_FILE || 'firestore.rules';
const rules = fs.readFileSync(path.join(__dirname, '..', '..', rulesFile), 'utf8');

let testEnv;

const users = {
  memberA: ['member', ['familyA'], true],
  ownerA: ['member', ['familyA'], true],
  adminA: ['admin', ['familyA'], true],
  memberB: ['member', ['familyB'], true],
  adminB: ['admin', ['familyB'], true],
  superAdmin: ['superAdmin', [], true],
  inactiveUser: ['member', ['familyA'], false],
};

function publicMember(familyId, id, overrides = {}) {
  return {
    id,
    familyId,
    firstName: 'Koffi',
    lastName: 'Ayivon',
    gender: 'male',
    fatherId: '',
    motherId: '',
    spouseIds: [],
    childrenIds: [],
    parents: [],
    spouses: [],
    children: [],
    birthYear: 1950,
    birthCity: 'Lomé',
    isDeceased: false,
    isPatriarch: false,
    displayOrder: 1,
    generation: 1,
    photoUrl: null,
    schemaVersion: 2,
    deletedAt: '',
    createdAt: Timestamp.fromMillis(1000),
    updatedAt: Timestamp.fromMillis(1000),
    ...overrides,
  };
}

function privateMember(familyId, memberId, ownerUid, overrides = {}) {
  return {
    memberId,
    familyId,
    ownerUid,
    fullBirthDate: '1950-04-12',
    email: 'private@example.test',
    phone: '+22800000000',
    privateNotes: 'Privé',
    visibilitySettings: {},
    version: 1,
    schemaVersion: 2,
    createdAt: Timestamp.fromMillis(1000),
    updatedAt: Timestamp.fromMillis(1000),
    ...overrides,
  };
}

function context(uid) {
  return uid ? testEnv.authenticatedContext(uid) : testEnv.unauthenticatedContext();
}

function db(uid) {
  return context(uid).firestore();
}

function publicRef(database, familyId = 'familyA', memberId = 'publicMemberA') {
  return doc(database, `families/${familyId}/members_public/${memberId}`);
}

function privateRef(database, familyId = 'familyA', memberId = 'privateMemberA') {
  return doc(database, `families/${familyId}/members_private/${memberId}`);
}

async function seed() {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const database = ctx.firestore();
    for (const [uid, [role, familyIds, active]] of Object.entries(users)) {
      await setDoc(doc(database, `user_roles/${uid}`), {
        uid,
        role,
        familyIds,
        active,
      });
    }
    // Les rôles créés par la fonction serveur utilisent déjà l'UID comme
    // identifiant du document et ne dupliquent pas ce champ dans les données.
    await setDoc(doc(database, 'user_roles/adminWithoutEmbeddedUid'), {
      role: 'admin',
      familyIds: ['familyA'],
      active: true,
    });
    await setDoc(doc(database, 'families/familyA'), {
      id: 'familyA', name: 'Famille A', active: true, schemaVersion: 2,
      isPublic: true, updatedAt: Timestamp.fromMillis(1000),
    });
    await setDoc(doc(database, 'families/familyB'), {
      id: 'familyB', name: 'Famille B', active: true, schemaVersion: 2,
      isPublic: true, updatedAt: Timestamp.fromMillis(1000),
    });
    await setDoc(publicRef(database), publicMember('familyA', 'publicMemberA'));
    await setDoc(publicRef(database, 'familyB', 'publicMemberB'), publicMember('familyB', 'publicMemberB'));
    await setDoc(privateRef(database), privateMember('familyA', 'privateMemberA', 'ownerA'));
    await setDoc(privateRef(database, 'familyA', 'unclaimedPrivateMemberA'), privateMember('familyA', 'unclaimedPrivateMemberA', null));
    await setDoc(privateRef(database, 'familyB', 'privateMemberB'), privateMember('familyB', 'privateMemberB', 'memberB'));
    await setDoc(doc(database, 'members/legacyMemberA'), {
      id: 'legacyMemberA', familyId: 'familyA', firstName: 'Legacy', deletedAt: '',
    });
    await setDoc(doc(database, 'activity_logs/logA'), { familyId: 'familyA', action: 'test' });
    await setDoc(doc(database, 'notifications/notificationA'), { familyId: 'familyA', title: 'A' });
    await setDoc(doc(database, 'settings/settingsA'), { familyId: 'familyA', value: true });
    await setDoc(doc(database, 'operation_queue/operationA'), {
      operationId: 'operationA',
      familyId: 'familyA',
      createdBy: 'memberA',
      status: 'pending',
      createdAt: Timestamp.fromMillis(1000),
    });
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { host: '127.0.0.1', port: 8080, rules },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seed();
});

after(async () => {
  await testEnv.cleanup();
});

describe('members_public', () => {
  it('autorise la lecture anonyme dans toutes les familles publiques', async () => {
    await assertSucceeds(getDoc(publicRef(db())));
    await assertSucceeds(getDoc(publicRef(db(), 'familyB', 'publicMemberB')));
  });

  it('refuse toute création, modification et suppression anonyme', async () => {
    const database = db();
    await assertFails(setDoc(publicRef(database, 'familyA', 'new'), publicMember('familyA', 'new', { updatedAt: serverTimestamp() })));
    await assertFails(updateDoc(publicRef(database), { firstName: 'X', updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(publicRef(database)));
  });

  it('autorise les lectures publiques aux membres des deux familles', async () => {
    await assertSucceeds(getDoc(publicRef(db('memberA'))));
    await assertSucceeds(getDoc(publicRef(db('memberA'), 'familyB', 'publicMemberB')));
  });

  it('refuse la création par un membre standard', async () => {
    await assertFails(setDoc(publicRef(db('memberA'), 'familyA', 'new'), publicMember('familyA', 'new', { updatedAt: serverTimestamp() })));
  });

  it('autorise adminA dans familyA et refuse les admins des autres familles', async () => {
    await assertSucceeds(setDoc(publicRef(db('adminA'), 'familyA', 'newA'), publicMember('familyA', 'newA', { updatedAt: serverTimestamp() })));
    await assertFails(setDoc(publicRef(db('adminA'), 'familyB', 'newB'), publicMember('familyB', 'newB', { updatedAt: serverTimestamp() })));
    await assertFails(updateDoc(publicRef(db('adminB')), { firstName: 'Interdit', updatedAt: serverTimestamp() }));
  });

  it('impose la cohérence entre familyId, id et le chemin', async () => {
    await assertFails(setDoc(publicRef(db('adminA'), 'familyA', 'wrongFamily'), publicMember('familyB', 'wrongFamily', { updatedAt: serverTimestamp() })));
    await assertFails(setDoc(publicRef(db('adminA'), 'familyA', 'wrongId'), publicMember('familyA', 'otherId', { updatedAt: serverTimestamp() })));
    await assertFails(updateDoc(publicRef(db('adminA')), { familyId: 'familyB', updatedAt: serverTimestamp() }));
  });

  it('rend createdAt immuable et exige updatedAt serveur', async () => {
    await assertFails(updateDoc(publicRef(db('adminA')), { createdAt: Timestamp.now(), updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(publicRef(db('adminA')), { firstName: 'Sans timestamp' }));
    await assertSucceeds(updateDoc(publicRef(db('adminA')), { firstName: 'Valide', updatedAt: serverTimestamp() }));
  });

  for (const [field, value] of [
    ['email', 'leak@example.test'], ['phone', '+228'], ['ownerUid', 'ownerA'],
    ['role', 'admin'], ['unknownField', true], ['privateNotes', 'secret'],
  ]) {
    it(`refuse le champ interdit ${field}`, async () => {
      await assertFails(updateDoc(publicRef(db('adminA')), { [field]: value, updatedAt: serverTimestamp() }));
    });
  }

  it('refuse les types invalides et le mauvais schemaVersion', async () => {
    await assertFails(updateDoc(publicRef(db('adminA')), { firstName: 42, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(publicRef(db('adminA')), { schemaVersion: 1, updatedAt: serverTimestamp() }));
  });

  it('réserve la suppression aux admins autorisés', async () => {
    await assertFails(deleteDoc(publicRef(db('memberA'))));
    await assertFails(deleteDoc(publicRef(db('adminB'))));
    await assertSucceeds(deleteDoc(publicRef(db('adminA'))));
  });
});

describe('members_private', () => {
  it('accepte un rôle serveur dont l’UID est porté par le chemin du document', async () => {
    await assertSucceeds(
      getDoc(privateRef(db('adminWithoutEmbeddedUid'))),
    );
  });

  it('refuse anonyme, rôle absent, rôle inactif et membre non propriétaire', async () => {
    await assertFails(getDoc(privateRef(db())));
    await assertFails(getDoc(privateRef(db('userWithoutRole'))));
    await assertFails(getDoc(privateRef(db('inactiveUser'))));
    await assertFails(getDoc(privateRef(db('memberA'))));
  });

  it('autorise uniquement le propriétaire actif de la même famille', async () => {
    await assertSucceeds(getDoc(privateRef(db('ownerA'))));
    await assertFails(getDoc(privateRef(db('ownerA'), 'familyA', 'unclaimedPrivateMemberA')));
    await assertFails(getDoc(privateRef(db('ownerA'), 'familyB', 'privateMemberB')));
  });

  it('autorise adminA dans familyA, refuse les admins croisés et autorise superAdmin', async () => {
    await assertSucceeds(getDoc(privateRef(db('adminA'))));
    await assertFails(getDoc(privateRef(db('adminA'), 'familyB', 'privateMemberB')));
    await assertFails(getDoc(privateRef(db('adminB'))));
    await assertSucceeds(getDoc(privateRef(db('superAdmin'), 'familyB', 'privateMemberB')));
  });

  it('ne confère aucun droit propriétaire lorsque ownerUid est null', async () => {
    await assertFails(getDoc(privateRef(db('memberA'), 'familyA', 'unclaimedPrivateMemberA')));
  });

  it('autorise au propriétaire uniquement les champs personnels', async () => {
    await assertSucceeds(updateDoc(privateRef(db('ownerA')), { email: 'new@example.test', privateNotes: 'Nouvelle note', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(privateRef(db('ownerA')), { familyCode: 'admin-only', updatedAt: serverTimestamp() }));
  });

  for (const field of ['ownerUid', 'familyId', 'memberId', 'createdAt']) {
    it(`empêche le propriétaire de changer ${field}`, async () => {
      const values = { ownerUid: 'memberA', familyId: 'familyB', memberId: 'other', createdAt: Timestamp.now() };
      await assertFails(updateDoc(privateRef(db('ownerA')), { [field]: values[field], updatedAt: serverTimestamp() }));
    });
  }

  it('autorise adminA à modifier familyA mais pas familyB', async () => {
    await assertSucceeds(updateDoc(privateRef(db('adminA')), { privateNotes: 'Admin', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(privateRef(db('adminA'), 'familyB', 'privateMemberB'), { privateNotes: 'Cross', updatedAt: serverTimestamp() }));
  });

  it('interdit ownerUid même à adminA depuis le client', async () => {
    await assertFails(updateDoc(privateRef(db('adminA')), { ownerUid: 'memberA', updatedAt: serverTimestamp() }));
    await assertFails(setDoc(privateRef(db('adminA'), 'familyA', 'claimed'), privateMember('familyA', 'claimed', 'ownerA', { updatedAt: serverTimestamp() })));
  });

  it('refuse suppression standard et autorise admin de la famille', async () => {
    await assertFails(deleteDoc(privateRef(db('ownerA'))));
    await assertFails(deleteDoc(privateRef(db('adminB'))));
    await assertSucceeds(deleteDoc(privateRef(db('adminA'))));
  });

  for (const [field, value] of [['role', 'admin'], ['secret', 'x'], ['unknownField', true]]) {
    it(`refuse le champ privé non autorisé ${field}`, async () => {
      await assertFails(updateDoc(privateRef(db('adminA')), { [field]: value, updatedAt: serverTimestamp() }));
    });
  }
});

describe('user_roles', () => {
  it('refuse la lecture anonyme et autorise la lecture de son propre rôle', async () => {
    await assertFails(getDoc(doc(db(), 'user_roles/memberA')));
    await assertSucceeds(getDoc(doc(db('memberA'), 'user_roles/memberA')));
    await assertFails(getDoc(doc(db('memberA'), 'user_roles/adminA')));
  });

  it('autorise adminA à lire sa famille mais pas familyB', async () => {
    await assertSucceeds(getDoc(doc(db('adminA'), 'user_roles/memberA')));
    await assertFails(getDoc(doc(db('adminA'), 'user_roles/memberB')));
  });

  it('refuse toutes les écritures clientes, y compris superAdmin et auto-promotion', async () => {
    await assertFails(setDoc(doc(db('memberA'), 'user_roles/new'), { uid: 'new', role: 'member', familyIds: ['familyA'], active: true }));
    await assertFails(updateDoc(doc(db('memberA'), 'user_roles/memberA'), { role: 'admin' }));
    await assertFails(updateDoc(doc(db('adminA'), 'user_roles/adminA'), { role: 'superAdmin' }));
    await assertFails(setDoc(doc(db('adminA'), 'user_roles/newSuper'), { uid: 'newSuper', role: 'superAdmin', familyIds: [], active: true }));
    await assertFails(updateDoc(doc(db('adminA'), 'user_roles/memberB'), { active: false }));
    await assertFails(updateDoc(doc(db('adminB'), 'user_roles/memberA'), { active: false }));
    await assertFails(updateDoc(doc(db('superAdmin'), 'user_roles/superAdmin'), { active: false }));
    await assertFails(setDoc(doc(db('superAdmin'), 'user_roles/unknown'), { uid: 'unknown', role: 'root', familyIds: ['wrong'], active: 'yes' }));
    await assertFails(deleteDoc(doc(db('superAdmin'), 'user_roles/memberA')));
  });
});

describe('isolation inter-familles et autres collections', () => {
  it('refuse tout accès privé croisé et les payloads de famille incohérents', async () => {
    await assertFails(getDoc(privateRef(db('adminA'), 'familyB', 'privateMemberB')));
    await assertFails(getDoc(privateRef(db('memberA'), 'familyB', 'privateMemberB')));
    await assertFails(updateDoc(privateRef(db('ownerA'), 'familyB', 'privateMemberB'), { email: 'x@test', updatedAt: serverTimestamp() }));
    await assertFails(setDoc(privateRef(db('adminA'), 'familyA', 'wrongPayload'), privateMember('familyB', 'wrongPayload', null, { updatedAt: serverTimestamp() })));
  });

  it('refuse une requête collectionGroup privée non bornée', async () => {
    await assertFails(getDocs(collectionGroup(db('ownerA'), 'members_private')));
    await assertFails(getDocs(collectionGroup(db('adminA'), 'members_private')));
  });

  it('isole logs, notifications et paramètres par famille', async () => {
    await assertFails(getDoc(doc(db('adminB'), 'activity_logs/logA')));
    await assertSucceeds(getDoc(doc(db('adminA'), 'activity_logs/logA')));
    await assertFails(getDoc(doc(db('memberB'), 'notifications/notificationA')));
    await assertSucceeds(getDoc(doc(db('memberA'), 'notifications/notificationA')));
    await assertFails(updateDoc(doc(db('adminB'), 'settings/settingsA'), { familyId: 'familyA', value: false }));
  });
});

describe('collection legacy members', () => {
  it('refuse anonyme et utilisateurs standards', async () => {
    await assertFails(getDoc(doc(db(), 'members/legacyMemberA')));
    await assertFails(getDoc(doc(db('memberA'), 'members/legacyMemberA')));
  });

  it('autorise seulement admin de migration de la famille et superAdmin', async () => {
    await assertSucceeds(getDoc(doc(db('adminA'), 'members/legacyMemberA')));
    await assertFails(getDoc(doc(db('adminB'), 'members/legacyMemberA')));
    await assertSucceeds(getDoc(doc(db('superAdmin'), 'members/legacyMemberA')));
  });

  it('refuse toutes les écritures et les requêtes non bornées', async () => {
    await assertFails(setDoc(doc(db('adminA'), 'members/newLegacy'), { familyId: 'familyA' }));
    await assertFails(updateDoc(doc(db('adminA'), 'members/legacyMemberA'), { firstName: 'Changed' }));
    await assertFails(deleteDoc(doc(db('superAdmin'), 'members/legacyMemberA')));
    await assertFails(getDocs(collection(db('adminA'), 'members')));
    await assertSucceeds(getDocs(query(collection(db('adminA'), 'members'), where('familyId', '==', 'familyA'))));
  });
});

describe('operation_queue et collections techniques', () => {
  it('autorise auteur, admin de la famille et superAdmin à lire', async () => {
    const refFor = (uid) => doc(db(uid), 'operation_queue/operationA');
    await assertSucceeds(getDoc(refFor('memberA')));
    await assertSucceeds(getDoc(refFor('adminA')));
    await assertSucceeds(getDoc(refFor('superAdmin')));
    await assertFails(getDoc(refFor('memberB')));
    await assertFails(getDoc(refFor('adminB')));
    await assertFails(getDoc(refFor()));
  });

  it('interdit toute écriture cliente et tout accès technique', async () => {
    await assertFails(setDoc(doc(db('adminA'), 'operation_queue/new'), {
      familyId: 'familyA',
      createdBy: 'adminA',
      status: 'completed',
    }));
    await assertFails(updateDoc(doc(db('memberA'), 'operation_queue/operationA'), {
      status: 'completed',
    }));
    await assertFails(deleteDoc(doc(db('superAdmin'), 'operation_queue/operationA')));
    await assertFails(getDoc(doc(db('superAdmin'), 'operation_idempotency/key')));
    await assertFails(getDoc(doc(db('superAdmin'), 'operation_resource_state/key')));
    await assertFails(getDoc(doc(db('superAdmin'), 'operation_dead_letters/key')));
    await assertFails(getDoc(doc(db('superAdmin'), 'system_health_checks/key')));
  });
});

describe('requêtes utilisées par l’application', () => {
  it('autorise la liste publique et les filtres/ordres prévus', async () => {
    const database = db();
    const members = collection(database, 'families/familyA/members_public');
    await assertSucceeds(getDocs(query(members, where('deletedAt', '==', ''), orderBy('displayOrder'))));
    await assertSucceeds(getDocs(query(members, where('isDeceased', '==', false), orderBy('displayOrder'))));
    await assertSucceeds(getDocs(query(members, where('isPatriarch', '==', false), orderBy('displayOrder'))));
  });

  it('autorise les lectures unitaires prévues', async () => {
    await assertSucceeds(getDoc(privateRef(db('ownerA'))));
    await assertSucceeds(getDoc(doc(db('memberA'), 'user_roles/memberA')));
    await assertSucceeds(getDoc(doc(db('adminA'), 'activity_logs/logA')));
    await assertSucceeds(getDoc(doc(db('memberA'), 'notifications/notificationA')));
  });
});
