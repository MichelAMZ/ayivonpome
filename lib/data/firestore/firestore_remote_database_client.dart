import 'package:cloud_firestore/cloud_firestore.dart';
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
    final doc = _members.doc(person.id);
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await doc.set(
        _mapper.toFirestore(
          person
              .copyWith(
                createdAt: person.createdAt.isEmpty ? now : person.createdAt,
                updatedAt: now,
                version: person.version <= 0 ? 1 : person.version,
              )
              .toJson(),
          id: person.id,
          familyId: _tenantFamilyId,
        ),
        SetOptions(merge: true),
      );
    } on FirebaseException catch (error, stackTrace) {
      _debugFirestoreSaveFailure('createPerson', doc.path, error);
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
      _debugFirestoreSaveFailure('createPerson', doc.path, error);
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
    final doc = _members.doc(person.id);
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(doc);
        final remote = snapshot.data();
        final remoteVersionValue = remote?['version'];
        final remoteVersion = remoteVersionValue is num
            ? remoteVersionValue.toInt()
            : 0;
        final createdAtValue = remote?['createdAt'];
        final createdAt = createdAtValue is String && createdAtValue.isNotEmpty
            ? createdAtValue
            : person.createdAt;

        final updatedPerson = person.copyWith(
          createdAt: createdAt.isEmpty ? now : createdAt,
          updatedAt: now,
          version: remoteVersion + 1,
        );

        transaction.set(
          doc,
          _mapper.toFirestore(
            updatedPerson.toJson(),
            id: person.id,
            familyId: _tenantFamilyId,
          ),
          SetOptions(merge: true),
        );
      });
    } on FirebaseException catch (error, stackTrace) {
      _debugFirestoreSaveFailure('updatePerson', doc.path, error);
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
      _debugFirestoreSaveFailure('updatePerson', doc.path, error);
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
  Future<void> createMarriage(MarriageRelation relation) {
    return _relationships
        .doc(relation.id)
        .set(
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
  Future<void> createFamilyLink(FamilyLink link) {
    return _familyLinks
        .doc(link.id)
        .set(
          _mapper.toFirestore(link.toJson(), id: link.id, familyId: _familyId),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> updateFamilyLink(FamilyLink link) => createFamilyLink(link);

  @override
  Future<void> createAuditLog(AuditLog log) {
    return _activityLogs.doc(log.id).set({
      ...log.toJson(),
      'familyId': _tenantFamilyId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> upsertSyncIncident(SyncIncident incident) async {
    final doc = _syncIncidents.doc(incident.id);
    final snapshot = await doc.get();
    await doc.set({
      ...incident.toFirestoreUpdate(),
      if (!snapshot.exists) 'firstOccurredAt': FieldValue.serverTimestamp(),
      'lastOccurredAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
  ) {
    if (collection.path == _members.path) {
      final doc = collection.doc(id);
      return doc.get().then((snapshot) {
        final remoteVersion = snapshot.data()?['version'] as int? ?? 0;
        return doc.set({
          'familyId': _familyId,
          'deletedAt': DateTime.now().toUtc().toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
          'version': remoteVersion + 1,
        }, SetOptions(merge: true));
      });
    }
    return collection.doc(id).set({
      'familyId': _familyId,
      'deletedAt': DateTime.now().toUtc().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String get _tenantFamilyId => _familyId;

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
  ) {
    if (kDebugMode) {
      debugPrint('Firestore $operation failed on $documentPath: $error');
    }
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
