import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/sync_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FamilyTreeData serializes sync settings and pending queue', () {
    const data = FamilyTreeData(
      syncSettings: SyncSettings(
        syncStatus: 'pending',
        lastSyncAt: '2026-07-01T12:00:00',
      ),
      pendingSyncQueue: [
        PendingSyncItem(
          id: 'sync001',
          entityType: 'person',
          entityId: 'p001',
          action: 'create',
          payload: {'id': 'p001', 'firstName': 'Ama'},
          createdAt: '2026-07-01T11:59:00',
          updatedAt: '2026-07-01T12:00:00',
          updatedBy: 'admin',
          lastError: 'network',
        ),
      ],
    );

    final parsed = FamilyTreeData.fromJson(data.toJson());

    expect(parsed.syncSettings.storageMode, 'jsonAndDatabase');
    expect(parsed.syncSettings.databaseEnabled, isTrue);
    expect(parsed.syncSettings.offlineModeEnabled, isTrue);
    expect(parsed.syncSettings.autoSyncOnReconnect, isTrue);
    expect(parsed.syncSettings.syncStatus, 'pending');
    expect(parsed.syncSettings.lastSyncAt, '2026-07-01T12:00:00');
    expect(parsed.pendingSyncQueue, hasLength(1));
    expect(parsed.pendingSyncQueue.single.id, 'sync001');
    expect(parsed.pendingSyncQueue.single.entityType, 'person');
    expect(parsed.pendingSyncQueue.single.entityId, 'p001');
    expect(parsed.pendingSyncQueue.single.action, 'create');
    expect(parsed.pendingSyncQueue.single.payload['firstName'], 'Ama');
    expect(parsed.pendingSyncQueue.single.updatedAt, '2026-07-01T12:00:00');
    expect(parsed.pendingSyncQueue.single.updatedBy, 'admin');
    expect(parsed.pendingSyncQueue.single.lastError, 'network');
  });
}
