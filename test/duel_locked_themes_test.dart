import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/l10n/app_localizations_fr.dart';
import 'package:QuizzBuilder/models/duel.dart';
import 'package:QuizzBuilder/models/duel_live.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/ui/duel/duel_challenge_screen.dart';
import 'package:QuizzBuilder/ui/premium_theme_unlock_screen.dart';

import 'support/duel_live_support.dart';
import 'support/duel_test_support.dart';
import 'support/theme_unlock_support.dart';

/// QB-C-016: the premium themes neither player owns, on the challenge screen,
/// with a padlock; touching one opens the unlock screen on that theme.
final _l = AppLocalizationsEn();
final _lFr = AppLocalizationsFr();

const _opponent = Opponent(id: 3, username: 'alice');

Map<String, Object?> _theme(
  int id,
  String en,
  String fr,
  int category,
  String categoryEn,
  String categoryFr,
  int easy,
  int medium,
  int hard, {
  bool? locked,
}) => {
  'id': id,
  'name_en': en,
  'name_fr': fr,
  'category_id': category,
  'category_name_en': categoryEn,
  'category_name_fr': categoryFr,
  'question_counts': {'easy': easy, 'medium': medium, 'hard': hard},
  if (locked != null) 'is_locked': locked,
};

/// Capitals (free, easy + medium), Oceans (premium 7, hard only), Rome (free,
/// easy only), Cold War (premium 8, alone in its category).
List<Map<String, Object?>> _mixed({
  bool oceansLocked = true,
  bool capitalsLocked = false,
}) => [
  _theme(10, 'Capitals', 'Capitales', 1, 'Geography', 'Géographie', 12, 8, 0, locked: capitalsLocked),
  _theme(7, 'Oceans', 'Océans', 1, 'Geography', 'Géographie', 0, 0, 30, locked: oceansLocked),
  _theme(20, 'Rome', 'Rome', 2, 'History', 'Histoire', 6, 0, 0, locked: false),
  _theme(8, 'Cold War', 'Guerre froide', 3, 'Modern history', 'Histoire moderne', 5, 5, 5, locked: true),
];

class _FlakyConnectivity extends FakeConnectivity {
  /// The next read says offline (the guard of a touch, not a build).
  bool offlineOnNextRead = false;

  @override
  bool get isOnline {
    if (offlineOnNextRead) {
      offlineOnNextRead = false;
      return false;
    }
    return super.isOnline;
  }
}

class _Server {
  _Server() {
    server = FakeDuelServer((r) {
      if (r.method == 'GET' && r.path.endsWith('/opponents/3/themes/')) {
        themeCalls++;
        return themesResponse(themeCalls);
      }
      if (r.method == 'POST' && r.path.endsWith('/duel/duels/')) {
        return createResponse(r);
      }
      if (r.method == 'GET' && r.path.contains('/duel/duels/')) {
        return jsonResponse(
          200,
          duelJson(id: 1, serverTime: FakeClock.base, callLink: 'https://play.quizzbuilder.fr/d/ABCD2345'),
        );
      }
      return jsonResponse(404, null);
    });
  }

  late final FakeDuelServer server;
  int themeCalls = 0;

  /// The list, by call number (1 = first load).
  http.Response Function(int call) themesResponse = (_) =>
      jsonResponse(200, {'count': 4, 'results': _mixed()});
  http.Response Function(RecordedRequest) createResponse = (r) => jsonResponse(
    201,
    duelJson(serverTime: FakeClock.base, callLink: 'https://play.quizzbuilder.fr/d/ABCD2345'),
  );

  Iterable<RecordedRequest> get themeRequests =>
      server.requests.where((r) => r.method == 'GET' && r.path.endsWith('/themes/'));

