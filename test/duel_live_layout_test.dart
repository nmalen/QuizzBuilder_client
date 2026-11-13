import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/models/duel.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/ui/duel/duel_challenge_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_history_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_hub_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_live_screen.dart';

import 'support/duel_live_support.dart';
import 'support/duel_scenario.dart';
import 'support/duel_test_support.dart';

/// The new screens of the live duel, on the narrowest phones with large text,
/// in both languages: no RenderFlex overflow in any state.
const _longName = 'a_rather_long_username_here_indeed';
const _longText =
    'Quelle est la très longue question dont l\'énoncé occupe plusieurs lignes '
    'sur un écran étroit avec un texte agrandi, pour vérifier la mise en page ?';
const _longAnswer =
    'Une réponse particulièrement longue qui doit passer à la ligne sans '
    'jamais déborder du bouton';

Map<String, Object?> _longQuestion(int id) => {
  ...questionJson(id),
  'question_fr': _longText,
  'question_en': _longText,
  'theme_name_fr': 'Un thème dont le nom est vraiment très long',
  'theme_name_en': 'A theme whose name is really very long indeed',
  for (var i = 1; i <= 4; i++) 'answer_${i}_fr': '$_longAnswer $i',
  for (var i = 1; i <= 4; i++) 'answer_${i}_en': '$_longAnswer $i',
};

