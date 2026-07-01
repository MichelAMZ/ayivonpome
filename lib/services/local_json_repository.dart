import 'dart:convert';

import '../models/audit_log.dart';
import '../models/family_link.dart';
import '../models/family_tree_data.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';
import 'family_repository.dart';
import 'json_storage_service.dart';

class JsonFamilyRepository implements FamilyRepository {
  const JsonFamilyRepository(this.storage);

  final JsonStorageService storage;

  @override
  Future<void> createPerson(Person person) => _upsertPerson(person);

  @override
  Future<void> updatePerson(Person person) => _upsertPerson(person);

  @override
  Future<void> deletePerson(String personId) async {
    final data = await loadFamilyTree();
    await _write(
      data.copyWith(
        people: data.people.where((person) => person.id != personId).toList(),
      ),
    );
  }

  @override
  Future<FamilyTreeData> loadFamilyTree() async {
    final raw = await storage.readRaw();
    if (raw == null || raw.trim().isEmpty) {
      return FamilyTreeData.demo();
    }
    return FamilyTreeData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveFamilyTree(FamilyTreeData data) => _write(data);

  @override
  Future<void> createMarriage(MarriageRelation relation) =>
      _upsertMarriage(relation);

  @override
  Future<void> updateMarriage(MarriageRelation relation) =>
      _upsertMarriage(relation);

  @override
  Future<void> deleteMarriage(String relationId) async {
    final data = await loadFamilyTree();
    await _write(
      data.copyWith(
        marriageRelations: data.marriageRelations
            .where((relation) => relation.id != relationId)
            .toList(),
      ),
    );
  }

  @override
  Future<void> createFamilyLink(FamilyLink link) => _upsertFamilyLink(link);

  @override
  Future<void> updateFamilyLink(FamilyLink link) => _upsertFamilyLink(link);

  @override
  Future<void> createAuditLog(AuditLog log) async {
    final data = await loadFamilyTree();
    await _write(data.copyWith(auditLog: [...data.auditLog, log]));
  }

  Future<void> _upsertPerson(Person person) async {
    final data = await loadFamilyTree();
    final people = [...data.people];
    final index = people.indexWhere((item) => item.id == person.id);
    if (index == -1) {
      people.add(person);
    } else {
      people[index] = person;
    }
    await _write(data.copyWith(people: people));
  }

  Future<void> _upsertMarriage(MarriageRelation relation) async {
    final data = await loadFamilyTree();
    final relations = [...data.marriageRelations];
    final index = relations.indexWhere((item) => item.id == relation.id);
    if (index == -1) {
      relations.add(relation);
    } else {
      relations[index] = relation;
    }
    await _write(data.copyWith(marriageRelations: relations));
  }

  Future<void> _upsertFamilyLink(FamilyLink link) async {
    final data = await loadFamilyTree();
    final links = [...data.familyLinks];
    final index = links.indexWhere((item) => item.id == link.id);
    if (index == -1) {
      links.add(link);
    } else {
      links[index] = link;
    }
    await _write(data.copyWith(familyLinks: links));
  }

  Future<void> _write(FamilyTreeData data) {
    return storage.writeRaw(
      const JsonEncoder.withIndent('  ').convert(data.toJson()),
    );
  }
}
