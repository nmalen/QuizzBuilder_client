import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/l10n/app_localizations_fr.dart';
import 'package:QuizzBuilder/models/theme.dart' as theme_model;
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/providers/quizz_builder_provider.dart';
import 'package:QuizzBuilder/services/credit_store_service.dart';
import 'package:QuizzBuilder/ui/premium_theme_unlock_screen.dart';

import 'support/duel_test_support.dart';
import 'support/theme_unlock_support.dart';

/// The credit unlock screen: its single-theme mode (opened from a padlock row
/// of the duel challenge screen, QB-C-016) and, unchanged, its old list mode.
final _l = AppLocalizationsEn();
final _lFr = AppLocalizationsFr();

class _Harness {
  _Harness(this.store)
    : builder = FakeCreditBuilder(store),
      catalog = FakeCreditCatalog();

  final FakeCreditStore store;
  final FakeCreditBuilder builder;
  final FakeCreditCatalog catalog;

  /// What the screen closed with (`closed` tells it did).
  bool? result;
  bool closed = false;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Runs [body] with the fake store behind every `http` call.
  Future<void> withStore(
    FakeCreditStore store,
    Future<void> Function() body,
  ) => http.runWithClient(body, () => store.client);

  Future<_Harness> open(
    WidgetTester tester,
    FakeCreditStore store, {
    int? focus,
    String locale = 'en',
    FakeConnectivity? connectivity,
    Size size = const Size(800, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = _Harness(store);
    await tester.pumpWidget(
      creditStoreShell(
        builder: h.builder,
        catalog: h.catalog,
        child: duelApp(
          locale: locale,
          connectivity: connectivity,
          duel: DuelProvider(
            service: FakeDuelServer((_) => jsonResponse(404, null)).service,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  h.result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => PremiumThemeUnlockScreen(
                        duelChallengeThemeId: focus,
                        storeBuilder: (storeContext) => Scaffold(
                          appBar: AppBar(title: const Text('Fake store')),
                          body: TextButton(
                            onPressed: () => Navigator.of(storeContext).pop(),
                            child: const Text('back from store'),
                          ),
                        ),
                      ),
                    ),
                  );
                  h.closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    return h;
  }

  VoidCallback? onPressedOf(WidgetTester tester, String label) =>
      tester
          .widget<ButtonStyleButton>(
            find.ancestor(
              of: find.text(label),
              matching: find.bySubtype<ButtonStyleButton>(),
            ),
          )
          .onPressed;

  group('single-theme mode', () {
    testWidgets('shows that theme alone, with the cost, and nothing of the list', (tester) async {
      final store = FakeCreditStore();
      await withStore(store, () async {
        await open(tester, store, focus: 7);
        expect(find.text(_l.unlockThemeFocusTitle), findsOneWidget);
        expect(find.text(_l.unlockThemeFocusHelp), findsOneWidget);
        expect(find.text('Premium 7'), findsOneWidget);
        expect(find.text('About seven.'), findsOneWidget);
        expect(find.text('Premium 8'), findsNothing);
        expect(find.text(_l.tapLockedThemeToUnlock), findsNothing);
        expect(find.textContaining('Locked premium themes'), findsNothing);
        expect(find.text(_l.unlockThemeAction), findsOneWidget);
        expect(find.byKey(const ValueKey('unlock-open-store')), findsNothing);
      });
    });

    testWidgets('French labels', (tester) async {
      final store = FakeCreditStore();
      await withStore(store, () async {
        await open(tester, store, focus: 7, locale: 'fr');
        expect(find.text('Débloquer ce thème'), findsOneWidget);
        expect(find.text(_lFr.unlockThemeFocusHelp), findsOneWidget);
        expect(find.text('Premium 7 fr'), findsOneWidget);
      });
    });

    testWidgets('unlock sends origin duel_challenge, closes with true, the message follows', (tester) async {
      final store = FakeCreditStore();
      await withStore(store, () async {
        final h = await open(tester, store, focus: 7);
        await tester.tap(find.text(_l.unlockThemeAction));
        await tester.pumpAndSettle();
        expect(store.origins, ['duel_challenge']);
        expect(h.closed, isTrue);
        expect(h.result, isTrue);
        expect(h.catalog.synced, [7]);
        // The snack bar outlives the screen that raised it.
        expect(
          find.text(_l.unlockThemeSuccess('Premium 7', _l.storeQuestionPackCount(2))),
          findsOneWidget,
        );
        expect(find.byType(PremiumThemeUnlockScreen), findsNothing);
      });
    });

    group('no credit', () {
      testWidgets('the reason and the way to the store, no unlock button', (tester) async {
        final store = FakeCreditStore()..balance = 0;
        await withStore(store, () async {
          await open(tester, store, focus: 7);
          expect(find.text(_l.unlockThemeNoCredits), findsOneWidget);
          expect(find.text(_l.openStore), findsOneWidget);
          expect(find.text(_l.unlockThemeAction), findsNothing);
        });
      });

      testWidgets('store, then back: reloaded, the unlock button appears, nothing unlocked by itself', (tester) async {
        final store = FakeCreditStore()..balance = 0;
        await withStore(store, () async {
          final h = await open(tester, store, focus: 7);
          await tester.tap(find.byKey(const ValueKey('unlock-open-store')));
          await tester.pumpAndSettle();
          expect(find.text('Fake store'), findsOneWidget);
          store.balance = 2; // bought in the store
          await tester.tap(find.text('back from store'));
          await tester.pumpAndSettle();
          expect(find.byType(PremiumThemeUnlockScreen), findsOneWidget);
          expect(find.text(_l.unlockThemeAction), findsOneWidget);
          expect(find.text(_l.unlockThemeNoCredits), findsNothing);
          expect(store.unlockCalls, 0);
          expect(h.closed, isFalse);
        });
      });

      testWidgets('theme unlocked from the store meanwhile: the screen closes with true', (tester) async {
        final store = FakeCreditStore()..balance = 0;
        await withStore(store, () async {
          final h = await open(tester, store, focus: 7);
          await tester.tap(find.byKey(const ValueKey('unlock-open-store')));
          await tester.pumpAndSettle();
          store.owned.add(7);
          await tester.tap(find.text('back from store'));
          await tester.pumpAndSettle();
          expect(h.closed, isTrue);
          expect(h.result, isTrue);
          expect(find.text(_l.unlockThemeAlreadyUnlocked('Premium 7')), findsOneWidget);
        });
      });
    });

    group('the server refuses the unlock: state fetched again, never the server text', (() {
      const english = 'Theme already unlocked';

      testWidgets('theme is the player\'s after all: closes with true', (tester) async {
        final store = FakeCreditStore()..unlockError = Exception(english);
        await withStore(store, () async {
          final h = await open(tester, store, focus: 7);
          store.owned.add(7); // the server knew, the app did not
          await tester.tap(find.text(_l.unlockThemeAction));
          await tester.pumpAndSettle();
          expect(h.result, isTrue);
          expect(find.text(_l.unlockThemeAlreadyUnlocked('Premium 7')), findsOneWidget);
          expect(find.textContaining(english), findsNothing);
          expect(find.textContaining('Exception'), findsNothing);
        });
      });

      testWidgets('no credit left: the no-credit state, no message', (tester) async {
        final store = FakeCreditStore()
          ..unlockError = Exception('Insufficient credits. Purchase credits to unlock this theme.');
        await withStore(store, () async {
          final h = await open(tester, store, focus: 7);
          store.balance = 0;
          await tester.tap(find.text(_l.unlockThemeAction));
          await tester.pumpAndSettle();
          expect(h.closed, isFalse);
          expect(find.text(_l.unlockThemeNoCredits), findsOneWidget);
          expect(find.byKey(const ValueKey('unlock-open-store')), findsOneWidget);
          expect(find.byType(SnackBar), findsNothing);
          expect(find.textContaining('Insufficient'), findsNothing);
        });
      });

      testWidgets('state cannot be fetched again: generic message, button back', (tester) async {
        final store = FakeCreditStore()..unlockError = Exception('boom');
        await withStore(store, () async {
          final h = await open(tester, store, focus: 7);
          store.refreshFails = true;
          await tester.tap(find.text(_l.unlockThemeAction));
          await tester.pumpAndSettle();
          expect(h.closed, isFalse);
          expect(find.text(_l.errorGenericTryAgain), findsOneWidget);
          expect(find.textContaining('boom'), findsNothing);
          expect(onPressedOf(tester, _l.unlockThemeAction), isNotNull);
        });
      });

      testWidgets('still locked, credit left, unknown refusal: generic message', (tester) async {
        final store = FakeCreditStore()..unlockError = Exception('anything');
        await withStore(store, () async {
          final h = await open(tester, store, focus: 7);
          await tester.tap(find.text(_l.unlockThemeAction));
          await tester.pumpAndSettle();
          expect(h.closed, isFalse);
          expect(find.text(_l.errorGenericTryAgain), findsOneWidget);
          expect(store.unlockCalls, 1);
        });
      });

      testWidgets('theme gone from the catalog meanwhile: closes with false', (tester) async {
        final store = FakeCreditStore()..unlockError = Exception('Theme not found or inactive');
        await withStore(store, () async {
          final h = await open(tester, store, focus: 7);
          store.catalog[7] = false;
          await tester.tap(find.text(_l.unlockThemeAction));
          await tester.pumpAndSettle();
          expect(h.closed, isTrue);
          expect(h.result, isFalse);
          expect(find.text(_l.unlockThemeUnavailable), findsOneWidget);
          expect(find.textContaining('inactive'), findsNothing);
        });
      });
    }));

    testWidgets('opened on a theme that is gone or inactive: closes with false at once', (tester) async {
      final store = FakeCreditStore()..catalog[7] = false;
      await withStore(store, () async {
        final h = await open(tester, store, focus: 7);
        expect(h.closed, isTrue);
        expect(h.result, isFalse);
        expect(find.text(_l.unlockThemeUnavailable), findsOneWidget);
      });
      final other = FakeCreditStore();
      await withStore(other, () async {
        final h = await open(tester, other, focus: 99);
        expect(h.result, isFalse);
      });
    });

    testWidgets('opened on a theme the player already owns: closes with true at once', (tester) async {
      final store = FakeCreditStore()..owned.add(7);
      await withStore(store, () async {
        final h = await open(tester, store, focus: 7);
        expect(h.closed, isTrue);
        expect(h.result, isTrue);
        expect(find.text(_l.unlockThemeAlreadyUnlocked('Premium 7')), findsOneWidget);
        expect(store.unlockCalls, 0);
      });
    });

    testWidgets('offline: the banner, the button off', (tester) async {
      final store = FakeCreditStore();
      await withStore(store, () async {
        await open(tester, store, focus: 7, connectivity: FakeConnectivity(online: false));
        expect(onPressedOf(tester, _l.unlockThemeAction), isNull);
        expect(store.unlockCalls, 0);
      });
    });
  });

  group('list mode, as it always was', () {
    testWidgets('lists every locked premium theme under the old title', (tester) async {
      final store = FakeCreditStore();
      await withStore(store, () async {
        await open(tester, store);
        expect(find.text(_l.unlockPremiumThemesTitle), findsOneWidget);
        expect(find.text('Premium 7'), findsOneWidget);
        expect(find.text('Premium 8'), findsOneWidget);
        expect(find.text(_l.tapLockedThemeToUnlock), findsOneWidget);
        expect(find.text(_l.unlockThemeFocusHelp), findsNothing);
        expect(find.byType(FilledButton), findsNWidgets(2));
      });
    });

    testWidgets('an unlock sends no origin, the screen stays open, the success message shows', (tester) async {
      final store = FakeCreditStore();
      await withStore(store, () async {
        final h = await open(tester, store);
        await tester.tap(find.text(_l.unlockThemeAction).first);
        await tester.pumpAndSettle();
        expect(store.origins, [null]);
        expect(h.closed, isFalse);
        expect(find.byType(PremiumThemeUnlockScreen), findsOneWidget);
        expect(
          find.text(_l.unlockThemeSuccess('Premium 7', _l.storeQuestionPackCount(2))),
          findsOneWidget,
        );
      });
    });

    testWidgets('a refusal still shows the server text as it is, and the screen stays', (tester) async {
      final store = FakeCreditStore()..unlockError = Exception('Theme already unlocked');
      await withStore(store, () async {
        final h = await open(tester, store);
        await tester.tap(find.text(_l.unlockThemeAction).first);
        await tester.pumpAndSettle();
        expect(find.text('Exception: Theme already unlocked'), findsOneWidget);
        expect(h.closed, isFalse);
        expect(find.text(_l.errorGenericTryAgain), findsNothing);
      });
    });

    testWidgets('without credit the buttons are off and there is no way to the store', (tester) async {
      final store = FakeCreditStore()..balance = 0;
      await withStore(store, () async {
        await open(tester, store);
        expect(find.byKey(const ValueKey('unlock-open-store')), findsNothing);
        expect(find.text(_l.openStore), findsNothing);
        expect(find.text(_l.unlockThemeNoCredits), findsNothing);
        for (final button in tester.widgetList<ButtonStyleButton>(find.byType(FilledButton))) {
          expect(button.onPressed, isNull);
        }
      });
    });

    testWidgets('one already owned: it is not listed', (tester) async {
      final store = FakeCreditStore()..owned.add(7);
      await withStore(store, () async {
        await open(tester, store);
        expect(find.text('Premium 7'), findsNothing);
        expect(find.text('Premium 8'), findsOneWidget);
      });
    });
  });

  group('what goes on the wire', () {
    theme_model.Theme theme() => theme_model.Theme.fromJson({
      'id': 7,
      'category': '1',
      'name_en': 'Premium 7',
      'name_fr': 'Premium 7 fr',
      'is_free': false,
      'is_active': true,
      'questions_count': 47,
    });

    ({MockClient client, List<http.Request> sent}) recorder() {
      final sent = <http.Request>[];
      final client = MockClient((request) async {
        sent.add(request);
        return http.Response(
          jsonEncode({'success': true, 'credits_remaining': 2}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });
      return (client: client, sent: sent);
    }

    test('no origin: the body is {} and carries no origin key at all', () async {
      final r = recorder();
      final service = CreditStoreService(authService: FakeAuthService());
      await http.runWithClient(() => service.unlockThemeWithCredit(7), () => r.client);
      expect(r.sent.single.url.path.endsWith('/themes/7/unlock/'), isTrue);
      expect(r.sent.single.body, '{}');
      expect(jsonDecode(r.sent.single.body), isNot(contains('origin')));
    });

    test('origin duel_challenge: sent as such', () async {
      final r = recorder();
      final service = CreditStoreService(authService: FakeAuthService());
      await http.runWithClient(
        () => service.unlockThemeWithCredit(7, origin: 'duel_challenge'),
        () => r.client,
      );
      expect(jsonDecode(r.sent.single.body), {'origin': 'duel_challenge'});
    });

    test('the provider hands the origin to the service, or none', () async {
      // The provider also writes the entitlements to the local database,
      // which has no plugin here (a missing plugin or an uninitialised
      // database factory): those failures are the only ones allowed.
      final errors = <Object>[];
      for (final origin in <String?>[null, 'duel_challenge']) {
        final r = recorder();
        await runZonedGuarded(
          () => http.runWithClient(() async {
            final builder = QuizzBuilderProvider(authService: FakeAuthService());
            final remaining = await builder.unlockThemeWithCredit(theme(), origin: origin);
            expect(remaining, 2);
          }, () => r.client),
          (e, _) => errors.add(e),
        );
        expect(
          jsonDecode(r.sent.single.body),
          origin == null ? <String, dynamic>{} : {'origin': origin},
        );
      }
      expect(
        errors.every((e) => e is MissingPluginException || e is StateError),
        isTrue,
        reason: '$errors',
      );
    });
  });
}
