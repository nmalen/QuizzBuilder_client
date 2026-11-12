// Data classes for the live duel API (`api/v1/duel/`, batch 2).
//
// Hand-written (no code generation), like `duel.dart`. A play question never
// carries the right answer: it only exists inside [DuelResult].

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// Life cycle of a duel, as the API names it.
enum DuelStatus {
  waiting,
  playing,
  finished,
  forfeit,
  noResult,
  expired,
  cancelled,
  unknown;

  static DuelStatus parse(Object? value) => switch (value) {
    'waiting' => waiting,
    'playing' => playing,
    'finished' => finished,
    'forfeit' => forfeit,
    'no_result' => noResult,
    'expired' => expired,
    'cancelled' => cancelled,
    _ => unknown,
  };

  /// Waiting or playing: the one open duel a pair can have.
  bool get isOpen => this == waiting || this == playing;

  /// Statuses that carry a [DuelResult].
  bool get hasResult => this == finished || this == forfeit || this == noResult;
}

/// How a duel ended for me.
enum DuelOutcome {
  win,
  loss,
  draw;

  static DuelOutcome? parse(Object? value) => switch (value) {
    'win' => win,
    'loss' => loss,
    'draw' => draw,
    _ => null,
  };
}

/// The seven kinds of result a player can see.
enum DuelResultKind { win, loss, draw, winByForfeit, lossByForfeit, none }

DuelResultKind duelResultKind({
  required DuelOutcome? outcome,
  required bool forfeit,
}) {
  switch (outcome) {
    case DuelOutcome.win:
      return forfeit ? DuelResultKind.winByForfeit : DuelResultKind.win;
    case DuelOutcome.loss:
      return forfeit ? DuelResultKind.lossByForfeit : DuelResultKind.loss;
    case DuelOutcome.draw:
      return DuelResultKind.draw;
    case null:
      return DuelResultKind.none;
  }
}

/// One line of the review: both answers and the right one.
class DuelResultQuestion {
  final int questionId;
  final int? myAnswer;
  final int? opponentAnswer;
  final int? correctAnswer;

  const DuelResultQuestion({
    required this.questionId,
    this.myAnswer,
    this.opponentAnswer,
    this.correctAnswer,
  });

  factory DuelResultQuestion.fromJson(Map<String, dynamic> json) =>
      DuelResultQuestion(
        questionId: json['question_id'] as int,
        myAnswer: json['my_answer'] as int?,
        opponentAnswer: json['opponent_answer'] as int?,
        correctAnswer: json['correct_answer'] as int?,
      );
}

/// The result, from my point of view. Scores and outcome are null when
/// nobody sent answers (`no_result`).
class DuelResult {
  final DuelOutcome? outcome;
  final bool forfeit;
  final int? myScore;
  final int? opponentScore;
  final List<DuelResultQuestion> questions;

  const DuelResult({
    this.outcome,
    this.forfeit = false,
    this.myScore,
    this.opponentScore,
    this.questions = const [],
  });

  DuelResultKind get kind => duelResultKind(outcome: outcome, forfeit: forfeit);

