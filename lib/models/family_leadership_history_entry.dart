class FamilyLeadershipHistoryEntry {
  const FamilyLeadershipHistoryEntry({
    required this.personId,
    this.title = 'Chef de famille',
    this.startDate = '',
    this.endDate = '',
    this.notes = '',
  });

  final String personId;
  final String title;
  final String startDate;
  final String endDate;
  final String notes;

  factory FamilyLeadershipHistoryEntry.fromJson(Map<String, dynamic> json) =>
      FamilyLeadershipHistoryEntry(
        personId: json['personId'] as String? ?? '',
        title: json['title'] as String? ?? 'Chef de famille',
        startDate: json['startDate'] as String? ?? '',
        endDate: json['endDate'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'personId': personId,
    'title': title,
    'startDate': startDate,
    'endDate': endDate,
    'notes': notes,
  };
}
