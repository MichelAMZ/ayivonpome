import 'package:flutter_test/flutter_test.dart';

import 'package:ayivonpome/models/server_operation.dart';

void main() {
  test('unknown enum values are handled without throwing', () {
    final operation = ServerOperation.fromJson({
      'id': 'op-1',
      'type': 'future.operation',
      'status': 'future-status',
      'payload': const {},
    });

    expect(operation.operationId, 'op-1');
    expect(operation.type, ServerOperationType.unknown);
    expect(operation.status, ServerOperationStatus.unknown);
    expect(operation.schemaVersion, 1);
  });

  test('optional fields can be absent and round-trip safely', () {
    final operation = ServerOperation.fromJson({
      'operationId': 'op-2',
      'localOperationId': 'local-2',
      'idempotencyKey': 'installation:local-2',
      'familyId': 'ayivon',
      'type': 'member.update',
      'resourceType': 'member',
      'resourceId': 'member-2',
      'resourceKey': 'ayivon:member:member-2',
      'resourceSequence': 3,
      'baseVersion': 2,
      'payload': const {'public': <String, dynamic>{}},
      'status': 'pending',
      'createdBy': 'uid',
      'attemptCount': 0,
      'schemaVersion': 1,
    });

    expect(operation.toJson()['type'], 'member.update');
    expect(operation.toJson()['resourceSequence'], 3);
    expect(operation.createdAt, isNull);
  });
}