  Map<String, dynamic> get createBody =>
      jsonDecode(server.requests.singleWhere((r) => r.method == 'POST').body)
          as Map<String, dynamic>;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('DuelTheme: is_locked absent, null or not true reads as not locked', () {
    DuelTheme parse(Map<String, Object?> j) => DuelTheme.fromJson(j);
    expect(parse(_theme(1, 'A', 'A', 1, 'C', 'C', 1, 1, 1)).isLocked, isFalse);
    expect(parse({..._theme(1, 'A', 'A', 1, 'C', 'C', 1, 1, 1), 'is_locked': null}).isLocked, isFalse);
    expect(parse({..._theme(1, 'A', 'A', 1, 'C', 'C', 1, 1, 1), 'is_locked': 'yes'}).isLocked, isFalse);
    expect(parse(_theme(1, 'A', 'A', 1, 'C', 'C', 1, 1, 1, locked: false)).isLocked, isFalse);
    expect(parse(_theme(1, 'A', 'A', 1, 'C', 'C', 1, 1, 1, locked: true)).isLocked, isTrue);
  });

  test('listThemes: include_locked=1 only when asked', () async {
    final s = _Server();
    await s.server.service.listThemes(3);
    await s.server.service.listThemes(3, includeLocked: true);
    expect(s.themeRequests.map((r) => r.query).toList(), ['', 'include_locked=1']);
  });

