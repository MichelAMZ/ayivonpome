import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/sync_state.dart';

class PendingSyncStore {
  const PendingSyncStore(this._preferences);

  static const _queueKey = 'lws_pending_sync_operations';

  final SharedPreferences _preferences;

  List<PendingSyncItem> readAll() {
    final raw = _preferences.getString(_queueKey);
    if (raw == null || raw.isEmpty) return const [];
    return (jsonDecode(raw) as List)
        .whereType<Map>()
        .map(
          (item) => PendingSyncItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> writeAll(List<PendingSyncItem> operations) async {
    await _preferences.setString(
      _queueKey,
      jsonEncode(operations.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> add(PendingSyncItem operation) async {
    await writeAll([...readAll(), operation]);
  }

  Future<void> clear() async {
    await _preferences.remove(_queueKey);
  }
}
