import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/models/duel.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/ui/duel/duel_join_confirm_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_join_screen.dart';

import 'support/duel_test_support.dart';

final _l = AppLocalizationsEn();

/// Home with a button that opens [child] and prints what it returned.
class _Launcher extends StatefulWidget {
  final Widget child;
  const _Launcher(this.child);
  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher> {
  String result = 'none';
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextButton(
          onPressed: () async {
            final opponent = await Navigator.of(context).push<Opponent>(
              MaterialPageRoute(builder: (_) => widget.child),
            );
            setState(() => result = 'result: ${opponent?.username}');
          },
          child: const Text('open'),
        ),
        Text(result),
      ],
    ),
  );
}

Future<void> _type(WidgetTester tester, String code) async {
  await tester.enterText(find.byKey(const Key('join-code-field')), code);
  await tester.pump();
}

Finder get _continue => find.widgetWithText(ElevatedButton, _l.duelContinue);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<FakeDuelServer> pumpJoin(
    WidgetTester tester,
    Handler handler,
  ) async {
    final server = FakeDuelServer(handler);
    await tester.pumpWidget(
      duelApp(
        home: const _Launcher(DuelJoinScreen()),
        duel: DuelProvider(service: server.service),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return server;
  }

  testWidgets('Continue needs 6 characters, dash and case ignored', (tester) async {
    await pumpJoin(tester, (r) => errorResponse(404, 'invitation_not_found'));
    expect(tester.widget<ElevatedButton>(_continue).onPressed, isNull);
    await _type(tester, 'K7P-3Q');
    expect(tester.widget<ElevatedButton>(_continue).onPressed, isNull);
    await _type(tester, 'k7p-3qx');
    expect(tester.widget<ElevatedButton>(_continue).onPressed, isNotNull);
  });

  testWidgets('a lower-case code is sent upper-cased, without dash (code en minuscules)', (tester) async {
    final server = await pumpJoin(
      tester,
      (r) => jsonResponse(200, {
        'inviter_username': 'alice',
        'expires_at': '2026-11-13T10:00:00Z',
      }),
    );
    await _type(tester, 'k7p-3qx');
    await tester.tap(_continue);
    await tester.pumpAndSettle();
    expect(server.requests.single.path, endsWith('/duel/invitations/K7P3QX/'));
  });

  group('preview errors show their own translated message', () {
    final table = <(String, int, String)>[
      ('invitation_not_found', 404, _l.duelErrInvitationNotFound),
      ('invitation_expired', 410, _l.duelErrInvitationExpired),
      ('invitation_already_used', 409, _l.duelErrInvitationAlreadyUsed),
      ('own_invitation', 400, _l.duelErrOwnInvitation),
      ('already_opponents', 409, _l.duelErrAlreadyOpponents),
      ('opponent_limit_reached', 409, _l.duelErrOpponentLimit),
      ('inviter_opponent_limit_reached', 409, _l.duelErrInviterOpponentLimit),
      ('throttled', 429, _l.duelErrThrottled),
      ('some_unknown_code', 500, _l.errorGenericTryAgain),
    ];
    for (final (code, status, message) in table) {
      testWidgets(code, (tester) async {
        await pumpJoin(tester, (r) => errorResponse(status, code));
        await _type(tester, 'K7P3QX');
        await tester.tap(_continue);
        await tester.pumpAndSettle();
        expect(find.text(message), findsOneWidget);
        expect(find.text('server text'), findsNothing);
      });
    }
  });

  group('accept errors show their own translated message', () {
    final table = <(String, int, String)>[
      ('invitation_not_found', 404, _l.duelErrInvitationNotFound),
      ('invitation_expired', 410, _l.duelErrInvitationExpired),
      ('invitation_already_used', 409, _l.duelErrInvitationAlreadyUsed),
      ('own_invitation', 400, _l.duelErrOwnInvitation),
      ('already_opponents', 409, _l.duelErrAlreadyOpponents),
      ('opponent_limit_reached', 409, _l.duelErrOpponentLimit),
      ('inviter_opponent_limit_reached', 409, _l.duelErrInviterOpponentLimit),
      ('throttled', 429, _l.duelErrThrottled),
    ];
    for (final (code, status, message) in table) {
      testWidgets(code, (tester) async {
        await pumpJoin(tester, (r) {
          if (r.method == 'GET') {
            return jsonResponse(200, {
              'inviter_username': 'alice',
              'expires_at': '2026-11-13T10:00:00Z',
            });
          }
          return errorResponse(status, code);
        });
        await _type(tester, 'K7P3QX');
        await tester.tap(_continue);
        await tester.pumpAndSettle();
        await tester.tap(find.text(_l.duelAccept));
        await tester.pumpAndSettle();
        expect(find.text(message), findsOneWidget);
        expect(find.text(_l.duelAccept), findsOneWidget, reason: 'still on the confirmation');
      });
    }
  });

  testWidgets('typing, confirming and accepting: the opponent comes back', (tester) async {
    final server = await pumpJoin(tester, (r) {
      if (r.method == 'GET') {
        return jsonResponse(200, {
          'inviter_username': 'alice',
          'expires_at': '2026-11-13T10:00:00Z',
        });
      }
      return jsonResponse(201, opponentJson(5, 'alice'));
    });
    await _type(tester, 'K7P3QX');
    await tester.tap(_continue);
    await tester.pumpAndSettle();

    expect(find.text(_l.duelChallengesYou('alice')), findsOneWidget);
    expect(find.text(_l.duelAcceptBody('alice')), findsOneWidget);
    expect(server.requests.where((r) => r.method == 'POST'), isEmpty,
        reason: 'nothing accepted before the explicit tap');

    await tester.tap(find.text(_l.duelAccept));
    await tester.pumpAndSettle();
    expect(find.text('result: alice'), findsOneWidget);
    expect(find.text(_l.duelNowOpponent('alice')), findsOneWidget);
    expect(server.requests.last.path, endsWith('/invitations/K7P3QX/accept/'));
  });

  testWidgets('"Not now" leaves without any call', (tester) async {
    final server = await pumpJoin(
      tester,
      (r) => jsonResponse(200, {
        'inviter_username': 'alice',
        'expires_at': '2026-11-13T10:00:00Z',
      }),
    );
    await _type(tester, 'K7P3QX');
    await tester.tap(_continue);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.duelNotNow));
    await tester.pumpAndSettle();
    expect(server.requests.length, 1, reason: 'only the preview');
    expect(find.byKey(const Key('join-code-field')), findsOneWidget);
  });

  testWidgets('from a link: preview failure lands on the typing screen with the message', (tester) async {
    final server = FakeDuelServer((r) => errorResponse(410, 'invitation_expired'));
    await tester.pumpWidget(
      duelApp(
        home: const DuelJoinConfirmScreen(code: 'K7P3QX'),
        duel: DuelProvider(service: server.service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('join-code-field')), findsOneWidget);
    expect(find.text(_l.duelErrInvitationExpired), findsOneWidget);
    expect(find.text('K7P3QX'), findsOneWidget, reason: 'code pre-filled');
  });

  testWidgets('from a link: the preview is shown without typing', (tester) async {
    final server = FakeDuelServer(
      (r) => jsonResponse(200, {
        'inviter_username': 'alice',
        'expires_at': '2026-11-13T10:00:00Z',
      }),
    );
    await tester.pumpWidget(
      duelApp(
        home: const DuelJoinConfirmScreen(code: 'K7P3QX'),
        duel: DuelProvider(service: server.service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_l.duelChallengesYou('alice')), findsOneWidget);
  });
}
