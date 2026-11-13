import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/ui/duel/duel_live_screen.dart';
import 'package:QuizzBuilder/utils/duel_clock.dart';

import 'support/duel_live_support.dart';
import 'support/duel_scenario.dart';
import 'support/duel_test_support.dart';

/// The game once the time per question is the players' choice (5, 10, 15 s):
/// the offline warning, the countdown when sending fails, and the compact
/// layout (timer and bar on one row, notice over the card, red threshold).
final _l = AppLocalizationsEn();

const _warning = ValueKey('offline-warning');
Finder get _warningFinder => find.byKey(_warning);

/// A game of [count] questions of [seconds] s, starting 8 s after the test
/// begins on the server clock, the phone [skew] behind the server.
class _Game {
  _Game({
    this.seconds = 10,
    this.count = 3,
    Duration skew = Duration.zero,
    this.submitted = false,
  }) : s = Scenario(
         skew: skew,
         questionCount: count,
         secondsPerQuestion: seconds,
       ) {
    s.startsAt = s.serverNow.add(const Duration(seconds: 8));
    s.state = (now) => duelJson(
      serverTime: now,
      status: 'playing',
      startsAt: s.startsAt,
      questionCount: count,
      secondsPerQuestion: seconds,
      mySubmitted: submitted,
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
  final int seconds;
  final int count;
  bool submitted;

  FakeClock get clock => s.clock;

  /// `deadline_at` as the phone's own clock will reach it: the game starts 8 s
  /// after the test begins **on the phone clock** whatever the skew.
  DateTime get phoneDeadline =>
      FakeClock.base.add(Duration(seconds: 8 + seconds * count + 20));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<FakeConnectivity> pump(WidgetTester tester, _Game g) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final connectivity = FakeConnectivity();
    await pumpLive(
      tester,
      home: DuelLiveScreen(duelId: 1, now: g.clock.now),
      duel: DuelProvider(service: g.s.server.service),
      connectivity: connectivity,
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    return connectivity;
  }

  /// `HH:mm:ss` of [t] in the device zone, as the screen formats it.
  String hms(DateTime t) => DateFormat.Hms('en').format(t.toLocal());

  group('offline warning, in the game', () {
    testWidgets('appears after 2 s offline, goes the moment the network is back', (tester) async {
      final g = _Game();
      final connectivity = await pump(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 8, milliseconds: 500));
      expect(find.byKey(const ValueKey('duel-timer')), findsOneWidget, reason: 'in the game');
      expect(_warningFinder, findsNothing);

      connectivity.setOnline(false);
      await tester.pump();
      await elapse(tester, g.clock, const Duration(milliseconds: 1750));
      expect(_warningFinder, findsNothing, reason: '1.75 s: a Wi-Fi to mobile handover must not flash it');
      await elapse(tester, g.clock, const Duration(milliseconds: 500));
      expect(_warningFinder, findsOneWidget, reason: '2.25 s offline');
      expect(find.text(_l.duelGameOfflineTitle), findsOneWidget);

      connectivity.setOnline(true);
      await tester.pump();
      expect(_warningFinder, findsNothing, reason: 'gone at once, no delay');
    });

    testWidgets('a short loss of network never shows it', (tester) async {
      final g = _Game();
      final connectivity = await pump(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 9));
      connectivity.setOnline(false);
      await tester.pump();
      await elapse(tester, g.clock, const Duration(milliseconds: 1500));
      connectivity.setOnline(true);
      await tester.pump();
      await elapse(tester, g.clock, const Duration(seconds: 3));
      expect(_warningFinder, findsNothing);
    });

    testWidgets('not in the countdown; there from the first question if offline for 2 s by then', (tester) async {
      final g = _Game();
      final connectivity = await pump(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 1));
      connectivity.setOnline(false);
      await tester.pump();
      await elapse(tester, g.clock, const Duration(seconds: 4));
      expect(find.byKey(const ValueKey('countdown-number')), findsOneWidget);
      expect(_warningFinder, findsNothing, reason: 'countdown, 4 s offline');
      await elapse(tester, g.clock, const Duration(seconds: 3, milliseconds: 500));
      // The questions came before the network went; the game is on.
      expect(find.byKey(const ValueKey('duel-timer')), findsOneWidget);
      expect(_warningFinder, findsOneWidget, reason: 'game started, offline for 7.5 s');
    });

    testWidgets('not while waiting for the result (the answers are in)', (tester) async {
      final g = _Game(submitted: true);
      final connectivity = await pump(tester, g);
      expect(find.byKey(const ValueKey('waiting-title')), findsOneWidget);
      connectivity.setOnline(false);
      await tester.pump();
      await elapse(tester, g.clock, const Duration(seconds: 6));
      expect(_warningFinder, findsNothing);
      expect(find.byKey(const ValueKey('send-deadline-warning')), findsNothing);
    });

    for (final (name, skew) in [
      ('phone behind the server (positive offset)', const Duration(seconds: 30)),
      ('phone ahead of the server (negative offset)', const Duration(seconds: -20)),
      ('phone on time', Duration.zero),
    ]) {
      testWidgets('the time is the deadline on the phone clock, to the second: $name', (tester) async {
        final g = _Game(skew: skew);
        final connectivity = await pump(tester, g);
        await elapse(tester, g.clock, const Duration(seconds: 9));
        connectivity.setOnline(false);
        await tester.pump();
        await elapse(tester, g.clock, const Duration(seconds: 3));
        final text = tester.widget<Text>(find.byKey(const ValueKey('offline-warning-text'))).data;
        expect(text, _l.duelDeadlineWarning(hms(g.phoneDeadline)));
        if (skew != Duration.zero) {
          // The raw server deadline would be wrong by the skew.
          final raw = g.phoneDeadline.add(skew);
          expect(text, isNot(contains(hms(raw))), reason: 'not the uncorrected server time');
        }
      });
    }

    testWidgets('a 5 x 5 s game: the narrow 45 s margin is not rounded to the minute', (tester) async {
      final g = _Game(seconds: 5, count: 5);
      final connectivity = await pump(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 9));
      connectivity.setOnline(false);
      await tester.pump();
      await elapse(tester, g.clock, const Duration(seconds: 3));
      final text = tester.widget<Text>(find.byKey(const ValueKey('offline-warning-text'))).data!;
      // 8 s start + 25 s of questions + 20 s margin = 53 s after the base.
      expect(text, _l.duelDeadlineWarning(hms(g.phoneDeadline)));
      expect(text, contains(':53,'), reason: 'to the second, not rounded to the minute');
      expect(RegExp(r'\d\d:\d\d:\d\d').hasMatch(text), isTrue, reason: 'HH:MM:SS, not HH:MM');
    });
  });

  group('when sending fails', () {
    testWidgets('the same warning and a countdown to the deadline', (tester) async {
      final g = _Game();
      g.s.answersOverride = (_) => Scenario.network();
      await pump(tester, g);
      // 8 s start + 30 s of questions, then 4 s of failed attempts.
      await elapse(tester, g.clock, const Duration(seconds: 8 + 30 + 4));
      expect(find.text(_l.duelSendRetry), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('send-deadline-warning'))).data,
        _l.duelDeadlineWarning(hms(g.phoneDeadline)),
      );
      // Deadline = end + 20 s; 4 s have gone: 16 s left.
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('send-time-left'))).data,
        _l.duelSendTimeLeft('0:16'),
      );
      await elapse(tester, g.clock, const Duration(seconds: 5));
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('send-time-left'))).data,
        _l.duelSendTimeLeft('0:11'),
        reason: 'it counts down',
      );
      // The network is back: the next attempt goes through and ends the retry.
      g.s.answersOverride = null;
      await elapse(tester, g.clock, const Duration(seconds: 3));
      expect(find.byKey(const ValueKey('send-time-left')), findsNothing);
    });

    testWidgets('nothing of it when the sending works', (tester) async {
      final g = _Game();
      await pump(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 8 + 30 + 1));
      expect(find.byKey(const ValueKey('send-deadline-warning')), findsNothing);
      expect(find.byKey(const ValueKey('send-time-left')), findsNothing);
      expect(_warningFinder, findsNothing);
    });
  });

  group('compact layout', () {
    Future<void> intoQuestion(WidgetTester tester, _Game g, Duration into) async {
      await pump(tester, g);
      await elapse(tester, g.clock, const Duration(seconds: 8) + into);
    }

    for (final seconds in [5, 10, 15]) {
      testWidgets('$seconds s: "time\'s up" floats over the card, the answers do not move', (tester) async {
        final g = _Game(seconds: seconds);
        await intoQuestion(tester, g, const Duration(milliseconds: 500));
        final key = const ValueKey('duel-answer-1');
        final before = tester.getTopLeft(find.byKey(key));
        final timerRow = tester.getRect(find.byKey(const ValueKey('duel-timer')));

        await elapse(tester, g.clock, Duration(seconds: seconds)); // question 1 closes unanswered
        expect(find.byKey(const ValueKey('time-up')), findsOneWidget);
        expect(tester.getTopLeft(find.byKey(key)), before, reason: 'no shift of the answers');
        expect(tester.getRect(find.byKey(const ValueKey('duel-timer'))).top, timerRow.top);
      });

      testWidgets('$seconds s: timer and bar share one row', (tester) async {
        final g = _Game(seconds: seconds);
        await intoQuestion(tester, g, const Duration(milliseconds: 500));
        final timer = tester.getRect(find.byKey(const ValueKey('duel-timer')));
        final bar = tester.getRect(find.byKey(const ValueKey('duel-progress')));
        expect(bar.center.dy, closeTo(timer.center.dy, 1));
        expect(bar.left, greaterThan(timer.right));
      });
    }

    testWidgets('the notice lasts 1 s at 5 s, 2 s otherwise', (tester) async {
      for (final (seconds, lasts) in [(5, 1), (10, 2), (15, 2)]) {
        final g = _Game(seconds: seconds);
        await intoQuestion(tester, g, Duration(seconds: seconds));
        expect(find.byKey(const ValueKey('time-up')), findsOneWidget, reason: '$seconds s: just closed');
        await elapse(tester, g.clock, Duration(seconds: lasts) - const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('time-up')), findsOneWidget, reason: '$seconds s: still there');
        await elapse(tester, g.clock, const Duration(seconds: 1));
        expect(find.byKey(const ValueKey('time-up')), findsNothing, reason: '$seconds s: gone');
        await tester.pumpWidget(const SizedBox());
      }
    });

    for (final (seconds, thresholdSeconds) in [(5, 2), (10, 5), (15, 5)]) {
      testWidgets('$seconds s: red for the last $thresholdSeconds s, not before', (tester) async {
        final g = _Game(seconds: seconds);
        Color? timerColor() => tester
            .widget<Icon>(
              find.descendant(
                of: find.byKey(const ValueKey('duel-timer')),
                matching: find.byIcon(Icons.timer),
              ),
            )
            .color;
        Color? barColor() => tester
            .widget<LinearProgressIndicator>(find.byKey(const ValueKey('duel-progress')))
            .color;

        // Just above the threshold: 0.5 s more than it remains.
        await intoQuestion(
          tester,
          g,
          Duration(seconds: seconds - thresholdSeconds) - const Duration(milliseconds: 500),
        );
        expect(timerColor(), Colors.black87, reason: 'above the threshold');
        expect(barColor(), Colors.white);

        await elapse(tester, g.clock, const Duration(milliseconds: 500));
        expect(timerColor(), Colors.red, reason: 'at the threshold');
        expect(barColor(), Colors.red);
      });
    }

    test('thresholds and notice durations, as validated (V5)', () {
      expect(duelUrgentThreshold(5), const Duration(seconds: 2));
      expect(duelUrgentThreshold(10), const Duration(seconds: 5));
      expect(duelUrgentThreshold(15), const Duration(seconds: 5));
      expect(duelUrgentThreshold(20), const Duration(seconds: 5), reason: 'duels from before QB-B-017');
      expect(duelTimeUpDuration(5), const Duration(seconds: 1));
      expect(duelTimeUpDuration(10), const Duration(seconds: 2));
      expect(duelTimeUpDuration(15), const Duration(seconds: 2));
      expect(duelTimeUpDuration(20), const Duration(seconds: 2));
    });

    testWidgets('a 5 s game plays on the received time: the bar empties in 5 s', (tester) async {
      final g = _Game(seconds: 5);
      await intoQuestion(tester, g, const Duration(milliseconds: 2500));
      final bar = tester.widget<LinearProgressIndicator>(find.byKey(const ValueKey('duel-progress')));
      expect(bar.value, closeTo(0.5, 0.06));
      expect(find.text('0:03'), findsOneWidget);
    });
  });
}
