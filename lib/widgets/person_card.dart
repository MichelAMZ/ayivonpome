import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/family_tree_data.dart';
import '../models/marriage_relation.dart';
import '../models/person.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/family_tree_provider.dart';
import '../services/family_relation_service.dart';
import '../screens/divorce_dialog.dart';
import '../screens/person_edit_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/modification_code_required_dialog.dart';
import '../widgets/member_deletion_dialog.dart';
import '../widgets/notification_form.dart';
import 'person_context_menu.dart';
import 'person_origin_name_text.dart';
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
    this.highlighted = false,
    this.hasLinkedFamilyTree = false,
    this.hasDescendants = false,
    this.branchCollapsed = false,
    this.descendantCount = 0,
    this.onToggleBranch,
  });

  final Person person;
  final FamilyTreeData data;
  final VoidCallback onOpen;
  final AuthMode authMode;
  final bool compact;
  final double? width;
  final double? height;
  final bool highlighted;
  final bool hasLinkedFamilyTree;
  final bool hasDescendants;
  final bool branchCollapsed;
  final int descendantCount;
  final VoidCallback? onToggleBranch;

  @override
  ConsumerState<PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends ConsumerState<PersonCard> {
  OverlayEntry? _entry;
  bool _hovered = false;
  bool _showScheduled = false;
  bool _removeScheduled = false;

  @override
  void dispose() {
    _remove();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PersonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final personChanged =
        oldWidget.person.id != widget.person.id ||
        oldWidget.person.updatedAt != widget.person.updatedAt ||
        oldWidget.data.lastUpdatedAt != widget.data.lastUpdatedAt;
    if (!personChanged || (_entry == null && !_showScheduled)) {
      return;
    }
    _remove();
    if (_hovered) {
      _show();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.width != null && widget.height != null) {
      return _buildCompactTreeCard(context);
    }
    return _buildHorizontalCard(context);
  }

  Widget _buildHorizontalCard(BuildContext context) {
    final isCurrentLeader =
        widget.data.familyLeadership.currentLeaderPersonId == widget.person.id;
    final compact = widget.compact;
    final location = _displayLocation;
    final primary = Theme.of(context).colorScheme.primary;
    final borderColor = _genderColor;
    final avatarBackground = _genderLightColor;
    final formerSpouses = _formerSpouses;
    final showGenerationBadge =
        widget.data.appSettings.treeSettings.showGenerationBadges &&
        widget.person.generation > 0;

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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: widget.height ?? (compact ? 118 : 126),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.highlighted
                      ? const Color(0xFFD6AD42)
                      : borderColor,
                  width: widget.highlighted ? 2.4 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.highlighted
                        ? const Color(0x33D6AD42)
                        : isCurrentLeader
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
                    if (widget.hasLinkedFamilyTree)
                      Positioned(
                        top: compact ? 42 : 48,
                        right: 10,
                        child: Tooltip(
                          message: AppLocalizations.of(
                            context,
                          ).openLinkedFamilyTree,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF3D7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF7CA45A),
                              ),
                            ),
                            child: const Icon(
                              Icons.account_tree_outlined,
                              size: 17,
                              color: Color(0xFF315B22),
                            ),
                          ),
                        ),
                      ),
                    if (showGenerationBadge)
                      Positioned(
                        top: 8,
                        right: 10,
                        child: _GenerationBadge(
                          generation: widget.person.generation,
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 14 : 20,
                        compact ? 12 : 14,
                        compact ? 8 : 12,
                        compact ? 12 : 14,
                      ),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: compact ? 32 : 36,
                                backgroundColor: avatarBackground,
                                foregroundColor: borderColor,
                                child: Text(
                                  _initials(widget.person),
                                  style: TextStyle(
                                    fontSize: compact ? 24 : 28,
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
                              mainAxisSize: MainAxisSize.min,
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
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.person.fullName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF121411,
                                                  ),
                                                  fontSize: compact ? 18 : 21,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0,
                                                ),
                                          ),
                                          PersonOriginNameText(
                                            person: widget.person,
                                            fontSize: 12,
                                            topPadding: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (location.isNotEmpty) ...[
                                  SizedBox(height: compact ? 4 : 5),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: compact ? 20 : 22,
                                        color: const Color(0xFF4C7A2E),
                                      ),
                                      SizedBox(width: compact ? 6 : 8),
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
                                                fontSize: compact ? 13 : 15,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (formerSpouses.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${AppLocalizations.of(context).formerSpouses}: ${formerSpouses.map((person) => person.fullName).join(', ')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: const Color(0xFF9A2636),
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0,
                                        ),
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
      ),
    );
  }

  Widget _buildCompactTreeCard(BuildContext context) {
    final isCurrentLeader =
        widget.data.familyLeadership.currentLeaderPersonId == widget.person.id;
    final borderColor = _genderColor;
    final showGenerationBadge =
        widget.data.appSettings.treeSettings.showGenerationBadges &&
        widget.person.generation > 0;
    final photo = widget.person.photo.trim();
    final birthYear = widget.person.birthDate.length >= 4
        ? widget.person.birthDate.substring(0, 4)
        : '';
    final extraCompactName = (widget.width ?? 100) <= 92;
    final fullName = widget.person.fullName.trim();

    Widget avatarFallback() => ColoredBox(
      color: _genderLightColor,
      child: Center(
        child: Text(
          _initials(widget.person),
          style: TextStyle(
            color: borderColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    final avatar = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 64,
        child: photo.isEmpty
            ? avatarFallback()
            : Image.network(
                photo,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => avatarFallback(),
              ),
      ),
    );

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
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        onSecondaryTapDown: (details) =>
            _showContextMenu(details.globalPosition),
        onLongPressStart: (_) => _show(),
        onLongPressEnd: (_) => _remove(),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.highlighted
                    ? const Color(0xFFD6AD42)
                    : borderColor,
                width: widget.highlighted ? 2.4 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.highlighted
                      ? const Color(0x33D6AD42)
                      : isCurrentLeader
                      ? const Color(0x30C59A2A)
                      : const Color(0x14000000),
                  blurRadius: _hovered ? 18 : 12,
                  offset: Offset(0, _hovered ? 8 : 5),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: Column(
                    children: [
                      Center(child: avatar),
                      const SizedBox(height: 0),
                      Tooltip(
                        message: fullName,
                        child: Column(
                          children: [
                            // Le prénom est l'information la plus utile pour
                            // identifier rapidement une personne dans l'arbre.
                            Text(
                              widget.person.firstName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: extraCompactName ? 15 : 16,
                                height: 1.05,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 1),
                            // Le nom reste volontairement discret pour établir
                            // une hiérarchie claire sans agrandir la carte.
                            Text(
                              widget.person.lastName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF757575),
                                fontSize: extraCompactName ? 11.5 : 12.5,
                                height: 1.05,
                                fontWeight: FontWeight.w400,
                                letterSpacing: extraCompactName ? 0.4 : 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _genderSymbol,
                            style: TextStyle(
                              color: borderColor,
                              fontSize: 15,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (birthYear.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                birthYear,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF4F514C),
                                  fontSize: 11,
                                  height: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCurrentLeader)
                  const Positioned(
                    bottom: -1,
                    left: 2,
                    child: Icon(
                      Icons.workspace_premium,
                      size: 19,
                      color: Color(0xFFC99A19),
                    ),
                  ),
                if (widget.hasLinkedFamilyTree)
                  const Positioned(
                    top: 30,
                    right: 2,
                    child: Icon(
                      Icons.account_tree_outlined,
                      size: 17,
                      color: Color(0xFF315B22),
                    ),
                  ),
                if (showGenerationBadge)
                  Positioned(
                    right: 0,
                    bottom: -1,
                    child: _GenerationBadge(
                      generation: widget.person.generation,
                    ),
                  ),
                if (widget.hasDescendants && widget.onToggleBranch != null)
                  Positioned(
                    left: 4,
                    top: 0,
                    child: _BranchToggleBadge(
                      key: ValueKey('branch-toggle-${widget.person.id}'),
                      collapsed: widget.branchCollapsed,
                      descendantCount: widget.descendantCount,
                      borderColor: borderColor,
                      onPressed: widget.onToggleBranch!,
                    ),
                  ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Builder(
                    builder: (buttonContext) => IconButton(
                      tooltip: 'Menu',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        final box =
                            buttonContext.findRenderObject() as RenderBox;
                        final center = box.localToGlobal(
                          box.size.center(Offset.zero),
                        );
                        _showContextMenu(center);
                      },
                    ),
                  ),
                ),
              ],
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
    if (!ref.read(authSessionProvider).canViewMemberDetails) {
      return;
    }
    if (_entry != null || _showScheduled || !mounted) {
      return;
    }
    _showScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _showScheduled = false;
      if (!mounted || !_hovered || _entry != null) {
        return;
      }
      _insertPreviewOverlay();
    });
  }

  void _insertPreviewOverlay() {
    if (!ref.read(authSessionProvider).canViewMemberDetails) {
      return;
    }
    final box = context.findRenderObject() as RenderBox;
    if (!box.hasSize || box.size.isEmpty) {
      return;
    }
    final offset = box.localToGlobal(Offset.zero);
    final viewport = MediaQuery.sizeOf(context);
    const margin = 12.0;
    final popupWidth = (viewport.width - margin * 2).clamp(240.0, 320.0);
    final popupMaxHeight = (viewport.height - margin * 2).clamp(220.0, 520.0);
    final rightSideLeft = offset.dx + box.size.width + margin;
    final leftSideLeft = offset.dx - popupWidth - margin;
    final left = rightSideLeft + popupWidth <= viewport.width - margin
        ? rightSideLeft
        : leftSideLeft >= margin
        ? leftSideLeft
        : margin;
    final top = offset.dy.clamp(
      margin,
      (viewport.height - popupMaxHeight - margin).clamp(
        margin,
        viewport.height,
      ),
    );
    _entry = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        child: PersonPreviewPopup(
          person: widget.person,
          data: widget.data,
          authMode: widget.authMode,
          maxWidth: popupWidth,
          maxHeight: popupMaxHeight,
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
    final canRequestModify = auth.canShowEditButton;
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
        canModify: auth.canEdit,
        canRequestEdit: canRequestModify,
        canDelete: auth.canDelete,
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
        await _deletePerson();
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
      case PersonContextAction.declareDivorce:
        if (await _ensureModificationAccess()) await _declareDivorce();
      case PersonContextAction.restoreMarriage:
        if (await _ensureModificationAccess()) await _restoreMarriage();
      case PersonContextAction.divorceHistory:
        await _showMarriageHistory();
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
    buildNext, {
    String relationship = 'context_relationship',
  }) async {
    if (!await _ensureModificationAccess()) return;
    try {
      final service = ref.read(familyRelationServiceProvider);
      final next = buildNext(service, ref.read(familyTreeProvider).value!);
      final auth = ref.read(authSessionProvider);
      final result = await ref
          .read(familyTreeProvider.notifier)
          .saveRelationshipChange(
            next,
            relationship: relationship,
            actorRole: _actorRole,
            adminId: auth.firebaseUid ?? auth.firebaseEmail ?? _actorRole,
          );
      if (!mounted || result.isFirestoreConfirmed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isLocalPending
                ? 'Relation enregistrée localement. Synchronisation en attente.'
                : result.lastError,
          ),
        ),
      );
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
    if (relationship == 'father') {
      final auth = ref.read(authSessionProvider);
      try {
        final result = await ref
            .read(familyTreeProvider.notifier)
            .linkExistingFather(
              childId: widget.person.id,
              fatherId: selected.id,
              actorRole: _actorRole,
              adminId: auth.firebaseUid ?? auth.firebaseEmail ?? _actorRole,
            );
        if (!mounted || result.isFirestoreConfirmed) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isLocalPending
                  ? 'Relation enregistrée localement. Synchronisation en attente.'
                  : result.lastError,
            ),
          ),
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return;
    }
    await _applyRelationship(
      (service, data) => service.linkExistingPerson(
        data,
        widget.person,
        selected,
        relationship: relationship,
        actorRole: _actorRole,
      ),
      relationship: 'link_$relationship',
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
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MemberDeletionDialog(
        person: widget.person,
        data: widget.data,
        onDelete: () => ref
            .read(familyTreeProvider.notifier)
            .deletePerson(widget.person.id),
      ),
    );
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le membre a été supprimé.')),
      );
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
    if (_entry == null || _removeScheduled) {
      return;
    }
    _removeScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _removeScheduled = false;
      _entry?.remove();
      _entry = null;
    });
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
    if (widget.person.shouldShowOriginLastName)
      '${AppLocalizations.of(context).nee} ${widget.person.originLastName}',
    _fatherLine,
    _motherLine,
    _spouseLine,
    _formerSpouseLine,
    if (_mapAddress.isNotEmpty) _mapAddress,
  ].where((line) => line.isNotEmpty).join('\n');

  FamilyRelationService get _relations => FamilyRelationService();
  List<Person> get _formerSpouses => ref
      .read(marriageServiceProvider)
      .getFormerSpouses(widget.data, widget.person);

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

  String get _formerSpouseLine {
    final spouses = _formerSpouses;
    if (spouses.isEmpty) return '';
    return '${AppLocalizations.of(context).formerSpouses}: ${spouses.map((person) => person.fullName).join(', ')}';
  }

  Future<void> _declareDivorce() async {
    final selection = await _selectMarriageRelation(divorced: false);
    if (selection == null || !mounted) return;
    final result = await showDialog<DivorceResult>(
      context: context,
      builder: (context) =>
          DivorceDialog(first: widget.person, second: selection.$2),
    );
    if (result == null) return;
    final auth = ref.read(authSessionProvider);
    await ref
        .read(familyTreeProvider.notifier)
        .declareDivorce(
          selection.$1,
          divorceDate: result.divorceDate,
          notes: result.notes,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }

  Future<void> _restoreMarriage() async {
    final selection = await _selectMarriageRelation(divorced: true);
    if (selection == null) return;
    final auth = ref.read(authSessionProvider);
    await ref
        .read(familyTreeProvider.notifier)
        .restoreMarriage(
          selection.$1,
          actorRole: auth.session?.role ?? 'viewer',
          adminId: auth.session?.familyCode ?? '',
        );
  }

  Future<void> _showMarriageHistory() async {
    final l10n = AppLocalizations.of(context);
    final relations = ref
        .read(marriageServiceProvider)
        .relationsFor(widget.data, widget.person.id);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.divorceHistory),
        content: SizedBox(
          width: 420,
          child: relations.isEmpty
              ? Text(l10n.emptyState)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final relation in relations)
                      ListTile(
                        leading: relation.status == 'divorced'
                            ? const Text('💔')
                            : const Text('💍'),
                        title: Text(relation.status),
                        subtitle: Text(
                          [
                            if (relation.marriageDate.isNotEmpty)
                              'Mariage: ${relation.marriageDate}',
                            if (relation.divorceDate.isNotEmpty)
                              '${l10n.divorceDate}: ${relation.divorceDate}',
                            relation.notes,
                          ].where((line) => line.isNotEmpty).join('\n'),
                        ),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<(MarriageRelation, Person)?> _selectMarriageRelation({
    required bool divorced,
  }) async {
    final service = ref.read(marriageServiceProvider);
    final relations = service
        .relationsFor(widget.data, widget.person.id)
        .where(
          (relation) => divorced
              ? relation.status == 'divorced'
              : relation.status != 'divorced',
        )
        .toList();
    final peopleById = {
      for (final person in widget.data.people) person.id: person,
    };
    final choices = relations
        .map((relation) {
          final spouseId = relation.personId == widget.person.id
              ? relation.spouseId
              : relation.personId;
          final spouse = peopleById[spouseId];
          return spouse == null ? null : (relation, spouse);
        })
        .whereType<(MarriageRelation, Person)>()
        .toList();
    if (choices.isEmpty) return null;
    if (choices.length == 1) return choices.first;
    return showDialog<(MarriageRelation, Person)>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context).spouse),
        children: [
          for (final choice in choices)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, choice),
              child: Text(choice.$2.fullName),
            ),
        ],
      ),
    );
  }

  static String _initials(Person person) {
    final first = person.firstName.isEmpty ? '' : person.firstName[0];
    final last = person.lastName.isEmpty ? '' : person.lastName[0];
    final value = '$first$last';
    return value.isEmpty ? '?' : value.toUpperCase();
  }
}

