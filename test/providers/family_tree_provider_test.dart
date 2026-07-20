import 'dart:async';
import 'dart:convert';

import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/models/sync_state.dart';
import 'package:ayivonpome/providers/app_providers.dart';
import 'package:ayivonpome/providers/family_tree_provider.dart';
import 'package:ayivonpome/services/connectivity_service.dart';
import 'package:ayivonpome/services/json_storage_service.dart';
import 'package:ayivonpome/services/local_json_repository.dart';
import 'package:ayivonpome/services/remote_database_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'save publishes local member update before remote sync resolves',
    () async {
      final storage = _MemoryJsonStorageService(
        initialRaw: jsonEncode(
          const FamilyTreeData(
            people: [Person(id: 'p001', firstName: 'Djidonou')],
          ).toJson(),
        ),
      );
      final connectivity = _BlockingConnectivityService();
      final container = ProviderContainer(
        overrides: [
          familyTreeProvider.overrideWith(_LocalFirstTestController.new),
          jsonStorageServiceProvider.overrideWithValue(storage),
          localJsonRepositoryProvider.overrideWithValue(
            JsonFamilyRepository(storage),
          ),
          connectivityServiceProvider.overrideWithValue(connectivity),
        ],
      );
      addTearDown(container.dispose);
      await container.read(familyTreeProvider.future);

      const updatedPerson = Person(id: 'p001', firstName: 'Djidonou modifie');
      final operation = container
          .read(syncServiceProvider)
          .personOperation(
            person: updatedPerson,
            action: 'update',
            updatedBy: 'test',
          );
      final saveFuture = container
          .read(familyTreeProvider.notifier)
          .save(
            const FamilyTreeData(people: [updatedPerson]),
            syncOperation: operation,
          );
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(familyTreeProvider).value!.people.single.firstName,
        'Djidonou modifie',
      );
      expect(storage.raw, contains('Djidonou modifie'));

      connectivity.complete(false);
      final result = await saveFuture;

      expect(result.pendingSyncQueue, hasLength(1));
      expect(
        container.read(familyTreeProvider).value!.people.single.firstName,
        'Djidonou modifie',
      );
    },
  );

  test(
    'remote snapshots add, modify and remove members without duplicates',
    () async {
      final storage = _MemoryJsonStorageService();
      final remote = _WatchRemoteClient();
      final container = ProviderContainer(
        overrides: [
          familyTreeProvider.overrideWith(_RealtimeTestController.new),
          jsonStorageServiceProvider.overrideWithValue(storage),
          localJsonRepositoryProvider.overrideWithValue(
            JsonFamilyRepository(storage),
          ),
          remoteDatabaseRepositoryProvider.overrideWithValue(
            DatabaseFamilyRepository(client: remote),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await remote.close();
      });
      await container.read(familyTreeProvider.future);
      await container
          .read(familyTreeProvider.notifier)
          .startRemoteFamilyTreeWatch();
      await container
          .read(familyTreeProvider.notifier)
          .startRemoteFamilyTreeWatch();
      expect(remote.activeListeners, 1);

      remote.emit(
        const FamilyTreeData(
          people: [
            Person(id: 'p001', firstName: 'Initial distant', version: 1),
            Person(id: 'p002', firstName: 'Ajout', version: 1),
          ],
        ),
      );
      await _flushRemoteWatch();
      expect(container.read(familyTreeProvider).value!.people, hasLength(2));

      remote.emitError(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      await _flushRemoteWatch();
      final offlineData = container.read(familyTreeProvider).value!;
      expect(offlineData.people, hasLength(2));
      expect(offlineData.syncSettings.syncStatus, 'offline');

      remote.emit(
        const FamilyTreeData(
          people: [
            Person(id: 'p001', firstName: 'Modifie', version: 2),
            Person(id: 'p001', firstName: 'Modifie', version: 2),
          ],
        ),
      );
      await _flushRemoteWatch();
      final modified = container.read(familyTreeProvider).value!.people;
      expect(modified, hasLength(1));
      expect(modified.single.firstName, 'Modifie');

      remote.emit(const FamilyTreeData());
      await _flushRemoteWatch();
      expect(container.read(familyTreeProvider).value!.people, isEmpty);
      await container
          .read(familyTreeProvider.notifier)
          .stopRemoteFamilyTreeWatch();
      expect(remote.activeListeners, 0);
    },
  );

  test(
    'an older remote version cannot overwrite a pending local member',
    () async {
      final storage = _MemoryJsonStorageService();
      final remote = _WatchRemoteClient();
      final container = ProviderContainer(
        overrides: [
          familyTreeProvider.overrideWith(_PendingRealtimeTestController.new),
          jsonStorageServiceProvider.overrideWithValue(storage),
          localJsonRepositoryProvider.overrideWithValue(
            JsonFamilyRepository(storage),
          ),
          remoteDatabaseRepositoryProvider.overrideWithValue(
            DatabaseFamilyRepository(client: remote),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await remote.close();
      });
      await container.read(familyTreeProvider.future);
      await container
          .read(familyTreeProvider.notifier)
          .startRemoteFamilyTreeWatch();

      remote.emit(
        const FamilyTreeData(
          people: [
            Person(
              id: 'p001',
              firstName: 'Ancienne valeur distante',
              updatedAt: '2026-01-01T00:00:00Z',
              version: 1,
            ),
          ],
        ),
      );
      await _flushRemoteWatch();

      expect(
        container.read(familyTreeProvider).value!.people.single.firstName,
        'Modification locale',
      );
    },
  );
}

Future<void> _flushRemoteWatch() async {
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

class _BlockingConnectivityService extends ConnectivityService {
  final _completer = Completer<bool>();

  @override
  Future<bool> get isOnline => _completer.future;

  void complete(bool value) => _completer.complete(value);
}

class _LocalFirstTestController extends FamilyTreeController {
  @override
  Future<FamilyTreeData> build() async {
    return const FamilyTreeData(
      people: [Person(id: 'p001', firstName: 'Djidonou')],
    );
  }
}

class _RealtimeTestController extends FamilyTreeController {
  @override
  Future<FamilyTreeData> build() async => const FamilyTreeData(
    people: [Person(id: 'p001', firstName: 'Initial local', version: 1)],
  );
}

class _PendingRealtimeTestController extends FamilyTreeController {
  @override
  Future<FamilyTreeData> build() async => const FamilyTreeData(
    people: [
      Person(
        id: 'p001',
        firstName: 'Modification locale',
        updatedAt: '2026-02-01T00:00:00Z',
        version: 2,
      ),
    ],
    pendingSyncQueue: [
      PendingSyncItem(
        id: 'operation-1',
        entityType: 'person',
        entityId: 'p001',
        action: 'update',
      ),
    ],
  );
}

class _WatchRemoteClient extends UnconfiguredRemoteDatabaseClient {
  _WatchRemoteClient() {
    controller = StreamController<FamilyTreeData>.broadcast(
      onListen: () => activeListeners += 1,
      onCancel: () => activeListeners -= 1,
    );
  }

  late final StreamController<FamilyTreeData> controller;
  int activeListeners = 0;

  @override
  Stream<FamilyTreeData> watchFamilyTree() {
    return controller.stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          sink.add(data);
        },
      ),
    );
  }

  void emit(FamilyTreeData data) => controller.add(data);

  void emitError(Object error) => controller.addError(error);

  Future<void> close() => controller.close();
}

class _MemoryJsonStorageService implements JsonStorageService {
  _MemoryJsonStorageService({this.initialRaw});

  final String? initialRaw;
  String? raw;

  @override
  Future<bool> exists() async => (raw ?? initialRaw)?.trim().isNotEmpty == true;

  @override
  Future<String?> readRaw() async => raw ?? initialRaw;

  @override
  Future<String> storageLocation() async => 'memory://family-tree.json';

  @override
  Future<String> writeBackup(String contents) async => contents;

  @override
  Future<void> writeRaw(String contents) async {
    raw = contents;
  }
}
