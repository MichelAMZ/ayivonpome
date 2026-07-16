import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../widgets/contact_section.dart';
import '../widgets/location_tile.dart';
import '../widgets/mini_map_card.dart';
import '../widgets/modification_code_required_dialog.dart';
import '../widgets/notify_person_button.dart';
import '../widgets/person_origin_name_text.dart';
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
    final marriageRelations = ref
        .watch(marriageServiceProvider)
        .relationsFor(data, person.id);
    final peopleById = {for (final item in data.people) item.id: item};
    final children = relationService.childrenOf(data, person);
    final siblings = relationService.siblingsOf(data, person);
    final rootAncestor = ref
        .watch(genealogyGenerationServiceProvider)
        .getRootAncestor(data);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.personDetails),
        actions: [
          if (_hasVisibleLocation(person, authenticated))
            IconButton(
              tooltip: l10n.googleMaps,
              icon: const Icon(Icons.location_on_outlined),
              onPressed: () => ref
                  .read(mapServiceProvider)
                  .openInGoogleMaps(
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
              CircleAvatar(
                radius: 36,
                backgroundImage:
                    (authenticated || person.privacy.photoVisible) &&
                        person.photo.isNotEmpty
                    ? NetworkImage(person.photo)
                    : null,
                child:
                    (authenticated || person.privacy.photoVisible) &&
                        person.photo.isNotEmpty
                    ? null
                    : const Icon(Icons.person, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    PersonOriginNameText(
                      person: person,
                      fontSize: 14,
                      topPadding: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!authenticated) ...[
            if (person.publicMapLocation.isNotEmpty)
              LocationTile(
                label: l10n.googleMaps,
                address: person.publicMapLocation,
              ),
            if (person.privacy.genderVisible)
              _Tile(label: l10n.gender, value: person.gender),
            if (person.privacy.birthLastNameVisible &&
                person.shouldShowOriginLastName)
              _Tile(label: l10n.bornLastName, value: person.originLastName),
            if (person.privacy.birthDateVisible)
              _Tile(label: l10n.birthDate, value: person.birthDate),
            if (person.privacy.showBirthPlaceInPublicMode)
              LocationTile(label: l10n.birthPlace, address: person.birthPlace),
            if (person.privacy.deathDateVisible)
              _Tile(label: l10n.deathDate, value: person.deathDate),
            if (person.privacy.deathPlaceVisible)
              LocationTile(label: l10n.deathPlace, address: person.deathPlace),
            if (person.privacy.burialPlaceVisible)
              LocationTile(
                label: l10n.burialPlace,
                address: person.burialPlace,
              ),
            if (person.privacy.showCurrentAddressInPublicMode)
              LocationTile(
                label: l10n.currentAddress,
                address: person.currentAddress,
                latitude: person.privacy.privateCoordinatesVisible
                    ? person.latitude
                    : null,
                longitude: person.privacy.privateCoordinatesVisible
                    ? person.longitude
                    : null,
              ),
            if (person.privacy.familyRelationsVisible) ...[
              const SizedBox(height: 12),
              Text(
                l10n.familyRelationships,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              _Tile(label: l10n.father, value: father?.fullName ?? ''),
              _Tile(label: l10n.mother, value: mother?.fullName ?? ''),
              _Tile(label: l10n.marriedTo, value: _namesFromPeople(spouses)),
              _Tile(label: l10n.children, value: _namesFromPeople(children)),
            ],
            if (person.privacy.familyBranchVisible)
              _Tile(label: l10n.familyBranch, value: person.familyCode),
            if (person.privacy.emailVisible ||
                person.privacy.phoneVisible ||
                person.privacy.whatsappVisible)
              ContactSection(
                person: person.copyWith(
                  email: person.privacy.emailVisible ? person.email : '',
                  emailVisibility: person.privacy.emailVisible
                      ? 'public'
                      : person.emailVisibility,
                  phoneNumber: person.privacy.phoneVisible
                      ? person.phoneNumber
                      : '',
                  phoneVisibility: person.privacy.phoneVisible
                      ? 'public'
                      : person.phoneVisibility,
                  whatsappNumber: person.privacy.whatsappVisible
                      ? person.whatsappNumber
                      : '',
                  whatsappVisibility: person.privacy.whatsappVisible
                      ? 'public'
                      : person.whatsappVisibility,
                ),
                session: auth.session,
              ),
            if (person.privacy.notesVisible)
              _Tile(label: l10n.notes, value: person.notes),
            if (person.privacy.showHistoryInPublicMode) ...[
              const SizedBox(height: 12),
              Text(l10n.history, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (person.history.isEmpty)
                Text(l10n.emptyState)
              else
                ...person.history.map(
                  (event) => Card(
                    child: ListTile(
                      title: Text(
                        event.title.isEmpty ? event.date : event.title,
                      ),
                      subtitle: Text(
                        [
                          event.date,
                          event.place,
                          event.description,
                        ].where((item) => item.isNotEmpty).join('\n'),
                      ),
                    ),
                  ),
                ),
            ],
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
            if (person.generation > 0)
              _Tile(
                label: l10n.generation,
                value: person.generation.toString(),
              ),
            _Tile(
              label: l10n.firstAncestor,
              value: rootAncestor?.fullName ?? '',
            ),
            if (person.shouldShowOriginLastName)
              _Tile(label: l10n.bornLastName, value: person.originLastName),
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
            if (marriageRelations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.spouses, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final relation in marriageRelations)
                _UnionTile(
                  relation: relation,
                  partner: peopleById[relation.partnerOf(person.id)],
                ),
            ],
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
                      [
                        event.date,
                        event.place,
                        event.description,
                      ].where((item) => item.isNotEmpty).join('\n'),
                    ),
                    trailing:
                        event.place.isEmpty &&
                            (event.latitude == null || event.longitude == null)
                        ? null
                        : IconButton(
                            tooltip: l10n.googleMaps,
                            icon: const Icon(Icons.map_outlined),
                            onPressed: () => ref
                                .read(mapServiceProvider)
                                .openInGoogleMaps(
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

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Person person,
  ) async {
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
    await ref
        .read(familyTreeProvider.notifier)
        .addAuditLog(
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
      return person.publicMapLocation.isNotEmpty;
    }
    return person.currentAddress.isNotEmpty ||
        person.birthPlace.isNotEmpty ||
        person.deathPlace.isNotEmpty ||
        person.burialPlace.isNotEmpty ||
        (person.latitude != null && person.longitude != null) ||
        person.importantPlaces.isNotEmpty;
  }
}

class _UnionTile extends StatelessWidget {
  const _UnionTile({required this.relation, required this.partner});

  final MarriageRelation relation;
  final Person? partner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = [
      _typeLabel(l10n, relation.marriageType),
      _statusLabel(l10n, relation.status),
      if (relation.traditionalMarriageDate.isNotEmpty)
        relation.traditionalMarriageDate,
      if (relation.marriagePlace.isNotEmpty) relation.marriagePlace,
    ].where((value) => value.isNotEmpty).join(' · ');
    return Card(
      child: ListTile(
        leading: Icon(
          relation.marriageType == 'traditional'
              ? Icons.diamond_outlined
              : Icons.favorite_border,
        ),
        title: Text(partner?.fullName ?? '-'),
        subtitle: Text(details.isEmpty ? '-' : details),
        trailing: partner == null ? null : const Icon(Icons.chevron_right),
        onTap: partner == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PersonDetailScreen(personId: partner!.id),
                ),
              ),
      ),
    );
  }

  String _typeLabel(AppLocalizations l10n, String type) {
    return switch (type) {
      'traditional' => l10n.traditionalMarriage,
      'civil' => l10n.civilMarriage,
      'religious' => l10n.religiousMarriage,
      'customaryAndCivil' =>
        '${l10n.traditionalMarriage} + ${l10n.civilMarriage}',
      'customaryCivilAndReligious' =>
        '${l10n.traditionalMarriage} + ${l10n.civilMarriage} + ${l10n.religiousMarriage}',
      'freeUnion' => l10n.freeUnion,
      _ => l10n.unknown,
    };
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'active' => l10n.activeUnion,
      'separated' => l10n.separated,
      'divorced' => l10n.divorced,
      'endedByDeath' => l10n.endedByDeath,
      _ => '',
    };
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
