import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../models/audit_log.dart';
import '../../models/family_link.dart';
import '../../models/family_tree_data.dart';
import '../../models/marriage_relation.dart';
import '../../models/person.dart';
import '../../models/sync_incident.dart';
import '../../services/remote_database_repository.dart';
import 'firestore_document_mapper.dart';

class FirestoreRemoteDatabaseClient implements RemoteDatabaseClient {
  FirestoreRemoteDatabaseClient({
    required FirebaseFirestore firestore,
    required String familyId,
    FirestoreDocumentMapper mapper = const FirestoreDocumentMapper(),
  }) : _firestore = firestore,
       _familyId = familyId,
       _mapper = mapper;

  final FirebaseFirestore _firestore;
  final String _familyId;
  final FirestoreDocumentMapper _mapper;

  CollectionReference<Map<String, dynamic>> get _members =>
      _firestore.collection('members');

  CollectionReference<Map<String, dynamic>> get _relationships =>
      _firestore.collection('relationships');

  CollectionReference<Map<String, dynamic>> get _familyLinks =>
      _firestore.collection('family_tree_links');

  CollectionReference<Map<String, dynamic>> get _activityLogs =>
      _firestore.collection('activity_logs');

  CollectionReference<Map<String, dynamic>> get _syncIncidents =>
      _firestore.collection('sync_incidents');

  @override
  Future<FamilyTreeData> loadFamilyTree() async {
    final people = await _activeByFamily(_members).get();
    final relationships = await _activeByFamily(_relationships).get();
    final links = await _activeByFamily(_familyLinks).get();

    return FamilyTreeData(
      mainFamilyCode: _familyId,
      people: people.docs
          .map((doc) => Person.fromJson(_mapper.fromSnapshot(doc)))
          .toList(),
      marriageRelations: relationships.docs
          .map((doc) => MarriageRelation.fromJson(_mapper.fromSnapshot(doc)))
          .toList(),
      familyLinks: links.docs
          .map((doc) => FamilyLink.fromJson(_mapper.fromSnapshot(doc)))
          .toList(),
    );
  }

