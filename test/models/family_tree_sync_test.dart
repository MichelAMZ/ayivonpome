import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/family.dart';
import 'package:ayivonpome/models/family_tree_reference.dart';
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
    expect(data.toJson()['schemaVersion'], 2);
    expect(data.toJson()['pendingSyncOperations'], isA<List>());
  });

  test('FamilyTreeData migrates pendingSyncOperations alias', () {
    final parsed = FamilyTreeData.fromJson({
      'schemaVersion': 2,
      'familyId': 'ayivon',
      'pendingSyncOperations': [
        {
          'id': 'op001',
          'entityType': 'person',
          'entityId': 'p001',
          'action': 'update',
          'payload': {'id': 'p001', 'firstName': 'Ama'},
          'status': 'retryScheduled',
          'retryCount': 1,
        },
      ],
    });

    expect(parsed.pendingSyncQueue, hasLength(1));
    expect(parsed.pendingSyncQueue.single.id, 'op001');
    expect(parsed.pendingSyncQueue.single.action, 'update');
    expect(parsed.pendingSyncQueue.single.payload['firstName'], 'Ama');
  });

  test('FamilyTreeData serializes families and linked tree references', () {
    const data = FamilyTreeData(
      families: [
        Family(id: 'family-ayivon', name: 'Famille AYIVON', code: 'AYIVON'),
        Family(id: 'family-levonvi', name: 'Famille Lévonvi', code: 'LEVONVI'),
      ],
      familyTreeLinks: [
        FamilyTreeReference(
          id: 'tree-link-001',
          personId: 'p100',
          sourceFamilyId: 'family-ayivon',
          targetFamilyId: 'family-levonvi',
          targetFamilyName: 'Famille Lévonvi',
          relationshipType: 'originFamily',
          enabled: true,
        ),
      ],
    );

    final parsed = FamilyTreeData.fromJson(data.toJson());

    expect(parsed.families, hasLength(2));
    expect(parsed.families.last.name, 'Famille Lévonvi');
    expect(parsed.familyTreeLinks, hasLength(1));
    expect(parsed.familyTreeLinks.single.personId, 'p100');
    expect(parsed.familyTreeLinks.single.targetFamilyId, 'family-levonvi');
    expect(parsed.familyTreeLinks.single.enabled, isTrue);
  });
}
