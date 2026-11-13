import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/models/duel.dart';
import 'package:QuizzBuilder/models/duel_live.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/ui/duel/duel_challenge_screen.dart';

import 'support/duel_live_support.dart';
import 'support/duel_test_support.dart';

final _l = AppLocalizationsEn();

Map<String, Object?> _theme(
  int id,
  String fr,
  String en,
  int category,
  String categoryFr,
  String categoryEn,
  int easy,
  int medium,
  int hard, {
  bool free = true,
}) => {
  'id': id,
  'name_fr': fr,
  'name_en': en,
  'category_id': category,
  'category_name_fr': categoryFr,
  'category_name_en': categoryEn,
  'is_free': free,
  'question_counts': {'easy': easy, 'medium': medium, 'hard': hard},
};

List<Map<String, Object?>> _themes() => [
  _theme(10, 'Capitales', 'Capitals', 1, 'Géographie', 'Geography', 12, 8, 0),
  _theme(11, 'Fleuves', 'Rivers', 1, 'Géographie', 'Geography', 0, 3, 0, free: false),
  _theme(20, 'Rome', 'Rome', 2, 'Histoire', 'History', 2, 0, 4),
];

const _opponent = Opponent(id: 3, username: 'alice');

class _Server {
  _Server() {
    server = FakeDuelServer((r) {
      if (r.method == 'GET' && r.path.endsWith('/opponents/3/themes/')) {
        themeCalls++;
        return themesResponse();
      }
      if (r.method == 'POST' && r.path.endsWith('/duel/duels/')) {
        return createResponse(r);
      }
      if (r.method == 'GET' && r.path.contains('/duel/duels/')) {
        return jsonResponse(
          200,
          duelJson(
            id: r.path.contains('/42/') ? 42 : 1,
            serverTime: FakeClock.base,
            callLink: 'https://play.quizzbuilder.fr/d/ABCD2345',
          ),
        );
      }
      return jsonResponse(404, null);
    });
  }

  late final FakeDuelServer server;
  int themeCalls = 0;
  http.Response Function() themesResponse = () =>
      jsonResponse(200, {'count': 3, 'results': _themes()});
  http.Response Function(RecordedRequest) createResponse = (r) =>
      jsonResponse(201, duelJson(serverTime: FakeClock.base, callLink: 'https://play.quizzbuilder.fr/d/ABCD2345'));

  Map<String, dynamic> get createBody =>
      jsonDecode(server.requests.singleWhere((r) => r.method == 'POST').body)
          as Map<String, dynamic>;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('rules of the choice', () {
    final themes = [for (final t in _themes()) DuelTheme.fromJson(t)];

    test('difficulties offered are those with questions', () {
      expect(DuelChoice.availableDifficulties([themes[1]]), ['medium']);
      expect(DuelChoice.availableDifficulties([themes[2]]), ['easy', 'hard']);
      expect(DuelChoice.availableDifficulties(themes), ['easy', 'medium', 'hard']);
      expect(DuelChoice.availableDifficulties(const []), isEmpty);
    });

    test('questions available sum the ticked themes and difficulties', () {
      expect(DuelChoice.availableQuestions(themes, ['easy']), 14);
      expect(DuelChoice.availableQuestions([themes[0]], ['easy', 'medium']), 20);
      expect(DuelChoice.availableQuestions(themes, const []), 0);
    });

    test('allowed counts: the ones the questions can serve', () {
      expect(DuelChoice.allowedCounts(4), isEmpty);
      expect(DuelChoice.allowedCounts(5), [5]);
      expect(DuelChoice.allowedCounts(14), [5, 10]);
      expect(DuelChoice.allowedCounts(20), [5, 10, 15, 20]);
      expect(DuelChoice.allowedCounts(500), [5, 10, 15, 20]);
    });
  });

