import 'package:flutter/foundation.dart';

import '../utils/invitation_link.dart';

/// Holds an invitation code received through a universal link until the
/// player can act on it.
///
/// Memory only, on purpose: the code is single use and expires within 24 h,
/// so it is not worth writing to disk. Signed out, the authentication screen
/// reads it (sign-up mode, code pre-filled); signed in, the link host opens
/// the "join" screen and clears it.
class InvitationLinkProvider extends ChangeNotifier {
  String? _pendingCode;
  bool _entryHintPending = false;

  /// Normalized 6-character code waiting to be used, or null.
  String? get pendingCode => _pendingCode;

  /// Stores a code delivered by a link (a new delivery re-arms the hint).
  void setPendingCode(String code) {
    _pendingCode = normalizeInvitationCode(code);
    _entryHintPending = true;
    notifyListeners();
  }

  /// True once per delivered code: tells the authentication screen to open
  /// in sign-up mode. Later rebuilds of the screen keep the player's choice.
  bool takeEntryHint() {
    final pending = _entryHintPending;
    _entryHintPending = false;
    return pending;
  }

  /// Forgets the code (used, or no longer relevant).
  void clear() {
    if (_pendingCode == null && !_entryHintPending) return;
    _pendingCode = null;
    _entryHintPending = false;
    notifyListeners();
  }
}
