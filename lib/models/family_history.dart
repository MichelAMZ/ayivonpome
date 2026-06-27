class FamilyHistory {
  const FamilyHistory({
    this.title = '',
    this.content = '',
    this.bannerImage = '',
    this.lastUpdatedAt = '',
    this.lastUpdatedByAdminId = '',
    this.lastUpdatedByName = '',
    this.maxCharacters = 5000,
  });

  final String title;
  final String content;
  final String bannerImage;
  final String lastUpdatedAt;
  final String lastUpdatedByAdminId;
  final String lastUpdatedByName;
  final int maxCharacters;

  factory FamilyHistory.fromJson(
    Map<String, dynamic> json, {
    int defaultMaxCharacters = 5000,
  }) => FamilyHistory(
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    bannerImage: json['bannerImage'] as String? ?? '',
    lastUpdatedAt: json['lastUpdatedAt'] as String? ?? '',
    lastUpdatedByAdminId: json['lastUpdatedByAdminId'] as String? ?? '',
    lastUpdatedByName: json['lastUpdatedByName'] as String? ?? '',
    maxCharacters: json['maxCharacters'] as int? ?? defaultMaxCharacters,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'bannerImage': bannerImage,
    'lastUpdatedAt': lastUpdatedAt,
    'lastUpdatedByAdminId': lastUpdatedByAdminId,
    'lastUpdatedByName': lastUpdatedByName,
    'maxCharacters': maxCharacters,
  };

  FamilyHistory copyWith({
    String? title,
    String? content,
    String? bannerImage,
    String? lastUpdatedAt,
    String? lastUpdatedByAdminId,
    String? lastUpdatedByName,
    int? maxCharacters,
  }) {
    return FamilyHistory(
      title: title ?? this.title,
      content: content ?? this.content,
      bannerImage: bannerImage ?? this.bannerImage,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lastUpdatedByAdminId: lastUpdatedByAdminId ?? this.lastUpdatedByAdminId,
      lastUpdatedByName: lastUpdatedByName ?? this.lastUpdatedByName,
      maxCharacters: maxCharacters ?? this.maxCharacters,
    );
  }
}