  Future<_Server> pumpChallenge(
    WidgetTester tester, {
    FakeConnectivity? connectivity,
    String locale = 'en',
    bool pushed = false,
    void Function(_Server)? configure,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final s = _Server();
    configure?.call(s);
    final provider = DuelProvider(service: s.server.service);
    final screen = const DuelChallengeScreen(opponent: _opponent);
    if (pushed) {
      await pumpLive(
        tester,
        duel: provider,
        connectivity: connectivity,
        locale: locale,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => screen),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    } else {
      await pumpLive(
        tester,
        duel: provider,
        connectivity: connectivity,
        locale: locale,
        home: screen,
      );
    }
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    return s;
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pump();
  }

  bool startEnabled(WidgetTester tester) =>
      tester
          .widget<ElevatedButton>(find.byKey(const ValueKey('start-challenge')))
          .onPressed !=
      null;

  testWidgets('themes grouped by category, nothing ticked, start disabled, no ownership hint', (tester) async {
    await pumpChallenge(tester);
    expect(find.text(_l.duelChallengeTitle('alice')), findsOneWidget);
    expect(find.text('Geography'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Capitals'), findsOneWidget);
    expect(find.text('Rivers'), findsOneWidget);
    expect(find.text('Rome'), findsOneWidget);
    expect(find.text(_l.duelThemesChosen(0)), findsOneWidget);
    expect(startEnabled(tester), isFalse);
    // D8: nothing says who owns what, nothing invites to buy.
    for (final word in ['free', 'Free', 'lent', 'borrow', 'owned', 'premium', 'Premium', 'unlock', 'buy', 'Buy']) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
    expect(find.byIcon(Icons.lock), findsNothing);
  });

  testWidgets('French names of themes and categories in French', (tester) async {
    await pumpChallenge(tester, locale: 'fr');
    expect(find.text('Géographie'), findsOneWidget);
    expect(find.text('Capitales'), findsOneWidget);
    expect(find.text('Histoire'), findsOneWidget);
    expect(find.text('Lancer le défi'), findsOneWidget);
    expect(find.text('Défier alice'), findsOneWidget);
  });

  testWidgets('difficulties offered follow the ticked themes', (tester) async {
    await pumpChallenge(tester);
    expect(find.byKey(const ValueKey('difficulty-easy')), findsOneWidget);
    expect(find.byKey(const ValueKey('difficulty-medium')), findsOneWidget);
    expect(find.byKey(const ValueKey('difficulty-hard')), findsOneWidget);

    await tapKey(tester, 'theme-11'); // Rivers: medium only
    expect(find.byKey(const ValueKey('difficulty-easy')), findsNothing);
    expect(find.byKey(const ValueKey('difficulty-medium')), findsOneWidget);
    expect(find.byKey(const ValueKey('difficulty-hard')), findsNothing);

    await tapKey(tester, 'theme-20'); // Rome: easy and hard
    expect(find.byKey(const ValueKey('difficulty-easy')), findsOneWidget);
    expect(find.byKey(const ValueKey('difficulty-hard')), findsOneWidget);
    expect(find.text(_l.duelThemesChosen(2)), findsOneWidget);
  });

  testWidgets('a difficulty that disappears is unticked', (tester) async {
    await pumpChallenge(tester);
    await tapKey(tester, 'theme-20'); // easy + hard offered and ticked
    await tapKey(tester, 'difficulty-hard'); // the player unticks hard
    await tapKey(tester, 'theme-20'); // theme off: all offered again
    await tapKey(tester, 'theme-11'); // medium only: easy/hard gone
    final medium = tester.widget<FilterChip>(find.byKey(const ValueKey('difficulty-medium')));
    expect(medium.selected, isFalse, reason: 'the player had unticked hard, medium never ticked on touch');
  });

  testWidgets('counts that the questions cannot serve are greyed, with the hint', (tester) async {
    await pumpChallenge(tester);
    await tapKey(tester, 'theme-11'); // 3 medium questions only
    expect(find.byKey(const ValueKey('counts-hint')), findsOneWidget);
    for (final n in [5, 10, 15, 20]) {
      expect(
        tester.widget<ChoiceChip>(find.byKey(ValueKey('count-$n'))).onSelected,
        isNull,
        reason: '$n',
      );
    }
    expect(startEnabled(tester), isFalse);

    await tapKey(tester, 'theme-10'); // + 20 questions -> 23 in easy+medium
    expect(find.byKey(const ValueKey('counts-hint')), findsNothing);
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('count-20'))).onSelected, isNotNull);
    expect(startEnabled(tester), isTrue);
  });

