import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreDocumentMapper {
  const FirestoreDocumentMapper();

  Map<String, dynamic> toFirestore(
    Map<String, dynamic> json, {
    required String id,
    required String familyId,
  }) {
    return {
      ...json,
      'id': id,
      'familyId': familyId,
      'deletedAt': json['deletedAt'] ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toPersonCreateData(
    Map<String, dynamic> json, {
    required String id,
    required String familyId,
    required String uid,
  }) {
    final sanitized = Map<String, dynamic>.from(json)
      ..remove('familyCode')
      ..removeWhere((key, value) => !_isFirestoreValue(value));
    return {
      ...sanitized,
      'id': id,
      'familyId': familyId,
      'version': 1,
      'schemaVersion': 1,
      'deletedAt': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'updatedBy': uid,
    };
  }

  bool _isFirestoreValue(Object? value) {
    if (value == null ||
        value is String ||
        value is num ||
        value is bool ||
        value is Timestamp ||
        value is FieldValue) {
      return true;
    }
    if (value is Map) {
      return value.keys.every((key) => key is String) &&
          value.values.every(_isFirestoreValue);
    }
    if (value is Iterable) return value.every(_isFirestoreValue);
    return false;
  }

  Map<String, dynamic> fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return {'id': doc.id, ..._normalize(doc.data() ?? const {})};
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> value) {
    return value.map((key, item) => MapEntry(key, _normalizeValue(item)));
  }

  Object? _normalizeValue(Object? value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Map) {
      return _normalize(Map<String, dynamic>.from(value));
    }
    if (value is Iterable) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }
}
