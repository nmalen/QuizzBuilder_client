import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/l10n/app_localizations_fr.dart';
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/catalog_provider.dart';
import 'package:QuizzBuilder/providers/connectivity_provider.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/providers/invitation_link_provider.dart';
import 'package:QuizzBuilder/services/push/push_gateway.dart';
import 'package:QuizzBuilder/services/push/push_notification_service.dart';
import 'package:QuizzBuilder/services/push/push_payload.dart';
import 'package:QuizzBuilder/services/push/push_prompt_state.dart';
import 'package:QuizzBuilder/ui/duel/duel_hub_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_live_screen.dart';
import 'package:QuizzBuilder/ui/home_screen.dart';
import 'package:QuizzBuilder/ui/push_navigation_host.dart';
import 'package:QuizzBuilder/ui/push_permission_prompt.dart';

import 'support/app_test_support.dart';
import 'support/duel_live_support.dart';
import 'support/duel_test_support.dart';
import 'support/push_test_support.dart';

/// QB-C-024 points 3, 4 and 5: a notification received while the app is open
/// (refresh + banner), the proposal on the duel screen, the 20 s refresh.
/// Nothing loads Firebase.
final _en = AppLocalizationsEn();
final _fr = AppLocalizationsFr();

const _banner = ValueKey('push-banner');
const _bannerAction = ValueKey('push-banner-action');
const _bannerClose = ValueKey('push-banner-close');

Map<String, Object?> _openRow(int id, String status, String name) => {
  'id': id,
  'status': status,
  'pair_id': 3,
  'opponent_username': name,
  'challenged_by_me': false,
  'question_count': 10,
  'created_at': iso(FakeClock.base),
  'room_expires_at': iso(FakeClock.base.add(const Duration(minutes: 10))),
  'starts_at': null,
  'deadline_at': null,
};

