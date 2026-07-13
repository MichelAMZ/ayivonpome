class BrandingSettings {
  const BrandingSettings({
    this.logoEnabled = true,
    this.logoUrl = '',
    this.cachedLogoUrl = '',
    this.defaultLogoUrl = 'assets/images/family_logo.png',
    this.logoFileName = '',
    this.logoMimeType = '',
    this.logoWidthDesktop = 140,
    this.logoWidthTablet = 92,
    this.logoWidthMobile = 52,
    this.logoPosition = 'leftOfTitle',
    this.logoFit = 'contain',
    this.logoShape = 'none',
    this.showMemberCountOnLogo = true,
    this.memberCountDisplayMode = 'onLogo',
    this.useAsFavicon = false,
    this.faviconUrl = '',
    this.logoVersion = 1,
    this.updatedAt = '',
    this.updatedBy = '',
  });

  final bool logoEnabled;
  final String logoUrl;
  final String cachedLogoUrl;
  final String defaultLogoUrl;
  final String logoFileName;
  final String logoMimeType;
  final double logoWidthDesktop;
  final double logoWidthTablet;
  final double logoWidthMobile;
  final String logoPosition;
  final String logoFit;
  final String logoShape;
  final bool showMemberCountOnLogo;
  final String memberCountDisplayMode;
  final bool useAsFavicon;
  final String faviconUrl;
  final int logoVersion;
  final String updatedAt;
  final String updatedBy;

  factory BrandingSettings.fromJson(Map<String, dynamic> json) {
    return BrandingSettings(
      logoEnabled: json['logoEnabled'] as bool? ?? true,
      logoUrl: json['logoUrl'] as String? ?? '',
      cachedLogoUrl: json['cachedLogoUrl'] as String? ?? '',
      defaultLogoUrl:
          json['defaultLogoUrl'] as String? ?? 'assets/images/family_logo.png',
      logoFileName: json['logoFileName'] as String? ?? '',
      logoMimeType: json['logoMimeType'] as String? ?? '',
      logoWidthDesktop: _clampWidth(
        json['logoWidthDesktop'],
        min: 64,
        max: 160,
        fallback: 140,
      ),
      logoWidthTablet: _clampWidth(
        json['logoWidthTablet'],
        min: 48,
        max: 110,
        fallback: 92,
      ),
      logoWidthMobile: _clampWidth(
        json['logoWidthMobile'],
        min: 36,
        max: 72,
        fallback: 52,
      ),
      logoPosition: _allowed(json['logoPosition'], const {
        'leftOfTitle',
        'rightOfTitle',
        'hidden',
      }, 'leftOfTitle'),
      logoFit: _allowed(json['logoFit'], const {'contain', 'cover'}, 'contain'),
      logoShape: _allowed(json['logoShape'], const {
        'none',
        'circle',
        'rounded',
      }, 'none'),
      showMemberCountOnLogo: json['showMemberCountOnLogo'] as bool? ?? true,
      memberCountDisplayMode: _allowed(json['memberCountDisplayMode'], const {
        'onLogo',
        'superscriptTitle',
        'bottomBar',
        'hidden',
      }, 'onLogo'),
      useAsFavicon: json['useAsFavicon'] as bool? ?? false,
      faviconUrl: json['faviconUrl'] as String? ?? '',
      logoVersion: json['logoVersion'] as int? ?? 1,
      updatedAt: json['updatedAt'] as String? ?? '',
      updatedBy: json['updatedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'logoEnabled': logoEnabled,
    'logoUrl': logoUrl,
    'cachedLogoUrl': cachedLogoUrl,
    'defaultLogoUrl': defaultLogoUrl,
    'logoFileName': logoFileName,
    'logoMimeType': logoMimeType,
    'logoWidthDesktop': logoWidthDesktop,
    'logoWidthTablet': logoWidthTablet,
    'logoWidthMobile': logoWidthMobile,
    'logoPosition': logoPosition,
    'logoFit': logoFit,
    'logoShape': logoShape,
    'showMemberCountOnLogo': showMemberCountOnLogo,
    'memberCountDisplayMode': memberCountDisplayMode,
    'useAsFavicon': useAsFavicon,
    'faviconUrl': faviconUrl,
    'logoVersion': logoVersion,
    'updatedAt': updatedAt,
    'updatedBy': updatedBy,
  };

  BrandingSettings copyWith({
    bool? logoEnabled,
    String? logoUrl,
    String? cachedLogoUrl,
    String? defaultLogoUrl,
    String? logoFileName,
    String? logoMimeType,
    double? logoWidthDesktop,
    double? logoWidthTablet,
    double? logoWidthMobile,
    String? logoPosition,
    String? logoFit,
    String? logoShape,
    bool? showMemberCountOnLogo,
    String? memberCountDisplayMode,
    bool? useAsFavicon,
    String? faviconUrl,
    int? logoVersion,
    String? updatedAt,
    String? updatedBy,
  }) {
    return BrandingSettings(
      logoEnabled: logoEnabled ?? this.logoEnabled,
      logoUrl: logoUrl ?? this.logoUrl,
      cachedLogoUrl: cachedLogoUrl ?? this.cachedLogoUrl,
      defaultLogoUrl: defaultLogoUrl ?? this.defaultLogoUrl,
      logoFileName: logoFileName ?? this.logoFileName,
      logoMimeType: logoMimeType ?? this.logoMimeType,
      logoWidthDesktop: logoWidthDesktop ?? this.logoWidthDesktop,
      logoWidthTablet: logoWidthTablet ?? this.logoWidthTablet,
      logoWidthMobile: logoWidthMobile ?? this.logoWidthMobile,
      logoPosition: logoPosition ?? this.logoPosition,
      logoFit: logoFit ?? this.logoFit,
      logoShape: logoShape ?? this.logoShape,
      showMemberCountOnLogo:
          showMemberCountOnLogo ?? this.showMemberCountOnLogo,
      memberCountDisplayMode:
          memberCountDisplayMode ?? this.memberCountDisplayMode,
      useAsFavicon: useAsFavicon ?? this.useAsFavicon,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      logoVersion: logoVersion ?? this.logoVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  BrandingSettings restoreDefault({
    String updatedAt = '',
    String updatedBy = '',
  }) {
    return BrandingSettings(
      logoVersion: logoVersion + 1,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  String get effectiveLogoUrl {
    if (logoUrl.trim().isNotEmpty) return logoUrl.trim();
    if (cachedLogoUrl.trim().isNotEmpty) return cachedLogoUrl.trim();
    return defaultLogoUrl;
  }

  bool get showLogo => logoEnabled && logoPosition != 'hidden';

  static double _clampWidth(
    Object? value, {
    required double min,
    required double max,
    required double fallback,
  }) {
    final parsed = value is num ? value.toDouble() : fallback;
    return parsed.clamp(min, max).toDouble();
  }

  static String _allowed(Object? value, Set<String> allowed, String fallback) {
    final parsed = value is String ? value : fallback;
    return allowed.contains(parsed) ? parsed : fallback;
  }
}
