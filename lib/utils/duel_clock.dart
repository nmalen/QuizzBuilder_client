/// Pure clock arithmetic of the live duel. No `DateTime.now()` in here: every
/// function takes the instants it needs, so each one is testable.
///
/// The server fixes `starts_at`; each phone follows it with the offset
/// `server_time − phone time`, recomputed at every server answer.
library;

/// Seconds a question stays open (decision F1). The API also sends it
/// (`seconds_per_question`); the app uses the value it receives.
const int duelSecondsPerQuestion = 20;

/// Offset to add to the phone clock to get the server clock.
///
/// [phoneTime] is the phone instant that best matches [serverTime]: the
/// midpoint between sending the request and receiving the answer.
Duration duelClockOffset({
  required DateTime serverTime,
  required DateTime phoneTime,
}) => serverTime.difference(phoneTime);

/// Midpoint of a request: sent at [sentAt], answered at [receivedAt]. Halving
/// the round trip removes most of the network delay from the offset.
DateTime duelRequestMidpoint(DateTime sentAt, DateTime receivedAt) =>
    sentAt.add(receivedAt.difference(sentAt) ~/ 2);

/// Where a duel is on its timeline at one instant.
enum DuelStage {
  /// Before `starts_at`: the countdown.
  countdown,

  /// A question window is open.
  question,

  /// After the last window: time to send the answers.
  finished,
}

/// What the clock says at one instant.
class DuelMoment {
  final DuelStage stage;

  /// Time left before the start (countdown stage), else [Duration.zero].
  final Duration untilStart;

  /// Index (0-based) of the open question, or null outside a window.
  final int? questionIndex;

  /// Time left in the open window, else [Duration.zero].
  final Duration questionRemaining;

  /// Time left until the next window opens (or until the end of the game,
  /// for the last question): the wait of a player who already answered.
  final Duration untilNextWindow;

  const DuelMoment({
    required this.stage,
    this.untilStart = Duration.zero,
    this.questionIndex,
    this.questionRemaining = Duration.zero,
    this.untilNextWindow = Duration.zero,
  });

  @override
  String toString() =>
      'DuelMoment($stage, q=$questionIndex, left=$questionRemaining)';
}

/// The timeline of a duel: question n (1-based) is open from
/// `starts_at + (n − 1) × seconds` to `starts_at + n × seconds`.
class DuelSchedule {
  final DateTime startsAt;
  final int secondsPerQuestion;
  final int questionCount;

  const DuelSchedule({
    required this.startsAt,
    required this.secondsPerQuestion,
    required this.questionCount,
  });

  Duration get _window => Duration(seconds: secondsPerQuestion);

  /// When the last window closes (the game is over).
  DateTime get endsAt => startsAt.add(_window * questionCount);

  /// Opening instant of the question at [index] (0-based).
  DateTime opensAt(int index) => startsAt.add(_window * index);

  /// The moment at [phoneNow] for a phone whose clock is [offset] behind the
  /// server (server time = phone time + offset). Window starts are inclusive,
  /// window ends exclusive: at exactly `starts_at + n × 20 s` question n + 1
  /// is open.
  DuelMoment momentAt(DateTime phoneNow, Duration offset) {
    final now = phoneNow.add(offset);
    if (now.isBefore(startsAt)) {
      return DuelMoment(
        stage: DuelStage.countdown,
        untilStart: startsAt.difference(now),
      );
    }
    if (!now.isBefore(endsAt)) {
      return const DuelMoment(stage: DuelStage.finished);
    }
    final elapsed = now.difference(startsAt);
    final index = elapsed.inMicroseconds ~/ _window.inMicroseconds;
    final windowEnd = opensAt(index + 1);
    final remaining = windowEnd.difference(now);
    return DuelMoment(
      stage: DuelStage.question,
      questionIndex: index,
      questionRemaining: remaining,
      untilNextWindow: remaining,
    );
  }
}

/// Seconds to show for a remaining duration: rounded **up**, so the display
/// reads 0:01 until the very end and never 0:00 while a window is open.
int duelCeilSeconds(Duration remaining) {
  if (remaining <= Duration.zero) return 0;
  return (remaining.inMilliseconds + 999) ~/ 1000;
}

/// `m:ss` for a duration, rounded up to the second.
String duelFormatClock(Duration remaining) {
  final total = duelCeilSeconds(remaining);
  final minutes = total ~/ 60;
  final seconds = total % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
