class BugReport {
  const BugReport({
    required this.id,
    required this.title,
    required this.description,
    this.screen = '',
    this.priority = 'medium',
    this.reportedByName = '',
    this.reportedByContact = '',
    this.screenshotPath = '',
    this.status = 'open',
    this.createdAt = '',
    this.notifiedAdmins = const [],
  });

  final String id;
  final String title;
  final String description;
  final String screen;
  final String priority;
  final String reportedByName;
  final String reportedByContact;
  final String screenshotPath;
  final String status;
  final String createdAt;
  final List<String> notifiedAdmins;

  factory BugReport.fromJson(Map<String, dynamic> json) => BugReport(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    screen: json['screen'] as String? ?? '',
    priority: json['priority'] as String? ?? 'medium',
    reportedByName: json['reportedByName'] as String? ?? '',
    reportedByContact: json['reportedByContact'] as String? ?? '',
    screenshotPath: json['screenshotPath'] as String? ?? '',
    status: json['status'] as String? ?? 'open',
    createdAt: json['createdAt'] as String? ?? '',
    notifiedAdmins: List<String>.from(
      json['notifiedAdmins'] as List? ?? const [],
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'screen': screen,
    'priority': priority,
    'reportedByName': reportedByName,
    'reportedByContact': reportedByContact,
    'screenshotPath': screenshotPath,
    'status': status,
    'createdAt': createdAt,
    'notifiedAdmins': notifiedAdmins,
  };

  BugReport copyWith({
    String? id,
    String? title,
    String? description,
    String? screen,
    String? priority,
    String? reportedByName,
    String? reportedByContact,
    String? screenshotPath,
    String? status,
    String? createdAt,
    List<String>? notifiedAdmins,
  }) {
    return BugReport(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      screen: screen ?? this.screen,
      priority: priority ?? this.priority,
      reportedByName: reportedByName ?? this.reportedByName,
      reportedByContact: reportedByContact ?? this.reportedByContact,
      screenshotPath: screenshotPath ?? this.screenshotPath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notifiedAdmins: notifiedAdmins ?? this.notifiedAdmins,
    );
  }
}
