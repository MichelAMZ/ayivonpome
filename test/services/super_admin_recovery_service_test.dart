import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/super_admin_recovery.dart';
import 'package:ayivonpome/services/super_admin_recovery_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validates the enabled Super Admin recovery code', () {
    const service = SuperAdminRecoveryService();
    const data = FamilyTreeData();

    expect(service.validate(data, ' Aziangbédévi2026! '), isTrue);
    expect(service.validate(data, 'ayivonvi2026'), isFalse);
  });

  test('rejects the recovery code when recovery is disabled', () {
    const service = SuperAdminRecoveryService();
    const data = FamilyTreeData(
      superAdminRecovery: SuperAdminRecovery(enabled: false),
    );

    expect(service.validate(data, 'Aziangbédévi2026!'), isFalse);
  });
}
