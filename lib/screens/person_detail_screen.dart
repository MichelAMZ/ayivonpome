import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/family_tree_data.dart';
import '../models/history_event.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../widgets/contact_section.dart';
import '../widgets/mini_map_card.dart';
import '../widgets/member_deletion_dialog.dart';
import '../widgets/modification_code_required_dialog.dart';
import '../widgets/notify_person_button.dart';
import 'person_detail_formatters.dart';
import 'person_edit_screen.dart';

const _pageBackground = Color(0xFFF6F5F1);
const _nightBlue = Color(0xFF173B57);
const _primaryBlue = Color(0xFF2F6FA3);
const _slateText = Color(0xFF52606D);
const _olive = Color(0xFF58752B);

class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncData = ref.watch(familyTreeProvider);
    return asyncData.when(
      loading: () => Scaffold(
        appBar: _ProfileAppBar(
          title: l10n.personDetails,
          canShowLocation: false,
          canEdit: false,
          onOpenLocation: null,
          onEdit: null,
          onDelete: null,
        ),
        backgroundColor: _pageBackground,
        body: const _ProfileLoadingSkeleton(),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: _ProfileAppBar(
          title: l10n.personDetails,
          canShowLocation: false,
          canEdit: false,
          onOpenLocation: null,
          onEdit: null,
          onDelete: null,
        ),
        backgroundColor: _pageBackground,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _ProfileCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: _primaryBlue,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.profileLoadError,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text('$error', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(familyTreeProvider),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (data) {
        final person = data.people
            .where((item) => item.id == personId)
            .firstOrNull;
        if (person == null) {
          return Scaffold(
            appBar: _ProfileAppBar(
              title: l10n.personDetails,
              canShowLocation: false,
              canEdit: false,
              onOpenLocation: null,
              onEdit: null,
              onDelete: null,
            ),
            backgroundColor: _pageBackground,
            body: Center(child: _ProfileCard(child: Text(l10n.emptyState))),
          );
        }
        return _LoadedPersonDetail(data: data, person: person);
      },
    );
  }
}

class _LoadedPersonDetail extends ConsumerWidget {
  const _LoadedPersonDetail({required this.data, required this.person});

