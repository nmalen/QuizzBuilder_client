import 'package:flutter_test/flutter_test.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/l10n/app_localizations_fr.dart';
import 'package:QuizzBuilder/services/api_exception.dart';
import 'package:QuizzBuilder/ui/duel/duel_errors.dart';

ApiException _e(String code, int status) =>
    ApiException('server text', statusCode: status, code: code);

void main() {
  for (final AppLocalizations l in <AppLocalizations>[
    AppLocalizationsEn(),
    AppLocalizationsFr(),
  ]) {
    group('duelErrorMessage (${l.localeName})', () {
      final expected = <String, String>{
        'invitation_not_found': l.duelErrInvitationNotFound,
        'invitation_expired': l.duelErrInvitationExpired,
        'invitation_already_used': l.duelErrInvitationAlreadyUsed,
        'own_invitation': l.duelErrOwnInvitation,
        'already_opponents': l.duelErrAlreadyOpponents,
        'opponent_limit_reached': l.duelErrOpponentLimit,
        'inviter_opponent_limit_reached': l.duelErrInviterOpponentLimit,
        'throttled': l.duelErrThrottled,
        'active_invitation_limit_reached': l.duelErrActiveInvitationLimit,
        'opponent_not_found': l.duelErrOpponentNotFound,
        'block_not_found': l.duelErrBlockNotFound,
      };

      test('every code of the contract has its own message', () {
        expect(expected.values.toSet().length, expected.length);
        expected.forEach((code, message) {
          expect(message, isNotEmpty);
          expect(duelErrorMessage(l, _e(code, 400)), message, reason: code);
          expect(message, isNot(l.errorGenericTryAgain), reason: code);
        });
      });

      test('unknown code and non-API errors get the generic message', () {
        expect(duelErrorMessage(l, _e('brand_new_code', 500)), l.errorGenericTryAgain);
        expect(duelErrorMessage(l, const FormatException('x')), l.errorGenericTryAgain);
      });

      test('network failure and bare 429', () {
        expect(duelErrorMessage(l, const ApiException.network()), l.duelErrNetwork);
        expect(
          duelErrorMessage(l, const ApiException('slow down', statusCode: 429)),
          l.errorTooManyRequests,
        );
      });
    });
  }
}
