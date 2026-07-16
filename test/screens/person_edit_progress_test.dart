import 'package:ayivonpome/screens/person_edit_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates profile progress from required non-empty fields', () {
    var firstName = 'Ada';
    var lastName = ' ';
    var familyCode = 'AMOUZOU2026';

    ProfileProgress progress() => ProfileProgress.fromFields([
      ProfileRequiredField(
        id: 'firstName',
        stepIndex: 0,
        label: 'Prénom',
        value: () => firstName,
      ),
      ProfileRequiredField(
        id: 'lastName',
        stepIndex: 0,
        label: 'Nom',
        value: () => lastName,
      ),
      ProfileRequiredField(
        id: 'familyCode',
        stepIndex: 1,
        label: 'Famille',
        value: () => familyCode,
      ),
    ]);

    expect(progress().completedRequired, 2);
    expect(progress().missingRequired, 1);
    expect(progress().percent, 67);
    expect(progress().stepPercent(0), 50);
    expect(progress().stepPercent(1), 100);

    lastName = 'Lovelace';

    expect(progress().completedRequired, 3);
    expect(progress().missingRequired, 0);
    expect(progress().percent, 100);
  });

  test('optional fields are excluded from required progress', () {
    final progress = ProfileProgress.fromFields([
      ProfileRequiredField(
        id: 'firstName',
        stepIndex: 0,
        label: 'Prénom',
        value: () => 'Grace',
      ),
    ]);

    expect(progress.percent, 100);
    expect(progress.missingRequired, 0);
  });
}
