import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/family_tree_provider.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(familyTreeProvider).value;
    if (data == null || !data.syncSettings.databaseEnabled) {
      return const SizedBox.shrink();
    }
    final pendingCount = data.pendingSyncQueue
        .where((item) => item.status != 'synced' && item.status != 'resolved')
        .length;
    final rawStatus =
        pendingCount > 0 && data.syncSettings.syncStatus == 'synced'
        ? 'pending'
        : data.syncSettings.syncStatus;
    final status = rawStatus == 'error' && pendingCount > 0
        ? 'pending'
        : rawStatus;
    final label = switch (status) {
      'synced' => 'Synchronisé',
      'offline' => 'Hors ligne',
      'syncing' => 'Synchronisation en cours',
      'pending' => 'Synchronisation en attente',
      _ => pendingCount > 0 ? 'Synchronisation en attente' : 'Synchronisé',
    };
    final icon = switch (status) {
      'synced' => Icons.cloud_done_outlined,
      'offline' => Icons.cloud_off_outlined,
      'syncing' => Icons.sync_outlined,
      'pending' => Icons.sync_outlined,
      _ => pendingCount > 0 ? Icons.sync_outlined : Icons.cloud_done_outlined,
    };
    final color = switch (status) {
      'synced' => const Color(0xFF2E7D32),
      'offline' => const Color(0xFF6D6F75),
      'syncing' => const Color(0xFF1565C0),
      'pending' => const Color(0xFF9A6A00),
      _ => pendingCount > 0 ? const Color(0xFF9A6A00) : const Color(0xFF2E7D32),
    };
    final displayLabel = pendingCount == 0 ? label : '$label ($pendingCount)';

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Tooltip(
          message: pendingCount == 0
              ? label
              : '$label - $pendingCount modification(s)',
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              border: Border.all(color: color.withValues(alpha: 0.28)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width - 82,
                    ),
                    child: Text(
                      displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
