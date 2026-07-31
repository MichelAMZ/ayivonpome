import 'package:ayivonpome/providers/auth_provider.dart';
import 'package:ayivonpome/screens/admin_dashboard_screen.dart';
import 'package:ayivonpome/services/auth_code_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('locked administration exposes status and unlock action', (
    tester,
  ) async {
    var unlockCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              AdminAuthorizationBanner(authorized: false, onUnlock: () {}),
              AdminAuthorizationStatusCard(
                auth: const AuthState(
                  restoreStatus: SessionRestoreStatus.unauthenticated,
                ),
                familyId: 'AYIVON',
                projectId: 'ayivon-test',
                onUnlock: () => unlockCount++,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Autorisation administrateur requise'), findsOneWidget);
    expect(find.text('Administration verrouillée'), findsOneWidget);
    expect(find.text('Déverrouiller l’administration'), findsNWidgets(2));
    expect(find.text('Non authentifié'), findsOneWidget);
    expect(find.text('ayivon-test'), findsOneWidget);
    await tester.tap(find.text('Administration verrouillée'));
    expect(unlockCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active administration replaces locked presentation', (
    tester,
  ) async {
    const auth = AuthState(
      mode: AuthMode.authenticated,
      restoreStatus: SessionRestoreStatus.authenticated,
      session: AuthSession(familyCode: 'AYIVON', role: 'admin'),
      firebaseUid: 'admin-id',
      firebaseEmail: 'admin@example.test',
      firebaseRole: 'admin',
      firebaseRoleActive: true,
      firebaseFamilyIds: {'ayivon'},
      firebaseAuthMethod: 'password',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              AdminAuthorizationBanner(authorized: true, onUnlock: () {}),
              AdminAuthorizationStatusCard(
                auth: auth,
                familyId: 'AYIVON',
                projectId: 'ayivon-test',
                onUnlock: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Administration déverrouillée'), findsOneWidget);
    expect(find.text('Administration active'), findsOneWidget);
    expect(find.text('admin@example.test'), findsOneWidget);
    expect(find.text('Déverrouiller l’administration'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
