import '../../core/network/api_client.dart';
import '../../models/sync_state.dart';

class SyncApi {
  const SyncApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> push({
    required String deviceId,
    required String familyId,
    required List<PendingSyncItem> operations,
  }) async {
    final response = await _client.post(
      '/sync/push',
      body: {
        'deviceId': deviceId,
        'familyId': familyId,
        'operations': operations.map((item) => item.toJson()).toList(),
      },
    );
    return Map<String, dynamic>.from(response['data'] as Map? ?? const {});
  }

  Future<Map<String, dynamic>> pull(
    String familyId, {
    int sinceVersion = 0,
  }) async {
    final response = await _client.get(
      '/sync/pull',
      query: {'familyId': familyId, 'sinceVersion': sinceVersion.toString()},
    );
    return Map<String, dynamic>.from(response['data'] as Map? ?? const {});
  }
}
