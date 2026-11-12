import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/ui/duel/duel_live_screen.dart';

import 'support/duel_live_support.dart';
import 'support/duel_scenario.dart';
import 'support/duel_test_support.dart';

final _l = AppLocalizationsEn();

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// A tall screen: the review is a lazy list, every card must be built.
  void tallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// A finished duel as the state route gives it.
  Scenario finished({
    String status = 'finished',
    Map<String, Object?>? result,
  }) {
    final s = Scenario();
    s.state = (now) => duelJson(
      serverTime: now,
      status: status,
      startsAt: now.subtract(const Duration(minutes: 2)),
      mySubmitted: true,
      opponentSubmitted: true,
      result: result ?? resultJson(),
    );
    return s;
  }

  Future<DuelProvider> pumpResult(WidgetTester tester, Scenario s) async {
    tallScreen(tester);
    final provider = DuelProvider(service: s.server.service);
    await pumpLive(
      tester,
      home: DuelLiveScreen(duelId: 1, now: s.clock.now),
      duel: provider,
    );
    await _settle(tester);
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    return provider;
  }

  Text title(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('result-title')));

  group('the six results', () {
    testWidgets('win', (tester) async {
      await pumpResult(tester, finished());
      expect(title(tester).data, _l.duelResultWin);
      expect(find.text(_l.duelResultWinSub('alice')), findsOneWidget);
      expect(find.text(_l.duelScoreOutOf(2, 3)), findsOneWidget);
      expect(find.text(_l.duelScoreOutOf(1, 3)), findsOneWidget);
      expect(title(tester).style?.color, Colors.green);
    });

    testWidgets('loss', (tester) async {
      await pumpResult(
        tester,
        finished(result: resultJson(outcome: 'loss', myScore: 1, opponentScore: 3)),
      );
      expect(title(tester).data, _l.duelResultLoss);
      expect(find.text(_l.duelResultLossSub('alice')), findsOneWidget);
      expect(find.text(_l.duelScoreOutOf(1, 3)), findsOneWidget);
      expect(find.text(_l.duelScoreOutOf(3, 3)), findsOneWidget);
      expect(title(tester).style?.color, Colors.red);
    });

    testWidgets('draw: a tie is a draw, no tie-break', (tester) async {
      await pumpResult(
        tester,
        finished(result: resultJson(outcome: 'draw', myScore: 2, opponentScore: 2)),
      );
      expect(title(tester).data, _l.duelResultDraw);
      expect(find.text(_l.duelResultDrawSub), findsOneWidget);
      expect(find.text(_l.duelScoreOutOf(2, 3)), findsNWidgets(2));
    });

    testWidgets('win by forfeit: the other did not finish in time', (tester) async {
      await pumpResult(
        tester,
        finished(
          status: 'forfeit',
          result: resultJson(outcome: 'win', forfeit: true, myScore: 2, opponentScore: 0),
        ),
      );
      expect(title(tester).data, _l.duelResultWinForfeit);
      expect(find.text(_l.duelResultWinForfeitSub('alice')), findsOneWidget);
    });

    testWidgets('loss by forfeit: my answers did not arrive in time', (tester) async {
      await pumpResult(
        tester,
        finished(
          status: 'forfeit',
          result: resultJson(outcome: 'loss', forfeit: true, myScore: 0, opponentScore: 2),
        ),
      );
      expect(title(tester).data, _l.duelResultLossForfeit);
      expect(find.text(_l.duelResultLossForfeitSub), findsOneWidget);
    });

    testWidgets('no result: nobody sent answers, no scores', (tester) async {
      await pumpResult(
        tester,
        finished(
          status: 'no_result',
          result: resultJson(
            outcome: null,
            myScore: null,
            opponentScore: null,
            lines: const [
              [null, null, null],
              [null, null, null],
              [null, null, null],
            ],
          ),
        ),
      );
      expect(title(tester).data, _l.duelResultNone);
      expect(find.text(_l.duelResultNoneSub), findsOneWidget);
      expect(find.byKey(const ValueKey('score-me')), findsNothing);
      expect(find.byKey(const ValueKey('score-opponent')), findsNothing);
      expect(find.text(_l.duelReviewNoAnswerYou), findsNWidgets(3));
      expect(find.text(_l.duelReviewNoAnswerOpponent('alice')), findsNWidgets(3));
    });
  });

  group('review question by question', () {
    testWidgets('my answer, the other one and the right one, per question', (tester) async {
      await pumpResult(tester, finished());
      // Lines: Q1 me 1 / alice 2 / right 1 ; Q2 me 2 / alice none / right 3 ;
      //        Q3 me 3 / alice 4 / right 4.
      expect(find.text(_l.duelReviewTitle), findsOneWidget);
      for (var n = 1; n <= 3; n++) {
        expect(find.byKey(ValueKey('review-$n')), findsOneWidget);
        expect(find.text('Question EN $n?'), findsOneWidget);
      }
      expect(find.text(_l.duelReviewQuestionHeader(1, 'Geography')), findsOneWidget);
      expect(find.text(_l.duelReviewCorrect), findsNWidgets(3));
      expect(find.text(_l.duelScoreYou), findsNWidgets(3 + 1), reason: '3 pills + the score label');
      expect(find.text('alice'), findsNWidgets(2 + 1), reason: '2 pills + the score label');
      expect(find.text(_l.duelReviewNoAnswerOpponent('alice')), findsOneWidget);
      expect(find.text(_l.duelReviewNoAnswerYou), findsNothing);

      // The right answer of question 2 is answer 3.
      final q2 = find.byKey(const ValueKey('review-2'));
      final correctBox = find.descendant(
        of: q2,
        matching: find.ancestor(
          of: find.text('Answer 3 of 2'),
          matching: find.byType(Container),
        ),
      );
      expect(correctBox, findsWidgets);
    });

    testWidgets('French review', (tester) async {
      tallScreen(tester);
      final s = finished();
      final provider = DuelProvider(service: s.server.service);
      await pumpLive(
        tester,
        locale: 'fr',
        home: DuelLiveScreen(duelId: 1, now: s.clock.now),
        duel: provider,
      );
      await _settle(tester);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      expect(find.text('Victoire !'), findsOneWidget);
      expect(find.text('Revue des questions'), findsOneWidget);
      expect(find.text('Question FR 1 ?'), findsOneWidget);
      expect(find.text('Bonne réponse'), findsNWidgets(3));
      expect(find.text('alice : pas de réponse'), findsOneWidget);
    });

    testWidgets('questions that cannot be fetched: the review says it is not available', (tester) async {
      final s = finished();
      s.questionsOverride = () => errorResponse(409, 'duel_closed');
      await pumpResult(tester, s);
      expect(title(tester).data, _l.duelResultWin, reason: 'the result still shows');
      expect(find.byKey(const ValueKey('review-unavailable')), findsOneWidget);
      expect(find.text(_l.duelReviewUnavailable), findsOneWidget);
      expect(find.byKey(const ValueKey('review-1')), findsNothing);
    });

    testWidgets('a duel finished while the app was away: the questions are downloaded again, in memory', (tester) async {
      final s = finished();
      final provider = await pumpResult(tester, s);
      expect(requestsTo(s.server, 'GET', '/duel/duels/1/questions/'), hasLength(1));
      expect(provider.questionsFor(1), isNotNull);
    });

    testWidgets('the questions are forgotten when the player leaves the screen', (tester) async {
      final s = finished();
      final provider = await pumpResult(tester, s);
      expect(provider.questionsFor(1), isNotNull);
      await tester.pumpWidget(const SizedBox());
      expect(provider.questionsFor(1), isNull);
    });

    testWidgets('Back to duels leaves the result', (tester) async {
      tallScreen(tester);
      final s = finished();
      final provider = DuelProvider(service: s.server.service);
      await pumpLive(
        tester,
        duel: provider,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DuelLiveScreen(duelId: 1, now: s.clock.now),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('back-to-duels')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('open'), findsOneWidget);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
    });
  });

  group('waiting for the result', () {
    testWidgets('waits for the other; the result arrives at the next look', (tester) async {
      final s = Scenario();
      var done = false;
      var opponentDone = false;
      s.state = (now) => done
          ? duelJson(
              serverTime: now,
              status: 'finished',
              startsAt: now.subtract(const Duration(minutes: 2)),
              mySubmitted: true,
              opponentSubmitted: true,
              result: resultJson(),
            )
          : duelJson(
              serverTime: now,
              status: 'playing',
              startsAt: now.subtract(const Duration(seconds: 70)),
              deadlineAt: now.add(const Duration(seconds: 100)),
              mySubmitted: true,
              opponentSubmitted: opponentDone,
            );
      await pumpResult(tester, s);
      expect(find.text(_l.duelAnswersSent), findsOneWidget);
      expect(find.text(_l.duelWaitingOpponentFinish('alice')), findsOneWidget);
      expect(find.text(_l.duelResultAtLatest('1:40')), findsOneWidget);

      opponentDone = true;
      await elapse(tester, s.clock, const Duration(seconds: 3));
      expect(find.text(_l.duelComputingResult), findsOneWidget);

      done = true;
      await elapse(tester, s.clock, const Duration(seconds: 3));
      expect(title(tester).data, _l.duelResultWin);
    });

    testWidgets('the state is read every 2.5 s while waiting', (tester) async {
      final s = Scenario();
      s.state = (now) => duelJson(
        serverTime: now,
        status: 'playing',
        startsAt: now.subtract(const Duration(seconds: 70)),
        mySubmitted: true,
      );
      await pumpResult(tester, s);
      final before = requestsTo(s.server, 'GET', '/duel/duels/1/').length;
      await elapse(tester, s.clock, const Duration(seconds: 10));
      final polls = requestsTo(s.server, 'GET', '/duel/duels/1/').length - before;
      expect(polls, inInclusiveRange(3, 5));
    });
  });
}
