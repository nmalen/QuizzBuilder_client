import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/providers/duel_provider.dart';

import 'support/duel_test_support.dart';

void main() {
  late List<Map<String, Object?>> serverOpponents;
  late FakeDuelServer server;
  late DuelProvider duel;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    serverOpponents = [opponentJson(1, 'alice'), opponentJson(2, 'bob')];
    server = FakeDuelServer((r) {
      if (r.method == 'GET' && r.path.endsWith('opponents/')) {
        return jsonResponse(200, {
          'count': serverOpponents.length,
          'results': serverOpponents,
        });
      }
      if (r.method == 'POST' && r.path.endsWith('/accept/')) {
        return jsonResponse(201, opponentJson(9, 'carol'));
      }
      return jsonResponse(204, null);
    });
    duel = DuelProvider(service: server.service);
  });

  test('a pair never seen is announced once, then never again', () async {
    await duel.loadOpponents(userId: 7);
    expect(duel.takeAnnouncement().map((o) => o.username), ['alice', 'bob']);
    expect(duel.takeAnnouncement(), isEmpty);

    await duel.loadOpponents(userId: 7);
    expect(duel.pendingAnnouncement, isEmpty, reason: 'same pairs: no repeat');

    serverOpponents.insert(0, opponentJson(3, 'dave'));
    await duel.loadOpponents(userId: 7);
    expect(duel.takeAnnouncement().map((o) => o.username), ['dave']);
  });

  test('seen pairs survive a new provider (kept on the device)', () async {
    await duel.loadOpponents(userId: 7);
    duel.takeAnnouncement();
    final again = DuelProvider(service: server.service);
    await again.loadOpponents(userId: 7);
    expect(again.pendingAnnouncement, isEmpty);
  });

  test('the seen set is per account and holds only ids', () async {
    await duel.loadOpponents(userId: 7);
    expect(duel.takeAnnouncement().length, 2);
    await duel.loadOpponents(userId: 8);
    expect(duel.takeAnnouncement().length, 2, reason: 'seen by 7, not by 8');

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('duel_seen_pairs_7')!;
    expect(stored.toSet(), {'1', '2'});
    for (final value in stored) {
      expect(int.tryParse(value), isNotNull, reason: 'no name, no e-mail');
    }
  });

  test('accepting an invitation marks the pair as seen: no announcement', () async {
    final opponent = await duel.acceptInvitation('k7p3qx', userId: 7);
    expect(opponent.username, 'carol');
    serverOpponents = [opponentJson(9, 'carol')];
    await duel.loadOpponents(userId: 7);
    expect(duel.pendingAnnouncement, isEmpty);
  });

  test('a failed load keeps the error and announces nothing', () async {
    server.handler = (r) => errorResponse(500, 'boom');
    await duel.loadOpponents(userId: 7);
    expect(duel.error, isNotNull);
    expect(duel.pendingAnnouncement, isEmpty);
  });

  test('detectNewOpponents is silent about failures', () async {
    server.handler = (r) => errorResponse(500, 'boom');
    await duel.detectNewOpponents(userId: 7);
    expect(duel.error, isNull);
  });

  test('reset forgets the in-memory state', () async {
    await duel.loadOpponents(userId: 7);
    duel.reset();
    expect(duel.opponents, isEmpty);
    expect(duel.pendingAnnouncement, isEmpty);
  });
}
