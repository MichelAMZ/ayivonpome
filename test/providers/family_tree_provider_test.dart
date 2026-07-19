import 'dart:async';
import 'dart:convert';

import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/models/person.dart';
import 'package:ayivonpome/providers/app_providers.dart';
import 'package:ayivonpome/providers/family_tree_provider.dart';
import 'package:ayivonpome/services/connectivity_service.dart';
import 'package:ayivonpome/services/json_storage_service.dart';
import 'package:ayivonpome/services/local_json_repository.dart';
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
