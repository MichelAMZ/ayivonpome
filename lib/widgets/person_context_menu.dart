import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum PersonContextAction {
  addFather,
  addMother,
  addParents,
  linkFather,
  linkMother,
  addChild,
  addChildren,
  linkChild,
  addSpouse,
  linkSpouse,
  declareDivorce,
  restoreMarriage,
  divorceHistory,
  addBrother,
  addSister,
  viewProfile,
  editPerson,
  addHistoricalEvent,
  viewOnMap,
  sendMessage,
  notifyPerson,
  copyInfo,
  deletePerson,
}

List<PopupMenuEntry<PersonContextAction>> personContextMenuItems(
  AppLocalizations l10n, {
  required bool canModify,
  required bool canDelete,
  required bool hasMap,
  required bool hasContact,
  required bool canNotify,
}) {
  return [
    if (canModify) ...[
      PopupMenuItem(
        value: PersonContextAction.addFather,
        child: _MenuRow(icon: Icons.man_2_outlined, label: l10n.addFather),
      ),
      PopupMenuItem(
        value: PersonContextAction.addMother,
        child: _MenuRow(icon: Icons.woman_2_outlined, label: l10n.addMother),
      ),
      PopupMenuItem(
        value: PersonContextAction.addParents,
        child: _MenuRow(icon: Icons.family_restroom, label: l10n.addParents),
      ),
      PopupMenuItem(
        value: PersonContextAction.linkFather,
        child: _MenuRow(
          icon: Icons.link,
          label: '${l10n.father} · ${l10n.linkExistingPerson}',
        ),
      ),
      PopupMenuItem(
        value: PersonContextAction.linkMother,
        child: _MenuRow(
          icon: Icons.link,
          label: '${l10n.mother} · ${l10n.linkExistingPerson}',
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: PersonContextAction.addChild,
        child: _MenuRow(icon: Icons.child_care_outlined, label: l10n.addChild),
      ),
      PopupMenuItem(
        value: PersonContextAction.addChildren,
        child: _MenuRow(
          icon: Icons.escalator_warning_outlined,
          label: l10n.addChildren,
        ),
      ),
      PopupMenuItem(
        value: PersonContextAction.linkChild,
        child: _MenuRow(
          icon: Icons.link,
          label: '${l10n.children} · ${l10n.linkExistingPerson}',
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: PersonContextAction.addSpouse,
        child: _MenuRow(icon: Icons.favorite_border, label: l10n.addSpouse),
      ),
      PopupMenuItem(
        value: PersonContextAction.linkSpouse,
        child: _MenuRow(
          icon: Icons.link,
          label: '${l10n.spouse} · ${l10n.linkExistingPerson}',
        ),
      ),
      PopupMenuItem(
        value: PersonContextAction.declareDivorce,
        child: _MenuRow(
          icon: Icons.heart_broken_outlined,
          label: l10n.declareDivorce,
        ),
      ),
      PopupMenuItem(
        value: PersonContextAction.restoreMarriage,
        child: _MenuRow(
          icon: Icons.favorite_outlined,
          label: l10n.restoreMarriage,
        ),
      ),
      PopupMenuItem(
        value: PersonContextAction.divorceHistory,
        child: _MenuRow(
          icon: Icons.history_outlined,
          label: l10n.divorceHistory,
        ),
      ),
      PopupMenuItem(
        value: PersonContextAction.addBrother,
        child: _MenuRow(icon: Icons.male, label: l10n.addBrother),
      ),
      PopupMenuItem(
        value: PersonContextAction.addSister,
        child: _MenuRow(icon: Icons.female, label: l10n.addSister),
      ),
      const PopupMenuDivider(),
    ],
    PopupMenuItem(
      value: PersonContextAction.viewProfile,
      child: _MenuRow(icon: Icons.badge_outlined, label: l10n.viewProfile),
    ),
    if (canModify)
      PopupMenuItem(
        value: PersonContextAction.editPerson,
        child: _MenuRow(icon: Icons.edit_outlined, label: l10n.editPerson),
      ),
    if (canModify)
      PopupMenuItem(
        value: PersonContextAction.addHistoricalEvent,
        child: _MenuRow(
          icon: Icons.history_edu_outlined,
          label: l10n.addHistoricalEvent,
        ),
      ),
    if (hasMap)
      PopupMenuItem(
        value: PersonContextAction.viewOnMap,
        child: _MenuRow(icon: Icons.map_outlined, label: l10n.viewOnMap),
      ),
    if (hasContact)
      PopupMenuItem(
        value: PersonContextAction.sendMessage,
        child: _MenuRow(icon: Icons.chat_outlined, label: l10n.sendMessage),
      ),
    if (canNotify)
      PopupMenuItem(
        value: PersonContextAction.notifyPerson,
        child: _MenuRow(
          icon: Icons.notifications_outlined,
          label: l10n.notifyPerson,
        ),
      ),
    PopupMenuItem(
      value: PersonContextAction.copyInfo,
      child: _MenuRow(icon: Icons.copy_outlined, label: l10n.copyInformation),
    ),
    if (canDelete) ...[
      const PopupMenuDivider(),
      PopupMenuItem(
        value: PersonContextAction.deletePerson,
        child: _MenuRow(icon: Icons.delete_outline, label: l10n.deletePerson),
      ),
    ],
  ];
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
