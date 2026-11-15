import 'package:firebase_core/firebase_core.dart';
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

  // `getToken` / `onTokenRefresh` are deprecated in firebase_messaging 17 in
  // favour of `register()` / `onRegistered`, which hand out a Firebase
  // Installation ID, not the FCM registration token the server study plans to
  // use. Kept until the server contract (QB-B-025 / QB-C-021) says otherwise.
  @override
  // ignore: deprecated_member_use
  Future<String?> readToken() => _messaging.getToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Future<Map<String, Object?>?> initialMessageData() async {
    final message = await _messaging.getInitialMessage();
    return message?.data;
  }

  @override
  Stream<Map<String, Object?>> get openedMessageData =>
      FirebaseMessaging.onMessageOpenedApp.map((message) => message.data);
}
