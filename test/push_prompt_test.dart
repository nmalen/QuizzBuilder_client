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
import 'package:QuizzBuilder/providers/language_provider.dart';
import 'package:QuizzBuilder/services/push/push_gateway.dart';
import 'package:QuizzBuilder/services/push/push_notification_service.dart';
import 'package:QuizzBuilder/services/push/push_prompt_state.dart';
import 'package:QuizzBuilder/ui/auth_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_invite_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_join_confirm_screen.dart';
import 'package:QuizzBuilder/ui/home_screen.dart';
import 'package:QuizzBuilder/ui/push_permission_prompt.dart';

import 'support/app_test_support.dart';
import 'support/duel_test_support.dart';
import 'support/push_test_support.dart';

/// QB-C-020 step 2: the one-time "turn on notifications?" proposal, shown in
/// context before the system prompt. Nothing loads Firebase.
final _en = AppLocalizationsEn();
final _fr = AppLocalizationsFr();

class _RecordingAuth extends FakeAuthProvider {
  _RecordingAuth() : super(loggedIn: false);
  bool succeed = true;

  @override
  Future<bool> register({
    required String email,
    required String username,
    required String password1,
    required String password2,
    String? invitationCode,
    bool newsEmailsOptIn = false,
  }) async => succeed;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late FakePushGateway gateway;
  late PushNotificationService service;
  late PushPromptController controller;

  /// A started service on a scripted gateway, and its prompt controller.
  Future<void> setUpPush(
    WidgetTester tester, {
    PushPermission permission = PushPermission.notDetermined,
    PushPermission answer = PushPermission.granted,
    bool failInit = false,
  }) async {
    gateway = FakePushGateway(
      permission: permission,
      requestAnswer: answer,
      failInit: failInit,
    );
    service = PushNotificationService(gateway: gateway);
    await service.start();
    controller = PushPromptController(service: service);
    addTearDown(service.dispose);
  }

