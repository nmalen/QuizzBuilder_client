import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_gateway.dart';
import 'push_log.dart';

/// [PushGateway] on Firebase Cloud Messaging. The only file that loads it.
class FirebasePushGateway implements PushGateway {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  @override
  Future<PushPermission> permission() async =>
      _map((await _messaging.getNotificationSettings()).authorizationStatus);

  @override
  Future<PushPermission> requestPermission() async =>
      _map((await _messaging.requestPermission()).authorizationStatus);

  PushPermission _map(AuthorizationStatus status) => switch (status) {
    AuthorizationStatus.authorized ||
    AuthorizationStatus.provisional => PushPermission.granted,
    AuthorizationStatus.notDetermined => PushPermission.notDetermined,
    AuthorizationStatus.denied ||
    AuthorizationStatus.deniedPermanently => PushPermission.denied,
  };

  /// How long to wait for the provider to hand the FID over after `register()`.
  static const Duration _registrationTimeout = Duration(seconds: 15);

  @override
  Stream<String> get installationIds => _messaging.onRegistered;

  @override
  Future<String?> registerInstallation() async {
    // Listen before asking: the FID comes out of `onRegistered`, not out of
    // `register()` itself. Any failure reads as "no FID" (only the kind of
    // failure is logged, never a value).
    final handedOver = _messaging.onRegistered.first
        .timeout(_registrationTimeout)
        .then<String?>(
          (fid) => fid,
          onError: (Object e) {
            pushLog('No installation ID handed over: ${e.runtimeType}');
            return null;
          },
        );
    pushLog('register() called');
    try {
      await _messaging.register();
    } catch (e) {
      final firebase = e is FirebaseException ? e : null;
      final why = describeNativeFailure(
        e.runtimeType.toString(),
        code: firebase?.code,
        message: firebase?.message,
      );
      pushLog('register() failed: $why');
      return null;
    }
    pushLog('register() returned');
    return handedOver;
  }

  @override
  Future<Map<String, Object?>?> initialMessageData() async {
    final message = await _messaging.getInitialMessage();
    return message?.data;
  }

  @override
  Stream<Map<String, Object?>> get openedMessageData =>
      FirebaseMessaging.onMessageOpenedApp.map((message) => message.data);

  @override
  Stream<PushMessage> get foregroundMessages => FirebaseMessaging.onMessage.map(
    (message) => PushMessage(
      data: message.data,
      title: message.notification?.title,
      body: message.notification?.body,
    ),
  );
}
