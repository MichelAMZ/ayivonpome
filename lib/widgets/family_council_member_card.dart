import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/family_council_member.dart';

class FamilyCouncilMemberCard extends StatelessWidget {
  const FamilyCouncilMemberCard({
    super.key,
    required this.member,
    required this.showContact,
    required this.showDetails,
    this.onEmail,
    this.onWhatsApp,
    this.onCall,
    this.onMap,
    this.onEdit,
    this.onDelete,
  });

  final FamilyCouncilMember member;
  final bool showContact;
  final bool showDetails;
  final VoidCallback? onEmail;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCall;
  final VoidCallback? onMap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = member.fullName.isEmpty ? '-' : member.fullName;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE4E8DD)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFEAF3DE),
                  foregroundImage: _imageProvider,
                  child: _imageProvider == null
                      ? Text(_initials(member))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7DD),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFE8D28A)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          child: Text(
                            member.roleTitle.isEmpty
                                ? l10n.councilMember
                                : member.roleTitle,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: const Color(0xFF725516),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    tooltip: l10n.editCouncilMember,
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: l10n.deleteCouncilMember,
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            if (showDetails && member.residencePlace.isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoLine(
                icon: Icons.location_on_outlined,
                text: member.residencePlace,
              ),
            ],
            if (showContact) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (member.email.isNotEmpty)
                    _ActionChip(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      onPressed: onEmail,
                    ),
                  if (member.whatsappNumber.isNotEmpty)
                    _ActionChip(
                      icon: Icons.chat_outlined,
                      label: 'WhatsApp',
                      onPressed: onWhatsApp,
                    ),
                  if (member.phoneNumber.isNotEmpty)
                    _ActionChip(
                      icon: Icons.call_outlined,
                      label: 'Appeler',
                      onPressed: onCall,
                    ),
                  if (member.residencePlace.isNotEmpty)
                    _ActionChip(
                      icon: Icons.map_outlined,
                      label: 'Carte',
                      onPressed: onMap,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  ImageProvider? get _imageProvider {
    final value = member.photo.trim();
    if (value.isEmpty || !value.startsWith('http')) return null;
    return NetworkImage(value);
  }

  String _initials(FamilyCouncilMember member) {
    final first = member.firstName.isEmpty ? '' : member.firstName[0];
    final last = member.lastName.isEmpty ? '' : member.lastName[0];
    final value = '$first$last';
    return value.isEmpty ? '?' : value.toUpperCase();
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4D742B)),
        const SizedBox(width: 6),
        Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 17),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
