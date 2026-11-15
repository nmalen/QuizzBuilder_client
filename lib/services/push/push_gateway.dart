/// What the app needs from the push provider (Firebase Cloud Messaging).
///
/// The only implementation that loads Firebase is `FirebasePushGateway`;
/// tests use a fake, so they never load Firebase.
abstract class PushGateway {
  /// Starts the provider. Never asks for the notification permission.
  Future<void> initialize();

  /// The player allowed notifications (nothing is asked here).
  Future<bool> isAuthorized();

  /// The device token, or null when there is none yet.
  Future<String?> readToken();

  /// New device tokens, after a renewal.
  Stream<String> get tokenRefreshes;

  /// Data of the notification that started the app (app killed), once.
  Future<Map<String, Object?>?> initialMessageData();

  /// Data of a notification tapped while the app was in the background.
  Stream<Map<String, Object?>> get openedMessageData;
}
