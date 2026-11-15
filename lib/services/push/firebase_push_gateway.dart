import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_gateway.dart';

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
            debugPrint(
              '[PUSH] No installation ID handed over: ${e.runtimeType}',
            );
            return null;
          },
        );
    try {
      await _messaging.register();
    } catch (e) {
      debugPrint('[PUSH] register() failed: ${e.runtimeType}');
      return null;
    }
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
}
