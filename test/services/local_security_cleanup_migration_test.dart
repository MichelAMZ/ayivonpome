import 'dart:convert';

import 'package:ayivonpome/services/json_storage_service.dart';
import 'package:ayivonpome/services/local_security_cleanup_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('removes legacy local access data and is idempotent', () async {
    SharedPreferences.setMockInitialValues({
      'last_family_code': 'TEST_ONLY_VALUE',
      'admin_code': 'TEST_ONLY_VALUE',
    });
    final storage = _MemoryStorage(
      jsonEncode({
        'accessCodes': [
          {'code': 'TEST_ONLY_VALUE'},
        ],
        'modificationCodes': [
          {'code': 'TEST_ONLY_VALUE'},
        ],
        'adminAccess': {
          'currentAdminCode': 'TEST_ONLY_VALUE',
          'codeHistory': [
            {'code': 'TEST_ONLY_VALUE'},
          ],
          'enabled': true,
        },
        'superAdminRecovery': {
          'recoveryCode': 'TEST_ONLY_VALUE',
          'enabled': true,
          'allowResetAllCodes': true,
        },
      }),
    );
    final migration = LocalSecurityCleanupMigration(storage);

    expect(await migration.run(), isTrue);
    final cleaned = jsonDecode(storage.raw!) as Map<String, dynamic>;
    expect(cleaned['accessCodes'], isEmpty);
    expect(cleaned['modificationCodes'], isEmpty);
    expect(cleaned['adminAccess'], isNot(contains('currentAdminCode')));
    expect(cleaned['adminAccess'], isNot(contains('codeHistory')));
    expect(cleaned['superAdminRecovery'], isNot(contains('recoveryCode')));
    expect(cleaned['superAdminRecovery']['enabled'], isFalse);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('last_family_code'), isFalse);
    expect(preferences.containsKey('admin_code'), isFalse);
    expect(
      preferences.getInt('local_security_cleanup_version'),
      LocalSecurityCleanupMigration.version,
    );
    expect(await migration.run(), isFalse);
  });
}

class _MemoryStorage implements JsonStorageService {
  _MemoryStorage(this.raw);

  String? raw;

  @override
  Future<bool> exists() async => raw != null;

  @override
  Future<String?> readRaw() async => raw;

  @override
  Future<String> storageLocation() async => 'memory';

  @override
  Future<String> writeBackup(String contents) async => 'memory-backup';

  @override
  Future<void> writeRaw(String contents) async => raw = contents;
}
