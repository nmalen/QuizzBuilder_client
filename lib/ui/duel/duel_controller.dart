import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/duel_live.dart';
import '../../providers/duel_provider.dart';
import '../../services/api_exception.dart';
import '../../services/duel_service.dart';
import '../../utils/duel_clock.dart';
import 'duel_errors.dart';

/// What the live duel screen is showing.
enum DuelPhase {
  /// First load of the duel (or join by call code).
  opening,

  /// The first load failed for a reason other than "no such duel".
  openFailed,

  /// Waiting room.
  room,

  /// The start is fixed, the countdown runs.
  countdown,

  /// A question window is open (or the game is on but the questions are not
  /// here yet).
  game,

  /// My answers are being sent.
  sending,

  /// My answers are in; waiting for the other player (or the deadline).
  awaitingResult,

  /// The duel is over and has a result.
  result,

  /// The room expired, was cancelled, or does not exist (any more).
  ended,
}

/// Why a duel ended without a result.
enum DuelEndKind { expired, cancelled, notFound, closed }

/// Drives one live duel from the waiting room to the result.
///
/// Owns the polling (room, result), the game clock, the questions kept **in
/// memory only** (decision J1) and the one sending of the answers (delegated
/// to [DuelProvider], so that leaving the screen never loses them).
///
/// Everything time-related goes through [now] and the server offset, so a
/// test can drive a whole game with a fake clock.
class DuelController extends ChangeNotifier {
  DuelController({
    required this.provider,
    this.duelId,
    this.initial,
    this.joinCode,
    DateTime Function()? now,
    this.roomPollInterval = const Duration(seconds: 2),
    this.resultPollInterval = const Duration(milliseconds: 2500),
    this.tickInterval = const Duration(milliseconds: 250),
    this.retryEvery = const Duration(seconds: 2),
    this.offlineWarningDelay = const Duration(seconds: 2),
  }) : assert(
         duelId != null || initial != null || joinCode != null,
         'a duel id, a duel or a call code is needed',
       ),
       _now = now ?? DateTime.now;

  final DuelProvider provider;

  /// Open an existing duel by id (banner, hub), or ...
  final int? duelId;

  /// ... the duel the server just returned (right after creating it), or ...
  final Duel? initial;

  /// ... join by call code (universal link).
  final String? joinCode;

  final Duration roomPollInterval;
  final Duration resultPollInterval;
  final Duration tickInterval;
  final Duration retryEvery;

  /// Offline this long before the forfeit warning shows (a Wi-Fi to mobile
  /// handover must not flash it).
  final Duration offlineWarningDelay;
  final DateTime Function() _now;

  DuelService get _service => provider.service;

  // ---- State read by the screen -----------------------------------------

  DuelPhase phase = DuelPhase.opening;
  DuelEndKind? endKind;
  Duel? duel;

  /// Failure of the first load (phase [DuelPhase.openFailed]).
  Object? openError;

  /// The last poll failed (connection trouble); polling goes on.
  bool unstable = false;

  /// I cancelled the duel myself (no message needed on the way out).
  bool cancelledByMe = false;

  DuelMoment? moment;
  List<DuelQuestion>? questions;
  Object? questionsError;

  /// One entry per question: 1-4, or null (no answer). Memory only.
  List<int?> answers = const [];

  /// When "time's up" stops being shown (phone clock).
  DateTime? _timeUpUntil;

  /// The questions of a finished duel, for the review (memory only).
  List<DuelQuestion>? reviewQuestions;
  bool reviewUnavailable = false;

  bool get online => _online;
  bool get retryingSend => _submission?.retrying ?? false;

  /// True while the phone has been offline for [offlineWarningDelay] or more
  /// **during the game** (decision: forfeit warning). Not in the countdown,
  /// not while waiting for the result (the answers are in by then). Read from
  /// the clock at every tick, so it needs no timer of its own.
  bool get offlineWarning {
    final since = _offlineSince;
    return phase == DuelPhase.game &&
        !_online &&
        since != null &&
        _now().difference(since) >= offlineWarningDelay;
  }

  /// The deadline for my answers, as the **phone** clock will show it: the
  /// server's `deadline_at` minus the offset. Null without a deadline.
  DateTime? get phoneDeadline => duel?.deadlineAt?.subtract(_offset);

  DuelSchedule? get schedule => _schedule;

  /// Server clock now (phone clock plus the offset).
  DateTime get serverNow => _now().add(_offset);

  /// Phone clock now, as this controller sees it.
  DateTime get phoneNow => _now();

