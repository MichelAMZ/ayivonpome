import 'package:ayivonpome/models/access_code.dart';
import 'package:ayivonpome/services/access_code_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = AccessCodeService();

  test('generates secure prefixed codes without ambiguous characters', () {
    final code = service.generateSecureCode('adminKpi');

    expect(
      code,
      matches(RegExp(r'^ADMIN-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$')),
    );
    expect(code.split('-').skip(1).join().contains(RegExp(r'[0OI1]')), isFalse);
  });

  test('restricts regeneration for simple admins', () {
    const superAdminCode = AccessCode(
      id: 'code001',
      code: 'ADMIN-AAAA-BBBB',
      label: 'Super admin',
      type: 'adminKpi',
      role: 'superAdmin',
      createdByAdminId: 'superAdmin001',
    );
    const ownCode = AccessCode(
      id: 'code002',
      code: 'TEMP-AAAA-BBBB',
      label: 'Temporary',
      type: 'temporary',
      role: 'editor',
      createdByAdminId: 'admin001',
    );

    expect(
      service.canRegenerate(
        superAdminCode,
        actorRole: 'admin',
        adminId: 'admin001',
      ),
      isFalse,
    );
    expect(
      service.canRegenerate(ownCode, actorRole: 'admin', adminId: 'admin001'),
      isTrue,
    );
    expect(
      service.canRegenerate(
        superAdminCode,
        actorRole: 'superAdmin',
        adminId: 'superAdmin001',
      ),
      isTrue,
    );
  });
}
