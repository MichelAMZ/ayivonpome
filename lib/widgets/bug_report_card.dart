import 'package:flutter/material.dart';

import '../models/bug_report.dart';

class BugReportCard extends StatelessWidget {
  const BugReportCard({
    super.key,
    required this.bug,
    this.onInProgress,
    this.onResolved,
    this.onDelete,
    this.onContact,
  });

  final BugReport bug;
  final VoidCallback? onInProgress;
  final VoidCallback? onResolved;
  final VoidCallback? onDelete;
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _priorityColor(bug.priority).withValues(alpha: 0.14),
          child: Icon(
            Icons.bug_report_outlined,
            color: _priorityColor(bug.priority),
          ),
        ),
        title: Text(bug.title),
        subtitle: Text(
          [
            bug.description,
            '${bug.screen} · ${bug.priority} · ${bug.status}',
            if (bug.reportedByName.isNotEmpty) bug.reportedByName,
            bug.createdAt,
          ].where((value) => value.isNotEmpty).join('\n'),
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 2,
          children: [
            IconButton(
              tooltip: 'En cours',
              onPressed: onInProgress,
              icon: const Icon(Icons.pending_actions_outlined),
            ),
            IconButton(
              tooltip: 'Résolu',
              onPressed: onResolved,
              icon: const Icon(Icons.check_circle_outline),
            ),
            IconButton(
              tooltip: 'Contacter',
              onPressed: onContact,
              icon: const Icon(Icons.chat_outlined),
            ),
            IconButton(
              tooltip: 'Supprimer',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String value) {
    return switch (value) {
      'urgent' => const Color(0xFFD32F2F),
      'high' => const Color(0xFFE67E22),
      'medium' => const Color(0xFF2F80ED),
      _ => const Color(0xFF6B7280),
    };
  }
}
