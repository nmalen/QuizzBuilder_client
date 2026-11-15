import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/models/user.dart';
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/services/auth_service.dart';
import 'package:QuizzBuilder/services/push/device_registration_api.dart';
import 'package:QuizzBuilder/services/push/push_notification_service.dart';
import 'package:QuizzBuilder/services/push/push_registration.dart';

import 'support/duel_test_support.dart';
import 'support/push_test_support.dart';

/// QB-C-021: the server learns which installation (Firebase Installation ID,
/// never an FCM token) gets the signed-in account's notifications. Server and
/// Firebase are simulated; every ID here is fictional.
const _path = '/notifications/devices/';

/// A real [AuthService] (its real `getAuthHeaders`), token set by the test.
class _TokenAuth extends AuthService {
  String? token = 'test-token';

  @override
  Future<String?> getAccessToken() async => token;
}

/// Records the calls and answers what the test says.
class _RecordingApi extends DeviceRegistrationApi {
  _RecordingApi() : super(authService: FakeAuthService());

  final calls = <String>[];
  DeviceCallResult answer = DeviceCallResult.done;
  Completer<void>? hold;
  bool throwOnUnregister = false;

  @override
  Future<DeviceCallResult> register(
    String installationId,
    String platform,
  ) async {
    calls.add('POST $installationId $platform');
    await hold?.future;
    return answer;
  }

  @override
  Future<DeviceCallResult> unregister(String installationId) async {
    calls.add('DELETE $installationId');
    if (throwOnUnregister) throw StateError('boom');
    await hold?.future;
    return answer;
  }
}

/// A signed-in or signed-out account whose id the test can change.
class _Account extends AuthProvider {
  _Account({bool loggedIn = false})
    : _in = loggedIn,
      super(authService: FakeAuthService());
  bool _in;
  int id = 7;

  @override
  bool get isLoggedIn => _in;
  @override
  bool get isLoading => false;
  @override
  bool get isInitialized => true;
  @override
  User? get user => _in
      ? User(id: id, username: 'tester', email: 'tester@example.test')
      : null;

  void signIn([int? as]) {
    if (as != null) id = as;
    _in = true;
    notifyListeners();
  }

