import 'package:ayivonpome/models/firebase_user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseUserRole Firestore compatibility', () {
    test('reads an active admin with a familyIds list', () {
      final role = FirebaseUserRole.fromFirestore('uid-admin', {
        'role': 'admin',
        'active': true,
        'familyIds': ['ayivon'],
      });

      expect(role.role, 'admin');
      expect(role.active, isTrue);
      expect(role.familyIds, ['ayivon']);
    });

    test('reads a familyAdmin with a single familyId', () {
      final role = FirebaseUserRole.fromFirestore('uid-family-admin', {
        'role': 'familyAdmin',
        'isActive': true,
        'familyId': ' ayivon ',
      });

      expect(role.role, 'admin');
      expect(role.active, isTrue);
      expect(role.familyIds, ['ayivon']);
    });

    test('reads enabled and status active variants', () {
      expect(
        FirebaseUserRole.fromFirestore('uid-enabled', {
          'role': 'admin',
          'enabled': true,
          'familyId': 'ayivon',
        }).active,
        isTrue,
      );
      expect(
        FirebaseUserRole.fromFirestore('uid-status', {
          'role': 'superAdmin',
          'status': ' ACTIVE ',
          'familyIds': ['ayivon'],
        }).active,
        isTrue,
      );
    });

    test('keeps an inactive role inactive', () {
      final role = FirebaseUserRole.fromFirestore('uid-inactive', {
        'role': 'admin',
        'active': false,
        'familyIds': ['ayivon'],
      });

      expect(role.active, isFalse);
    });

    test('does not attach an admin to another family', () {
      final role = FirebaseUserRole.fromFirestore('uid-other-family', {
        'role': 'admin',
        'active': true,
        'familyIds': ['other-family'],
      });

      expect(role.familyIds, isNot(contains('ayivon')));
    });

    test('reads an active superAdmin', () {
      final role = FirebaseUserRole.fromFirestore('uid-super-admin', {
        'role': 'superAdmin',
        'active': true,
        'familyId': 'ayivon',
      });

      expect(role.isSuperAdmin, isTrue);
      expect(role.familyIds, contains('ayivon'));
    });

    test('unknown or absent role remains unprivileged', () {
      final absent = FirebaseUserRole.fromFirestore('uid-absent', {
        'active': true,
        'familyId': 'ayivon',
      });
      final unknown = FirebaseUserRole.fromFirestore('uid-unknown', {
        'role': 'owner',
        'active': true,
        'familyId': 'ayivon',
      });

      expect(absent.role, 'viewer');
      expect(absent.isSuperAdmin, isFalse);
      expect(unknown.role, 'viewer');
    });

    test('merges familyId and familyIds without duplicates', () {
      final ids = FirebaseUserRole.readFamilyIds({
        'familyId': 'ayivon',
        'familyIds': [' ayivon ', 'linked-family', ''],
      });

      expect(ids, ['ayivon', 'linked-family']);
    });
  });
}
