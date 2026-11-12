import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/ui/auth_screen.dart';
import 'package:QuizzBuilder/ui/home_screen.dart';
import 'package:QuizzBuilder/ui/splash_screen.dart';

import 'support/app_test_support.dart';

/// `_AppRouter` alone chooses the screen from `AuthProvider`; the splash
/// screen only shows itself. A slow call (more than the splash's old 2 s
/// timer) must end on the right screen.
Future<void> _elapse(WidgetTester tester, Duration total) async {
  var left = total;
  while (left > Duration.zero) {
    final step = left < const Duration(milliseconds: 100)
        ? left
        : const Duration(milliseconds: 100);
    await tester.pump(step);
    left -= step;
  }
}

const _slow = Duration(seconds: 3);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Mounts the whole app over a real [AuthProvider] and a scripted service.
  Future<({AuthProvider auth, ScriptedAuthService service})> mount(
    WidgetTester tester,
    ScriptedAuthService service,
  ) async {
    final auth = AuthProvider(authService: service);
    final h = AppHarness(authProvider: auth);
    await tester.pumpWidget(h.app);
    await _elapse(tester, const Duration(milliseconds: 300));
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    return (auth: auth, service: service);
  }

  void expectScreens(
    WidgetTester tester, {
    int home = 0,
    int auth = 0,
    int splash = 0,
  }) {
    expect(tester.takeException(), isNull);
    expect(find.byType(HomeScreen), findsNWidgets(home), reason: 'HomeScreen');
    expect(find.byType(AuthScreen), findsNWidgets(auth), reason: 'AuthScreen');
    expect(
      find.byType(SplashScreen),
      findsNWidgets(splash),
      reason: 'SplashScreen',
    );
  }

  group('a slow sign-in, sign-up, start or sign-out', () {
    testWidgets('sign-in that takes 3 s: the home screen, not the sign-in screen', (tester) async {
      final m = await mount(tester, ScriptedAuthService(loginDelay: _slow));
      expectScreens(tester, auth: 1);

      unawaited(m.auth.login(identifier: 'someone', password: 'secret'));
      await _elapse(tester, const Duration(seconds: 2, milliseconds: 500));
      expectScreens(tester, splash: 1); // still waiting, past the old 2 s

      await _elapse(tester, const Duration(seconds: 1));
      expect(m.auth.isLoggedIn, isTrue);
      expectScreens(tester, home: 1);
    });

    testWidgets('sign-in that takes 10 s: the home screen too', (tester) async {
      final m = await mount(
        tester,
        ScriptedAuthService(loginDelay: const Duration(seconds: 10)),
      );
      unawaited(m.auth.login(identifier: 'someone', password: 'secret'));
      await _elapse(tester, const Duration(seconds: 11));
      expectScreens(tester, home: 1);
    });

    testWidgets('fast sign-in (under 2 s): the home screen, as before', (tester) async {
      final m = await mount(
        tester,
        ScriptedAuthService(loginDelay: const Duration(milliseconds: 500)),
      );
      unawaited(m.auth.login(identifier: 'someone', password: 'secret'));
      await _elapse(tester, const Duration(seconds: 1));
      expectScreens(tester, home: 1);
    });

    testWidgets('sign-up that takes 3 s: back on the authentication screen, not signed in', (tester) async {
      final m = await mount(tester, ScriptedAuthService(registerDelay: _slow));
      unawaited(
        m.auth.register(
          email: 'someone@example.test',
          username: 'someone',
          password1: 'secret',
          password2: 'secret',
        ),
      );
      await _elapse(tester, const Duration(seconds: 2, milliseconds: 500));
      expectScreens(tester, splash: 1);
      await _elapse(tester, const Duration(seconds: 1));
      expect(m.auth.isLoggedIn, isFalse);
      expectScreens(tester, auth: 1);
    });

    testWidgets('start with a stored session and a 3 s token refresh: the home screen', (tester) async {
      final service = ScriptedAuthService(hasSession: true, refreshDelay: _slow);
      final auth = AuthProvider(authService: service);
      final h = AppHarness(authProvider: auth);
      await tester.pumpWidget(h.app);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      await _elapse(tester, const Duration(seconds: 2, milliseconds: 500));
      expectScreens(tester, splash: 1);
      await _elapse(tester, const Duration(seconds: 1));
      expectScreens(tester, home: 1);
    });

    testWidgets('start with a 3 s token refresh that the server refuses: the authentication screen', (tester) async {
      final service = ScriptedAuthService(
        hasSession: true,
        refreshDelay: _slow,
        refreshAccepted: false,
      );
      final auth = AuthProvider(authService: service);
      final h = AppHarness(authProvider: auth);
      await tester.pumpWidget(h.app);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      await _elapse(tester, const Duration(seconds: 2, milliseconds: 500));
      expectScreens(tester, splash: 1);
      await _elapse(tester, const Duration(seconds: 1));
      expect(auth.isLoggedIn, isFalse);
      expectScreens(tester, auth: 1);
    });

    testWidgets('slow initialisation (3 s) with a stored session: the home screen', (tester) async {
      final service = ScriptedAuthService(hasSession: true, initializeDelay: _slow);
      final auth = AuthProvider(authService: service);
      final h = AppHarness(authProvider: auth);
      await tester.pumpWidget(h.app);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      await _elapse(tester, const Duration(seconds: 2, milliseconds: 500));
      expectScreens(tester, splash: 1);
      await _elapse(tester, const Duration(seconds: 1));
      expect(auth.isLoggedIn, isTrue);
      expectScreens(tester, home: 1);
    });

    testWidgets('slow start without any stored session: the authentication screen', (tester) async {
      final service = ScriptedAuthService(initializeDelay: _slow);
      final auth = AuthProvider(authService: service);
      final h = AppHarness(authProvider: auth);
      await tester.pumpWidget(h.app);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      await _elapse(tester, const Duration(seconds: 2, milliseconds: 500));
      expectScreens(tester, splash: 1);
      await _elapse(tester, const Duration(seconds: 1));
      expectScreens(tester, auth: 1);
    });

    testWidgets('sign-out that takes 3 s: the authentication screen', (tester) async {
      final m = await mount(
        tester,
        ScriptedAuthService(hasSession: true, logoutDelay: _slow),
      );
      expectScreens(tester, home: 1);
      unawaited(m.auth.logout());
      await _elapse(tester, const Duration(seconds: 2, milliseconds: 500));
      expectScreens(tester, splash: 1);
      await _elapse(tester, const Duration(seconds: 1));
      expect(m.auth.isLoggedIn, isFalse);
      expectScreens(tester, auth: 1);
    });

    testWidgets('after a slow sign-in, signing out and in again still works', (tester) async {
      final m = await mount(tester, ScriptedAuthService(loginDelay: _slow));
      unawaited(m.auth.login(identifier: 'someone', password: 'secret'));
      await _elapse(tester, const Duration(seconds: 4));
      expectScreens(tester, home: 1);
      unawaited(m.auth.logout()); // a timer: it only runs when time is pumped
      await _elapse(tester, const Duration(milliseconds: 500));
      expectScreens(tester, auth: 1);
      unawaited(m.auth.login(identifier: 'someone', password: 'secret'));
      await _elapse(tester, const Duration(seconds: 4));
      expectScreens(tester, home: 1);
    });
  });

  group('the splash screen only shows itself', () {
    testWidgets('alone, it pushes and replaces no route, whatever the state', (tester) async {
      final events = <String>[];
      final observer = _RecordingObserver(events);
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SplashScreen(),
        ),
      );
      await _elapse(tester, const Duration(seconds: 10));
      expect(tester.takeException(), isNull);
      expect(events, ['push /'], reason: 'only the initial route');
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
    });

    testWidgets('it still shows the same things: gradient, icon, title, subtitle, spinner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SplashScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.quiz), findsOneWidget);
      expect(find.text('QuizzBuilder'), findsOneWidget);
      expect(find.text('Ready to test your knowledge?'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final decorated = tester.widget<Container>(
        find.descendant(
          of: find.byType(Scaffold),
          matching: find.byType(Container),
        ).first,
      );
      expect(
        (decorated.decoration as BoxDecoration).gradient,
        isA<LinearGradient>(),
      );
    });
  });
}

class _RecordingObserver extends NavigatorObserver {
  _RecordingObserver(this.events);
  final List<String> events;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      events.add('push ${route.settings.name}');

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      events.add('replace ${newRoute?.settings.name}');

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      events.add('remove ${route.settings.name}');
}
