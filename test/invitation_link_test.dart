import 'package:flutter_test/flutter_test.dart';

import 'package:QuizzBuilder/utils/invitation_link.dart';

InvitationLink? parse(String s) => parseInvitationLocation(s);

void main() {
  group('normalizeInvitationCode', () {
    test('upper-cases a lower-case code (code en minuscules)', () {
      expect(normalizeInvitationCode('k7p3qx'), 'K7P3QX');
    });
    test('drops the dash and the spaces', () {
      expect(normalizeInvitationCode(' k7p-3qx '), 'K7P3QX');
      expect(normalizeInvitationCode('K7P 3QX'), 'K7P3QX');
    });
    test('isCompleteInvitationCode needs exactly 6 characters', () {
      expect(isCompleteInvitationCode('K7P-3QX'), isTrue);
      expect(isCompleteInvitationCode('k7p3q'), isFalse);
      expect(isCompleteInvitationCode('K7P3QXZ'), isFalse);
    });
  });

  group('parseInvitationUri', () {
    test('6 characters: join link', () {
      expect(
        parse('https://play.quizzbuilder.fr/d/K7P3QX'),
        const JoinInvitationLink('K7P3QX'),
      );
    });
    test('8 characters: call link (reserved to the live duel batch)', () {
      expect(
        parse('https://play.quizzbuilder.fr/d/ABCD2345'),
        const CallInvitationLink('ABCD2345'),
      );
    });
    test('lower case code (code en minuscules)', () {
      expect(
        parse('https://play.quizzbuilder.fr/d/k7p3qx'),
        const JoinInvitationLink('K7P3QX'),
      );
    });
    test('dash inside the code', () {
      expect(
        parse('https://play.quizzbuilder.fr/d/K7P-3QX'),
        const JoinInvitationLink('K7P3QX'),
      );
      expect(
        parse('/d/ABCD-2345'),
        const CallInvitationLink('ABCD2345'),
      );
    });
    test('trailing slash', () {
      expect(
        parse('https://play.quizzbuilder.fr/d/K7P3QX/'),
        const JoinInvitationLink('K7P3QX'),
      );
    });
    test('path only, as the engine may hand it over', () {
      expect(parse('/d/K7P3QX'), const JoinInvitationLink('K7P3QX'));
    });
    test('query string is ignored', () {
      expect(
        parse('https://play.quizzbuilder.fr/d/K7P3QX?utm=x'),
        const JoinInvitationLink('K7P3QX'),
      );
    });
    test('any other path is ignored', () {
      expect(parse('/'), isNull);
      expect(parse('/d'), isNull);
      expect(parse('/d/'), isNull);
      expect(parse('/x/K7P3QX'), isNull);
      expect(parse('/d/K7P3QX/extra'), isNull);
      expect(parse('/admin/'), isNull);
    });
    test('other lengths are ignored', () {
      expect(parse('/d/K7P3Q'), isNull);
      expect(parse('/d/K7P3QXZ'), isNull);
      expect(parse('/d/K7P3QXZABC'), isNull);
    });
    test('non alphanumeric code is ignored', () {
      expect(parse('/d/K7P_3Q'), isNull);
      expect(parse('/d/K7P%2F3Q'), isNull);
    });
    test('another host is ignored', () {
      expect(parse('https://evil.example/d/K7P3QX'), isNull);
    });
  });
}
