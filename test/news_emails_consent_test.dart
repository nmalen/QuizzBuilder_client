import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/l10n/app_localizations_fr.dart';
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/connectivity_provider.dart';
import 'package:QuizzBuilder/providers/invitation_link_provider.dart';
import 'package:QuizzBuilder/providers/language_provider.dart';
import 'package:QuizzBuilder/services/auth_service.dart';
import 'package:QuizzBuilder/ui/auth_screen.dart';
import 'package:QuizzBuilder/ui/settings_screen.dart';

import 'support/duel_test_support.dart';

/// QB-C-027: explicit, optional consent to news e-mails. A box at sign-up
/// (unticked, separate from the policy) and the same choice in the settings,
/// plus a link to the privacy policy.
final _en = AppLocalizationsEn();
final _fr = AppLocalizationsFr();

const _optInKey = Key('newsEmailsOptIn');
const _switchKey = Key('newsEmailsSwitch');

// ---------------------------------------------------------------------------
// Sign-up screen
// ---------------------------------------------------------------------------

/// AuthService whose registration waits for the test, and records what the
/// screen asked for.
class _GatedService extends AuthService {
  final gate = Completer<Map<String, dynamic>>();
  final optIns = <bool>[];

  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password1,
    required String password2,
    String? invitationCode,
    bool newsEmailsOptIn = false,
  }) {
    optIns.add(newsEmailsOptIn);
    return gate.future;
  }
}

/// The app router in miniature (`_AppRouter` in `main.dart`): while the
/// provider is loading, the splash replaces the sign-in screen, so the screen
/// is torn down and rebuilt around every call.
class _MiniRouter extends StatelessWidget {
  const _MiniRouter();

  @override
  Widget build(BuildContext context) => Consumer<AuthProvider>(
    builder: (context, auth, _) => auth.isLoading
        ? const Scaffold(body: Center(child: Text('splash')))
        : const AuthScreen(),
  );
}

Widget _authApp(
  AuthProvider auth, {
  String locale = 'en',
  Widget home = const AuthScreen(),
  InvitationLinkProvider? links,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>.value(value: auth),
    ChangeNotifierProvider<InvitationLinkProvider>.value(
      value: links ?? InvitationLinkProvider(),
    ),
    ChangeNotifierProvider<LanguageProvider>.value(value: LanguageProvider()),
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
    home: home,
  ),
);

Future<void> _pumpAuth(
  WidgetTester tester,
  AuthProvider auth, {
  String locale = 'en',
  Widget home = const AuthScreen(),
  Size size = const Size(1000, 2600),
  InvitationLinkProvider? links,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _authApp(auth, locale: locale, home: home, links: links),
  );
  await tester.pumpAndSettle();
}

Future<void> _toRegister(WidgetTester tester, AppLocalizations l) async {
  await tester.tap(find.text(l.register));
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, AppLocalizations l) async {
  await tester.enterText(find.widgetWithText(TextFormField, l.email), 'a@b.co');
  await tester.enterText(find.widgetWithText(TextFormField, l.username), 'abcd');
  await tester.enterText(
    find.widgetWithText(TextFormField, l.password),
    '12345678',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, l.confirmPassword),
    '12345678',
  );
}

bool _ticked(WidgetTester tester) =>
    tester.widget<Checkbox>(find.byKey(_optInKey)).value!;

// ---------------------------------------------------------------------------
// Settings screen
// ---------------------------------------------------------------------------