  /// Time left before the room expires; null outside the room.
  Duration? get roomTimeLeft {
    final expires = duel?.roomExpiresAt;
    if (expires == null) return null;
    final left = expires.difference(serverNow);
    return left.isNegative ? Duration.zero : left;
  }

  /// Time left before the deadline to get a result; null without deadline.
  Duration? get deadlineLeft {
    final deadline = duel?.deadlineAt;
    if (deadline == null) return null;
    final left = deadline.difference(serverNow);
    return left.isNegative ? Duration.zero : left;
  }

  bool get showTimeUp {
    final until = _timeUpUntil;
    return until != null && _now().isBefore(until);
  }

  int? get currentIndex => moment?.questionIndex;

  DuelQuestion? get currentQuestion {
    final i = currentIndex;
    final list = questions;
    if (i == null || list == null || i >= list.length) return null;
    return list[i];
  }

  /// The answer given to the open question (1-4), or null.
  int? get currentAnswer {
    final i = currentIndex;
    if (i == null || i >= answers.length) return null;
    return answers[i];
  }

  // ---- Internals ----------------------------------------------------------

  Duration _offset = Duration.zero;
  DuelSchedule? _schedule;
  Timer? _pollTimer;
  Timer? _ticker;
  Timer? _questionsRetry;
  bool _polling = false;
  bool _questionsLoading = false;
  bool _disposed = false;
  bool _foreground = true;
  bool _online = true;

  /// Phone instant the connection was lost; null while online.
  DateTime? _offlineSince;
  int _backoff = 1;
  int? _lastIndex;
  DuelSubmission? _submission;

  /// The first state came without a `GET` of the duel (just created, or
  /// joined by code): look right away, which also marks my presence.
  bool _needsFirstLook = false;

  // ---- Opening -----------------------------------------------------------

  /// Loads (or joins) the duel and starts following it.
  Future<void> open() async {
    phase = DuelPhase.opening;
    openError = null;
    _notify();
    try {
      final Duel first;
      final seed = initial;
      _needsFirstLook = seed != null || joinCode != null;
      if (seed != null) {
        first = seed;
        _syncClock(seed.serverTime, _now(), _now());
      } else if (joinCode != null) {
        first = await _fetch(() => _service.joinDuel(joinCode!));
      } else {
        first = await _fetch(() => _service.getDuel(duelId!));
      }
      if (_disposed) return;
      _apply(first);
    } on ApiException catch (e) {
      if (_disposed) return;
      if (e.code == DuelErrorCodes.duelNotFound || e.statusCode == 404) {
        _end(DuelEndKind.notFound);
      } else if (e.code == DuelErrorCodes.duelClosed) {
        _end(DuelEndKind.closed);
      } else {
        openError = e;
        phase = DuelPhase.openFailed;
        _notify();
      }
    } catch (e) {
      if (_disposed) return;
      openError = e;
      phase = DuelPhase.openFailed;
      _notify();
    }
  }

  /// Runs a duel call and recalibrates the clock from its `server_time`.
  Future<Duel> _fetch(Future<Duel> Function() call) async {
    final sent = _now();
    final value = await call();
    _syncClock(value.serverTime, sent, _now());
    return value;
  }

  void _syncClock(DateTime? serverTime, DateTime sentAt, DateTime receivedAt) {
    if (serverTime == null) return;
    _offset = duelClockOffset(
      serverTime: serverTime,
      phoneTime: duelRequestMidpoint(sentAt, receivedAt),
    );
  }

  // ---- State machine -------------------------------------------------------

  void _apply(Duel d) {
    if (_disposed) return;
    duel = d;
    switch (d.status) {
      case DuelStatus.waiting:
        _enterRoom();
      case DuelStatus.playing:
        if (d.mySubmitted || _submission != null) {
          _enterAwaiting();
        } else if (d.startsAt == null) {
          _enterRoom();
        } else {
          _enterPlay(d);
        }
      case DuelStatus.finished:
      case DuelStatus.forfeit:
      case DuelStatus.noResult:
        _enterResult();
      case DuelStatus.expired:
        _end(DuelEndKind.expired);
      case DuelStatus.cancelled:
        _end(DuelEndKind.cancelled);
      case DuelStatus.unknown:
        _end(DuelEndKind.closed);
    }
  }

  void _enterRoom() {
    phase = DuelPhase.room;
    _startTicker();
    _ensurePolling(_needsFirstLook ? Duration.zero : roomPollInterval);
    _needsFirstLook = false;
    _notify();
  }

