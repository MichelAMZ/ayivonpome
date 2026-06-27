import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../widgets/responsive.dart';
import 'person_detail_screen.dart';

class FamilyHonorHallScreen extends ConsumerWidget {
  const FamilyHonorHallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    final leadership = data.familyLeadership;
    final current = _find(data.people, leadership.currentLeaderPersonId);
    final former = _find(data.people, leadership.formerLeaderPersonId);
    final successor = _find(data.people, leadership.successorPersonId);
    final patriarch = _find(data.people, data.familyHonor.patriarchPersonId);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyHonorHall)),
      body: ResponsivePage(
        children: [
          ResponsiveGrid(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 4,
            spacing: 14,
            mainAxisExtent: 106,
            children: [
              if (current != null)
                _HonorCard(
                  title: l10n.currentChief,
                  person: current,
                  subtitle: leadership.title,
                  authMode: auth.mode,
                ),
              if (former != null)
                _HonorCard(
                  title: l10n.formerChief,
                  person: former,
                  subtitle: l10n.formerChief,
                  authMode: auth.mode,
                ),
              if (successor != null)
                _HonorCard(
                  title: l10n.successor,
                  person: successor,
                  subtitle: l10n.successor,
                  authMode: auth.mode,
                ),
              if (patriarch != null)
                _HonorCard(
                  title: l10n.patriarch,
                  person: patriarch,
                  subtitle: l10n.familyHonor,
                  authMode: auth.mode,
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            l10n.leadershipHistory,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (data.familyLeadershipHistory.isEmpty)
            Text(l10n.emptyState)
          else
            for (final entry in data.familyLeadershipHistory)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF4D6),
                    child: Icon(Icons.workspace_premium),
                  ),
                  title: Text(
                    _find(data.people, entry.personId)?.fullName ??
                        entry.personId,
                  ),
                  subtitle: Text(
                    [
                      entry.title,
                      if (entry.startDate.isNotEmpty) entry.startDate,
                      if (entry.endDate.isNotEmpty) entry.endDate,
                      if (entry.notes.isNotEmpty) entry.notes,
                    ].join(' • '),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Person? _find(List<Person> people, String id) {
    if (id.isEmpty) return null;
    for (final person in people) {
      if (person.id == id) return person;
    }
    return null;
  }
}

class _HonorCard extends StatelessWidget {
  const _HonorCard({
    required this.title,
    required this.person,
    required this.subtitle,
    required this.authMode,
  });

  final String title;
  final Person person;
  final String subtitle;
  final AuthMode authMode;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PersonDetailScreen(personId: person.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFD8F0B5),
                child: Text(_initials(person)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF8B6818),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      person.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(Person person) {
    final first = person.firstName.isEmpty ? '' : person.firstName[0];
    final last = person.lastName.isEmpty ? '' : person.lastName[0];
    final value = '$first$last';
    return value.isEmpty ? '?' : value.toUpperCase();
  }
}
