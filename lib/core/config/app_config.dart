import 'environment.dart';

/// Runtime configuration resolved from `--dart-define` values.
///
/// ```
/// flutter run --dart-define=ENV=production \
///   --dart-define=API_BASE_URL=https://api.panditindia.com/v1
/// ```
///
/// No secret, key or production URL is ever hardcoded inside widgets
/// (PDF section 16).
class AppConfig {
  AppConfig._();

  static const String envName =
      String.fromEnvironment('ENV', defaultValue: 'development');
  static const String apiBaseUrlDefine =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static final AppEnvironment environment = AppEnvironment.fromName(envName);

  /// Mock services are used outside production until the backend is wired.
  static const bool useMockApi =
      bool.fromEnvironment('USE_MOCK_API', defaultValue: true);

  static const String _fallbackBaseUrl = 'https://api.panditindia.com/v1';

  static String get baseUrl =>
      apiBaseUrlDefine.isNotEmpty ? apiBaseUrlDefine : _fallbackBaseUrl;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static const String appName = 'PanditIndia';
  static const String appVersion = '1.0.0';

  static Map<String, Object> debugInfo() => <String, Object>{
        'environment': environment.name,
        'baseUrl': baseUrl,
        'useMockApi': useMockApi,
      };
}
