import 'package:ayivonpome/models/family_code.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/services/auth_code_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = AuthCodeService();

  test('uses accepted family code role instead of elevating main code', () {
    const data = FamilyTreeData(
      mainFamilyCode: 'ayivon',
      familyCodes: [
        FamilyCode(
          code: 'ayivon',
          familyName: 'Famille AYIVON',
          role: 'owner',
          status: 'accepted',
        ),
      ],
    );

    final session = service.verifyCode(data, ' AYIVON ');

    expect(session, isNotNull);
    expect(session!.familyCode, 'ayivon');
    expect(session.role, 'owner');
    expect(session.isSuperAdmin, isFalse);
  });

  test('falls back to viewer for main code when no family code exists', () {
    const data = FamilyTreeData(mainFamilyCode: 'ayivon');

    final session = service.verifyCode(data, 'ayivon');

    expect(session, isNotNull);
    expect(session!.role, 'viewer');
    expect(session.isSuperAdmin, isFalse);
  });

  test('rejects inactive or unknown family codes', () {
    const data = FamilyTreeData(
      mainFamilyCode: 'ayivon',
      familyCodes: [
        FamilyCode(
          code: 'linked',
          familyName: 'Linked family',
          role: 'owner',
          status: 'pending',
        ),
      ],
    );

    expect(service.verifyCode(data, 'linked'), isNull);
    expect(service.verifyCode(data, 'unknown'), isNull);
  });
}
