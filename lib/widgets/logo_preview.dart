import 'package:flutter/material.dart';

import '../models/branding_settings.dart';
import 'family_logo_widget.dart';

class LogoPreview extends StatelessWidget {
  const LogoPreview({
    super.key,
    required this.settings,
    required this.title,
    required this.membersCount,
  });

  final BrandingSettings settings;
  final String title;
  final int membersCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5DA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (settings.logoPosition == 'leftOfTitle') ...[
              FamilyLogoWidget(settings: settings, membersCount: membersCount),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF233A2A),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (settings.logoPosition == 'rightOfTitle') ...[
              const SizedBox(width: 14),
              FamilyLogoWidget(settings: settings, membersCount: membersCount),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.more_vert),
          ],
        ),
      ),
    );
  }
}
