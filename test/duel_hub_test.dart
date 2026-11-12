import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/ui/duel/duel_blocked_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_hub_screen.dart';

import 'support/duel_test_support.dart';

final _l = AppLocalizationsEn();

void main() {
  late List<Map<String, Object?>> opponents;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    opponents = [opponentJson(1, 'alice'), opponentJson(2, 'bob')];
  });

  FakeDuelServer serverWithOpponents() => FakeDuelServer((r) {
    if (r.method == 'GET' && r.path.endsWith('/duel/opponents/')) {
      return jsonResponse(200, {'count': opponents.length, 'results': opponents});
    }
    return jsonResponse(204, null);
  });

  Future<void> pumpHub(
    WidgetTester tester,
    FakeDuelServer server, {
    FakeConnectivity? connectivity,
    DuelProvider? duel,
  }) async {
    // A Challenge button per opponent makes the list taller than the default
    // test screen: every row must be built.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      duelApp(
        home: const DuelHubScreen(),
        duel: duel ?? DuelProvider(service: server.service),
        connectivity: connectivity,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists the opponents; Inviter and Rejoindre; a Challenge button on each opponent', (tester) async {
    final server = serverWithOpponents();
    await pumpHub(tester, server);

    expect(find.text(_l.duelOpponentsSection(2)), findsOneWidget);
    expect(find.text('alice'), findsOneWidget);
    expect(find.text('bob'), findsOneWidget);
    expect(find.text(_l.duelInviteTitle), findsOneWidget);
    expect(find.text(_l.duelJoinTitle), findsOneWidget);
    expect(find.text(_l.duelMyInvitations), findsOneWidget);
    expect(find.text(_l.duelBlockedPlayers), findsOneWidget);
    // Batch 2 (QB-C-012): the live duel exists, one Challenge button per
    // opponent (lot 1 asserted the opposite).
    expect(find.text(_l.duelChallengeAction), findsNWidgets(2));
  });

  testWidgets('empty state', (tester) async {
    opponents = [];
    await pumpHub(tester, serverWithOpponents());
    expect(find.text(_l.duelNoOpponents), findsOneWidget);
  });

  testWidgets('hub offline: says so, calls nothing, actions disabled', (tester) async {
    final server = serverWithOpponents();
    await pumpHub(tester, server, connectivity: FakeConnectivity(online: false));

    expect(find.text(_l.duelOfflineMessage), findsOneWidget);
    expect(server.requests, isEmpty);
    expect(find.text('alice'), findsNothing, reason: 'nothing cached or shown');
    for (final title in [
      _l.duelInviteTitle,
      _l.duelJoinTitle,
      _l.duelMyInvitations,
      _l.duelBlockedPlayers,
    ]) {
      final tile = find.ancestor(of: find.text(title), matching: find.byType(InkWell));
      expect(tester.widget<InkWell>(tile.first).onTap, isNull, reason: title);
    }
  });

  testWidgets('hub reloads when the connection comes back', (tester) async {
    final server = serverWithOpponents();
    final connectivity = FakeConnectivity(online: false);
    await pumpHub(tester, server, connectivity: connectivity);
    connectivity.setOnline(true);
    await tester.pumpAndSettle();
    expect(find.text('alice'), findsOneWidget);
  });

  testWidgets('a pair never seen is announced once on opening, not on the next opening', (tester) async {
    opponents = [opponentJson(1, 'alice')];
    final server = serverWithOpponents();
    final duel = DuelProvider(service: server.service);

    await pumpHub(tester, server, duel: duel);
    expect(find.text(_l.duelNowOpponent('alice')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await pumpHub(tester, server, duel: duel);
    expect(find.text(_l.duelNowOpponent('alice')), findsNothing);
  });

  testWidgets('several new pairs: one grouped message', (tester) async {
    await pumpHub(tester, serverWithOpponents());
    expect(find.text(_l.duelNewOpponents(2)), findsOneWidget);
    expect(find.textContaining('now opponents with'), findsNothing);
  });

  testWidgets('Remove asks for confirmation, then calls DELETE', (tester) async {
    final server = serverWithOpponents();
    await pumpHub(tester, server);
    await tester.pump(const Duration(seconds: 5)); // let the snackbar go

    await tester.tap(find.byKey(const ValueKey('opponent-menu-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.duelMenuRemove));
    await tester.pumpAndSettle();
    expect(find.text(_l.duelRemoveBody('alice')), findsOneWidget);
    expect(server.requests.where((r) => r.method == 'DELETE'), isEmpty);

    await tester.tap(find.text(_l.duelRemoveAction));
    await tester.pumpAndSettle();
    final delete = server.requests.singleWhere((r) => r.method == 'DELETE');
    expect(delete.path, endsWith('/duel/opponents/1/'));
    expect(find.text('alice'), findsNothing);
    expect(find.text('bob'), findsOneWidget);
  });

  testWidgets('Block asks for confirmation, then calls POST block; Cancel does nothing', (tester) async {
    final server = serverWithOpponents();
    await pumpHub(tester, server);
    await tester.pump(const Duration(seconds: 5));

    await tester.tap(find.byKey(const ValueKey('opponent-menu-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.duelMenuBlock));
    await tester.pumpAndSettle();
    expect(find.text(_l.duelBlockBody('bob')), findsOneWidget);
    await tester.tap(find.text(_l.cancel));
    await tester.pumpAndSettle();
    expect(server.requests.where((r) => r.method == 'POST'), isEmpty);
    expect(find.text('bob'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('opponent-menu-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.duelMenuBlock));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.duelBlockAction));
    await tester.pumpAndSettle();
    expect(
      server.requests.singleWhere((r) => r.method == 'POST').path,
      endsWith('/duel/opponents/2/block/'),
    );
    expect(find.text('bob'), findsNothing);
  });

  group('Blocked players', () {
    testWidgets('lists, and Unblock says the pair is not recreated', (tester) async {
      var blocks = [
        {'id': 4, 'username': 'mallory', 'created_at': '2026-11-12T10:00:00Z'},
      ];
      final server = FakeDuelServer((r) {
        if (r.method == 'DELETE') {
          blocks = [];
          return jsonResponse(204, null);
        }
        return jsonResponse(200, {'count': blocks.length, 'results': blocks});
      });
      await tester.pumpWidget(
        duelApp(
          home: const DuelBlockedScreen(),
          duel: DuelProvider(service: server.service),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('mallory'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('unblock-4')));
      await tester.pumpAndSettle();
      expect(find.text(_l.duelUnblockBody('mallory')), findsOneWidget);
      await tester.tap(find.text(_l.duelUnblock).last);
      await tester.pumpAndSettle();

      expect(
        server.requests.singleWhere((r) => r.method == 'DELETE').path,
        endsWith('/duel/blocks/4/'),
      );
      expect(find.text('mallory'), findsNothing);
      expect(find.text(_l.duelUnblocked('mallory')), findsOneWidget);
    });

    testWidgets('empty list', (tester) async {
      final server = FakeDuelServer(
        (r) => jsonResponse(200, {'count': 0, 'results': []}),
      );
      await tester.pumpWidget(
        duelApp(
          home: const DuelBlockedScreen(),
          duel: DuelProvider(service: server.service),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_l.duelNoBlocked), findsOneWidget);
    });
  });
}
