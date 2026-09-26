import 'user_model.dart';

/// Request / response payloads for the authentication endpoints.
///
/// The exact wire contract is documented in `docs/api-contract.md`
/// (PDF section 17).
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn = 3600,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: '${json['access_token'] ?? ''}',
        refreshToken: '${json['refresh_token'] ?? ''}',
        expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': expiresIn,
      };
}

class AuthSession {
  const AuthSession({required this.tokens, required this.user});

  final AuthTokens tokens;
  final UserModel user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        tokens: AuthTokens.fromJson(
          (json['tokens'] as Map<String, dynamic>?) ??
              <String, dynamic>{
                'access_token': json['access_token'],
                'refresh_token': json['refresh_token'],
                'expires_in': json['expires_in'],
              },
        ),
        user: UserModel.fromJson(
          (json['user'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        ),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tokens': tokens.toJson(),
        'user': user.toJson(),
      };
}

class LoginRequest {
  const LoginRequest({required this.identifier, required this.password});

  final String identifier;
  final String password;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'identifier': identifier, 'password': password};
}

class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.mobile,
    required this.password,
    this.email,
    this.acceptTerms = false,
    this.referralCode,
  });

  final String fullName;
  final String mobile;
  final String? email;
  final String password;
  final bool acceptTerms;
  final String? referralCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'full_name': fullName,
        'mobile': mobile,
        'email': email,
        'password': password,
        'accept_terms': acceptTerms,
        'referral_code': referralCode,
      };
}

class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.identifier});

  final String identifier;

  Map<String, dynamic> toJson() => <String, dynamic>{'identifier': identifier};
}

/// Response of `POST /auth/forgot-password`.
class OtpChallenge {
  const OtpChallenge({required this.otpToken, required this.destination});

  final String otpToken;
  final String destination;

  factory OtpChallenge.fromJson(Map<String, dynamic> json) => OtpChallenge(
        otpToken: '${json['otp_token'] ?? ''}',
        destination: '${json['masked_destination'] ?? json['destination'] ?? ''}',
      );
}

class VerifyOtpRequest {
  const VerifyOtpRequest({required this.otpToken, required this.otp});

  final String otpToken;
  final String otp;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'otp_token': otpToken, 'otp': otp};
}

class ResetPasswordRequest {
  const ResetPasswordRequest({required this.resetToken, required this.newPassword});

  final String resetToken;
  final String newPassword;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'reset_token': resetToken, 'new_password': newPassword};
}

class SocialLoginRequest {
  const SocialLoginRequest({
    required this.provider,
    this.idToken,
    this.accessToken,
  });

  final String provider;
  final String? idToken;
  final String? accessToken;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'provider': provider,
        'id_token': idToken,
        'access_token': accessToken,
      };
}
