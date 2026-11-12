import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:QuizzBuilder/models/duel_live.dart';
import 'package:QuizzBuilder/services/api_exception.dart';

import 'support/duel_live_support.dart';
import 'support/duel_test_support.dart';

void main() {
  final server0 = FakeClock.base;

  test('routes and methods of the live calls', () async {
    final server = FakeDuelServer((r) {
      if (r.path.endsWith('/themes/') || r.path.endsWith('/history/')) {
        return jsonResponse(200, {'count': 0, 'results': []});
      }
      if (r.method == 'GET' && r.path.endsWith('/duel/duels/')) {
        return jsonResponse(200, {
          'server_time': iso(server0),
          'count': 0,
          'results': [],
        });
      }
      if (r.path.endsWith('/questions/')) {
        return jsonResponse(
          200,
          questionsPayload(count: 3, startsAt: server0, serverTime: server0),
        );
      }
      return jsonResponse(
        r.method == 'POST' && r.path.endsWith('/duel/duels/') ? 201 : 200,
        duelJson(serverTime: server0),
      );
    });
    final s = server.service;
    await s.listThemes(3);
    await s.createDuel(
      pairId: 3,
      themeIds: [10, 11],
      difficulties: ['easy'],
      questionCount: 10,
    );
    await s.listOpenDuels();
    await s.listHistory();
    await s.getDuel(1);
    await s.joinDuel('abcd-2345');
    await s.cancelDuel(1);
    await s.getQuestions(1);
    await s.submitAnswers(1, [1, null, 4]);

    final seen = server.requests
        .map((r) => '${r.method} ${r.path.split('/duel/').last}')
        .toList();
    expect(seen, [
      'GET opponents/3/themes/',
      'POST duels/',
      'GET duels/',
      'GET duels/history/',
      'GET duels/1/',
      'POST duels/join/ABCD2345/',
      'POST duels/1/cancel/',
      'GET duels/1/questions/',
      'POST duels/1/answers/',
    ]);
  });

  test('createDuel sends pair, themes, difficulties and count', () async {
    final server = FakeDuelServer(
      (r) => jsonResponse(201, duelJson(serverTime: server0)),
    );
    await server.service.createDuel(
      pairId: 3,
      themeIds: [10, 11],
      difficulties: ['easy', 'hard'],
      questionCount: 15,
    );
    expect(jsonDecode(server.requests.single.body), {
      'pair_id': 3,
      'themes': [10, 11],
      'difficulties': ['easy', 'hard'],
      'question_count': 15,
    });
  });

  test('submitAnswers sends the list as is, nulls included', () async {
    final server = FakeDuelServer(
      (r) => jsonResponse(200, duelJson(serverTime: server0, status: 'playing')),
    );
    await server.service.submitAnswers(1, [2, null, 4]);
    expect(jsonDecode(server.requests.single.body), {
      'answers': [2, null, 4],
    });
  });

  test('a duel parses with its result and the helper kinds', () async {
    final json = duelJson(
      status: 'forfeit',
      serverTime: server0,
      startsAt: server0,
      result: resultJson(outcome: 'win', forfeit: true),
    );
    final duel = Duel.fromJson(json);
    expect(duel.status, DuelStatus.forfeit);
    expect(duel.themeIds, [10]);
    expect(duel.difficulties, ['easy', 'medium']);
    expect(duel.result!.kind, DuelResultKind.winByForfeit);
    expect(duel.result!.questions, hasLength(3));
    expect(duel.result!.questions[1].myAnswer, 2);
    expect(duel.result!.questions[1].opponentAnswer, isNull);
  });

  test('result kinds', () {
    DuelResultKind kind(String? o, bool f) =>
        duelResultKind(outcome: DuelOutcome.parse(o), forfeit: f);
    expect(kind('win', false), DuelResultKind.win);
    expect(kind('loss', false), DuelResultKind.loss);
    expect(kind('draw', false), DuelResultKind.draw);
    expect(kind('win', true), DuelResultKind.winByForfeit);
    expect(kind('loss', true), DuelResultKind.lossByForfeit);
    expect(kind(null, false), DuelResultKind.none);
  });

  test('a play question has no right answer field', () {
    final question = DuelQuestion.fromJson(questionJson(1));
    expect(question.answers('en'), hasLength(4));
    expect(question.text('fr'), 'Question FR 1 ?');
    expect(question.themeName('en'), 'Geography');
    expect(questionJson(1).keys.any((k) => k.contains('correct')), isFalse);
  });

  test('open duels list: server time, and no my_submitted in the rows', () async {
    final server = FakeDuelServer(
      (r) => jsonResponse(200, {
        'server_time': iso(server0),
        'count': 1,
        'results': [
          {
            'id': 7,
            'status': 'playing',
            'pair_id': 3,
            'opponent_username': 'alice',
            'challenged_by_me': false,
            'question_count': 10,
            'created_at': iso(server0),
            'room_expires_at': iso(server0),
            'starts_at': iso(server0),
            'deadline_at': iso(server0),
          },
        ],
      }),
    );
    final page = await server.service.listOpenDuels();
    expect(page.serverTime, server0);
    expect(page.duels.single.status, DuelStatus.playing);
    expect(page.duels.single.mySubmitted, isNull);
  });

  test('themes parse: names, category, counts; nothing about ownership', () async {
    final server = FakeDuelServer(
      (r) => jsonResponse(200, {
        'count': 1,
        'results': [
          {
            'id': 10,
            'name_fr': 'Capitales',
            'name_en': 'Capitals',
            'category_id': 1,
            'category_name_fr': 'Géographie',
            'category_name_en': 'Geography',
            'is_free': true,
            'question_counts': {'easy': 12, 'medium': 0, 'hard': 3},
          },
        ],
      }),
    );
    final theme = (await server.service.listThemes(3)).single;
    expect(theme.name('fr'), 'Capitales');
    expect(theme.categoryName('en'), 'Geography');
    expect(theme.countFor('easy'), 12);
    expect(theme.countFor('medium'), 0);
    expect(theme.countFor('unknown'), 0);
  });

  test('duel_already_open carries the existing duel in details', () async {
    final server = FakeDuelServer(
      (r) => jsonResponse(409, {
        'error': {
          'code': 'duel_already_open',
          'message': 'x',
          'status_code': 409,
          'details': {
            'duel': {'id': 42},
          },
        },
      }),
    );
    await expectLater(
      server.service.createDuel(
        pairId: 3,
        themeIds: [1],
        difficulties: ['easy'],
        questionCount: 10,
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'duel_already_open')
            .having((e) => (e.details?['duel'] as Map)['id'], 'duel id', 42),
      ),
    );
  });

  test('a questions payload without times is an invalid response', () async {
    final server = FakeDuelServer(
      (r) => jsonResponse(200, {'duel_id': 1, 'questions': []}),
    );
    await expectLater(
      server.service.getQuestions(1),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'invalid_response')),
    );
  });
}
