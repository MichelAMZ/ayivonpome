import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../providers/auth_provider.dart';

class PatriarchHonorBadge extends StatelessWidget {
  const PatriarchHonorBadge({
    super.key,
    required this.person,
    required this.authMode,
    required this.style,
    required this.onOpen,
  });

  final Person person;
  final AuthMode authMode;
  final String style;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = _colorsFor(style);
    final details = _details;
    return Tooltip(
      message: l10n.viewPatriarchProfile,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpen,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x16000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: colors.iconBackground,
                  foregroundColor: colors.icon,
                  child: const Icon(Icons.workspace_premium, size: 25),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.patriarch,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.label,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        person.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.label,
                                fontWeight: FontWeight.w600,
                              ),
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
    );
  }

  String get _details {
    if (authMode != AuthMode.authenticated) return '';
    final years = [
      if (person.birthDate.length >= 4) person.birthDate.substring(0, 4),
      if (person.deathDate.length >= 4) person.deathDate.substring(0, 4),
    ];
    final yearText = years.isEmpty ? '' : years.join(' - ');
    return [
      if (yearText.isNotEmpty) yearText,
      if (person.familyCode.isNotEmpty) person.familyCode,
    ].join(' · ');
  }

  _BadgeColors _colorsFor(String style) {
    return switch (style) {
      'gold' => const _BadgeColors(
        background: Color(0xFFFFF8E0),
        border: Color(0xFFE7C76B),
        iconBackground: Color(0xFFFFE7A4),
        icon: Color(0xFF9B6A00),
        label: Color(0xFF7A5A11),
        text: Color(0xFF2F2715),
      ),
      'green' => const _BadgeColors(
        background: Color(0xFFEFF7E6),
        border: Color(0xFFC8DDB3),
        iconBackground: Color(0xFFD9F0BE),
        icon: Color(0xFF4A7B24),
        label: Color(0xFF527333),
        text: Color(0xFF223319),
      ),
      'simple' => const _BadgeColors(
        background: Color(0xFFFFFFFF),
        border: Color(0xFFE2E4DB),
        iconBackground: Color(0xFFF1F3EA),
        icon: Color(0xFF66704F),
        label: Color(0xFF64685E),
        text: Color(0xFF20231E),
      ),
      _ => const _BadgeColors(
        background: Color(0xFFFFFBEC),
        border: Color(0xFFE2D4A2),
        iconBackground: Color(0xFFF5D979),
        icon: Color(0xFF7B5A0B),
        label: Color(0xFF658044),
        text: Color(0xFF1F2418),
      ),
    };
  }
}

class _BadgeColors {
  const _BadgeColors({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.icon,
    required this.label,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color iconBackground;
  final Color icon;
  final Color label;
  final Color text;
}