/// The server: open duels and opponents are scripted, every call is counted.
class _Server {
  _Server() {
    server = FakeDuelServer((r) {
      final p = r.path;
      if (r.method == 'GET' && p.endsWith('/duel/duels/')) {
        duelListCalls++;
        return jsonResponse(200, {
          'server_time': iso(FakeClock.base),
          'count': open.length,
          'results': open,
        });
      }
      if (r.method == 'GET' && p.endsWith('/duel/opponents/')) {
        opponentCalls++;
        return jsonResponse(200, {
          'count': opponents.length,
          'results': opponents,
        });
      }
      if (r.method == 'GET' && RegExp(r'/duel/duels/\d+/$').hasMatch(p)) {
        return jsonResponse(
          200,
          duelJson(
            id: 5,
            serverTime: FakeClock.base,
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
  List<Map<String, Object?>> opponents = [];
  int duelListCalls = 0;
  int opponentCalls = 0;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('words: FR and EN', () {
    expect(_fr.pushBannerJoin, 'Rejoindre');
    expect(_fr.pushBannerView, 'Voir');
    expect(_fr.pushBannerClose, 'Fermer');
    expect(_en.pushBannerJoin, 'Join');
    expect(_en.pushBannerView, 'View');
    expect(_en.pushBannerClose, 'Close');
  });

  group('a notification received while the app is open', () {
    late FakeAuthProvider auth;
    late FakePushGateway gateway;
    late PushNotificationService service;
    late _Server s;
    late DuelProvider duel;
    final navigatorKey = GlobalKey<NavigatorState>();

    Future<void> pumpHost(
      WidgetTester tester, {
      bool loggedIn = true,
      String locale = 'en',
    }) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      auth = FakeAuthProvider(loggedIn: loggedIn);
      gateway = FakePushGateway();
      service = PushNotificationService(gateway: gateway);
      s = _Server();
      duel = DuelProvider(service: s.server.service);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<ConnectivityProvider>.value(
              value: FakeConnectivity(),
            ),
            ChangeNotifierProvider<DuelProvider>.value(value: duel),
            ChangeNotifierProvider<InvitationLinkProvider>.value(
              value: InvitationLinkProvider(),
            ),
          ],
          child: PushNavigationHost(
            service: service,
            navigatorKey: navigatorKey,
            child: MaterialApp(
              navigatorKey: navigatorKey,
              locale: Locale(locale),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: Text('home-marker')),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await service.dispose();
      });
    }

    Future<void> receive(
      WidgetTester tester, {
      required Map<String, Object?> data,
      String? title = 'Alice t\'attend',
      String? body = 'Rejoins le duel',
    }) async {
      gateway.foreground.add(PushMessage(data: data, title: title, body: body));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    const call = {PushPayloadKeys.type: 'duel_call', PushPayloadKeys.duelId: '5'};
    const accepted = {PushPayloadKeys.type: 'invitation_accepted'};

    testWidgets(
      'duel_call: the calls are refreshed and a banner with the received title and body offers "Join"',
      (tester) async {
        await pumpHost(tester);
        s.open = [_openRow(5, 'waiting', 'alice')];
        expect(s.server.requests, isEmpty);
        await receive(tester, data: call);
        expect(s.duelListCalls, 1);
        expect(duel.openDuels, hasLength(1), reason: 'the list is refreshed');
        expect(find.byKey(_banner), findsOneWidget);
        expect(find.text('Alice t\'attend'), findsOneWidget);
        expect(find.text('Rejoins le duel'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(_bannerAction),
            matching: find.text('Join'),
          ),
          findsOneWidget,
        );
        // At the top of the screen.
        expect(tester.getTopLeft(find.byKey(_banner)).dy, lessThan(100));
      },
    );

    testWidgets('"Join" leads where a tap on the notification leads', (
      tester,
    ) async {
      await pumpHost(tester);
      await receive(tester, data: call);
      await tester.tap(find.byKey(_bannerAction));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      final screen = tester.widget<DuelLiveScreen>(find.byType(DuelLiveScreen));
      expect(screen.duelId, 5);
      expect(find.byKey(_banner), findsNothing);
    });

    testWidgets(
      'invitation_accepted: the opponents are refreshed, "View" opens the duel screen',
      (tester) async {
        await pumpHost(tester);
        s.opponents = [opponentJson(1, 'alice')];
        await receive(
          tester,
          data: accepted,
          title: 'Invitation acceptée',
          body: 'Alice a accepté',
        );
        expect(s.opponentCalls, 1);
        expect(duel.opponents, hasLength(1));
        expect(find.text('Invitation acceptée'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(_bannerAction),
            matching: find.text('View'),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(_bannerAction));
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(find.byType(DuelHubScreen), findsOneWidget);
        expect(find.byKey(_banner), findsNothing);
      },
    );

    testWidgets('the banner buttons speak French on a French phone', (
      tester,
    ) async {
      await pumpHost(tester, locale: 'fr');
      await receive(tester, data: call);
      expect(
        find.descendant(
          of: find.byKey(_bannerAction),
          matching: find.text('Rejoindre'),
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Fermer'), findsOneWidget);
    });

    testWidgets('no "notification" block: refresh only, no banner', (
      tester,
    ) async {
      await pumpHost(tester);
      await receive(tester, data: call, title: null, body: null);
      expect(s.duelListCalls, 1);
      expect(find.byKey(_banner), findsNothing);
    });

    testWidgets('another type: both lists refreshed, no banner', (tester) async {
      await pumpHost(tester);
      await receive(tester, data: {PushPayloadKeys.type: 'who_knows'});
      expect(s.duelListCalls, 1);
      expect(s.opponentCalls, 1);
      expect(find.byKey(_banner), findsNothing);
    });

    testWidgets('signed out: nothing is refreshed, nothing is shown', (
      tester,
    ) async {
      await pumpHost(tester, loggedIn: false);
      await receive(tester, data: call);
      expect(s.server.requests, isEmpty);
      expect(find.byKey(_banner), findsNothing);
    });

    testWidgets('the banner goes away by itself after 10 s, not before', (
      tester,
    ) async {
      await pumpHost(tester);
      await receive(tester, data: call);
      await tester.pump(const Duration(seconds: 9));
      expect(find.byKey(_banner), findsOneWidget);
      await tester.pump(const Duration(seconds: 1, milliseconds: 300));
      expect(find.byKey(_banner), findsNothing);
    });

    testWidgets('the close button closes it; the call stays in the list', (
      tester,
    ) async {
      await pumpHost(tester);
      s.open = [_openRow(5, 'waiting', 'alice')];
      await receive(tester, data: call);
      expect(find.byTooltip('Close'), findsOneWidget);
      await tester.tap(find.byKey(_bannerClose));
      await tester.pump();
      expect(find.byKey(_banner), findsNothing);
      expect(duel.openDuels, hasLength(1));
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('a new notification replaces the banner, and restarts the 10 s', (
      tester,
    ) async {
      await pumpHost(tester);
      await receive(tester, data: call, title: 'first', body: 'one');
      await tester.pump(const Duration(seconds: 8));
      await receive(tester, data: call, title: 'second', body: 'two');
      expect(find.text('first'), findsNothing);
      expect(find.text('second'), findsOneWidget);
      await tester.pump(const Duration(seconds: 8));
      expect(find.byKey(_banner), findsOneWidget, reason: '8 s after the second');
      await tester.pump(const Duration(seconds: 3));
      expect(find.byKey(_banner), findsNothing);
    });

    testWidgets(
      'never over a live duel: refreshed, not shown; shown again once it is left',
      (tester) async {
        await pumpHost(tester);
        gateway.opened.add(call);
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(find.byType(DuelLiveScreen), findsOneWidget);

        final before = s.duelListCalls;
        await receive(tester, data: call);
        expect(find.byKey(_banner), findsNothing);
        expect(s.duelListCalls, greaterThan(before), reason: 'still refreshed');

        navigatorKey.currentState!.pop();
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(find.byType(DuelLiveScreen), findsNothing);
        await receive(tester, data: call);
        expect(find.byKey(_banner), findsOneWidget);
      },
    );

    testWidgets('a banner already showing goes when a live duel opens', (
      tester,
    ) async {
      await pumpHost(tester);
      await receive(tester, data: call);
      expect(find.byKey(_banner), findsOneWidget);
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const DuelLiveScreen(duelId: 5)),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.byKey(_banner), findsNothing);
    });

    testWidgets('the journal tells the kind and whether a banner was shown, nothing else', (
      tester,
    ) async {
      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          lines.add(message ?? '');
      await pumpHost(tester);
      await receive(tester, data: call);
      debugPrint = original;
      final text = lines.join('\n');
      expect(text, contains('[PUSH] Foreground message: duel_call, banner shown'));
      expect(text, isNot(contains('Alice')));
      expect(text, isNot(contains('tester')));
    });
  });

  group('the proposal on the duel screen', () {
    late FakePushGateway gateway;
    late PushNotificationService service;
    late _Server s;

    Future<void> pumpHub(
      WidgetTester tester, {
      PushPermission permission = PushPermission.notDetermined,
      bool alreadyProposed = false,
      List<Map<String, Object?>>? opponents,
    }) async {
      if (alreadyProposed) await PushPromptState().markProposed();
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      gateway = FakePushGateway(permission: permission);
      service = PushNotificationService(gateway: gateway);
      await service.start();
      addTearDown(service.dispose);
      s = _Server()..opponents = opponents ?? [opponentJson(1, 'alice')];
      await tester.pumpWidget(
        PushPromptScope(
          controller: PushPromptController(service: service),
          child: duelApp(
            home: const DuelHubScreen(),
            duel: DuelProvider(service: s.server.service),
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    Finder title() => find.text(_en.pushPromptTitle);

    testWidgets('with an opponent: proposed once; the answer is remembered', (
      tester,
    ) async {
      await pumpHub(tester);
      expect(title(), findsOneWidget);
      await tester.tap(find.text(_en.pushPromptTurnOn));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(gateway.requestCalls, 1);
      expect(await PushPromptState().wasProposed(), isTrue);

      // The screen opens again: never twice.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        PushPromptScope(
          controller: PushPromptController(service: service),
          child: duelApp(
            home: const DuelHubScreen(),
            duel: DuelProvider(service: s.server.service),
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(title(), findsNothing);
    });

    testWidgets('"Not now": the system is not asked, and never again', (
      tester,
    ) async {
      await pumpHub(tester);
      await tester.tap(find.text(_en.pushPromptLater));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(gateway.requestCalls, 0);
      expect(await PushPromptState().wasProposed(), isTrue);
    });

    testWidgets('no opponent: nothing proposed, and not marked as proposed', (
      tester,
    ) async {
      await pumpHub(tester, opponents: []);
      expect(title(), findsNothing);
      expect(await PushPromptState().wasProposed(), isFalse);
    });

    testWidgets('already allowed: nothing', (tester) async {
      await pumpHub(tester, permission: PushPermission.granted);
      expect(title(), findsNothing);
    });

    testWidgets('refused earlier: nothing', (tester) async {
      await pumpHub(tester, permission: PushPermission.denied);
      expect(title(), findsNothing);
    });

    testWidgets('already proposed on this phone: nothing', (tester) async {
      await pumpHub(tester, alreadyProposed: true);
      expect(title(), findsNothing);
      expect(gateway.requestCalls, 0);
    });

    testWidgets('pulling to refresh does not propose again', (tester) async {
      await pumpHub(tester);
      await tester.tap(find.text(_en.pushPromptLater));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(title(), findsNothing);
    });
  });

  group('the 20 s refresh', () {
    late _Server s;
    late FakeConnectivity connectivity;

    Future<void> pumpScreen(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      s = _Server();
      connectivity = FakeConnectivity();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(
              value: FakeAuthProvider(),
            ),
            ChangeNotifierProvider<CatalogProvider>.value(
              value: FakeCatalogProvider(),
            ),
            ChangeNotifierProvider<ConnectivityProvider>.value(
              value: connectivity,
            ),
            ChangeNotifierProvider<DuelProvider>.value(
              value: DuelProvider(service: s.server.service),
            ),
            ChangeNotifierProvider<InvitationLinkProvider>.value(
              value: InvitationLinkProvider(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
    }

    for (final entry in <String, Widget>{
      'home screen': const HomeScreen(),
      'duel screen': const DuelHubScreen(),
    }.entries) {
      testWidgets('${entry.key}: one check every 20 s, only the open-duels route', (
        tester,
      ) async {
        await pumpScreen(tester, entry.value);
        final start = s.duelListCalls;
        await tester.pump(const Duration(seconds: 19));
        expect(s.duelListCalls, start, reason: 'not before 20 s');
        await tester.pump(const Duration(seconds: 1));
        expect(s.duelListCalls, start + 1);
        await tester.pump(const Duration(seconds: 20));
        expect(s.duelListCalls, start + 2);
        await tester.pump(const Duration(seconds: 40));
        expect(s.duelListCalls, start + 4, reason: '3 a minute, no more');
        final others = s.server.requests
            .where((r) => !r.path.endsWith('/duel/duels/'))
            .map((r) => r.path)
            .toSet();
        // Only what the screen already calls when it opens.
        expect(
          others.every((p) => p.endsWith('/duel/opponents/')),
          isTrue,
          reason: '$others',
        );
        expect(
          s.opponentCalls,
          lessThanOrEqualTo(1),
          reason: 'the opponents are not polled',
        );
      });

      testWidgets('${entry.key}: nothing while a screen covers it; again once it is back', (
        tester,
      ) async {
        await pumpScreen(tester, entry.value);
        final context = tester.element(find.byType(Scaffold).first);
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('cover')),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        final covered = s.duelListCalls;
        await tester.pump(const Duration(seconds: 60));
        expect(s.duelListCalls, covered);
        Navigator.of(tester.element(find.text('cover'))).pop();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(seconds: 21));
        expect(s.duelListCalls, greaterThan(covered));
      });

      testWidgets('${entry.key}: nothing in the background; again on return', (
        tester,
      ) async {
        await pumpScreen(tester, entry.value);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        final paused = s.duelListCalls;
        await tester.pump(const Duration(seconds: 90));
        expect(s.duelListCalls, paused);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump(const Duration(seconds: 21));
        expect(s.duelListCalls, greaterThan(paused));
      });

      testWidgets('${entry.key}: nothing offline, and nothing once the screen is gone', (
        tester,
      ) async {
        await pumpScreen(tester, entry.value);
        connectivity.setOnline(false);
        await tester.pump(const Duration(milliseconds: 200));
        final offline = s.duelListCalls;
        await tester.pump(const Duration(seconds: 60));
        expect(s.duelListCalls, offline);
        connectivity.setOnline(true);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpWidget(const SizedBox());
        final gone = s.duelListCalls;
        await tester.pump(const Duration(seconds: 90));
        expect(s.duelListCalls, gone);
      });
    }
  });
}
