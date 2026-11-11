import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/l10n/app_localizations_fr.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/ui/duel/duel_invitations_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_invite_screen.dart';

import 'support/duel_test_support.dart';

final _l = AppLocalizationsEn();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the code in large, validity, Share and Copy', (tester) async {
    final server = FakeDuelServer((r) => jsonResponse(201, invitationJson()));
    await tester.pumpWidget(
      duelApp(
        home: const DuelInviteScreen(),
        duel: DuelProvider(service: server.service),
      ),
    );
    await tester.pumpAndSettle();

    expect(server.requests.single.method, 'POST');
    expect(find.byKey(const Key('invitation-code')), findsOneWidget);
    expect(find.text('K7P-3QX'), findsOneWidget);
    expect(find.text(_l.duelInviteSingleUse), findsOneWidget);
    expect(find.text(_l.duelShare), findsOneWidget);
    expect(find.text(_l.duelCopy), findsOneWidget);
  });

  testWidgets('Share hands the validated message (link and code) to the sheet', (tester) async {
    final server = FakeDuelServer((r) => jsonResponse(201, invitationJson()));
    String? shared;
    await tester.pumpWidget(
      duelApp(
        home: DuelInviteScreen(shareFn: (context, text) async => shared = text),
        duel: DuelProvider(service: server.service),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.duelShare));
    await tester.pumpAndSettle();

    expect(shared, isNotNull);
    expect(shared, contains('https://play.quizzbuilder.fr/d/K7P3QX'));
    expect(shared, contains('K7P-3QX'));
    expect(shared, startsWith('Challenge me on QuizzBuilder!'));
  });

  testWidgets('the shared message is French in a French app', (tester) async {
    final server = FakeDuelServer((r) => jsonResponse(201, invitationJson()));
    String? shared;
    await tester.pumpWidget(
      duelApp(
        locale: 'fr',
        home: DuelInviteScreen(shareFn: (context, text) async => shared = text),
        duel: DuelProvider(service: server.service),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppLocalizationsFr().duelShare));
    await tester.pumpAndSettle();
    expect(shared, startsWith('Défie-moi sur QuizzBuilder !'));
    expect(shared, contains('https://play.quizzbuilder.fr/d/K7P3QX'));
  });

  testWidgets('Copy puts the same message on the clipboard', (tester) async {
    final server = FakeDuelServer((r) => jsonResponse(201, invitationJson()));
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(
      duelApp(
        home: const DuelInviteScreen(),
        duel: DuelProvider(service: server.service),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.duelCopy));
    await tester.pumpAndSettle();

    expect(clipboard, contains('https://play.quizzbuilder.fr/d/K7P3QX'));
    expect(find.text(_l.duelCopied), findsOneWidget);
  });

  testWidgets('the cap of 5 active invitations: message, then access to My invitations', (tester) async {
    final server = FakeDuelServer((r) {
      if (r.method == 'POST') {
        return errorResponse(409, 'active_invitation_limit_reached');
      }
      return jsonResponse(200, {
        'count': 1,
        'results': [invitationJson()],
      });
    });
    await tester.pumpWidget(
      duelApp(
        home: const DuelInviteScreen(),
        duel: DuelProvider(service: server.service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_l.duelErrActiveInvitationLimit), findsOneWidget);
    expect(find.byKey(const Key('invitation-code')), findsNothing);
    await tester.tap(find.text(_l.duelMyInvitations));
    await tester.pumpAndSettle();
    expect(find.text('K7P-3QX'), findsOneWidget);
  });

  testWidgets('another error offers Retry', (tester) async {
    var calls = 0;
    final server = FakeDuelServer((r) {
      calls++;
      return calls == 1
          ? errorResponse(500, 'boom')
          : jsonResponse(201, invitationJson());
    });
    await tester.pumpWidget(
      duelApp(
        home: const DuelInviteScreen(),
        duel: DuelProvider(service: server.service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_l.errorGenericTryAgain), findsOneWidget);
    await tester.tap(find.text(_l.retry));
    await tester.pumpAndSettle();
    expect(find.text('K7P-3QX'), findsOneWidget);
  });

  testWidgets('offline: says so and calls nothing; creates the invitation when back online', (tester) async {
    final server = FakeDuelServer((r) => jsonResponse(201, invitationJson()));
    final connectivity = FakeConnectivity(online: false);
    await tester.pumpWidget(
      duelApp(
        home: const DuelInviteScreen(),
        duel: DuelProvider(service: server.service),
        connectivity: connectivity,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_l.duelInviteOfflineMessage), findsOneWidget);
    expect(server.requests, isEmpty);

    connectivity.setOnline(true);
    await tester.pumpAndSettle();
    expect(find.text('K7P-3QX'), findsOneWidget);
  });

  group('My invitations', () {
    testWidgets('lists, shares again and cancels after confirmation', (tester) async {
      var invitations = [
        invitationJson(),
        invitationJson(code: 'ABCD23', display: 'ABC-D23'),
      ];
      final server = FakeDuelServer((r) {
        if (r.method == 'DELETE') {
          invitations = invitations
              .where((i) => !r.path.contains(i['code']! as String))
              .toList();
          return jsonResponse(204, null);
        }
        return jsonResponse(200, {
          'count': invitations.length,
          'results': invitations,
        });
      });
      String? shared;
      await tester.pumpWidget(
        duelApp(
          home: DuelInvitationsScreen(shareFn: (c, t) async => shared = t),
          duel: DuelProvider(service: server.service),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('K7P-3QX'), findsOneWidget);
      expect(find.text('ABC-D23'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.share).first);
      await tester.pumpAndSettle();
      expect(shared, contains('K7P3QX'));

      await tester.tap(find.byKey(const ValueKey('cancel-K7P3QX')));
      await tester.pumpAndSettle();
      expect(find.text(_l.duelCancelInvitationBody('K7P-3QX')), findsOneWidget);
      expect(server.requests.where((r) => r.method == 'DELETE'), isEmpty,
          reason: 'confirmation first');

      await tester.tap(find.text(_l.duelCancelInvitationAction));
      await tester.pumpAndSettle();
      expect(server.requests.last.path, endsWith('/invitations/K7P3QX/'));
      expect(find.text('K7P-3QX'), findsNothing);
      expect(find.text('ABC-D23'), findsOneWidget);
      expect(find.text(_l.duelInvitationCancelled), findsOneWidget);
    });

    testWidgets('empty list', (tester) async {
      final server = FakeDuelServer(
        (r) => jsonResponse(200, {'count': 0, 'results': []}),
      );
      await tester.pumpWidget(
        duelApp(
          home: const DuelInvitationsScreen(),
          duel: DuelProvider(service: server.service),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_l.duelNoInvitations), findsOneWidget);
    });
  });
}
