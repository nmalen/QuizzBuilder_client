import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/models/theme.dart' as theme_model;
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/catalog_provider.dart';
import 'package:QuizzBuilder/providers/connectivity_provider.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/providers/invitation_link_provider.dart';
import 'package:QuizzBuilder/ui/home_screen.dart';

import 'support/duel_live_support.dart';
import 'support/duel_test_support.dart';

final _l = AppLocalizationsEn();

class _Catalog extends CatalogProvider {
  _Catalog() : super(authService: FakeAuthService());

  @override
  Future<void> loadStatistics() async {}

  @override
  Future<void> syncOfflineContent({
    required bool Function(theme_model.Theme theme) isEntitled,
  }) async {}
}

/// The server of the home screen tests: open duels are scripted.
class _HomeServer {
  _HomeServer() {
    server = FakeDuelServer((r) {
      final p = r.path;
      if (r.method == 'GET' && p.endsWith('/duel/duels/')) {
        listCalls++;
        if (listFails) return errorResponse(500, 'server_error');
        return jsonResponse(200, {
          'server_time': iso(FakeClock.base),
          'count': open.length,
          'results': open,
        });
      }
      if (r.method == 'GET' && p.contains('/duel/duels/')) {
        return jsonResponse(
          200,
          duelJson(
            id: 5,
            serverTime: FakeClock.base,
            status: p.endsWith('/9/') ? 'playing' : 'waiting',
            startsAt: p.endsWith('/9/') ? FakeClock.base.add(const Duration(seconds: 8)) : null,
            challengedByMe: false,
            mySubmitted: false,
          ),
        );
      }
      return jsonResponse(200, {'count': 0, 'results': []});
    });
  }

  late final FakeDuelServer server;
  List<Map<String, Object?>> open = [];
  bool listFails = false;
  int listCalls = 0;
}

