import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'json_storage_service.dart';

class LocalSecurityCleanupMigration {
  const LocalSecurityCleanupMigration(this._storage);

  static const version = 1;
  static const _versionKey = 'local_security_cleanup_version';
  static const _legacyKeys = <String>[
    'last_family_code',
    'admin_code',
    'modification_code',
    'super_admin_code',
    'super_admin_recovery_code',
  ];

  final JsonStorageService _storage;

  Future<bool> run() async {
    final preferences = await SharedPreferences.getInstance();
    var changed = false;
    for (final key in _legacyKeys) {
      if (preferences.containsKey(key)) {
        await preferences.remove(key);
        changed = true;
      }
    }

    final raw = await _storage.readRaw();
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic> && _sanitize(decoded)) {
          await _storage.writeRaw(
            const JsonEncoder.withIndent('  ').convert(decoded),
          );
          changed = true;
        }
      } on FormatException {
        // Le chargement normal signalera le JSON invalide. La migration ne
        // remplace jamais des données qu'elle ne peut pas interpréter.
      }
    }

    await preferences.setInt(_versionKey, version);
    return changed;
  }

  bool _sanitize(Map<String, dynamic> data) {
    var changed = false;
    changed = _clearList(data, 'accessCodes') || changed;
    changed = _clearList(data, 'modificationCodes') || changed;

    final adminAccess = data['adminAccess'];
    if (adminAccess is Map) {
      final mutable = Map<String, dynamic>.from(adminAccess);
      changed = mutable.remove('currentAdminCode') != null || changed;
      changed = mutable.remove('codeHistory') != null || changed;
      if (mutable['enabled'] != false) {
        mutable['enabled'] = false;
        changed = true;
      }
      if (mutable['requireCodeRotationReminder'] != false) {
        mutable['requireCodeRotationReminder'] = false;
        changed = true;
      }
      data['adminAccess'] = mutable;
    }

    final recovery = data['superAdminRecovery'];
    if (recovery is Map) {
      final mutable = Map<String, dynamic>.from(recovery);
      changed = mutable.remove('recoveryCode') != null || changed;
      if (mutable['enabled'] != false) {
        mutable['enabled'] = false;
        changed = true;
      }
      if (mutable['allowResetAllCodes'] != false) {
        mutable['allowResetAllCodes'] = false;
        changed = true;
      }
      data['superAdminRecovery'] = mutable;
    }
    return changed;
  }

  bool _clearList(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is List && value.isEmpty) return false;
    if (!data.containsKey(key)) return false;
    data[key] = <Object?>[];
    return true;
  }
}