  void _enterPlay(Duel d) {
    _schedule = DuelSchedule(
      startsAt: d.startsAt!,
      secondsPerQuestion: d.secondsPerQuestion,
      questionCount: d.questionCount,
    );
    if (answers.length != d.questionCount) {
      answers = List<int?>.filled(d.questionCount, null);
    }
    _pollTimer?.cancel();
    if (phase != DuelPhase.game && phase != DuelPhase.countdown) {
      phase = DuelPhase.countdown;
    }
    _startTicker();
    _tick();
    unawaited(_ensureQuestions());
  }

  void _enterAwaiting() {
    final fromSending = phase == DuelPhase.sending;
    phase = DuelPhase.awaitingResult;
    _startTicker();
    _ensurePolling(fromSending ? Duration.zero : resultPollInterval);
    _notify();
  }

  void _enterResult() {
    phase = DuelPhase.result;
    _stopTimers();
    unawaited(_loadReview());
    unawaited(provider.loadOpenDuels());
    _notify();
  }

  void _end(DuelEndKind kind) {
    endKind = kind;
    phase = DuelPhase.ended;
    _stopTimers();
    unawaited(provider.loadOpenDuels());
    _notify();
  }

  // ---- Polling (room and result) ------------------------------------------

  bool get _pollingAllowed =>
      !_disposed &&
      _foreground &&
      _online &&
      (phase == DuelPhase.room || phase == DuelPhase.awaitingResult);

  Duration get _pollInterval =>
      (phase == DuelPhase.room ? roomPollInterval : resultPollInterval) *
      _backoff;

  void _ensurePolling(Duration delay) {
    if (_pollTimer?.isActive == true || _polling) return;
    _schedulePoll(delay);
  }

  void _schedulePoll(Duration delay) {
    _pollTimer?.cancel();
    if (!_pollingAllowed) return;
    _pollTimer = Timer(delay, _poll);
  }

  Future<void> _poll() async {
    if (_polling || !_pollingAllowed || duel == null) return;
    _polling = true;
    try {
      final d = await _fetch(() => _service.getDuel(duel!.id));
      unstable = false;
      _backoff = 1;
      if (_disposed) return;
      _apply(d);
    } on ApiException catch (e) {
      if (_disposed) return;
      if (e.code == DuelErrorCodes.duelNotFound) {
        _end(DuelEndKind.notFound);
      } else if (e.code == DuelErrorCodes.duelClosed) {
        _end(DuelEndKind.closed);
      } else if (e.isRateLimited) {
        // Too many polls: space them out, say nothing.
        _backoff = (_backoff * 2).clamp(1, 4);
      } else {
        unstable = true;
        _notify();
      }
    } catch (_) {
      if (_disposed) return;
      unstable = true;
      _notify();
    } finally {
      _polling = false;
      if (!_disposed && _pollingAllowed) _schedulePoll(_pollInterval);
    }
  }

  /// Polls now (a user gesture, a cancel that was refused, back online).
  void refreshNow() {
    if (_disposed) return;
    _schedulePoll(Duration.zero);
  }

