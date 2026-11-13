import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/l10n/app_localizations_fr.dart';
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/invitation_link_provider.dart';
import 'package:QuizzBuilder/providers/language_provider.dart';
import 'package:QuizzBuilder/services/auth_service.dart';
import 'package:QuizzBuilder/ui/auth_screen.dart';
import 'package:QuizzBuilder/utils/register_throttle_message.dart';

/// Sign-up refused by the rate limit (HTTP 429): what the service hands over,
/// and the message the player reads.
final _en = AppLocalizationsEn();
final _fr = AppLocalizationsFr();

/// The server's English text is a trap: it must never reach the player.
const _serverText = 'Request was throttled. Expected available in 3500 seconds.';

String _body429({Object? details}) => jsonEncode({
  'error': {
    'code': 'throttled',
    'message': _serverText,
    'status_code': 429,
    if (details != null) 'details': details,
  },
});

Future<Map<String, dynamic>> _register(http.Response Function() answer) =>
    http.runWithClient(
      () => AuthService().register(
        email: 'a@b.co',
        username: 'abcd',
        password1: '12345678',
        password2: '12345678',
      ),
      () => MockClient((request) async => answer()),
    );

class _StubService extends AuthService {
  _StubService(this.result);
  final Map<String, dynamic> result;

  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password1,
    required String password2,
    String? invitationCode,
  }) async => result;
}

