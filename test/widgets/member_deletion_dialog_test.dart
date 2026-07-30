import 'dart:async';

import 'package:ayivonpome/l10n/app_localizations.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/providers/auth_provider.dart';
import 'package:ayivonpome/providers/family_tree_provider.dart';
import 'package:ayivonpome/services/auth_code_service.dart';
import 'package:ayivonpome/widgets/member_deletion_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only a live Firebase editor or admin session exposes deletion', () {
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
    expect(editor.canSecurelyDeleteMember, isTrue);
    expect(firebaseAdmin.canSecurelyDeleteMember, isTrue);
  });

  testWidgets(
    'destructive confirmation requires the member name or SUPPRIMER',
    (tester) async {
      var deleteCount = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_AuthorizedAdminController.new),
          ],
          child: MaterialApp(
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
        ),
      );

      final destructive = find.widgetWithText(
        FilledButton,
        'Supprimer et enregistrer',
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
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(_AuthorizedAdminController.new),
        ],
        child: MaterialApp(
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
      ),
    );
    await tester.enterText(find.byType(TextField), 'SUPPRIMER');
    await tester.pump();
    final destructive = find.widgetWithText(
      FilledButton,
      'Supprimer et enregistrer',
    );

    await tester.tap(destructive);
    await tester.tap(destructive);
    await tester.pump();
    expect(deleteCount, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.text('Suppression et enregistrement…'), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'locked deletion explains authorization and preserves confirmation',
    (tester) async {
      var deleteCount = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(_LockedAuthController.new),
            familyTreeProvider.overrideWith(_TestFamilyTreeController.new),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MemberDeletionDialog(
                person: const Person(
                  id: 'test-member',
                  firstName: 'Membre',
                  lastName: 'Test',
                ),
                data: const FamilyTreeData(),
                onDelete: () async => deleteCount++,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Autorisation administrateur requise'), findsOneWidget);
      expect(find.text('Déverrouiller l’administration'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'SUPPRIMER');
      await tester.pump();
      final destructive = find.widgetWithText(
        FilledButton,
        'Supprimer et enregistrer',
      );
      expect(tester.widget<FilledButton>(destructive).onPressed, isNull);
      expect(deleteCount, 0);

      await tester.ensureVisible(find.text('Déverrouiller l’administration'));
      await tester.tap(find.text('Déverrouiller l’administration'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Déverrouiller l’administration'), findsWidgets);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller?.text,
        'SUPPRIMER',
      );

      await tester.tap(find.text('Annuler').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'SUPPRIMER',
      );
      expect(deleteCount, 0);
    },
  );
}

class _AuthorizedAdminController extends AuthController {
  @override
  AuthState build() => const AuthState(
    mode: AuthMode.authenticated,
    restoreStatus: SessionRestoreStatus.authenticated,
    session: AuthSession(familyCode: 'ayivon', role: 'admin'),
    firebaseUid: 'admin-uid',
    firebaseRole: 'admin',
    firebaseAuthMethod: 'password',
  );
}

class _LockedAuthController extends AuthController {
  @override
  AuthState build() =>
      const AuthState(restoreStatus: SessionRestoreStatus.unauthenticated);
}

class _TestFamilyTreeController extends FamilyTreeController {
  @override
  Future<FamilyTreeData> build() async => const FamilyTreeData();
}