Future<void> _pumpSettings(
  WidgetTester tester, {
  String locale = 'en',
  FakeConnectivity? connectivity,
  Size size = const Size(393, 852),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: FakeAuthProvider()),
        ChangeNotifierProvider<ConnectivityProvider>.value(
          value: connectivity ?? FakeConnectivity(),
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
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Runs [body] with every HTTP call going to [server].
Future<void> _withServer(
  FakeDuelServer server,
  Future<void> Function() body,
) => http.runWithClient(body, () => server.client);

http.Response _user({required bool enabled}) =>
    jsonResponse(200, {'id': 7, 'username': 'tester', 'news_emails_enabled': enabled});

bool _switchOn(WidgetTester tester) =>
    tester.widget<SwitchListTile>(find.byKey(_switchKey)).value;

bool _switchEnabled(WidgetTester tester) =>
    tester.widget<SwitchListTile>(find.byKey(_switchKey)).onChanged != null;

List<RecordedRequest> _patches(FakeDuelServer s) =>
    s.requests.where((r) => r.method == 'PATCH').toList();

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  // -------------------------------------------------------------------------
  group('API contract (service)', () {
    late AuthService service;
    late FakeDuelServer server;

    setUp(() async {
      service = FakeAuthService();
      server = FakeDuelServer((_) => _user(enabled: true));
    });

    Future<Map<String, dynamic>> register({bool? optIn}) => http.runWithClient(
      () => AuthService().register(
        email: 'a@b.co',
        username: 'abcd',
        password1: '12345678',
        password2: '12345678',
        newsEmailsOptIn: optIn ?? false,
      ),
      () => server.client,
    );

    test('registration sends news_emails_opt_in: false when unticked', () async {
      server.handler = (_) => jsonResponse(201, {'detail': 'ok'});
      await register();
      final body = jsonDecode(server.requests.single.body) as Map;
      expect(body['news_emails_opt_in'], false);
    });

    test('registration sends news_emails_opt_in: true when ticked', () async {
      server.handler = (_) => jsonResponse(201, {'detail': 'ok'});
      await register(optIn: true);
      final body = jsonDecode(server.requests.single.body) as Map;
      expect(body['news_emails_opt_in'], true);
    });

    test('the GET reads news_emails_enabled', () async {
      late Map<String, dynamic> result;
      await _withServer(server, () async {
        result = await service.fetchNewsEmailsEnabled();
      });
      expect(result, containsPair('success', true));
      expect(result, containsPair('enabled', true));
      expect(server.requests.single.method, 'GET');
      expect(server.requests.single.path, endsWith('/auth/user/'));
    });

    test('the PATCH carries news_emails_enabled and nothing else', () async {
      late Map<String, dynamic> result;
      await _withServer(server, () async {
        result = await service.setNewsEmailsEnabled(false);
      });
      expect(server.requests.single.method, 'PATCH');
      expect(server.requests.single.path, endsWith('/auth/user/'));
      expect(jsonDecode(server.requests.single.body), {
        'news_emails_enabled': false,
      });
      expect(result['success'], true);
    });

    test('a 400, a missing field or a non-boolean is a failure', () async {
      for (final answer in [
        errorResponse(400, 'invalid'),
        jsonResponse(200, {'id': 7}),
        jsonResponse(200, {'news_emails_enabled': 'yes'}),
        jsonResponse(200, {'news_emails_enabled': null}),
      ]) {
        server.handler = (_) => answer;
        late Map<String, dynamic> result;
        await _withServer(server, () async {
          result = await service.setNewsEmailsEnabled(true);
        });
        expect(result['success'], false, reason: answer.body);
      }
    });

    test('a network error is a failure, not an exception', () async {
      late Map<String, dynamic> result;
      await http.runWithClient(() async {
        result = await service.fetchNewsEmailsEnabled();
      }, () => MockClient((_) async => throw http.ClientException('down')));
      expect(result['success'], false);
    });
  });

  // -------------------------------------------------------------------------
  group('sign-up: the consent box', () {
    for (final locale in ['fr', 'en']) {
      final l = locale == 'fr' ? _fr : _en;

      testWidgets('[$locale] the label is the validated text, sign-up only', (
        tester,
      ) async {
        await _pumpAuth(tester, AuthProvider(authService: _GatedService()),
            locale: locale);
        expect(find.byKey(_optInKey), findsNothing, reason: 'not on sign-in');
        await _toRegister(tester, l);
        expect(find.byKey(_optInKey), findsOneWidget);
        expect(find.text(l.newsEmailsOptInLabel), findsOneWidget);
      });
    }

    test('the two labels', () {
      expect(
        _fr.newsEmailsOptInLabel,
        'Je souhaite recevoir par e-mail les nouveautés de QuizzBuilder '
        '(nouvelles fonctions, nouveaux thèmes). Désinscription possible à '
        'tout moment.',
      );
      expect(
        _en.newsEmailsOptInLabel,
        "Email me what's new in QuizzBuilder (new features, new themes). "
        'You can unsubscribe at any time.',
      );
    });

    testWidgets('unticked by default', (tester) async {
      await _pumpAuth(tester, AuthProvider(authService: _GatedService()));
      await _toRegister(tester, _en);
      expect(_ticked(tester), isFalse);
    });

    testWidgets('opened straight in sign-up mode (invitation link): unticked', (
      tester,
    ) async {
      final links = InvitationLinkProvider()..setPendingCode('k7p3qx');
      await _pumpAuth(
        tester,
        AuthProvider(authService: _GatedService()),
        links: links,
      );
      expect(find.byKey(_optInKey), findsOneWidget);
      expect(_ticked(tester), isFalse);
    });

    testWidgets('left unticked: the field is sent, at false', (tester) async {
      final service = _GatedService();
      await _pumpAuth(tester, AuthProvider(authService: service));
      await _toRegister(tester, _en);
      await _fill(tester, _en);
      await tester.tap(find.widgetWithText(ElevatedButton, _en.register));
      await tester.pump();
      expect(service.optIns, [false]);
    });

    testWidgets('ticked: the field is sent, at true', (tester) async {
      final service = _GatedService();
      await _pumpAuth(tester, AuthProvider(authService: service));
      await _toRegister(tester, _en);
      await _fill(tester, _en);
      await tester.tap(find.byKey(_optInKey));
      await tester.pump();
      expect(_ticked(tester), isTrue);
      await tester.tap(find.widgetWithText(ElevatedButton, _en.register));
      await tester.pump();
      expect(service.optIns, [true]);
    });

    testWidgets('ticked, then switching to sign-in and back: unticked again', (
      tester,
    ) async {
      await _pumpAuth(tester, AuthProvider(authService: _GatedService()));
      await _toRegister(tester, _en);
      await tester.tap(find.byKey(_optInKey));
      await tester.pump();
      await tester.tap(find.text(_en.login));
      await tester.pumpAndSettle();
      await _toRegister(tester, _en);
      expect(_ticked(tester), isFalse);
    });

    testWidgets(
      'the choice survives the screen being rebuilt while the call runs',
      (tester) async {
        final service = _GatedService();
        await _pumpAuth(
          tester,
          AuthProvider(authService: service),
          home: const _MiniRouter(),
        );
        await _toRegister(tester, _en);
        await _fill(tester, _en);
        await tester.tap(find.byKey(_optInKey));
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, _en.register));
        await tester.pump();

        // The precondition of the trap: the sign-in screen is gone, replaced
        // by the splash, while the request is in flight.
        expect(find.byType(AuthScreen), findsNothing);
        expect(find.text('splash'), findsOneWidget);
        // …and what reached the service is what was ticked.
        expect(service.optIns, [true]);

        service.gate.complete({'success': false, 'message': 'refused'});
        await tester.pumpAndSettle();
        expect(find.byType(AuthScreen), findsOneWidget);
      },
    );
  });

  // -------------------------------------------------------------------------
  group('settings: the switch', () {
    test('the validated texts', () {
      expect(_fr.emailsSection, 'E-mails');
      expect(_en.emailsSection, 'Emails');
      expect(_fr.newsEmailsTitle, 'Nouveautés par e-mail');
      expect(_en.newsEmailsTitle, 'News by email');
      expect(
        _fr.newsEmailsSubtitle,
        'Nouvelles fonctions et nouveaux thèmes, rarement.',
      );
      expect(
        _en.newsEmailsSubtitle,
        'New features and new themes, occasionally.',
      );
      expect(
        _fr.newsEmailsSaveError,
        "Impossible d'enregistrer ce choix. Réessaie plus tard.",
      );
      expect(
        _en.newsEmailsSaveError,
        "Couldn't save this choice. Please try again later.",
      );
    });

    testWidgets('the section sits between Language and About', (tester) async {
      final server = FakeDuelServer((_) => _user(enabled: false));
      await _withServer(server, () async {
        await _pumpSettings(tester);
        final language = tester.getTopLeft(find.text(_en.language)).dy;
        final emails = tester.getTopLeft(find.text(_en.emailsSection)).dy;
        final about = tester.getTopLeft(find.text(_en.about)).dy;
        expect(language, lessThan(emails));
        expect(emails, lessThan(about));
        expect(find.text(_en.newsEmailsTitle), findsOneWidget);
        expect(find.text(_en.newsEmailsSubtitle), findsOneWidget);
      });
    });

    for (final value in [true, false]) {
      testWidgets('it reads the server value ($value)', (tester) async {
        final server = FakeDuelServer((_) => _user(enabled: value));
        await _withServer(server, () async {
          await _pumpSettings(tester);
          expect(_switchOn(tester), value);
          expect(_switchEnabled(tester), isTrue);
          expect(server.requests.single.method, 'GET');
        });
      });
    }

    testWidgets('off and disabled until the server has answered', (
      tester,
    ) async {
      final gate = Completer<http.Response>();
      final client = MockClient((_) => gate.future);
      await http.runWithClient(() async {
        await _pumpSettings(tester);
        expect(_switchOn(tester), isFalse);
        expect(_switchEnabled(tester), isFalse);
        gate.complete(_user(enabled: true));
        await tester.pumpAndSettle();
        expect(_switchOn(tester), isTrue);
        expect(_switchEnabled(tester), isTrue);
      }, () => client);
    });

    testWidgets('tapping it sends the PATCH with that field only', (
      tester,
    ) async {
      final server = FakeDuelServer(
        (r) => r.method == 'PATCH'
            ? _user(enabled: true)
            : _user(enabled: false),
      );
      await _withServer(server, () async {
        await _pumpSettings(tester);
        await tester.tap(find.byKey(_switchKey));
        await tester.pumpAndSettle();
        final patches = _patches(server);
        expect(patches, hasLength(1));
        expect(jsonDecode(patches.single.body), {'news_emails_enabled': true});
        expect(_switchOn(tester), isTrue);

        server.handler = (r) => _user(enabled: false);
        await tester.tap(find.byKey(_switchKey));
        await tester.pumpAndSettle();
        expect(jsonDecode(_patches(server).last.body), {
          'news_emails_enabled': false,
        });
        expect(_switchOn(tester), isFalse);
      });
    });

    for (final locale in ['fr', 'en']) {
      final l = locale == 'fr' ? _fr : _en;
      testWidgets('[$locale] a refused save: back to the previous state and '
          'a translated message', (tester) async {
        final server = FakeDuelServer(
          (r) => r.method == 'PATCH'
              ? errorResponse(400, 'invalid')
              : _user(enabled: false),
        );
        await _withServer(server, () async {
          await _pumpSettings(tester, locale: locale);
          await tester.tap(find.byKey(_switchKey));
          await tester.pumpAndSettle();
          expect(_switchOn(tester), isFalse, reason: 'rolled back');
          expect(_switchEnabled(tester), isTrue);
          expect(find.text(l.newsEmailsSaveError), findsOneWidget);
          expect(find.text('server text'), findsNothing);
        });
      });
    }

    testWidgets('a network failure rolls back the same way', (tester) async {
      var down = false;
      final client = MockClient((request) async {
        if (down) throw http.ClientException('down');
        return _user(enabled: true);
      });
      await http.runWithClient(() async {
        await _pumpSettings(tester);
        expect(_switchOn(tester), isTrue);
        down = true;
        await tester.tap(find.byKey(_switchKey));
        await tester.pumpAndSettle();
        expect(_switchOn(tester), isTrue, reason: 'rolled back to on');
        expect(find.text(_en.newsEmailsSaveError), findsOneWidget);
      }, () => client);
    });

    testWidgets('offline: the switch is disabled, and nothing is sent', (
      tester,
    ) async {
      final connectivity = FakeConnectivity(online: false);
      final server = FakeDuelServer((_) => _user(enabled: true));
      await _withServer(server, () async {
        await _pumpSettings(tester, connectivity: connectivity);
        expect(_switchEnabled(tester), isFalse);
        expect(server.requests, isEmpty);

        // Back online: the value is read, and the switch comes alive.
        connectivity.setOnline(true);
        await tester.pumpAndSettle();
        expect(_switchOn(tester), isTrue);
        expect(_switchEnabled(tester), isTrue);

        // Offline again: the known value stays, the switch is disabled.
        connectivity.setOnline(false);
        await tester.pumpAndSettle();
        expect(_switchOn(tester), isTrue);
        expect(_switchEnabled(tester), isFalse);
      });
    });
  });

  // -------------------------------------------------------------------------
  group('settings: the privacy policy link', () {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    late List<String> launched;

    setUp(() {
      launched = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'launch') {
              launched.add((call.arguments as Map)['url'] as String);
            }
            return true;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    const expected = {
      'fr': 'https://www.quizzbuilder.fr/privacy.html',
      'en': 'https://www.quizzbuilder.fr/en/privacy.html',
    };

    for (final locale in ['fr', 'en']) {
      final l = locale == 'fr' ? _fr : _en;
      testWidgets('[$locale] "${l.privacyPolicy}" opens ${expected[locale]}', (
        tester,
      ) async {
        final server = FakeDuelServer((_) => _user(enabled: false));
        await _withServer(server, () async {
          await _pumpSettings(tester, locale: locale);
          await tester.ensureVisible(find.text(l.privacyPolicy));
          await tester.tap(find.text(l.privacyPolicy));
          await tester.pumpAndSettle();
          expect(launched, [expected[locale]]);
        });
      });
    }

    test('the two labels', () {
      expect(_fr.privacyPolicy, 'Politique de confidentialité');
      expect(_en.privacyPolicy, 'Privacy policy');
    });
  });

  // -------------------------------------------------------------------------
  group('small screen (320 x 640): nothing overflows', () {
    /// Runs [body] and returns the Flutter errors raised meanwhile.
    Future<List<String>> raisedDuring(Future<void> Function() body) async {
      final raised = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (d) => raised.add(d.toString());
      try {
        await body();
      } finally {
        FlutterError.onError = previous;
      }
      return raised;
    }

    for (final locale in ['fr', 'en']) {
      final l = locale == 'fr' ? _fr : _en;

      testWidgets('[$locale] sign-up', (tester) async {
        final raised = await raisedDuring(() async {
          await _pumpAuth(
            tester,
            AuthProvider(authService: _GatedService()),
            locale: locale,
            size: const Size(320, 640),
          );
          await _toRegister(tester, l);
        });
        expect(raised.where((e) => e.contains('overflow')), isEmpty);
        expect(raised, isEmpty);
      });

      testWidgets('[$locale] settings: the new widgets stay inside the screen', (
        tester,
      ) async {
        // The test font (Ahem) is wider than a real one: two rows that were
        // already there (the web address, the contact e-mail) overflow in it
        // at 320 pt, with or without this lot. So the check is on the new
        // widgets' own geometry, not on the absence of any overflow.
        final server = FakeDuelServer((_) => _user(enabled: true));
        await _withServer(server, () async {
          final previous = FlutterError.onError;
          FlutterError.onError = (_) {};
          try {
            await _pumpSettings(
              tester,
              locale: locale,
              size: const Size(320, 640),
            );
            for (final finder in [
              find.byKey(_switchKey),
              find.text(l.emailsSection),
              find.text(l.newsEmailsTitle),
              find.text(l.newsEmailsSubtitle),
              find.text(l.privacyPolicy),
            ]) {
              await tester.ensureVisible(finder);
              final rect = tester.getRect(finder);
              expect(rect.left, greaterThanOrEqualTo(0), reason: '$finder');
              expect(rect.right, lessThanOrEqualTo(320), reason: '$finder');
            }
          } finally {
            FlutterError.onError = previous;
          }
        });
      });
    }
  });
}
