import 'package:ayivonpome/models/audit_log.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/providers/auth_provider.dart';
import 'package:ayivonpome/widgets/activity_journal_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const data = FamilyTreeData(
    mainFamilyCode: 'Famille Test',
    auditLog: [
      AuditLog(
        id: 'new',
        date: '2026-07-20T12:00:00Z',
        action: 'sync_remote_success',
        actorRole: 'admin',
      ),
      AuditLog(
        id: 'old',
        date: '2026-07-19T12:00:00Z',
        action: 'authorization_failed',
        actorRole: 'editor',
        personId: 'member-42',
      ),
    ],
  );

  testWidgets('shows real KPIs, translated labels and admin selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        data,
        const AuthState(
          restoreStatus: SessionRestoreStatus.authenticated,
          firebaseUid: 'admin-uid',
          firebaseRole: 'admin',
        ),
      ),
    );

    expect(find.text('Activités totales'), findsOneWidget);
    expect(find.text('Synchronisation réussie'), findsWidgets);
    expect(find.byType(Checkbox), findsNWidgets(3));
    expect(find.textContaining('Famille Test'), findsOneWidget);
  });

  testWidgets('editor sees no destructive selection controls', (tester) async {
    await tester.pumpWidget(
      _app(
        data,
        const AuthState(
          restoreStatus: SessionRestoreStatus.authenticated,
          firebaseUid: 'editor-uid',
          firebaseRole: 'editor',
        ),
      ),
    );

    expect(find.byType(Checkbox), findsNothing);
    expect(find.byKey(const Key('delete-selected-activities')), findsNothing);
  });

  testWidgets('debounced search filters activities without mobile overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(data, const AuthState()));

    await tester.enterText(
      find.byKey(const Key('activity-search')),
      'member-42',
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Autorisation refusée'), findsOneWidget);
    expect(find.text('Synchronisation réussie'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(FamilyTreeData data, AuthState auth) => ProviderScope(
  child: MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ActivityJournalPanel(data: data, auth: auth),
      ),
    ),
  ),
);
