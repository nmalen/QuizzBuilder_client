import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/duel.dart';
import '../services/duel_service.dart';

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
}
