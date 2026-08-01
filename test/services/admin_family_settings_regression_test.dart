import 'dart:io';

import 'package:ayivonpome/services/info_news_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default banner message is shared with the admin editor', () {
    const service = InfoNewsService();
    final news = service.defaultNews('Conseil AYIVON');

    expect(news.id, InfoNewsService.defaultInfoNewsId);
    expect(news.message, contains('Conseil AYIVON'));
    expect(news.isActive, isTrue);
  });

  test(
    'admin settings use verified Firebase identity and reactive leader key',
    () {
      final source = File(
        'lib/screens/admin_dashboard_screen.dart',
      ).readAsStringSync();

      expect(source, contains('defaultNews('));
      expect(source, contains('news.copyWith(id: \'\')'));
      expect(source, contains('auth.firebaseRole ?? auth.session?.role'));
      expect(source, contains('adminId: auth.firebaseUid ?? \'\''));
      expect(source, contains('family-leader-\${selectedLeader?.id'));
      expect(source, contains('onChanged: canManage'));
    },
  );

  test('family leader updates reject invalid roles and missing members', () {
    final source = File(
      'lib/providers/family_tree_provider.dart',
    ).readAsStringSync();
    final method = source.substring(
      source.indexOf('Future<void> updateFamilyLeadership'),
      source.indexOf('Future<void> markChangeNotificationsSeen'),
    );

    expect(method, contains("actorRole != 'superAdmin'"));
    expect(method, contains("actorRole != 'admin'"));
    expect(method, contains("StateError('family_leader_not_found')"));
    expect(method, contains('person.deletedAt.isEmpty'));
    expect(method, contains('.updateFamilyLeadership(familyLeadership)'));
  });

  test('member deletion cleans remote branch links with allowed fields', () {
    final source = File(
      'lib/data/firestore/firestore_remote_database_client.dart',
    ).readAsStringSync();
    final method = source.substring(
      source.indexOf('Future<void> deletePerson'),
      source.indexOf('Future<User> _requireFirebaseAdminForFamily'),
    );

    expect(method, contains('affectedFamilyLinks'));
    expect(method, isNot(contains('settingsSnapshot')));
    expect(method, isNot(contains("'version':")));
    expect(method, contains('_confirmPersonDeletionOnServer'));
    expect(method, contains('GetOptions(source: Source.server)'));
    expect(method, contains("'isDeleted': true"));
    expect(method, contains("'deletedBy': user.uid"));
    expect(method, contains("'visibility': 'hidden'"));
    expect(method, contains("'isActive': false"));
    expect(method, contains("'isVisible': false"));
  });

  test('JSON restoration is confirmed remotely before the local save', () {
    final source = File(
      'lib/providers/family_tree_provider.dart',
    ).readAsStringSync();
    final method = source.substring(
      source.indexOf('Future<void> importData'),
      source.indexOf('Future<String?> _readBundledFamilyJson'),
    );

    expect(method, contains('.restoreFamilyTree(restored)'));
    expect(
      method.indexOf('.restoreFamilyTree(restored)'),
      lessThan(method.indexOf('await save(restored)')),
    );
  });
}
