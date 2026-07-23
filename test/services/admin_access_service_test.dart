import 'package:ayivonpome/models/admin_access.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/services/admin_access_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = AdminAccessService();

  test('never grants admin access from locally stored codes', () {
    const data = FamilyTreeData(
      adminAccess: AdminAccess(currentAdminCode: 'TEST_ONLY_VALUE'),
    );

    expect(service.validate(data, 'TEST_ONLY_VALUE'), isFalse);
    expect(service.validate(data, 'INVALID_TEST_CODE'), isFalse);
  });

  test('rejects admin codes when persisted access is disabled', () {
    const data = FamilyTreeData(
      adminAccess: AdminAccess(
        currentAdminCode: 'TEST_ONLY_VALUE',
        enabled: false,
      ),
    );

    expect(service.validate(data, 'TEST_ONLY_VALUE'), isFalse);
  });

  test('normalizes whitespace in admin codes', () {
    expect(
      AdminAccessService.normalizeCode(' TEST ONLY VALUE\n'),
      'TESTONLYVALUE',
    );
  });

  test('local code rotation is disabled', () {
    expect(
      () => service.changeCode(
        data: const FamilyTreeData(),
        oldCode: 'TEST_ONLY_VALUE',
        newCode: 'PLACEHOLDER_NOT_A_SECRET',
        changedByAdminId: 'test',
      ),
      throwsStateError,
    );
  });
}
