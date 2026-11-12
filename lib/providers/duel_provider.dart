import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/duel.dart';
import '../models/duel_live.dart';
import '../services/api_exception.dart';
import '../services/duel_service.dart';
import '../ui/duel/duel_errors.dart';

/// A sending of answers in progress. Owned by [DuelProvider], not by a
/// screen: leaving the screen never loses the answers.
class DuelSubmission extends ChangeNotifier {
  DuelSubmission._(this.duelId, this.answers);

  final int duelId;

  /// The answers being sent. Frozen: every retry sends this very list.
  final List<int?> answers;

  bool _retrying = false;

  /// True while the last attempt failed and another one is coming.
  bool get retrying => _retrying;

  /// The duel as the server answered, or null when the sending was given up
  /// (deadline passed, duel closed): the state route then tells the rest.
  Duel? duel;
  bool isDone = false;

  void _setRetrying(bool value) {
    if (_retrying == value) return;
    _retrying = value;
    notifyListeners();
  }
}

/// State of the duel hub: my opponents, and the one-time "you are now
/// opponents with …" announcement.
///
/// Nothing is cached across sessions except the set of pair ids already
/// announced on this device (per account). That set holds no name or e-mail.
class DuelProvider extends ChangeNotifier {
  final DuelService service;

  DuelProvider({required this.service});

  List<Opponent> _opponents = const [];
  bool _isLoading = false;
  Object? _error;
  int? _ownerUserId;
  List<Opponent> _announcement = const [];

  // ---- Live duel state (memory only) -------------------------------------
  List<OpenDuel> _openDuels = const [];
  final Map<int, List<DuelQuestion>> _questions = {};
  final Map<int, DuelSubmission> _submissions = {};

  /// My open duels (waiting or playing), as of the last silent check.
  List<OpenDuel> get openDuels => _openDuels;

  List<Opponent> get opponents => _opponents;
  bool get isLoading => _isLoading;

  /// Last load failure (an `ApiException` in practice), or null.
  Object? get error => _error;

  /// Opponents never seen on this device, waiting to be announced once.
  List<Opponent> get pendingAnnouncement => _announcement;

  static String _seenKey(int userId) => 'duel_seen_pairs_$userId';

  /// Forgets everything held in memory (logout, account switch).
  void reset() {
    _opponents = const [];
    _isLoading = false;
    _error = null;
    _ownerUserId = null;
    _announcement = const [];
    _openDuels = const [];
    _questions.clear();
    _submissions.clear();
    notifyListeners();
  }

  /// Loads my opponents. Pairs never seen on this device (for [userId]) are
  /// queued in [pendingAnnouncement] and recorded as seen, so each is
  /// announced once.
  Future<void> loadOpponents({required int? userId}) async {
    if (_ownerUserId != userId) {
      _opponents = const [];
      _announcement = const [];
    }
    _ownerUserId = userId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final loaded = await service.listOpponents();
      if (_ownerUserId != userId) return; // account changed meanwhile
      _opponents = loaded;
      if (userId != null) {
        final fresh = await _collectUnseen(userId, loaded);
        if (fresh.isNotEmpty) {
          _announcement = [..._announcement, ...fresh];
        }
      }
    } catch (e) {
      _error = e;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Same as [loadOpponents] but silent on failure: used right after sign-in
  /// to catch a pair created while the player was away.
  Future<void> detectNewOpponents({required int? userId}) async {
    await loadOpponents(userId: userId);
    _error = null;
  }

  /// Returns and clears the pending announcement.
  List<Opponent> takeAnnouncement() {
    final taken = _announcement;
    _announcement = const [];
    return taken;
  }

  /// Accepts an invitation. The new pair is marked as seen on the spot: the
  /// player just did it, no announcement later.
  Future<Opponent> acceptInvitation(String code, {required int? userId}) async {
    final opponent = await service.acceptInvitation(code);
    if (userId != null) {
      await _markSeen(userId, [opponent.id]);
    }
    _opponents = [opponent, ..._opponents.where((o) => o.id != opponent.id)];
    notifyListeners();
    return opponent;
  }

  Future<void> removeOpponent(int pairId) async {
    await service.removeOpponent(pairId);
    _drop(pairId);
  }

  Future<void> blockOpponent(int pairId) async {
    await service.blockOpponent(pairId);
    _drop(pairId);
  }

  /// Drops a pair from the list (after a server answer that says it is gone).
  void _drop(int pairId) {
    _opponents = _opponents.where((o) => o.id != pairId).toList();
    notifyListeners();
  }

  Future<List<Opponent>> _collectUnseen(
    int userId,
    List<Opponent> current,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getStringList(_seenKey(userId)) ?? const <String>[])
        .toSet();
    final fresh = current.where((o) => !seen.contains('${o.id}')).toList();
    if (fresh.isNotEmpty) {
      await _markSeen(userId, fresh.map((o) => o.id));
    }
    return fresh;
  }

