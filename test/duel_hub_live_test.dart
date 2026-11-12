import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/models/duel_live.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/ui/duel/duel_history_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_hub_screen.dart';

import 'support/duel_live_support.dart';
import 'support/duel_test_support.dart';

final _l = AppLocalizationsEn();

Map<String, Object?> _row(
  int id,
  String status,
  String name, {
  bool mine = false,
  int? pair,
}) => {
  'id': id,
  'status': status,
  'pair_id': pair ?? id,
  'opponent_username': name,
  'challenged_by_me': mine,
  'question_count': 10,
  'created_at': iso(FakeClock.base),
  'room_expires_at': iso(DateTime.utc(2026, 11, 12, 18, 52)),
  'starts_at': status == 'playing' ? iso(FakeClock.base) : null,
  'deadline_at': status == 'playing' ? iso(FakeClock.base.add(const Duration(minutes: 4))) : null,
};

class _Api {
  _Api() {
    server = FakeDuelServer((r) {
      final p = r.path;
      if (r.method == 'GET' && p.endsWith('/duel/opponents/')) {
        return jsonResponse(200, {
          'count': opponents.length,
          'results': opponents,
        });
      }
      if (r.method == 'GET' && p.endsWith('/duel/duels/')) {
        listCalls++;
        if (listFails) return errorResponse(500, 'server_error');
        return jsonResponse(200, {
          'server_time': iso(FakeClock.base),
          'count': open.length,
          'results': open,
        });
      }
      if (r.method == 'GET' && p.endsWith('/duel/duels/history/')) {
        if (historyResponse != null) return historyResponse!();
        return jsonResponse(200, {'count': history.length, 'results': history});
      }
      if (r.method == 'GET' && p.endsWith('/themes/')) {
        return jsonResponse(200, {'count': 0, 'results': []});
      }
      if (r.method == 'GET' && p.contains('/duel/duels/')) {
        final id = int.parse(p.split('/').where((e) => e.isNotEmpty).last);
        stateCalls.add(id);
        return jsonResponse(
          200,
          duelJson(
            id: id,
            serverTime: FakeClock.base,
            status: 'playing',
            startsAt: FakeClock.base.subtract(const Duration(seconds: 70)),
            mySubmitted: submittedIds.contains(id),
          ),
        );
      }
      return jsonResponse(204, null);
    });
  }

  late final FakeDuelServer server;
  List<Map<String, Object?>> opponents = [
    opponentJson(1, 'alice'),
    opponentJson(2, 'bob'),
  ];
  List<Map<String, Object?>> open = [];
  List<Map<String, Object?>> history = [];
  Set<int> submittedIds = {};
  List<int> stateCalls = [];
  int listCalls = 0;
  bool listFails = false;
  dynamic Function()? historyResponse;
}

