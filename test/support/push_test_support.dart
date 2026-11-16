import 'dart:async';

import 'package:QuizzBuilder/services/push/push_gateway.dart';

/// A fictional Firebase Installation ID: tests check it never reaches a log.
const String fakeInstallationId = 'fid-fictional-must-never-be-logged';

/// A [PushGateway] with no Firebase: the permission, the answer to the system
/// prompt and the notifications are scripted by the test.
class FakePushGateway implements PushGateway {
  FakePushGateway({
    bool authorized = false,
    PushPermission? permission,
    this.requestAnswer = PushPermission.granted,
    this.failInit = false,
    this.initial,
  }) : state =
           permission ??
           (authorized ? PushPermission.granted : PushPermission.notDetermined);

  /// Where the permission stands now.
  PushPermission state;

  /// What the player answers to the system prompt.
  PushPermission requestAnswer;
  bool failInit;
  Map<String, Object?>? initial;
  int registerCalls = 0;
  int initCalls = 0;
  int requestCalls = 0;
  final refreshes = StreamController<String>.broadcast();
  final opened = StreamController<Map<String, Object?>>.broadcast();
  final foreground = StreamController<PushMessage>.broadcast();

  set authorized(bool value) =>
      state = value ? PushPermission.granted : PushPermission.notDetermined;

  @override
  Future<void> initialize() async {
    initCalls++;
    if (failInit) throw StateError('no firebase here');
  }

  @override
  Future<PushPermission> permission() async => state;

  @override
  Future<PushPermission> requestPermission() async {
    requestCalls++;
    state = requestAnswer;
    return requestAnswer;
  }

  /// What `registerInstallation()` answers (null: no FID, the provider failed).
  String? installationId = fakeInstallationId;

  /// When set, `registerInstallation()` waits for it (the provider is slow).
  Completer<void>? registerGate;

  @override
  Future<String?> registerInstallation() async {
    registerCalls++;
    await registerGate?.future;
    return installationId;
  }

  @override
  Stream<String> get installationIds => refreshes.stream;

  @override
  Future<Map<String, Object?>?> initialMessageData() async => initial;

  @override
  Stream<Map<String, Object?>> get openedMessageData => opened.stream;

  @override
  Stream<PushMessage> get foregroundMessages => foreground.stream;
}
