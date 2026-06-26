import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/family_tree_data.dart';
import '../models/person.dart';
import '../providers/auth_provider.dart';
import '../services/family_relation_service.dart';

class PersonPreviewPopup extends StatelessWidget {
  const PersonPreviewPopup({
    super.key,
    required this.person,
    required this.data,
    required this.authMode,
    required this.onViewProfile,
  });

  final Person person;
  final FamilyTreeData data;
  final AuthMode authMode;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final relationService = FamilyRelationService();
    final father = relationService.fatherOf(data, person);
    final mother = relationService.motherOf(data, person);
    final spouses = relationService.spousesOf(data, person);
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
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
                    child: Text(
                      person.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (authMode == AuthMode.authenticated) ...[
                _line(l10n.birthDate, _join([person.birthDate, person.birthPlace])),
                if (person.deathDate.isNotEmpty || person.deathPlace.isNotEmpty)
                  _line(l10n.deathDate, _join([person.deathDate, person.deathPlace])),
                _line(l10n.father, father?.fullName ?? ''),
                _line(l10n.mother, mother?.fullName ?? ''),
                _line(
                  l10n.marriedTo,
                  spouses.map((person) => person.fullName).join(', '),
                ),
                _line(l10n.parents, _names(person.parents)),
                _line(l10n.spouses, _names(person.spouses)),
                _line(l10n.children, _names(person.children)),
                _line(l10n.familyBranch, person.familyCode),
                if (person.history.isNotEmpty)
                  _line(l10n.history, person.history.first.description),
              ] else if (person.privacy.showMapInPublicMode &&
                  person.publicMapLocation.isNotEmpty)
                _line(l10n.googleMaps, person.publicMapLocation),
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
