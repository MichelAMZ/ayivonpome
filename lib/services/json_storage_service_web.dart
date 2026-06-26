import 'package:shared_preferences/shared_preferences.dart';

import 'json_storage_service.dart';

JsonStorageService createJsonStorageService({String? storageDirectory}) =>
    WebJsonStorageService();

class WebJsonStorageService implements JsonStorageService {
  static const _key = 'family_tree.json';

  @override
  Future<bool> exists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  @override
  Future<String?> readRaw() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<String> storageLocation() async => 'browser-local-storage:$_key';

  @override
  Future<void> writeRaw(String contents) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, contents);
  }

  @override
  Future<String> writeBackup(String contents) async {
    final prefs = await SharedPreferences.getInstance();
    final stamp = DateTime.now().toIso8601String();
    final key = '$_key.backup.$stamp';
    await prefs.setString(key, contents);
    return 'browser-local-storage:$key';
  }
}
