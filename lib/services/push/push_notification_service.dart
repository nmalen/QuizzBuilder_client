import 'dart:async';

import 'package:flutter/foundation.dart';

import 'push_gateway.dart';
import 'push_payload.dart';

/// The single entry point of push notifications.
///
/// - [start] starts the provider **without asking for the permission**;
/// - the Firebase Installation ID (FID) is asked for **only when the
///   permission is granted**, and kept in memory ([installationId]) for the
///   server registration (`PushRegistration`); it is never logged;
/// - a tapped notification (app killed or in the background) comes out on
///   [destinations].
///
/// Whatever fails inside the provider (no network, simulator without APNs,
/// misconfiguration) leaves the app working without notifications.
class PushNotificationService {
  PushNotificationService({required PushGateway gateway}) : _gateway = gateway;

  final PushGateway _gateway;
  final _destinations = StreamController<PushDestination>.broadcast();
  final _idChanges = StreamController<String?>.broadcast();
  StreamSubscription<String>? _idSub;
  StreamSubscription<Map<String, Object?>>? _openedSub;
  bool _started = false;
  bool _available = false;
  String? _installationId;

  /// Firebase Installation ID, in memory only; null until the permission is
  /// granted and the provider has handed it over.
  String? get installationId => _installationId;

  /// Emits each time [installationId] changes.
  Stream<String?> get installationIdChanges => _idChanges.stream;

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
    _idSub = _gateway.installationIds.listen(
      (id) => unawaited(_onInstallationId(id)),
      onError: (Object e) =>
          debugPrint('[PUSH] Installation id error: ${e.runtimeType}'),
    );
    await refreshInstallationId();
    try {
      final initial = await _gateway.initialMessageData();
      if (initial != null) _destinations.add(parsePushPayload(initial));
    } catch (e) {
      debugPrint('[PUSH] Initial message error: ${e.runtimeType}');
    }
  }

  /// Asks for the installation ID if (and only if) notifications are allowed.
  /// To call again once the player has answered the permission request.
  Future<void> refreshInstallationId() async {
    if (!_available) return;
    try {
      if (await _gateway.permission() != PushPermission.granted) {
        _set(null);
        return;
      }
      // No answer (null) keeps what is already known.
      final id = await _gateway.registerInstallation();
      if (id != null) _set(id);
    } catch (e) {
      debugPrint('[PUSH] Installation id unavailable: ${e.runtimeType}');
    }
  }

  /// An ID handed out by the provider (first registration, or a change).
  Future<void> _onInstallationId(String id) async {
    try {
      if (await _gateway.permission() != PushPermission.granted) return;
    } catch (_) {
      return;
    }
    _set(id);
  }

  void _set(String? next) {
    if (next == _installationId) return;
    _installationId = next;
    _idChanges.add(next);
  }

  /// Where the permission stands; `denied` when the provider is unavailable
  /// (nothing can be asked then).
  Future<PushPermission> permission() async {
    if (!_available) return PushPermission.denied;
    try {
      return await _gateway.permission();
    } catch (e) {
      debugPrint('[PUSH] Permission unreadable: ${e.runtimeType}');
      return PushPermission.denied;
    }
  }

  /// Shows the system prompt, then asks for the installation ID if it was allowed.
  Future<PushPermission> requestPermission() async {
    if (!_available) return PushPermission.denied;
    PushPermission answer;
    try {
      answer = await _gateway.requestPermission();
    } catch (e) {
      debugPrint('[PUSH] Permission request failed: ${e.runtimeType}');
      return PushPermission.denied;
    }
    await refreshInstallationId();
    return answer;
  }

  Future<void> dispose() async {
    await _openedSub?.cancel();
    await _idSub?.cancel();
    await _destinations.close();
    await _idChanges.close();
  }
}
