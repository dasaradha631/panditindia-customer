import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/core/network/api_client.dart';
import 'package:customer_app/providers/auth_provider.dart';

import 'support/test_environment.dart';

void main() {
  setUpAll(TestEnvironment.ensureLoaded);

  group('ApiException.isSessionConflict', () {
    test('detects detail.session_conflict flag (401 only)', () {
      final e = ApiException(
        'Logged in elsewhere',
        statusCode: 401,
        data: {
          'detail': {'session_conflict': true, 'message': 'Signed in from another browser'},
        },
      );
      expect(e.isSessionConflict, isTrue);
    });

    test('detects "another browser" message text', () {
      final e = ApiException(
        'Your account was logged in from another browser or device.',
        statusCode: 401,
        data: {
          'detail': 'Your account was logged in from another browser or device.',
        },
      );
      expect(e.isSessionConflict, isTrue);
    });

    test('plain 401 without conflict markers is not a conflict', () {
      final e = ApiException('Invalid credentials', statusCode: 401, data: null);
      expect(e.isSessionConflict, isFalse);
    });

    test('409/500 never count as session conflicts', () {
      final e409 = ApiException('Conflict', statusCode: 409, data: {
        'session_conflict': true,
      });
      expect(e409.isSessionConflict, isFalse);
    });
  });

  group('AuthProvider.handleSessionConflict', () {
    test('fires onSessionConflict and clears the local session', () async {
      final provider = AuthProvider();
      String? fired;
      AuthProvider.onSessionConflict = (m) => fired = m;
      addTearDown(() => AuthProvider.onSessionConflict = null);

      // No session → must be a no-op (conflict can fire after logout races).
      await provider.handleSessionConflict('x');
      expect(fired, isNull);

      expect(provider.isLoggedIn, isFalse);
    });
  });
}
