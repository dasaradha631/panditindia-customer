import '../constants/app_strings.dart';

/// Form validation rules shared by every feature screen.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(
    r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$",
  );

  /// Indian mobile numbers: 10 digits starting 6-9.
  static final RegExp _mobile = RegExp(r'^[6-9]\d{9}$');

  static final RegExp _password = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');

  static final RegExp _otp = RegExp(r'^\d{6}$');

  static String? required(String? value, [String message = AppStrings.requiredField]) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? name(String? value) {
    final String? base = required(value, 'Enter your full name');
    if (base != null) return base;
    if (value!.trim().length < 3) return 'Enter at least 3 characters';
    return null;
  }

  static String? email(String? value, {bool optional = false}) {
    if (value == null || value.trim().isEmpty) {
      return optional ? null : AppStrings.invalidEmail;
    }
    if (!_email.hasMatch(value.trim())) return AppStrings.invalidEmail;
    return null;
  }

  static String? mobile(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.invalidMobile;
    final String digits = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (!_mobile.hasMatch(digits)) return AppStrings.invalidMobile;
    return null;
  }

  /// Accepts either an email address or an Indian mobile number.
  static String? identifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email or mobile number';
    }
    final String trimmed = value.trim();
    if (trimmed.contains('@')) {
      return _email.hasMatch(trimmed) ? null : AppStrings.invalidEmail;
    }
    String digits = trimmed.replaceAll(RegExp(r'[\s\-]'), '');
    if (digits.length == 10 && _mobile.hasMatch(digits)) return null;
    digits = digits.replaceFirst(RegExp(r'^(\+91|91|0)'), '');
    if (digits.length == 10 && _mobile.hasMatch(digits)) return null;
    return 'Enter a valid email or 10 digit mobile number';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    if (!_password.hasMatch(value)) return AppStrings.weakPassword;
    return null;
  }

  /// Same rule but the field is required to be filled first.
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.requiredField;
    if (!_password.hasMatch(value)) return AppStrings.weakPassword;
    return null;
  }

  static String? confirmPassword(String? value, String other) {
    if (value == null || value.isEmpty) return AppStrings.requiredField;
    if (value != other) return AppStrings.passwordMismatch;
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.invalidOtp;
    if (!_otp.hasMatch(value.trim())) return AppStrings.invalidOtp;
    return null;
  }
}
