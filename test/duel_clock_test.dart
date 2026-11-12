import 'package:flutter_test/flutter_test.dart';

import 'package:QuizzBuilder/utils/duel_clock.dart';

void main() {
  final startsAt = DateTime.utc(2026, 11, 12, 18, 0, 8);
  final schedule = DuelSchedule(
    startsAt: startsAt,
    secondsPerQuestion: 20,
    questionCount: 10,
  );
  DateTime at(int secondsFromStart, [int ms = 0]) =>
      startsAt.add(Duration(seconds: secondsFromStart, milliseconds: ms));

  group('offset', () {
    test('phone behind the server: positive offset', () {
      final phone = DateTime.utc(2026, 11, 12, 18, 0, 0);
      final server = DateTime.utc(2026, 11, 12, 18, 0, 5);
      expect(
        duelClockOffset(serverTime: server, phoneTime: phone),
        const Duration(seconds: 5),
      );
    });

    test('phone ahead of the server: negative offset', () {
      final phone = DateTime.utc(2026, 11, 12, 18, 0, 5);
      final server = DateTime.utc(2026, 11, 12, 18, 0, 0);
      expect(
        duelClockOffset(serverTime: server, phoneTime: phone),
        const Duration(seconds: -5),
      );
    });

    test('request midpoint halves the round trip', () {
      final sent = DateTime.utc(2026, 11, 12, 18, 0, 0);
      final received = sent.add(const Duration(milliseconds: 800));
      expect(
        duelRequestMidpoint(sent, received),
        sent.add(const Duration(milliseconds: 400)),
      );
    });
  });

  group('countdown', () {
    test('before the start: countdown with the time left', () {
      final m = schedule.momentAt(at(-8), Duration.zero);
      expect(m.stage, DuelStage.countdown);
      expect(m.untilStart, const Duration(seconds: 8));
      expect(m.questionIndex, isNull);
    });

    test('one millisecond before the start is still the countdown', () {
      final m = schedule.momentAt(at(0, -1), Duration.zero);
      expect(m.stage, DuelStage.countdown);
      expect(m.untilStart, const Duration(milliseconds: 1));
    });
  });

  group('windows', () {
    test('exactly at the start, question 1 opens with the full 20 s', () {
      final m = schedule.momentAt(at(0), Duration.zero);
      expect(m.stage, DuelStage.question);
      expect(m.questionIndex, 0);
      expect(m.questionRemaining, const Duration(seconds: 20));
    });

    test('last millisecond of window 1 is still question 1', () {
      final m = schedule.momentAt(at(19, 999), Duration.zero);
      expect(m.questionIndex, 0);
      expect(m.questionRemaining, const Duration(milliseconds: 1));
    });

    test('exactly at 20 s question 2 opens (window ends are exclusive)', () {
      final m = schedule.momentAt(at(20), Duration.zero);
      expect(m.questionIndex, 1);
      expect(m.questionRemaining, const Duration(seconds: 20));
    });

    test('every window opens at start + (n - 1) x 20 s', () {
      for (var n = 1; n <= 10; n++) {
        final opens = at((n - 1) * 20);
        expect(schedule.momentAt(opens, Duration.zero).questionIndex, n - 1);
        expect(schedule.opensAt(n - 1), opens);
      }
    });

    test('the wait after an answer runs to the next window', () {
      final m = schedule.momentAt(at(5), Duration.zero);
      expect(m.untilNextWindow, const Duration(seconds: 15));
    });
  });

  group('last question and end', () {
    test('last window: question 10, its end is the end of the game', () {
      final m = schedule.momentAt(at(199, 500), Duration.zero);
      expect(m.stage, DuelStage.question);
      expect(m.questionIndex, 9);
      expect(m.untilNextWindow, const Duration(milliseconds: 500));
    });

    test('exactly at start + 10 x 20 s the game is over', () {
      expect(schedule.endsAt, at(200));
      final m = schedule.momentAt(at(200), Duration.zero);
      expect(m.stage, DuelStage.finished);
      expect(m.questionIndex, isNull);
    });

    test('long after the end: still finished', () {
      expect(schedule.momentAt(at(10000), Duration.zero).stage, DuelStage.finished);
    });
  });

  group('offset applied to the phone clock', () {
    test('positive offset: the phone is behind, so the server is later', () {
      // Phone says start - 3 s, but the server is 5 s ahead: server time is
      // start + 2 s, question 1 is open with 18 s left.
      final m = schedule.momentAt(at(-3), const Duration(seconds: 5));
      expect(m.stage, DuelStage.question);
      expect(m.questionIndex, 0);
      expect(m.questionRemaining, const Duration(seconds: 18));
    });

    test('negative offset: the phone is ahead, the countdown lasts longer', () {
      // Phone says start + 2 s, but the server is 5 s behind: server time is
      // start - 3 s, still the countdown.
      final m = schedule.momentAt(at(2), const Duration(seconds: -5));
      expect(m.stage, DuelStage.countdown);
      expect(m.untilStart, const Duration(seconds: 3));
    });

    test('two phones with opposite errors agree on the window', () {
      final server = at(25); // question 2, 15 s left
      final behind = server.subtract(const Duration(seconds: 7));
      final ahead = server.add(const Duration(seconds: 9));
      final a = schedule.momentAt(behind, const Duration(seconds: 7));
      final b = schedule.momentAt(ahead, const Duration(seconds: -9));
      expect(a.questionIndex, 1);
      expect(b.questionIndex, 1);
      expect(a.questionRemaining, b.questionRemaining);
    });
  });

  group('display', () {
    test('seconds are rounded up, never 0:00 while a window is open', () {
      expect(duelCeilSeconds(const Duration(milliseconds: 1)), 1);
      expect(duelCeilSeconds(const Duration(milliseconds: 1000)), 1);
      expect(duelCeilSeconds(const Duration(milliseconds: 1001)), 2);
      expect(duelCeilSeconds(Duration.zero), 0);
      expect(duelCeilSeconds(const Duration(seconds: -3)), 0);
    });

    test('m:ss', () {
      expect(duelFormatClock(const Duration(seconds: 9)), '0:09');
      expect(duelFormatClock(const Duration(seconds: 14)), '0:14');
      expect(duelFormatClock(const Duration(minutes: 9, seconds: 41)), '9:41');
      expect(duelFormatClock(const Duration(milliseconds: 20000)), '0:20');
    });
  });
}
