import 'dart:async';

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

  CollectionReference<Map<String, dynamic>> get _families =>
      _firestore.collection('families');

  CollectionReference<Map<String, dynamic>> get _relationships =>
      _firestore.collection('relationships');

  CollectionReference<Map<String, dynamic>> get _familyLinks =>
      _firestore.collection('family_tree_links');

  CollectionReference<Map<String, dynamic>> get _activityLogs =>
      _firestore.collection('activity_logs');

  CollectionReference<Map<String, dynamic>> get _adminAuditLogs =>
      _firestore.collection('admin_audit_logs');

  CollectionReference<Map<String, dynamic>> get _syncIncidents =>
      _firestore.collection('sync_incidents');

  @override
  Future<FamilyTreeData> loadFamilyTree() async {
    final people = await _activeByFamily(_members).get();
    final relationships = await _activeByFamily(_relationships).get();
    final links = await _activeByFamily(_familyLinks).get();

    return _treeFromSnapshots(people.docs, relationships.docs, links.docs);
  }

  @override
  Stream<FamilyTreeData> watchFamilyTree() {
    final controller = StreamController<FamilyTreeData>();
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? people;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? relationships;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? links;
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emitIfReady() {
      final currentPeople = people;
      final currentRelationships = relationships;
      final currentLinks = links;
      if (currentPeople == null ||
          currentRelationships == null ||
          currentLinks == null ||
          controller.isClosed) {
        return;
      }
      controller.add(
        _treeFromSnapshots(currentPeople, currentRelationships, currentLinks),
      );
    }

    void listen(
      Query<Map<String, dynamic>> query,
      void Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>) assign,
    ) {
      subscriptions.add(
        query.snapshots().listen((snapshot) {
          assign(snapshot.docs);
          emitIfReady();
        }, onError: controller.addError),
      );
    }

    listen(_activeByFamily(_members), (docs) => people = docs);
    listen(_activeByFamily(_relationships), (docs) => relationships = docs);
    listen(_activeByFamily(_familyLinks), (docs) => links = docs);

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }

  FamilyTreeData _treeFromSnapshots(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> people,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> relationships,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> links,
  ) {
    return FamilyTreeData(
      mainFamilyCode: _familyId,
      people: people
          .map((doc) => Person.fromJson(_mapper.fromSnapshot(doc)))
          .toList(),
      marriageRelations: relationships
          .map((doc) => MarriageRelation.fromJson(_mapper.fromSnapshot(doc)))
          .toList(),
      familyLinks: links
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
    FirestoreUpdateDiagnostic? diagnostic;
    try {
      final user = await _ensureFirebaseUser(
        'createPerson',
        doc.path,
        personId: personId,
      );
      await _ensureFamilyDocument(user);
      final snapshot = await doc.get();
      final remoteData = snapshot.data();
      final data = snapshot.exists
          ? _mapper.toFirestore(
              person
                  .copyWith(
                    createdAt: person.createdAt.isEmpty
                        ? now
                        : person.createdAt,
                    updatedAt: now,
                    version: _safeVersion(remoteData?['version']) + 1,
                  )
                  .toJson(),
              id: personId,
              familyId: _tenantFamilyId,
            )
          : _mapper.toPersonCreateData(
              person.copyWith(version: 1, deletedAt: '').toJson(),
              id: personId,
              familyId: _tenantFamilyId,
              uid: user?.uid ?? '',
            );
      if (snapshot.exists) {
        diagnostic = await _buildMemberUpdateDiagnostic(
          doc: doc,
          data: data,
          user: user,
          existingData: remoteData,
          existingExists: true,
        );
        _debugFirestoreUpdateDiagnostic(diagnostic);
      } else {
        diagnostic = await _buildMemberUpdateDiagnostic(
          doc: doc,
          data: data,
          user: user,
          existingData: const {},
          existingExists: false,
          operation: 'create',
        );
        _debugFirestoreUpdateDiagnostic(diagnostic);
      }
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
          diagnostic: diagnostic,
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
          diagnostic: diagnostic,
        ),
        stackTrace,
      );
    }
  }

  Future<void> _ensureFamilyDocument(User? user) async {
    final doc = _families.doc(_tenantFamilyId);
    final snapshot = await doc.get();
    if (snapshot.exists) return;
    await doc.set({
      'id': _tenantFamilyId,
      'name': _tenantFamilyId == 'ayivon' ? 'Famille AYIVON' : _tenantFamilyId,
      'active': true,
      'schemaVersion': 1,
      'version': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': user?.uid ?? '',
      'updatedBy': user?.uid ?? '',
    });
  }

  @override
  Future<void> updatePerson(Person person) async {
    _validatePersonWrite(person, 'enregistrer');
    final personId = person.id.trim();
    final doc = _members.doc(personId);
    final now = DateTime.now().toUtc().toIso8601String();
    FirestoreUpdateDiagnostic? diagnostic;
    try {
      final user = await _ensureFirebaseUser(
        'updatePerson',
        doc.path,
        personId: personId,
      );
      final snapshot = await doc.get();
      final remoteData = snapshot.data();
      final nextVersion = snapshot.exists
          ? _safeVersion(remoteData?['version']) + 1
          : 1;
      final data = _mapper.toFirestore(
        person.copyWith(updatedAt: now, version: nextVersion).toJson(),
        id: personId,
        familyId: _tenantFamilyId,
      );
      diagnostic = await _buildMemberUpdateDiagnostic(
        doc: doc,
        data: data,
        user: user,
        existingData: remoteData,
        existingExists: snapshot.exists,
      );
      _debugFirestoreUpdateDiagnostic(diagnostic);
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
          diagnostic: diagnostic,
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
          diagnostic: diagnostic,
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
    final snapshot = await doc.get();
    final remoteData = snapshot.data();
    final now = DateTime.now().toIso8601String();
    final nextVersion = snapshot.exists
        ? _safeVersion(remoteData?['version']) + 1
        : 1;
    final prepared = relation.copyWith(
      familyId: relation.familyId.isEmpty ? _familyId : relation.familyId,
      createdAt: relation.createdAt.isEmpty ? now : relation.createdAt,
      updatedAt: now,
      version: nextVersion,
    );
    await doc.set(
      _mapper.toFirestore(
        prepared.toJson(),
        id: prepared.id,
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
  Future<int> deleteActivityLogs({
    required String familyId,
    DateTime? olderThan,
    required String actorUid,
    required String actorRole,
    required String retentionLabel,
  }) async {
    final user = await _ensureFirebaseUser(
      'deleteActivityLogs',
      'activity_logs',
    );
    if (actorRole != 'superAdmin') {
      throw StateError('Suppression du journal non autorisee.');
    }
    final targetFamilyId = familyId.trim().isEmpty ? _tenantFamilyId : familyId;
    final auditId = 'adminAudit${DateTime.now().microsecondsSinceEpoch}';
    final startedAt = DateTime.now().toUtc();
    await _adminAuditLogs.doc(auditId).set({
      'id': auditId,
      'familyId': targetFamilyId,
      'actorUid': actorUid.trim().isEmpty ? user?.uid ?? '' : actorUid.trim(),
      'actorRole': actorRole,
      'action': 'activity_log_clear_started',
      'retentionLabel': retentionLabel,
      'olderThan': olderThan?.toUtc().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtClient': startedAt.toIso8601String(),
    });

    var deletedCount = 0;
    while (true) {
      Query<Map<String, dynamic>> query = _activityLogs
          .where('familyId', isEqualTo: targetFamilyId)
          .limit(400);
      if (olderThan != null) {
        query = _activityLogs
            .where('familyId', isEqualTo: targetFamilyId)
            .where('date', isLessThan: olderThan.toUtc().toIso8601String())
            .limit(400);
      }
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      deletedCount += snapshot.docs.length;
      if (snapshot.docs.length < 400) break;
    }

    await _adminAuditLogs.doc(auditId).set({
      'action': 'activity_log_cleared',
      'deletedCount': deletedCount,
      'completedAt': FieldValue.serverTimestamp(),
      'completedAtClient': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
    return deletedCount;
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
        'occurredAt': FieldValue.serverTimestamp(),
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
      _debugAuthMessage('AUTH Firebase not initialized for $operation');
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError(
        'Session Firebase editor/admin requise pour écrire dans Firestore.',
      );
    }

    _debugAuthMessage('AUTH UID = ${user.uid}');
    _debugAuthMessage('AUTH ANONYMOUS = ${user.isAnonymous}');
    _debugAuthMessage('AUTH EMAIL = ${user.email}');
    _debugAuthMessage('FAMILY ID = $_tenantFamilyId');
    if (personId.isNotEmpty) _debugAuthMessage('PERSON ID = $personId');
    _debugAuthMessage('FIRESTORE OPERATION = $operation');
    _debugAuthMessage('FIRESTORE PATH = $documentPath');
    await _debugCurrentRole(user.uid);
    return user;
  }

  void _debugAuthMessage(String message) {
    debugPrint(message);
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

  Future<FirestoreUpdateDiagnostic> _buildMemberUpdateDiagnostic({
    required DocumentReference<Map<String, dynamic>> doc,
    required Map<String, dynamic> data,
    required User? user,
    Map<String, dynamic>? existingData,
    bool? existingExists,
    String operation = 'update',
  }) async {
    var resolvedExistingData = Map<String, dynamic>.from(
      existingData ?? const {},
    );
    var resolvedExistingExists = existingExists ?? false;
    if (existingData == null || existingExists == null) {
      try {
        final snapshot = await doc.get();
        resolvedExistingExists = snapshot.exists;
        resolvedExistingData = Map<String, dynamic>.from(
          snapshot.data() ?? const {},
        );
      } catch (error) {
        resolvedExistingData = {'readError': error.toString()};
      }
    }

    final roleData = await _readCurrentRoleForDiagnostic(user?.uid);
    return FirestoreUpdateDiagnostic(
      documentPath: doc.path,
      operation: operation,
      uid: user?.uid ?? '',
      role: roleData.role,
      userFamilyIds: roleData.familyIds,
      userFamilyId: roleData.familyIds.contains(_tenantFamilyId)
          ? _tenantFamilyId
          : roleData.familyIds.join(', '),
      documentFamilyId: _stringValue(resolvedExistingData['familyId']),
      requestFamilyId: _stringValue(data['familyId']),
      sentData: _sanitizeDiagnosticMap(data),
      existingData: _sanitizeDiagnosticMap(resolvedExistingData),
      diff: _diffMaps(resolvedExistingData, data),
      existingExists: resolvedExistingExists,
      roleActive: roleData.active,
      rulePath: 'match /members/{memberId}',
    );
  }

  Future<_DiagnosticRoleData> _readCurrentRoleForDiagnostic(String? uid) async {
    if (uid == null || uid.isEmpty) return const _DiagnosticRoleData();
    try {
      final snapshot = await _firestore.collection('user_roles').doc(uid).get();
      final data = snapshot.data() ?? const <String, dynamic>{};
      final familyIds = (data['familyIds'] as List? ?? const [])
          .map((value) => '$value')
          .where((value) => value.trim().isNotEmpty)
          .toList();
      return _DiagnosticRoleData(
        role: _stringValue(data['role']),
        familyIds: familyIds,
        active: data['active'] == true,
      );
    } catch (error) {
      return _DiagnosticRoleData(role: 'role-read-error: $error');
    }
  }

  Map<String, dynamic> _sanitizeDiagnosticMap(Map<String, dynamic> data) {
    return data.map((key, value) {
      final normalized = key.toLowerCase();
      if (normalized.contains('password') ||
          normalized.contains('token') ||
          normalized.contains('secret') ||
          normalized.contains('apikey') ||
          normalized.contains('api_key') ||
          normalized.contains('accesscode') ||
          normalized.contains('access_code') ||
          normalized.contains('codefamilial') ||
          normalized.contains('familycode')) {
        return MapEntry(key, '[masque]');
      }
      return MapEntry(key, _sanitizeDiagnosticValue(value));
    });
  }

  Object? _sanitizeDiagnosticValue(Object? value) {
    if (value is Map) {
      return _sanitizeDiagnosticMap(Map<String, dynamic>.from(value));
    }
    if (value is List) {
      return value.map(_sanitizeDiagnosticValue).toList();
    }
    if (value is FieldValue) return value.toString();
    return value;
  }

  Map<String, dynamic> _diffMaps(
    Map<String, dynamic> existing,
    Map<String, dynamic> sent,
  ) {
    final diff = <String, dynamic>{};
    final keys = {...existing.keys, ...sent.keys}.toList()..sort();
    for (final key in keys) {
      final previous = existing[key];
      final next = sent[key];
      if ('$previous' == '$next') continue;
      diff[key] = {
        'avant': _sanitizeDiagnosticValue(previous),
        'apres': _sanitizeDiagnosticValue(next),
      };
    }
    return diff;
  }

  void _debugFirestoreUpdateDiagnostic(FirestoreUpdateDiagnostic diagnostic) {
    if (!kDebugMode) return;
    debugPrint('FIRESTORE UPDATE DIAGNOSTIC');
    debugPrint(diagnostic.toReport());
  }

  String _stringValue(Object? value) {
    if (value == null) return '';
    return '$value';
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
    this.diagnostic,
  });

  final String operation;
  final String documentPath;
  final String? firebaseCode;
  final String message;
  final FirestoreUpdateDiagnostic? diagnostic;

  @override
  String toString() {
    final code = firebaseCode == null ? '' : ' [$firebaseCode]';
    final base =
        'Firestore save failed$code on $documentPath during $operation: '
        '$message';
    final report = diagnostic?.toReport();
    if (report == null || report.isEmpty) return base;
    return '$base\n\n$report';
  }
}

class FirestoreUpdateDiagnostic {
  const FirestoreUpdateDiagnostic({
    required this.documentPath,
    required this.operation,
    required this.uid,
    required this.role,
    required this.userFamilyIds,
    required this.userFamilyId,
    required this.documentFamilyId,
    required this.requestFamilyId,
    required this.sentData,
    required this.existingData,
    required this.diff,
    required this.existingExists,
    required this.roleActive,
    required this.rulePath,
  });

  final String documentPath;
  final String operation;
  final String uid;
  final String role;
  final List<String> userFamilyIds;
  final String userFamilyId;
  final String documentFamilyId;
  final String requestFamilyId;
  final Map<String, dynamic> sentData;
  final Map<String, dynamic> existingData;
  final Map<String, dynamic> diff;
  final bool existingExists;
  final bool roleActive;
  final String rulePath;

  String get refusedCondition {
    if (uid.isEmpty) return 'request.auth != null';
    if (!roleActive) return 'currentRole().active == true';
    if (!['editor', 'admin', 'superAdmin'].contains(role)) {
      return "currentRole().role in ['editor', 'admin', 'superAdmin']";
    }
    final documentId = documentPath.split('/').last;
    if (operation == 'create') {
      if (requestFamilyId.isEmpty) return 'request.resource.data.familyId';
      if (!userFamilyIds.contains(requestFamilyId)) {
        return 'currentRole().familyIds.hasAny([request.resource.data.familyId])';
      }
      if (sentData['id'] != documentId) {
        return 'request.resource.data.id == memberId';
      }
      if (_version(sentData['version']) != 1) {
        return 'request.resource.data.version == 1';
      }
      if (sentData['createdBy'] != uid) {
        return 'request.resource.data.createdBy == request.auth.uid';
      }
      if (sentData['updatedBy'] != uid) {
        return 'request.resource.data.updatedBy == request.auth.uid';
      }
      return 'Aucune condition de création refusée déduite côté client';
    }
    if (!existingExists) {
      return 'resource.data existe pour allow update';
    }
    final normalizedDocumentFamilyId = documentFamilyId == 'family-ayivon'
        ? 'ayivon'
        : documentFamilyId;
    final sameTenantFamilyId =
        requestFamilyId == documentFamilyId ||
        (documentFamilyId == 'family-ayivon' && requestFamilyId == 'ayivon');
    if (!userFamilyIds.contains(normalizedDocumentFamilyId)) {
      return 'currentRole().familyIds.hasAny([resource.data.familyId])';
    }
    if (!sameTenantFamilyId) {
      return 'isSameTenantFamilyId(resource.data.familyId, request.resource.data.familyId)';
    }
    final previousVersion = _version(existingData['version']);
    final nextVersion = _version(sentData['version']);
    if (previousVersion == null) {
      if (nextVersion != 1) return 'hasValidNextVersion() version == 1';
    } else if (nextVersion != previousVersion + 1) {
      return 'hasValidNextVersion() version == resource.data.version + 1';
    }
    return 'Aucune condition refusée déduite côté client';
  }

  String toReport() {
    return [
      'Document : $documentPath',
      'Operation : $operation',
      'UID : ${uid.isEmpty ? 'non connecte' : uid}',
      'Role : ${role.isEmpty ? 'inconnu' : role}',
      'FamilyId utilisateur : ${userFamilyId.isEmpty ? userFamilyIds.join(', ') : userFamilyId}',
      'FamilyId document : ${documentFamilyId.isEmpty ? 'absent' : documentFamilyId}',
      'FamilyId envoye : ${requestFamilyId.isEmpty ? 'absent' : requestFamilyId}',
      'Donnees envoyees : $sentData',
      'Donnees existantes : $existingData',
      'Difference : $diff',
      'Regle Firestore concernee : $rulePath',
      'Condition refusee : $refusedCondition',
    ].join('\n');
  }

  static int? _version(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}

class _DiagnosticRoleData {
  const _DiagnosticRoleData({
    this.role = '',
    this.familyIds = const [],
    this.active = false,
  });

  final String role;
  final List<String> familyIds;
  final bool active;
}
