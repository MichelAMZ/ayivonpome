import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/family_tree_provider.dart';
import '../widgets/bug_report_card.dart';

class BugReportsScreen extends ConsumerWidget {
  const BugReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(familyTreeProvider).value!;
    final service = ref.watch(bugReportServiceProvider);
    final bugs = service.filter(data);
    return Scaffold(
      appBar: AppBar(title: const Text('Bugs signalés')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [for (final bug in bugs) BugReportCard(bug: bug)],
      ),
    );
  }
}
