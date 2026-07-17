import 'dart:io';

import 'package:ayivonpome/l10n/app_localizations_en.dart';
import 'package:ayivonpome/l10n/app_localizations_fr.dart';
import 'package:ayivonpome/models/marriage_relation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('customary marriage label replaces the old visible French wording', () {
    final l10n = AppLocalizationsFr();

    expect(l10n.traditionalMarriage, 'Mariage coutumier');
    expect(l10n.traditionalMarriageDate, 'Date du mariage coutumier');
    expect(l10n.traditionalMarriage, isNot(contains('traditionnel')));
    expect(l10n.traditionalMarriageDate, isNot(contains('traditionnel')));
  });

  test('customary marriage label replaces the old visible English wording', () {
    final l10n = AppLocalizationsEn();

    expect(l10n.traditionalMarriage, 'Customary marriage');
    expect(l10n.traditionalMarriageDate, 'Customary marriage date');
    expect(l10n.traditionalMarriage, isNot(contains('Traditional marriage')));
    expect(
      l10n.traditionalMarriageDate,
      isNot(contains('Traditional marriage')),
    );
  });

  test('legacy customary records keep the existing technical value', () {
    final parsed = MarriageRelation.fromJson({
      'id': 'm1',
      'personId': 'p1',
      'spouseId': 'p2',
      'marriageType': 'customary',
      'marriageDate': '1985-02-01',
    });

    expect(parsed.marriageType, 'traditional');
    expect(parsed.toJson()['marriageType'], 'traditional');
    expect(parsed.traditionalMarriageDate, '1985-02-01');
  });

  test('visible localization sources no longer contain the old label', () {
    final oldLabels = [
      'Mariage traditionnel',
      'mariage traditionnel',
      'Traditional marriage',
      'traditional marriage',
      'Matrimonio tradicional',
      'matrimonio tradicional',
      'Casamento tradicional',
      'casamento tradicional',
    ];
    final localizationFiles = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.arb') ||
              file.path.contains('app_localizations'),
        );

    for (final file in localizationFiles) {
      final content = file.readAsStringSync();
      for (final oldLabel in oldLabels) {
        expect(
          content,
          isNot(contains(oldLabel)),
          reason: '${file.path} still contains "$oldLabel"',
        );
      }
    }
  });
}
