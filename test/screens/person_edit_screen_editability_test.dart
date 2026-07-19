import 'package:ayivonpome/l10n/app_localizations.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/providers/family_tree_provider.dart';
import 'package:ayivonpome/screens/person_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const child = Person(
  id: 'p001',
  firstName: 'Djidonou',
  lastName: 'AMOUZOU',
  gender: 'male',
  birthDate: '1942-02-10',
  familyCode: 'AYIVON',
  fatherId: 'p002',
);
const father = Person(
  id: 'p002',
  firstName: 'Amouzou',
  lastName: 'Aziangbédé',
  gender: 'male',
  birthDate: '1900',
  birthPlace: 'Bassadji',
  familyCode: 'AYIVON',
);

void main() {
  testWidgets('identity fields remain editable', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: PersonEditScreen(
            person: Person(
              id: 'p001',
              firstName: 'Djidonou',
              lastName: 'AMOUZOU',
              gender: 'male',
              birthDate: '1942-02-10',
              familyCode: 'AYIVON',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('firstNameField')));
    await tester.enterText(
      find.byKey(const ValueKey('firstNameField')),
      'Édouard',
    );
    await tester.tap(find.byKey(const ValueKey('lastNameField')));
    await tester.enterText(find.byKey(const ValueKey('lastNameField')), '');

    expect(find.text('Édouard'), findsOneWidget);
    expect(find.text('Djidonou'), findsNothing);
    expect(find.text('AMOUZOU'), findsNothing);
  });

  testWidgets('existing father field suggests and selects a loaded member', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyTreeProvider.overrideWith(_TestFamilyTreeController.new),
        ],
        child: const MaterialApp(
          locale: Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: PersonEditScreen(person: child),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Relations'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('existing-member-fatherId')),
      'AMOUZ',
    );
    await tester.pumpAndSettle();

    expect(find.text('Amouzou Aziangbédé'), findsWidgets);

    await tester.tap(find.text('Amouzou Aziangbédé').last);
    await tester.pumpAndSettle();

    expect(find.text('Amouzou Aziangbédé'), findsWidgets);
    expect(find.text('Bassadji'), findsOneWidget);
  });
}

class _TestFamilyTreeController extends FamilyTreeController {
  @override
  Future<FamilyTreeData> build() async {
    return const FamilyTreeData(people: [child, father]);
  }
}
