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
              relation.personId == personId || relation.spouseId == personId,
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

  FamilyTreeData _replace(FamilyTreeData data, MarriageRelation next) {
    return data.copyWith(
      marriageRelations: data.marriageRelations
          .map((relation) => relation.id == next.id ? next : relation)
          .toList(),
    );
  }
}