  /// Pumps the challenge screen, with the credit store behind it.
  Future<({_Server server, FakeCreditStore store, FakeCreditBuilder builder, FakeCreditCatalog catalog})> pump(
    WidgetTester tester, {
    FakeCreditStore? store,
    FakeConnectivity? connectivity,
    String locale = 'en',
    Size size = const Size(800, 2400),
    double textScale = 1,
    void Function(_Server)? configure,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final s = _Server();
    configure?.call(s);
    final st = store ?? FakeCreditStore();
    final builder = FakeCreditBuilder(st);
    final catalog = FakeCreditCatalog();
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
        child: creditStoreShell(
          builder: builder,
          catalog: catalog,
          child: duelApp(
            locale: locale,
            connectivity: connectivity,
            duel: DuelProvider(service: s.server.service),
            home: const DuelChallengeScreen(opponent: _opponent),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    return (server: s, store: st, builder: builder, catalog: catalog);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pump();
  }

  bool startEnabled(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byKey(const ValueKey('start-challenge'))).onPressed != null;

  /// Runs [body] with the fake credit store behind every `http` call.
  Future<void> withStore(FakeCreditStore store, Future<void> Function() body) =>
      http.runWithClient(body, () => store.client);

  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();

  group('the list', () {
    testWidgets('padlock rows, mixed in their category, never a box; the hint; the request', (tester) async {
      final r = await pump(tester);
      expect(r.server.themeRequests.single.query, 'include_locked=1');
      expect(find.byIcon(Icons.lock), findsNWidgets(2));
      expect(find.text(_l.duelThemeLockedSubtitle), findsNWidgets(2));
      expect(find.text(_l.duelThemesLockedHint), findsOneWidget);
      // Boxes only on the playable themes.
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      expect(find.byKey(const ValueKey('theme-10')), findsOneWidget);
      expect(find.byKey(const ValueKey('theme-20')), findsOneWidget);
      expect(find.byKey(const ValueKey('theme-7')), findsNothing);
      expect(find.byKey(const ValueKey('locked-theme-7')), findsOneWidget);
      // Server order kept inside the category: Capitals, then Oceans.
      expect(
        tester.getTopLeft(find.text('Capitals')).dy < tester.getTopLeft(find.text('Oceans')).dy,
        isTrue,
      );
      // A category holding only padlock rows is shown like the others.
      expect(find.text('Modern history'), findsOneWidget);
      expect(find.text('Cold War'), findsOneWidget);
      expect(find.byKey(const ValueKey('locked-theme-8')), findsOneWidget);
      expect(find.text(_l.duelThemesChosen(0)), findsOneWidget);
    });

    testWidgets('French labels', (tester) async {
      await pump(tester, locale: 'fr');
      expect(find.text(_lFr.duelThemesLockedHint), findsOneWidget);
      expect(find.text('Thème premium'), findsNWidgets(2));
      expect(find.text('Océans'), findsOneWidget);
      expect(find.text('Guerre froide'), findsOneWidget);
    });

    testWidgets('no padlock from the server: the screen is what it was, no hint', (tester) async {
      final r = await pump(
        tester,
        configure: (s) => s.themesResponse = (_) => jsonResponse(200, {
          'count': 2,
          'results': [
            for (final t in _mixed().where((t) => t['id'] == 10 || t['id'] == 20))
              {...t}..remove('is_locked'),
          ],
        }),
      );
      expect(find.byIcon(Icons.lock), findsNothing);
      expect(find.text(_l.duelThemesLockedHint), findsNothing);
      expect(find.text(_l.duelThemeLockedSubtitle), findsNothing);
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      expect(r.server.themeCalls, 1);
    });

    testWidgets('screen reader: one button, the name, locked, how to unlock', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      final node = tester.getSemantics(find.byKey(const ValueKey('locked-theme-7')));
      expect(node.label, _l.duelThemeLockedSemantics('Oceans'));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('a padlock theme never enters the difficulties, the counts, the recap or the request', (tester) async {
      final r = await pump(tester);
      // Oceans has the only hard questions: Hard is not offered.
      expect(find.byKey(const ValueKey('difficulty-hard')), findsNothing);
      expect(find.byKey(const ValueKey('difficulty-easy')), findsOneWidget);
      await tapKey(tester, 'theme-20'); // Rome: 6 questions, easy only
      // Only 6 questions: just the count of 5 can be served (Oceans' 30 do not help).
      expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('count-10'))).onSelected, isNull);
      expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('count-5'))).onSelected, isNotNull);
      await tapKey(tester, 'theme-10');
      // 5, not 10: ticking Rome alone left room for 5 only, and the count
      // does not climb back by itself (the rule of the screen, unchanged).
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('challenge-recap'))).data,
        _l.duelRoomSummary(5, 10, '${_l.easy}, ${_l.medium}'),
      );
      expect(find.text(_l.duelThemesChosen(2)), findsOneWidget);
      await tapKey(tester, 'start-challenge');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));
      expect(r.server.createBody['themes'], [10, 20]);
      expect(r.server.createBody['difficulties'], ['easy', 'medium']);
    });

    testWidgets('only padlock themes: the explanation and the list, no settings, no bar', (tester) async {
      await pump(
        tester,
        configure: (s) => s.themesResponse = (_) => jsonResponse(200, {
          'count': 2,
          'results': [
            for (final t in _mixed().where((t) => t['id'] == 7 || t['id'] == 8)) t,
          ],
        }),
      );
      expect(find.text(_l.duelOnlyLockedThemes('alice')), findsOneWidget);
      expect(find.text(_l.duelNoPlayableThemes), findsNothing);
      expect(find.text(_l.duelDifficultiesSection), findsNothing);
      expect(find.text(_l.duelQuestionCountSection), findsNothing);
      expect(find.text(_l.duelSecondsSection), findsNothing);
      expect(find.byKey(const ValueKey('start-challenge')), findsNothing);
      expect(find.byKey(const ValueKey('challenge-recap')), findsNothing);
      expect(find.byKey(const ValueKey('locked-theme-7')), findsOneWidget);
      expect(find.byKey(const ValueKey('locked-theme-8')), findsOneWidget);
      expect(find.text(_l.duelThemesLockedHint), findsOneWidget);
      expect(find.text(_l.duelThemesSection), findsOneWidget);
    });

    testWidgets('only padlock themes, in French', (tester) async {
      await pump(
        tester,
        locale: 'fr',
        configure: (s) => s.themesResponse = (_) => jsonResponse(200, {
          'count': 1,
          'results': [_mixed()[1]],
        }),
      );
      expect(find.text(_lFr.duelOnlyLockedThemes('alice')), findsOneWidget);
    });

    testWidgets('no theme at all: the old message', (tester) async {
      await pump(
        tester,
        configure: (s) => s.themesResponse = (_) => jsonResponse(200, {'count': 0, 'results': []}),
      );
      expect(find.text(_l.duelNoPlayableThemes), findsOneWidget);
      expect(find.text(_l.duelOnlyLockedThemes('alice')), findsNothing);
    });
  });

  group('touching a padlock', () {
    testWidgets('opens the unlock screen on that theme; back without unlocking changes nothing', (tester) async {
      final store = FakeCreditStore();
      await withStore(store, () async {
        final r = await pump(tester, store: store);
        await tapKey(tester, 'theme-10');
        await tester.tap(find.byKey(const ValueKey('locked-theme-7')));
        await settle(tester);
        expect(find.byType(PremiumThemeUnlockScreen), findsOneWidget);
        expect(find.text(_l.unlockThemeFocusTitle), findsOneWidget);
        expect(find.text('Premium 7'), findsOneWidget);
        expect(find.text('Premium 8'), findsNothing);
        await tester.pageBack();
        await settle(tester);
        expect(find.byType(PremiumThemeUnlockScreen), findsNothing);
        expect(r.server.themeCalls, 1, reason: 'no reload when nothing was unlocked');
        expect(store.unlockCalls, 0);
        expect(find.byKey(const ValueKey('locked-theme-7')), findsOneWidget);
        expect(find.text(_l.duelThemesChosen(1)), findsOneWidget, reason: 'Capitals only');
      });
    });

    testWidgets('offline at the touch: the existing message, the screen does not open', (tester) async {
      final connectivity = _FlakyConnectivity();
      await pump(tester, connectivity: connectivity);
      connectivity.offlineOnNextRead = true;
      await tester.tap(find.byKey(const ValueKey('locked-theme-7')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_l.offlinePurchaseUnavailable), findsOneWidget);
      expect(find.byType(PremiumThemeUnlockScreen), findsNothing);
    });

    testWidgets('the network gone while the list is shown: the offline card replaces the list', (tester) async {
      final connectivity = FakeConnectivity();
      await pump(tester, connectivity: connectivity);
      connectivity.setOnline(false);
      await tester.pump();
      expect(find.text(_l.duelOfflineMessage), findsOneWidget);
      expect(find.byKey(const ValueKey('locked-theme-7')), findsNothing);
    });
  });

  group('back from an unlock', () {
    /// The server list after the unlock: Oceans now the player's.
    void unlockedAfterFirstCall(_Server s) => s.themesResponse = (call) => jsonResponse(200, {
      'count': 4,
      'results': _mixed(oceansLocked: call == 1),
    });

    testWidgets('the theme is ticked, the list fetched again, every other choice kept', (tester) async {
      final store = FakeCreditStore();
      await withStore(store, () async {
        final r = await pump(tester, store: store, configure: unlockedAfterFirstCall);
        await tapKey(tester, 'theme-10'); // Capitals
        await tapKey(tester, 'difficulty-easy'); // untick Easy: Medium only
        await tapKey(tester, 'seconds-15');
        final before = tester.widget<Text>(find.byKey(const ValueKey('challenge-recap'))).data;
        expect(before, _l.duelRoomSummary(5, 15, _l.medium));

        await tester.tap(find.byKey(const ValueKey('locked-theme-7')));
        await settle(tester);
        await tester.tap(find.text(_l.unlockThemeAction));
        await settle(tester);

        expect(store.origins, ['duel_challenge']);
        expect(r.server.themeCalls, 2);
        expect(find.byType(PremiumThemeUnlockScreen), findsNothing);
        // The padlock is gone; Oceans is a box, ticked, with Capitals.
        expect(find.byKey(const ValueKey('locked-theme-7')), findsNothing);
        expect(tester.widget<CheckboxListTile>(find.byKey(const ValueKey('theme-7'))).value, isTrue);
        expect(tester.widget<CheckboxListTile>(find.byKey(const ValueKey('theme-10'))).value, isTrue);
        expect(find.text(_l.duelThemesChosen(2)), findsOneWidget);
        // Choices kept: seconds, difficulties (Medium only), count.
        expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('seconds-15'))).selected, isTrue);
        expect(tester.widget<FilterChip>(find.byKey(const ValueKey('difficulty-medium'))).selected, isTrue);
        expect(tester.widget<FilterChip>(find.byKey(const ValueKey('difficulty-easy'))).selected, isFalse);
        // The new theme adds Hard to the offer, unticked: the player's choice stands.
        expect(tester.widget<FilterChip>(find.byKey(const ValueKey('difficulty-hard'))).selected, isFalse);
        expect(tester.widget<Text>(find.byKey(const ValueKey('challenge-recap'))).data, before);
        // The success message follows the player to this screen.
        expect(
          find.text(_l.unlockThemeSuccess('Premium 7', _l.storeQuestionPackCount(2))),
          findsOneWidget,
        );
        expect(r.catalog.synced, [7]);
      });
    });

    testWidgets('the unlocked theme is what the request carries', (tester) async {
      final store = FakeCreditStore();
      await withStore(store, () async {
        final r = await pump(tester, store: store, configure: unlockedAfterFirstCall);
        await tester.tap(find.byKey(const ValueKey('locked-theme-7')));
        await settle(tester);
        await tester.tap(find.text(_l.unlockThemeAction));
        await settle(tester);
        expect(startEnabled(tester), isTrue);
        // The success message floats over the button: let it go.
        await tester.pump(const Duration(seconds: 6));
        await settle(tester);
        await tapKey(tester, 'start-challenge');
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 400));
        expect(r.server.createBody['themes'], [7]);
        expect(r.server.createBody['difficulties'], ['hard']);
      });
    });

    testWidgets('the list cannot be fetched again: the theme stays playable, the screen stays', (tester) async {
      final store = FakeCreditStore();
      await withStore(store, () async {
        final r = await pump(
          tester,
          store: store,
          configure: (s) => s.themesResponse = (call) =>
              call == 1 ? jsonResponse(200, {'count': 4, 'results': _mixed()}) : errorResponse(500, 'server_error'),
        );
        await tester.tap(find.byKey(const ValueKey('locked-theme-7')));
        await settle(tester);
        await tester.tap(find.text(_l.unlockThemeAction));
        await settle(tester);
        expect(r.server.themeCalls, 2);
        expect(find.byKey(const ValueKey('locked-theme-7')), findsNothing);
        expect(tester.widget<CheckboxListTile>(find.byKey(const ValueKey('theme-7'))).value, isTrue);
        expect(find.text(_l.retry), findsNothing, reason: 'the list is still there');
        expect(startEnabled(tester), isTrue);
      });
    });

    testWidgets('the theme is gone meanwhile: the list is fetched again, nothing ticked, the reason shown', (tester) async {
      final store = FakeCreditStore()..catalog[7] = false;
      await withStore(store, () async {
        final r = await pump(tester, store: store);
        await tester.tap(find.byKey(const ValueKey('locked-theme-7')));
        await settle(tester);
        expect(find.byType(PremiumThemeUnlockScreen), findsNothing, reason: 'closed at once');
        expect(r.server.themeCalls, 2);
        expect(find.text(_l.unlockThemeUnavailable), findsOneWidget);
        expect(find.text(_l.duelThemesChosen(0)), findsOneWidget);
        expect(store.unlockCalls, 0);
      });
    });

    testWidgets('a ticked theme that comes back locked is unticked, with the old message', (tester) async {
      final r = await pump(
        tester,
        configure: (s) {
          s.createResponse = (_) => errorResponse(400, 'theme_not_playable');
          s.themesResponse = (call) => jsonResponse(200, {
            'count': 4,
            'results': _mixed(capitalsLocked: call > 1),
          });
        },
      );
      await tapKey(tester, 'theme-10');
      await tapKey(tester, 'start-challenge');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(_l.duelErrThemeNotPlayable), findsOneWidget);
      expect(r.server.themeCalls, 2);
      expect(find.byKey(const ValueKey('locked-theme-10')), findsOneWidget);
      expect(find.byKey(const ValueKey('theme-10')), findsNothing);
      expect(find.text(_l.duelThemesChosen(0)), findsOneWidget);
      expect(startEnabled(tester), isFalse);
    });
  });

  for (final locale in ['fr', 'en']) {
    group('320 dp, text x1.3, $locale', () {
      const size = Size(320, 640);
      Map<String, Object?> long(int id, bool locked) => _theme(
        id,
        'A premium theme whose name is really very long indeed, id $id',
        'Un thème premium dont le nom est vraiment très long, numéro $id',
        id,
        'A category with a very long name too',
        'Une catégorie au nom très long aussi',
        4,
        4,
        4,
        locked: locked,
      );

      testWidgets('challenge screen with padlock rows and long names', (tester) async {
        await pump(
          tester,
          locale: locale,
          size: size,
          textScale: 1.3,
          configure: (s) => s.themesResponse = (_) => jsonResponse(200, {
            'count': 3,
            'results': [long(1, false), long(2, true), long(3, true)],
          }),
        );
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(find.byKey(const ValueKey('locked-theme-3')), 200, scrollable: find.byType(Scrollable).first);
        await tester.pump();
        expect(tester.takeException(), isNull);
        final tile = tester.getRect(find.byKey(const ValueKey('locked-theme-3')));
        expect(tile.left, greaterThanOrEqualTo(0));
        expect(tile.right, lessThanOrEqualTo(size.width));
        expect(tile.height, greaterThanOrEqualTo(48), reason: 'a touch target');
      });

      testWidgets('challenge screen, only padlock themes', (tester) async {
        await pump(
          tester,
          locale: locale,
          size: size,
          textScale: 1.3,
          configure: (s) => s.themesResponse = (_) => jsonResponse(200, {
            'count': 2,
            'results': [long(2, true), long(3, true)],
          }),
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('only-locked-themes')), findsOneWidget);
      });

      for (final balance in [3, 0]) {
        testWidgets('unlock screen on one theme, $balance credits', (tester) async {
          final store = FakeCreditStore()..balance = balance;
          await withStore(store, () async {
            await pump(
              tester,
              store: store,
              locale: locale,
              size: size,
              textScale: 1.3,
              configure: (s) => s.themesResponse = (_) => jsonResponse(200, {
                'count': 2,
                'results': [long(1, false), _theme(7, 'Oceans', 'Océans', 2, 'Sea', 'Mer', 0, 0, 3, locked: true)],
              }),
            );
            await tester.scrollUntilVisible(find.byKey(const ValueKey('locked-theme-7')), 200, scrollable: find.byType(Scrollable).first);
            await tester.ensureVisible(find.byKey(const ValueKey('locked-theme-7')));
            await tester.pump();
            await tester.tap(find.byKey(const ValueKey('locked-theme-7')));
            await settle(tester);
            expect(find.byType(PremiumThemeUnlockScreen), findsOneWidget);
            expect(tester.takeException(), isNull);
            final key = balance == 0 ? 'unlock-open-store' : null;
            if (key != null) {
              final button = tester.getRect(find.byKey(ValueKey(key)));
              expect(button.right, lessThanOrEqualTo(size.width));
            }
          });
        });
      }
    });
  }
}
