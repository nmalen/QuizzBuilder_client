import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
import 'support/duel_live_support.dart';
import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'support/duel_test_support.dart';

final _l = AppLocalizationsEn();

class _Harness {
  _Harness({bool loggedIn = true, bool initialized = true, String? initial}) {
    auth = FakeAuthProvider(loggedIn: loggedIn, initialized: initialized);
    initialLocation = initial;
    server = FakeDuelServer((r) {
      if (r.method == 'POST' && r.path.contains('/duels/join/')) {
        return joinResponse(r);
      }
      if (r.method == 'GET' && r.path.contains('/duel/duels/') && !r.path.endsWith('/duel/duels/')) {
        return jsonResponse(200, duelJson(serverTime: FakeClock.base));
      }
      if (r.method == 'GET' && r.path.contains('/invitations/')) {
        return jsonResponse(200, {
          'inviter_username': 'alice',
          'expires_at': '2026-11-13T10:00:00Z',
        });
      }
      return jsonResponse(200, {'count': 0, 'results': []});
    });
  }

  /// Answer to `POST duels/join/<code>/`.
  late http.Response Function(RecordedRequest) joinResponse = (r) =>
      jsonResponse(200, duelJson(serverTime: FakeClock.base));

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

  group('8-character call link (live duel)', () {
    /// Delivers a link without waiting for the room's clock to settle.
    Future<void> deliverLive(WidgetTester tester, String location) async {
      final message = const JSONMethodCodec().encodeMethodCall(
        MethodCall('pushRouteInformation', {'location': location}),
      );
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/navigation',
        message,
        (_) {},
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    testWidgets('signed in: POST join with the normalized code, then the waiting room', (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.app);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      await deliverLive(tester, 'https://play.quizzbuilder.fr/d/abcd-2345');

      final joins = h.server.requests.where((r) => r.method == 'POST').toList();
      expect(joins, hasLength(1));
      expect(joins.single.path, endsWith('/duel/duels/join/ABCD2345/'));
      expect(find.text(_l.duelRoomTitle), findsOneWidget);
      expect(find.text(_l.duelRoomWaitingFor('alice')), findsOneWidget);
      expect(h.links.pendingCallCode, isNull);
      expect(h.links.pendingCode, isNull, reason: 'not an invitation');
      expect(
        h.server.requests.where((r) => r.path.contains('/invitations/')),
        isEmpty,
      );
    });

    testWidgets('signed out: the code is kept, nothing is called, the room opens after sign-in', (tester) async {
      final h = _Harness(loggedIn: false);
      await tester.pumpWidget(h.app);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      await deliverLive(tester, '/d/ABCD2345');

      expect(h.links.pendingCallCode, 'ABCD2345');
      expect(h.links.pendingCode, isNull);
      expect(h.server.requests, isEmpty);
      expect(find.text(_l.duelRoomTitle), findsNothing);
      expect(find.text('app home'), findsOneWidget, reason: 'the usual screen stays');

      h.auth.setState(loggedIn: true);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(h.server.requests.where((r) => r.method == 'POST'), hasLength(1));
      expect(find.text(_l.duelRoomTitle), findsOneWidget);
      expect(h.links.pendingCallCode, isNull);
    });

    testWidgets('cold link: waits for the authentication state, then joins', (tester) async {
      final h = _Harness(initialized: false, initial: '/d/ABCD2345');
      await tester.pumpWidget(h.app);
      await tester.pump(const Duration(milliseconds: 200));
      expect(h.server.requests, isEmpty);

      h.auth.setState(initialized: true);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      expect(h.server.requests.where((r) => r.method == 'POST'), hasLength(1));
      expect(find.text(_l.duelRoomTitle), findsOneWidget);
    });

    testWidgets('the same link delivered twice at once joins once', (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.app);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      await deliverLive(tester, '/d/ABCD2345');
      await deliverLive(tester, '/d/ABCD2345');
      expect(h.server.requests.where((r) => r.method == 'POST'), hasLength(1));
    });

    testWidgets('unknown duel: the message, then the hub', (tester) async {
      final h = _Harness();
      h.joinResponse = (r) => errorResponse(404, 'duel_not_found');
      await tester.pumpWidget(h.app);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      await deliverLive(tester, '/d/ABCD2345');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(_l.duelErrDuelNotFound), findsOneWidget);
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text(_l.duelHubTitle)),
        findsOneWidget,
      );
    });

    testWidgets('a duel already expired shows the expiry message in the room', (tester) async {
      final h = _Harness();
      h.joinResponse = (r) => jsonResponse(
        200,
        duelJson(serverTime: FakeClock.base, status: 'expired'),
      );
      await tester.pumpWidget(h.app);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      await deliverLive(tester, '/d/ABCD2345');
      expect(find.text(_l.duelRoomExpired), findsOneWidget);
    });

    testWidgets('6-character links keep their behaviour (invitation, not a duel)', (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.app);
      await deliver(tester, '/d/K7P3QX');
      expect(find.text(_l.duelChallengesYou('alice')), findsOneWidget);
      expect(h.server.requests.where((r) => r.path.contains('/duels/join/')), isEmpty);
      expect(h.links.pendingCallCode, isNull);
    });
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
