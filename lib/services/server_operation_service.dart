import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/server_operation.dart';

class ServerOperationSubmission {
  const ServerOperationSubmission({
    required this.operationId,
    required this.status,
    required this.duplicate,
    required this.resourceSequence,
  });

  final String operationId;
  final ServerOperationStatus status;
  final bool duplicate;
  final int resourceSequence;
}

class ServerOperationException implements Exception {
  const ServerOperationException(this.code, this.message);
  final String code;
  final String message;

  bool get isRetryable => const {
    'unavailable',
    'deadline-exceeded',
    'resource-exhausted',
    'internal',
  }.contains(code);

  @override
  String toString() => 'ServerOperationException($code, $message)';
}

class ServerOperationService {
  const ServerOperationService({
    required FirebaseFunctions functions,
    required FirebaseFirestore firestore,
  }) : _functions = functions,
       _firestore = firestore;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Future<ServerOperationSubmission> submitOperation({
    required String localOperationId,
    required String idempotencyKey,
    required String familyId,
    required ServerOperationType type,
    required String resourceId,
    required int baseVersion,
    required Map<String, dynamic> payload,
    int schemaVersion = 1,
  }) async {
    if (type == ServerOperationType.unknown) {
      throw const ServerOperationException(
        'invalid-argument',
        'Type d’opération inconnu.',
      );
    }
    try {
      final response = await _functions
          .httpsCallable('submitFamilyOperation')
          .call(<String, dynamic>{
            'localOperationId': localOperationId,
            'idempotencyKey': idempotencyKey,
            'familyId': familyId,
            'type': type.wireName,
            'resourceId': resourceId,
            'baseVersion': baseVersion,
            'payload': payload,
            'schemaVersion': schemaVersion,
          });
      final data = Map<String, dynamic>.from(response.data as Map);
      return ServerOperationSubmission(
        operationId: '${data['operationId'] ?? ''}',
        status: ServerOperationStatus.parse(data['status']),
        duplicate: data['duplicate'] == true,
        resourceSequence: (data['resourceSequence'] as num?)?.toInt() ?? 0,
      );
    } on FirebaseFunctionsException catch (error) {
      throw ServerOperationException(error.code, _safeMessage(error.code));
    }
  }

  Stream<ServerOperation> watchOperation(String operationId) => _firestore
      .collection('operation_queue')
      .doc(operationId)
      .snapshots()
      .map((snapshot) => _operationFromSnapshot(snapshot));

  Future<ServerOperation> getOperation(String operationId) async =>
      _operationFromSnapshot(
        await _firestore.collection('operation_queue').doc(operationId).get(),
      );

  Future<void> cancelPendingOperation(String operationId) =>
      _invokeControl('cancelFamilyOperation', operationId);

  Future<void> retryEligibleOperation(String operationId) =>
      _invokeControl('retryFamilyOperation', operationId);

  Future<void> _invokeControl(String callable, String operationId) async {
    try {
      await _functions.httpsCallable(callable).call(<String, dynamic>{
        'operationId': operationId,
      });
    } on FirebaseFunctionsException catch (error) {
      throw ServerOperationException(error.code, _safeMessage(error.code));
    }
  }

  ServerOperation _operationFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw const ServerOperationException(
        'not-found',
        'Opération serveur introuvable.',
      );
    }
    return ServerOperation.fromJson({...data, 'operationId': snapshot.id});
  }

  static String _safeMessage(String code) => switch (code) {
    'unauthenticated' => 'Authentification Firebase requise.',
    'permission-denied' => 'Autorisation insuffisante.',
    'invalid-argument' => 'Opération invalide.',
    'already-exists' => 'La clé existe avec un contenu différent.',
    'failed-precondition' => 'La ressource ne permet pas cette opération.',
    'unavailable' => 'Service temporairement indisponible.',
    'deadline-exceeded' => 'La demande a expiré.',
    'resource-exhausted' => 'Limite temporaire atteinte.',
    _ => 'Échec technique de l’opération.',
  };
}
