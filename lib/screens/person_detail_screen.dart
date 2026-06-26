import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../widgets/contact_section.dart';
import '../widgets/location_tile.dart';
import '../widgets/mini_map_card.dart';
import '../widgets/modification_code_required_dialog.dart';
import '../widgets/notify_person_button.dart';
import 'person_edit_screen.dart';

class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(familyTreeProvider).value!;
    final auth = ref.watch(authSessionProvider);
    final authenticated = auth.isAuthenticated;
    final person = data.people.firstWhere((item) => item.id == personId);
    final relationService = ref.watch(familyRelationServiceProvider);
    final father = relationService.fatherOf(data, person);
    final mother = relationService.motherOf(data, person);
    final spouses = relationService.spousesOf(data, person);
    final children = relationService.childrenOf(data, person);
    final siblings = relationService.siblingsOf(data, person);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.personDetails),
        actions: [
          if (_hasVisibleLocation(person, authenticated))
            IconButton(
              tooltip: l10n.googleMaps,
              icon: const Icon(Icons.location_on_outlined),
              onPressed: () => ref.read(mapServiceProvider).openInGoogleMaps(
                    address: authenticated
                        ? (person.currentAddress.isNotEmpty
                            ? person.currentAddress
                            : person.birthPlace)
                        : person.publicMapLocation,
                    latitude: authenticated ? person.latitude : null,
                    longitude: authenticated ? person.longitude : null,
                  ),
            ),
          if (authenticated)
            IconButton(
              tooltip: l10n.edit,
              icon: const Icon(Icons.edit),
              onPressed: () => _requestModificationThen(
                context,
                ref,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PersonEditScreen(person: person),
                  ),
                ),
              ),
            ),
          if (authenticated)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _requestModificationThen(
                context,
                ref,
                () => _delete(context, ref, person),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  person.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!authenticated) ...[
            if (person.privacy.showMapInPublicMode &&
                person.publicMapLocation.isNotEmpty)
              LocationTile(
                label: l10n.googleMaps,
                address: person.publicMapLocation,
              ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n.publicLimitedMode),
                subtitle: Text(l10n.publicLimitedModeDescription),
              ),
            ),
          ] else ...[
            ContactSection(person: person, session: auth.session),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: NotifyPersonButton(person: person, people: data.people),
            ),
            const SizedBox(height: 12),
            _Tile(label: l10n.gender, value: person.gender),
            _Tile(label: l10n.birthDate, value: person.birthDate),
            MiniMapCard(
              address: person.currentAddress.isNotEmpty
                  ? person.currentAddress
                  : person.birthPlace,
              latitude: person.latitude,
              longitude: person.longitude,
            ),
            LocationTile(
              label: l10n.currentAddress,
              address: person.currentAddress,
              latitude: person.latitude,
              longitude: person.longitude,
            ),
            LocationTile(label: l10n.birthPlace, address: person.birthPlace),
            _Tile(label: l10n.deathDate, value: person.deathDate),
            LocationTile(label: l10n.deathPlace, address: person.deathPlace),
            LocationTile(label: l10n.burialPlace, address: person.burialPlace),
            const SizedBox(height: 12),
            Text(
              l10n.familyRelationships,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _Tile(label: l10n.father, value: father?.fullName ?? ''),
            _Tile(label: l10n.mother, value: mother?.fullName ?? ''),
            _Tile(label: l10n.marriedTo, value: _namesFromPeople(spouses)),
            _Tile(label: l10n.children, value: _namesFromPeople(children)),
            _Tile(label: l10n.siblings, value: _namesFromPeople(siblings)),
            _Tile(label: l10n.familyBranch, value: person.familyCode),
            _Tile(label: l10n.notes, value: person.notes),
            if (person.importantPlaces.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.importantPlaces,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...person.importantPlaces.map(
                (place) => LocationTile(
                  label: place.name.isEmpty ? l10n.importantPlaces : place.name,
                  address: place.address,
                  latitude: place.latitude,
                  longitude: place.longitude,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(l10n.history, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (person.history.isEmpty)
              Text(l10n.emptyState)
            else
              ...person.history.map(
                (event) => Card(
                  child: ListTile(
                    title: Text(event.title.isEmpty ? event.date : event.title),
                    subtitle: Text(
                      [event.date, event.place, event.description]
                          .where((item) => item.isNotEmpty)
                          .join('\n'),
                    ),
                    trailing: event.place.isEmpty &&
                            (event.latitude == null || event.longitude == null)
                        ? null
                        : IconButton(
                            tooltip: l10n.googleMaps,
                            icon: const Icon(Icons.map_outlined),
                            onPressed: () =>
                                ref.read(mapServiceProvider).openInGoogleMaps(
                                      address: event.place,
                                      latitude: event.latitude,
                                      longitude: event.longitude,
                                    ),
                          ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Person person) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(person.fullName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(familyTreeProvider.notifier).deletePerson(person.id);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _requestModificationThen(
    BuildContext context,
    WidgetRef ref,
    VoidCallback action,
  ) async {
    final auth = ref.read(authSessionProvider);
    if (auth.canModify) {
      action();
      return;
    }
    await ref.read(familyTreeProvider.notifier).addAuditLog(
          'modification_code_required',
          actorRole: auth.session?.role ?? 'viewer',
          personId: personId,
          description:
              'L’utilisateur a demandé une modification sans code de modification.',
        );
    if (!context.mounted) return;
    final unlocked = await showDialog<bool>(
      context: context,
      builder: (context) => const ModificationCodeRequiredDialog(),
    );
    if (unlocked == true && context.mounted) {
      action();
    }
  }

  String _namesFromPeople(List<Person> people) {
    if (people.isEmpty) return '-';
    return people.map((person) => person.fullName).join(', ');
  }

  bool _hasVisibleLocation(Person person, bool authenticated) {
    if (!authenticated) {
      return person.privacy.showMapInPublicMode &&
          person.publicMapLocation.isNotEmpty;
    }
    return person.currentAddress.isNotEmpty ||
        person.birthPlace.isNotEmpty ||
        person.deathPlace.isNotEmpty ||
        person.burialPlace.isNotEmpty ||
        (person.latitude != null && person.longitude != null) ||
        person.importantPlaces.isNotEmpty;
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value.isEmpty ? '-' : value),
      ),
    );
  }
}
