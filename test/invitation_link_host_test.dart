import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/connectivity_provider.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/providers/invitation_link_provider.dart';
import 'package:QuizzBuilder/ui/duel/invitation_link_host.dart';
import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'support/duel_test_support.dart';

final _l = AppLocalizationsEn();

class _Harness {
  _Harness({bool loggedIn = true, bool initialized = true, String? initial}) {
    auth = FakeAuthProvider(loggedIn: loggedIn, initialized: initialized);
    initialLocation = initial;
    server = FakeDuelServer((r) {
      if (r.method == 'GET' && r.path.contains('/invitations/')) {
        return jsonResponse(200, {
          'inviter_username': 'alice',
          'expires_at': '2026-11-13T10:00:00Z',
        });
      }
      return jsonResponse(200, {'count': 0, 'results': []});
    });
  }

  late final FakeAuthProvider auth;
  late final FakeDuelServer server;
  final links = InvitationLinkProvider();
  final navigatorKey = GlobalKey<NavigatorState>();
  String? initialLocation;

  Widget get app => MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<InvitationLinkProvider>.value(value: links),
      ChangeNotifierProvider<DuelProvider>.value(
        value: DuelProvider(service: server.service),
      ),
      ChangeNotifierProvider<ConnectivityProvider>.value(
        value: FakeConnectivity(),
      ),
    ],
    child: InvitationLinkHost(
      navigatorKey: navigatorKey,
      initialLocation: initialLocation,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(body: Text('app home')),
      ),
    ),
  );
}

/// Delivers a link the way the engine does for a warm start.
Future<void> deliver(WidgetTester tester, String location) async {
  final message = const JSONMethodCodec().encodeMethodCall(
    MethodCall('pushRouteInformation', {'location': location}),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    message,
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('warm link, signed in: the join confirmation opens', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.app);
    await deliver(tester, 'https://play.quizzbuilder.fr/d/k7p-3qx');

    expect(find.text(_l.duelChallengesYou('alice')), findsOneWidget);
    expect(h.server.requests.single.path, endsWith('/invitations/K7P3QX/'));
    expect(h.links.pendingCode, isNull);
  });

  testWidgets('warm link, signed out: code kept, then the join flow resumes after sign-in', (tester) async {
    final h = _Harness(loggedIn: false);
    await tester.pumpWidget(h.app);
    await deliver(tester, '/d/K7P3QX');

    expect(find.text(_l.duelChallengesYou('alice')), findsNothing);
    expect(h.links.pendingCode, 'K7P3QX');
    expect(h.server.requests, isEmpty);

    h.auth.setState(loggedIn: true);
    await tester.pumpAndSettle();
    expect(find.text(_l.duelChallengesYou('alice')), findsOneWidget);
    expect(h.links.pendingCode, isNull);
  });

  testWidgets('cold link: waits for the authentication state, then opens', (tester) async {
    final h = _Harness(initialized: false, initial: '/d/K7P3QX');
    await tester.pumpWidget(h.app);
    await tester.pumpAndSettle();
    expect(find.text(_l.duelChallengesYou('alice')), findsNothing);
    expect(h.server.requests, isEmpty);

    h.auth.setState(initialized: true);
    await tester.pumpAndSettle();
    expect(find.text(_l.duelChallengesYou('alice')), findsOneWidget);
  });

  testWidgets('cold link, signed out: code kept for the sign-up screen', (tester) async {
    final h = _Harness(loggedIn: false, initialized: false, initial: '/d/K7P3QX');
    await tester.pumpWidget(h.app);
    h.auth.setState(initialized: true);
    await tester.pumpAndSettle();
    expect(h.links.pendingCode, 'K7P3QX');
    expect(h.links.takeEntryHint(), isTrue);
  });

  testWidgets('8-character link, signed in: opens the hub and nothing else', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.app);
    await deliver(tester, 'https://play.quizzbuilder.fr/d/ABCD2345');

    expect(find.text(_l.duelHubTitle), findsOneWidget);
    expect(find.text(_l.duelChallengesYou('alice')), findsNothing);
    expect(h.links.pendingCode, isNull);
    expect(
      h.server.requests.where((r) => r.path.contains('/invitations/')),
      isEmpty,
      reason: 'the call code is not an invitation',
    );
  });

  testWidgets('8-character link, signed out: ignored, nothing kept', (tester) async {
    final h = _Harness(loggedIn: false);
    await tester.pumpWidget(h.app);
    await deliver(tester, '/d/ABCD2345');
    expect(h.links.pendingCode, isNull);
    h.auth.setState(loggedIn: true);
    await tester.pumpAndSettle();
    expect(find.text(_l.duelHubTitle), findsNothing);
  });

  testWidgets('any other path is ignored without error', (tester) async {
    final h = _Harness();
    await tester.pumpWidget(h.app);
    for (final location in ['/', '/admin/', '/d/K7P3', '/x/K7P3QX', 'https://evil.example/d/K7P3QX']) {
      await deliver(tester, location);
    }
    expect(find.text('app home'), findsOneWidget);
    expect(h.links.pendingCode, isNull);
    expect(h.server.requests, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
