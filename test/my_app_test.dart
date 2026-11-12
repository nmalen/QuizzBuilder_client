import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/ui/auth_screen.dart';
import 'package:QuizzBuilder/ui/home_screen.dart';
import 'package:QuizzBuilder/ui/splash_screen.dart';

import 'support/app_test_support.dart';
import 'support/duel_live_support.dart';
import 'support/duel_test_support.dart';

final _l = AppLocalizationsEn();

/// A server for the duel calls the home screen and the links make.
FakeDuelServer _server() => FakeDuelServer((r) {
  final p = r.path;
  if (r.method == 'GET' && p.endsWith('/duel/duels/')) {
    return jsonResponse(200, {
      'server_time': iso(FakeClock.base),
      'count': 0,
      'results': [],
    });
  }
  if (r.method == 'GET' && p.contains('/invitations/')) {
    return jsonResponse(200, {
      'inviter_username': 'alice',
      'expires_at': '2026-11-13T10:00:00Z',
    });
  }
  if (r.method == 'POST' && p.contains('/duels/join/')) {
    return jsonResponse(200, duelJson(serverTime: FakeClock.base));
  }
  if (r.method == 'GET' && p.contains('/duel/duels/')) {
    return jsonResponse(200, duelJson(serverTime: FakeClock.base));
  }
  return jsonResponse(200, {'count': 0, 'results': []});
});

