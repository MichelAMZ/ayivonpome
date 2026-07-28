import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/screens/admin_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSettingsHeader(
    WidgetTester tester, {
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: AdminSettingsHeader(data: FamilyTreeData()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('admin settings header keeps title and sync state on desktop', (
    tester,
  ) async {
    await pumpSettingsHeader(tester, size: const Size(1280, 800));

    expect(find.text('Paramètres de l’application'), findsOneWidget);
    expect(
      find.text(
        'Configurez l’identité, l’affichage et les informations de la famille.',
      ),
      findsOneWidget,
    );
    expect(find.text('Synchronisé'), findsOneWidget);
    expect(find.text('Modifier le titre'), findsOneWidget);
    expect(find.text('Recalculer les générations'), findsOneWidget);
    expect(find.text('Recharger les données'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin settings header remains responsive on tablet', (
    tester,
  ) async {
    await pumpSettingsHeader(tester, size: const Size(768, 900));

    expect(find.text('Paramètres de l’application'), findsOneWidget);
    expect(find.text('Synchronisé'), findsOneWidget);
    expect(find.text('Recharger les données'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin settings header has no horizontal overflow on mobile', (
    tester,
  ) async {
    await pumpSettingsHeader(tester, size: const Size(360, 740));

    expect(find.text('Paramètres de l’application'), findsOneWidget);
    expect(find.text('Synchronisé'), findsOneWidget);
    expect(find.text('Modifier le titre'), findsOneWidget);
    expect(find.text('Recalculer les générations'), findsOneWidget);
    expect(find.text('Recharger les données'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin settings section card exposes its hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminSettingsSectionCard(
            icon: Icons.tune,
            title: 'Application',
            description: 'Configuration générale',
            child: Text('Réglage'),
          ),
        ),
      ),
    );

    expect(find.text('Application'), findsOneWidget);
    expect(find.text('Configuration générale'), findsOneWidget);
    expect(find.text('Réglage'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
