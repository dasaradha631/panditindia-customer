import 'package:flutter_test/flutter_test.dart';
import 'package:panditindia_customer/core/constants/app_strings.dart';
import 'package:panditindia_customer/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('rejects null, empty and whitespace', () {
      expect(Validators.required(null), AppStrings.requiredField);
      expect(Validators.required(''), AppStrings.requiredField);
      expect(Validators.required('   '), AppStrings.requiredField);
    });

    test('accepts a value', () {
      expect(Validators.required('x'), isNull);
    });
  });

  group('Validators.email', () {
    test('accepts a valid address', () {
      expect(Validators.email('demo@panditindia.com'), isNull);
    });

    test('rejects malformed addresses', () {
      expect(Validators.email('demo@pandit'), AppStrings.invalidEmail);
      expect(Validators.email('not-an-email'), AppStrings.invalidEmail);
    });

    test('optional email may be empty', () {
      expect(Validators.email('', optional: true), isNull);
      expect(Validators.email(null, optional: true), isNull);
      expect(Validators.email('bad', optional: true), AppStrings.invalidEmail);
    });
  });

  group('Validators.mobile', () {
    test('accepts 10 digit numbers starting 6-9', () {
      expect(Validators.mobile('9876543210'), isNull);
      expect(Validators.mobile('6123456789'), isNull);
      expect(Validators.mobile('98765 43210'), isNull);
      expect(Validators.mobile('98765-43210'), isNull);
    });

    test('rejects invalid numbers', () {
      expect(Validators.mobile('5876543210'), AppStrings.invalidMobile);
      expect(Validators.mobile('987654321'), AppStrings.invalidMobile);
      expect(Validators.mobile('98765432101'), AppStrings.invalidMobile);
      expect(Validators.mobile(''), AppStrings.invalidMobile);
      expect(Validators.mobile(null), AppStrings.invalidMobile);
    });
  });

  group('Validators.identifier', () {
    test('accepts email or mobile', () {
      expect(Validators.identifier('demo@panditindia.com'), isNull);
      expect(Validators.identifier('9876543210'), isNull);
      expect(Validators.identifier('+91 9876543210'), isNull);
      expect(Validators.identifier('919876543210'), isNull);
      expect(Validators.identifier('09876543210'), isNull);
    });

    test('rejects everything else', () {
      expect(Validators.identifier(''), isNotNull);
      expect(Validators.identifier('demo@bad'), isNotNull);
      expect(Validators.identifier('12345'), isNotNull);
      expect(Validators.identifier('91987654321'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('requires 8+ chars with a letter and a number', () {
      expect(Validators.password('Passw0rd'), isNull);
      expect(Validators.password('Passw0r'), AppStrings.weakPassword);
      expect(Validators.password('password'), AppStrings.weakPassword);
      expect(Validators.password('12345678'), AppStrings.weakPassword);
      expect(Validators.password(''), 'Enter your password');
    });

    test('confirmPassword matches', () {
      expect(Validators.confirmPassword('Passw0rd', 'Passw0rd'), isNull);
      expect(
        Validators.confirmPassword('Passw0rd', 'Passw0rd2'),
        AppStrings.passwordMismatch,
      );
      expect(Validators.confirmPassword('', 'x'), AppStrings.requiredField);
    });
  });

  group('Validators.otp', () {
    test('accepts exactly 6 digits', () {
      expect(Validators.otp('123456'), isNull);
      expect(Validators.otp(' 123456 '), isNull);
      expect(Validators.otp('12345'), AppStrings.invalidOtp);
      expect(Validators.otp('1234567'), AppStrings.invalidOtp);
      expect(Validators.otp('12345a'), AppStrings.invalidOtp);
      expect(Validators.otp(''), AppStrings.invalidOtp);
    });
  });

  group('Validators.name', () {
    test('requires at least 3 characters', () {
      expect(Validators.name(null), 'Enter your full name');
      expect(Validators.name('Ra'), 'Enter at least 3 characters');
      expect(Validators.name('Rahul Sharma'), isNull);
    });
  });
}
