/// Normalised error produced by the API layer.
///
/// Wire format (PDF section 17):
/// ```json
/// { "status": "error",
///   "error": { "code": "invalid_credentials",
///              "message": "...",
///              "fields": { "mobile": "Already registered" } } }
/// ```
class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fieldErrors = const <String, String>{},
    this.isNetworkError = false,
  });

  final String code;
  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;
  final bool isNetworkError;

  static const String codeGeneric = 'unknown_error';
  static const String codeNetwork = 'network_error';
  static const String codeInvalidCredentials = 'invalid_credentials';
  static const String codeMobileExists = 'mobile_exists';
  static const String codeEmailExists = 'email_exists';
  static const String codeOtpExpired = 'otp_expired';
  static const String codeInvalidOtp = 'invalid_otp';
  static const String codeWeakPassword = 'weak_password';
  static const String codeSocialNotConfigured = 'social_not_configured';
  static const String codeSessionExpired = 'session_expired';

  bool get isInvalidCredentials => code == codeInvalidCredentials;

  /// Parses either the documented error envelope or a bare message.
  factory ApiException.fromPayload(
    Map<String, dynamic> json, {
    int? statusCode,
  }) {
    final dynamic error = json['error'];
    if (error is Map<String, dynamic>) {
      final Map<String, String> fields = <String, String>{};
      final dynamic rawFields = error['fields'];
      if (rawFields is Map<String, dynamic>) {
        rawFields.forEach((String key, dynamic value) => fields[key] = '$value');
      }
      return ApiException(
        code: '${error['code'] ?? codeGeneric}',
        message: '${error['message'] ?? 'Something went wrong'}',
        statusCode: statusCode,
        fieldErrors: fields,
      );
    }
    return ApiException(
      code: '${json['code'] ?? codeGeneric}',
      message: '${json['message'] ?? json['detail'] ?? 'Something went wrong'}',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => 'ApiException($code, $message, status: $statusCode)';
}
