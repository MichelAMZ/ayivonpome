import 'package:ayivonpome/l10n/app_localizations.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/widgets/family_leader_premium_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FamilyLeaderPremiumBadge shows leader name in compact mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: FamilyLeaderPremiumBadge(
              person: const Person(
                id: 'leader-1',
                firstName: 'Kossi',
                lastName: 'AYIVON',
              ),
              title: 'Chef actuel',
              subtitle: 'Patriarche de la famille',
              photo: '',
              compact: true,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Kossi AYIVON'), findsOneWidget);
    expect(find.text('Chef actuel'), findsOneWidget);
  });
}
