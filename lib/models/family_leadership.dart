class FamilyLeadership {
  const FamilyLeadership({
    this.currentLeaderPersonId = '',
    this.formerLeaderPersonId = '',
    this.successorPersonId = '',
    this.title = 'Chef actuel',
    this.subtitle = 'Patriarche de la famille',
    this.showLeaderInTopBar = true,
    this.showLeaderBanner = false,
    this.showLeaderPhoto = true,
    this.showLeaderBadge = true,
    this.badgeStyle = 'premiumGreenGold',
    this.topBarLogoMode = 'leaderOnly',
    this.officialPhoto = '',
  });

  final String currentLeaderPersonId;
  final String formerLeaderPersonId;
  final String successorPersonId;
  final String title;
  final String subtitle;
  final bool showLeaderInTopBar;
  final bool showLeaderBanner;
  final bool showLeaderPhoto;
  final bool showLeaderBadge;
  final String badgeStyle;
  final String topBarLogoMode;
  final String officialPhoto;

  factory FamilyLeadership.fromJson(Map<String, dynamic> json) =>
      FamilyLeadership(
        currentLeaderPersonId: json['currentLeaderPersonId'] as String? ?? '',
        formerLeaderPersonId: json['formerLeaderPersonId'] as String? ?? '',
        successorPersonId: json['successorPersonId'] as String? ?? '',
        title: json['title'] as String? ?? 'Chef actuel',
        subtitle: json['subtitle'] as String? ?? 'Patriarche de la famille',
        showLeaderInTopBar: json['showLeaderInTopBar'] as bool? ?? true,
        showLeaderBanner: json['showLeaderBanner'] as bool? ?? false,
        showLeaderPhoto: json['showLeaderPhoto'] as bool? ?? true,
        showLeaderBadge: json['showLeaderBadge'] as bool? ?? true,
        badgeStyle: json['badgeStyle'] as String? ?? 'royal',
        topBarLogoMode: json['topBarLogoMode'] as String? ?? 'leaderOnly',
        officialPhoto: json['officialPhoto'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'currentLeaderPersonId': currentLeaderPersonId,
    'formerLeaderPersonId': formerLeaderPersonId,
    'successorPersonId': successorPersonId,
    'title': title,
    'subtitle': subtitle,
    'showLeaderInTopBar': showLeaderInTopBar,
    'showLeaderBanner': showLeaderBanner,
    'showLeaderPhoto': showLeaderPhoto,
    'showLeaderBadge': showLeaderBadge,
    'badgeStyle': badgeStyle,
    'topBarLogoMode': topBarLogoMode,
    'officialPhoto': officialPhoto,
  };

  FamilyLeadership copyWith({
    String? currentLeaderPersonId,
    String? formerLeaderPersonId,
    String? successorPersonId,
    String? title,
    String? subtitle,
    bool? showLeaderInTopBar,
    bool? showLeaderBanner,
    bool? showLeaderPhoto,
    bool? showLeaderBadge,
    String? badgeStyle,
    String? topBarLogoMode,
    String? officialPhoto,
  }) {
    return FamilyLeadership(
      currentLeaderPersonId:
          currentLeaderPersonId ?? this.currentLeaderPersonId,
      formerLeaderPersonId: formerLeaderPersonId ?? this.formerLeaderPersonId,
      successorPersonId: successorPersonId ?? this.successorPersonId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      showLeaderInTopBar: showLeaderInTopBar ?? this.showLeaderInTopBar,
      showLeaderBanner: showLeaderBanner ?? this.showLeaderBanner,
      showLeaderPhoto: showLeaderPhoto ?? this.showLeaderPhoto,
      showLeaderBadge: showLeaderBadge ?? this.showLeaderBadge,
      badgeStyle: badgeStyle ?? this.badgeStyle,
      topBarLogoMode: topBarLogoMode ?? this.topBarLogoMode,
      officialPhoto: officialPhoto ?? this.officialPhoto,
    );
  }
}
