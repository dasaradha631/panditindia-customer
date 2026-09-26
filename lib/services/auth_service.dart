import '../core/config/app_config.dart';
import '../models/api_error.dart';
import '../models/auth_models.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'mock_auth_service.dart';
import 'session_service.dart';

/// Authentication boundary (PDF section 17 - keep integration behind
/// service/repository layers).
abstract class AuthService {
  Future<AuthSession> login(LoginRequest request);

  Future<AuthSession> register(RegisterRequest request);

  Future<OtpChallenge> forgotPassword(ForgotPasswordRequest request);

  /// Returns the short lived reset token.
  Future<String> verifyOtp(VerifyOtpRequest request);

  Future<void> resetPassword(ResetPasswordRequest request);

  Future<AuthSession> socialLogin(SocialLoginRequest request);

  Future<UserModel> me();

  Future<void> logout();
}

/// Picks the implementation from `--dart-define=USE_MOCK_API`.
class AuthServiceFactory {
  AuthServiceFactory._();

  static AuthService create() =>
      AppConfig.useMockApi ? MockAuthService() : RemoteAuthService();

  static AuthService instance = create();
}

/// Real HTTP implementation - active when `USE_MOCK_API=false`.
class RemoteAuthService implements AuthService {
  RemoteAuthService({ApiService? api, SessionService? session})
      : _api = api ?? ApiService(),
        _session = session ?? SessionService.instance;

  final ApiService _api;
  final SessionService _session;

  Map<String, dynamic> _unwrap(dynamic body) {
    if (body is Map<String, dynamic>) {
      final dynamic data = body['data'];
      if (data is Map<String, dynamic>) return data;
      return body;
    }
    throw ApiException(
      code: ApiException.codeGeneric,
      message: 'Unexpected server response',
    );
  }

  Future<AuthSession> _persist(dynamic body) async {
    final AuthSession session = AuthSession.fromJson(_unwrap(body));
    await _session.saveSession(session);
    return session;
  }

  @override
  Future<AuthSession> login(LoginRequest request) async =>
      _persist(await _api.post('/auth/login', data: request.toJson()));

  @override
  Future<AuthSession> register(RegisterRequest request) async =>
      _persist(await _api.post('/auth/register', data: request.toJson()));

  @override
  Future<OtpChallenge> forgotPassword(ForgotPasswordRequest request) async =>
      OtpChallenge.fromJson(
        _unwrap(await _api.post('/auth/forgot-password', data: request.toJson())),
      );

  @override
  Future<String> verifyOtp(VerifyOtpRequest request) async {
    final Map<String, dynamic> data =
        _unwrap(await _api.post('/auth/verify-otp', data: request.toJson()));
    return '${data['reset_token'] ?? ''}';
  }

  @override
  Future<void> resetPassword(ResetPasswordRequest request) async {
    await _api.post('/auth/reset-password', data: request.toJson());
  }

  @override
  Future<AuthSession> socialLogin(SocialLoginRequest request) async =>
      _persist(await _api.post('/auth/social-login', data: request.toJson()));

  @override
  Future<UserModel> me() async =>
      UserModel.fromJson(_unwrap(await _api.get('/auth/me')));

  @override
  Future<void> logout() async {
    final String? refresh = await _session.refreshToken();
    try {
      await _api.post('/auth/logout', data: <String, dynamic>{
        'refresh_token': refresh,
      });
    } on ApiException {
      // Sign out must succeed locally even when the API call fails.
    }
    await _session.clear();
  }
}
