import 'dart:convert';

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
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void _background(WidgetTester tester) {
  for (final s in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

void _foreground(WidgetTester tester) {
  for (final s in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

/// A game of [count] questions that starts 8 s after the test begins (on the
/// server clock), with the phone [skew] behind the server.
class Game {
  Game({Duration skew = Duration.zero, this.count = 3, Duration startsIn = const Duration(seconds: 8)})
    : s = Scenario(skew: skew, questionCount: count) {
    s.startsAt = s.serverNow.add(startsIn);
    s.state = (now) => duelJson(
      serverTime: now,
      status: 'playing',
      startsAt: s.startsAt,
      questionCount: count,
      mySubmitted: submitted,
      opponentSubmitted: opponentSubmitted,
      challengedByMe: false,
    );
    s.intercept = (r) {
      if (r.method == 'POST' &&
          r.path.endsWith('/answers/') &&
          s.answersOverride == null) {
        submitted = true;
      }
      return null;
    };
  }

  final Scenario s;
  final int count;
  bool submitted = false;
  bool opponentSubmitted = false;

  FakeClock get clock => s.clock;

  List<RecordedRequest> get answerPosts =>
      requestsTo(s.server, 'POST', '/answers/').toList();

  List<Object?> answersOf(RecordedRequest r) =>
      (jsonDecode(r.body) as Map)['answers'] as List<Object?>;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<DuelProvider> pumpGame(WidgetTester tester, Game g, {bool pushed = false}) async {
    final provider = DuelProvider(service: g.s.server.service);
    final screen = DuelLiveScreen(
      duelId: 1,
      now: g.clock.now,
      retryEvery: const Duration(seconds: 2),
    );
    if (pushed) {
      await pumpLive(
        tester,
        duel: provider,
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
      await pumpLive(tester, home: screen, duel: provider);
    }
    await _settle(tester);
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    return provider;
  }

  String questionLabel(int n) => _l.duelQuestionOf(n, 3);

  Color? answerColor(WidgetTester tester, int n) {
    final button = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byKey(ValueKey('duel-answer-$n')),
        matching: find.byType(ElevatedButton),
      ),
    );
    return button.style?.backgroundColor?.resolve({});
  }

  group('countdown and first question', () {
    testWidgets('countdown, then question 1 opens exactly at the start', (tester) async {
      final g = Game();
      await pumpGame(tester, g);
      expect(find.byKey(const ValueKey('countdown-number')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('countdown-number'))).data,
        '8',
      );
      expect(find.text(_l.duelNoCorrectionHint), findsOneWidget);
      expect(find.byType(BackButton), findsNothing, reason: 'no way back in 8 s');

      await elapse(tester, g.clock, const Duration(seconds: 3));
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('countdown-number'))).data,
        '5',
      );
      await elapse(tester, g.clock, const Duration(seconds: 5));
      expect(find.text(questionLabel(1)), findsOneWidget);
      expect(find.text('Question EN 1?'), findsOneWidget);
      expect(find.text('Geography'), findsOneWidget);
      expect(find.text('Answer 1 of 1'), findsOneWidget);
      expect(find.text('0:20'), findsOneWidget);
      expect(requestsTo(g.s.server, 'GET', '/duel/duels/1/questions/'), hasLength(1));
    });

    testWidgets('the countdown cannot be left with the system back', (tester) async {
      final g = Game();
      await pumpGame(tester, g, pushed: true);
      await tester.binding.handlePopRoute();
      await _pumpDialog(tester);
      expect(find.byKey(const ValueKey('countdown-number')), findsOneWidget);
      expect(find.text('open'), findsNothing);
    });

    testWidgets('French question and answers when the app is in French', (tester) async {
      final g = Game();
      final provider = DuelProvider(service: g.s.server.service);
      await pumpLive(
        tester,
        locale: 'fr',
        duel: provider,
        home: DuelLiveScreen(duelId: 1, now: g.clock.now),
      );
      await _settle(tester);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      await elapse(tester, g.clock, const Duration(seconds: 8));
      expect(find.text('Question 1/3'), findsOneWidget);
      expect(find.text('Question FR 1 ?'), findsOneWidget);
      expect(find.text('Géographie'), findsOneWidget);
    });
  });

  group('answering', () {
    testWidgets('an answer waits for the next question: dark blue with a check, others grey, no green or red', (tester) async {
      final g = Game();
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 11)); // 3 s into Q1
      expect(answerColor(tester, 1), Colors.blue);

      await tester.tap(find.byKey(const ValueKey('duel-answer-2')));
      await tester.pump();
      expect(find.text(_l.duelAnswerSaved('0:17')), findsOneWidget);
      expect(answerColor(tester, 2), Colors.blue.shade900);
      for (final n in [1, 3, 4]) {
        expect(answerColor(tester, n), Colors.grey);
      }
      for (final n in [1, 2, 3, 4]) {
        final color = answerColor(tester, n);
        expect(color, isNot(Colors.green));
        expect(color, isNot(Colors.red));
      }
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('duel-answer-2')),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      expect(find.text(questionLabel(1)), findsOneWidget, reason: 'still question 1');
    });

    testWidgets('the answer is final: a second tap changes nothing', (tester) async {
      final g = Game();
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 10));
      await tester.tap(find.byKey(const ValueKey('duel-answer-2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('duel-answer-3')), warnIfMissed: false);
      await tester.pump();
      expect(answerColor(tester, 2), Colors.blue.shade900);
      expect(answerColor(tester, 3), Colors.grey);
    });

    testWidgets('the next question opens on time, and the last one says the game ends', (tester) async {
      final g = Game();
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 10));
      await tester.tap(find.byKey(const ValueKey('duel-answer-2')));
      await tester.pump();
      await elapse(tester, g.clock, const Duration(seconds: 18)); // 20 s into Q1 + 8 s start
      expect(find.text(questionLabel(2)), findsOneWidget);
      expect(find.text('Question EN 2?'), findsOneWidget);
      expect(find.byKey(const ValueKey('answer-saved')), findsNothing);

      await elapse(tester, g.clock, const Duration(seconds: 20));
      expect(find.text(questionLabel(3)), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('duel-answer-1')));
      await tester.pump();
      expect(find.textContaining('The game ends in'), findsOneWidget);
    });

    testWidgets('the timer turns red in the last 5 seconds', (tester) async {
      final g = Game();
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 8 + 14));
      Color? timerColor() => tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(const ValueKey('duel-timer')),
              matching: find.byIcon(Icons.timer),
            ),
          )
          .color;
      expect(timerColor(), Colors.black87);
      await elapse(tester, g.clock, const Duration(seconds: 2));
      expect(timerColor(), Colors.red);
    });
  });

  group('time runs out', () {
    testWidgets('an unanswered question is null and a notice shows; one single sending at the end', (tester) async {
      final g = Game();
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 10));
      await tester.tap(find.byKey(const ValueKey('duel-answer-2')));
      await tester.pump();

      await elapse(tester, g.clock, const Duration(seconds: 18)); // Q2 opens
      expect(find.byKey(const ValueKey('time-up')), findsNothing, reason: 'Q1 was answered');

      await elapse(tester, g.clock, const Duration(seconds: 20)); // Q2 unanswered -> Q3
      expect(find.text(questionLabel(3)), findsOneWidget);
      expect(find.text(_l.duelTimeUp), findsOneWidget);
      await elapse(tester, g.clock, const Duration(seconds: 3));
      expect(find.text(_l.duelTimeUp), findsNothing, reason: 'the notice goes away by itself');

      await tester.tap(find.byKey(const ValueKey('duel-answer-4')));
      await tester.pump();
      expect(g.answerPosts, isEmpty, reason: 'nothing is sent during the game');

      await elapse(tester, g.clock, const Duration(seconds: 20));
      await _settle(tester);
      expect(g.answerPosts, hasLength(1));
      expect(g.answersOf(g.answerPosts.single), [2, null, 4]);
      expect(find.text(_l.duelAnswersSent), findsOneWidget);

      await elapse(tester, g.clock, const Duration(seconds: 30));
      expect(g.answerPosts, hasLength(1), reason: 'sent once, never again');
    });

    testWidgets('no answer at all: three nulls, sent at the end of the last window', (tester) async {
      final g = Game();
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 8 + 59));
      expect(g.answerPosts, isEmpty);
      await elapse(tester, g.clock, const Duration(seconds: 2));
      await _settle(tester);
      expect(g.answersOf(g.answerPosts.single), [null, null, null]);
    });

    testWidgets('the answers are sent between starts_at and deadline_at', (tester) async {
      final g = Game();
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 8 + 61));
      await _settle(tester);
      final sentAt = g.clock.now(); // phone clock; skew is zero
      final startsAt = g.s.startsAt!;
      expect(sentAt.isAfter(startsAt), isTrue);
      expect(sentAt.isBefore(startsAt.add(const Duration(seconds: 80))), isTrue);
    });
  });

  group('the network drops while sending', () {
    testWidgets('the same answers are sent again until it works', (tester) async {
      final g = Game();
      var failures = 2;
      g.s.answersOverride = (r) {
        if (failures > 0) {
          failures--;
          return Scenario.network();
        }
        g.submitted = true;
        return jsonResponse(
          200,
          duelJson(
            serverTime: g.s.serverNow,
            status: 'playing',
            startsAt: g.s.startsAt,
            questionCount: 3,
            mySubmitted: true,
          ),
        );
      };
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 10));
      await tester.tap(find.byKey(const ValueKey('duel-answer-3')));
      await tester.pump();

      await elapse(tester, g.clock, const Duration(seconds: 59));
      await _settle(tester);
      expect(g.answerPosts, hasLength(1));
      expect(find.text(_l.duelSendRetry), findsOneWidget);

      await elapse(tester, g.clock, const Duration(seconds: 5));
      expect(g.answerPosts, hasLength(3), reason: 'two failures then one success');
      final bodies = g.answerPosts.map((r) => r.body).toSet();
      expect(bodies, hasLength(1), reason: 'identical bodies');
      expect(g.answersOf(g.answerPosts.first), [3, null, null]);
      expect(find.text(_l.duelSendRetry), findsNothing);
      expect(find.text(_l.duelAnswersSent), findsOneWidget);
    });

    testWidgets('a refusal after the deadline stops the sending and waits for the result', (tester) async {
      final g = Game();
      g.s.answersOverride = (r) => errorResponse(409, 'duel_deadline_passed');
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 8 + 61));
      await _settle(tester);
      await elapse(tester, g.clock, const Duration(seconds: 6));
      expect(g.answerPosts, hasLength(1), reason: 'no point in sending again');
      expect(find.text(_l.duelAnswersSent), findsOneWidget);
    });
  });

  group('leaving the game on purpose', () {
    testWidgets('back asks first; "Keep playing" sends nothing', (tester) async {
      final g = Game();
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 12));
      await tester.tap(find.byType(BackButton));
      await _pumpDialog(tester);
      expect(find.text(_l.duelQuitTitle), findsOneWidget);
      expect(find.text(_l.duelQuitBody), findsOneWidget);
      await tester.tap(find.text(_l.duelKeepPlaying));
      await _pumpDialog(tester);
      expect(g.answerPosts, isEmpty);
      expect(find.text(questionLabel(1)), findsOneWidget);
    });

    testWidgets('Leave: the answers so far are sent at once, the rest is null, then waits for the result', (tester) async {
      final g = Game();
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 10));
      await tester.tap(find.byKey(const ValueKey('duel-answer-3')));
      await tester.pump();
      await elapse(tester, g.clock, const Duration(seconds: 17)); // into Q2

      await tester.tap(find.byType(BackButton));
      await _pumpDialog(tester);
      await tester.tap(find.text(_l.duelQuitAction));
      await tester.pump();
      await _settle(tester);

      expect(g.answerPosts, hasLength(1));
      expect(g.answersOf(g.answerPosts.single), [3, null, null]);
      expect(find.text(_l.duelAnswersSent), findsOneWidget);
      expect(find.text(_l.duelWaitingOpponentFinish('alice')), findsOneWidget);
    });

    testWidgets('the system back asks the same question', (tester) async {
      final g = Game();
      await pumpGame(tester, g, pushed: true);
      await elapse(tester, g.clock, const Duration(seconds: 12));
      await tester.binding.handlePopRoute();
      await _pumpDialog(tester);
      expect(find.text(_l.duelQuitTitle), findsOneWidget);
      expect(g.answerPosts, isEmpty);
    });
  });

  group('app in the background, or killed', () {
    testWidgets('back from the background: the open question follows the clock, missed ones are null', (tester) async {
      final g = Game();
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 13)); // 5 s into Q1
      _background(tester);
      await tester.pump();
      g.clock.advance(const Duration(seconds: 25)); // 30 s into the game: Q2
      _foreground(tester);
      await tester.pump(const Duration(milliseconds: 300));
      g.clock.advance(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(questionLabel(2)), findsOneWidget);
      expect(find.text(_l.duelTimeUp), findsOneWidget, reason: 'Q1 passed unanswered');
      await tester.tap(find.byKey(const ValueKey('duel-answer-4')));
      await tester.pump();

      await elapse(tester, g.clock, const Duration(seconds: 60));
      await _settle(tester);
      expect(g.answersOf(g.answerPosts.single), [null, 4, null]);
    });

    testWidgets('long in the background: the game is over, null answers are sent', (tester) async {
      final g = Game();
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 12));
      _background(tester);
      await tester.pump();
      g.clock.advance(const Duration(seconds: 70)); // past the end (68 s)
      _foreground(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await _settle(tester);
      expect(g.answersOf(g.answerPosts.single), [null, null, null]);
    });

    testWidgets('app killed: the duel reopens mid-game, questions downloaded again, earlier answers are null', (tester) async {
      final g = Game(startsIn: const Duration(seconds: -45)); // Q3 is open
      final provider = await pumpGame(tester, g);
      expect(provider.questionsFor(1), isNotNull);
      expect(find.byKey(const ValueKey('countdown-number')), findsNothing);
      expect(find.text(questionLabel(3)), findsOneWidget);
      expect(requestsTo(g.s.server, 'GET', '/duel/duels/1/questions/'), hasLength(1));

      await tester.tap(find.byKey(const ValueKey('duel-answer-4')));
      await tester.pump();
      await elapse(tester, g.clock, const Duration(seconds: 16));
      await _settle(tester);
      expect(g.answersOf(g.answerPosts.single), [null, null, 4]);
    });

    testWidgets('a duel whose answers were already sent opens on the waiting screen', (tester) async {
      final g = Game(startsIn: const Duration(seconds: -30));
      g.submitted = true;
      await pumpGame(tester, g);
      expect(find.text(_l.duelAnswersSent), findsOneWidget);
      expect(g.answerPosts, isEmpty);
      expect(requestsTo(g.s.server, 'GET', '/questions/'), isEmpty);
    });
  });

  group('questions that do not come', () {
    testWidgets('fetched again every second during the countdown', (tester) async {
      final g = Game();
      var failures = 2;
      g.s.questionsOverride = () {
        if (failures > 0) {
          failures--;
          return Scenario.network();
        }
        return jsonResponse(
          200,
          questionsPayload(count: 3, startsAt: g.s.startsAt!, serverTime: g.s.serverNow),
        );
      };
      await pumpGame(tester, g);
      expect(find.text(_l.duelLoadingQuestions), findsOneWidget);
      await elapse(tester, g.clock, const Duration(seconds: 8));
      expect(find.text(questionLabel(1)), findsOneWidget);
      expect(requestsTo(g.s.server, 'GET', '/questions/'), hasLength(3));
    });

    testWidgets('still missing at the start: an error card with Retry', (tester) async {
      final g = Game();
      var down = true;
      g.s.questionsOverride = () {
        if (down) return Scenario.network();
        return jsonResponse(
          200,
          questionsPayload(count: 3, startsAt: g.s.startsAt!, serverTime: g.s.serverNow),
        );
      };
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 12));
      expect(find.text(_l.duelErrNetwork), findsOneWidget);
      down = false;
      await tester.tap(find.text(_l.retry));
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(questionLabel(1)), findsOneWidget);
    });
  });

  group('the phone clock is wrong', () {
    testWidgets('phone behind the server (positive offset): question 1 opens at the server start', (tester) async {
      final g = Game(skew: const Duration(seconds: 5));
      await pumpGame(tester, g);
      // starts_at is 8 s ahead on the server clock; the phone shows the same
      // 8 s wait because the offset is applied.
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('countdown-number'))).data,
        '8',
      );
      await elapse(tester, g.clock, const Duration(seconds: 7));
      expect(find.byKey(const ValueKey('countdown-number')), findsOneWidget);
      await elapse(tester, g.clock, const Duration(seconds: 1));
      expect(find.text(questionLabel(1)), findsOneWidget);
    });

    testWidgets('a start fixed for server time, phone 5 s behind: no early start, no late start', (tester) async {
      final g = Game(skew: const Duration(seconds: 5), startsIn: const Duration(seconds: 3));
      await pumpGame(tester, g);
      // Without the offset the phone would think the start is 3 s away and
      // would also compare phone time with a server instant.
      await elapse(tester, g.clock, const Duration(seconds: 2, milliseconds: 500));
      expect(find.byKey(const ValueKey('countdown-number')), findsOneWidget);
      await elapse(tester, g.clock, const Duration(milliseconds: 500));
      expect(find.text(questionLabel(1)), findsOneWidget);
    });

    testWidgets('phone ahead of the server (negative offset): the countdown lasts the real time', (tester) async {
      final g = Game(skew: const Duration(seconds: -5));
      await pumpGame(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 7));
      expect(find.byKey(const ValueKey('countdown-number')), findsOneWidget);
      await elapse(tester, g.clock, const Duration(seconds: 1));
      expect(find.text(questionLabel(1)), findsOneWidget);
    });

    testWidgets('the offset is recalculated at every server answer', (tester) async {
      final s = Scenario();
      s.state = (now) => duelJson(
        serverTime: now,
        roomExpiresAt: FakeClock.base.add(const Duration(minutes: 10)),
      );
      final provider = DuelProvider(service: s.server.service);
      await pumpLive(
        tester,
        duel: provider,
        home: DuelLiveScreen(duelId: 1, now: s.clock.now),
      );
      await _settle(tester);
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      expect(find.text(_l.duelRoomTimeLeft('10:00')), findsOneWidget);

      s.skew = const Duration(minutes: 1); // the server clock moved ahead
      await elapse(tester, s.clock, const Duration(seconds: 3));
      expect(find.text(_l.duelRoomTimeLeft('8:57')), findsOneWidget);
    });
  });
}
