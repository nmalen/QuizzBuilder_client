import 'package:flutter_test/flutter_test.dart';

import 'package:QuizzBuilder/utils/invitation_link.dart';

/// QB-C-022: what the "Paste" button takes from the clipboard.
void main() {
  group('a code alone, in any shape a player may copy', () {
    test('as the page copies it (no dash)', () {
      expect(invitationCodeFromPastedText('K7P3QX'), 'K7P3QX');
    });
    test('as displayed (dash), selected by hand', () {
      expect(invitationCodeFromPastedText('K7P-3QX'), 'K7P3QX');
    });
    test('with spaces, in lower case', () {
      expect(invitationCodeFromPastedText('  k7p 3qx \n'), 'K7P3QX');
      expect(invitationCodeFromPastedText('k7p-3qx'), 'K7P3QX');
    });
  });

  group('a text holding an invitation link', () {
    test('the link alone, with or without scheme, slash or capitals', () {
      for (final text in [
        'https://play.quizzbuilder.fr/d/K7P3QX',
        'http://play.quizzbuilder.fr/d/k7p3qx',
        'play.quizzbuilder.fr/d/K7P3QX',
        'https://PLAY.QUIZZBUILDER.FR/d/K7P3QX/',
        'https://play.quizzbuilder.fr/d/K7P-3QX',
      ]) {
        expect(invitationCodeFromPastedText(text), 'K7P3QX', reason: text);
      }
    });

    test('the shared message (link and code): the link wins', () {
      expect(
        invitationCodeFromPastedText(
          'Challenge me on QuizzBuilder! https://play.quizzbuilder.fr/d/K7P3QX '
          'or enter the code K7P-3QX in the app.',
        ),
        'K7P3QX',
      );
    });
  });

  group('nothing usable', () {
    test(
      'the link of a live duel call (8 characters) is not an invitation',
      () {
        expect(
          invitationCodeFromPastedText(
            'https://play.quizzbuilder.fr/d/K7P3QXZ9',
          ),
          isNull,
        );
        expect(
          invitationCodeFromPastedText('play.quizzbuilder.fr/d/K7P3QXZ9'),
          isNull,
        );
      },
    );
    test('a call code alone is not an invitation either', () {
      expect(invitationCodeFromPastedText('K7P3QXZ9'), isNull);
    });
    test('a link of another site, or another path of this one', () {
      expect(
        invitationCodeFromPastedText('https://example.com/d/K7P3QX'),
        isNull,
      );
      expect(
        invitationCodeFromPastedText('https://play.quizzbuilder.fr/x/K7P3QX'),
        isNull,
      );
    });
    test('wrong length, any other text, empty, null', () {
      expect(invitationCodeFromPastedText('K7P3Q'), isNull);
      expect(invitationCodeFromPastedText('K7P3QXZ'), isNull);
      expect(invitationCodeFromPastedText('hello, how are you?'), isNull);
      expect(invitationCodeFromPastedText('Merci !'), isNull);
      expect(invitationCodeFromPastedText('   '), isNull);
      expect(invitationCodeFromPastedText(''), isNull);
      expect(invitationCodeFromPastedText(null), isNull);
    });
  });
}
