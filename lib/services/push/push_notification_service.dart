import 'dart:async';

import 'package:flutter/foundation.dart';

import 'push_gateway.dart';
import 'push_payload.dart';

/// The single entry point of push notifications.
///
/// - [start] starts the provider **without asking for the permission**;
/// - the device token is read **only when the permission is granted**, and
///   kept in memory ([token]) for the server registration (QB-C-021); it is
///   never logged;
/// - a tapped notification (app killed or in the background) comes out on
///   [destinations].
///
/// Whatever fails inside the provider (no network, simulator without APNs,
/// misconfiguration) leaves the app working without notifications.
class PushNotificationService {
  PushNotificationService({required PushGateway gateway}) : _gateway = gateway;

  final PushGateway _gateway;
  final _destinations = StreamController<PushDestination>.broadcast();
  final _tokenChanges = StreamController<String?>.broadcast();
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<Map<String, Object?>>? _openedSub;
  bool _started = false;
  bool _available = false;
  String? _token;

  /// Device token, in memory only; null until the permission is granted.
  String? get token => _token;

  /// Emits each time [token] changes.
  Stream<String?> get tokenChanges => _tokenChanges.stream;

  /// Where each tapped notification leads. Listen before calling [start].
  Stream<PushDestination> get destinations => _destinations.stream;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      await _gateway.initialize();
      _available = true;
    } catch (e) {
      debugPrint('[PUSH] Provider unavailable: ${e.runtimeType}');
      return;
    }
    _openedSub = _gateway.openedMessageData.listen(
      (data) => _destinations.add(parsePushPayload(data)),
      onError: (Object e) =>
          debugPrint('[PUSH] Opened message error: ${e.runtimeType}'),
    );
    _refreshSub = _gateway.tokenRefreshes.listen(
      (_) => unawaited(refreshToken()),
      onError: (Object e) =>
          debugPrint('[PUSH] Token refresh error: ${e.runtimeType}'),
    );
    await refreshToken();
    try {
      final initial = await _gateway.initialMessageData();
      if (initial != null) _destinations.add(parsePushPayload(initial));
    } catch (e) {
      debugPrint('[PUSH] Initial message error: ${e.runtimeType}');
    }
  }

  /// Reads the token if (and only if) notifications are allowed. To call
  /// again once the player has answered the permission request.
  Future<void> refreshToken() async {
    if (!_available) return;
    String? next;
    try {
      if (await _gateway.isAuthorized()) next = await _gateway.readToken();
    } catch (e) {
      debugPrint('[PUSH] Token unavailable: ${e.runtimeType}');
      return;
    }
    if (next == _token) return;
    _token = next;
    _tokenChanges.add(next);
  }

  Future<void> dispose() async {
    await _openedSub?.cancel();
    await _refreshSub?.cancel();
    await _destinations.close();
    await _tokenChanges.close();
  }
}
