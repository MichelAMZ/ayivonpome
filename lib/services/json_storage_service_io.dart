import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'json_storage_service.dart';

JsonStorageService createJsonStorageService({String? storageDirectory}) =>
    IoJsonStorageService(storageDirectory: storageDirectory);

class IoJsonStorageService implements JsonStorageService {
  IoJsonStorageService({String? storageDirectory})
      : _storageDirectory = storageDirectory;

  final String? _storageDirectory;

  Future<File> _file() async {
    final directory = _storageDirectory == null
        ? await getApplicationDocumentsDirectory()
        : Directory(_storageDirectory);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}${Platform.pathSeparator}family_tree.json');
  }

  @override
  Future<bool> exists() async => (await _file()).exists();

  @override
  Future<String?> readRaw() async {
    final file = await _file();
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  @override
  Future<String> storageLocation() async => (await _file()).path;

  @override
  Future<void> writeRaw(String contents) async {
    final file = await _file();
    await file.writeAsString(contents);
  }

  @override
  Future<String> writeBackup(String contents) async {
    final file = await _file();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backup = File('${file.path}.$stamp.backup');
    await backup.writeAsString(contents);
    return backup.path;
  }
}