  Future<void> _markSeen(int userId, Iterable<int> pairIds) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getStringList(_seenKey(userId)) ?? const <String>[])
        .toSet();
    seen.addAll(pairIds.map((id) => '$id'));
    await prefs.setStringList(_seenKey(userId), seen.toList());
  }

  // ---- Live duel ---------------------------------------------------------

  /// Checks my open duels. Silent: any failure leaves the previous list.
  ///
  /// The list does not say whether I already sent my answers for a `playing`
  /// duel, so each one is looked up (one request, only while a game runs).
  Future<void> loadOpenDuels() async {
    try {
      final page = await service.listOpenDuels();
      final refined = <OpenDuel>[];
      for (final duel in page.duels) {
        if (duel.status != DuelStatus.playing) {
          refined.add(duel);
        } else if (_submissions.containsKey(duel.id)) {
          refined.add(duel.withSubmitted(true));
        } else {
          try {
            final state = await service.getDuel(duel.id);
            refined.add(duel.withSubmitted(state.mySubmitted));
          } catch (_) {
            refined.add(duel);
          }
        }
      }
      _openDuels = refined;
      notifyListeners();
    } catch (_) {
      // Silent by design (decision H2): the banner just stays as it was.
    }
  }

  /// Duels the home banner talks about: a game I can resume, then rooms where
  /// I am challenged.
  List<OpenDuel> get bannerDuels {
    final resumable = _openDuels.where(
      (d) => d.status == DuelStatus.playing && d.mySubmitted != true,
    );
    final waiting = _openDuels.where(
      (d) => d.status == DuelStatus.waiting && !d.challengedByMe,
    );
    return [...resumable, ...waiting];
  }

  /// The open duel with this pair, if any.
  OpenDuel? openDuelForPair(int pairId) {
    for (final duel in _openDuels) {
      if (duel.pairId == pairId) return duel;
    }
    return null;
  }

  /// Keeps the questions of a duel in memory (decision J1). Never on disk,
  /// never in the theme cache.
  void rememberQuestions(int duelId, List<DuelQuestion> questions) {
    _questions[duelId] = questions;
  }

  List<DuelQuestion>? questionsFor(int duelId) => _questions[duelId];

  void forgetQuestions(int duelId) => _questions.remove(duelId);

  /// Starts sending [answers] for a duel, once. A second call for the same
  /// duel returns the sending already in progress (same answers).
  ///
  /// A network failure (or a 429 / 5xx) is retried with the **same** answers
  /// every [retryEvery] until [giveUpAt] on the phone clock. A refusal that
  /// no retry can fix ends the sending without a duel.
  DuelSubmission submitAnswers({
    required int duelId,
    required List<int?> answers,
    required DateTime giveUpAt,
    DateTime Function()? now,
    Duration retryEvery = const Duration(seconds: 2),
  }) {
    final existing = _submissions[duelId];
    if (existing != null) return existing;
    final submission = DuelSubmission._(
      duelId,
      List<int?>.unmodifiable(answers),
    );
    _submissions[duelId] = submission;
    final clock = now ?? DateTime.now;
    unawaited(() async {
      while (true) {
        try {
          submission.duel = await service.submitAnswers(
            duelId,
            submission.answers,
          );
          break;
        } on ApiException catch (e) {
          final retryable =
              e.isNetworkError ||
              e.isRateLimited ||
              (e.statusCode != null && e.statusCode! >= 500);
          if (!retryable ||
              e.code == DuelErrorCodes.duelDeadlinePassed ||
              !clock().isBefore(giveUpAt)) {
            break;
          }
          submission._setRetrying(true);
          await Future<void>.delayed(retryEvery);
        } catch (_) {
          break;
        }
      }
      submission._setRetrying(false);
      submission.isDone = true;
      submission.notifyListeners();
      notifyListeners();
    }());
    return submission;
  }

  /// True when this app already sent (or is sending) answers for the duel.
  bool hasSubmitted(int duelId) => _submissions.containsKey(duelId);
}
