import 'package:ayivonpome/models/audit_log.dart';
import 'package:ayivonpome/models/family_link.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/marriage_relation.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/models/sync_incident.dart';
import 'package:ayivonpome/models/sync_state.dart';
import 'package:ayivonpome/services/family_repository.dart';
import 'package:ayivonpome/services/incident_reporter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds structured incident from FirebaseException', () {
    final incident = IncidentReporter.buildIncident(
      item: _operation(),
      familyId: 'ayivon',
      error: FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing permissions',
      ),
      stackTrace: StackTrace.fromString(
        '#0 SyncService._send (package:ayivonpome/services/sync_service.dart:358:31)',
      ),
      sourceFunction: 'syncPendingQueue',
    );

    expect(incident.errorCode, 'permission-denied');
    expect(incident.errorType, 'FirebaseException');
    expect(incident.sourceFile, 'lib/services/sync_service.dart');
    expect(incident.sourceLine, 358);
    expect(incident.sourceColumn, 31);
    expect(incident.locationPrecision, 'exact');
  });

  test('builds structured incident from Dart exception', () {
    final incident = IncidentReporter.buildIncident(
      item: _operation(),
      familyId: 'ayivon',
      error: StateError('remote update failed'),
      stackTrace: StackTrace.fromString(
        '#0 _FakeRepository.updatePerson (file:///C:/repo/lib/services/member_repository.dart:142:18)',
      ),
    );

    expect(incident.errorCode, 'sync-error');
    expect(incident.errorType, 'StateError');
    expect(incident.sourceFile, 'lib/services/member_repository.dart');
    expect(incident.sourceLine, 142);
    expect(incident.sourceColumn, 18);
  });

  test('does not invent location when stack trace has no app frame', () {
    final location = IncidentReporter.extractSourceLocation(
      StackTrace.fromString(
        '#0 Future._propagateToListeners (dart:async/future_impl.dart:862:13)',
      ),
    );

    expect(location.sourceFile, isEmpty);
    expect(location.sourceLine, isNull);
    expect(location.sourceColumn, isNull);
    expect(location.precision, 'unavailable');
  });

  test('sanitizes sensitive technical data', () {
    final sanitized = IncidentReporter.sanitizeTechnicalData(
      'password=secret token: abc email test@example.com tel +228 90 11 22 33',
    );

    expect(sanitized, isNot(contains('secret')));
    expect(sanitized, isNot(contains('abc')));
    expect(sanitized, isNot(contains('test@example.com')));
    expect(sanitized, isNot(contains('+228 90 11 22 33')));
  });

  test('report never throws when incident persistence fails', () async {
    final reporter = IncidentReporter(_FailingIncidentRepository());

    await reporter.report(
      item: _operation(),
      familyId: 'ayivon',
      error: StateError('remote update failed'),
      stackTrace: StackTrace.current,
    );
  });

  test('limits stack trace size', () {
    final incident = IncidentReporter.buildIncident(
      item: _operation(),
      familyId: 'ayivon',
      error: StateError('remote update failed'),
      stackTrace: StackTrace.fromString('a' * 13000),
    );

    expect(incident.stackTrace.length, lessThanOrEqualTo(12020));
    expect(incident.stackTrace, contains('trace tronquée'));
  });
}

PendingSyncItem _operation() {
  return const PendingSyncItem(
    id: 'sync-1',
    entityType: 'person',
    entityId: 'p010',
    action: 'update',
    payload: {'id': 'p010'},
  );
}

class _FailingIncidentRepository implements FamilyRepository {
  @override
  Future<void> upsertSyncIncident(SyncIncident incident) {
    throw StateError('incident write failed');
  }

  @override
  Future<void> createAuditLog(AuditLog log) => throw UnimplementedError();

  @override
  Future<void> createFamilyLink(FamilyLink link) => throw UnimplementedError();

  @override
  Future<void> createMarriage(MarriageRelation relation) =>
      throw UnimplementedError();

  @override
  Future<void> createPerson(Person person) => throw UnimplementedError();

  @override
  Future<void> deleteMarriage(String relationId) => throw UnimplementedError();

  @override
  Future<void> deletePerson(String personId) => throw UnimplementedError();

  @override
  Future<FamilyTreeData> loadFamilyTree() => throw UnimplementedError();

  @override
  Future<void> saveFamilyTree(FamilyTreeData data) =>
      throw UnimplementedError();

  @override
  Future<void> updateFamilyLink(FamilyLink link) => throw UnimplementedError();

  @override
  Future<void> updateMarriage(MarriageRelation relation) =>
      throw UnimplementedError();

  @override
  Future<void> updatePerson(Person person) => throw UnimplementedError();
}
