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
      firebaseRoleActive: true,
      firebaseFamilyIds: {'ayivon'},
    );
    const firebaseAdmin = AuthState(
      mode: AuthMode.authenticated,
      restoreStatus: SessionRestoreStatus.authenticated,
      session: AuthSession(familyCode: 'ayivon', role: 'admin'),
      firebaseUid: 'admin-uid',
      firebaseRole: 'admin',
      firebaseRoleActive: true,
      firebaseFamilyIds: {'ayivon'},
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
                data: const FamilyTreeData(
                  mainFamilyCode: 'ayivon',
                  people: [
                    Person(
                      id: 'test-member',
                      firstName: 'Membre',
                      lastName: 'Test',
                      familyCode: 'ayivon',
                    ),
                  ],
                ),
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
              data: const FamilyTreeData(
                people: [Person(id: 'test-member', firstName: 'Test')],
              ),
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
                data: const FamilyTreeData(
                  people: [
                    Person(
                      id: 'test-member',
                      firstName: 'Membre',
                      lastName: 'Test',
                    ),
                  ],
                ),
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

  testWidgets('successful unlock resumes once without reopening or deleting', (
    tester,
  ) async {
    final unlockResult = Completer<bool?>();
    var unlockDialogOpenCount = 0;
    var deleteCount = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(_RefreshableAuthController.new),
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
                familyCode: 'ayivon',
              ),
              data: const FamilyTreeData(
                mainFamilyCode: 'ayivon',
                people: [
                  Person(
                    id: 'test-member',
                    firstName: 'Membre',
                    lastName: 'Test',
                    familyCode: 'ayivon',
                  ),
                ],
              ),
              showUnlockDialog: (_) {
                unlockDialogOpenCount++;
                return unlockResult.future;
              },
              onDelete: () async => deleteCount++,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'SUPPRIMER');
    await tester.ensureVisible(find.text('Déverrouiller l’administration'));
    await tester.tap(find.text('Déverrouiller l’administration'));
    await tester.tap(find.text('Déverrouiller l’administration'));
    await tester.pump();
    expect(unlockDialogOpenCount, 1);

    unlockResult.complete(true);
    await tester.pumpAndSettle();

    expect(find.text('Supprimer ce membre ?'), findsOneWidget);
    expect(find.text('Déverrouiller l’administration'), findsNothing);
    expect(
      find.text(
        'Administration déverrouillée. Vous pouvez maintenant confirmer la suppression.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'SUPPRIMER',
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Supprimer et enregistrer'),
          )
          .onPressed,
      isNotNull,
    );
    expect(unlockDialogOpenCount, 1);
    expect(deleteCount, 0);
  });

  testWidgets('insufficient rights popup is actionable once and preserves deletion', (
    tester,
  ) async {
    var unlockDialogOpenCount = 0;
    var deleteCount = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(_RejectedAuthController.new),
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
                familyCode: 'ayivon',
              ),
              data: const FamilyTreeData(
                mainFamilyCode: 'ayivon',
                people: [
                  Person(
                    id: 'test-member',
                    firstName: 'Membre',
                    lastName: 'Test',
                    familyCode: 'ayivon',
                  ),
                ],
              ),
              showUnlockDialog: (_) async {
                unlockDialogOpenCount++;
                return unlockDialogOpenCount < 3 ? true : null;
              },
              onDelete: () async => deleteCount++,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'SUPPRIMER');
    await tester.ensureVisible(find.text('Déverrouiller l’administration'));
    await tester.tap(find.text('Déverrouiller l’administration'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(
        'La session est ouverte, mais ce compte ne possède pas les droits nécessaires pour supprimer ce membre.',
      ),
      findsWidgets,
    );
    expect(
      find.text(
        'Déverrouillez l’administration avec un code administrateur valide, puis revenez confirmer la suppression.',
      ),
      findsOneWidget,
    );
    expect(find.text('Annuler'), findsWidgets);
    expect(unlockDialogOpenCount, 1);
    expect(deleteCount, 0);

    await tester.tap(find.text('Annuler').last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Déverrouillez l’administration avec un code administrateur valide, puis revenez confirmer la suppression.',
      ),
      findsNothing,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'SUPPRIMER',
    );

    await tester.ensureVisible(find.text('Déverrouiller l’administration'));
    await tester.tap(find.text('Déverrouiller l’administration'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Déverrouiller l’administration').last);
    await tester.pumpAndSettle();

    expect(unlockDialogOpenCount, 3);
    expect(find.text('Supprimer ce membre ?'), findsOneWidget);
    expect(
      find.text(
        'Déverrouillez l’administration avec un code administrateur valide, puis revenez confirmer la suppression.',
      ),
      findsNothing,
    );
    expect(deleteCount, 0);
  });
}

class _AuthorizedAdminController extends AuthController {
  @override
  AuthState build() => const AuthState(
    mode: AuthMode.authenticated,
    restoreStatus: SessionRestoreStatus.authenticated,
    session: AuthSession(familyCode: 'ayivon', role: 'admin'),
    firebaseUid: 'admin-uid',
    firebaseRole: 'admin',
    firebaseRoleActive: true,
    firebaseFamilyIds: {'ayivon'},
    firebaseAuthMethod: 'password',
  );
}

class _LockedAuthController extends AuthController {
  @override
  AuthState build() =>
      const AuthState(restoreStatus: SessionRestoreStatus.unauthenticated);
}

class _RefreshableAuthController extends AuthController {
  @override
  AuthState build() =>
      const AuthState(restoreStatus: SessionRestoreStatus.unauthenticated);

  @override
  Future<bool> refreshEffectiveAdminAuthorization({
    required String familyId,
  }) async {
    state = AuthState(
      mode: AuthMode.authenticated,
      restoreStatus: SessionRestoreStatus.authenticated,
      session: AuthSession(familyCode: familyId, role: 'admin'),
      firebaseUid: 'admin-uid',
      firebaseRole: 'admin',
      firebaseRoleActive: true,
      firebaseFamilyIds: {familyId},
      firebaseAuthMethod: 'password',
    );
    return true;
  }
}

class _RejectedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
    mode: AuthMode.authenticated,
    restoreStatus: SessionRestoreStatus.authenticated,
    session: AuthSession(familyCode: 'ayivon', role: 'viewer'),
    firebaseUid: 'viewer-uid',
    firebaseRole: 'viewer',
    firebaseAuthMethod: 'password',
  );

  @override
  Future<bool> refreshEffectiveAdminAuthorization({
    required String familyId,
  }) async => false;
}

class _TestFamilyTreeController extends FamilyTreeController {
  @override
  Future<FamilyTreeData> build() async => const FamilyTreeData();
}
