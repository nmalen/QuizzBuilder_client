import 'dart:async';

import 'push_gateway.dart';
import 'push_log.dart';
import 'push_payload.dart';

/// The single entry point of push notifications.
///
/// - [start] starts the provider **without asking for the permission**;
/// - the Firebase Installation ID (FID) is asked for **only when the
///   permission is granted**, and kept in memory ([installationId]) for the
///   server registration (`PushRegistration`); it is never logged;
/// - an ID the provider hands out **before** the permission is granted is kept
///   in memory and used once it is (the provider may not hand it out again);
/// - a tapped notification (app killed or in the background) comes out on
///   [destinations]; one received while the app is open comes out on
///   [foregroundMessages].
///
/// Whatever fails inside the provider (no network, simulator without APNs,
/// misconfiguration) leaves the app working without notifications.
class PushNotificationService {
  PushNotificationService({required PushGateway gateway}) : _gateway = gateway;

  final PushGateway _gateway;
  final _destinations = StreamController<PushDestination>.broadcast();
  final _idChanges = StreamController<String?>.broadcast();
  final _foreground = StreamController<PushMessage>.broadcast();
  StreamSubscription<String>? _idSub;
  StreamSubscription<Map<String, Object?>>? _openedSub;
  StreamSubscription<PushMessage>? _foregroundSub;
  bool _started = false;
  bool _available = false;
  String? _installationId;

  /// The last ID the provider handed out, whatever the permission was then.
  /// Memory only, never logged.
  String? _lastHandedOutId;

  /// Firebase Installation ID, in memory only; null until the permission is
  /// granted and the provider has handed it over.
  String? get installationId => _installationId;

  /// Emits each time [installationId] changes.
  Stream<String?> get installationIdChanges => _idChanges.stream;

  /// Where each tapped notification leads. Listen before calling [start].
  Stream<PushDestination> get destinations => _destinations.stream;

  /// Notifications received while the app is open. Listen before [start].
  Stream<PushMessage> get foregroundMessages => _foreground.stream;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      await _gateway.initialize();
      _available = true;
    } catch (e) {
      pushLog('Provider unavailable: ${e.runtimeType}');
      return;
    }
    pushLog('Provider started');
    _openedSub = _gateway.openedMessageData.listen(
      (data) => _destinations.add(parsePushPayload(data)),
      onError: (Object e) => pushLog('Opened message error: ${e.runtimeType}'),
    );
    _foregroundSub = _gateway.foregroundMessages.listen(
      _foreground.add,
      onError: (Object e) =>
          pushLog('Foreground message error: ${e.runtimeType}'),
    );
    _idSub = _gateway.installationIds.listen(
      (id) => unawaited(_onInstallationId(id)),
      onError: (Object e) => pushLog('Installation id error: ${e.runtimeType}'),
    );
    // The notification that started the app first: asking for the ID can wait
    // for the provider (up to its timeout) and must not delay the opening.
    try {
      final initial = await _gateway.initialMessageData();
      if (initial != null) _destinations.add(parsePushPayload(initial));
    } catch (e) {
      pushLog('Initial message error: ${e.runtimeType}');
    }
    await refreshInstallationId();
  }

  /// Asks for the installation ID if (and only if) notifications are allowed.
  /// To call again once the player has answered the permission request.
  Future<void> refreshInstallationId() async {
    if (!_available) return;
    try {
      final permission = await _gateway.permission();
      pushLog('Permission: ${permission.name}');
      if (permission != PushPermission.granted) {
        _set(null);
        return;
      }
      final handed = await _gateway.registerInstallation();
      // The provider may not hand the ID out again for an installation it
      // already registered: fall back on the one it handed out earlier.
      final id = handed ?? _lastHandedOutId;
      pushLog(
        'Installation ID: ${id != null ? 'yes' : 'no'}'
        '${handed == null && id != null ? ' (handed out earlier)' : ''}',
      );
      // No ID at all keeps what is already known.
      if (id != null) _set(id);
    } catch (e) {
      pushLog('Installation id unavailable: ${e.runtimeType}');
    }
  }

  /// An ID handed out by the provider (first registration, or a change).
  Future<void> _onInstallationId(String id) async {
    _lastHandedOutId = id;
    try {
      final permission = await _gateway.permission();
      if (permission != PushPermission.granted) {
        pushLog('Installation ID handed out, permission ${permission.name}: '
            'kept for later');
        return;
      }
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
      pushLog('Permission unreadable: ${e.runtimeType}');
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
      pushLog('Permission request failed: ${e.runtimeType}');
      return PushPermission.denied;
    }
    pushLog('System prompt answered: ${answer.name}');
    await refreshInstallationId();
    return answer;
  }

  Future<void> dispose() async {
    await _openedSub?.cancel();
    await _idSub?.cancel();
    await _foregroundSub?.cancel();
    await _foreground.close();
    await _destinations.close();
    await _idChanges.close();
  }
}
