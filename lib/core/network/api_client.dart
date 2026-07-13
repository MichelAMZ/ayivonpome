import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
    : _http = httpClient ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _http;
  final String _baseUrl;
  String? _token;

  void setBearerToken(String? token) {
    _token = token == null || token.isEmpty ? null : token;
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) {
    return _send('GET', path, query: query);
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) {
    return _send('POST', path, body: body);
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) {
    return _send('PUT', path, body: body);
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _send('DELETE', path);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/${path.replaceFirst(RegExp(r'^/'), '')}',
    ).replace(queryParameters: query);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    final encoded = body == null ? null : jsonEncode(body);
    final response = switch (method) {
      'GET' => await _http.get(uri, headers: headers),
      'POST' => await _http.post(uri, headers: headers, body: encoded),
      'PUT' => await _http.put(uri, headers: headers, body: encoded),
      'DELETE' => await _http.delete(uri, headers: headers),
      _ => throw ArgumentError.value(method, 'method'),
    };
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'] as Map<String, dynamic>? ?? const {};
      throw ApiException(
        error['code'] as String? ?? 'HTTP_${response.statusCode}',
        error['message'] as String? ?? 'Erreur API',
        statusCode: response.statusCode,
        fields: Map<String, dynamic>.from(error['fields'] as Map? ?? const {}),
      );
    }
    if (decoded['success'] == false) {
      final error = decoded['error'] as Map<String, dynamic>? ?? const {};
      throw ApiException(
        error['code'] as String? ?? 'API_ERROR',
        error['message'] as String? ?? 'Erreur API',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}
