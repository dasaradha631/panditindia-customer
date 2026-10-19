import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/storage/session_store.dart';
import '../models/user_session.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({SessionStore? store}) : store = store ?? SessionStore.instance {
    ApiClient.authToken = null;
    // Any API call in the app can be the one that discovers the session was
    // replaced (web parity: api.js response interceptor → session-conflict).
    ApiClient.onSessionConflict = handleSessionConflict;
  }

  final SessionStore store;
  final AuthService _auth = AuthService();

  UserSession? _session;
  bool _restored = false;
  Timer? _idleTimer;
  Timer? _sessionTimer;
  bool _idleCheckRunning = false;
  bool _sessionCheckRunning = false;

  /// Inactivity window before the app signs the devotee out automatically —
  /// 15 minutes of no interaction (the web dashboard logs off idle sessions
  /// the same way). Any tap on the app, or opening the app again, restarts
  /// the clock.
  static const Duration idleTimeout = Duration(minutes: 15);

  /// Wired up by SessionGuard so an idle expiry can route to the sign-in
  /// screen with an explanation instead of leaving stale, empty screens.
  static void Function()? onIdleExpired;

  /// Wired up by SessionGuard so a replaced-session 401 can route to the
  /// sign-in screen with the backend's "another browser or device" message.
  static void Function(String message)? onSessionConflict;

  UserSession? get session => _session;
  bool get isLoggedIn =>
      _session != null && (_session!.token?.isNotEmpty ?? false);
  bool get restored => _restored;
  String get recipientId {
    final s = _session;
    return (s?.phone?.isNotEmpty ?? false)
        ? s!.phone!
        : (s?.email?.isNotEmpty ?? false)
        ? s!.email!
        : (s?.displayName ?? '');
  }

  Future<void> restoreSession() async {
    final user = await store.readUser();
    final token = await store.readToken();
    final role = await store.readRole();
    if (user != null && token != null && token.isNotEmpty) {
      user['token'] = token;
      user['role'] = role ?? user['role'] ?? 'user';
      _session = UserSession.fromJson(user);
      ApiClient.authToken = token;
      // Opening the app counts as activity — the 15-minute idle clock
      // starts now, not from whenever the session was last saved (otherwise
      // a fresh app open would instantly sign the user out and every screen
      // would come up empty).
      await store.touchActivity();
      _startIdleTimer();
    }
    _restored = true;
    notifyListeners();
  }

  Future<String?> login({
    required String identifier,
    required String password,
    String role = 'user',
  }) async {
    final res = await _auth.login(
      email: identifier,
      password: password,
      role: role,
    );
    if (!res.success || res.data == null) {
      return res.message ?? 'Login failed. Please verify your credentials.';
    }
    final data = res.data!;
    final session = UserSession.fromLoginResponse(data);
    _session = session;
    ApiClient.authToken = session.token;
    await store.saveSession(
      token: session.token ?? '',
      role: session.role ?? role,
      user: session.toJson(),
    );
    _startIdleTimer();
    notifyListeners();
    return null;
  }

  /// Registers a new devotee. With [persistSession] false the returned JWT is
  /// discarded so the user is sent to Sign In instead of being logged in.
  Future<String?> register(
    Map<String, dynamic> payload, {
    bool persistSession = true,
  }) async {
    final res = await _auth.register(payload);
    if (!res.success || res.data == null) {
      return res.message ?? 'Registration failed. Please check your details.';
    }
    final data = res.data!;
    if (!persistSession) return null;
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      return res.message;
    }
    final session = UserSession.fromLoginResponse(data);
    _session = session;
    ApiClient.authToken = token;
    await store.saveSession(
      token: token,
      role: session.role ?? 'user',
      user: session.toJson(),
    );
    _startIdleTimer();
    notifyListeners();
    return null;
  }

  /// Sends a registration OTP to [identifier] over [channel]
  /// ('email' or 'phone'). Returns null on success, else the error message.
  Future<String?> sendRegistrationOtp({
    required String identifier,
    required String channel,
  }) async {
    final res = await _auth.sendRegistrationOtp(
      identifier: identifier,
      channel: channel,
    );
    return res.success ? null : (res.message ?? 'Could not send OTP. Please try again.');
  }

  /// Verifies the 6-digit registration OTP. Returns null on success.
  Future<String?> verifyRegistrationOtp({
    required String identifier,
    required String channel,
    required String otp,
  }) async {
    final res = await _auth.verifyRegistrationOtp(
      identifier: identifier,
      channel: channel,
      otp: otp,
    );
    return res.success ? null : (res.message ?? 'Could not verify this code. Please try again.');
  }

  Future<AuthResult> forgotPassword(String email) =>
      _auth.forgotPassword(email);

  Future<AuthResult> verifyOtp({required String email, required String otp}) =>
      _auth.verifyOtp(email: email, otp: otp);

  Future<AuthResult> changePassword({
    required String email,
    required String newPassword,
  }) => _auth.changePassword(email: email, newPassword: newPassword);

  Future<void> logout() async {
    _idleTimer?.cancel();
    _sessionTimer?.cancel();
    await _auth.logout();
    await store.clear();
    _session = null;
    ApiClient.authToken = null;
    notifyListeners();
  }

  /// Server-side single-session enforcement: another login replaced this
  /// token. Drop the local session immediately (no /logout call — the token
  /// is already invalid) and let SessionGuard route to the sign-in screen.
  Future<void> handleSessionConflict(String message) async {
    if (_session == null) return;
    _idleTimer?.cancel();
    _sessionTimer?.cancel();
    await store.clear();
    _session = null;
    ApiClient.authToken = null;
    notifyListeners();
    onSessionConflict?.call(
      message.isNotEmpty
          ? message
          : 'Your account has been signed in from another browser or device.',
    );
  }

  /// Web parity: AuthContext's 10-second `/session-check` heartbeat plus the
  /// focus/visibility re-check — the app equivalent is a foreground timer and
  /// an immediate check whenever the app resumes.
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(verifySessionNow()),
    );
  }

  /// Immediate single-session verification (call on app resume too).
  Future<void> verifySessionNow() async {
    if (_sessionCheckRunning || _session == null) return;
    _sessionCheckRunning = true;
    try {
      await _auth.sessionCheck();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await handleSessionConflict(e.isSessionConflict ? e.message : '');
      }
    } catch (_) {
      // Network blips must not sign the user out — only an explicit 401 does.
    } finally {
      _sessionCheckRunning = false;
    }
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkIdle(),
    );
    _startSessionTimer();
  }

  Future<void> _checkIdle() async {
    if (_idleCheckRunning || _session == null) return;
    _idleCheckRunning = true;
    try {
      final last = await store.lastActivity();
      if (last == null) return;
      if (DateTime.now().difference(last) <= idleTimeout) return;
      // Re-read after the await so a tap that landed mid-check wins.
      final fresh = await store.lastActivity();
      if (fresh != null && DateTime.now().difference(fresh) <= idleTimeout) {
        return;
      }
      await logout();
      onIdleExpired?.call();
    } finally {
      _idleCheckRunning = false;
    }
  }

  DateTime _lastTouch = DateTime.fromMillisecondsSinceEpoch(0);

  /// Records user activity for the idle-logout timer. Throttled so pointer
  /// handlers can call it freely without writing SharedPreferences on every
  /// tap (web parity: 15-minute inactivity sign-out).
  void touchActivityThrottled() {
    final now = DateTime.now();
    if (now.difference(_lastTouch) < const Duration(seconds: 30)) return;
    _lastTouch = now;
    unawaited(store.touchActivity());
  }

  Future<void> touchActivity() => store.touchActivity();

  void applyProfile(CustomerProfile profile) {
    final s = _session;
    if (s == null) return;
    _session = UserSession(
      id: s.id,
      name: profile.fullName ?? s.name,
      username: s.username,
      email: profile.email ?? s.email,
      phone: profile.phonenumber ?? s.phone,
      role: s.role,
      token: s.token,
      gotra: profile.gotra ?? s.gotra,
      kulaDevata: profile.kulaDevata ?? s.kulaDevata,
      city: profile.city ?? s.city,
      state: profile.state ?? s.state,
    );
    store.saveSession(
      token: s.token ?? '',
      role: s.role ?? 'user',
      user: _session!.toJson(),
    );
    notifyListeners();
  }
}
