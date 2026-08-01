import 'dart:io';

import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/services/member_firestore_service.dart';
import 'package:ayivonpome/services/remote_database_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each member command delegates to one direct remote write', () async {
    final client = _CountingRemoteClient();
    final service = MemberFirestoreService(
      DatabaseFamilyRepository(client: client),
    );
    const person = Person(id: 'member-1', firstName: 'Membre');

    await service.createMember(person);
    await service.updateMember(person);
    await service.softDeleteMember(person.id);
    await service.upsertMemberGraph(const FamilyTreeData(people: [person]));

    expect(client.createCount, 1);
    expect(client.updateCount, 1);
    expect(client.softDeleteCount, 1);
    expect(client.graphCommitCount, 1);
  });

  test('member CRUD keeps unrelated pending operations intact', () {
    final source = File(
      'lib/providers/family_tree_provider.dart',
    ).readAsStringSync();
    final method = source.substring(
      source.indexOf('Future<MemberSaveResult> _saveMemberOperations'),
      source.indexOf('String _memberWriteErrorMessage'),
    );

    expect(method, contains('memberService.updateMember(directMember)'));
    expect(method, contains("hasPendingOperations ? 'pending' : 'synced'"));
    expect(method, isNot(contains('pendingSyncQueue: const []')));
  });
}

class _CountingRemoteClient extends UnconfiguredRemoteDatabaseClient {
  var createCount = 0;
  var updateCount = 0;
  var softDeleteCount = 0;
  var graphCommitCount = 0;

  @override
  Future<void> createPerson(Person person) async => createCount++;

  @override
  Future<void> updatePerson(Person person) async => updateCount++;

  @override
  Future<void> deletePerson(String personId) async => softDeleteCount++;

  @override
  Future<void> saveFamilyTree(FamilyTreeData data) async => graphCommitCount++;
}
