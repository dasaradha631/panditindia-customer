import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_models.dart';
import '../models/user_model.dart';

/// Minimal encrypted key/value contract so services can be unit tested
/// without platform channels.
abstract class SecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Production store backed by `flutter_secure_storage`.
class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// In-memory store used by tests and previews.
class InMemorySecureStore implements SecureStore {
  final Map<String, String> _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }
}

/// Encrypted token + session persistence (PDF section 15 - secure storage).
class SessionService {
  SessionService({SecureStore? store}) : _store = store ?? const FlutterSecureStore();

  static SessionService instance = SessionService();

  static const String _kAccess = 'pi.access_token';
  static const String _kRefresh = 'pi.refresh_token';
  static const String _kUser = 'pi.user';

  final SecureStore _store;

  Future<void> saveSession(AuthSession session) async {
    await _store.write(_kAccess, session.tokens.accessToken);
    await _store.write(_kRefresh, session.tokens.refreshToken);
    await _store.write(_kUser, jsonEncode(session.user.toJson()));
  }

  Future<void> saveTokens(AuthTokens tokens) async {
    await _store.write(_kAccess, tokens.accessToken);
    await _store.write(_kRefresh, tokens.refreshToken);
  }

  Future<String?> accessToken() => _store.read(_kAccess);

  Future<String?> refreshToken() => _store.read(_kRefresh);

  Future<UserModel?> user() async {
    final String? raw = await _store.read(_kUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  Future<bool> hasSession() async {
    final String? token = await _store.read(_kAccess);
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    await _store.delete(_kAccess);
    await _store.delete(_kRefresh);
    await _store.delete(_kUser);
  }
}