  testWidgets('a count that can no longer be served falls back to the largest possible', (tester) async {
    await pumpChallenge(tester);
    await tapKey(tester, 'theme-10'); // easy 12 + medium 8 = 20
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('count-10'))).selected, isTrue);
    await tapKey(tester, 'difficulty-easy'); // medium only: 8 questions
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('count-5'))).selected, isTrue);
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('count-10'))).onSelected, isNull);
    expect(startEnabled(tester), isTrue);
  });

  testWidgets('no difficulty ticked: start disabled', (tester) async {
    await pumpChallenge(tester);
    await tapKey(tester, 'theme-10');
    await tapKey(tester, 'difficulty-easy');
    await tapKey(tester, 'difficulty-medium');
    expect(startEnabled(tester), isFalse);
  });

  testWidgets('start: exact body, then the waiting room opens', (tester) async {
    final s = await pumpChallenge(tester);
    await tapKey(tester, 'theme-20');
    await tapKey(tester, 'theme-10');
    await tapKey(tester, 'count-15');
    await tapKey(tester, 'start-challenge');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));

    expect(s.createBody, {
      'pair_id': 3,
      'themes': [10, 20],
      'difficulties': ['easy', 'medium', 'hard'],
      'question_count': 15,
      'seconds_per_question': 10,
    });
    expect(find.text(_l.duelRoomTitle), findsOneWidget);
    expect(find.text(_l.duelRoomWaitingFor('alice')), findsOneWidget);
    expect(find.text('https://play.quizzbuilder.fr/d/ABCD2345'), findsOneWidget);
  });

  testWidgets('default question count is 10', (tester) async {
    final s = await pumpChallenge(tester);
    await tapKey(tester, 'theme-10');
    await tapKey(tester, 'start-challenge');
    await tester.pump(const Duration(milliseconds: 50));
    expect(s.createBody['question_count'], 10);
    expect(s.createBody['difficulties'], ['easy', 'medium']);
    await tester.pump(const Duration(milliseconds: 400));
  });

  group('every error of the contract has its own message', () {
    final cases = <String, ({int status, String message})>{
      'no_theme_selected': (status: 400, message: _l.duelErrNoThemeSelected),
      'theme_not_playable': (status: 400, message: _l.duelErrThemeNotPlayable),
      'invalid_question_count': (status: 400, message: _l.duelErrInvalidQuestionCount),
      'invalid_difficulty': (status: 400, message: _l.duelErrInvalidDifficulty),
      'not_enough_questions': (status: 409, message: _l.duelErrNotEnoughQuestions),
      'lent_theme_limit_reached': (status: 409, message: _l.duelErrLentThemeLimit),
      'unknown_new_code': (status: 400, message: _l.errorGenericTryAgain),
    };
    for (final entry in cases.entries) {
      testWidgets(entry.key, (tester) async {
        final s = await pumpChallenge(
          tester,
          configure: (s) => s.createResponse = (r) => errorResponse(entry.value.status, entry.key),
        );
        await tapKey(tester, 'theme-10');
        await tapKey(tester, 'start-challenge');
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text(entry.value.message), findsOneWidget);
        expect(find.text(_l.duelChallengeTitle('alice')), findsOneWidget, reason: 'stays on the screen');
        expect(startEnabled(tester), isTrue, reason: 'can try again');
        if (entry.key == 'theme_not_playable') {
          expect(s.themeCalls, 2, reason: 'the list of themes is reloaded');
        }
      });
    }

    testWidgets('network failure', (tester) async {
      await pumpChallenge(
        tester,
        configure: (s) => s.createResponse = (r) => throw Exception('socket'),
      );
      await tapKey(tester, 'theme-10');
      await tapKey(tester, 'start-challenge');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(_l.errorGenericTryAgain), findsOneWidget);
    });
  });

  testWidgets('opponent_not_found at creation: message and back to the hub', (tester) async {
    await pumpChallenge(
      tester,
      pushed: true,
      configure: (s) => s.createResponse = (r) => errorResponse(404, 'opponent_not_found'),
    );
    await tapKey(tester, 'theme-10');
    await tapKey(tester, 'start-challenge');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('open'), findsOneWidget);
    expect(find.text(_l.duelErrOpponentNotFound), findsOneWidget);
  });

  testWidgets('opponent_not_found when loading the themes: message and back', (tester) async {
    await pumpChallenge(
      tester,
      pushed: true,
      configure: (s) => s.themesResponse = () => errorResponse(404, 'opponent_not_found'),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('open'), findsOneWidget);
    expect(find.text(_l.duelErrOpponentNotFound), findsOneWidget);
  });

  testWidgets('duel_already_open opens the existing duel, with a word about it', (tester) async {
    await pumpChallenge(
      tester,
      configure: (s) => s.createResponse = (r) => jsonResponse(409, {
        'error': {
          'code': 'duel_already_open',
          'message': 'x',
          'status_code': 409,
          'details': {
            'duel': {'id': 42},
          },
        },
      }),
    );
    await tapKey(tester, 'theme-10');
    await tapKey(tester, 'start-challenge');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(_l.duelRoomTitle), findsOneWidget);
    expect(find.text(_l.duelAlreadyOpenOpened('alice')), findsOneWidget);
  });

  testWidgets('offline: says so, calls nothing, no start button', (tester) async {
    final s = await pumpChallenge(tester, connectivity: FakeConnectivity(online: false));
    expect(find.text(_l.duelOfflineMessage), findsOneWidget);
    expect(s.server.requests, isEmpty);
    expect(find.byKey(const ValueKey('start-challenge')), findsNothing);
  });

  testWidgets('loading error: message and retry', (tester) async {
    final s = await pumpChallenge(
      tester,
      configure: (s) => s.themesResponse = () => errorResponse(500, 'server_error'),
    );
    expect(find.text(_l.errorGenericTryAgain), findsOneWidget);
    s.themesResponse = () => jsonResponse(200, {'count': 3, 'results': _themes()});
    await tester.tap(find.text(_l.retry));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Capitals'), findsOneWidget);
  });

  group('settings above the themes, and the time per question (R1, T2)', () {
    Offset top(WidgetTester tester, String key) =>
        tester.getTopLeft(find.byKey(ValueKey(key)));

    testWidgets('order: difficulties, count, time, then the themes', (tester) async {
      await pumpChallenge(tester);
      final difficulties = top(tester, 'difficulty-easy').dy;
      final count = top(tester, 'count-5').dy;
      final seconds = top(tester, 'seconds-5').dy;
      final themes = top(tester, 'theme-10').dy;
      expect(difficulties, lessThan(count));
      expect(count, lessThan(seconds));
      expect(seconds, lessThan(themes));
      expect(
        tester.getTopLeft(find.text(_l.duelThemesSection)).dy,
        lessThan(themes),
      );
      expect(
        tester.getTopLeft(find.text(_l.duelThemesSection)).dy,
        greaterThan(seconds),
        reason: 'the themes title is under the settings',
      );
      // The start button is still fixed under everything.
      expect(find.byKey(const ValueKey('start-challenge')), findsOneWidget);
    });

    testWidgets('the three times are offered, 10 s preselected, never greyed', (tester) async {
      await pumpChallenge(tester);
      expect(find.text(_l.duelSecondsSection), findsOneWidget);
      expect(find.text(_l.duelSecondsHelp), findsOneWidget);
      ChoiceChip chip(int n) =>
          tester.widget<ChoiceChip>(find.byKey(ValueKey('seconds-$n')));
      for (final n in [5, 10, 15]) {
        expect(find.text(_l.duelSecondsChoice(n)), findsOneWidget);
        expect(chip(n).onSelected, isNotNull, reason: '$n s is never greyed');
      }
      expect(chip(5).selected, isFalse);
      expect(chip(10).selected, isTrue);
      expect(chip(15).selected, isFalse);
      expect(find.byKey(const ValueKey('seconds-20')), findsNothing);
      // The old fixed 20 s sentence is gone.
      expect(find.textContaining('20 seconds'), findsNothing);
    });

    testWidgets('French labels', (tester) async {
      await pumpChallenge(tester, locale: 'fr');
      expect(find.text('Temps par question'), findsOneWidget);
      expect(find.text('Le même temps pour vous deux.'), findsOneWidget);
      expect(find.text('10 s'), findsOneWidget);
    });

    testWidgets('untouched, 10 is sent; a choice is sent as made', (tester) async {
      var s = await pumpChallenge(tester);
      await tapKey(tester, 'theme-10');
      await tapKey(tester, 'start-challenge');
      await tester.pump(const Duration(milliseconds: 50));
      expect(s.createBody['seconds_per_question'], 10);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(const SizedBox());

      for (final n in [5, 15]) {
        s = await pumpChallenge(tester);
        await tapKey(tester, 'theme-10');
        await tapKey(tester, 'seconds-$n');
        expect(
          tester.widget<ChoiceChip>(find.byKey(ValueKey('seconds-$n'))).selected,
          isTrue,
        );
        expect(
          tester.widget<ChoiceChip>(find.byKey(const ValueKey('seconds-10'))).selected,
          isFalse,
        );
        await tapKey(tester, 'start-challenge');
        await tester.pump(const Duration(milliseconds: 50));
        expect(s.createBody['seconds_per_question'], n);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('the recap follows the choices live', (tester) async {
      await pumpChallenge(tester);
      String recap() =>
          tester.widget<Text>(find.byKey(const ValueKey('challenge-recap'))).data!;
      // Nothing ticked: every difficulty that exists, 10 questions, 10 s.
      expect(recap(), _l.duelRoomSummary(10, 10, 'Easy, Medium, Hard'));

      // A theme that only has medium questions: the other difficulties go.
      await tapKey(tester, 'theme-11');
      expect(recap(), _l.duelRoomSummary(10, 10, 'Medium'));

      // Tick Capitals too: easy and medium are offered again.
      await tapKey(tester, 'theme-10');
      expect(recap(), _l.duelRoomSummary(10, 10, 'Easy, Medium'));

      await tapKey(tester, 'count-15');
      expect(recap(), _l.duelRoomSummary(15, 10, 'Easy, Medium'));
      await tapKey(tester, 'seconds-5');
      expect(recap(), _l.duelRoomSummary(15, 5, 'Easy, Medium'));

      // Untick a difficulty: only 11 medium questions are left, so 15 falls
      // back to 10 — and the recap says so (the point of showing it).
      await tapKey(tester, 'difficulty-easy');
      expect(recap(), _l.duelRoomSummary(10, 5, 'Medium'));
      expect(recap(), '10 questions · 5 s per question · Medium');
    });

    testWidgets('the count that falls back after a theme change shows in the recap', (tester) async {
      await pumpChallenge(tester);
      await tapKey(tester, 'theme-10'); // 20 easy + medium questions
      await tapKey(tester, 'count-20');
      String recap() =>
          tester.widget<Text>(find.byKey(const ValueKey('challenge-recap'))).data!;
      expect(recap(), contains('20 questions'));
      // Rome has few questions: ticking it alone is not what changes the
      // count; unticking Capitals leaves 6 (2 easy + 4 hard).
      await tapKey(tester, 'theme-20');
      await tapKey(tester, 'theme-10');
      expect(recap(), contains('5 questions'), reason: '6 questions: 5 is the largest count left');
    });

    testWidgets('no difficulty ticked: no dangling separator', (tester) async {
      await pumpChallenge(tester);
      await tapKey(tester, 'theme-11'); // only medium is offered
      await tapKey(tester, 'difficulty-medium');
      final text =
          tester.widget<Text>(find.byKey(const ValueKey('challenge-recap'))).data!;
      expect(text, '10 questions · 10 s per question');
    });

    testWidgets('offline and error states show no recap and no settings', (tester) async {
      await pumpChallenge(tester, connectivity: FakeConnectivity(online: false));
      expect(find.byKey(const ValueKey('challenge-recap')), findsNothing);
      expect(find.byKey(const ValueKey('seconds-10')), findsNothing);
    });
  });

  testWidgets('no playable theme: a message and no start', (tester) async {
    await pumpChallenge(
      tester,
      configure: (s) => s.themesResponse = () => jsonResponse(200, {'count': 0, 'results': []}),
    );
    expect(find.text(_l.duelNoPlayableThemes), findsOneWidget);
    expect(find.byKey(const ValueKey('start-challenge')), findsNothing);
  });
}
