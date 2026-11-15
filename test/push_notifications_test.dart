import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/connectivity_provider.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/providers/invitation_link_provider.dart';
import 'package:QuizzBuilder/services/push/push_notification_service.dart';
import 'package:QuizzBuilder/services/push/push_payload.dart';
import 'package:QuizzBuilder/ui/duel/duel_hub_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_live_screen.dart';
import 'package:QuizzBuilder/ui/push_navigation_host.dart';

import 'support/duel_live_support.dart';
import 'support/duel_test_support.dart';
import 'support/push_test_support.dart';

/// QB-C-020 step 1: the push service and what a tapped notification opens.
/// Nothing here loads Firebase: the provider is a fake.

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('payload', () {
    test(
      'duel_call with a duel id leads to the waiting room (string or int id)',
      () {
        expect(
          parsePushPayload({
            PushPayloadKeys.type: 'duel_call',
            PushPayloadKeys.duelId: '42',
          }),
          isA<DuelCallDestination>().having((d) => d.duelId, 'duelId', 42),
        );
        expect(
          parsePushPayload({
            PushPayloadKeys.type: 'duel_call',
            PushPayloadKeys.duelId: 7,
          }),
          isA<DuelCallDestination>().having((d) => d.duelId, 'duelId', 7),
        );
      },
    );

    test('invitation_accepted leads to the duel hub', () {
      expect(
        parsePushPayload({
          PushPayloadKeys.type: 'invitation_accepted',
          PushPayloadKeys.pairId: '3',
        }),
        isA<InvitationAcceptedDestination>(),
      );
    });

    test(
      'unknown type, missing or bad field, no data: home, never an error',
      () {
        for (final data in <Map<String, Object?>?>[
          null,
          {},
          {PushPayloadKeys.type: 'something_new'},
          {PushPayloadKeys.type: 'duel_call'},
          {PushPayloadKeys.type: 'duel_call', PushPayloadKeys.duelId: 'abc'},
          {PushPayloadKeys.type: 'duel_call', PushPayloadKeys.duelId: '0'},
          {PushPayloadKeys.type: 'duel_call', PushPayloadKeys.duelId: null},
          {PushPayloadKeys.duelId: '5'},
        ]) {
          expect(
            parsePushPayload(data),
            isA<HomeDestination>(),
            reason: '$data',
          );
        }
      },
    );
  });

  group('service', () {
    test(
      'start() never asks for the permission and asks for no installation ID without it',
      () async {
        final gateway = FakePushGateway(authorized: false);
        final service = PushNotificationService(gateway: gateway);
        await service.start();
        expect(gateway.initCalls, 1);
        expect(gateway.registerCalls, 0);
        expect(service.installationId, isNull);
        await service.dispose();
      },
    );

    test(
      'with the permission granted, the installation ID is kept in memory',
      () async {
        final gateway = FakePushGateway(authorized: true);
        final service = PushNotificationService(gateway: gateway);
        final seen = <String?>[];
        service.installationIdChanges.listen(seen.add);
        await service.start();
        expect(service.installationId, fakeInstallationId);
        await pumpEventQueue();
        expect(seen, [fakeInstallationId]);
        await service.dispose();
      },
    );

    test(
      'an ID handed out by the provider is followed, and still needs the permission',
      () async {
        final gateway = FakePushGateway(authorized: false);
        final service = PushNotificationService(gateway: gateway);
        final seen = <String?>[];
        service.installationIdChanges.listen(seen.add);
        await service.start();
        gateway.refreshes.add('fid-handed-out-fictional');
        await pumpEventQueue();
        expect(
          service.installationId,
          isNull,
          reason: 'no permission, no installation ID',
        );
        gateway.authorized = true;
        gateway.refreshes.add('fid-handed-out-fictional');
        await pumpEventQueue();
        expect(service.installationId, 'fid-handed-out-fictional');
        gateway.refreshes.add('fid-changed-fictional');
        await pumpEventQueue();
        expect(service.installationId, 'fid-changed-fictional');
        expect(seen, ['fid-handed-out-fictional', 'fid-changed-fictional']);
        await service.dispose();
      },
    );

    test(
      'the provider gives no ID (it failed): what is known is kept, nothing breaks',
      () async {
        final gateway = FakePushGateway(authorized: true);
        final service = PushNotificationService(gateway: gateway);
        await service.start();
        expect(service.installationId, fakeInstallationId);
        gateway.installationId = null;
        await service.refreshInstallationId();
        expect(service.installationId, fakeInstallationId);
        await service.dispose();
      },
    );

    test('the permission taken away clears the ID', () async {
      final gateway = FakePushGateway(authorized: true);
      final service = PushNotificationService(gateway: gateway);
      await service.start();
      gateway.authorized = false;
      await service.refreshInstallationId();
      expect(service.installationId, isNull);
      await service.dispose();
    });

    test(
      'refreshInstallationId() picks the installation ID up once the player allowed notifications',
      () async {
        final gateway = FakePushGateway(authorized: false);
        final service = PushNotificationService(gateway: gateway);
        await service.start();
        expect(service.installationId, isNull);
        gateway.authorized = true;
        await service.refreshInstallationId();
        expect(service.installationId, fakeInstallationId);
        await service.dispose();
      },
    );

    test('the installation ID never reaches a log', () async {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          logs.add(message ?? '');
      addTearDown(() => debugPrint = original);
      final gateway = FakePushGateway(authorized: true);
      final service = PushNotificationService(gateway: gateway);
      await service.start();
      gateway.refreshes.add('renewed');
      await pumpEventQueue();
      expect(logs.join('\n'), isNot(contains(fakeInstallationId)));
      await service.dispose();
    });

    test(
      'a provider that fails to start leaves the app working: no installation ID, no destination',
      () async {
        final gateway = FakePushGateway(
          authorized: true,
          failInit: true,
          initial: {PushPayloadKeys.type: 'duel_call'},
        );
        final service = PushNotificationService(gateway: gateway);
        final out = <PushDestination>[];
        service.destinations.listen(out.add);
        await service.start();
        await pumpEventQueue();
        expect(service.installationId, isNull);
        expect(out, isEmpty);
        await service.dispose();
      },
    );

    test(
      'app killed: the notification that started the app comes out, once',
      () async {
        final gateway = FakePushGateway(
          initial: {
            PushPayloadKeys.type: 'duel_call',
            PushPayloadKeys.duelId: '9',
          },
        );
        final service = PushNotificationService(gateway: gateway);
        final out = <PushDestination>[];
        service.destinations.listen(out.add);
        await service.start();
        await service.start();
        await pumpEventQueue();
        expect(out, hasLength(1));
        expect((out.single as DuelCallDestination).duelId, 9);
        await service.dispose();
      },
    );

    test('app in the background: a tapped notification comes out', () async {
      final gateway = FakePushGateway();
      final service = PushNotificationService(gateway: gateway);
      final out = <PushDestination>[];
      service.destinations.listen(out.add);
      await service.start();
      gateway.opened.add({PushPayloadKeys.type: 'invitation_accepted'});
      gateway.opened.add({PushPayloadKeys.type: 'who_knows'});
      await pumpEventQueue();
      expect(out.map((d) => d.runtimeType), [
        InvitationAcceptedDestination,
        HomeDestination,
      ]);
      await service.dispose();
    });
  });

  group('navigation host', () {
    late FakeAuthProvider auth;
    late FakePushGateway gateway;
    late PushNotificationService service;
    final navigatorKey = GlobalKey<NavigatorState>();

    Future<void> pumpHost(
      WidgetTester tester, {
      FakeAuthProvider? withAuth,
      Map<String, Object?>? initial,
    }) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      auth = withAuth ?? FakeAuthProvider();
      gateway = FakePushGateway(initial: initial);
      service = PushNotificationService(gateway: gateway);
      final server = FakeDuelServer((r) {
        if (r.method == 'GET' &&
            RegExp(r'/duel/duels/\d+/$').hasMatch(r.path)) {
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
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<ConnectivityProvider>.value(
              value: FakeConnectivity(),
            ),
            ChangeNotifierProvider<DuelProvider>.value(
              value: DuelProvider(service: server.service),
            ),
            ChangeNotifierProvider<InvitationLinkProvider>.value(
              value: InvitationLinkProvider(),
            ),
          ],
          child: PushNavigationHost(
            service: service,
            navigatorKey: navigatorKey,
            child: MaterialApp(
              navigatorKey: navigatorKey,
              locale: const Locale('en'),
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

    /// A few frames: the navigation happens after the frame that follows the tap.
    Future<void> frames(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    testWidgets('duel_call opens the waiting room of that duel', (
      tester,
    ) async {
      await pumpHost(tester);
      gateway.opened.add({
        PushPayloadKeys.type: 'duel_call',
        PushPayloadKeys.duelId: '5',
      });
      await frames(tester);
      final screen = tester.widget<DuelLiveScreen>(find.byType(DuelLiveScreen));
      expect(screen.duelId, 5);
    });

    testWidgets('invitation_accepted opens the duel hub', (tester) async {
      await pumpHost(tester);
      gateway.opened.add({PushPayloadKeys.type: 'invitation_accepted'});
      await frames(tester);
      expect(find.byType(DuelHubScreen), findsOneWidget);
    });

    testWidgets(
      'an unknown type comes back to the home screen, without error',
      (tester) async {
        await pumpHost(tester);
        gateway.opened.add({PushPayloadKeys.type: 'invitation_accepted'});
        await frames(tester);
        expect(find.byType(DuelHubScreen), findsOneWidget);
        gateway.opened.add({PushPayloadKeys.type: 'who_knows'});
        await frames(tester);
        await frames(tester); // the pop transition
        expect(find.byType(DuelHubScreen), findsNothing);
        expect(find.text('home-marker'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'app killed: the notification that started the app opens once the session is known',
      (tester) async {
        final auth = FakeAuthProvider(initialized: false);
        await pumpHost(
          tester,
          withAuth: auth,
          initial: {
            PushPayloadKeys.type: 'duel_call',
            PushPayloadKeys.duelId: '5',
          },
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          find.byType(DuelLiveScreen),
          findsNothing,
          reason: 'the session is not known yet',
        );
        auth.setState(initialized: true);
        await frames(tester);
        expect(find.byType(DuelLiveScreen), findsOneWidget);
      },
    );

    testWidgets('signed out: the notification opens nothing', (tester) async {
      await pumpHost(tester, withAuth: FakeAuthProvider(loggedIn: false));
      gateway.opened.add({
        PushPayloadKeys.type: 'duel_call',
        PushPayloadKeys.duelId: '5',
      });
      await frames(tester);
      expect(find.byType(DuelLiveScreen), findsNothing);
      expect(find.text('home-marker'), findsOneWidget);
    });
  });
}