  factory DuelResult.fromJson(Map<String, dynamic> json) {
    final raw = json['questions'];
    return DuelResult(
      outcome: DuelOutcome.parse(json['outcome']),
      forfeit: json['forfeit'] == true,
      myScore: json['my_score'] as int?,
      opponentScore: json['opponent_score'] as int?,
      questions: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(DuelResultQuestion.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

/// A duel as `GET duels/<id>/` and the creation / join / cancel / answers
/// routes return it.
class Duel {
  final int id;
  final DuelStatus status;

  /// Null once the pair was removed.
  final int? pairId;
  final String opponentUsername;
  final bool challengedByMe;

  /// Identifiers only: the API sends no theme names here.
  final List<int> themeIds;
  final List<String> difficulties;
  final int questionCount;
  final int secondsPerQuestion;
  final DateTime? createdAt;
  final DateTime? roomExpiresAt;
  final DateTime? startsAt;
  final DateTime? deadlineAt;
  final DateTime? serverTime;
  final bool opponentPresent;
  final bool mySubmitted;
  final bool opponentSubmitted;

  /// Only for the challenger, only while the room waits.
  final String? callLink;
  final DuelResult? result;

  const Duel({
    required this.id,
    required this.status,
    this.pairId,
    required this.opponentUsername,
    required this.challengedByMe,
    this.themeIds = const [],
    this.difficulties = const [],
    required this.questionCount,
    this.secondsPerQuestion = 20,
    this.createdAt,
    this.roomExpiresAt,
    this.startsAt,
    this.deadlineAt,
    this.serverTime,
    this.opponentPresent = false,
    this.mySubmitted = false,
    this.opponentSubmitted = false,
    this.callLink,
    this.result,
  });

  factory Duel.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    return Duel(
      id: json['id'] as int,
      status: DuelStatus.parse(json['status']),
      pairId: json['pair_id'] as int?,
      opponentUsername: json['opponent_username'] as String,
      challengedByMe: json['challenged_by_me'] == true,
      themeIds: _intList(json['themes']),
      difficulties: _stringList(json['difficulties']),
      questionCount: json['question_count'] as int,
      secondsPerQuestion: (json['seconds_per_question'] as int?) ?? 20,
      createdAt: _parseDate(json['created_at']),
      roomExpiresAt: _parseDate(json['room_expires_at']),
      startsAt: _parseDate(json['starts_at']),
      deadlineAt: _parseDate(json['deadline_at']),
      serverTime: _parseDate(json['server_time']),
      opponentPresent: json['opponent_present'] == true,
      mySubmitted: json['my_submitted'] == true,
      opponentSubmitted: json['opponent_submitted'] == true,
      callLink: json['call_link'] as String?,
      result: result is Map<String, dynamic>
          ? DuelResult.fromJson(result)
          : null,
    );
  }
}

/// A row of `GET duels/` (my open duels). The list does not say whether I
/// already sent my answers: [mySubmitted] stays null until the provider
/// learns it (from the duel's own route, or from what this app sent).
class OpenDuel {
  final int id;
  final DuelStatus status;
  final int? pairId;
  final String opponentUsername;
  final bool challengedByMe;
  final int questionCount;
  final DateTime? createdAt;
  final DateTime? roomExpiresAt;
  final DateTime? startsAt;
  final DateTime? deadlineAt;
  final bool? mySubmitted;

  const OpenDuel({
    required this.id,
    required this.status,
    this.pairId,
    required this.opponentUsername,
    required this.challengedByMe,
    required this.questionCount,
    this.createdAt,
    this.roomExpiresAt,
    this.startsAt,
    this.deadlineAt,
    this.mySubmitted,
  });

  factory OpenDuel.fromJson(Map<String, dynamic> json) => OpenDuel(
    id: json['id'] as int,
    status: DuelStatus.parse(json['status']),
    pairId: json['pair_id'] as int?,
    opponentUsername: json['opponent_username'] as String,
    challengedByMe: json['challenged_by_me'] == true,
    questionCount: json['question_count'] as int,
    createdAt: _parseDate(json['created_at']),
    roomExpiresAt: _parseDate(json['room_expires_at']),
    startsAt: _parseDate(json['starts_at']),
    deadlineAt: _parseDate(json['deadline_at']),
  );

  OpenDuel withSubmitted(bool value) => OpenDuel(
    id: id,
    status: status,
    pairId: pairId,
    opponentUsername: opponentUsername,
    challengedByMe: challengedByMe,
    questionCount: questionCount,
    createdAt: createdAt,
    roomExpiresAt: roomExpiresAt,
    startsAt: startsAt,
    deadlineAt: deadlineAt,
    mySubmitted: value,
  );
}

/// The answer to `GET duels/`: the list and the server clock.
class OpenDuelsPage {
  final DateTime? serverTime;
  final List<OpenDuel> duels;
  const OpenDuelsPage({this.serverTime, required this.duels});
}

/// A row of `GET duels/history/`.
class DuelHistoryItem {
  final int id;
  final DuelStatus status;
  final String opponentUsername;
  final bool challengedByMe;
  final DuelOutcome? outcome;
  final int? myScore;
  final int? opponentScore;
  final int questionCount;
  final DateTime? createdAt;
  final DateTime? closedAt;

  /// Won or lost by forfeit (the history carries the status, not the flag).
  bool get forfeit => status == DuelStatus.forfeit;

  DuelResultKind get kind => duelResultKind(outcome: outcome, forfeit: forfeit);

  const DuelHistoryItem({
    required this.id,
    required this.status,
    required this.opponentUsername,
    required this.challengedByMe,
    this.outcome,
    this.myScore,
    this.opponentScore,
    required this.questionCount,
    this.createdAt,
    this.closedAt,
  });

  factory DuelHistoryItem.fromJson(Map<String, dynamic> json) =>
      DuelHistoryItem(
        id: json['id'] as int,
        status: DuelStatus.parse(json['status']),
        opponentUsername: json['opponent_username'] as String,
        challengedByMe: json['challenged_by_me'] == true,
        outcome: DuelOutcome.parse(json['outcome']),
        myScore: json['my_score'] as int?,
        opponentScore: json['opponent_score'] as int?,
        questionCount: json['question_count'] as int,
        createdAt: _parseDate(json['created_at']),
        closedAt: _parseDate(json['closed_at']),
      );
}

/// A theme offered for a duel with one opponent. No field says who owns it.
class DuelTheme {
  final int id;
  final String nameFr;
  final String nameEn;
  final int categoryId;
  final String categoryNameFr;
  final String categoryNameEn;
  final Map<String, int> questionCounts;

  const DuelTheme({
    required this.id,
    required this.nameFr,
    required this.nameEn,
    required this.categoryId,
    required this.categoryNameFr,
    required this.categoryNameEn,
    required this.questionCounts,
  });

  String name(String languageCode) => languageCode == 'fr' ? nameFr : nameEn;

  String categoryName(String languageCode) =>
      languageCode == 'fr' ? categoryNameFr : categoryNameEn;

  int countFor(String difficulty) => questionCounts[difficulty] ?? 0;

  factory DuelTheme.fromJson(Map<String, dynamic> json) {
    final counts = json['question_counts'];
    return DuelTheme(
      id: json['id'] as int,
      nameFr: json['name_fr'] as String,
      nameEn: json['name_en'] as String,
      categoryId: json['category_id'] as int,
      categoryNameFr: json['category_name_fr'] as String,
      categoryNameEn: json['category_name_en'] as String,
      questionCounts: counts is Map
          ? {
              for (final entry in counts.entries)
                entry.key.toString(): (entry.value as num).toInt(),
            }
          : const {},
    );
  }
}

/// A question as played in a duel. Memory only (decision J1): never written
/// to the theme cache nor to the disk. No right answer here.
class DuelQuestion {
  final int id;
  final int themeId;
  final String themeNameFr;
  final String themeNameEn;
  final String difficulty;
  final String questionFr;
  final String questionEn;
  final List<String> answersFr;
  final List<String> answersEn;

  const DuelQuestion({
    required this.id,
    required this.themeId,
    required this.themeNameFr,
    required this.themeNameEn,
    required this.difficulty,
    required this.questionFr,
    required this.questionEn,
    required this.answersFr,
    required this.answersEn,
  });

  String themeName(String languageCode) =>
      languageCode == 'fr' ? themeNameFr : themeNameEn;

  String text(String languageCode) =>
      languageCode == 'fr' ? questionFr : questionEn;

  List<String> answers(String languageCode) =>
      languageCode == 'fr' ? answersFr : answersEn;

  factory DuelQuestion.fromJson(Map<String, dynamic> json) => DuelQuestion(
    id: json['id'] as int,
    themeId: json['theme_id'] as int,
    themeNameFr: json['theme_name_fr'] as String,
    themeNameEn: json['theme_name_en'] as String,
    difficulty: json['difficulty'] as String,
    questionFr: json['question_fr'] as String,
    questionEn: json['question_en'] as String,
    answersFr: [for (var i = 1; i <= 4; i++) json['answer_${i}_fr'] as String],
    answersEn: [for (var i = 1; i <= 4; i++) json['answer_${i}_en'] as String],
  );
}

/// The answer to `GET duels/<id>/questions/`.
class DuelQuestions {
  final int duelId;
  final DateTime? serverTime;
  final DateTime startsAt;
  final DateTime deadlineAt;
  final int secondsPerQuestion;
  final List<DuelQuestion> questions;

  const DuelQuestions({
    required this.duelId,
    this.serverTime,
    required this.startsAt,
    required this.deadlineAt,
    required this.secondsPerQuestion,
    required this.questions,
  });

  factory DuelQuestions.fromJson(Map<String, dynamic> json) {
    final raw = json['questions'];
    final startsAt = _parseDate(json['starts_at']);
    final deadlineAt = _parseDate(json['deadline_at']);
    if (raw is! List || startsAt == null || deadlineAt == null) {
      throw const FormatException('Invalid duel questions payload');
    }
    return DuelQuestions(
      duelId: json['duel_id'] as int,
      serverTime: _parseDate(json['server_time']),
      startsAt: startsAt,
      deadlineAt: deadlineAt,
      secondsPerQuestion: (json['seconds_per_question'] as int?) ?? 20,
      questions: raw
          .whereType<Map<String, dynamic>>()
          .map(DuelQuestion.fromJson)
          .toList(growable: false),
    );
  }
}

List<int> _intList(Object? value) =>
    value is List ? value.whereType<int>().toList(growable: false) : const [];

List<String> _stringList(Object? value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const [];