Map<String, Object?> _openRow(
  int id,
  String status,
  String name, {
  bool mine = false,
  int pair = 3,
}) => {
  'id': id,
  'status': status,
  'pair_id': pair,
  'opponent_username': name,
  'challenged_by_me': mine,
  'question_count': 10,
  'created_at': iso(FakeClock.base),
  'room_expires_at': iso(FakeClock.base.add(const Duration(minutes: 10))),
  'starts_at': status == 'playing' ? iso(FakeClock.base) : null,
  'deadline_at': status == 'playing' ? iso(FakeClock.base.add(const Duration(minutes: 4))) : null,
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<_HomeServer> pumpHome(
    WidgetTester tester, {
    FakeConnectivity? connectivity,
    String locale = 'en',
    void Function(_HomeServer)? configure,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final s = _HomeServer();
    configure?.call(s);
    final duel = DuelProvider(service: s.server.service);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: FakeAuthProvider()),
          ChangeNotifierProvider<CatalogProvider>.value(value: _Catalog()),
          ChangeNotifierProvider<ConnectivityProvider>.value(
            value: connectivity ?? FakeConnectivity(),
          ),
          ChangeNotifierProvider<DuelProvider>.value(value: duel),
          ChangeNotifierProvider<InvitationLinkProvider>.value(
            value: InvitationLinkProvider(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(locale),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    return s;
  }

  testWidgets('the Duel card says "Challenge a friend" (and the French one "Défie un proche")', (tester) async {
    await pumpHome(tester);
    expect(find.text(_l.duelCardTitle), findsOneWidget);
    expect(find.text('Challenge a friend'), findsOneWidget);
    expect(find.text('Find your friends and invite them'), findsNothing);
  });

  testWidgets('French card subtitle', (tester) async {
    await pumpHome(tester, locale: 'fr');
    expect(find.text('Défie un proche'), findsOneWidget);
  });

  testWidgets('opening the home screen looks for open duels once, silently', (tester) async {
    final s = await pumpHome(tester);
    expect(s.listCalls, 1);
    expect(find.byKey(const ValueKey('duel-banner')), findsNothing, reason: 'nothing to do');
  });

  testWidgets('a failing check shows nothing at all', (tester) async {
    final s = await pumpHome(tester, configure: (s) => s.listFails = true);
    expect(s.listCalls, 1);
    expect(find.byKey(const ValueKey('duel-banner')), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline: no check', (tester) async {
    final s = await pumpHome(tester, connectivity: FakeConnectivity(online: false));
    expect(s.listCalls, 0);
    expect(find.byKey(const ValueKey('duel-banner')), findsNothing);
  });

  testWidgets('challenged in a waiting room: "<name> is waiting for you", on top of the cards', (tester) async {
    await pumpHome(
      tester,
      configure: (s) => s.open = [_openRow(5, 'waiting', 'alice')],
    );
    expect(find.text(_l.duelBannerWaiting('alice')), findsOneWidget);
    expect(find.text(_l.duelBannerWaitingSub), findsOneWidget);
    final bannerTop = tester.getTopLeft(find.byKey(const ValueKey('duel-banner'))).dy;
    final dailyTop = tester.getTopLeft(find.text(_l.dailyChallenge)).dy;
    expect(bannerTop, lessThan(dailyTop), reason: 'the banner comes first');
  });

  testWidgets('tapping it opens the waiting room of that duel', (tester) async {
    final s = await pumpHome(
      tester,
      configure: (s) => s.open = [_openRow(5, 'waiting', 'alice')],
    );
    await tester.tap(find.byKey(const ValueKey('duel-banner')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(_l.duelRoomTitle), findsOneWidget);
    expect(requestsTo(s.server, 'GET', '/duel/duels/5/'), isNotEmpty);
  });

  testWidgets('my own waiting room has no banner (it is listed in the hub)', (tester) async {
    await pumpHome(
      tester,
      configure: (s) => s.open = [_openRow(5, 'waiting', 'alice', mine: true)],
    );
    expect(find.byKey(const ValueKey('duel-banner')), findsNothing);
  });

  testWidgets('a game I can resume: "Duel in progress", resume on tap', (tester) async {
    final s = await pumpHome(
      tester,
      configure: (s) => s.open = [_openRow(9, 'playing', 'alice')],
    );
    expect(find.text(_l.duelBannerPlaying('alice')), findsOneWidget);
    expect(find.text(_l.duelBannerPlayingSub), findsOneWidget);
    expect(find.text(_l.duelBannerWaiting('alice')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('duel-banner')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 50));
    expect(requestsTo(s.server, 'GET', '/duel/duels/9/'), isNotEmpty);
    expect(find.text(_l.duelGameTitle('alice')), findsOneWidget);
  });

  testWidgets('a game opens only when the player taps: never by itself', (tester) async {
    await pumpHome(
      tester,
      configure: (s) => s.open = [_openRow(9, 'playing', 'alice')],
    );
    await tester.pump(const Duration(seconds: 5));
    expect(find.text(_l.duelGameTitle('alice')), findsNothing);
    expect(find.text(_l.duelRoomTitle), findsNothing);
  });

  testWidgets('several: one banner with the count, going to the hub', (tester) async {
    await pumpHome(
      tester,
      configure: (s) => s.open = [
        _openRow(5, 'waiting', 'alice', pair: 3),
        _openRow(6, 'waiting', 'bob', pair: 4),
      ],
    );
    expect(find.text(_l.duelBannerMany(2)), findsOneWidget);
    expect(find.text(_l.duelBannerManySub), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('duel-banner')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text(_l.duelHubTitle)),
      findsOneWidget,
    );
  });

  testWidgets('French banner', (tester) async {
    await pumpHome(
      tester,
      locale: 'fr',
      configure: (s) => s.open = [_openRow(5, 'waiting', 'alice')],
    );
    expect(find.text("alice t'attend"), findsOneWidget);
  });

  group('back in the foreground (main.dart)', () {
    // `MyApp` cannot be built in a debug test: it passes both `home:` and
    // `onGenerateInitialRoutes:` to MaterialApp, which a debug assertion
    // refuses (already true at 1961fae, not touched by this batch). So the
    // wiring is checked on the source, and the provider call it makes is
    // tested above (opening the home screen runs the same silent check).
    test('didChangeAppLifecycleState checks open duels, online only, silently', () {
      final source = File('lib/main.dart').readAsStringSync();
      final start = source.indexOf('void didChangeAppLifecycleState');
      expect(start, isNonNegative);
      final end = source.indexOf('void dispose()', start);
      final body = source.substring(start, end);
      expect(body, contains('loadOpenDuels()'));
      expect(body, contains('isOnline == true'));
      expect(body, contains('AppLifecycleState.resumed'));
      expect(body.indexOf('isOnline == true'), lessThan(body.indexOf('loadOpenDuels()')));
    });
  });
}
