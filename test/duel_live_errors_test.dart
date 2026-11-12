import 'package:flutter_test/flutter_test.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/l10n/app_localizations_fr.dart';
import 'package:QuizzBuilder/services/api_exception.dart';
import 'package:QuizzBuilder/ui/duel/duel_errors.dart';

void main() {
  final en = AppLocalizationsEn();
  final fr = AppLocalizationsFr();
  ApiException api(String code, [int status = 400]) =>
      ApiException('server text', code: code, statusCode: status);

  test('one translated message per contract code (EN)', () {
    final expected = <String, String>{
      'no_theme_selected': en.duelErrNoThemeSelected,
      'theme_not_playable': en.duelErrThemeNotPlayable,
      'invalid_question_count': en.duelErrInvalidQuestionCount,
      'invalid_difficulty': en.duelErrInvalidDifficulty,
      'not_enough_questions': en.duelErrNotEnoughQuestions,
      'lent_theme_limit_reached': en.duelErrLentThemeLimit,
      'opponent_not_found': en.duelErrOpponentNotFound,
      'duel_not_found': en.duelErrDuelNotFound,
      'duel_closed': en.duelErrDuelClosed,
      'duel_cannot_be_cancelled': en.duelErrCannotCancel,
      'duel_not_started': en.duelErrNotStarted,
      'duel_deadline_passed': en.duelErrDeadlinePassed,
    };
    for (final entry in expected.entries) {
      expect(duelLiveErrorMessage(en, api(entry.key)), entry.value, reason: entry.key);
      expect(entry.value, isNot(en.errorGenericTryAgain), reason: entry.key);
      expect(entry.value, isNot('server text'));
    }
  });

  test('the French messages differ from the English ones and are not generic', () {
    for (final code in [
      'no_theme_selected',
      'theme_not_playable',
      'invalid_question_count',
      'invalid_difficulty',
      'not_enough_questions',
      'lent_theme_limit_reached',
      'duel_not_found',
      'duel_closed',
      'duel_cannot_be_cancelled',
      'duel_not_started',
      'duel_deadline_passed',
    ]) {
      final message = duelLiveErrorMessage(fr, api(code));
      expect(message, isNot(duelLiveErrorMessage(en, api(code))), reason: code);
      expect(message, isNot(fr.errorGenericTryAgain), reason: code);
    }
  });

  test('the plafond message is in the second person and says nothing about lending', () {
    final frText = fr.duelErrLentThemeLimit;
    expect(frText, startsWith('Tu as atteint'));
    for (final text in [frText, en.duelErrLentThemeLimit]) {
      final lower = text.toLowerCase();
      expect(lower.contains('prêt'), isFalse);
      expect(lower.contains('lent'), isFalse);
      expect(lower.contains('borrow'), isFalse);
      expect(lower.contains('adversaire'), isFalse);
      expect(lower.contains('opponent'), isFalse);
    }
  });

  test('invalid_answers and answers_already_submitted get the generic message', () {
    expect(duelLiveErrorMessage(en, api('invalid_answers')), en.errorGenericTryAgain);
    expect(
      duelLiveErrorMessage(en, api('answers_already_submitted', 409)),
      en.errorGenericTryAgain,
    );
  });

  test('unknown code and non-API errors get the generic message', () {
    expect(duelLiveErrorMessage(en, api('something_new')), en.errorGenericTryAgain);
    expect(duelLiveErrorMessage(en, StateError('boom')), en.errorGenericTryAgain);
  });

  test('network error and 429 (never "in an hour")', () {
    expect(
      duelLiveErrorMessage(en, const ApiException.network()),
      en.duelErrNetwork,
    );
    expect(
      duelLiveErrorMessage(en, api('throttled', 429)),
      en.errorTooManyRequests,
    );
    expect(
      duelLiveErrorMessage(en, const ApiException('x', statusCode: 429)),
      en.errorTooManyRequests,
    );
    expect(en.errorTooManyRequests.toLowerCase().contains('hour'), isFalse);
  });

  test('duel_already_open has no error message: the caller opens the duel', () {
    expect(duelLiveErrorMessage(en, api('duel_already_open', 409)), en.errorGenericTryAgain);
  });
}
