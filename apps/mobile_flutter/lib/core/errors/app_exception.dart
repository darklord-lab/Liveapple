class AppException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final dynamic details;

  AppException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'AppException [$code]: $message';
}
