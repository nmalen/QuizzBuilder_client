import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/ui/duel/duel_live_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_share.dart';

import 'support/duel_live_support.dart';
import 'support/duel_scenario.dart';
import 'support/duel_test_support.dart';

final _l = AppLocalizationsEn();
const _link = 'https://play.quizzbuilder.fr/d/ABCD2345';

/// Lets a dialog or route animation finish (the room never "settles": its
/// clock ticks all the time).
Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// App lifecycle in the order the engine sends it.
void _background(WidgetTester tester) {
  for (final s in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

void _foreground(WidgetTester tester) {
  for (final s in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<DuelProvider> pumpRoom(
    WidgetTester tester,
    Scenario s, {
    InvitationShareFn? shareFn,
    FakeConnectivity? connectivity,
    String locale = 'en',
  }) async {
    // Tall window: the QR of the call link pushes the summary and "Cancel the
    // duel" below a 600 px fold, and the list only builds what it shows.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = DuelProvider(service: s.server.service);
    await pumpLive(
      tester,
      home: DuelLiveScreen(duelId: 1, now: s.clock.now, shareFn: shareFn),
      duel: provider,
      connectivity: connectivity,
      locale: locale,
    );
    await _settle(tester);
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    return provider;
  }

  Map<String, Object?> waiting(Scenario s, {bool challenger = true}) => duelJson(
    serverTime: s.serverNow,
    challengedByMe: challenger,
    callLink: challenger ? _link : null,
    roomExpiresAt: FakeClock.base.add(const Duration(minutes: 10)),
  );

  testWidgets('challenger: waiting card, call link, summary, time left', (tester) async {
    final s = Scenario();
    s.state = (_) => waiting(s);
    await pumpRoom(tester, s);

    expect(find.text(_l.duelRoomWaitingFor('alice')), findsOneWidget);
    expect(find.text(_l.duelRoomHintChallenger('alice')), findsOneWidget);
    expect(find.text(_l.duelRoomTimeLeft('10:00')), findsOneWidget);
    expect(find.text(_link), findsOneWidget);
    expect(find.text(_l.duelShare), findsOneWidget);
    expect(find.text(_l.duelCopy), findsOneWidget);
    expect(
      find.text(_l.duelRoomSummary(3, 20, 'Easy, Medium')),
      findsOneWidget,
    );
    expect(find.text(_l.duelCancelDuel), findsOneWidget);
  });

  testWidgets('challenged: no call link card, own hint', (tester) async {
    final s = Scenario();
    s.state = (_) => waiting(s, challenger: false);
    await pumpRoom(tester, s);
    expect(find.text(_l.duelRoomHintChallenged('alice')), findsOneWidget);
    expect(find.text(_l.duelCallLinkTitle), findsNothing);
    expect(find.byKey(const ValueKey('call-link')), findsNothing);
    expect(find.text(_l.duelCancelDuel), findsOneWidget);
  });

  testWidgets('Share sends the validated text with the link and the closing time', (tester) async {
    final s = Scenario();
    s.state = (_) => waiting(s);
    String? shared;
    await pumpRoom(tester, s, shareFn: (context, text) async => shared = text);

    await tester.tap(find.byKey(const ValueKey('call-link-share')));
    await tester.pump();
    final expected = _l.duelCallShareMessage(_link, '19:00');
    // The closing time is shown in the device zone: compare the part that
    // does not depend on it, then the zone-aware time.
    expect(shared, startsWith(_l.duelCallShareMessage(_link, '').split('\n').first));
    expect(shared, contains(_link));
    expect(shared, contains('\n'));
    final local = FakeClock.base.add(const Duration(minutes: 10)).toLocal();
    final hm =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    expect(shared, _l.duelCallShareMessage(_link, hm));
    expect(expected, isNotEmpty);
  });

  testWidgets('Copy puts the same message on the clipboard and says so', (tester) async {
    final s = Scenario();
    s.state = (_) => waiting(s);
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
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpRoom(tester, s);

    await tester.tap(find.byKey(const ValueKey('call-link-copy')));
    await tester.pump();
    expect(clipboard, contains(_link));
    expect(find.text(_l.duelCopied), findsOneWidget);
  });

  testWidgets('the room polls the state about every 2 s and counts down', (tester) async {
    final s = Scenario();
    s.state = (_) => waiting(s);
    await pumpRoom(tester, s);
    final first = requestsTo(s.server, 'GET', '/duel/duels/1/').length;
    expect(first, 1, reason: 'one immediate look on opening');

    await elapse(tester, s.clock, const Duration(seconds: 7));
    final after = requestsTo(s.server, 'GET', '/duel/duels/1/').length;
    expect(after, inInclusiveRange(4, 5), reason: '1 + about one per 2 s');
    expect(find.text(_l.duelRoomTimeLeft('9:53')), findsOneWidget);
  });

  testWidgets('waiting then playing: the countdown shows and the questions are fetched', (tester) async {
    final s = Scenario();
    var playing = false;
    s.state = (now) => playing
        ? duelJson(
            serverTime: now,
            status: 'playing',
            startsAt: now.add(const Duration(seconds: 8)),
          )
        : waiting(s);
    await pumpRoom(tester, s);
    expect(find.text(_l.duelRoomWaitingFor('alice')), findsOneWidget);

    playing = true;
    await elapse(tester, s.clock, const Duration(seconds: 2, milliseconds: 500));
    expect(find.byKey(const ValueKey('countdown-number')), findsOneWidget);
    expect(find.text(_l.duelCountdownIntro('alice')), findsOneWidget);
    expect(requestsTo(s.server, 'GET', '/duel/duels/1/questions/'), isNotEmpty);
    expect(find.text(_l.duelRoomWaitingFor('alice')), findsNothing);
  });

  testWidgets('expired: message and a way back', (tester) async {
    final s = Scenario();
    var status = 'waiting';
    s.state = (now) => {...waiting(s), 'status': status, 'server_time': iso(now)};
    await pumpRoom(tester, s);

    status = 'expired';
    await elapse(tester, s.clock, const Duration(seconds: 3));
    expect(find.text(_l.duelRoomExpired), findsOneWidget);
    expect(find.text(_l.duelBackToDuels), findsOneWidget);
    final before = s.server.requests.length;
    await elapse(tester, s.clock, const Duration(seconds: 6));
    expect(s.server.requests.length, before, reason: 'polling stopped');
  });

  testWidgets('cancelled by the other side: message', (tester) async {
    final s = Scenario();
    var status = 'waiting';
    s.state = (now) => {...waiting(s), 'status': status, 'server_time': iso(now)};
    await pumpRoom(tester, s);
    status = 'cancelled';
    await elapse(tester, s.clock, const Duration(seconds: 3));
    expect(find.text(_l.duelRoomCancelled), findsOneWidget);
  });

  testWidgets('polling stops in the background and resumes at once on return', (tester) async {
    final s = Scenario();
    s.state = (_) => waiting(s);
    await pumpRoom(tester, s);

    _background(tester);
    await tester.pump();
    final paused = s.server.requests.length;
    await elapse(tester, s.clock, const Duration(seconds: 10));
    expect(s.server.requests.length, paused, reason: 'no request in the background');

    _foreground(tester);
    await _settle(tester);
    expect(s.server.requests.length, paused + 1, reason: 'one look on return');
    await elapse(tester, s.clock, const Duration(seconds: 4));
    expect(s.server.requests.length, greaterThan(paused + 1));
  });

  testWidgets('429: no message, and the polls are spaced out', (tester) async {
    final s = Scenario();
    s.state = (_) => waiting(s);
    var limited = false;
    s.intercept = (r) => limited && r.method == 'GET' && r.path.endsWith('/duel/duels/1/')
        ? errorResponse(429, 'throttled')
        : null;
    await pumpRoom(tester, s);

    limited = true;
    final before = requestsTo(s.server, 'GET', '/duel/duels/1/').length;
    await elapse(tester, s.clock, const Duration(seconds: 20));
    final polls = requestsTo(s.server, 'GET', '/duel/duels/1/').length - before;
    expect(polls, lessThan(8), reason: 'spaced out (10 at the normal pace)');
    expect(polls, greaterThan(1));
    expect(find.text(_l.errorTooManyRequests), findsNothing);
    expect(find.text(_l.duelErrThrottled), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text(_l.duelRoomUnstable), findsNothing);
  });

  testWidgets('network trouble: a discreet line, polling goes on, back to normal', (tester) async {
    final s = Scenario();
    s.state = (_) => waiting(s);
    var down = false;
    s.intercept = (r) => down && r.path.endsWith('/duel/duels/1/') ? Scenario.network() : null;
    await pumpRoom(tester, s);

    down = true;
    await elapse(tester, s.clock, const Duration(seconds: 3));
    expect(find.text(_l.duelRoomUnstable), findsOneWidget);
    down = false;
    await elapse(tester, s.clock, const Duration(seconds: 3));
    expect(find.text(_l.duelRoomUnstable), findsNothing);
  });

  testWidgets('offline: the room says so and does not call', (tester) async {
    final s = Scenario();
    s.state = (_) => waiting(s);
    final connectivity = FakeConnectivity();
    await pumpRoom(tester, s, connectivity: connectivity);
    connectivity.setOnline(false);
    await tester.pump();
    final before = s.server.requests.length;
    await elapse(tester, s.clock, const Duration(seconds: 6));
    expect(find.text(_l.duelRoomOffline), findsOneWidget);
    expect(s.server.requests.length, before);

    connectivity.setOnline(true);
    await _settle(tester);
    expect(s.server.requests.length, before + 1);
    expect(find.text(_l.duelRoomOffline), findsNothing);
  });

  testWidgets('cancel: asks first, then POST cancel, leaves with a message', (tester) async {
    final s = Scenario();
    s.state = (_) => waiting(s);
    // Tall window, as in pumpRoom: the QR pushes "Cancel the duel" down.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = DuelProvider(service: s.server.service);
    await tester.pumpWidget(
      duelApp(
        duel: provider,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DuelLiveScreen(duelId: 1, now: s.clock.now),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('cancel-duel')));
    await _pumpDialog(tester);
    expect(find.text(_l.duelCancelDuelBody), findsOneWidget);
    expect(requestsTo(s.server, 'POST', '/cancel/'), isEmpty);
    await tester.tap(find.text(_l.duelBack));
    await _pumpDialog(tester);
    expect(requestsTo(s.server, 'POST', '/cancel/'), isEmpty);

    await tester.tap(find.byKey(const ValueKey('cancel-duel')));
    await _pumpDialog(tester);
    await tester.tap(find.text(_l.duelCancelDuel).last);
    await _pumpDialog(tester);
    expect(requestsTo(s.server, 'POST', '/duel/duels/1/cancel/'), hasLength(1));
    expect(find.text('open'), findsOneWidget, reason: 'back on the previous screen');
    expect(find.text(_l.duelDuelCancelled), findsOneWidget);
  });

  testWidgets('cancel refused because the start was fixed: message, follows the start', (tester) async {
    final s = Scenario();
    var playing = false;
    s.state = (now) => playing
        ? duelJson(serverTime: now, status: 'playing', startsAt: now.add(const Duration(seconds: 8)))
        : waiting(s);
    s.intercept = (r) {
      if (r.method == 'POST' && r.path.endsWith('/cancel/')) {
        playing = true;
        return errorResponse(409, 'duel_cannot_be_cancelled');
      }
      return null;
    };
    await pumpRoom(tester, s);
    await tester.tap(find.byKey(const ValueKey('cancel-duel')));
    await _pumpDialog(tester);
    await tester.tap(find.text(_l.duelCancelDuel).last);
    await tester.pump();
    await _settle(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(_l.duelErrCannotCancel), findsOneWidget);
    await elapse(tester, s.clock, const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('countdown-number')), findsOneWidget);
  });

  testWidgets('a duel that does not exist: message and way back', (tester) async {
    final s = Scenario();
    s.intercept = (r) => errorResponse(404, 'duel_not_found');
    await pumpRoom(tester, s);
    expect(find.text(_l.duelErrDuelNotFound), findsOneWidget);
    expect(find.text(_l.duelBackToDuels), findsOneWidget);
  });

  testWidgets('first load fails: message and retry', (tester) async {
    final s = Scenario();
    s.state = (_) => waiting(s);
    var down = true;
    s.intercept = (r) => down ? Scenario.network() : null;
    await pumpRoom(tester, s);
    expect(find.text(_l.duelErrNetwork), findsOneWidget);
    down = false;
    await tester.tap(find.text(_l.retry));
    await _settle(tester);
    expect(find.text(_l.duelRoomWaitingFor('alice')), findsOneWidget);
  });

  testWidgets('French strings render in the room', (tester) async {
    final s = Scenario();
    s.state = (_) => waiting(s);
    await pumpRoom(tester, s, locale: 'fr');
    expect(find.text('En attente de alice…'), findsOneWidget);
    expect(find.text('Annuler le duel'), findsOneWidget);
    expect(find.text('Salle ouverte encore 10:00'), findsOneWidget);
  });

  testWidgets('no SocketException leaks out', (tester) async {
    final s = Scenario();
    s.state = (_) => waiting(s);
    s.intercept = (r) => throw const SocketException('down');
    await pumpRoom(tester, s);
    expect(tester.takeException(), isNull);
  });
}
