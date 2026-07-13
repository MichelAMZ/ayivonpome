class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.data,
    this.message = '',
    this.serverTime = '',
  });

  final bool success;
  final T data;
  final String message;
  final String serverTime;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parse,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: parse(json['data']),
      message: json['message'] as String? ?? '',
      serverTime: json['serverTime'] as String? ?? '',
    );
  }
}
