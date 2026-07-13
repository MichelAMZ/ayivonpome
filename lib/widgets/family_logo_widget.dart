import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/branding_settings.dart';
import 'responsive.dart';

class FamilyLogoWidget extends StatelessWidget {
  const FamilyLogoWidget({
    super.key,
    required this.settings,
    required this.membersCount,
    this.showCounter,
  });

  final BrandingSettings settings;
  final int membersCount;
  final bool? showCounter;

  @override
  Widget build(BuildContext context) {
    if (!settings.showLogo) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width <= ResponsiveBreakpoints.mobileMax;
    final tablet = width <= ResponsiveBreakpoints.tabletMax;
    final logoSize = mobile
        ? settings.logoWidthMobile
        : tablet
        ? settings.logoWidthTablet
        : settings.logoWidthDesktop;
    final displayCounter =
        showCounter ?? settings.memberCountDisplayMode == 'onLogo';

    return SizedBox(
      width: logoSize,
      height: logoSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: _borderRadius(logoSize),
            child: SizedBox(
              width: logoSize,
              height: logoSize,
              child: Padding(
                padding: EdgeInsets.all(logoSize * 0.02),
                child: _LogoImage(settings: settings),
              ),
            ),
          ),
          if (displayCounter)
            Positioned(
              top: mobile ? -2 : -8,
              child: _MemberCountBadge(
                count: membersCount,
                compact: mobile,
                large: width > ResponsiveBreakpoints.tabletMax,
              ),
            ),
        ],
      ),
    );
  }

  BorderRadius _borderRadius(double size) {
    return switch (settings.logoShape) {
      'circle' => BorderRadius.circular(size),
      'rounded' => BorderRadius.circular(14),
      _ => BorderRadius.zero,
    };
  }
}

class _LogoImage extends StatelessWidget {
  const _LogoImage({required this.settings});

  final BrandingSettings settings;

  @override
  Widget build(BuildContext context) {
    final url = settings.effectiveLogoUrl;
    final fit = settings.logoFit == 'cover' ? BoxFit.cover : BoxFit.contain;
    if (url.startsWith('data:')) {
      final bytes = _decodeDataUrl(url);
      if (bytes != null) {
        return Image.memory(bytes, fit: fit, errorBuilder: _fallback);
      }
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(url, fit: fit, errorBuilder: _fallback);
    }
    return Image.asset(url, fit: fit, errorBuilder: _fallback);
  }

  Widget _fallback(BuildContext context, Object error, StackTrace? stackTrace) {
    return Image.asset(settings.defaultLogoUrl, fit: BoxFit.contain);
  }

  Uint8List? _decodeDataUrl(String value) {
    final comma = value.indexOf(',');
    if (comma == -1) return null;
    try {
      return base64Decode(value.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }
}

class _MemberCountBadge extends StatelessWidget {
  const _MemberCountBadge({
    required this.count,
    required this.compact,
    required this.large,
  });

  final int count;
  final bool compact;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 20 : 26),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 10,
        vertical: compact ? 1 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3C65B), width: 1),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x1A000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        count.toString(),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF4F6F1F),
          fontSize: compact
              ? 10
              : large
              ? 28
              : 18,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
