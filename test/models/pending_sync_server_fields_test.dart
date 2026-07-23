import 'package:flutter_test/flutter_test.dart';

import 'package:ayivonpome/models/sync_state.dart';

void main() {
  test('legacy queue item receives a stable local operation id', () {
    final item = PendingSyncItem.fromJson({
      'id': 'legacy-op-1',
      'entityType': 'person',
      'entityId': 'member-1',
      'action': 'update',
    });

    expect(item.localOperationId, 'legacy-op-1');
    expect(item.submissionStatus, 'pendingSubmission');
    expect(item.toJson()['localOperationId'], 'legacy-op-1');
  });

  test('server submission fields survive serialization', () {
    const item = PendingSyncItem(
      id: 'op-1',
      entityType: 'person',
      entityId: 'member-1',
      action: 'update',
      localOperationId: 'op-1',
      idempotencyKey: 'install:op-1',
      serverOperationId: 'server-1',
      submissionStatus: 'submittedToServer',
      serverStatus: 'pending',
      submittedAt: '2026-07-23T10:00:00Z',
    );

    final restored = PendingSyncItem.fromJson(item.toJson());
    expect(restored.idempotencyKey, 'install:op-1');
    expect(restored.serverOperationId, 'server-1');
    expect(restored.submissionStatus, 'submittedToServer');
  });
}
