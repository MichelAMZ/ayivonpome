import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/person.dart';

enum FamilyLeaderMenuAction { profile, descendants, ancestors, map }

class FamilyLeaderPremiumBadge extends StatelessWidget {
  const FamilyLeaderPremiumBadge({
    super.key,
    required this.person,
    required this.title,
    required this.subtitle,
    required this.photo,
    required this.onTap,
    required this.compact,
    this.onMenuAction,
  });

  final Person person;
  final String title;
  final String subtitle;
  final String photo;
  final VoidCallback onTap;
  final bool compact;
  final ValueChanged<FamilyLeaderMenuAction>? onMenuAction;

  static const _green = Color(0xFF103C1C);
  static const _greenDeep = Color(0xFF082811);
  static const _greenLight = Color(0xFF1E5A2A);
  static const _gold = Color(0xFFE6B74A);
  static const _goldLight = Color(0xFFFFE59B);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = compact || width < 650;
    final tablet = !mobile && width < 1100;
    final badgeWidth = mobile ? 168.0 : (tablet ? 270.0 : 340.0);
    final badgeHeight = mobile ? 54.0 : (tablet ? 74.0 : 88.0);
    final radius = mobile ? 16.0 : 18.0;

    final badge = Tooltip(
      message: AppLocalizations.of(context).viewLeaderProfile,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 700),
      verticalOffset: 8,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Ink(
            width: badgeWidth,
            height: badgeHeight,
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 5 : 12,
              vertical: mobile ? 2 : 8,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_greenLight, _green, _greenDeep],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: _gold, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: mobile
                ? _MobileContent(person: person, title: title, photo: photo)
                : _FullContent(
                    person: person,
                    title: title,
                    subtitle: subtitle,
                    photo: photo,
                    tablet: tablet,
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
      child: badge,
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
          value: FamilyLeaderMenuAction.ancestors,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.family_restroom_outlined),
            title: Text('Voir l’ascendance'),
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
    if (action != null) onMenuAction?.call(action);
  }
}

class _FullContent extends StatelessWidget {
  const _FullContent({
    required this.person,
    required this.title,
    required this.subtitle,
    required this.photo,
    required this.tablet,
  });

  final Person person;
  final String title;
  final String subtitle;
  final String photo;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final avatarSize = tablet ? 52.0 : 64.0;

    return Row(
      children: [
        _LeaderPortrait(person: person, photo: photo, size: avatarSize),
        SizedBox(width: tablet ? 10 : 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: FamilyLeaderPremiumBadge._goldLight,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: FamilyLeaderPremiumBadge._goldLight,
                        fontSize: tablet ? 11 : 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: tablet ? 2 : 4),
              Text(
                person.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: tablet ? 18 : 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  height: 1.05,
                ),
              ),
              SizedBox(height: tablet ? 1 : 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFFFE7A8),
                  fontSize: tablet ? 12 : 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: tablet ? 8 : 10),
        Container(
          width: 1,
          height: tablet ? 44 : 56,
          color: FamilyLeaderPremiumBadge._gold.withValues(alpha: 0.72),
        ),
        SizedBox(width: tablet ? 7 : 9),
        _ShieldIcon(size: tablet ? 30 : 38),
      ],
    );
  }
}

class _MobileContent extends StatelessWidget {
  const _MobileContent({
    required this.person,
    required this.title,
    required this.photo,
  });

  final Person person;
  final String title;
  final String photo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LeaderPortrait(person: person, photo: photo, size: 34),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: FamilyLeaderPremiumBadge._goldLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderPortrait extends StatelessWidget {
  const _LeaderPortrait({
    required this.person,
    required this.photo,
    required this.size,
  });

  final Person person;
  final String photo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = _imageProvider;

    return SizedBox(
      width: size + 18,
      height: size + 12,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF8F5EA),
                border: Border.all(
                  color: FamilyLeaderPremiumBadge._gold,
                  width: size >= 60 ? 2.4 : 2,
                ),
                image: image == null
                    ? null
                    : DecorationImage(image: image, fit: BoxFit.cover),
              ),
              alignment: Alignment.center,
              child: image == null
                  ? Text(
                      _initials(person),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF17451F),
                        fontSize: size * 0.34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    )
                  : null,
            ),
          ),
          Positioned(
            top: -2,
            child: Icon(
              Icons.workspace_premium,
              size: size * 0.34,
              color: FamilyLeaderPremiumBadge._goldLight,
              shadows: const [
                Shadow(
                  color: Color(0x70000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? get _imageProvider {
    final value = photo.trim().isNotEmpty ? photo.trim() : person.photo.trim();
    if (value.isEmpty || !value.startsWith('http')) return null;
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

class _ShieldIcon extends StatelessWidget {
  const _ShieldIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShieldPainter(),
        child: Icon(
          Icons.park,
          color: FamilyLeaderPremiumBadge._goldLight,
          size: size * 0.52,
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.04)
      ..lineTo(size.width * 0.88, size.height * 0.18)
      ..lineTo(size.width * 0.84, size.height * 0.67)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.96,
        size.width * 0.16,
        size.height * 0.67,
      )
      ..lineTo(size.width * 0.12, size.height * 0.18)
      ..close();

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = FamilyLeaderPremiumBadge._goldLight;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
