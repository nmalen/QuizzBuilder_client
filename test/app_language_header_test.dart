import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/providers/language_provider.dart';
import 'package:QuizzBuilder/services/auth_service.dart';
import 'package:QuizzBuilder/services/catalog_service.dart';
import 'package:QuizzBuilder/services/credit_store_service.dart';
import 'package:QuizzBuilder/services/daily_challenge_service.dart';
import 'package:QuizzBuilder/services/duel_service.dart';

/// QB-C-019: every authenticated call carries `X-App-Language` (exact
/// lowercase `fr` or `en`, the language chosen in the app); calls without a
/// token carry nothing.
const _header = 'X-App-Language';

/// A real [AuthService] (its real `getAuthHeaders`) with the token set by
/// the test instead of the secure storage.
class _TokenAuth extends AuthService {
  String? token = 'test-token';

  @override
  Future<String?> getAccessToken() async => token;

  @override
  Future<String?> getRefreshToken() async => 'test-refresh';

  @override
  Future<bool> refreshAccessToken() async => false;
}

/// Same, but with the real `refreshAccessToken` (storage replaced).
class _RefreshingAuth extends AuthService {
  @override
  Future<String?> getRefreshToken() async => 'test-refresh';

  @override
  Future<void> logout() async {}
}

void main() {
  late _TokenAuth auth;
  late LanguageProvider language;
  late List<http.Request> seen;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language_code': 'en'});
    language = LanguageProvider();
    await language.initialize();
    auth = _TokenAuth()..appLanguageSource = () => language.languageCode;
    seen = [];
  });

  /// Runs [body] against a fake server that records every request.
  Future<T> serve<T>(Future<T> Function() body, {String json = '[]'}) {
    final client = MockClient((request) async {
      seen.add(request);
      return http.Response(json, 200, headers: {'content-type': 'application/json'});
    });
    return http.runWithClient(body, () => client);
  }

  Future<void> swallow(Future<Object?> Function() call) async {
    try {
      await call();
    } catch (_) {
      // The payload is not what matters here, the request headers are.
    }
  }

  /// One authenticated call of each service (GET and POST where they exist).
  final calls = <String, Future<void> Function()>{
    'catalog GET': () => swallow(() => CatalogService(authService: auth).getCategories()),
    'catalog POST': () => swallow(() => CatalogService(authService: auth).reportQuestionError(1)),
    'daily GET': () => swallow(() => DailyChallengeService(authService: auth).getStatus()),
    'daily POST': () => swallow(
      () => DailyChallengeService(authService: auth).complete(answers: [1, 2]),
    ),
    'store GET': () => swallow(() => CreditStoreService(authService: auth).getCreditPacks()),
    'store POST': () => swallow(() => CreditStoreService(authService: auth).unlockThemeWithCredit(1)),
    'account deletion POST': () => swallow(() => auth.requestAccountDeletion()),
  };

  for (final lang in ['fr', 'en']) {
    for (final entry in calls.entries) {
      test('[$lang] ${entry.key} carries $_header: $lang', () async {
        await language.setLanguage(lang);
        await serve(entry.value);
        expect(seen, isNotEmpty);
        for (final r in seen) {
          expect(r.headers[_header], lang, reason: '${r.method} ${r.url.path}');
          expect(r.headers['Authorization'], 'Bearer test-token');
        }
      });
    }

    test('[$lang] duel call carries $_header: $lang', () async {
      await language.setLanguage(lang);
      final client = MockClient((request) async {
        seen.add(request);
        return http.Response('{"results": []}', 200, headers: {'content-type': 'application/json'});
      });
      await swallow(() => DuelService(authService: auth, client: client).listInvitations());
      expect(seen, hasLength(1));
      expect(seen.single.headers[_header], lang);
    });
  }

  test('a language change in the settings is sent with the very next call', () async {
    final service = CatalogService(authService: auth);
    await language.setLanguage('en');
    await serve(() => swallow(service.getCategories));
    await language.setLanguage('fr');
    await serve(() => swallow(service.getCategories));
    await language.setLanguage('en');
    await serve(() => swallow(service.getCategories));
    expect(seen.map((r) => r.headers[_header]), ['en', 'fr', 'en']);
  });

  test('no token: no header on the headers of a signed-out player', () async {
    auth.token = null;
    final headers = await auth.getAuthHeaders();
    expect(headers.containsKey(_header), isFalse);
    expect(headers.containsKey('Authorization'), isFalse);
  });

  test('calls without a token (login, registration, password reset, refresh) carry no header', () async {
    final real = AuthService()..appLanguageSource = () => 'fr';
    await serve(() async {
      await swallow(() => real.login(identifier: 'someone', password: 'secret-for-test'));
      await swallow(
        () => real.register(
          email: 'a@b.co',
          username: 'abcd',
          password1: '12345678',
          password2: '12345678',
        ),
      );
      await swallow(() => real.requestPasswordReset(email: 'a@b.co'));
    }, json: jsonEncode({'detail': 'ok'}));
    expect(seen, hasLength(3));
    for (final r in seen) {
      expect(r.headers.containsKey(_header), isFalse, reason: r.url.path);
    }
  });

  test('the token refresh call carries no header either', () async {
    final refreshing = _RefreshingAuth()..appLanguageSource = () => 'fr';
    final client = MockClient((request) async {
      seen.add(request);
      return http.Response('{}', 401);
    });
    await http.runWithClient(refreshing.refreshAccessToken, () => client);
    expect(seen, hasLength(1));
    expect(seen.single.url.path, endsWith('/auth/refresh/'));
    expect(seen.single.headers.containsKey(_header), isFalse);
  });

  test('a value other than fr or en is never sent', () async {
    for (final bad in ['FR', 'fr-FR', '', 'de']) {
      auth.appLanguageSource = () => bad;
      expect((await auth.getAuthHeaders()).containsKey(_header), isFalse, reason: '"$bad"');
    }
  });

  test('without a language source nothing is sent', () async {
    auth.appLanguageSource = null;
    expect((await auth.getAuthHeaders()).containsKey(_header), isFalse);
  });
}