  final FamilyTreeData data;
  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authSessionProvider);
    final authenticated = auth.isAuthenticated;
    final relationService = ref.watch(familyRelationServiceProvider);
    final father = relationService.fatherOf(data, person);
    final mother = relationService.motherOf(data, person);
    final spouses = relationService.spousesOf(data, person);
    final children = relationService.childrenOf(data, person);
    final siblings = relationService.siblingsOf(data, person);
    final rootAncestor = ref
        .watch(genealogyGenerationServiceProvider)
        .getRootAncestor(data);
    final marriageRelations = ref
        .watch(marriageServiceProvider)
        .relationsFor(data, person.id);
    final peopleById = {for (final item in data.people) item.id: item};
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final display = _ProfileDisplay(context, person, authenticated, localeName);

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: _ProfileAppBar(
        title: l10n.personDetails,
        canShowLocation: display.hasMapLocation,
        canEdit: authenticated,
        onOpenLocation: display.hasMapLocation
            ? () => _openPersonLocation(context, ref, display, authenticated)
            : null,
        onEdit: authenticated
            ? () => _requestModificationThen(
                context,
                ref,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PersonEditScreen(person: person),
                  ),
                ),
              )
            : null,
        onDelete: auth.canSecurelyDeleteMember
            ? () => _delete(context, ref, person)
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                children: [
                  _MemberProfileHeader(
                    person: person,
                    display: display,
                    canEdit: authenticated,
                    onEdit: authenticated
                        ? () => _requestModificationThen(
                            context,
                            ref,
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PersonEditScreen(person: person),
                              ),
                            ),
                          )
                        : null,
                    onViewTree: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 900;
                      final left = Column(
                        children: [
                          ProfileInfoCard(
                            items: [
                              ProfileInfoItemData(
                                icon: Icons.male,
                                label: l10n.gender,
                                value: display.gender,
                              ),
                              ProfileInfoItemData(
                                icon: Icons.calendar_month,
                                label: l10n.birthDate,
                                value: display.birthDate,
                              ),
                              ProfileInfoItemData(
                                icon: Icons.groups,
                                label: l10n.generation,
                                value: person.generation > 0
                                    ? person.generation.toString()
                                    : '',
                              ),
                              ProfileInfoItemData(
                                icon: Icons.account_tree_outlined,
                                label: l10n.familyBranch,
                                value: display.familyBranch,
                              ),
                              ProfileInfoItemData(
                                icon: Icons.hub_outlined,
                                label: l10n.firstAncestor,
                                value: rootAncestor?.fullName ?? '',
                              ),
                              if (display.originLastName.isNotEmpty)
                                ProfileInfoItemData(
                                  icon: Icons.badge_outlined,
                                  label: l10n.bornLastName,
                                  value: display.originLastName,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          RelationshipCard(
                            father: father,
                            mother: mother,
                            spouses: spouses,
                            children: children,
                            siblings: siblings,
                            showRelations: display.showRelations,
                          ),
                          const SizedBox(height: 16),
                          MemberHistoryCard(
                            events: display.showHistory
                                ? person.history
                                : const [],
                          ),
                        ],
                      );
                      final right = Column(
                        children: [
                          _MemberLocationCard(display: display),
                          const SizedBox(height: 16),
                          _EventsAndPlacesCard(display: display),
                          const SizedBox(height: 16),
                          MemberNotesCard(note: display.notes),
                          if (authenticated) ...[
                            const SizedBox(height: 16),
                            ContactSection(
                              person: person,
                              session: auth.session,
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: NotifyPersonButton(
                                person: person,
                                people: data.people,
                              ),
                            ),
                          ] else
                            const SizedBox.shrink(),
                          if (marriageRelations.isNotEmpty &&
                              display.showRelations) ...[
                            const SizedBox(height: 16),
                            _MarriageRelationsCard(
                              relations: marriageRelations,
                              peopleById: peopleById,
                            ),
                          ],
                        ],
                      );
                      if (!twoColumns) {
                        return Column(
                          children: [left, const SizedBox(height: 16), right],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: left),
                          const SizedBox(width: 16),
                          Expanded(flex: 4, child: right),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Person person,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MemberDeletionDialog(
        person: person,
        data: data,
        onDelete: () =>
            ref.read(familyTreeProvider.notifier).deletePerson(person.id),
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le membre a été supprimé.')),
      );
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
          personId: person.id,
          description:
              'L’utilisateur a demandé une modification sans code de modification.',
        );
    if (!context.mounted) return;
    final unlocked = await showDialog<bool>(
      context: context,
      builder: (context) => const ModificationCodeRequiredDialog(),
    );
    if (unlocked == true && context.mounted) action();
  }

  Future<void> _openPersonLocation(
    BuildContext context,
    WidgetRef ref,
    _ProfileDisplay display,
    bool authenticated,
  ) async {
    await ref
        .read(mapServiceProvider)
        .openInGoogleMaps(
          address: authenticated
              ? (display.currentAddress.isNotEmpty
                    ? display.currentAddress
                    : display.birthPlace)
              : display.publicMapLocation,
          latitude: authenticated || display.canShowPrivateCoordinates
              ? person.latitude
              : null,
          longitude: authenticated || display.canShowPrivateCoordinates
              ? person.longitude
              : null,
        );
  }
}

class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileAppBar({
    required this.title,
    required this.canShowLocation,
    required this.canEdit,
    required this.onOpenLocation,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final bool canShowLocation;
  final bool canEdit;
  final VoidCallback? onOpenLocation;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBar(
      backgroundColor: _nightBlue,
      foregroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      title: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 420) return Text(title);
          return Row(
            children: [
              Text(
                l10n.familyTree,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('/', style: TextStyle(color: Colors.white70)),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
      centerTitle: true,
      actions: [
        if (canShowLocation)
          Semantics(
            label: l10n.googleMaps,
            button: true,
            child: IconButton(
              tooltip: l10n.googleMaps,
              onPressed: onOpenLocation,
              icon: const Icon(Icons.location_on_outlined),
            ),
          ),
        if (canEdit)
          Semantics(
            label: l10n.edit,
            button: true,
            child: IconButton(
              tooltip: l10n.edit,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
        PopupMenuButton<String>(
          tooltip: l10n.moreActions,
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'delete') onDelete?.call();
          },
          itemBuilder: (context) => [
            if (onDelete != null)
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l10n.delete),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MemberProfileHeader extends StatelessWidget {
  const _MemberProfileHeader({
    required this.person,
    required this.display,
    required this.canEdit,
    required this.onEdit,
    required this.onViewTree,
  });

  final Person person;
  final _ProfileDisplay display;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback onViewTree;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 640;
    final avatarBorder = person.isFemale
        ? const Color(0xFFD74D87)
        : _primaryBlue;
    final actionColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canEdit)
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: Text(l10n.editThisPerson),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: _nightBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        if (canEdit) const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onViewTree,
          icon: const Icon(Icons.account_tree_outlined),
          label: Text(l10n.viewInTree),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: _nightBlue,
            side: const BorderSide(color: _nightBlue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
    return _ProfileCard(
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: _ProfileAvatar(
                    person: person,
                    borderColor: avatarBorder,
                  ),
                ),
                const SizedBox(height: 16),
                _HeaderText(display: display),
                const SizedBox(height: 16),
                actionColumn,
              ],
            )
          : Row(
              children: [
                _ProfileAvatar(person: person, borderColor: avatarBorder),
                const SizedBox(width: 24),
                Expanded(child: _HeaderText(display: display)),
                const SizedBox(width: 24),
                SizedBox(width: 320, child: actionColumn),
              ],
            ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText({required this.display});

  final _ProfileDisplay display;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          display.fullName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: _nightBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            if (display.gender.isNotEmpty)
              _ProfileChip(icon: Icons.male, label: display.gender),
            if (display.generationLabel.isNotEmpty)
              _ProfileChip(icon: Icons.groups, label: display.generationLabel),
            if (display.familyBranch.isNotEmpty)
              _ProfileChip(
                icon: Icons.account_tree_outlined,
                label: '${l10n.branchLabel} ${display.familyBranch}',
                accent: _olive,
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (display.birthDate.isNotEmpty)
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 18, color: _primaryBlue),
              const SizedBox(width: 8),
              Flexible(child: Text(l10n.bornOn(display.birthDate))),
            ],
          ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.person, required this.borderColor});

  final Person person;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final showPhoto = person.photo.trim().isNotEmpty;
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 3),
      ),
      padding: const EdgeInsets.all(4),
      child: CircleAvatar(
        backgroundImage: showPhoto ? NetworkImage(person.photo) : null,
        child: showPhoto ? null : const Icon(Icons.person, size: 58),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.icon,
    required this.label,
    this.accent = _primaryBlue,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: accent, size: 18),
      label: Text(label),
      backgroundColor: accent.withValues(alpha: 0.10),
      side: BorderSide.none,
      labelStyle: TextStyle(color: accent, fontWeight: FontWeight.w700),
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key, required this.items});

  final List<ProfileInfoItemData> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _ProfileCard(
      title: l10n.personalInformation,
      icon: Icons.person,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 560 ? 2 : 1;
          return GridView.count(
            crossAxisCount: columns,
            childAspectRatio: columns == 2 ? 4.2 : 5.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 12,
            children: [for (final item in items) ProfileInfoItem(item: item)],
          );
        },
      ),
    );
  }
}

