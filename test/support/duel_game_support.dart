import 'dart:convert';

import 'duel_live_support.dart';
import 'duel_scenario.dart';
import 'duel_test_support.dart';

/// A game of [count] questions that starts 8 s after the test begins (on the
/// server clock), with the phone [skew] behind the server.
class Game {
  Game({
    Duration skew = Duration.zero,
    this.count = 3,
    Duration startsIn = const Duration(seconds: 8),
  }) : s = Scenario(skew: skew, questionCount: count) {
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
