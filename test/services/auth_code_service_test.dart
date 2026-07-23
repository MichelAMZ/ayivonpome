import 'package:ayivonpome/models/family_code.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/services/auth_code_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = AuthCodeService();

  test('does not derive a UI role from an accepted family code', () {
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

    expect(session, isNull);
  });

  test('does not treat the main family identifier as authentication', () {
    const data = FamilyTreeData(mainFamilyCode: 'ayivon');

    final session = service.verifyCode(data, 'ayivon');

    expect(session, isNull);
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
