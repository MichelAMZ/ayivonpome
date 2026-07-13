import '../../core/network/api_client.dart';

class AdminApi {
  const AdminApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> kpi() async {
    final response = await _client.get('/admin/kpi');
    return Map<String, dynamic>.from(response['data'] as Map? ?? const {});
  }
}
