import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/family_tree_data.dart';
import '../models/person.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../services/family_relation_service.dart';
import 'person_origin_name_text.dart';

class PersonPreviewPopup extends ConsumerWidget {
  const PersonPreviewPopup({
    super.key,
    required this.person,
    required this.data,
    required this.authMode,
    required this.onViewProfile,
    this.maxWidth = 320,
    this.maxHeight,
  });

  final Person person;
  final FamilyTreeData data;
  final AuthMode authMode;
  final VoidCallback onViewProfile;
  final double maxWidth;
  final double? maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final relationService = FamilyRelationService();
    final statistics = ref
        .watch(genealogyStatisticsServiceProvider(data))
        .getStatistics(person.id);
    final father = relationService.fatherOf(data, person);
    final mother = relationService.motherOf(data, person);
    final spouses = relationService.spousesOf(data, person);
    final formerSpouses = ref
        .watch(marriageServiceProvider)
        .getFormerSpouses(data, person);
    final rootAncestor = ref
        .watch(genealogyGenerationServiceProvider)
        .getRootAncestor(data);
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(child: Text(_initials(person))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        PersonOriginNameText(person: person),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (authMode == AuthMode.authenticated) ...[
                _line(
                  l10n.birthDate,
                  _join([person.birthDate, person.birthPlace]),
                ),
                if (person.deathDate.isNotEmpty || person.deathPlace.isNotEmpty)
                  _line(
                    l10n.deathDate,
                    _join([person.deathDate, person.deathPlace]),
                  ),
                _line(l10n.father, father?.fullName ?? ''),
                _line(l10n.mother, mother?.fullName ?? ''),
                _line(
                  l10n.marriedTo,
                  spouses.map((person) => person.fullName).join(', '),
                ),
                if (formerSpouses.isNotEmpty)
                  _line(
                    l10n.formerSpouses,
                    formerSpouses.map((person) => person.fullName).join(', '),
                  ),
                _line(l10n.parents, _names(person.parents)),
                _line(l10n.spouses, _names(person.spouses)),
                _line(l10n.children, _names(person.children)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatBadge(
                      icon: Icons.child_care_outlined,
                      label: l10n.directChildren,
                      value: statistics.directChildrenCount,
                    ),
                    _StatBadge(
                      icon: Icons.account_tree_outlined,
                      label: l10n.totalDescendants,
                      value: statistics.totalDescendantsCount,
                    ),
                    if (person.generation > 0)
                      _StatBadge(
                        icon: Icons.family_restroom_outlined,
                        label: l10n.generation,
                        value: person.generation,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                _line(l10n.firstAncestor, rootAncestor?.fullName ?? ''),
                _line(l10n.familyBranch, person.familyCode),
                if (person.history.isNotEmpty)
                  _line(l10n.history, person.history.first.description),
              ] else ...[
                _StatBadge(
                  icon: Icons.account_tree_outlined,
                  label: l10n.descendants,
                  value: statistics.totalDescendantsCount,
                ),
                if (person.generation > 0) ...[
                  const SizedBox(height: 8),
                  _line(l10n.generation, person.generation.toString()),
                ],
                if (person.privacy.showMapInPublicMode &&
                    person.publicMapLocation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _line(l10n.googleMaps, person.publicMapLocation),
                ],
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onViewProfile,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.viewFullProfile),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _names(List<String> ids) {
    final values = ids
        .map((id) => data.people.where((person) => person.id == id).firstOrNull)
        .whereType<Person>()
        .map((person) => person.fullName)
        .toList();
    return values.isEmpty ? '-' : values.join(', ');
  }

  static Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text('$label: ${value.isEmpty ? '-' : value}'),
  );

  static String _join(List<String> values) =>
      values.where((value) => value.isNotEmpty).join(' - ');

  static String _initials(Person person) {
    final first = person.firstName.isEmpty ? '' : person.firstName[0];
    final last = person.lastName.isEmpty ? '' : person.lastName[0];
    final value = '$first$last';
    return value.isEmpty ? '?' : value.toUpperCase();
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3DE),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCFE1BD)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF4D742B)),
            const SizedBox(width: 5),
            Text(
              '$label : $value',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF35581C),
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
