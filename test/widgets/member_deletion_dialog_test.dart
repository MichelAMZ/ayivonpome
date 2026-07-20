import 'dart:async';

import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/providers/auth_provider.dart';
import 'package:ayivonpome/services/auth_code_service.dart';
import 'package:ayivonpome/widgets/member_deletion_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only a live Firebase admin session exposes secure deletion', () {
    const localAdmin = AuthState(
      mode: AuthMode.authenticated,
      restoreStatus: SessionRestoreStatus.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'admin'),
    );
    const editor = AuthState(
      mode: AuthMode.authenticated,
      restoreStatus: SessionRestoreStatus.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'editor'),
      firebaseUid: 'editor-uid',
      firebaseRole: 'editor',
    );
    const firebaseAdmin = AuthState(
      mode: AuthMode.authenticated,
      restoreStatus: SessionRestoreStatus.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'admin'),
      firebaseUid: 'admin-uid',
      firebaseRole: 'admin',
    );

    expect(localAdmin.canSecurelyDeleteMember, isFalse);
    expect(editor.canSecurelyDeleteMember, isFalse);
    expect(firebaseAdmin.canSecurelyDeleteMember, isTrue);
  });

  testWidgets(
    'destructive confirmation requires the member name or SUPPRIMER',
    (tester) async {
      var deleteCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberDeletionDialog(
              person: const Person(
                id: 'test-member',
                firstName: 'Membre',
                lastName: 'Test',
                familyCode: 'ayivon',
              ),
              data: const FamilyTreeData(mainFamilyCode: 'ayivon'),
              onDelete: () async => deleteCount++,
            ),
          ),
        ),
      );

      final destructive = find.widgetWithText(
        FilledButton,
        'Supprimer définitivement',
      );
      expect(tester.widget<FilledButton>(destructive).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'SUPPRIMER');
      await tester.pump();
      expect(tester.widget<FilledButton>(destructive).onPressed, isNotNull);

      await tester.tap(destructive);
      await tester.pumpAndSettle();
      expect(deleteCount, 1);
    },
  );

  testWidgets('double click cannot start two deletions', (tester) async {
    final completer = Completer<void>();
    var deleteCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemberDeletionDialog(
            person: const Person(id: 'test-member', firstName: 'Test'),
            data: const FamilyTreeData(),
            onDelete: () {
              deleteCount++;
              return completer.future;
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'SUPPRIMER');
    await tester.pump();
    final destructive = find.widgetWithText(
      FilledButton,
      'Supprimer définitivement',
    );

    await tester.tap(destructive);
    await tester.tap(destructive);
    await tester.pump();
    expect(deleteCount, 1);
    expect(tester.widget<FilledButton>(destructive).onPressed, isNull);

    completer.complete();
    await tester.pumpAndSettle();
  });
}
