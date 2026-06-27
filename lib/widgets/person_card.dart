import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/family_tree_data.dart';
import '../models/person.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../services/family_relation_service.dart';
import '../screens/person_edit_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/modification_code_required_dialog.dart';
import '../widgets/notification_form.dart';
import 'person_context_menu.dart';
import 'person_preview_popup.dart';

class PersonCard extends ConsumerStatefulWidget {
  const PersonCard({
    super.key,
    required this.person,
    required this.data,
    required this.onOpen,
    required this.authMode,
    this.compact = false,
    this.width,
    this.height,
  });

  final Person person;
  final FamilyTreeData data;
  final VoidCallback onOpen;
  final AuthMode authMode;
  final bool compact;
  final double? width;
  final double? height;

  @override
  ConsumerState<PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends ConsumerState<PersonCard> {
  OverlayEntry? _entry;
  bool _hovered = false;

  @override
  void dispose() {
    _remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentLeader =
        widget.data.familyLeadership.currentLeaderPersonId == widget.person.id;
    final compact = widget.compact;
    final location = _displayLocation;
    final primary = Theme.of(context).colorScheme.primary;
    final borderColor = _genderColor;
    final avatarBackground = _genderLightColor;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _show();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _remove();
      },
      child: GestureDetector(
        onTap: widget.onOpen,
        onSecondaryTapDown: (details) =>
            _showContextMenu(details.globalPosition),
        onLongPressStart: (_) => _show(),
        onLongPressEnd: (_) => _remove(),
        child: SizedBox(
          width: widget.width ?? (compact ? 300 : 420),
          height: widget.height ?? (compact ? 112 : 126),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: isCurrentLeader
                      ? const Color(0x30C59A2A)
                      : const Color(0x14000000),
                  blurRadius: _hovered ? 26 : 18,
                  offset: Offset(0, _hovered ? 12 : 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    left: 0,
                    right: null,
                    child: Container(width: 5, color: borderColor),
                  ),
                  if (isCurrentLeader)
                    Positioned(
                      top: 8,
                      right: compact ? 76 : 88,
                      child: _LeaderPill(
                        label: AppLocalizations.of(context).currentChief,
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 22,
                      compact ? 14 : 18,
                      compact ? 10 : 14,
                      compact ? 14 : 18,
                    ),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: compact ? 34 : 42,
                              backgroundColor: avatarBackground,
                              foregroundColor: borderColor,
                              child: Text(
                                _initials(widget.person),
                                style: TextStyle(
                                  fontSize: compact ? 25 : 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            if (isCurrentLeader)
                              Positioned(
                                right: -3,
                                top: -6,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3B344),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium,
                                    size: 15,
                                    color: Color(0xFF6F4C0E),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(width: compact ? 16 : 22),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _genderSymbol,
                                    style: TextStyle(
                                      color: _genderColor,
                                      fontSize: compact ? 27 : 32,
                                      height: 1,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: compact ? 8 : 12),
                                  Expanded(
                                    child: Text(
                                      widget.person.fullName,
                                      maxLines: compact ? 2 : 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: const Color(0xFF121411),
                                            fontSize: compact ? 19 : 23,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              if (location.isNotEmpty) ...[
                                SizedBox(height: compact ? 9 : 13),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: compact ? 25 : 31,
                                      color: const Color(0xFF4C7A2E),
                                    ),
                                    SizedBox(width: compact ? 7 : 10),
                                    Expanded(
                                      child: Text(
                                        location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: const Color(0xFF4F514C),
                                              fontSize: compact ? 16 : 20,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: compact ? 6 : 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_mapAddress.isNotEmpty)
                              IconButton(
                                tooltip: 'Google Maps',
                                visualDensity: VisualDensity.compact,
                                constraints: BoxConstraints.tightFor(
                                  width: compact ? 34 : 38,
                                  height: compact ? 34 : 38,
                                ),
                                padding: EdgeInsets.zero,
                                iconSize: compact ? 28 : 32,
                                icon: const Icon(Icons.location_on_outlined),
                                color: primary,
                                onPressed: () => ref
                                    .read(mapServiceProvider)
                                    .openInGoogleMaps(address: _mapAddress),
                              ),
                            Builder(
                              builder: (buttonContext) => IconButton(
                                tooltip: 'Menu',
                                visualDensity: VisualDensity.compact,
                                constraints: BoxConstraints.tightFor(
                                  width: compact ? 30 : 34,
                                  height: compact ? 34 : 38,
                                ),
                                padding: EdgeInsets.zero,
                                iconSize: compact ? 25 : 30,
                                icon: const Icon(Icons.more_vert),
                                onPressed: () {
                                  final box =
                                      buttonContext.findRenderObject()
                                          as RenderBox;
                                  final center = box.localToGlobal(
                                    box.size.center(Offset.zero),
                                  );
                                  _showContextMenu(center);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
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

  String get _displayLocation {
    if (widget.authMode == AuthMode.authenticated) {
      final currentAddress = widget.person.currentAddress.trim();
      if (currentAddress.isNotEmpty) return currentAddress;
      final publicLocation = widget.person.publicMapLocation.trim();
      if (publicLocation.isNotEmpty) return publicLocation;
      final birthPlace = widget.person.birthPlace.trim();
      if (birthPlace.isNotEmpty) return birthPlace;
      return widget.person.burialPlace.trim();
    }
    return _publicMapLocation;
  }

  void _show() {
    if (_entry != null || !mounted) {
      return;
    }
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    _entry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + box.size.width + 12,
        top: offset.dy,
        child: PersonPreviewPopup(
          person: widget.person,
          data: widget.data,
          authMode: widget.authMode,
          onViewProfile: () {
            _remove();
            widget.onOpen();
          },
        ),
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  Future<void> _showContextMenu(Offset position) async {
    _remove();
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authSessionProvider);
    final canRequestModify =
        auth.isAuthenticated && auth.session?.role != 'viewer';
    final hasMap = _mapAddress.isNotEmpty;
    final hasContact =
        widget.person.allowContact &&
        (widget.person.whatsappNumber.isNotEmpty ||
            widget.person.email.isNotEmpty);
    final selected = await showMenu<PersonContextAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: personContextMenuItems(
        l10n,
        canModify: canRequestModify,
        canDelete: auth.canModify && auth.isAdmin,
        hasMap: hasMap,
        hasContact: hasContact,
        canNotify: auth.isAdmin,
      ),
    );
    if (selected == null || !mounted) return;
    await _handleContextAction(selected);
  }

  Future<void> _handleContextAction(PersonContextAction action) async {
    switch (action) {
      case PersonContextAction.viewProfile:
        widget.onOpen();
      case PersonContextAction.editPerson:
      case PersonContextAction.addHistoricalEvent:
        if (await _ensureModificationAccess()) _openEditor(widget.person);
      case PersonContextAction.deletePerson:
        if (await _ensureModificationAccess()) await _deletePerson();
      case PersonContextAction.addFather:
        await _applyRelationship(
          (service, data) =>
              service.addFather(data, widget.person, actorRole: _actorRole),
        );
      case PersonContextAction.addMother:
        await _applyRelationship(
          (service, data) =>
              service.addMother(data, widget.person, actorRole: _actorRole),
        );
      case PersonContextAction.addParents:
        await _applyRelationship(
          (service, data) =>
              service.addParents(data, widget.person, actorRole: _actorRole),
        );
      case PersonContextAction.addChild:
      case PersonContextAction.addChildren:
        await _applyRelationship(
          (service, data) =>
              service.addChild(data, widget.person, actorRole: _actorRole),
        );
      case PersonContextAction.addBrother:
        await _applyRelationship(
          (service, data) => service.addSibling(
            data,
            widget.person,
            gender: 'male',
            actorRole: _actorRole,
          ),
        );
      case PersonContextAction.addSister:
        await _applyRelationship(
          (service, data) => service.addSibling(
            data,
            widget.person,
            gender: 'female',
            actorRole: _actorRole,
          ),
        );
      case PersonContextAction.addSpouse:
        await _applyRelationship(
          (service, data) =>
              service.addSpouse(data, widget.person, actorRole: _actorRole),
        );
      case PersonContextAction.linkFather:
        await _linkExisting('father');
      case PersonContextAction.linkMother:
        await _linkExisting('mother');
      case PersonContextAction.linkChild:
        await _linkExisting('child');
      case PersonContextAction.linkSpouse:
        await _linkExisting('spouse');
      case PersonContextAction.viewOnMap:
        await ref
            .read(mapServiceProvider)
            .openInGoogleMaps(address: _mapAddress);
      case PersonContextAction.sendMessage:
        await _sendMessage();
      case PersonContextAction.notifyPerson:
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => NotificationForm(
            people: widget.data.people,
            initialPerson: widget.person,
          ),
        );
      case PersonContextAction.copyInfo:
        await Clipboard.setData(ClipboardData(text: _copyText));
    }
  }

  Future<void> _applyRelationship(
    FamilyTreeData Function(FamilyRelationService service, FamilyTreeData data)
    buildNext,
  ) async {
    if (!await _ensureModificationAccess()) return;
    try {
      final service = ref.read(familyRelationServiceProvider);
      final next = buildNext(service, ref.read(familyTreeProvider).value!);
      await ref.read(familyTreeProvider.notifier).save(next);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _linkExisting(String relationship) async {
    if (!await _ensureModificationAccess()) return;
    if (!mounted) return;
    final data = ref.read(familyTreeProvider).value!;
    final candidates = data.people
        .where((person) => person.id != widget.person.id)
        .toList();
    if (candidates.isEmpty) return;
    var selected = candidates.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).linkExistingPerson),
          content: DropdownButtonFormField<Person>(
            initialValue: selected,
            items: candidates
                .map(
                  (person) => DropdownMenuItem(
                    value: person,
                    child: Text(person.fullName),
                  ),
                )
                .toList(),
            onChanged: (person) {
              if (person != null) setDialogState(() => selected = person);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).save),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await _applyRelationship(
      (service, data) => service.linkExistingPerson(
        data,
        widget.person,
        selected,
        relationship: relationship,
        actorRole: _actorRole,
      ),
    );
  }

  Future<bool> _ensureModificationAccess() async {
    if (ref.read(authSessionProvider).canModify) return true;
    final unlocked = await showDialog<bool>(
      context: context,
      builder: (context) => const ModificationCodeRequiredDialog(),
    );
    return unlocked == true;
  }

  void _openEditor(Person person) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PersonEditScreen(person: person)));
  }

  Future<void> _deletePerson() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(widget.person.fullName),
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
    if (confirmed == true) {
      await ref
          .read(familyTreeProvider.notifier)
          .deletePerson(widget.person.id);
    }
  }

  Future<void> _sendMessage() async {
    final service = ref.read(communicationServiceProvider);
    if (widget.person.whatsappNumber.isNotEmpty) {
      await service.openWhatsApp(
        phoneNumber: widget.person.whatsappNumber,
        message: AppLocalizations.of(context).familyWhatsappMessage,
      );
    } else if (widget.person.email.isNotEmpty) {
      await service.sendEmail(
        email: widget.person.email,
        subject: AppLocalizations.of(context).familyEmailSubject,
        body: AppLocalizations.of(context).familyEmailBody,
      );
    }
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
  }

  String get _publicMapLocation => widget.person.privacy.showMapInPublicMode
      ? widget.person.publicMapLocation.trim()
      : '';

  String get _mapAddress => widget.authMode == AuthMode.authenticated
      ? (widget.person.currentAddress.isNotEmpty
            ? widget.person.currentAddress
            : widget.person.birthPlace)
      : _publicMapLocation;

  String get _actorRole =>
      ref.read(authSessionProvider).session?.role ?? 'viewer';

  String get _copyText => [
    widget.person.fullName,
    _fatherLine,
    _motherLine,
    _spouseLine,
    if (_mapAddress.isNotEmpty) _mapAddress,
  ].where((line) => line.isNotEmpty).join('\n');

  FamilyRelationService get _relations => FamilyRelationService();

  String get _genderSymbol {
    final gender = widget.person.gender.toLowerCase();
    if (_isMaleGender(gender)) return '♂';
    if (_isFemaleGender(gender)) return '♀';
    return '○';
  }

  Color get _genderColor {
    final gender = widget.person.gender.toLowerCase();
    if (_isMaleGender(gender)) return AppColors.maleBlue;
    if (_isFemaleGender(gender)) return AppColors.femalePink;
    return AppColors.neutralGrey;
  }

  Color get _genderLightColor {
    final gender = widget.person.gender.toLowerCase();
    if (_isMaleGender(gender)) return AppColors.maleLight;
    if (_isFemaleGender(gender)) return AppColors.femaleLight;
    return AppColors.neutralLight;
  }

  bool _isMaleGender(String gender) =>
      gender == 'male' || gender == 'm' || gender == 'homme';

  bool _isFemaleGender(String gender) =>
      gender == 'female' || gender == 'f' || gender == 'femme';

  String get _fatherLine {
    final father = _relations.fatherOf(widget.data, widget.person);
    return father == null ? '' : 'Père: ${father.fullName}';
  }

  String get _motherLine {
    final mother = _relations.motherOf(widget.data, widget.person);
    return mother == null ? '' : 'Mère: ${mother.fullName}';
  }

  String get _spouseLine {
    final spouses = _relations.spousesOf(widget.data, widget.person);
    if (spouses.isEmpty) return '';
    return 'Marié(e) à: ${spouses.map((person) => person.fullName).join(', ')}';
  }

  static String _initials(Person person) {
    final first = person.firstName.isEmpty ? '' : person.firstName[0];
    final last = person.lastName.isEmpty ? '' : person.lastName[0];
    final value = '$first$last';
    return value.isEmpty ? '?' : value.toUpperCase();
  }
}

class _LeaderPill extends StatelessWidget {
  const _LeaderPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1B84E)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium,
              size: 11,
              color: Color(0xFF8B6818),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF8B6818),
                fontSize: 10,
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
