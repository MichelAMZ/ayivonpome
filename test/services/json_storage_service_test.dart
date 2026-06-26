import 'dart:io';

import 'package:ayivonpome/models/family_tree_data.dart';
import 'package:ayivonpome/services/import_export_service.dart';
import 'package:ayivonpome/services/json_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('writes and reads family_tree.json', () async {
    final directory = await Directory.systemTemp.createTemp('family_tree_test_');
    addTearDown(() => directory.delete(recursive: true));

    final storage = JsonStorageService(storageDirectory: directory.path);
    final raw = ImportExportService().serialize(FamilyTreeData.demo());

    await storage.writeRaw(raw);

    expect(await storage.exists(), isTrue);
    expect(await storage.readRaw(), raw);
    expect(await storage.storageLocation(), contains('family_tree.json'));

    final backupPath = await storage.writeBackup(raw);
    expect(File(backupPath).existsSync(), isTrue);
  });

  test('parses exported JSON', () {
    final service = ImportExportService();
    final raw = service.serialize(FamilyTreeData.demo());

    final parsed = service.parse(raw);

    expect(parsed.mainFamilyCode, 'ayivon');
    expect(parsed.people, isNotEmpty);
  });
}