class ProfileInfoItemData {
  const ProfileInfoItemData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class ProfileInfoItem extends StatelessWidget {
  const ProfileInfoItem({super.key, required this.item});

  final ProfileInfoItemData item;

  @override
  Widget build(BuildContext context) {
    final value = item.value.trim().isEmpty
        ? AppLocalizations.of(context).notProvided
        : item.value.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(item.icon, color: _primaryBlue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _slateText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _nightBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RelationshipCard extends StatelessWidget {
  const RelationshipCard({
    super.key,
    required this.father,
    required this.mother,
    required this.spouses,
    required this.children,
    required this.siblings,
    required this.showRelations,
  });

  final Person? father;
  final Person? mother;
  final List<Person> spouses;
  final List<Person> children;
  final List<Person> siblings;
  final bool showRelations;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _ProfileCard(
      title: l10n.familyRelationships,
      icon: Icons.groups,
      child: showRelations
          ? Column(
              children: [
                RelationshipRow(label: l10n.father, person: father),
                RelationshipRow(label: l10n.mother, person: mother),
                for (final spouse in spouses)
                  RelationshipRow(label: l10n.marriedTo, person: spouse),
                _RelationshipGroup(
                  label: l10n.children,
                  people: children,
                  emptyLabel: l10n.noChildrenProvided,
                ),
                _RelationshipGroup(
                  label: l10n.siblings,
                  people: siblings,
                  emptyLabel: l10n.noSiblingsProvided,
                ),
              ],
            )
          : Text(l10n.publicLimitedModeDescription),
    );
  }
}

class _RelationshipGroup extends StatelessWidget {
  const _RelationshipGroup({
    required this.label,
    required this.people,
    required this.emptyLabel,
  });

  final String label;
  final List<Person> people;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return _EmptyRelationshipRow(label: label, value: emptyLabel);
    }
    return Column(
      children: [
        for (final person in people)
          RelationshipRow(label: label, person: person),
      ],
    );
  }
}

class RelationshipRow extends StatelessWidget {
  const RelationshipRow({super.key, required this.label, required this.person});

