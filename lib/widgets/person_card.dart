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
  });

  final Person person;
  final FamilyTreeData data;
  final VoidCallback onOpen;
  final AuthMode authMode;
  final bool compact;

  @override
  ConsumerState<PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends ConsumerState<PersonCard> {
  OverlayEntry? _entry;

  @override
  void dispose() {
    _remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _show(),
      onExit: (_) => _remove(),
      child: GestureDetector(
        onTap: widget.onOpen,
        onSecondaryTapDown: (details) => _showContextMenu(details.globalPosition),
        onLongPressStart: (details) => _showContextMenu(details.globalPosition),
        child: Card(
          child: SizedBox(
            width: widget.compact ? 190 : 250,
            height: widget.compact ? 104 : 138,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(child: Text(_initials(widget.person))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_genderSymbol),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.person.fullName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                        if (widget.authMode == AuthMode.authenticated) ...[
                          const SizedBox(height: 4),
                          _relationLine(context, _fatherLine),
                          _relationLine(context, _motherLine),
                          _relationLine(context, _spouseLine),
                        ] else if (_publicMapLocation.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _publicMapLocation,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ],
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
    final hasContact = widget.person.allowContact &&
        (widget.person.whatsappNumber.isNotEmpty || widget.person.email.isNotEmpty);
    final selected = await showMenu<PersonContextAction>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: personContextMenuItems(
        l10n,
        canModify: canRequestModify,
        canDelete: auth.canModify && auth.isAdmin,
        hasMap: hasMap,
        hasContact: hasContact,
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
          (service, data) => service.addFather(data, widget.person, actorRole: _actorRole),
        );
      case PersonContextAction.addMother:
        await _applyRelationship(
          (service, data) => service.addMother(data, widget.person, actorRole: _actorRole),
        );
      case PersonContextAction.addParents:
        await _applyRelationship(
          (service, data) => service.addParents(data, widget.person, actorRole: _actorRole),
        );
      case PersonContextAction.addChild:
      case PersonContextAction.addChildren:
        await _applyRelationship(
          (service, data) => service.addChild(data, widget.person, actorRole: _actorRole),
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
          (service, data) => service.addSpouse(data, widget.person, actorRole: _actorRole),
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
        await ref.read(mapServiceProvider).openInGoogleMaps(address: _mapAddress);
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
    FamilyTreeData Function(FamilyRelationService service, FamilyTreeData data) buildNext,
  ) async {
    if (!await _ensureModificationAccess()) return;
    try {
      final service = ref.read(familyRelationServiceProvider);
      final next = buildNext(service, ref.read(familyTreeProvider).value!);
      await ref.read(familyTreeProvider.notifier).save(next);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _linkExisting(String relationship) async {
    if (!await _ensureModificationAccess()) return;
    if (!mounted) return;
    final data = ref.read(familyTreeProvider).value!;
    final candidates = data.people.where((person) => person.id != widget.person.id).toList();
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
                .map((person) => DropdownMenuItem(value: person, child: Text(person.fullName)))
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PersonEditScreen(person: person)),
    );
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
      await ref.read(familyTreeProvider.notifier).deletePerson(widget.person.id);
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

  String get _actorRole => ref.read(authSessionProvider).session?.role ?? 'viewer';

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
    if (gender == 'male' || gender == 'm' || gender == 'homme') return '♂';
    if (gender == 'female' || gender == 'f' || gender == 'femme') return '♀';
    return '⚪';
  }

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

  Widget _relationLine(BuildContext context, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  static String _initials(Person person) {
    final first = person.firstName.isEmpty ? '' : person.firstName[0];
    final last = person.lastName.isEmpty ? '' : person.lastName[0];
    final value = '$first$last';
    return value.isEmpty ? '?' : value.toUpperCase();
  }
}
