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

  // Live duel (batch 2)
  static const duelNotFound = 'duel_not_found';
  static const duelAlreadyOpen = 'duel_already_open';
  static const noThemeSelected = 'no_theme_selected';
  static const themeNotPlayable = 'theme_not_playable';
  static const invalidQuestionCount = 'invalid_question_count';
  static const invalidDifficulty = 'invalid_difficulty';
  static const notEnoughQuestions = 'not_enough_questions';
  static const lentThemeLimitReached = 'lent_theme_limit_reached';
  static const duelNotStarted = 'duel_not_started';
  static const duelDeadlinePassed = 'duel_deadline_passed';
  static const duelClosed = 'duel_closed';
  static const duelCannotBeCancelled = 'duel_cannot_be_cancelled';
  static const invalidAnswers = 'invalid_answers';
  static const answersAlreadySubmitted = 'answers_already_submitted';
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

/// The translated message for a failed call of the live duel (challenge,
/// room, game, answers). Unlike [duelErrorMessage], a 429 here is a burst
/// limit, never the hourly invitation limit. `duel_already_open` has no
/// message of its own: the caller opens the existing duel. Unknown codes,
/// `invalid_answers` and `answers_already_submitted` get the generic message.
String duelLiveErrorMessage(AppLocalizations l, Object error) {
  if (error is ApiException) {
    if (error.isNetworkError) return l.duelErrNetwork;
    switch (error.code) {
      case DuelErrorCodes.noThemeSelected:
        return l.duelErrNoThemeSelected;
      case DuelErrorCodes.themeNotPlayable:
        return l.duelErrThemeNotPlayable;
      case DuelErrorCodes.invalidQuestionCount:
        return l.duelErrInvalidQuestionCount;
      case DuelErrorCodes.invalidDifficulty:
        return l.duelErrInvalidDifficulty;
      case DuelErrorCodes.notEnoughQuestions:
        return l.duelErrNotEnoughQuestions;
      case DuelErrorCodes.lentThemeLimitReached:
        return l.duelErrLentThemeLimit;
      case DuelErrorCodes.opponentNotFound:
        return l.duelErrOpponentNotFound;
      case DuelErrorCodes.duelNotFound:
        return l.duelErrDuelNotFound;
      case DuelErrorCodes.duelClosed:
        return l.duelErrDuelClosed;
      case DuelErrorCodes.duelCannotBeCancelled:
        return l.duelErrCannotCancel;
      case DuelErrorCodes.duelNotStarted:
        return l.duelErrNotStarted;
      case DuelErrorCodes.duelDeadlinePassed:
        return l.duelErrDeadlinePassed;
    }
    if (error.isRateLimited || error.code == DuelErrorCodes.throttled) {
      return l.errorTooManyRequests;
    }
  }
  return l.errorGenericTryAgain;
}