  Widget shell({
    required Widget home,
    String locale = 'en',
    AuthProvider? auth,
    DuelProvider? duel,
    bool withPrompt = true,
  }) {
    final app = MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth ?? FakeAuthProvider(),
        ),
        ChangeNotifierProvider<ConnectivityProvider>.value(
          value: FakeConnectivity(),
        ),
        ChangeNotifierProvider<DuelProvider>.value(
          value:
              duel ??
              DuelProvider(
                service: FakeDuelServer(
                  (r) => jsonResponse(200, {'count': 0, 'results': []}),
                ).service,
              ),
        ),
        ChangeNotifierProvider<InvitationLinkProvider>.value(
          value: InvitationLinkProvider(),
        ),
        ChangeNotifierProvider<CatalogProvider>.value(
          value: FakeCatalogProvider(),
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
        home: home,
      ),
    );
    return withPrompt
        ? PushPromptScope(controller: controller, child: app)
        : app;
  }

  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// A bare screen; returns a context under the MaterialApp.
  Future<BuildContext> pumpBare(
    WidgetTester tester, {
    String locale = 'en',
  }) async {
    late BuildContext context;
    await tester.pumpWidget(
      shell(
        locale: locale,
        home: Builder(
          builder: (c) {
            context = c;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );
    return context;
  }

  Future<void> frames(WidgetTester tester, [int n = 4]) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<bool> proposed() => PushPromptState().wasProposed();

  Finder title([AppLocalizations? l]) => find.text((l ?? _en).pushPromptTitle);

  group('the proposal itself', () {
    test('words: FR and EN, as validated', () {
      expect(_fr.pushPromptTitle, 'Activer les notifications ?');
      expect(
        _fr.pushPromptBody,
        "Active les notifications pour savoir quand un proche t'attend pour un duel ou accepte ton invitation, même si l'app est fermée.",
      );
      expect(_fr.pushPromptTurnOn, 'Activer');
      expect(_fr.pushPromptLater, 'Plus tard');
      expect(_en.pushPromptTitle, 'Turn on notifications?');
      expect(
        _en.pushPromptBody,
        'Turn on notifications to know when a friend is waiting for you in a duel or accepts your invitation, even when the app is closed.',
      );
      expect(_en.pushPromptTurnOn, 'Turn on');
      expect(_en.pushPromptLater, 'Not now');
    });

    testWidgets(
      '"Turn on": the system is asked once, the installation ID is asked for, never shown again',
      (tester) async {
        await setUpPush(tester);
        final context = await pumpBare(tester);
        unawaited(controller.propose(context));
        await frames(tester);
        expect(title(), findsOneWidget);
        expect(find.text(_en.pushPromptBody), findsOneWidget);
        expect(
          gateway.requestCalls,
          0,
          reason: 'nothing before the player answers',
        );
        expect(service.installationId, isNull);

        await tester.tap(find.text(_en.pushPromptTurnOn));
        await frames(tester);
        expect(gateway.requestCalls, 1);
        expect(
          service.installationId,
          fakeInstallationId,
          reason: 'installation ID asked for once allowed',
        );
        expect(await proposed(), isTrue);
        expect(title(), findsNothing);

        unawaited(controller.propose(context));
        await frames(tester);
        expect(title(), findsNothing, reason: 'once in total');
        expect(gateway.requestCalls, 1);
      },
    );

    testWidgets(
      '"Not now": the system is never asked, and never proposed again',
      (tester) async {
        await setUpPush(tester);
        final context = await pumpBare(tester);
        unawaited(controller.propose(context));
        await frames(tester);
        await tester.tap(find.text(_en.pushPromptLater));
        await frames(tester);
        expect(gateway.requestCalls, 0);
        expect(service.installationId, isNull);
        expect(await proposed(), isTrue);

        unawaited(controller.propose(context));
        await frames(tester);
        expect(title(), findsNothing);
      },
    );

    testWidgets('a refusal in the system window is not asked again', (
      tester,
    ) async {
      await setUpPush(tester, answer: PushPermission.denied);
      final context = await pumpBare(tester);
      unawaited(controller.propose(context));
      await frames(tester);
      await tester.tap(find.text(_en.pushPromptTurnOn));
      await frames(tester);
      expect(gateway.requestCalls, 1);
      expect(service.installationId, isNull, reason: 'no permission, no installation ID');

      unawaited(controller.propose(context));
      await frames(tester);
      expect(title(), findsNothing);
      expect(gateway.requestCalls, 1);
    });

    testWidgets(
      'Android 12 and older (always allowed): no window, the installation ID is already known',
      (tester) async {
        await setUpPush(tester, permission: PushPermission.granted);
        expect(service.installationId, fakeInstallationId);
        final context = await pumpBare(tester);
        unawaited(controller.propose(context));
        await frames(tester);
        expect(title(), findsNothing);
        expect(gateway.requestCalls, 0);
      },
    );

    testWidgets('already refused, or no provider: nothing to propose', (
      tester,
    ) async {
      await setUpPush(tester, permission: PushPermission.denied);
      var context = await pumpBare(tester);
      unawaited(controller.propose(context));
      await frames(tester);
      expect(title(), findsNothing);

      await setUpPush(tester, failInit: true);
      context = await pumpBare(tester);
      unawaited(controller.propose(context));
      await frames(tester);
      expect(title(), findsNothing);
      expect(gateway.requestCalls, 0);
    });

    testWidgets('French app: the window is in French', (tester) async {
      await setUpPush(tester);
      final context = await pumpBare(tester, locale: 'fr');
      unawaited(controller.propose(context));
      await frames(tester);
      expect(title(_fr), findsOneWidget);
      expect(find.text(_fr.pushPromptTurnOn), findsOneWidget);
      expect(find.text(_fr.pushPromptLater), findsOneWidget);
    });
  });

  group('moment A: an invitation was created', () {
    testWidgets('the window shows once the code is displayed', (tester) async {
      await setUpPush(tester);
      final server = FakeDuelServer((r) => jsonResponse(201, invitationJson()));
      await tester.pumpWidget(
        shell(
          home: const DuelInviteScreen(),
          duel: DuelProvider(service: server.service),
        ),
      );
      await frames(tester);
      expect(find.byKey(const Key('invitation-code')), findsOneWidget);
      expect(title(), findsOneWidget);
      await tester.tap(find.text(_en.pushPromptLater));
      await frames(tester);
      expect(title(), findsNothing);
      expect(
        find.byKey(const Key('invitation-code')),
        findsOneWidget,
        reason: 'the code stays',
      );
    });

    testWidgets('without the prompt scope (every other test): nothing', (
      tester,
    ) async {
      await setUpPush(tester);
      final server = FakeDuelServer((r) => jsonResponse(201, invitationJson()));
      await tester.pumpWidget(
        shell(
          home: const DuelInviteScreen(),
          duel: DuelProvider(service: server.service),
          withPrompt: false,
        ),
      );
      await frames(tester);
      expect(title(), findsNothing);
    });
  });

  group('moment B: an invitation was accepted', () {
    testWidgets(
      'the window shows before leaving the confirmation, then the screen closes',
      (tester) async {
        await setUpPush(tester);
        final server = FakeDuelServer((r) {
          if (r.method == 'GET') {
            return jsonResponse(200, {
              'inviter_username': 'alice',
              'expires_at': '2026-11-13T10:00:00Z',
            });
          }
          return jsonResponse(201, opponentJson(5, 'alice'));
        });
        await tester.pumpWidget(
          shell(
            duel: DuelProvider(service: server.service),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const DuelJoinConfirmScreen(code: 'K7P3QX'),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await frames(tester);
        await tester.tap(find.text(_en.duelAccept));
        await frames(tester);
        expect(title(), findsOneWidget);
        expect(
          find.byType(DuelJoinConfirmScreen),
          findsOneWidget,
          reason: 'still there until answered',
        );
        // The confirmation screen has its own "Not now": aim at the window.
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(_en.pushPromptLater),
          ),
        );
        await frames(tester, 6);
        expect(find.byType(DuelJoinConfirmScreen), findsNothing);
      },
    );
  });

  group(
    'invited at sign-up (no "join" screen): the window is for the home screen',
    () {
      Future<void> register(WidgetTester tester, {String? code}) async {
        bigScreen(tester);
        await setUpPush(tester);
        await tester.pumpWidget(
          shell(home: const AuthScreen(), auth: _RecordingAuth()),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(_en.register));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, _en.email),
          'a@b.co',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, _en.username),
          'abcd',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, _en.password),
          '12345678',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, _en.confirmPassword),
          '12345678',
        );
        if (code != null) {
          await tester.enterText(
            find.widgetWithText(TextFormField, _en.invitationCodeOptional),
            code,
          );
        }
        await tester.tap(find.widgetWithText(ElevatedButton, _en.register));
        await tester.pumpAndSettle();
      }

      testWidgets(
        'signing up WITH a code remembers it; no window on the sign-up screen',
        (tester) async {
          await register(tester, code: 'k7p-3qx');
          expect(await PushPromptState().isInviteePending(), isTrue);
          expect(title(), findsNothing);
        },
      );

      testWidgets('signing up without a code remembers nothing', (
        tester,
      ) async {
        await register(tester);
        expect(await PushPromptState().isInviteePending(), isFalse);
      });

      testWidgets('the home screen shows the window once, then forgets', (
        tester,
      ) async {
        bigScreen(tester);
        await setUpPush(tester);
        SharedPreferences.setMockInitialValues({
          PushPromptState.inviteePendingKey: true,
        });
        await tester.pumpWidget(shell(home: const HomeScreen()));
        await frames(tester);
        expect(title(), findsOneWidget);
        await tester.tap(find.text(_en.pushPromptLater));
        await frames(tester);
        expect(await PushPromptState().isInviteePending(), isFalse);
        expect(await proposed(), isTrue);

        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(shell(home: const HomeScreen()));
        await frames(tester);
        expect(title(), findsNothing, reason: 'once in total');
      });

      testWidgets('the home screen of anyone else proposes nothing', (
        tester,
      ) async {
        bigScreen(tester);
        await setUpPush(tester);
        await tester.pumpWidget(shell(home: const HomeScreen()));
        await frames(tester);
        expect(title(), findsNothing);
      });
    },
  );
}
