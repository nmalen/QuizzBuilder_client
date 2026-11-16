import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/ui/duel/duel_controller.dart';

import 'support/duel_game_support.dart';
import 'support/duel_live_support.dart';

/// The answer of a duel question can be changed for as long as the time of the
/// question runs (decision of 16/11): these tests drive the controller itself,
/// on a phone clock that only moves when told to.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  }

  /// Runs [body] with a controller in the game: starts 8 s in, 3 questions of
  /// 20 s, the phone clock 10 s after the beginning of the test (2 s into the
  /// first question). The controller is released at the end (its ticker is a
  /// timer).
  void game(
    String name,
    Future<void> Function(WidgetTester tester, DuelController c, Game g) body,
  ) {
    testWidgets(name, (tester) async {
      final g = Game();
      final c = DuelController(
        provider: DuelProvider(service: g.s.server.service),
        duelId: 1,
        now: g.clock.now,
      );
      try {
        await c.open();
        await settle(tester);
        await elapse(tester, g.clock, const Duration(seconds: 10));
        expect(c.phase, DuelPhase.game);
        expect(c.currentIndex, 0);
        await body(tester, c, g);
      } finally {
        c.dispose();
      }
    });
  }

  game('a new choice replaces the previous one', (tester, c, g) async {
    expect(c.answer(2), isTrue);
    expect(c.currentAnswer, 2);
    expect(c.answer(3), isTrue);
    expect(c.currentAnswer, 3);
    expect(c.answer(1), isTrue);
    expect(c.currentAnswer, 1);
    expect(c.answers, [1, null, null]);
  });

  game('the same choice again changes nothing and tells nothing', (
    tester,
    c,
    g,
  ) async {
    expect(c.answer(2), isTrue);
    var notified = 0;
    c.addListener(() => notified++);
    expect(c.answer(2), isFalse);
    expect(c.currentAnswer, 2, reason: 'no way back to "no answer"');
    expect(notified, 0);
  });

  game('a choice outside 1-4 is refused, and keeps the answer given', (
    tester,
    c,
    g,
  ) async {
    expect(c.answer(0), isFalse);
    expect(c.answer(5), isFalse);
    expect(c.answer(-1), isFalse);
    expect(c.currentAnswer, isNull);
    expect(c.answer(4), isTrue);
    expect(c.answer(0), isFalse);
    expect(c.answer(5), isFalse);
    expect(c.currentAnswer, 4);
  });

  game('a change counts until the last instant of the question', (
    tester,
    c,
    g,
  ) async {
    expect(c.answer(2), isTrue);
    // 19.75 s into Q1 (the clock is 2 s in).
    await elapse(tester, g.clock, const Duration(milliseconds: 17750));
    expect(c.currentIndex, 0);
    expect(c.answer(3), isTrue, reason: '250 ms before the end');
    expect(c.currentAnswer, 3);
  });

  game(
    'the question is over at its end: a tap before the next tick cannot '
    'change it',
    (tester, c, g) async {
      expect(c.answer(2), isTrue);
      // Question 1 ended, but the controller has not ticked yet: it still
      // shows question 1. The clock, not the last tick, decides.
      g.clock.advance(const Duration(seconds: 18));
      expect(c.currentIndex, 0, reason: 'the screen has not caught up yet');
      expect(c.answer(3), isFalse);
      expect(c.answers, [2, null, null]);
    },
  );

  game('a change on a later question leaves the earlier answers alone', (
    tester,
    c,
    g,
  ) async {
    expect(c.answer(2), isTrue);
    await elapse(tester, g.clock, const Duration(seconds: 18)); // Q2 opens
    expect(c.currentIndex, 1);
    expect(c.currentAnswer, isNull);
    expect(c.answer(4), isTrue);
    expect(c.answer(1), isTrue);
    expect(c.answers, [2, 1, null]);
  });

  game('the answers sent carry the last choice of each question', (
    tester,
    c,
    g,
  ) async {
    expect(c.answer(2), isTrue);
    expect(c.answer(3), isTrue);
    expect(c.answer(1), isTrue);
    await elapse(tester, g.clock, const Duration(seconds: 18)); // Q2: no answer
    await elapse(tester, g.clock, const Duration(seconds: 20)); // Q3
    expect(c.answer(4), isTrue);
    expect(c.answer(2), isTrue);
    expect(g.answerPosts, isEmpty, reason: 'nothing leaves during the game');

    await elapse(tester, g.clock, const Duration(seconds: 21)); // game over
    await settle(tester);
    expect(g.answersOf(g.answerPosts.single), [1, null, 2]);
  });

  game('once the sending has begun, nothing changes any more', (
    tester,
    c,
    g,
  ) async {
    expect(c.answer(2), isTrue);
    await elapse(tester, g.clock, const Duration(seconds: 58)); // end of game
    await settle(tester);
    expect(c.phase, isNot(DuelPhase.game));
    expect(c.answer(3), isFalse);
    expect(c.answers, [2, null, null]);
    expect(g.answersOf(g.answerPosts.single), [2, null, null]);
  });

  game('leaving on purpose sends the answer shown, and freezes it', (
    tester,
    c,
    g,
  ) async {
    expect(c.answer(2), isTrue);
    expect(c.answer(4), isTrue);
    c.quit();
    await settle(tester);
    expect(c.answer(1), isFalse, reason: 'the sending has begun');
    expect(g.answersOf(g.answerPosts.single), [4, null, null]);
  });
}