Future<void> _steps(WidgetTester tester, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<Scenario> pumpAt320(
    WidgetTester tester, {
    required String locale,
    required Widget Function(Scenario) home,
    void Function(Scenario)? configure,
    FakeConnectivity? connectivity,
  }) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final s = Scenario();
    configure?.call(s);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(1.3),
        ),
        child: duelApp(
          locale: locale,
          home: home(s),
          duel: DuelProvider(service: s.server.service),
          connectivity: connectivity,
        ),
      ),
    );
    await _steps(tester);
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    return s;
  }

  Map<String, Object?> waiting(Scenario s, {bool challenger = true}) => duelJson(
    serverTime: s.serverNow,
    opponent: _longName,
    challengedByMe: challenger,
    difficulties: const ['easy', 'medium', 'hard'],
    callLink: challenger ? 'https://play.quizzbuilder.fr/d/ABCD2345' : null,
    roomExpiresAt: FakeClock.base.add(const Duration(minutes: 10)),
  );

  Map<String, Object?> playing(Scenario s, {int startsInSeconds = 0}) => duelJson(
    serverTime: s.serverNow,
    status: 'playing',
    opponent: _longName,
    challengedByMe: false,
    startsAt: FakeClock.base.add(Duration(seconds: startsInSeconds)),
  );

  for (final locale in ['fr', 'en']) {
    group('320 dp, text x1.3, $locale', () {
      testWidgets('challenge screen, with long names and a selection', (tester) async {
        final s = await pumpAt320(
          tester,
          locale: locale,
          home: (s) => const DuelChallengeScreen(
            opponent: Opponent(id: 3, username: _longName),
          ),
          configure: (s) => s.intercept = (r) {
            if (r.path.endsWith('/themes/')) {
              return jsonResponse(200, {
                'count': 2,
                'results': [
                  {
                    'id': 10,
                    'name_fr': 'Un thème dont le nom est vraiment très long',
                    'name_en': 'A theme whose name is really very long indeed',
                    'category_id': 1,
                    'category_name_fr': 'Une catégorie au nom très long aussi',
                    'category_name_en': 'A category with a very long name too',
                    'is_free': true,
                    'question_counts': {'easy': 12, 'medium': 8, 'hard': 2},
                  },
                  {
                    'id': 11,
                    'name_fr': 'Court',
                    'name_en': 'Short',
                    'category_id': 1,
                    'category_name_fr': 'Une catégorie au nom très long aussi',
                    'category_name_en': 'A category with a very long name too',
                    'is_free': true,
                    'question_counts': {'easy': 1, 'medium': 0, 'hard': 0},
                  },
                ],
              });
            }
            return null;
          },
        );
        expect(tester.takeException(), isNull);
        // The themes are below the settings (decision R1): scroll to them.
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('theme-11')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        // Barely visible is not tappable: bring it fully into view.
        await tester.ensureVisible(find.byKey(const ValueKey('theme-11')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('theme-11')));
        await _steps(tester, 2);
        expect(tester.takeException(), isNull, reason: 'greyed counts and hint');
        expect(s.server.requests, isNotEmpty);
      });

      testWidgets('room: challenger and challenged', (tester) async {
        await pumpAt320(
          tester,
          locale: locale,
          home: (s) => DuelLiveScreen(duelId: 1, now: s.clock.now),
          configure: (s) => s.state = (_) => waiting(s),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await pumpAt320(
          tester,
          locale: locale,
          home: (s) => DuelLiveScreen(duelId: 1, now: s.clock.now),
          configure: (s) => s.state = (_) => waiting(s, challenger: false),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('room: expired and unstable connection', (tester) async {
        await pumpAt320(
          tester,
          locale: locale,
          home: (s) => DuelLiveScreen(duelId: 1, now: s.clock.now),
          configure: (s) => s.state = (_) => {...waiting(s), 'status': 'expired'},
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('countdown', (tester) async {
        await pumpAt320(
          tester,
          locale: locale,
          home: (s) => DuelLiveScreen(duelId: 1, now: s.clock.now),
          configure: (s) {
            s.state = (_) => playing(s, startsInSeconds: 8);
            s.startsAt = FakeClock.base.add(const Duration(seconds: 8));
            s.questionsOverride = () => errorResponse(500, 'x');
          },
        );
        expect(find.byKey(const ValueKey('countdown-number')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('game: long question, answered state, time-up notice', (tester) async {
        final s = await pumpAt320(
          tester,
          locale: locale,
          home: (s) => DuelLiveScreen(duelId: 1, now: s.clock.now),
          configure: (s) {
            s.state = (_) => playing(s);
            s.startsAt = FakeClock.base;
            s.questionsOverride = () => jsonResponse(200, {
              ...questionsPayload(count: 3, startsAt: FakeClock.base, serverTime: FakeClock.base),
              'questions': [for (var i = 1; i <= 3; i++) _longQuestion(i)],
            });
          },
        );
        await elapse(tester, s.clock, const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('duel-question-text')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'open question');

        await tester.ensureVisible(find.byKey(const ValueKey('duel-answer-2')));
        await tester.tap(find.byKey(const ValueKey('duel-answer-2')));
        await tester.pump();
        expect(find.byKey(const ValueKey('answer-saved')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'answer saved');

        await elapse(tester, s.clock, const Duration(seconds: 40));
        expect(find.byKey(const ValueKey('time-up')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'time up notice');
      });

      testWidgets('game: offline warning above a long question, 5 s per question', (tester) async {
        final connectivity = FakeConnectivity();
        final s = await pumpAt320(
          tester,
          locale: locale,
          connectivity: connectivity,
          home: (s) => DuelLiveScreen(duelId: 1, now: s.clock.now),
          configure: (s) {
            s.state = (_) => {
              ...playing(s),
              'seconds_per_question': 5,
              'deadline_at': iso(FakeClock.base.add(const Duration(seconds: 35))),
            };
            s.startsAt = FakeClock.base;
            s.questionsOverride = () => jsonResponse(200, {
              ...questionsPayload(
                count: 3,
                startsAt: FakeClock.base,
                serverTime: FakeClock.base,
                secondsPerQuestion: 5,
              ),
              'questions': [for (var i = 1; i <= 3; i++) _longQuestion(i)],
            });
          },
        );
        await elapse(tester, s.clock, const Duration(milliseconds: 500));
        connectivity.setOnline(false);
        await tester.pump();
        await elapse(tester, s.clock, const Duration(seconds: 2, milliseconds: 500));
        expect(find.byKey(const ValueKey('offline-warning')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'warning card');

        // The notice floats over the card at the next question (opened at
        // 5 s, shown for 1 s: look at 5.5 s).
        await elapse(tester, s.clock, const Duration(seconds: 2, milliseconds: 500));
        expect(find.byKey(const ValueKey('time-up')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'time-up notice with the warning');
      });

      testWidgets('sending fails: the warning and the countdown', (tester) async {
        final s = await pumpAt320(
          tester,
          locale: locale,
          home: (s) => DuelLiveScreen(duelId: 1, now: s.clock.now),
          configure: (s) {
            s.state = (_) => playing(s);
            s.startsAt = FakeClock.base;
            s.answersOverride = (_) => Scenario.network();
          },
        );
        await elapse(tester, s.clock, const Duration(seconds: 3 * 20 + 5));
        expect(find.byKey(const ValueKey('send-deadline-warning')), findsOneWidget);
        expect(find.byKey(const ValueKey('send-time-left')), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Let the retry end.
        s.answersOverride = null;
        await elapse(tester, s.clock, const Duration(seconds: 3));
      });

      testWidgets('game: the quit dialog', (tester) async {
        final s = await pumpAt320(
          tester,
          locale: locale,
          home: (s) => DuelLiveScreen(duelId: 1, now: s.clock.now),
          configure: (s) {
            s.state = (_) => playing(s);
            s.startsAt = FakeClock.base;
          },
        );
        await elapse(tester, s.clock, const Duration(milliseconds: 500));
        await tester.tap(find.byType(BackButton));
        await _steps(tester, 5);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('waiting for the result, sending with retry', (tester) async {
        await pumpAt320(
          tester,
          locale: locale,
          home: (s) => DuelLiveScreen(duelId: 1, now: s.clock.now),
          configure: (s) => s.state = (_) => duelJson(
            serverTime: s.serverNow,
            status: 'playing',
            opponent: _longName,
            startsAt: FakeClock.base.subtract(const Duration(seconds: 70)),
            mySubmitted: true,
          ),
        );
        expect(tester.takeException(), isNull);
      });

      for (final entry in {
        'win': ('win', false),
        'loss by forfeit': ('loss', true),
        'no result': (null, false),
      }.entries) {
        testWidgets('result with review: ${entry.key}', (tester) async {
          await pumpAt320(
            tester,
            locale: locale,
            home: (s) => DuelLiveScreen(duelId: 1, now: s.clock.now),
            configure: (s) {
              final (outcome, forfeit) = entry.value;
              s.state = (_) => duelJson(
                serverTime: s.serverNow,
                status: outcome == null
                    ? 'no_result'
                    : (forfeit ? 'forfeit' : 'finished'),
                opponent: _longName,
                mySubmitted: true,
                startsAt: FakeClock.base.subtract(const Duration(minutes: 2)),
                result: resultJson(
                  outcome: outcome,
                  forfeit: forfeit,
                  myScore: outcome == null ? null : 2,
                  opponentScore: outcome == null ? null : 1,
                ),
              );
              s.questionsOverride = () => jsonResponse(200, {
                ...questionsPayload(count: 3, startsAt: FakeClock.base, serverTime: FakeClock.base),
                'questions': [for (var i = 1; i <= 3; i++) _longQuestion(i)],
              });
            },
          );
          expect(tester.takeException(), isNull);
          await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
          await _steps(tester, 3);
          expect(tester.takeException(), isNull, reason: 'scrolled to the review');
        });
      }

      testWidgets('hub with open duels, long names and Challenge buttons', (tester) async {
        await pumpAt320(
          tester,
          locale: locale,
          home: (s) => const DuelHubScreen(),
          configure: (s) => s.intercept = (r) {
            if (r.path.endsWith('/duel/opponents/')) {
              return jsonResponse(200, {
                'count': 1,
                'results': [opponentJson(1, _longName)],
              });
            }
            if (r.method == 'GET' && r.path.endsWith('/duel/duels/')) {
              return jsonResponse(200, {
                'server_time': iso(FakeClock.base),
                'count': 4,
                'results': [
                  for (final (i, st) in [
                    (1, 'waiting'),
                    (2, 'waiting'),
                    (3, 'playing'),
                    (4, 'playing'),
                  ])
                    {
                      'id': i,
                      'status': st,
                      'pair_id': i + 10,
                      'opponent_username': _longName,
                      'challenged_by_me': i == 2,
                      'question_count': 10,
                      'created_at': iso(FakeClock.base),
                      'room_expires_at': iso(FakeClock.base.add(const Duration(minutes: 10))),
                      'starts_at': st == 'playing' ? iso(FakeClock.base) : null,
                      'deadline_at': st == 'playing' ? iso(FakeClock.base.add(const Duration(minutes: 4))) : null,
                    },
                ],
              });
            }
            if (r.method == 'GET' && r.path.contains('/duel/duels/')) {
              return jsonResponse(200, duelJson(serverTime: FakeClock.base, mySubmitted: true));
            }
            return null;
          },
        );
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
        await _steps(tester, 3);
        expect(tester.takeException(), isNull, reason: 'scrolled');
      });

      testWidgets('history with long names', (tester) async {
        await pumpAt320(
          tester,
          locale: locale,
          home: (s) => const DuelHistoryScreen(),
          configure: (s) => s.intercept = (r) {
            if (r.path.endsWith('/history/')) {
              return jsonResponse(200, {
                'count': 2,
                'results': [
                  {
                    'id': 1,
                    'status': 'forfeit',
                    'opponent_username': _longName,
                    'challenged_by_me': true,
                    'outcome': 'loss',
                    'my_score': 12,
                    'opponent_score': 20,
                    'question_count': 20,
                    'themes': [10],
                    'created_at': iso(FakeClock.base),
                    'closed_at': iso(FakeClock.base),
                  },
                  {
                    'id': 2,
                    'status': 'no_result',
                    'opponent_username': _longName,
                    'challenged_by_me': false,
                    'outcome': null,
                    'my_score': null,
                    'opponent_score': null,
                    'question_count': 5,
                    'themes': [10],
                    'created_at': iso(FakeClock.base),
                    'closed_at': iso(FakeClock.base),
                  },
                ],
              });
            }
            return null;
          },
        );
        expect(tester.takeException(), isNull);
      });
    });
  }
}
