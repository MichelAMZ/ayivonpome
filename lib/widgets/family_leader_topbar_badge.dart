import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/family_leadership.dart';
import '../models/person.dart';

enum FamilyLeaderMenuAction { profile, descendants, ancestors, map }

class FamilyLeaderTopBarBadge extends StatelessWidget {
  const FamilyLeaderTopBarBadge({
    super.key,
    required this.person,
    required this.leadership,
    required this.onOpenProfile,
    required this.onMenuAction,
  });

  final Person person;
  final FamilyLeadership leadership;
  final VoidCallback onOpenProfile;
  final ValueChanged<FamilyLeaderMenuAction> onMenuAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 650;
    final colors = _styleColors(leadership.badgeStyle);

    final child = Tooltip(
      message: l10n.viewLeaderProfile,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpenProfile,
          child: Container(
            width: compact ? 52 : 220,
            height: compact ? 52 : 64,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 10,
              vertical: compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: compact
                ? _Avatar(
                    person: person,
                    colors: colors,
                    showPhoto: leadership.showLeaderPhoto,
                    officialPhoto: leadership.officialPhoto,
                  )
                : Row(
                    children: [
                      _Avatar(
                        person: person,
                        colors: colors,
                        showPhoto: leadership.showLeaderPhoto,
                        officialPhoto: leadership.officialPhoto,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: const Color(0xFF1F261B),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              leadership.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF63704D),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    return GestureDetector(
      onSecondaryTapDown: (details) =>
          _showContextMenu(context, details.globalPosition),
      onLongPressStart: (details) =>
          _showContextMenu(context, details.globalPosition),
      child: child,
    );
  }

  Future<void> _showContextMenu(BuildContext context, Offset position) async {
    final l10n = AppLocalizations.of(context);
    final action = await showMenu<FamilyLeaderMenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          value: FamilyLeaderMenuAction.profile,
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.badge_outlined),
            title: Text(l10n.viewProfile),
          ),
        ),
        const PopupMenuItem(
          value: FamilyLeaderMenuAction.descendants,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.account_tree_outlined),
            title: Text('Voir la descendance'),
          ),
        ),
        const PopupMenuItem(
          value: FamilyLeaderMenuAction.ancestors,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.family_restroom_outlined),
            title: Text('Voir l’ascendance'),
          ),
        ),
        PopupMenuItem(
          value: FamilyLeaderMenuAction.map,
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.location_on_outlined),
            title: Text(l10n.viewOnMap),
          ),
        ),
      ],
    );
    if (action != null) onMenuAction(action);
  }

  _LeaderBadgeColors _styleColors(String style) {
    return switch (style) {
      'gold' || 'royal' => const _LeaderBadgeColors(
        background: Color(0xFFFFF8E1),
        border: Color(0xFFE6C35C),
        avatar: Color(0xFFE8C15A),
      ),
      'green' || 'traditional' => const _LeaderBadgeColors(
        background: Color(0xFFEAF3DE),
        border: Color(0xFF8EAF66),
        avatar: Color(0xFFBBDD87),
      ),
      'simple' => const _LeaderBadgeColors(
        background: Color(0xFFFFFFFF),
        border: Color(0xFFE1E4DA),
        avatar: Color(0xFFDDEBC7),
      ),
      _ => const _LeaderBadgeColors(
        background: Color(0xFFFFFEF6),
        border: Color(0xFFD9C98E),
        avatar: Color(0xFFD6EAAE),
      ),
    };
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.person,
    required this.colors,
    required this.showPhoto,
    required this.officialPhoto,
  });

  final Person person;
  final _LeaderBadgeColors colors;
  final bool showPhoto;
  final String officialPhoto;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: colors.avatar,
          foregroundImage: _imageProvider,
          child: showPhoto && _imageProvider == null
              ? Text(
                  _initials(person),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF385E20),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                )
              : const Icon(
                  Icons.account_tree,
                  color: Color(0xFF385E20),
                  size: 24,
                ),
        ),
        Positioned(
          right: -4,
          top: -5,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFE2B845),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Icon(
              Icons.workspace_premium,
              size: 12,
              color: Color(0xFF5E4614),
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? get _imageProvider {
    final value = officialPhoto.trim().isNotEmpty
        ? officialPhoto.trim()
        : person.photo.trim();
    if (!showPhoto || value.isEmpty || !value.startsWith('http')) return null;
    return NetworkImage(value);
  }

  String _initials(Person person) {
    final first = person.firstName.trim();
    final last = person.lastName.trim();
    final value =
        '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}';
    return value.isEmpty ? '?' : value.toUpperCase();
  }
}

class _LeaderBadgeColors {
  const _LeaderBadgeColors({
    required this.background,
    required this.border,
    required this.avatar,
  });

  final Color background;
  final Color border;
  final Color avatar;
}
