class ApiException implements Exception {
  const ApiException(
    this.code,
    this.message, {
    this.statusCode,
    this.fields = const {},
  });

  final String code;
  final String message;
  final int? statusCode;
  final Map<String, dynamic> fields;

  @override
  String toString() => 'ApiException($code, $message)';
}