  /// The app went to the background (false) or came back (true). Polling
  /// stops in the background and resumes, at once, on return.
  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    if (!value) {
      _pollTimer?.cancel();
    } else {
      _tick();
      if (_pollingAllowed) _schedulePoll(Duration.zero);
    }
  }

  void setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    _offlineSince = value ? null : _now();
    if (!value) {
      _pollTimer?.cancel();
    } else if (_pollingAllowed) {
      _schedulePoll(Duration.zero);
    }
    _notify();
  }

  // ---- Clock tick ------------------------------------------------------------

  void _startTicker() {
    _ticker ??= Timer.periodic(tickInterval, (_) => _tick());
  }

  void _tick() {
    if (_disposed) return;
    final s = _schedule;
    if (s != null &&
        (phase == DuelPhase.countdown || phase == DuelPhase.game)) {
      final m = s.momentAt(_now(), _offset);
      moment = m;
      switch (m.stage) {
        case DuelStage.countdown:
          break;
        case DuelStage.question:
          phase = DuelPhase.game;
          final index = m.questionIndex!;
          final last = _lastIndex;
          if (last != index) {
            if (last != null && last < index && answers[last] == null) {
              _timeUpUntil = _now().add(
                duelTimeUpDuration(s.secondsPerQuestion),
              );
            }
            _lastIndex = index;
          }
        case DuelStage.finished:
          _beginSubmit();
      }
    }
    _notify();
  }

  // ---- Questions (memory only) -----------------------------------------------

  Future<void> _ensureQuestions() async {
    final d = duel;
    if (_disposed || _questionsLoading || questions != null || d == null) {
      return;
    }
    final cached = provider.questionsFor(d.id);
    if (cached != null) {
      questions = cached;
      _notify();
      return;
    }
    _questionsLoading = true;
    try {
      final sent = _now();
      final fetched = await _service.getQuestions(d.id);
      _syncClock(fetched.serverTime, sent, _now());
      if (_disposed) return;
      questions = fetched.questions;
      questionsError = null;
      provider.rememberQuestions(d.id, fetched.questions);
    } catch (e) {
      if (_disposed) return;
      questionsError = e;
      _questionsRetry?.cancel();
      if (phase == DuelPhase.countdown || phase == DuelPhase.game) {
        _questionsRetry = Timer(
          const Duration(seconds: 1),
          () => unawaited(_ensureQuestions()),
        );
      }
    } finally {
      _questionsLoading = false;
      _notify();
    }
  }

  /// "Retry" on the questions error card.
  void retryQuestions() {
    questionsError = null;
    _notify();
    unawaited(_ensureQuestions());
  }

  // ---- Playing -----------------------------------------------------------------

  /// Records [choice] (1-4) for the open question. One answer per question,
  /// final. Returns false when nothing was recorded.
  bool answer(int choice) {
    final index = currentIndex;
    if (phase != DuelPhase.game || index == null || questions == null) {
      return false;
    }
    if (choice < 1 || choice > 4 || answers[index] != null) return false;
    answers = [...answers]..[index] = choice;
    _notify();
    return true;
  }

  /// Leaving the game on purpose (decision J2): the answers given so far are
  /// sent now, the rest counts as unanswered.
  void quit() {
    if (phase == DuelPhase.game) _beginSubmit();
  }

  void _beginSubmit() {
    final d = duel;
    if (d == null || _submission != null) return;
    phase = DuelPhase.sending;
    _questionsRetry?.cancel();
    final frozen = List<int?>.generate(
      d.questionCount,
      (i) => i < answers.length ? answers[i] : null,
    );
    final giveUpAt = (d.deadlineAt ?? _now()).subtract(_offset);
    final submission = provider.submitAnswers(
      duelId: d.id,
      answers: frozen,
      giveUpAt: giveUpAt,
      now: _now,
      retryEvery: retryEvery,
    );
    _submission = submission;
    submission.addListener(_onSubmissionChanged);
    _notify();
    if (submission.isDone) _onSubmissionChanged();
  }

  void _onSubmissionChanged() {
    final submission = _submission;
    if (_disposed || submission == null) return;
    if (!submission.isDone) {
      _notify();
      return;
    }
    submission.removeListener(_onSubmissionChanged);
    final sent = submission.duel;
    if (sent != null) {
      _syncClock(sent.serverTime, _now(), _now());
      _apply(sent);
    } else {
      // Given up (deadline passed, duel closed): the state route tells.
      _enterAwaiting();
    }
  }

  // ---- Room actions ---------------------------------------------------------------

  /// Cancels the room. Returns the error to show, or null on success.
  Future<Object?> cancelDuel() async {
    final d = duel;
    if (d == null) return null;
    try {
      final updated = await _fetch(() => _service.cancelDuel(d.id));
      cancelledByMe = true;
      _apply(updated);
      return null;
    } catch (e) {
      if (e is ApiException && e.code == DuelErrorCodes.duelCannotBeCancelled) {
        refreshNow(); // the start was fixed meanwhile: follow it
      }
      return e;
    }
  }

  // ---- Review ----------------------------------------------------------------------

  Future<void> _loadReview() async {
    final d = duel;
    if (d == null) return;
    final kept = questions ?? provider.questionsFor(d.id);
    if (kept != null) {
      reviewQuestions = kept;
      _notify();
      return;
    }
    try {
      final sent = _now();
      final fetched = await _service.getQuestions(d.id);
      _syncClock(fetched.serverTime, sent, _now());
      if (_disposed) return;
      reviewQuestions = fetched.questions;
      provider.rememberQuestions(d.id, fetched.questions);
    } catch (_) {
      if (_disposed) return;
      reviewUnavailable = true;
    }
    _notify();
  }

  // ---- Plumbing -----------------------------------------------------------------------

  void _stopTimers() {
    _pollTimer?.cancel();
    _ticker?.cancel();
    _ticker = null;
    _questionsRetry?.cancel();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimers();
    _submission?.removeListener(_onSubmissionChanged);
    // Decision J1: the questions are forgotten when the player leaves.
    final id = duel?.id ?? duelId;
    if (id != null) provider.forgetQuestions(id);
    super.dispose();
  }
}
