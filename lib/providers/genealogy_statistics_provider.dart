import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/genealogy_statistics_service.dart';
import 'family_tree_provider.dart';

final genealogyStatisticsProvider = Provider<GenealogyStatisticsService?>((
  ref,
) {
  final data = ref.watch(familyTreeProvider).value;
  if (data == null) return null;
  return GenealogyStatisticsService(data);
});
