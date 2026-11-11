import '../../l10n/app_localizations.dart';
import '../../services/api_exception.dart';

/// Stable error codes of the duel API (see `API_DUEL_INVITATIONS.md`).
class DuelErrorCodes {
  static const invitationNotFound = 'invitation_not_found';
  static const invitationExpired = 'invitation_expired';
  static const invitationAlreadyUsed = 'invitation_already_used';
  static const ownInvitation = 'own_invitation';
  static const alreadyOpponents = 'already_opponents';
  static const opponentLimitReached = 'opponent_limit_reached';
  static const inviterOpponentLimitReached = 'inviter_opponent_limit_reached';
  static const activeInvitationLimitReached = 'active_invitation_limit_reached';
  static const opponentNotFound = 'opponent_not_found';
  static const blockNotFound = 'block_not_found';
  static const throttled = 'throttled';
}

/// The translated message for a failed duel call. Unknown codes and
/// non-API errors get the generic message.
String duelErrorMessage(AppLocalizations l, Object error) {
  if (error is ApiException) {
    if (error.isNetworkError) return l.duelErrNetwork;
    switch (error.code) {
      case DuelErrorCodes.invitationNotFound:
        return l.duelErrInvitationNotFound;
      case DuelErrorCodes.invitationExpired:
        return l.duelErrInvitationExpired;
      case DuelErrorCodes.invitationAlreadyUsed:
        return l.duelErrInvitationAlreadyUsed;
      case DuelErrorCodes.ownInvitation:
        return l.duelErrOwnInvitation;
      case DuelErrorCodes.alreadyOpponents:
        return l.duelErrAlreadyOpponents;
      case DuelErrorCodes.opponentLimitReached:
        return l.duelErrOpponentLimit;
      case DuelErrorCodes.inviterOpponentLimitReached:
        return l.duelErrInviterOpponentLimit;
      case DuelErrorCodes.activeInvitationLimitReached:
        return l.duelErrActiveInvitationLimit;
      case DuelErrorCodes.opponentNotFound:
        return l.duelErrOpponentNotFound;
      case DuelErrorCodes.blockNotFound:
        return l.duelErrBlockNotFound;
      case DuelErrorCodes.throttled:
        return l.duelErrThrottled;
    }
    if (error.isRateLimited) return l.errorTooManyRequests;
  }
  return l.errorGenericTryAgain;
}
