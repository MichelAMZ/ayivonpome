import 'package:ayivonpome/models/admin_user.dart';
import 'package:ayivonpome/models/bug_report.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/services/bug_report_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BugReportService();

  const openUrgent = BugReport(
    id: 'bug001',
    title: 'Erreur affichage arbre',
    description: 'Les cartes sont trop espacées.',
    screen: 'TreeScreen',
    priority: 'urgent',
    status: 'open',
    reportedByName: 'Kossi Ayivon',
    createdAt: '2026-06-27T10:00:00',
  );

  const resolvedMedium = BugReport(
    id: 'bug002',
    title: 'Bouton invisible',
    description: 'Le bouton About manque.',
    screen: 'TopBar',
    priority: 'medium',
    status: 'resolved',
    createdAt: '2026-06-26T10:00:00',
  );

  test('filters reported bugs by status and priority', () {
    const data = FamilyTreeData(bugReports: [resolvedMedium, openUrgent]);

    expect(service.filter(data, status: 'open', priority: 'urgent'), [
      openUrgent,
    ]);
    expect(service.filter(data, status: 'resolved'), [resolvedMedium]);
  });

  test('returns active admins with WhatsApp numbers only', () {
    const data = FamilyTreeData(
      admins: [
        AdminUser(
          id: 'admin001',
          fullName: 'Admin Principal',
          role: 'admin',
          whatsappNumber: '+22890000000',
        ),
        AdminUser(
          id: 'admin002',
          fullName: 'Inactive Admin',
          role: 'admin',
          whatsappNumber: '+22891111111',
          active: false,
        ),
        AdminUser(id: 'admin003', fullName: 'No WhatsApp', role: 'admin'),
      ],
    );

    final admins = service.whatsappAdmins(data);

    expect(admins, hasLength(1));
    expect(admins.single.id, 'admin001');
  });

  test('builds WhatsApp message and JSON export', () {
    final message = service.whatsappMessage(openUrgent);
    final exported = service.exportJson([openUrgent]);

    expect(message, contains('Nouveau bug signalé dans FamilyTreeApp'));
    expect(message, contains('Titre : Erreur affichage arbre'));
    expect(message, contains('Priorité : urgent'));
    expect(exported, contains('"id": "bug001"'));
    expect(exported, contains('"notifiedAdmins": []'));
  });
}
