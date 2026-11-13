import 'dart:io';

import 'package:http/http.dart' as http;

import 'duel_live_support.dart';
import 'duel_test_support.dart';

/// A scripted duel server driven by a fake phone clock. The server clock is
/// the phone clock plus [skew].
class Scenario {
  Scenario({
    this.skew = Duration.zero,
    this.questionCount = 3,
    this.secondsPerQuestion = 20,
  });

  final FakeClock clock = FakeClock();

  /// Server time minus phone time.
  Duration skew;
  final int questionCount;
  final int secondsPerQuestion;

  DateTime get serverNow => clock.now().add(skew);

  /// The state route answers with this, built at the server time of the call.
  Map<String, Object?> Function(DateTime serverNow) state = (now) =>
      duelJson(serverTime: now);

  /// Start of the game on the server clock (for the questions route).
  DateTime? startsAt;

  /// Answers to the questions route (null: the normal payload).
  http.Response Function()? questionsOverride;

  /// Runs first on every request; return null to fall through.
  http.Response? Function(RecordedRequest request)? intercept;

  /// Answers of the answers route (null: the duel as `state` gives it,
  /// marked submitted).
  http.Response Function(RecordedRequest request)? answersOverride;

  int answerCalls = 0;

  late final FakeDuelServer server = FakeDuelServer((r) {
    final hooked = intercept?.call(r);
    if (hooked != null) return hooked;
    final path = r.path;
    if (r.method == 'GET' && path.endsWith('/questions/')) {
      final custom = questionsOverride;
      if (custom != null) return custom();
      return jsonResponse(
        200,
        questionsPayload(
          count: questionCount,
          startsAt: startsAt ?? serverNow,
          serverTime: serverNow,
          secondsPerQuestion: secondsPerQuestion,
        ),
      );
    }
    if (r.method == 'POST' && path.endsWith('/answers/')) {
      answerCalls++;
      final custom = answersOverride;
      if (custom != null) return custom(r);
      final base = state(serverNow);
      return jsonResponse(200, {...base, 'my_submitted': true});
    }
    if (r.method == 'POST' && path.endsWith('/cancel/')) {
      return jsonResponse(200, {...state(serverNow), 'status': 'cancelled'});
    }
    if (r.method == 'GET' && path.endsWith('/duel/duels/')) {
      return jsonResponse(200, {
        'server_time': iso(serverNow),
        'count': 0,
        'results': [],
      });
    }
    return jsonResponse(200, state(serverNow));
  });

  static http.Response network() => throw const SocketException('down');
}
