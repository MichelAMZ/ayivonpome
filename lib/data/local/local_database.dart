import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/family_tree_data.dart';

class LocalDatabase {
  const LocalDatabase(this._preferences);

  static const _familyTreeKey = 'lws_local_family_tree';

  final SharedPreferences _preferences;

  Future<FamilyTreeData?> readFamilyTree() async {
    final raw = _preferences.getString(_familyTreeKey);
    if (raw == null || raw.isEmpty) return null;
    return FamilyTreeData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> writeFamilyTree(FamilyTreeData data) async {
    await _preferences.setString(_familyTreeKey, jsonEncode(data.toJson()));
  }
}
