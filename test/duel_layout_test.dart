import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/ui/duel/duel_blocked_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_hub_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_invitations_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_invite_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_join_confirm_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_join_screen.dart';

import 'support/duel_test_support.dart';

/// Narrowest phones with large text, in the language with the longest labels:
/// no RenderFlex overflow on any duel screen.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final screens = <String, Widget Function()>{
    'hub': () => const DuelHubScreen(),
    'invite': () => const DuelInviteScreen(),
    'join': () => const DuelJoinScreen(),
    'confirm': () => const DuelJoinConfirmScreen(code: 'K7P3QX'),
    'invitations': () => const DuelInvitationsScreen(),
    'blocked': () => const DuelBlockedScreen(),
  };

  for (final locale in ['fr', 'en']) {
    for (final entry in screens.entries) {
      testWidgets('320 dp wide, text scale 1.3 (${entry.key}, $locale): no overflow', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final server = FakeDuelServer((r) {
          if (r.method == 'POST') return jsonResponse(201, invitationJson());
          final path = r.path;
          if (path.endsWith('/duel/opponents/')) {
            return jsonResponse(200, {
              'count': 2,
              'results': [
                opponentJson(1, 'a_rather_long_username_here'),
                opponentJson(2, 'bob'),
              ],
            });
          }
          if (path.endsWith('/duel/invitations/')) {
            return jsonResponse(200, {
              'count': 1,
              'results': [invitationJson()],
            });
          }
          if (path.endsWith('/duel/blocks/')) {
            return jsonResponse(200, {
              'count': 1,
              'results': [
                {'id': 4, 'username': 'a_rather_long_username_here', 'created_at': '2026-11-12T10:00:00Z'},
              ],
            });
          }
          return jsonResponse(200, {
            'inviter_username': 'a_rather_long_username_here',
            'expires_at': '2026-11-13T10:00:00Z',
          });
        });

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: duelApp(
              locale: locale,
              home: entry.value(),
              duel: DuelProvider(service: server.service),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
