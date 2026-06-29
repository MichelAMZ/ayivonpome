import 'package:ayivonpome/models/access_code.dart';
import 'package:ayivonpome/models/admin_access.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/services/admin_access_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = AdminAccessService();

  test('validates current admin code and active admin KPI access codes', () {
    const data = FamilyTreeData(
      adminAccess: AdminAccess(currentAdminCode: 'customAdmin2026'),
      accessCodes: [
        AccessCode(
          id: 'code002',
          code: 'ayivonvi2026',
          label: 'Code Admin KPI',
          type: 'adminKpi',
          role: 'admin',
        ),
      ],
    );

    expect(service.validate(data, 'customAdmin2026'), isTrue);
    expect(service.validate(data, 'ayivonvi2026'), isTrue);
    expect(service.validate(data, 'bad-code'), isFalse);
  });

  test('keeps expected admin code valid when persisted access is disabled', () {
    const data = FamilyTreeData(
      adminAccess: AdminAccess(
        currentAdminCode: 'oldPersistedCode',
        enabled: false,
      ),
    );

    expect(service.validate(data, 'ayivonvi2026'), isTrue);
    expect(service.validate(data, 'oldPersistedCode'), isFalse);
  });

  test('normalizes whitespace in admin codes', () {
    expect(
      AdminAccessService.normalizeCode(' ayivonvi 2026\n'),
      AdminAccessService.defaultAdminCode,
    );
  });
}
