class FamilyHonor {
  const FamilyHonor({
    this.patriarchPersonId = '',
    this.showPatriarchBadge = true,
    this.badgePosition = 'topLeft',
    this.badgeStyle = 'premium',
  });

  final String patriarchPersonId;
  final bool showPatriarchBadge;
  final String badgePosition;
  final String badgeStyle;

  factory FamilyHonor.fromJson(Map<String, dynamic> json) => FamilyHonor(
    patriarchPersonId: json['patriarchPersonId'] as String? ?? '',
    showPatriarchBadge: json['showPatriarchBadge'] as bool? ?? true,
    badgePosition: json['badgePosition'] as String? ?? 'topLeft',
    badgeStyle: json['badgeStyle'] as String? ?? 'premium',
  );

  Map<String, dynamic> toJson() => {
    'patriarchPersonId': patriarchPersonId,
    'showPatriarchBadge': showPatriarchBadge,
    'badgePosition': badgePosition,
    'badgeStyle': badgeStyle,
  };

  FamilyHonor copyWith({
    String? patriarchPersonId,
    bool? showPatriarchBadge,
    String? badgePosition,
    String? badgeStyle,
  }) {
    return FamilyHonor(
      patriarchPersonId: patriarchPersonId ?? this.patriarchPersonId,
      showPatriarchBadge: showPatriarchBadge ?? this.showPatriarchBadge,
      badgePosition: badgePosition ?? this.badgePosition,
      badgeStyle: badgeStyle ?? this.badgeStyle,
    );
  }
}
