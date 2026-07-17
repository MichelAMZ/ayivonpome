import 'package:ayivonpome/screens/person_detail_formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  test('formats ISO profile dates for display', () async {
    await initializeDateFormatting('fr');

    expect(formatProfileDate('1942-02-10', 'fr'), '10 février 1942');
  });

  test('keeps non ISO dates unchanged', () {
    expect(formatProfileDate('vers 1942', 'fr'), 'vers 1942');
  });

  test('converts technical gender values for display', () {
    expect(formatProfileGender('M', 'Homme', 'Femme'), 'Homme');
    expect(formatProfileGender('F', 'Homme', 'Femme'), 'Femme');
    expect(formatProfileGender('unknown', 'Homme', 'Femme'), 'unknown');
  });
}
