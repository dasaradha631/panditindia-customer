import '../models/api_error.dart';
import '../models/auth_models.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'session_service.dart';

/// In-memory authentication used while the PanditIndia backend is not
/// connected (`USE_MOCK_API=true`, the default outside production).
///
/// Demo credentials
///  - mobile `9876543210` / password `Passw0rd`
///  - email  `demo@panditindia.com` / password `Passw0rd`
///  - OTP for any destination: `123456`
class MockAuthService implements AuthService {
  MockAuthService({
    SessionService? session,
    this.latency = const Duration(milliseconds: 450),
  }) : _session = session ?? SessionService.instance;

  final SessionService _session;
  final Duration latency;

  static const String demoPassword = 'Passw0rd';
  static const String demoOtp = '123456';

  static const UserModel _demoUser = UserModel(
    id: 'cus_1001',
    fullName: 'Rahul Sharma',
    mobile: '9876543210',
    email: 'demo@panditindia.com',
    city: 'Hyderabad',
  );

  final List<String> _registeredEmails = <String>['demo@panditindia.com'];
  final List<String> _registeredMobiles = <String>['9876543210'];

  Future<void> _wait() => Future<void>.delayed(latency);

  AuthSession _sessionFor(UserModel user) => AuthSession(
        tokens: AuthTokens(
          accessToken: 'mock.access.${user.id}.${DateTime.now().millisecondsSinceEpoch}',
          refreshToken: 'mock.refresh.${user.id}',
          expiresIn: 3600,
        ),
        user: user,
      );

  static bool _isEmail(String value) => value.contains('@');

  @override
  Future<AuthSession> login(LoginRequest request) async {
    await _wait();
    final String identifier = request.identifier.trim();
    final bool matchesUser = (identifier == _demoUser.mobile ||
            identifier.toLowerCase() == _demoUser.email) &&
        request.password == demoPassword;
    if (!matchesUser) {
      throw ApiException(
        code: ApiException.codeInvalidCredentials,
        message: 'The email/mobile or password you entered is incorrect.',
        statusCode: 401,
        fieldErrors: <String, String>{},
      );
    }
    final AuthSession session = _sessionFor(_demoUser);
    await _session.saveSession(session);
    return session;
  }

  @override
  Future<AuthSession> register(RegisterRequest request) async {
    await _wait();
    final Map<String, String> fields = <String, String>{};
    if (_registeredMobiles.contains(request.mobile)) {
      fields['mobile'] = 'This mobile number is already registered';
    }
    final String? email = request.email?.trim();
    if (email != null && email.isNotEmpty && _registeredEmails.contains(email)) {
      fields['email'] = 'This email address is already registered';
    }
    if (fields.isNotEmpty) {
      throw ApiException(
        code: fields.containsKey('mobile')
            ? ApiException.codeMobileExists
            : ApiException.codeEmailExists,
        message: fields.values.first,
        statusCode: 409,
        fieldErrors: fields,
      );
    }

    _registeredMobiles.add(request.mobile);
    if (email != null && email.isNotEmpty) _registeredEmails.add(email);

    final UserModel user = UserModel(
      id: 'cus_${DateTime.now().millisecondsSinceEpoch}',
      fullName: request.fullName,
      mobile: request.mobile,
      email: email,
      city: 'Hyderabad',
    );
    final AuthSession session = _sessionFor(user);
    await _session.saveSession(session);
    return session;
  }

  @override
  Future<OtpChallenge> forgotPassword(ForgotPasswordRequest request) async {
    await _wait();
    final String identifier = request.identifier.trim();
    if (identifier.isEmpty) {
      throw ApiException(
        code: ApiException.codeGeneric,
        message: 'Enter your registered email or mobile number',
        fieldErrors: <String, String>{'identifier': 'This field is required'},
      );
    }
    final String masked = _isEmail(identifier)
        ? _maskEmail(identifier)
        : _maskMobile(identifier);
    return OtpChallenge(otpToken: 'mock.otp.${identifier.hashCode}', destination: masked);
  }

  @override
  Future<String> verifyOtp(VerifyOtpRequest request) async {
    await _wait();
    if (request.otp.trim() == '000000') {
      throw ApiException(
        code: ApiException.codeOtpExpired,
        message: 'This code has expired. Please request a new one.',
        statusCode: 410,
      );
    }
    if (request.otp.trim() != demoOtp) {
      throw ApiException(
        code: ApiException.codeInvalidOtp,
        message: 'The verification code is incorrect',
        statusCode: 400,
        fieldErrors: <String, String>{'otp': 'Incorrect code'},
      );
    }
    return 'mock.reset.${request.otpToken}';
  }

  @override
  Future<void> resetPassword(ResetPasswordRequest request) async {
    await _wait();
    if (request.newPassword.length < 8) {
      throw ApiException(
        code: ApiException.codeWeakPassword,
        message: 'Password must be at least 8 characters',
        fieldErrors: <String, String>{'password': 'Use at least 8 characters'},
      );
    }
  }

  @override
  Future<AuthSession> socialLogin(SocialLoginRequest request) async {
    await _wait();
    throw ApiException(
      code: ApiException.codeSocialNotConfigured,
      message: request.provider == 'apple'
          ? 'Apple Sign-In will be enabled once the OAuth keys are added.'
          : 'Google Sign-In will be enabled once the OAuth keys are added.',
      statusCode: 501,
    );
  }

  @override
  Future<UserModel> me() async {
    await _wait();
    final UserModel? stored = await _session.user();
    if (stored == null) {
      throw ApiException(
        code: ApiException.codeSessionExpired,
        message: 'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
    }
    return stored;
  }

  @override
  Future<void> logout() async {
    await _session.clear();
  }

  static String _maskMobile(String value) {
    if (value.length < 4) return value;
    return '******${value.substring(value.length - 4)}';
  }

  static String _maskEmail(String value) {
    final int at = value.indexOf('@');
    if (at <= 1) return value;
    return '${value.substring(0, 1)}***${value.substring(at)}';
  }
}
