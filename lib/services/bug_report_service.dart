import 'dart:convert';

import '../models/admin_user.dart';
import '../models/bug_report.dart';
import '../models/family_tree_data.dart';

class BugReportService {
  const BugReportService();

  List<BugReport> filter(
    FamilyTreeData data, {
    String status = 'all',
    String priority = 'all',
  }) {
    return data.bugReports.where((bug) {
      final statusOk = status == 'all' || bug.status == status;
      final priorityOk = priority == 'all' || bug.priority == priority;
      return statusOk && priorityOk;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<AdminUser> whatsappAdmins(FamilyTreeData data) {
    return data.admins
        .where(
          (admin) => admin.active && admin.whatsappNumber.trim().isNotEmpty,
        )
        .toList();
  }

  String whatsappMessage(BugReport bug) {
    return 'Nouveau bug signalé dans FamilyTreeApp :\n'
        'Titre : ${bug.title}\n'
        'Écran : ${bug.screen}\n'
        'Priorité : ${bug.priority}\n'
        'Déclaré par : ${bug.reportedByName}\n'
        'Date : ${bug.createdAt}\n'
        'Description : ${bug.description}';
  }

  String exportJson(List<BugReport> bugs) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(bugs.map((bug) => bug.toJson()).toList());
  }
}
