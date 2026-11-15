import 'dart:async';

import 'package:QuizzBuilder/services/push/push_gateway.dart';

/// A fake device token: tests check it never reaches a log.
const String fakeDeviceToken = 'fake-device-token-must-never-be-logged';

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
  int tokenReads = 0;
  int initCalls = 0;
  int requestCalls = 0;
  final refreshes = StreamController<String>.broadcast();
  final opened = StreamController<Map<String, Object?>>.broadcast();

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

  @override
  Future<String?> readToken() async {
    tokenReads++;
    return fakeDeviceToken;
  }

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;

  @override
  Future<Map<String, Object?>?> initialMessageData() async => initial;

  @override
  Stream<Map<String, Object?>> get openedMessageData => opened.stream;
}
