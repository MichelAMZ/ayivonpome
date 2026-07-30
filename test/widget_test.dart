import 'dart:async';

import 'package:ayivonpome/app.dart';
import 'package:ayivonpome/core/logging/app_logger.dart';
import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/sync_state.dart';
import 'package:ayivonpome/providers/family_tree_provider.dart';
import 'package:ayivonpome/screens/tree_screen.dart';
import 'package:ayivonpome/widgets/sync_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FamilyTreeApp builds', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FamilyTreeApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('TreeScreen tolerates a transient loading state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyTreeProvider.overrideWith(_LoadingFamilyTreeController.new),
        ],
        child: const MaterialApp(home: TreeScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('render error fallback works without a Material ancestor', (
    tester,
  ) async {
    final incident = AppLogger.capture(
      category: 'widget_rendering',
      error: StateError('test rendering failure'),
      stackTrace: StackTrace.current,
    );

    await tester.pumpWidget(AppInlineError(incident: incident));

    expect(
      find.text('Cette partie de la page n’a pas pu être affichée.'),
      findsOneWidget,
    );
    expect(find.textContaining('Code d’assistance : AYV-UI-'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sync status badge fits its actual narrow parent', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyTreeProvider.overrideWith(_AuthorizationRequiredController.new),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: SizedBox(width: 150, child: SyncStatusBadge()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Administration verrouillée'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _LoadingFamilyTreeController extends FamilyTreeController {
  @override
  Future<FamilyTreeData> build() => Completer<FamilyTreeData>().future;
}

class _AuthorizationRequiredController extends FamilyTreeController {
  @override
  Future<FamilyTreeData> build() async => const FamilyTreeData(
    pendingSyncQueue: [
      PendingSyncItem(
        id: 'operation-1',
        entityType: 'person',
        entityId: 'person-1',
        action: 'update',
        status: 'authorizationRequired',
        lastErrorCode: 'permission-denied',
      ),
    ],
  );
}
