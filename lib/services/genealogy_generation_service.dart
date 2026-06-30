import '../models/family_tree_data.dart';
import '../models/person.dart';
import 'genealogy_layout_service.dart';

class GenealogyGenerationService {
  const GenealogyGenerationService({
    this.layoutService = const GenealogyLayoutService(),
  });

  final GenealogyLayoutService layoutService;

  Person? getRootAncestor(FamilyTreeData data) {
    if (data.people.isEmpty) return null;
    final generations = computeAllGenerations(data);
    final ordered = [...data.people]
      ..sort((a, b) {
        final generationCompare = (generations[a.id] ?? 0).compareTo(
          generations[b.id] ?? 0,
        );
        if (generationCompare != 0) return generationCompare;
        return data.people.indexOf(a).compareTo(data.people.indexOf(b));
      });
    return ordered.first;
  }

  int computeGeneration(FamilyTreeData data, Person person) {
    return computeAllGenerations(data)[person.id] ?? 0;
  }

  Map<String, int> computeAllGenerations(FamilyTreeData data) {
    final layoutGenerations = layoutService.computeGenerations(data);
    return {
      for (final entry in layoutGenerations.entries) entry.key: entry.value + 1,
    };
  }

  FamilyTreeData recalculate(FamilyTreeData data) {
    final generations = computeAllGenerations(data);
    var changed = false;
    final people = data.people.map((person) {
      final generation = generations[person.id] ?? 0;
      if (person.generation == generation) return person;
      changed = true;
      return person.copyWith(generation: generation);
    }).toList();
    return changed ? data.copyWith(people: people) : data;
  }

  int generationDistance(Person first, Person second) {
    if (first.generation <= 0 || second.generation <= 0) return 0;
    return (first.generation - second.generation).abs();
  }
}
