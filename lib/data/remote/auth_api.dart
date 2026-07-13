import '../../core/network/api_client.dart';

class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> accessCode(String code) async {
    final response = await _client.post(
      '/auth/access-code',
      body: {'code': code},
    );
    return Map<String, dynamic>.from(response['data'] as Map? ?? const {});
  }

  Future<Map<String, dynamic>> adminCode(String code) async {
    final response = await _client.post(
      '/auth/admin-code',
      body: {'code': code},
    );
    return Map<String, dynamic>.from(response['data'] as Map? ?? const {});
  }
}