class _BranchToggleBadge extends StatelessWidget {
  const _BranchToggleBadge({
    super.key,
    required this.collapsed,
    required this.descendantCount,
    required this.borderColor,
    required this.onPressed,
  });

  final bool collapsed;
  final int descendantCount;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final actionLabel = collapsed
        ? 'Réafficher les descendants'
        : 'Masquer les descendants';
    return Semantics(
      button: true,
      label: '$actionLabel, $descendantCount descendants',
      child: Tooltip(
        message: actionLabel,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(15),
                hoverColor: const Color(0x14315B22),
                splashColor: const Color(0x1F315B22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: 44,
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: collapsed
                        ? const Color(0xFFF2F5EE)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: borderColor.withValues(alpha: 0.32),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedRotation(
                        turns: collapsed ? 0 : 0.25,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Color(0xFF315B22),
                        ),
                      ),
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 14,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              '$descendantCount',
                              key: ValueKey('$collapsed-$descendantCount'),
                              maxLines: 1,
                              style: const TextStyle(
                                color: Color(0xFF315B22),
                                fontSize: 12,
                                height: 1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

class _GenerationBadge extends StatelessWidget {
  const _GenerationBadge({required this.generation});

  final int generation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8EC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD5C15C)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          'G$generation',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF5E6F1E),
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            height: 1,
          ),
        ),
      ),
    );
  }
}