Future<void> _pumpFrames(WidgetTester tester, [int n = 5]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void _background(WidgetTester tester) {
  for (final s in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

void _foreground(WidgetTester tester) {
  for (final s in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

Future<void> _deliver(WidgetTester tester, String location) async {
  final message = const JSONMethodCodec().encodeMethodCall(
    MethodCall('pushRouteInformation', {'location': location}),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    message,
    (_) {},
  );
  await _pumpFrames(tester);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AppHarness> mount(
    WidgetTester tester, {
    bool loggedIn = true,
    bool loading = false,
    String? route,
  }) async {
    if (route != null) setInitialRoute(tester, route);
    final h = AppHarness(
      loggedIn: loggedIn,
      loading: loading,
      initialLocation: route,
      server: _server(),
    );
    await tester.pumpWidget(h.app);
    await _pumpFrames(tester);
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    return h;
  }

  group('MyApp mounts in debug (no assertion on home / onGenerateInitialRoutes)', () {
    testWidgets('signed in: the home screen', (tester) async {
      await mount(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
    });

    testWidgets('signed out: the authentication screen', (tester) async {
      await mount(tester, loggedIn: false);
      expect(tester.takeException(), isNull);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('loading: the splash screen, then the right screen', (tester) async {
      final h = await mount(tester, loading: true, loggedIn: false);
      expect(tester.takeException(), isNull);
      expect(find.byType(SplashScreen), findsOneWidget);
      h.auth.loading = false;
      h.auth.setLoading(false);
      await _pumpFrames(tester, 2);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
      await tester.pump(const Duration(seconds: 3)); // the splash's own 2 s timer
      expect(tester.takeException(), isNull);
    });

    testWidgets("the splash's own push of '/home' (signed in, still loading after 2 s) is invisible and harmless", (tester) async {
      final h = await mount(tester, loading: true);
      await tester.pump(const Duration(seconds: 2, milliseconds: 100));
      expect(tester.takeException(), isNull);
      // The push replaced the page by the app router, with no transition:
      // one splash screen, no second page underneath.
      expect(find.byType(SplashScreen, skipOffstage: false), findsOneWidget);

      h.auth.setLoading(false);
      await _pumpFrames(tester, 3);
      await tester.pump(const Duration(seconds: 3)); // the splash's own timer
      expect(find.byType(HomeScreen, skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the title, the English texts and the Duel card are unchanged', (tester) async {
      await mount(tester);
      expect(find.text(_l.duelCardTitle), findsOneWidget);
      expect(find.text(_l.duelCardSubtitle), findsOneWidget);
      expect(find.text(_l.dailyChallenge), findsOneWidget);
    });

    testWidgets('a route name nobody generated lands on the app router, without error', (tester) async {
      final h = await mount(tester);
      h.navigatorKey.currentState!.pushNamed('/not-a-route');
      await _pumpFrames(tester, 3);
      expect(tester.takeException(), isNull);
      expect(find.byType(HomeScreen), findsOneWidget, reason: 'the fallback page is the app router, not an error screen');
      expect(
        find.byType(HomeScreen, skipOffstage: false),
        findsNWidgets(2),
        reason: 'one more page on the stack, the first one stays below',
      );
    });
  });

  group('cold start by a universal link', () {
    /// Runs [body] with `debugPrint` captured, and always puts it back (the
    /// test framework checks it before any tearDown runs).
    void linkTest(
      String name,
      Future<void> Function(WidgetTester tester, List<String> logs) body,
    ) {
      testWidgets(name, (tester) async {
        final logs = <String>[];
        final original = debugPrint;
        debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
        try {
          await body(tester, logs);
        } finally {
          debugPrint = original;
        }
      });
    }

    bool routeError(List<String> logs) => logs.any(
      (l) =>
          l.contains('Could not generate route') ||
          l.contains('Could not find a generator for route'),
    );

    linkTest('/d/<6>, signed in: no error, the join screen opens', (tester, logs) async {
      final h = await mount(tester, route: '/d/K7P3QX');
      expect(tester.takeException(), isNull);
      expect(routeError(logs), isFalse, reason: logs.join('\n'));
      expect(find.text(_l.duelChallengesYou('alice')), findsOneWidget);
      expect(h.links.pendingCode, isNull);
      expect(
        h.server.requests.where((r) => r.path.endsWith('/invitations/K7P3QX/')),
        hasLength(1),
      );
    });

    linkTest('/d/<6>, signed out: no error, the code is kept for the sign-up screen', (tester, logs) async {
      final h = await mount(tester, loggedIn: false, route: '/d/K7P3QX');
      expect(tester.takeException(), isNull);
      expect(routeError(logs), isFalse, reason: logs.join('\n'));
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(h.links.pendingCode, 'K7P3QX');
      expect(h.server.requests, isEmpty);
    });

    linkTest('/d/<8>, signed in: no error, the waiting room opens', (tester, logs) async {
      final h = await mount(tester, route: '/d/ABCD2345');
      expect(tester.takeException(), isNull);
      expect(routeError(logs), isFalse, reason: logs.join('\n'));
      expect(find.text(_l.duelRoomTitle), findsOneWidget);
      expect(
        h.server.requests.where((r) => r.path.endsWith('/duels/join/ABCD2345/')),
        hasLength(1),
      );
      expect(h.links.pendingCallCode, isNull);
    });

    linkTest('/d/<8>, signed out: no error, the code is kept', (tester, logs) async {
      final h = await mount(tester, loggedIn: false, route: '/d/ABCD2345');
      expect(tester.takeException(), isNull);
      expect(routeError(logs), isFalse, reason: logs.join('\n'));
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(h.links.pendingCallCode, 'ABCD2345');
    });

    linkTest('an engine route that is not a link: starts on the app router, no error', (tester, logs) async {
      await mount(tester, route: '/somewhere/else');
      expect(tester.takeException(), isNull);
      expect(routeError(logs), isFalse, reason: logs.join('\n'));
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    linkTest('a warm link is still handed to the link host', (tester, logs) async {
      final h = await mount(tester);
      await _deliver(tester, 'https://play.quizzbuilder.fr/d/K7P3QX');
      expect(tester.takeException(), isNull);
      expect(routeError(logs), isFalse, reason: logs.join('\n'));
      expect(find.text(_l.duelChallengesYou('alice')), findsOneWidget);
      expect(h.links.pendingCode, isNull);
    });
  });

  group('back in the foreground', () {
    testWidgets('looks for open duels, silently, and refreshes the token', (tester) async {
      final h = await mount(tester);
      int calls() => requestsTo(h.server, 'GET', '/duel/duels/').length;
      final before = calls();
      final tokenBefore = h.auth.refreshTokenCalls;

      _background(tester);
      await _pumpFrames(tester, 1);
      expect(calls(), before, reason: 'nothing while in the background');
      _foreground(tester);
      await _pumpFrames(tester, 2);

      expect(calls(), before + 1);
      expect(h.auth.refreshTokenCalls, tokenBefore + 1);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('offline: no check', (tester) async {
      final h = await mount(tester);
      h.connectivity.setOnline(false);
      await _pumpFrames(tester, 1);
      final before = requestsTo(h.server, 'GET', '/duel/duels/').length;
      _background(tester);
      _foreground(tester);
      await _pumpFrames(tester, 2);
      expect(requestsTo(h.server, 'GET', '/duel/duels/').length, before);
    });

    testWidgets('signed out: no check', (tester) async {
      final h = await mount(tester, loggedIn: false);
      _background(tester);
      _foreground(tester);
      await _pumpFrames(tester, 2);
      expect(h.server.requests, isEmpty);
    });

    testWidgets('a failing check shows nothing', (tester) async {
      final h = await mount(tester);
      h.server.handler = (r) => errorResponse(500, 'server_error');
      _background(tester);
      _foreground(tester);
      await _pumpFrames(tester, 2);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