  final String label;
  final Person? person;

  @override
  Widget build(BuildContext context) {
    if (person == null) {
      return _EmptyRelationshipRow(
        label: label,
        value: AppLocalizations.of(context).notProvided,
      );
    }
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE6E8EB)),
      ),
      child: ListTile(
        minTileHeight: 56,
        leading: CircleAvatar(
          backgroundImage: person!.photo.isEmpty
              ? null
              : NetworkImage(person!.photo),
          child: person!.photo.isEmpty ? Text(_initials(person!)) : null,
        ),
        title: Text(label, style: const TextStyle(color: _slateText)),
        subtitle: Text(
          person!.fullName,
          style: const TextStyle(
            color: _primaryBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PersonDetailScreen(personId: person!.id),
          ),
        ),
      ),
    );
  }
}

class _EmptyRelationshipRow extends StatelessWidget {
  const _EmptyRelationshipRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE6E8EB)),
      ),
      child: ListTile(
        minTileHeight: 52,
        leading: const Icon(Icons.groups_outlined, color: _olive),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(
            color: _slateText,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _MemberLocationCard extends ConsumerWidget {
  const _MemberLocationCard({required this.display});

  final _ProfileDisplay display;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mapAddress = display.mapAddress;
    final hasLocation =
        mapAddress.isNotEmpty ||
        (display.mapLatitude != null && display.mapLongitude != null);
    return _ProfileCard(
      title: l10n.location,
      icon: Icons.location_on,
      child: Column(
        children: [
          if (hasLocation)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MiniMapCard(
                address: mapAddress,
                latitude: display.mapLatitude,
                longitude: display.mapLongitude,
              ),
            )
          else
            _EmptyPanel(
              icon: Icons.map_outlined,
              text: l10n.noLocationAvailable,
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: hasLocation
                  ? () => ref
                        .read(mapServiceProvider)
                        .openInGoogleMaps(
                          address: mapAddress,
                          latitude: display.mapLatitude,
                          longitude: display.mapLongitude,
                        )
                  : null,
              icon: const Icon(Icons.map_outlined),
              label: Text(l10n.viewOnMap),
            ),
          ),
          const SizedBox(height: 10),
          _LocationActionRow(label: l10n.birthPlace, value: display.birthPlace),
          _LocationActionRow(
            label: l10n.currentAddress,
            value: display.currentAddress,
            latitude: display.canShowPrivateCoordinates
                ? display.mapLatitude
                : null,
            longitude: display.canShowPrivateCoordinates
                ? display.mapLongitude
                : null,
          ),
        ],
      ),
    );
  }
}

class _LocationActionRow extends ConsumerWidget {
  const _LocationActionRow({
    required this.label,
    required this.value,
    this.latitude,
    this.longitude,
  });

