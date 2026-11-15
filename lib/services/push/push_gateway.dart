/// Where the notification permission stands.
enum PushPermission {
  /// Allowed (also the case of Android 12 and older, which has no prompt).
  granted,

  /// Never asked: the system prompt can still be shown.
  notDetermined,

  /// Refused, or the provider is unavailable: nothing more can be asked.
  denied,
}

/// What the app needs from the push provider (Firebase Cloud Messaging).
///
/// The only implementation that loads Firebase is `FirebasePushGateway`;
/// tests use a fake, so they never load Firebase.
abstract class PushGateway {
  /// Starts the provider. Never asks for the notification permission.
  Future<void> initialize();

  /// Where the permission stands (nothing is asked here).
  Future<PushPermission> permission();

  /// Shows the system prompt (iOS; Android 13+) and returns the answer.
  Future<PushPermission> requestPermission();

  /// Registers this installation with the provider and returns its Firebase
  /// Installation ID (FID), or null when there is none (provider error, no
  /// answer in time). The FID, never the FCM registration token, is what the
  /// server gets.
  Future<String?> registerInstallation();

  /// Installation IDs handed out by the provider, each time one is.
  Stream<String> get installationIds;

  /// Data of the notification that started the app (app killed), once.
  Future<Map<String, Object?>?> initialMessageData();

  /// Data of a notification tapped while the app was in the background.
  Stream<Map<String, Object?>> get openedMessageData;
}