Map<String, dynamic> _refused({int status = 429, Object? retryAfter}) => {
  'success': false,
  'message': _serverText,
  'status_code': status,
  if (status == 429) 'retry_after_seconds': retryAfter,
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the service hands over the 429', () {
    test('status and the announced wait, from details.retry_after_seconds', () async {
      final result = await _register(
        () => http.Response(_body429(details: {'retry_after_seconds': 3500}), 429),
      );
      expect(result['success'], isFalse);
      expect(result['status_code'], 429);
      expect(result['retry_after_seconds'], 3500);
    });

    test('field missing, details missing or not a whole number: null, never read from the text', () async {
      for (final body in [
        _body429(),
        _body429(details: <String, Object?>{}),
        _body429(details: {'retry_after_seconds': '3500'}),
        _body429(details: {'retry_after_seconds': 12.5}),
        _body429(details: ['retry_after_seconds']),
      ]) {
        final result = await _register(() => http.Response(body, 429));
        expect(result['status_code'], 429);
        expect(result['retry_after_seconds'], isNull, reason: body);
      }
    });

    test('a 400 carries its status and no wait', () async {
      final result = await _register(
        () => http.Response(
          jsonEncode({
            'error': {
              'code': 'invalid',
              'message': 'bad',
              'details': {'email': ['bad']},
            },
          }),
          400,
        ),
      );
      expect(result['status_code'], 400);
      expect(result.containsKey('retry_after_seconds'), isFalse);
    });

    test('a 201 is unchanged', () async {
      final result = await _register(() => http.Response('{"detail": "ok"}', 201));
      expect(result['success'], isTrue);
      expect(result.containsKey('status_code'), isFalse);
    });
  });

  group('the provider', () {
    test('keeps the 429 and the wait, and forgets them on the next outcome', () async {
      final provider = AuthProvider(
        authService: _StubService(_refused(retryAfter: 600)),
      );
      await provider.register(
        email: 'a@b.co',
        username: 'abcd',
        password1: '12345678',
        password2: '12345678',
      );
      expect(provider.registerThrottled, isTrue);
      expect(provider.registerRetryAfterSeconds, 600);

      final other = AuthProvider(authService: _StubService(_refused(status: 400)));
      await other.register(
        email: 'a@b.co',
        username: 'abcd',
        password1: '12345678',
        password2: '12345678',
      );
      expect(other.registerThrottled, isFalse);
      expect(other.registerRetryAfterSeconds, isNull);
    });
  });

  group('the message', () {
    final cases = <(int?, String Function(AppLocalizations))>[
      (1, (l) => l.registerThrottledWaitShort),
      (60, (l) => l.registerThrottledWaitShort),
      (61, (l) => l.registerThrottledWait(2)),
      (120, (l) => l.registerThrottledWait(2)),
      (121, (l) => l.registerThrottledWait(3)),
      (3500, (l) => l.registerThrottledWait(59)),
      (3600, (l) => l.registerThrottledWait(60)),
      // Absurd or absent: the vague wait.
      (null, (l) => l.registerThrottledWaitUnknown),
      (0, (l) => l.registerThrottledWaitUnknown),
      (-5, (l) => l.registerThrottledWaitUnknown),
      (3601, (l) => l.registerThrottledWaitUnknown),
      (99999999, (l) => l.registerThrottledWaitUnknown),
    ];
    for (final l in [_en, _fr]) {
      for (final (seconds, wait) in cases) {
        test('${l.localeName}: $seconds s', () {
          expect(
            registerThrottledText(l, seconds),
            l.registerThrottledMessage(wait(l)),
          );
        });
      }
    }

    test('wording, as validated', () {
      expect(
        registerThrottledText(_en, 3500),
        'Many sign-ups are coming from this connection right now. Try again in about 59 minutes.',
      );
      expect(
        registerThrottledText(_fr, 3500),
        "Beaucoup d'inscriptions viennent de cette connexion en ce moment. Réessaie dans environ 59 minutes.",
      );
      expect(registerThrottledText(_fr, 30), contains("moins d'une minute"));
      expect(registerThrottledText(_fr, null), contains('dans un moment'));
      expect(_en.registerThrottledWait(1), 'Try again in about 1 minute.');
      expect(_fr.registerThrottledWait(1), 'Réessaie dans environ 1 minute.');
    });
  });

  group('on the sign-up screen', () {
    Future<void> pumpScreen(
      WidgetTester tester,
      AuthProvider auth,
      String locale,
    ) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<InvitationLinkProvider>.value(
              value: InvitationLinkProvider(),
            ),
            ChangeNotifierProvider<LanguageProvider>.value(
              value: LanguageProvider(),
            ),
          ],
          child: MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AuthScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<String> refusedMessage(
      WidgetTester tester,
      String locale,
      Map<String, dynamic> result,
    ) async {
      final l = locale == 'fr' ? _fr : _en;
      await pumpScreen(tester, AuthProvider(authService: _StubService(result)), locale);
      await tester.tap(find.text(l.register));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, l.email), 'a@b.co');
      await tester.enterText(find.widgetWithText(TextFormField, l.username), 'abcd');
      await tester.enterText(find.widgetWithText(TextFormField, l.password), '12345678');
      await tester.enterText(find.widgetWithText(TextFormField, l.confirmPassword), '12345678');
      await tester.tap(find.widgetWithText(ElevatedButton, l.register));
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      final texts = find.descendant(of: dialog, matching: find.byType(Text));
      return [
        for (final t in tester.widgetList<Text>(texts)) t.data ?? '',
      ].join('\n');
    }

    for (final locale in ['en', 'fr']) {
      final l = locale == 'fr' ? _fr : _en;
      testWidgets('$locale: with the field, in minutes, never the server text', (tester) async {
        final shown = await refusedMessage(tester, locale, _refused(retryAfter: 3500));
        expect(shown, contains(registerThrottledText(l, 3500)));
        expect(shown, isNot(contains('throttled')));
        expect(shown, isNot(contains('Expected available')));
      });

      testWidgets('$locale: without the field, the vague wait', (tester) async {
        final shown = await refusedMessage(tester, locale, _refused(retryAfter: null));
        expect(shown, contains(registerThrottledText(l, null)));
        expect(shown, isNot(contains('throttled')));
      });

      testWidgets('$locale: an absurd value, the vague wait', (tester) async {
        final shown = await refusedMessage(tester, locale, _refused(retryAfter: 86400));
        expect(shown, contains(registerThrottledText(l, null)));
      });
    }

    testWidgets('another refusal keeps its own message', (tester) async {
      final shown = await refusedMessage(tester, 'en', {
        'success': false,
        'message': 'This username is already taken.',
        'status_code': 400,
      });
      expect(shown, contains('This username is already taken.'));
      expect(shown, isNot(contains('sign-ups')));
    });
  });
}
