import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../providers/family_tree_provider.dart';
import '../widgets/admin_contact_card.dart';
import '../widgets/kpi_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
    final kpi = ref.watch(kpiServiceProvider).compute(data);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminDashboard)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.adminKpi, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              KpiCard(label: l10n.totalPeople, value: kpi.totalPeople),
              KpiCard(
                label: l10n.personAddedThisMonth,
                value: kpi.peopleAddedThisMonth,
              ),
              KpiCard(
                label: l10n.personModifiedThisMonth,
                value: kpi.peopleModifiedThisMonth,
              ),
              KpiCard(label: l10n.familiesCount, value: kpi.linkedFamilies),
              KpiCard(label: l10n.pendingCount, value: kpi.pendingFamilyLinks),
              KpiCard(label: l10n.activeCodes, value: kpi.activeCodes),
              KpiCard(label: l10n.expiredCodes, value: kpi.expiredCodes),
              KpiCard(label: l10n.activityLog, value: data.auditLog.length),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.manageAdmins, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...data.admins.map((admin) => AdminContactCard(admin: admin)),
          const SizedBox(height: 24),
          Text(
            l10n.manageModificationCodes,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...data.modificationCodes.map(
            (code) => Card(
              child: ListTile(
                leading: const Icon(Icons.key_outlined),
                title: Text(code.label),
                subtitle: Text(
                  '${code.code}\n${code.enabled ? l10n.accepted : l10n.refused}',
                ),
                trailing: Text('${code.usedCount}/${code.maxUses ?? '∞'}'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.activityLog, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...data.auditLog.reversed.take(30).map(
                (log) => Card(
                  child: ListTile(
                    title: Text(log.action),
                    subtitle: Text(
                      [log.date, log.actorRole, log.description]
                          .where((value) => value.isNotEmpty)
                          .join('\n'),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
