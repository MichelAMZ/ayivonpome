import 'package:flutter_test/flutter_test.dart';
import 'package:ayivonpome/models/sync_state.dart';
import 'package:ayivonpome/services/conflict_resolution_service.dart';

void main() {
  const service = ConflictResolutionService();

  test('a conflict is preserved and cannot be retried directly', () {
    const conflict = PendingSyncItem(
      id: 'local-old',
      localOperationId: 'local-old',
      serverOperationId: 'server-old',
      idempotencyKey: 'installation:local-old',
      entityType: 'person',
      entityId: 'member-1',
      action: 'update',
      payload: {'firstName': 'Local'},
      status: 'conflict',
      baseVersion: 2,
      resultVersion: 3,
      conflictedAt: '2026-07-23T10:00:00Z',
      lastError: 'La ressource a changé.',
    );

    expect(service.canRetryDirectly(conflict), isFalse);
    expect(conflict.payload['firstName'], 'Local');
    expect(conflict.baseVersion, 2);
    expect(conflict.resultVersion, 3);
  });

  test('resolution gets a new identity, remote base, and history link', () {
    const conflict = PendingSyncItem(
      id: 'local-old',
      localOperationId: 'local-old',
      serverOperationId: 'server-old',
      idempotencyKey: 'installation:local-old',
      entityType: 'person',
      entityId: 'member-1',
      action: 'update',
      payload: {'firstName': 'Local'},
      status: 'conflict',
    );

    final resolution = service.createResolutionOperation(
      conflict: conflict,
      payload: const {'firstName': 'Resolved'},
      remoteVersion: 4,
      newLocalOperationId: 'local-new',
      newIdempotencyKey: 'installation:local-new',
      createdAt: '2026-07-23T11:00:00Z',
    );

    expect(resolution.localOperationId, 'local-new');
    expect(resolution.idempotencyKey, 'installation:local-new');
    expect(resolution.baseVersion, 4);
    expect(resolution.resolvedFromOperationId, 'server-old');
    expect(resolution.status, 'pending');
    expect(conflict.status, 'conflict');
  });
}