  void signOut() {
    _in = false;
    notifyListeners();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the server call', () {
    late _TokenAuth auth;
    late List<http.Request> seen;
    late http.Response Function(http.Request) answer;

    setUp(() {
      auth = _TokenAuth()..appLanguageSource = () => 'fr';
      seen = [];
      answer = (_) => http.Response('', 204);
    });

    DeviceRegistrationApi api() => DeviceRegistrationApi(
      authService: auth,
      client: MockClient((request) async {
        seen.add(request);
        return answer(request);
      }),
    );

    test(
      'POST: the FID in the "token" field, the platform, the bearer and the language',
      () async {
        final result = await api().register('fid-fictional-1', 'ios');
        expect(result, DeviceCallResult.done);
        final r = seen.single;
        expect(r.method, 'POST');
        expect(r.url.path, endsWith(_path));
        expect(jsonDecode(r.body), {
          'token': 'fid-fictional-1',
          'platform': 'ios',
        });
        expect(r.headers['Authorization'], 'Bearer test-token');
        expect(r.headers['X-App-Language'], 'fr');
      },
    );

    test('DELETE: the same FID, no platform', () async {
      expect(await api().unregister('fid-fictional-1'), DeviceCallResult.done);
      final r = seen.single;
      expect(r.method, 'DELETE');
      expect(r.url.path, endsWith(_path));
      expect(jsonDecode(r.body), {'token': 'fid-fictional-1'});
      expect(r.headers['Authorization'], 'Bearer test-token');
    });

    test(
      '429, 5xx, network failure, no answer: retry later, nothing thrown',
      () async {
        for (final status in [429, 500, 502, 503]) {
          answer = (_) =>
              http.Response('{"error":{"code":"throttled"}}', status);
          expect(
            await api().register('fid-fictional-1', 'android'),
            DeviceCallResult.retryLater,
            reason: '$status',
          );
        }
        final failing = DeviceRegistrationApi(
          authService: auth,
          client: MockClient(
            (_) async => throw const SocketException('offline'),
          ),
        );
        expect(
          await failing.register('fid-fictional-1', 'android'),
          DeviceCallResult.retryLater,
        );
        expect(
          await failing.unregister('fid-fictional-1'),
          DeviceCallResult.retryLater,
        );
      },
    );

    test('400 and 401 are not retried here', () async {
      for (final status in [400, 401]) {
        answer = (_) => http.Response('{}', status);
        expect(
          await api().register('fid-fictional-1', 'ios'),
          DeviceCallResult.notAccepted,
          reason: '$status',
        );
      }
    });

    test('signed out (no auth token): no call at all', () async {
      auth.token = null;
      expect(
        await api().register('fid-fictional-1', 'ios'),
        DeviceCallResult.notAccepted,
      );
      expect(
        await api().unregister('fid-fictional-1'),
        DeviceCallResult.notAccepted,
      );
      expect(seen, isEmpty);
    });

    test('the FID never reaches a log, whatever the answer', () async {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          logs.add(message ?? '');
      addTearDown(() => debugPrint = original);
      for (final status in [204, 400, 401, 429, 500]) {
        answer = (_) => http.Response('{}', status);
        await api().register('fid-fictional-secret-1', 'ios');
        await api().unregister('fid-fictional-secret-1');
      }
      expect(logs.join('\n'), isNot(contains('fid-fictional-secret-1')));
    });
  });

  group('when the server is told', () {
    late FakePushGateway gateway;
    late PushNotificationService push;
    late _RecordingApi api;
    late _Account account;
    late PushRegistration registration;

    Future<void> setUpAll_({
      bool authorized = true,
      bool loggedIn = true,
    }) async {
      gateway = FakePushGateway(authorized: authorized);
      push = PushNotificationService(gateway: gateway);
      api = _RecordingApi();
      account = _Account(loggedIn: loggedIn);
      registration = PushRegistration(
        push: push,
        api: api,
        platform: 'android',
        signOutTimeout: const Duration(milliseconds: 50),
      );
      registration.attach(account);
      await push.start();
      await pumpEventQueue();
      addTearDown(() async {
        registration.dispose();
        await push.dispose();
      });
    }

    final id = fakeInstallationId;

    test('signed in with an ID: one POST, with the platform', () async {
      await setUpAll_();
      expect(api.calls, ['POST $id android']);
    });

    test('signed out: no POST; at sign-in: one POST', () async {
      await setUpAll_(loggedIn: false);
      expect(api.calls, isEmpty);
      account.signIn();
      await pumpEventQueue();
      expect(api.calls, ['POST $id android']);
    });

    test(
      'without the permission there is no ID, so no POST; once allowed, one POST',
      () async {
        await setUpAll_(authorized: false);
        expect(api.calls, isEmpty);
        gateway.authorized = true;
        await push.refreshInstallationId();
        await pumpEventQueue();
        expect(api.calls, ['POST $id android']);
      },
    );

    test('a changed ID is posted; the same one is not posted twice', () async {
      await setUpAll_();
      gateway.refreshes.add('fid-changed-fictional');
      await pumpEventQueue();
      gateway.refreshes.add('fid-changed-fictional');
      await pumpEventQueue();
      expect(api.calls, [
        'POST $id android',
        'POST fid-changed-fictional android',
      ]);
    });

    test(
      'other news from the account (token refresh, resume) post nothing more',
      () async {
        await setUpAll_();
        for (var i = 0; i < 5; i++) {
          account.notifyListeners();
          await pumpEventQueue();
        }
        expect(api.calls, hasLength(1));
      },
    );

    test('another account on the same phone: posted again', () async {
      await setUpAll_();
      account.signOut();
      await pumpEventQueue();
      account.signIn(8);
      await pumpEventQueue();
      expect(api.calls, ['POST $id android', 'POST $id android']);
    });

    test(
      'a failure (429, 5xx, network) is silent and not retried until the ID or the session changes',
      () async {
        api = _RecordingApi()..answer = DeviceCallResult.retryLater;
        gateway = FakePushGateway(authorized: true);
        push = PushNotificationService(gateway: gateway);
        account = _Account(loggedIn: true);
        registration = PushRegistration(push: push, api: api, platform: 'ios')
          ..attach(account);
        addTearDown(() async {
          registration.dispose();
          await push.dispose();
        });
        await push.start();
        await pumpEventQueue();
        expect(api.calls, hasLength(1));
        for (var i = 0; i < 3; i++) {
          account.notifyListeners();
          await pumpEventQueue();
        }
        expect(api.calls, hasLength(1), reason: 'no hammering after a failure');

        gateway.refreshes.add('fid-changed-fictional');
        await pumpEventQueue();
        expect(api.calls, hasLength(2), reason: 'a new ID is tried');

        api.answer = DeviceCallResult.done;
        account.signOut();
        await pumpEventQueue();
        account.signIn();
        await pumpEventQueue();
        expect(api.calls, hasLength(3), reason: 'a new session is tried');
      },
    );

    test('a 401 is left to the session code: no retry loop', () async {
      await setUpAll_(loggedIn: false);
      api.answer = DeviceCallResult.notAccepted;
      account.signIn();
      await pumpEventQueue();
      account.notifyListeners();
      await pumpEventQueue();
      expect(api.calls, hasLength(1));
    });

    test(
      'the account changes while a call is running: the new one is posted after',
      () async {
        await setUpAll_(loggedIn: false);
        api.hold = Completer<void>();
        account.signIn(7);
        await pumpEventQueue();
        expect(api.calls, hasLength(1));
        account.signOut();
        account.signIn(9);
        final release = api.hold!;
        api.hold = null;
        release.complete();
        await pumpEventQueue();
        expect(api.calls, hasLength(2));
      },
    );

    test(
      'sign-out: DELETE of the ID, and no POST during the sign-out',
      () async {
        await setUpAll_();
        api.calls.clear();
        await registration.unregisterForSignOut();
        expect(api.calls, ['DELETE $id']);
        gateway.refreshes.add('fid-late-fictional');
        account.notifyListeners();
        await pumpEventQueue();
        expect(api.calls, [
          'DELETE $id',
        ], reason: 'nothing is posted while signing out');
        account.signOut();
        await pumpEventQueue();
        account.signIn();
        await pumpEventQueue();
        expect(
          api.calls.last,
          startsWith('POST'),
          reason: 'the next session registers again',
        );
      },
    );

    test('no ID, no DELETE', () async {
      await setUpAll_(authorized: false);
      await registration.unregisterForSignOut();
      expect(api.calls, isEmpty);
    });

    test(
      'a failing or never-answering removal does not hold the sign-out',
      () async {
        await setUpAll_();
        api.throwOnUnregister = true;
        await registration.unregisterForSignOut();
        api.throwOnUnregister = false;
        api.hold = Completer<void>();
        final watch = Stopwatch()..start();
        await registration.unregisterForSignOut();
        expect(watch.elapsedMilliseconds, lessThan(2000));
      },
    );
  });

  group('AuthProvider.logout', () {
    test(
      'the removal runs BEFORE the auth token is erased (else 401)',
      () async {
        final events = <String>[];
        final service = _OrderService(events);
        final provider = AuthProvider(authService: service)
          ..beforeLogout = () async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            events.add('delete-from-server');
          };
        await provider.logout();
        expect(events, ['delete-from-server', 'erase-token']);
        expect(provider.isLoggedIn, isFalse);
      },
    );

    test('a failing hook never prevents the sign-out', () async {
      final events = <String>[];
      final provider = AuthProvider(authService: _OrderService(events))
        ..beforeLogout = () async => throw StateError('server down');
      await provider.logout();
      expect(events, ['erase-token']);
      expect(provider.isLoggedIn, isFalse);
    });

    test('without a hook: as before', () async {
      final events = <String>[];
      await AuthProvider(authService: _OrderService(events)).logout();
      expect(events, ['erase-token']);
    });
  });

  group('no FCM token path left', () {
    test('lib/ has no getToken / onTokenRefresh / deprecated_member_use', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final text = entity.readAsStringSync();
        for (final word in [
          'getToken',
          'onTokenRefresh',
          'deprecated_member_use',
        ]) {
          if (text.contains(word)) offenders.add('${entity.path}: $word');
        }
      }
      expect(offenders, isEmpty);
    });
  });
}

class _OrderService extends AuthService {
  _OrderService(this.events);
  final List<String> events;

  @override
  Future<void> logout() async => events.add('erase-token');
}
