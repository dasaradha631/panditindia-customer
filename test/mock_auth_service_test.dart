import 'package:flutter_test/flutter_test.dart';
import 'package:panditindia_customer/models/api_error.dart';
import 'package:panditindia_customer/models/auth_models.dart';
import 'package:panditindia_customer/services/mock_auth_service.dart';
import 'package:panditindia_customer/services/session_service.dart';

void main() {
  late InMemorySecureStore store;
  late SessionService session;
  late MockAuthService auth;

  setUp(() {
    store = InMemorySecureStore();
    session = SessionService(store: store);
    auth = MockAuthService(
      session: session,
      latency: Duration.zero,
    );
  });

  group('login', () {
    test('accepts demo mobile credentials and stores a session', () async {
      final AuthSession result = await auth.login(
        const LoginRequest(identifier: '9876543210', password: 'Passw0rd'),
      );
      expect(result.user.id, 'cus_1001');
      expect(await session.hasSession(), isTrue);
      expect(await session.accessToken(), startsWith('mock.access.cus_1001'));
    });

    test('accepts demo email credentials', () async {
      final AuthSession result = await auth.login(
        const LoginRequest(
          identifier: 'demo@panditindia.com',
          password: 'Passw0rd',
        ),
      );
      expect(result.user.email, 'demo@panditindia.com');
    });

    test('rejects a wrong password with an ApiException', () async {
      await expectLater(
        auth.login(
          const LoginRequest(identifier: '9876543210', password: 'wrong'),
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.code,
            'code',
            ApiException.codeInvalidCredentials,
          ),
        ),
      );
      expect(await session.hasSession(), isFalse);
    });

    test('rejects an unknown identifier', () async {
      await expectLater(
        auth.login(
          const LoginRequest(identifier: '0000000000', password: 'Passw0rd'),
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('register', () {
    test('creates an account and signs the user in', () async {
      final AuthSession result = await auth.register(
        const RegisterRequest(
          fullName: 'Priya Iyer',
          mobile: '9123456780',
          email: 'priya@example.com',
          password: 'Secret12',
          acceptTerms: true,
        ),
      );
      expect(result.user.fullName, 'Priya Iyer');
      expect(await session.hasSession(), isTrue);
    });

    test('rejects the already registered demo mobile', () async {
      await expectLater(
        auth.register(
          const RegisterRequest(
            fullName: 'Dup User',
            mobile: '9876543210',
            password: 'Secret12',
          ),
        ),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.code, 'code',
                  ApiException.codeMobileExists)
              .having((ApiException e) => e.statusCode, 'statusCode', 409),
        ),
      );
    });

    test('rejects the already registered demo email', () async {
      await expectLater(
        auth.register(
          const RegisterRequest(
            fullName: 'Dup Mail',
            mobile: '9123456781',
            email: 'demo@panditindia.com',
            password: 'Secret12',
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.code,
            'code',
            ApiException.codeEmailExists,
          ),
        ),
      );
    });
  });

  group('password recovery', () {
    test('forgotPassword returns a masked destination', () async {
      final OtpChallenge challenge = await auth.forgotPassword(
        const ForgotPasswordRequest(identifier: '9876543210'),
      );
      expect(challenge.destination, '******3210');
      expect(challenge.otpToken, startsWith('mock.otp.'));

      final OtpChallenge emailChallenge = await auth.forgotPassword(
        const ForgotPasswordRequest(identifier: 'demo@panditindia.com'),
      );
      expect(emailChallenge.destination, 'd***@panditindia.com');
    });

    test('verifyOtp accepts 123456 and rejects the rest', () async {
      final String resetToken = await auth.verifyOtp(
        const VerifyOtpRequest(otpToken: 'mock.otp.1', otp: '123456'),
      );
      expect(resetToken, startsWith('mock.reset.'));

      await expectLater(
        auth.verifyOtp(
          const VerifyOtpRequest(otpToken: 'mock.otp.1', otp: '999999'),
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.code,
            'code',
            ApiException.codeInvalidOtp,
          ),
        ),
      );
    });

    test('verifyOtp flags an expired code (000000)', () async {
      await expectLater(
        auth.verifyOtp(
          const VerifyOtpRequest(otpToken: 'mock.otp.1', otp: '000000'),
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.code,
            'code',
            ApiException.codeOtpExpired,
          ),
        ),
      );
    });

    test('resetPassword enforces the password rule', () async {
      await expectLater(
        auth.resetPassword(
          const ResetPasswordRequest(resetToken: 't', newPassword: 'short'),
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.code,
            'code',
            ApiException.codeWeakPassword,
          ),
        ),
      );
      await expectLater(
        auth.resetPassword(
          const ResetPasswordRequest(
            resetToken: 't',
            newPassword: 'NewPass12',
          ),
        ),
        completes,
      );
    });
  });

  group('session endpoints', () {
    test('me() requires a stored user', () async {
      await expectLater(
        auth.me(),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.code,
            'code',
            ApiException.codeSessionExpired,
          ),
        ),
      );

      await auth.login(
        const LoginRequest(identifier: '9876543210', password: 'Passw0rd'),
      );
      final result = await auth.me();
      expect(result.mobile, '9876543210');
    });

    test('logout() clears the stored session', () async {
      await auth.login(
        const LoginRequest(identifier: '9876543210', password: 'Passw0rd'),
      );
      await auth.logout();
      expect(await session.hasSession(), isFalse);
    });

    test('socialLogin is not configured yet', () async {
      await expectLater(
        auth.socialLogin(const SocialLoginRequest(provider: 'google')),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.code,
            'code',
            ApiException.codeSocialNotConfigured,
          ),
        ),
      );
    });
  });
}
