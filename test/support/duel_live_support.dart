import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:QuizzBuilder/providers/duel_provider.dart';

import 'duel_test_support.dart';

/// Phone clock of a test. Starts at [base]; moves only when told to.
class FakeClock {
  FakeClock([DateTime? start]) : _now = start ?? base;

  /// A fixed instant all the live tests count from.
  static final DateTime base = DateTime.utc(2026, 11, 12, 18, 0, 0);

  DateTime _now;
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

/// Moves the phone clock and the widget clock together, in small steps, so
/// that timers and clock-based screens see time pass.
Future<void> elapse(
  WidgetTester tester,
  FakeClock clock,
  Duration total, {
  Duration step = const Duration(milliseconds: 250),
}) async {
  var left = total;
  while (left > Duration.zero) {
    final d = left < step ? left : step;
    clock.advance(d);
    await tester.pump(d);
    left -= d;
  }
}

String iso(DateTime t) => t.toUtc().toIso8601String();

/// A duel payload as the API sends it. Times are given on the **server**
/// clock.
Map<String, Object?> duelJson({
  int id = 1,
  String status = 'waiting',
  int? pairId = 3,
  String opponent = 'alice',
  bool challengedByMe = true,
  int questionCount = 3,
  int secondsPerQuestion = 20,
  List<int> themes = const [10],
  List<String> difficulties = const ['easy', 'medium'],
  DateTime? roomExpiresAt,
  DateTime? startsAt,
  DateTime? deadlineAt,
  required DateTime serverTime,
  bool mySubmitted = false,
  bool opponentSubmitted = false,
  String? callLink,
  Map<String, Object?>? result,
}) => {
  'id': id,
  'status': status,
  'pair_id': pairId,
  'opponent_username': opponent,
  'challenged_by_me': challengedByMe,
  'themes': themes,
  'difficulties': difficulties,
  'question_count': questionCount,
  'seconds_per_question': secondsPerQuestion,
  'created_at': iso(serverTime),
  'room_expires_at': iso(roomExpiresAt ?? serverTime.add(const Duration(minutes: 10))),
  'starts_at': startsAt == null ? null : iso(startsAt),
  'deadline_at': deadlineAt == null
      ? (startsAt == null
            ? null
            : iso(startsAt.add(Duration(seconds: secondsPerQuestion * questionCount + 20))))
      : iso(deadlineAt),
  'server_time': iso(serverTime),
  'opponent_present': false,
  'my_submitted': mySubmitted,
  'opponent_submitted': opponentSubmitted,
  'call_link': callLink,
  'result': result,
};

Map<String, Object?> questionJson(int id) => {
  'id': id,
  'theme_id': 10,
  'theme_name_fr': 'Géographie',
  'theme_name_en': 'Geography',
  'difficulty': 'easy',
  'question_fr': 'Question FR $id ?',
  'question_en': 'Question EN $id?',
  for (var i = 1; i <= 4; i++) 'answer_${i}_fr': 'Réponse $i de $id',
  for (var i = 1; i <= 4; i++) 'answer_${i}_en': 'Answer $i of $id',
};

Map<String, Object?> questionsPayload({
  int duelId = 1,
  required int count,
  required DateTime startsAt,
  required DateTime serverTime,
  int secondsPerQuestion = 20,
}) => {
  'duel_id': duelId,
  'server_time': iso(serverTime),
  'starts_at': iso(startsAt),
  'deadline_at': iso(startsAt.add(Duration(seconds: secondsPerQuestion * count + 20))),
  'seconds_per_question': secondsPerQuestion,
  'questions': [for (var i = 1; i <= count; i++) questionJson(i)],
};

Map<String, Object?> resultJson({
  String? outcome = 'win',
  bool forfeit = false,
  int? myScore = 2,
  int? opponentScore = 1,
  List<List<int?>> lines = const [
    [1, 2, 1],
    [2, null, 3],
    [3, 4, 4],
  ],
}) => {
  'outcome': outcome,
  'forfeit': forfeit,
  'my_score': myScore,
  'opponent_score': opponentScore,
  'questions': [
    for (var i = 0; i < lines.length; i++)
      {
        'question_id': i + 1,
        'my_answer': lines[i][0],
        'opponent_answer': lines[i][1],
        'correct_answer': lines[i][2],
      },
  ],
};

/// Requests of a kind, by method and the end of the path.
Iterable<RecordedRequest> requestsTo(
  FakeDuelServer server,
  String method,
  String pathEnd,
) => server.requests.where((r) => r.method == method && r.path.endsWith(pathEnd));

/// Pumps a screen under [duelApp] with the provider given.
Future<void> pumpLive(
  WidgetTester tester, {
  required Widget home,
  required DuelProvider duel,
  FakeConnectivity? connectivity,
  String locale = 'en',
}) async {
  await tester.pumpWidget(
    duelApp(
      home: home,
      duel: duel,
      connectivity: connectivity,
      locale: locale,
    ),
  );
  await tester.pump();
}