Map<String, Object?> _history(
  int id,
  String name,
  String? outcome,
  int? mine,
  int? theirs, {
  String status = 'finished',
}) => {
  'id': id,
  'status': status,
  'opponent_username': name,
  'challenged_by_me': true,
  'outcome': outcome,
  'my_score': mine,
  'opponent_score': theirs,
  'question_count': 10,
  'themes': [10],
  'created_at': iso(DateTime.utc(2026, 11, 10, 20)),
  'closed_at': iso(DateTime.utc(2026, 11, 11, 20)),
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('DuelProvider: open duels', () {
    test('loads the list; a playing duel is looked up for my_submitted, a waiting one is not', () async {
      final api = _Api()
        ..open = [
          _row(5, 'waiting', 'alice'),
          _row(9, 'playing', 'bob'),
        ]
        ..submittedIds = {9};
      final provider = DuelProvider(service: api.server.service);
      await provider.loadOpenDuels();
      expect(provider.openDuels.map((d) => d.id), [5, 9]);
      expect(provider.openDuels[0].mySubmitted, isNull);
      expect(provider.openDuels[1].mySubmitted, isTrue);
      expect(api.stateCalls, [9], reason: 'only the playing duel is looked up');
    });

    test('failure: silent, the previous list stays', () async {
      final api = _Api()..open = [_row(5, 'waiting', 'alice')];
      final provider = DuelProvider(service: api.server.service);
      await provider.loadOpenDuels();
      api.listFails = true;
      await provider.loadOpenDuels();
      expect(provider.openDuels, hasLength(1));
      expect(provider.error, isNull);
    });

    test('banner duels: a game to resume first, then rooms where I am challenged', () async {
      final api = _Api()
        ..open = [
          _row(1, 'waiting', 'mine', mine: true),
          _row(2, 'waiting', 'alice'),
          _row(3, 'playing', 'bob'),
          _row(4, 'playing', 'carol'),
        ]
        ..submittedIds = {4};
      final provider = DuelProvider(service: api.server.service);
      await provider.loadOpenDuels();
      expect(provider.bannerDuels.map((d) => d.opponentUsername), ['bob', 'alice']);
    });

    test('openDuelForPair finds the open duel of a pair', () async {
      final api = _Api()..open = [_row(5, 'waiting', 'alice', pair: 7)];
      final provider = DuelProvider(service: api.server.service);
      await provider.loadOpenDuels();
      expect(provider.openDuelForPair(7)?.id, 5);
      expect(provider.openDuelForPair(8), isNull);
    });

    test('reset forgets the open duels and the questions kept in memory', () async {
      final api = _Api()..open = [_row(5, 'waiting', 'alice')];
      final provider = DuelProvider(service: api.server.service);
      await provider.loadOpenDuels();
      provider.rememberQuestions(5, [DuelQuestion.fromJson(questionJson(1))]);
      provider.reset();
      expect(provider.openDuels, isEmpty);
      expect(provider.questionsFor(5), isNull);
    });

    test('a sending is made once per duel; its answers stay the same', () async {
      final api = _Api();
      final provider = DuelProvider(service: api.server.service);
      final first = provider.submitAnswers(
        duelId: 1,
        answers: [1, null],
        giveUpAt: DateTime.now().add(const Duration(minutes: 1)),
      );
      final second = provider.submitAnswers(
        duelId: 1,
        answers: [4, 4],
        giveUpAt: DateTime.now().add(const Duration(minutes: 1)),
      );
      expect(identical(first, second), isTrue);
      expect(second.answers, [1, null]);
      expect(provider.hasSubmitted(1), isTrue);
    });
  });

  group('hub: open duels, Challenge buttons, history entry', () {
    Future<_Api> pumpHub(
      WidgetTester tester, {
      FakeConnectivity? connectivity,
      void Function(_Api)? configure,
    }) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = _Api();
      configure?.call(api);
      await tester.pumpWidget(const SizedBox()); // a fresh State every time
      await tester.pumpWidget(
        duelApp(
          home: const DuelHubScreen(),
          duel: DuelProvider(service: api.server.service),
          connectivity: connectivity,
        ),
      );
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('the four kinds of open duel, with their text', (tester) async {
      await pumpHub(
        tester,
        configure: (a) => a
          ..open = [
            _row(5, 'waiting', 'alice', pair: 1),
            _row(6, 'waiting', 'bob', mine: true, pair: 2),
            _row(7, 'playing', 'carol', pair: 11),
            _row(8, 'playing', 'dave', pair: 12),
          ]
          ..submittedIds = {8},
      );
      expect(find.text(_l.duelOpenSection(4)), findsOneWidget);
      expect(find.text(_l.duelOpenWaitingForMe('alice')), findsOneWidget);
      expect(find.text(_l.duelOpenWaitingForMeSub), findsOneWidget);
      expect(find.text(_l.duelOpenMyChallenge('bob')), findsOneWidget);
      expect(find.textContaining('Waiting · room open until'), findsOneWidget);
      expect(find.text(_l.duelOpenPlaying('carol')), findsOneWidget);
      expect(find.text(_l.duelOpenPlayingSub), findsOneWidget);
      expect(find.text(_l.duelOpenAwaitingResult('dave')), findsOneWidget);
      expect(find.text(_l.duelOpenAwaitingResultSub), findsOneWidget);
    });

    testWidgets('no open duel: no section; a failing check: no section, no message', (tester) async {
      await pumpHub(tester);
      expect(find.textContaining('Open duels'), findsNothing);

      await pumpHub(tester, configure: (a) => a.listFails = true);
      expect(find.textContaining('Open duels'), findsNothing);
      expect(find.text('alice'), findsOneWidget, reason: 'the rest of the hub works');
      expect(find.text(_l.errorGenericTryAgain), findsNothing);
    });

    testWidgets('offline: no open duels, no Challenge buttons, history disabled', (tester) async {
      final api = await pumpHub(
        tester,
        connectivity: FakeConnectivity(online: false),
        configure: (a) => a.open = [_row(5, 'waiting', 'alice')],
      );
      expect(api.server.requests, isEmpty);
      expect(find.text(_l.duelOpenSection(1)), findsNothing);
      expect(find.byKey(const ValueKey('challenge-1')), findsNothing);
      final tile = find.ancestor(
        of: find.text(_l.duelHistoryTitle),
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(tile.first).onTap, isNull);
    });

    testWidgets('every opponent has a Challenge button that opens the choice screen', (tester) async {
      final api = await pumpHub(tester);
      expect(find.text(_l.duelChallengeAction), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('challenge-2')));
      await tester.pumpAndSettle();
      expect(find.text(_l.duelChallengeTitle('bob')), findsOneWidget);
      expect(
        requestsTo(api.server, 'GET', '/duel/opponents/2/themes/'),
        hasLength(1),
        reason: 'the pair id, not an account id',
      );
    });

    testWidgets('an opponent with an open duel shows "Open" and goes to that duel', (tester) async {
      final api = await pumpHub(
        tester,
        configure: (a) => a.open = [_row(5, 'waiting', 'alice', pair: 1)],
      );
      expect(find.text(_l.duelOpenAction), findsOneWidget);
      expect(find.text(_l.duelChallengeAction), findsOneWidget, reason: 'bob only');
      await tester.tap(find.byKey(const ValueKey('challenge-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 50));
      expect(requestsTo(api.server, 'GET', '/duel/duels/5/'), isNotEmpty);
      expect(
        requestsTo(api.server, 'GET', '/themes/'),
        isEmpty,
        reason: 'no new challenge: the open duel is opened',
      );
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
    });

    testWidgets('the History card opens the history screen', (tester) async {
      await pumpHub(tester);
      await tester.tap(find.text(_l.duelHistoryTitle));
      await tester.pumpAndSettle();
      expect(find.text(_l.duelHistoryEmpty), findsOneWidget);
    });
  });

  group('history screen', () {
    Future<_Api> pumpHistory(
      WidgetTester tester, {
      FakeConnectivity? connectivity,
      String locale = 'en',
      void Function(_Api)? configure,
    }) async {
      final api = _Api();
      configure?.call(api);
      await tester.pumpWidget(const SizedBox()); // a fresh State every time
      await tester.pumpWidget(
        duelApp(
          home: const DuelHistoryScreen(),
          duel: DuelProvider(service: api.server.service),
          connectivity: connectivity,
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('one row per duel: opponent, outcome, questions, date, score', (tester) async {
      await pumpHistory(
        tester,
        configure: (a) => a.history = [
          _history(1, 'alice', 'win', 7, 5),
          _history(2, 'bob', 'loss', 3, 8),
          _history(3, 'carol', 'draw', 4, 4),
          _history(4, 'dave', 'win', 6, 0, status: 'forfeit'),
          _history(5, 'erin', 'loss', 0, 6, status: 'forfeit'),
          _history(6, 'frank', null, null, null, status: 'no_result'),
        ],
      );
      expect(find.text(_l.duelHistoryLine(_l.duelOutcomeWin, 10)), findsOneWidget);
      expect(find.text(_l.duelHistoryLine(_l.duelOutcomeLoss, 10)), findsOneWidget);
      expect(find.text(_l.duelHistoryLine(_l.duelOutcomeDraw, 10)), findsOneWidget);
      expect(find.text(_l.duelHistoryLine(_l.duelOutcomeWinForfeit, 10)), findsOneWidget);
      expect(find.text(_l.duelHistoryLine(_l.duelOutcomeLossForfeit, 10)), findsOneWidget);
      expect(find.text(_l.duelHistoryLine(_l.duelOutcomeNone, 10)), findsOneWidget);
      expect(find.text('7 – 5'), findsOneWidget);
      expect(find.text('4 – 4'), findsOneWidget);
      expect(find.byKey(const ValueKey('history-score-6')), findsNothing, reason: 'no score without result');
      expect(find.text('alice'), findsOneWidget);
      expect(find.textContaining('Nov'), findsWidgets);
    });

    testWidgets('no review link from the history: rows are not tappable', (tester) async {
      await pumpHistory(
        tester,
        configure: (a) => a.history = [_history(1, 'alice', 'win', 7, 5)],
      );
      final row = find.byKey(const ValueKey('history-1'));
      expect(find.descendant(of: row, matching: find.byType(InkWell)), findsNothing);
    });

    testWidgets('empty, offline, error with retry', (tester) async {
      await pumpHistory(tester);
      expect(find.text(_l.duelHistoryEmpty), findsOneWidget);

      await pumpHistory(tester, connectivity: FakeConnectivity(online: false));
      expect(find.text(_l.duelOfflineListMessage), findsOneWidget);

      final api = await pumpHistory(
        tester,
        configure: (a) => a.historyResponse = () => errorResponse(500, 'server_error'),
      );
      expect(find.text(_l.errorGenericTryAgain), findsOneWidget);
      api.historyResponse = null;
      api.history = [_history(1, 'alice', 'win', 7, 5)];
      await tester.tap(find.text(_l.retry));
      await tester.pumpAndSettle();
      expect(find.text('alice'), findsOneWidget);
    });

    testWidgets('French outcome labels', (tester) async {
      await pumpHistory(
        tester,
        locale: 'fr',
        configure: (a) => a.history = [_history(1, 'alice', 'win', 7, 5)],
      );
      expect(find.text('Victoire · 10 questions'), findsOneWidget);
      expect(find.text('Historique des duels'), findsOneWidget);
    });

    test('the history shape carries the status, so forfeit is told from a plain win', () {
      final item = DuelHistoryItem.fromJson(
        jsonDecode(jsonEncode(_history(4, 'dave', 'win', 6, 0, status: 'forfeit')))
            as Map<String, dynamic>,
      );
      expect(item.kind, DuelResultKind.winByForfeit);
    });
  });
}