  @override
  Future<void> saveFamilyTree(FamilyTreeData data) async {
    await _ensureFirebaseUser('saveFamilyTree', 'families/$_familyId');
    final batch = _firestore.batch();
    batch.set(_firestore.collection('families').doc(_familyId), {
      'id': _familyId,
      'name': _familyId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    for (final person in data.people) {
      batch.set(
        _members.doc(person.id),
        _mapper.toFirestore(
          person.toJson(),
          id: person.id,
          familyId: _tenantFamilyId,
        ),
        SetOptions(merge: true),
      );
    }
    for (final relation in data.marriageRelations) {
      batch.set(
        _relationships.doc(relation.id),
        _mapper.toFirestore(
          relation.toJson(),
          id: relation.id,
          familyId: _familyId,
        ),
        SetOptions(merge: true),
      );
    }
    for (final link in data.familyLinks) {
      batch.set(
        _familyLinks.doc(link.id),
        _mapper.toFirestore(link.toJson(), id: link.id, familyId: _familyId),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  @override
  Future<void> savePerson(Person person) => updatePerson(person);

  @override
  Future<void> createPerson(Person person) async {
    _validatePersonWrite(person, 'creer');
    final personId = person.id.trim();
    final doc = _members.doc(personId);
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await _ensureFirebaseUser('createPerson', doc.path, personId: personId);
      final data = _mapper.toFirestore(
        person
            .copyWith(
              createdAt: person.createdAt.isEmpty ? now : person.createdAt,
              updatedAt: now,
              version: person.version <= 0 ? 1 : person.version,
            )
            .toJson(),
        id: personId,
        familyId: _tenantFamilyId,
      );
      _debugFirestoreWriteStart(
        'createPerson',
        doc.path,
        personId: personId,
        data: data,
      );
      await doc.set(data, SetOptions(merge: true));
      _debugFirestoreWriteSuccess('createPerson', doc.path);
    } on FirebaseException catch (error, stackTrace) {
      _debugFirestoreSaveFailure('createPerson', doc.path, error, stackTrace);
      Error.throwWithStackTrace(
        FirestoreSaveException(
          operation: 'createPerson',
          documentPath: doc.path,
          firebaseCode: error.code,
          message: error.message ?? error.toString(),
        ),
        stackTrace,
      );
    } catch (error, stackTrace) {
      _debugFirestoreSaveFailure('createPerson', doc.path, error, stackTrace);
      Error.throwWithStackTrace(
        FirestoreSaveException(
          operation: 'createPerson',
          documentPath: doc.path,
          message: error.toString(),
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<void> updatePerson(Person person) async {
    _validatePersonWrite(person, 'enregistrer');
    final personId = person.id.trim();
    final doc = _members.doc(personId);
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await _ensureFirebaseUser('updatePerson', doc.path, personId: personId);
      final nextVersion = person.version <= 0 ? 1 : person.version + 1;
      final data = _mapper.toFirestore(
        person.copyWith(updatedAt: now, version: nextVersion).toJson(),
        id: personId,
        familyId: _tenantFamilyId,
      );
      _debugFirestoreWriteStart(
        'updatePerson',
        doc.path,
        personId: personId,
        data: data,
      );
      await doc.set(data, SetOptions(merge: true));
      _debugFirestoreWriteSuccess('updatePerson', doc.path);
    } on FirebaseException catch (error, stackTrace) {
      _debugFirestoreSaveFailure('updatePerson', doc.path, error, stackTrace);
      Error.throwWithStackTrace(
        FirestoreSaveException(
          operation: 'updatePerson',
          documentPath: doc.path,
          firebaseCode: error.code,
          message: error.message ?? error.toString(),
        ),
        stackTrace,
      );
    } catch (error, stackTrace) {
      _debugFirestoreSaveFailure('updatePerson', doc.path, error, stackTrace);
      Error.throwWithStackTrace(
        FirestoreSaveException(
          operation: 'updatePerson',
          documentPath: doc.path,
          message: error.toString(),
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<void> deletePerson(String personId) => _softDelete(_members, personId);

  @override
  Future<void> createMarriage(MarriageRelation relation) async {
    final doc = _relationships.doc(relation.id);
    await _ensureFirebaseUser('createMarriage', doc.path);
    await doc.set(
      _mapper.toFirestore(
        relation.toJson(),
        id: relation.id,
        familyId: _familyId,
      ),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> updateMarriage(MarriageRelation relation) =>
      createMarriage(relation);

  @override
  Future<void> deleteMarriage(String relationId) =>
      _softDelete(_relationships, relationId);

  @override
  Future<void> createFamilyLink(FamilyLink link) async {
    final doc = _familyLinks.doc(link.id);
    await _ensureFirebaseUser('createFamilyLink', doc.path);
    await doc.set(
      _mapper.toFirestore(link.toJson(), id: link.id, familyId: _familyId),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> updateFamilyLink(FamilyLink link) => createFamilyLink(link);

  @override
  Future<void> createAuditLog(AuditLog log) async {
    final doc = _activityLogs.doc(log.id);
    try {
      await _ensureFirebaseUser('createAuditLog', doc.path);
      await doc.set({
        ...log.toJson(),
        'id': log.id,
        'familyId': _tenantFamilyId,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _debugFirestoreWriteSuccess('createAuditLog', doc.path);
    } on FirebaseException catch (error, stackTrace) {
      _debugFirestoreSaveFailure('createAuditLog', doc.path, error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      _debugFirestoreSaveFailure('createAuditLog', doc.path, error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> upsertSyncIncident(SyncIncident incident) async {
    final doc = _syncIncidents.doc(incident.id);
    try {
      final user = await _ensureFirebaseUser('upsertSyncIncident', doc.path);
      if (user == null) {
        throw StateError(
          'Impossible d’enregistrer l’incident : utilisateur Firebase non connecté.',
        );
      }
      await doc.set({
        ...incident.toFirestoreUpdate(),
        'id': incident.id,
        'familyId': _tenantFamilyId,
        'userId': user.uid,
        'firstOccurredAtClient': incident.firstOccurredAt,
        'lastOccurredAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _debugFirestoreWriteSuccess('upsertSyncIncident', doc.path);
    } on FirebaseException catch (error, stackTrace) {
      _debugFirestoreSaveFailure(
        'upsertSyncIncident',
        doc.path,
        error,
        stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      _debugFirestoreSaveFailure(
        'upsertSyncIncident',
        doc.path,
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  Query<Map<String, dynamic>> _activeByFamily(
    CollectionReference<Map<String, dynamic>> collection,
  ) {
    return collection
        .where('familyId', isEqualTo: _familyId)
        .where('deletedAt', isEqualTo: '');
  }

  Future<void> _softDelete(
    CollectionReference<Map<String, dynamic>> collection,
    String id,
  ) async {
    final doc = collection.doc(id);
    await _ensureFirebaseUser('softDelete', doc.path, personId: id);
    if (collection.path == _members.path) {
      final snapshot = await doc.get();
      final remoteVersion = _safeVersion(snapshot.data()?['version']);
      await doc.set({
        'familyId': _familyId,
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
        'version': remoteVersion + 1,
      }, SetOptions(merge: true));
      return;
    }
    await doc.set({
      'familyId': _familyId,
      'deletedAt': DateTime.now().toUtc().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String get _tenantFamilyId => _familyId;

  Future<User?> _ensureFirebaseUser(
    String operation,
    String documentPath, {
    String personId = '',
  }) async {
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) {
        debugPrint('AUTH Firebase not initialized for $operation');
      }
      return null;
    }

    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (kDebugMode) {
        debugPrint('AUTH anonymous sign-in START for $operation');
      }
      final credential = await FirebaseAuth.instance.signInAnonymously();
      user = credential.user;
      if (user == null) {
        throw StateError(
          'Firebase Authentication n’a pas créé de session utilisateur.',
        );
      }
    }

    if (kDebugMode) {
      debugPrint('AUTH UID = ${user.uid}');
      debugPrint('AUTH ANONYMOUS = ${user.isAnonymous}');
      debugPrint('AUTH EMAIL = ${user.email}');
      debugPrint('FAMILY ID = $_tenantFamilyId');
      if (personId.isNotEmpty) debugPrint('PERSON ID = $personId');
      debugPrint('FIRESTORE OPERATION = $operation');
      debugPrint('FIRESTORE PATH = $documentPath');
      await _debugCurrentRole(user.uid);
    }
    return user;
  }

  Future<void> _debugCurrentRole(String uid) async {
    try {
      final role = await _firestore.collection('user_roles').doc(uid).get();
      final data = role.data();
      debugPrint('AUTH ROLE DOC = user_roles/$uid');
      debugPrint('AUTH ROLE EXISTS = ${role.exists}');
      debugPrint('AUTH ROLE = ${data?['role']}');
      debugPrint('AUTH ROLE ACTIVE = ${data?['active']}');
      debugPrint('AUTH ROLE FAMILY_IDS = ${data?['familyIds']}');
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('AUTH ROLE READ FAILED code=${error.code}');
      debugPrint('AUTH ROLE READ MESSAGE = ${error.message}');
      debugPrint('AUTH ROLE READ PLUGIN = ${error.plugin}');
      debugPrintStack(stackTrace: stackTrace);
    } catch (error, stackTrace) {
      debugPrint('AUTH ROLE READ ERROR = $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _validatePersonWrite(Person person, String action) {
    if (person.id.trim().isEmpty) {
      throw ArgumentError(
        'Impossible de $action une personne sans identifiant.',
      );
    }
    if (_tenantFamilyId.trim().isEmpty) {
      throw StateError(
        'Impossible de $action la personne : familyId est vide.',
      );
    }
  }

  void _debugFirestoreSaveFailure(
    String operation,
    String documentPath,
    Object error,
    StackTrace stackTrace,
  ) {
    if (kDebugMode) {
      debugPrint('FIRESTORE $operation FAILED');
      debugPrint('path: $documentPath');
      debugPrint('familyId: $_tenantFamilyId');
      if (error is FirebaseException) {
        debugPrint('code: ${error.code}');
        debugPrint('message: ${error.message}');
        debugPrint('plugin: ${error.plugin}');
      } else {
        debugPrint('error: $error');
      }
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _debugFirestoreWriteStart(
    String operation,
    String documentPath, {
    required String personId,
    required Map<String, dynamic> data,
  }) {
    if (kDebugMode) {
      debugPrint('FIRESTORE $operation START');
      debugPrint('path: $documentPath');
      debugPrint('familyId: $_tenantFamilyId');
      debugPrint('personId: $personId');
      debugPrint('data: $data');
    }
  }

  void _debugFirestoreWriteSuccess(String operation, String documentPath) {
    if (kDebugMode) {
      debugPrint('FIRESTORE $operation SUCCESS: $documentPath');
    }
  }

  int _safeVersion(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class FirestoreConflictException implements Exception {
  const FirestoreConflictException({
    required this.documentPath,
    required this.localVersion,
    required this.remoteVersion,
  });

  final String documentPath;
  final int localVersion;
  final int remoteVersion;

  @override
  String toString() {
    return 'Firestore conflict on $documentPath: local version $localVersion, '
        'remote version $remoteVersion.';
  }
}

class FirestoreSaveException implements Exception {
  const FirestoreSaveException({
    required this.operation,
    required this.documentPath,
    required this.message,
    this.firebaseCode,
  });

  final String operation;
  final String documentPath;
  final String? firebaseCode;
  final String message;

  @override
  String toString() {
    final code = firebaseCode == null ? '' : ' [$firebaseCode]';
    return 'Firestore save failed$code on $documentPath during $operation: '
        '$message';
  }
}
