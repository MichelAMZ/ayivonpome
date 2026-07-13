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
      'updatedAt': FieldValue.serverTimestamp(),
    };
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
