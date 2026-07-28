import 'dart:io';

import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/providers/auth_provider.dart';
import 'package:ayivonpome/widgets/person_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tree metrics keep member cards compact on every breakpoint', () {
    final source = File(
      'lib/widgets/family_tree_canvas.dart',
    ).readAsStringSync();

    expect(source, contains('compactCardWidth = 92.0'));
    expect(source, contains('standardCardWidth = 100.0'));
    expect(source, contains('compactCardHeight = 158.0'));
    expect(source, contains('standardCardHeight = 168.0'));
    expect(source, isNot(contains('cardWidth: 430')));
    expect(source, isNot(contains('cardWidth: 360')));
    expect(source, isNot(contains('cardWidth: 310')));
  });

  test('compact card keeps essential content and interactions', () {
    final source = File('lib/widgets/person_card.dart').readAsStringSync();
    final compactCard = source.substring(
      source.indexOf('Widget _buildCompactTreeCard'),
      source.indexOf('String get _displayLocation'),
    );

    expect(compactCard, contains('width: 56'));
    expect(compactCard, contains('height: 64'));
    expect(compactCard, contains('fit: BoxFit.cover'));
    expect(compactCard, contains('avatarFallback()'));
    expect(compactCard, contains('widget.person.lastName.toUpperCase()'));
    expect(compactCard, contains('widget.person.firstName'));
    expect(compactCard, contains('_genderSymbol'));
    expect(compactCard, contains('birthYear'));
    expect(compactCard, contains('overflow: TextOverflow.ellipsis'));
    expect(compactCard, contains('onTap: widget.onOpen'));
    expect(compactCard, contains('_showContextMenu'));
    expect(compactCard, contains('minWidth: 44'));
    expect(compactCard, contains('minHeight: 44'));
    expect(compactCard, contains('_GenerationBadge'));
    expect(compactCard, contains('Icons.workspace_premium'));
    expect(compactCard, isNot(contains('_displayLocation')));
    expect(compactCard, isNot(contains('_mapAddress')));
  });

  test('link anchors remain derived from compact card rectangles', () {
    final source = File(
      'lib/widgets/family_tree_canvas.dart',
    ).readAsStringSync();
    final painter = source.substring(
      source.indexOf('void _drawFamilyUnitConnectors'),
      source.indexOf('void _drawDashedLine'),
    );

    expect(painter, contains('rect.bottomCenter'));
    expect(painter, contains('rect.topCenter'));
    expect(painter, contains('parentAnchor.dx'));
    expect(painter, contains('childTop.dx'));
  });

  testWidgets('compact card has no overflow and remains clickable', (
    tester,
  ) async {
    var opened = false;
    const person = Person(
      id: 'member-1',
      firstName: 'PrénomExtrêmementLong',
      lastName: 'NomDeFamilleExtrêmementLong',
      gender: 'male',
      birthDate: '2000-04-12',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: PersonCard(
                person: person,
                data: const FamilyTreeData(people: [person]),
                authMode: AuthMode.publicLimited,
                width: 92,
                height: 158,
                compact: true,
                onOpen: () => opened = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('PN'), findsOneWidget);
    expect(find.text('NOMDEFAMILLEEXTRÊMEMENTLONG'), findsOneWidget);
    expect(find.text('PrénomExtrêmementLong'), findsOneWidget);
    expect(find.text('2000'), findsOneWidget);

    final surname = tester.widget<Text>(
      find.text('NOMDEFAMILLEEXTRÊMEMENTLONG'),
    );
    final firstName = tester.widget<Text>(find.text('PrénomExtrêmementLong'));
    expect(surname.overflow, TextOverflow.ellipsis);
    expect(firstName.overflow, TextOverflow.ellipsis);

    await tester.tap(find.byType(PersonCard));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('branch toggle is accessible and does not open the member', (
    tester,
  ) async {
    var opened = false;
    var toggled = false;
    const person = Person(
      id: 'parent',
      firstName: 'Parent',
      lastName: 'Ayivon',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: PersonCard(
                person: person,
                data: const FamilyTreeData(people: [person]),
                authMode: AuthMode.publicLimited,
                width: 92,
                height: 158,
                compact: true,
                hasDescendants: true,
                branchCollapsed: true,
                descendantCount: 8,
                onToggleBranch: () => toggled = true,
                onOpen: () => opened = true,
              ),
            ),
          ),
        ),
      ),
    );

    final toggle = find.byKey(const ValueKey('branch-toggle-parent'));
    expect(toggle, findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.byTooltip('Afficher les descendants'), findsOneWidget);
    expect(tester.getSize(toggle), const Size(44, 44));

    await tester.tap(toggle);
    expect(toggled, isTrue);
    expect(opened, isFalse);
    expect(tester.takeException(), isNull);
  });
}
