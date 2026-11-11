import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/services/auth_service.dart';

const _password = 'Sup3r-Secret-Pw!';
const _identifier = 'someone@example.test';
const _accessToken = 'ACCESS-TOKEN-VALUE-123';
const _refreshToken = 'REFRESH-TOKEN-VALUE-456';

void main() {
  late List<String> logs;
  late DebugPrintCallback originalDebugPrint;
  late AuthService auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    auth = AuthService();
    await auth.initialize();
    logs = [];
    originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message ?? '');
  });

  tearDown(() => debugPrint = originalDebugPrint);

  void expectCleanLogs() {
    final all = logs.join('\n');
    expect(all, isNot(contains(_password)), reason: 'password in a log');
    expect(all, isNot(contains(_accessToken)), reason: 'access token in a log');
    expect(all, isNot(contains(_refreshToken)), reason: 'refresh token in a log');
    expect(all, isNot(contains(_identifier)), reason: 'identifier in a log');
    expect(logs, isNotEmpty, reason: 'useful traces are kept');
  }

  Future<Map<String, dynamic>> register(
    http.Response Function(http.Request) handler, {
    String? invitationCode,
  }) => http.runWithClient(
    () => auth.register(
      email: _identifier,
      username: 'someone',
      password1: _password,
      password2: _password,
      invitationCode: invitationCode,
    ),
    () => MockClient((request) async => handler(request)),
  );

  group('registration', () {
    test('invitation_code is sent only when filled in', () async {
      final bodies = <Map<String, dynamic>>[];
      http.Response ok(http.Request r) {
        bodies.add(jsonDecode(r.body) as Map<String, dynamic>);
        return http.Response('{"detail": "ok"}', 201);
      }

      await register(ok);
      await register(ok, invitationCode: '');
      await register(ok, invitationCode: 'K7P3QX');

      expect(bodies[0].containsKey('invitation_code'), isFalse);
      expect(bodies[1].containsKey('invitation_code'), isFalse);
      expect(bodies[2]['invitation_code'], 'K7P3QX');
      expect(bodies[2]['email'], _identifier, reason: 'the rest of the body is unchanged');
      expect(bodies[2]['password1'], _password);
    });

    test('no password in the journal, success or failure', () async {
      await register((r) => http.Response('{"detail": "ok"}', 201));
      await register(
        (r) => http.Response(
          '{"error": {"code": "invalid", "message": "bad", "details": {"email": ["bad"]}}}',
          400,
        ),
      );
      expectCleanLogs();
    });
  });

  group('login', () {
    Future<Map<String, dynamic>> login(http.Response Function() handler) =>
        http.runWithClient(
          () => auth.login(identifier: _identifier, password: _password),
          () => MockClient((request) async => handler()),
        );

    test('no password, token or identifier in the journal on success', () async {
      final result = await login(
        () => http.Response(
          jsonEncode({
            'access': _accessToken,
            'refresh': _refreshToken,
            'user': {'id': 1, 'username': 'someone', 'email': _identifier},
          }),
          200,
        ),
      );
      expect(result['success'], isTrue);
      expectCleanLogs();
    });

    test('and on failure', () async {
      await login(() => http.Response('{"detail": "no"}', 401));
      await login(() => http.Response('{"error": {"code": "x", "message": "m"}}', 403));
      expectCleanLogs();
    });
  });

  test('grep: no debugPrint of auth_service.dart mentions a password', () {
    final source = File('lib/services/auth_service.dart').readAsStringSync();
    final calls = RegExp(r'debugPrint\((?:[^;])*\);', dotAll: true)
        .allMatches(source)
        .map((m) => m.group(0)!)
        .toList();
    expect(calls, isNotEmpty);
    for (final call in calls) {
      expect(call.toLowerCase(), isNot(contains('password')), reason: call);
      expect(call, isNot(contains('response.body}')),
          reason: 'a response body may carry tokens: $call');
    }
  });
}
