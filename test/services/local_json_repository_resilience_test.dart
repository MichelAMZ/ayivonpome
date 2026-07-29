import 'package:ayivonpome/services/json_storage_service.dart';
import 'package:ayivonpome/services/local_json_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing local cache falls back to demo data', () async {
    final repository = JsonFamilyRepository(_MemoryStorage());

    final data = await repository.loadFamilyTree();

    expect(data.people, isNotEmpty);
  });

  test('invalid JSON local cache falls back to demo data', () async {
    final repository = JsonFamilyRepository(_MemoryStorage('{invalid'));

    final data = await repository.loadFamilyTree();

    expect(data.people, isNotEmpty);
  });

  test('unexpected JSON type local cache falls back to demo data', () async {
    final repository = JsonFamilyRepository(_MemoryStorage('[]'));

    final data = await repository.loadFamilyTree();

    expect(data.people, isNotEmpty);
  });
}

class _MemoryStorage implements JsonStorageService {
  _MemoryStorage([this.raw]);

  String? raw;

  @override
  Future<bool> exists() async => raw != null;

  @override
  Future<String?> readRaw() async => raw;

  @override
  Future<String> storageLocation() async => 'memory';

  @override
  Future<void> writeRaw(String contents) async => raw = contents;

  @override
  Future<String> writeBackup(String contents) async => 'memory-backup';
}
