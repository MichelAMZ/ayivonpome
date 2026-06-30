import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/family_tree_provider.dart';

class FamilyHistoryScreen extends ConsumerWidget {
  const FamilyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value;
    final history = data?.familyGeneralHistory;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFCF7),
      appBar: AppBar(title: Text(l10n.ourHistory)),
      body: history == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8DDBE)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          history.title.trim().isEmpty
                              ? l10n.generalFamilyHistory
                              : history.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          history.content.trim().isEmpty
                              ? l10n.familyHistory
                              : history.content,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.45),
                        ),
                        if (history.lastUpdatedAt.isNotEmpty ||
                            history.lastUpdatedByName.isNotEmpty) ...[
                          const Divider(height: 36),
                          Wrap(
                            spacing: 18,
                            runSpacing: 8,
                            children: [
                              if (history.lastUpdatedByName.isNotEmpty)
                                Text(
                                  '${l10n.lastUpdatedBy}: ${history.lastUpdatedByName}',
                                ),
                              if (history.lastUpdatedAt.isNotEmpty)
                                Text(
                                  '${l10n.lastUpdatedAt}: ${history.lastUpdatedAt}',
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
