import 'package:shared_preferences/shared_preferences.dart';

import 'json_storage_service.dart';

JsonStorageService createJsonStorageService({String? storageDirectory}) =>
    WebJsonStorageService();

class WebJsonStorageService implements JsonStorageService {
  static const _key = 'family_tree.json';
  String? _memoryRaw;

  @override
  Future<bool> exists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_key) || _memoryRaw != null;
    } catch (_) {
      return _memoryRaw != null;
    }
  }

  @override
  Future<String?> readRaw() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key) ?? _memoryRaw;
    } catch (_) {
      return _memoryRaw;
    }
  }

  @override
  Future<String> storageLocation() async => 'browser-local-storage:$_key';

  @override
  Future<void> writeRaw(String contents) async {
    _memoryRaw = contents;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, contents);
    } catch (_) {
      // Certains navigateurs intégrés ou modes privés refusent le stockage.
      // La copie mémoire garde l'application utilisable pendant la session.
    }
  }

  @override
  Future<String> writeBackup(String contents) async {
    final stamp = DateTime.now().toIso8601String();
    final key = '$_key.backup.$stamp';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, contents);
      return 'browser-local-storage:$key';
    } catch (_) {
      return 'browser-memory:$key';
    }
  }
}