  final String label;
  final String value;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasValue =
        value.trim().isNotEmpty || (latitude != null && longitude != null);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 48,
      leading: Icon(
        hasValue ? Icons.place_outlined : Icons.home_outlined,
        color: hasValue ? _olive : Colors.grey,
      ),
      title: Text(label),
      subtitle: Text(hasValue ? value.trim() : l10n.notProvidedFeminine),
      trailing: hasValue
          ? Wrap(
              spacing: 4,
              children: [
                IconButton.outlined(
                  tooltip: l10n.googleMaps,
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () => ref
                      .read(mapServiceProvider)
                      .openInGoogleMaps(
                        address: value,
                        latitude: latitude,
                        longitude: longitude,
                      ),
                ),
                IconButton.outlined(
                  tooltip: l10n.copyAddress,
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: value.trim().isEmpty
                      ? null
                      : () => Clipboard.setData(
                          ClipboardData(text: value.trim()),
                        ),
                ),
              ],
            )
          : null,
    );
  }
}

class _EventsAndPlacesCard extends StatelessWidget {
  const _EventsAndPlacesCard({required this.display});

  final _ProfileDisplay display;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _ProfileCard(
      title: l10n.eventsAndPlaces,
      icon: Icons.event_note_outlined,
      child: Column(
        children: [
          _EventInfoRow(
            icon: Icons.event_busy_outlined,
            label: l10n.deathDate,
            value: display.deathDate,
          ),
          _EventInfoRow(
            icon: Icons.location_on_outlined,
            label: l10n.deathPlace,
            value: display.deathPlace,
            isLocation: true,
          ),
          _EventInfoRow(
            icon: Icons.landscape_outlined,
            label: l10n.burialPlace,
            value: display.burialPlace,
            isLocation: true,
          ),
        ],
      ),
    );
  }
}

