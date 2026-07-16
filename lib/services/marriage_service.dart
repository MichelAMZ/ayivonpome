import '../models/family_tree_data.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';

class MarriageService {
  const MarriageService();

  MarriageRelation? relationBetween(
    FamilyTreeData data,
    String firstId,
    String secondId,
  ) {
    for (final relation in data.marriageRelations) {
      if (relation.deletedAt.isNotEmpty) continue;
      final direct =
          relation.personId == firstId && relation.spouseId == secondId;
      final reverse =
          relation.personId == secondId && relation.spouseId == firstId;
      if (direct || reverse) return relation;
    }
    return null;
  }

  List<MarriageRelation> relationsFor(FamilyTreeData data, String personId) {
    return data.marriageRelations
        .where(
          (relation) =>
              relation.deletedAt.isEmpty &&
              (relation.personId == personId || relation.spouseId == personId),
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<Person> getFormerSpouses(FamilyTreeData data, Person person) {
    final peopleById = {for (final item in data.people) item.id: item};
    return relationsFor(data, person.id)
        .where((relation) => relation.status == 'divorced')
        .map(
          (relation) =>
              peopleById[relation.personId == person.id
                  ? relation.spouseId
                  : relation.personId],
        )
        .whereType<Person>()
        .toList();
  }

  FamilyTreeData declareDivorce(
    FamilyTreeData data,
    MarriageRelation relation, {
    required String divorceDate,
    String notes = '',
  }) {
    return _replace(
      data,
      relation.copyWith(
        status: 'divorced',
        divorceDate: divorceDate.trim(),
        endDate: divorceDate.trim(),
        notes: notes.trim().isEmpty ? relation.notes : notes.trim(),
      ),
    );
  }

  FamilyTreeData restoreMarriage(
    FamilyTreeData data,
    MarriageRelation relation,
  ) {
    return _replace(
      data,
      relation.copyWith(status: 'active', divorceDate: '', endDate: ''),
    );
  }

  FamilyTreeData upsertUnion(
    FamilyTreeData data,
    MarriageRelation draft, {
    required String updatedBy,
  }) {
    if (draft.personId == draft.spouseId ||
        draft.personId.isEmpty ||
        draft.spouseId.isEmpty) {
      throw StateError('invalid_union');
    }
    final peopleById = {for (final person in data.people) person.id: person};
    final first = peopleById[draft.personId];
    final second = peopleById[draft.spouseId];
    if (first == null || second == null) throw StateError('unknown_partner');

    final now = DateTime.now().toIso8601String();
    final existingIndex = data.marriageRelations.indexWhere((relation) {
      final samePair =
          (relation.personId == draft.personId &&
              relation.spouseId == draft.spouseId) ||
          (relation.personId == draft.spouseId &&
              relation.spouseId == draft.personId);
      return relation.deletedAt.isEmpty && samePair;
    });
    final existing = existingIndex == -1
        ? null
        : data.marriageRelations[existingIndex];
    final next = draft.copyWith(
      id: existing?.id ?? (draft.id.isEmpty ? _id('marriage') : draft.id),
      familyId: draft.familyId.isEmpty ? data.mainFamilyCode : draft.familyId,
      createdAt:
          existing?.createdAt ??
          (draft.createdAt.isEmpty ? now : draft.createdAt),
      updatedAt: now,
      updatedBy: updatedBy,
      version: existing == null ? 1 : existing.version + 1,
      order: existing?.order ?? data.marriageRelations.length + 1,
      deletedAt: '',
    );

    final relations = [...data.marriageRelations];
    if (existingIndex == -1) {
      relations.add(next);
    } else {
      relations[existingIndex] = next;
    }

    final people = data.people.map((person) {
      if (person.id == first.id) {
        return person.copyWith(
          spouseIds: {...person.spouseIds, second.id}.toList(),
          spouses: {...person.spouses, second.id}.toList(),
        );
      }
      if (person.id == second.id) {
        return person.copyWith(
          spouseIds: {...person.spouseIds, first.id}.toList(),
          spouses: {...person.spouses, first.id}.toList(),
        );
      }
      return person;
    }).toList();

    return data.copyWith(people: people, marriageRelations: relations);
  }

  FamilyTreeData deleteUnion(
    FamilyTreeData data,
    MarriageRelation relation, {
    required String deletedBy,
  }) {
    final now = DateTime.now().toIso8601String();
    return _replace(
      data,
      relation.copyWith(
        deletedAt: now,
        updatedAt: now,
        updatedBy: deletedBy,
        version: relation.version + 1,
      ),
    );
  }

  FamilyTreeData _replace(FamilyTreeData data, MarriageRelation next) {
    return data.copyWith(
      marriageRelations: data.marriageRelations
          .map((relation) => relation.id == next.id ? next : relation)
          .toList(),
    );
  }

  String _id(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}';
}
