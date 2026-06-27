import '../models/family_tree_data.dart';
import '../models/person.dart';
import 'family_relation_service.dart';

class GenealogyStatistics {
  const GenealogyStatistics({
    required this.directChildrenCount,
    required this.totalDescendantsCount,
    required this.descendants,
  });

  final int directChildrenCount;
  final int totalDescendantsCount;
  final List<Person> descendants;
}

class GenealogyStatisticsService {
  GenealogyStatisticsService(
    this.data, {
    FamilyRelationService? relationService,
  }) : _relationService = relationService ?? FamilyRelationService();

  final FamilyTreeData data;
  final FamilyRelationService _relationService;
  final Map<String, GenealogyStatistics> _cache = {};

  int getDirectChildrenCount(String personId) =>
      getStatistics(personId).directChildrenCount;

  int getTotalDescendantsCount(String personId) =>
      getStatistics(personId).totalDescendantsCount;

  List<Person> getAllDescendants(String personId) =>
      getStatistics(personId).descendants;

  GenealogyStatistics getStatistics(String personId) {
    return _cache.putIfAbsent(personId, () {
      final person = _byId(personId);
      if (person == null) {
        return const GenealogyStatistics(
          directChildrenCount: 0,
          totalDescendantsCount: 0,
          descendants: [],
        );
      }

      final directChildren = _relationService.childrenOf(data, person);
      final descendants = <Person>[];
      final visitedPersonIds = <String>{personId};
      final stack = [...directChildren.reversed];

      while (stack.isNotEmpty) {
        final current = stack.removeLast();
        if (!visitedPersonIds.add(current.id)) continue;
        descendants.add(current);
        final children = _relationService.childrenOf(data, current);
        stack.addAll(children.reversed);
      }

      return GenealogyStatistics(
        directChildrenCount: directChildren.length,
        totalDescendantsCount: descendants.length,
        descendants: List.unmodifiable(descendants),
      );
    });
  }

  Person? _byId(String personId) {
    for (final person in data.people) {
      if (person.id == personId) return person;
    }
    return null;
  }
}
