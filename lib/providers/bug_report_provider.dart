import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bug_report.dart';
import 'family_tree_provider.dart';

final bugReportsProvider = Provider<List<BugReport>>((ref) {
  final data = ref.watch(familyTreeProvider).value;
  return data?.bugReports ?? const [];
});
