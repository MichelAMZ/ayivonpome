import 'package:flutter/material.dart';

import '../models/branding_settings.dart';
import 'family_logo_widget.dart';

class TopbarFamilyLogo extends StatelessWidget {
  const TopbarFamilyLogo({
    super.key,
    required this.membersCount,
    required this.settings,
    this.showCounter = true,
  });

  final int membersCount;
  final BrandingSettings settings;
  final bool showCounter;

  @override
  Widget build(BuildContext context) {
    final mode = settings.memberCountDisplayMode;
    return FamilyLogoWidget(
      settings: settings,
      membersCount: membersCount,
      showCounter: showCounter && mode == 'onLogo',
    );
  }
}
