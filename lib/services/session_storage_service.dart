import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_metadata.dart';

class SessionStorageService {
  const SessionStorageService();

  static const _sessionKey = 'auth_session_metadata';
  static const _legacyLastCodeKey = 'last_family_code';

  Future<SessionMetadata?> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return null;
      final session = SessionMetadata.fromJson(data);
      if (session.uid.isEmpty ||
          session.familyId.isEmpty ||
          session.isExpired) {
        await clearSession();
        return null;
      }
      return session;
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> saveSession(SessionMetadata session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    await prefs.remove(_legacyLastCodeKey);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_legacyLastCodeKey);
  }
}
