import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../providers/auth_provider.dart';
import 'device_registration_api.dart';
import 'push_notification_service.dart';

/// Keeps the server told which installation gets this account's
/// notifications.
///
/// - **Register** (POST) each time there is both a signed-in account and an
///   installation ID (started with permission, changed, or just allowed in
///   the "Turn on notifications?" window), and after each sign-in. Once per
///   (account, ID) pair: the server call is idempotent but limited to 30 an
///   hour.
/// - **Remove** (DELETE) at sign-out, **before** the auth token is erased
///   ([unregisterForSignOut], run by `AuthProvider.logout`).
/// - A failure (network, 5xx, 429) shows nothing and is not retried until the
///   ID or the account changes, or the app starts again; a 401 is left to the
///   session code. The ID is never logged.
class PushRegistration {
  PushRegistration({
    required this.push,
    required this.api,
    required this.platform,
    this.signOutTimeout = const Duration(seconds: 5),
  });

  final PushNotificationService push;
  final DeviceRegistrationApi api;

  /// `ios` or `android`.
  final String platform;

  AuthProvider? _auth;
  StreamSubscription<String?>? _idSub;
  String? _registeredKey;
  String? _failedKey;
  bool _inFlight = false;
  bool _signingOut = false;

  /// The longest the sign-out waits for the server to remove this phone.
  final Duration signOutTimeout;

  /// Follows the account and the installation ID.
  void attach(AuthProvider auth) {
    _auth = auth;
    auth.addListener(_sync);
    _idSub = push.installationIdChanges.listen((_) => _sync());
    _sync();
  }

  void dispose() {
    _auth?.removeListener(_sync);
    _idSub?.cancel();
  }

  String _keyOf(AuthProvider auth, String id) => '${auth.user?.id}|$id';

  void _sync() {
    final auth = _auth;
    if (auth == null) return;
    if (!auth.isLoggedIn) {
      // Signed out: forget, so the next sign-in registers again.
      _signingOut = false;
      _registeredKey = null;
      _failedKey = null;
      return;
    }
    if (_signingOut || _inFlight) return;
    final id = push.installationId;
    if (id == null) return;
    final key = _keyOf(auth, id);
    if (key == _registeredKey || key == _failedKey) return;
    unawaited(_register(key, id));
  }

  Future<void> _register(String key, String id) async {
    _inFlight = true;
    DeviceCallResult result;
    try {
      result = await api.register(id, platform);
    } catch (_) {
      result = DeviceCallResult.retryLater;
    }
    _inFlight = false;
    if (result == DeviceCallResult.done) {
      _registeredKey = key;
    } else {
      _failedKey = key;
    }
    // The account or the ID may have changed while the call was running.
    _sync();
  }

  /// Removes this installation from the account, before the sign-out erases
  /// the auth token. Never throws and never waits long: a failure must not
  /// prevent signing out.
  Future<void> unregisterForSignOut() async {
    _signingOut = true;
    final id = push.installationId;
    if (id == null) return;
    try {
      await api.unregister(id).timeout(signOutTimeout);
    } catch (e) {
      debugPrint('[PUSH] Removal skipped: ${e.runtimeType}');
    }
  }
}