class _EventInfoRow extends StatelessWidget {
  const _EventInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLocation = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasValue = value.trim().isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 52,
      leading: Icon(icon, color: hasValue ? _olive : Colors.grey),
      title: Text(label),
      trailing: Text(
        hasValue ? value : l10n.notProvided,
        style: TextStyle(
          color: hasValue ? _nightBlue : _slateText,
          fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
          fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

class MemberHistoryCard extends StatelessWidget {
  const MemberHistoryCard({super.key, required this.events});

  final List<HistoryEvent> events;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sorted = [...events]..sort((a, b) => a.date.compareTo(b.date));
    return _ProfileCard(
      title: l10n.history,
      icon: Icons.history,
      child: sorted.isEmpty
          ? _EmptyPanel(
              icon: Icons.history_toggle_off,
              text: l10n.noHistoryEvents,
              detail: l10n.noHistoryEventsHelp,
            )
          : Column(
              children: [
                for (final event in sorted) _TimelineEvent(event: event),
              ],
            ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  const _TimelineEvent({required this.event});

  final HistoryEvent event;

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final date = formatProfileDate(event.date, localeName);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const Icon(Icons.circle, color: _primaryBlue, size: 12),
              Expanded(
                child: Container(width: 2, color: const Color(0xFFE0E4E8)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title.isEmpty ? date : event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _nightBlue,
                    ),
                  ),
                  if (date.isNotEmpty || event.place.isNotEmpty)
                    Text(
                      [
                        date,
                        event.place,
                      ].where((item) => item.isNotEmpty).join(' · '),
                      style: const TextStyle(color: _slateText),
                    ),
                  if (event.description.isNotEmpty) Text(event.description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MemberNotesCard extends StatelessWidget {
  const MemberNotesCard({super.key, required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _ProfileCard(
      title: l10n.notes,
      icon: Icons.note_alt_outlined,
      child: note.trim().isEmpty
          ? Text(l10n.noNotes)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.trim(), maxLines: 4, overflow: TextOverflow.ellipsis),
                if (note.trim().length > 180)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.notes),
                          content: SingleChildScrollView(
                            child: Text(note.trim()),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.cancel),
                            ),
                          ],
                        ),
                      ),
                      child: Text(l10n.viewMore),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MarriageRelationsCard extends StatelessWidget {
  const _MarriageRelationsCard({
    required this.relations,
    required this.peopleById,
  });

  final List<MarriageRelation> relations;
  final Map<String, Person> peopleById;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _ProfileCard(
      title: l10n.unionsAndSpouses,
      icon: Icons.favorite_border,
      child: Column(
        children: [
          for (final relation in relations)
            RelationshipRow(
              label: _typeLabel(l10n, relation.marriageType),
              person: peopleById[relation.partnerOf(relation.personId)],
            ),
        ],
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
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({this.title, this.icon, required this.child});

  final String? title;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) Icon(icon, color: _primaryBlue),
                  if (icon != null) const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _nightBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.text, this.detail});

  final IconData icon;
  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _primaryBlue),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _slateText),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileLoadingSkeleton extends StatelessWidget {
  const _ProfileLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              children: [
                _SkeletonCard(height: 150),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 900;
                    if (!twoColumns) {
                      return const Column(
                        children: [
                          _SkeletonCard(height: 240),
                          SizedBox(height: 16),
                          _SkeletonCard(height: 220),
                        ],
                      );
                    }
                    return const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: _SkeletonCard(height: 360)),
                        SizedBox(width: 16),
                        Expanded(flex: 4, child: _SkeletonCard(height: 300)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ProfileDisplay {
  _ProfileDisplay(
    BuildContext context,
    this.person,
    this.authenticated,
    this.localeName,
  ) : l10n = AppLocalizations.of(context);

  final Person person;
  final bool authenticated;
  final String localeName;
  final AppLocalizations l10n;

  bool get canShowPrivateCoordinates =>
      authenticated || person.privacy.privateCoordinatesVisible;
  bool get showRelations =>
      authenticated || person.privacy.familyRelationsVisible;
  bool get showHistory =>
      authenticated || person.privacy.showHistoryInPublicMode;

  String get fullName => person.fullName;
  String get gender => authenticated || person.privacy.genderVisible
      ? formatProfileGender(person.gender, l10n.male, l10n.female)
      : '';
  String get birthDate => authenticated || person.privacy.birthDateVisible
      ? formatProfileDate(person.birthDate, localeName)
      : '';
  String get deathDate => authenticated || person.privacy.deathDateVisible
      ? formatProfileDate(person.deathDate, localeName)
      : '';
  String get birthPlace =>
      authenticated || person.privacy.showBirthPlaceInPublicMode
      ? person.birthPlace
      : '';
  String get deathPlace => authenticated || person.privacy.deathPlaceVisible
      ? person.deathPlace
      : '';
  String get burialPlace => authenticated || person.privacy.burialPlaceVisible
      ? person.burialPlace
      : '';
  String get currentAddress =>
      authenticated || person.privacy.showCurrentAddressInPublicMode
      ? person.currentAddress
      : '';
  String get publicMapLocation => person.publicMapLocation;
  String get familyBranch => authenticated || person.privacy.familyBranchVisible
      ? person.familyCode
      : '';
  String get originLastName =>
      authenticated || person.privacy.birthLastNameVisible
      ? (person.shouldShowOriginLastName ? person.originLastName : '')
      : '';
  String get notes =>
      authenticated || person.privacy.notesVisible ? person.notes : '';
  String get generationLabel =>
      person.generation > 0 ? '${l10n.generation} ${person.generation}' : '';
  String get mapAddress {
    if (publicMapLocation.trim().isNotEmpty) return publicMapLocation.trim();
    if (birthPlace.trim().isNotEmpty) return birthPlace.trim();
    return currentAddress.trim();
  }

  double? get mapLatitude => canShowPrivateCoordinates ? person.latitude : null;
  double? get mapLongitude =>
      canShowPrivateCoordinates ? person.longitude : null;
  bool get hasMapLocation =>
      mapAddress.isNotEmpty || (mapLatitude != null && mapLongitude != null);
}

String _initials(Person person) {
  final first = person.firstName.trim().isEmpty
      ? ''
      : person.firstName.trim()[0];
  final last = person.lastName.trim().isEmpty ? '' : person.lastName.trim()[0];
  final value = '$first$last'.trim();
  return value.isEmpty ? '?' : value.toUpperCase();
}
