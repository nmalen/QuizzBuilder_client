import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/l10n/app_localizations_fr.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/ui/duel/duel_invite_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_live_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_qr.dart';
import 'package:QuizzBuilder/ui/duel/duel_widgets.dart';

import 'support/duel_live_support.dart';
import 'support/duel_scenario.dart';
import 'support/duel_test_support.dart';

/// The QR code of the invitation link (Invite screen) and of the call link
/// (waiting room): what it encodes, where it sits, how it looks, and what
/// becomes of it offline, on error and when the room is over.
final _en = AppLocalizationsEn();
final _fr = AppLocalizationsFr();
const _callLink = 'https://play.quizzbuilder.fr/d/ABCD2345';
const _inviteLink = 'https://play.quizzbuilder.fr/d/K7P3QX';

const _qr = ValueKey('duel-qr');
Finder get _qrFinder => find.byKey(_qr);
Finder get _qrCaption => find.byKey(const ValueKey('duel-qr-caption'));

QrImageView _view(WidgetTester tester) => tester.widget<QrImageView>(_qrFinder);

/// What the screen hands to the QR widget.
String _handedOver(WidgetTester tester) =>
    tester.widget<DuelQrCode>(find.byType(DuelQrCode)).data;

/// RGBA pixels of the QR on screen (the QR alone, via its repaint boundary).
Future<List<int>> _drawn(WidgetTester tester) async =>
    (await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('duel-qr-boundary')),
      );
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return bytes!.buffer.asUint8List().toList();
    }))!;

/// RGBA pixels of a reference QR of [data], drawn the same way, alone.
Future<List<int>> _reference(WidgetTester tester, String data) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey('duel-qr-boundary'),
            child: QrImageView(
              data: data,
              size: 192,
              padding: const EdgeInsets.all(8),
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return _drawn(tester);
}

/// The QR on screen is the QR of exactly [expected] (and not of [other]).
Future<void> expectDrawnFor(WidgetTester tester, String expected, String other) async {
  final onScreen = await _drawn(tester);
  expect(onScreen.any((b) => b == 0), isTrue, reason: 'black modules are drawn');
  expect(await _reference(tester, expected), onScreen, reason: 'same pixels as the QR of $expected');
  expect(await _reference(tester, other), isNot(onScreen), reason: 'control: another link differs');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Invite screen', () {
    Future<FakeConnectivity> pumpInvite(
      WidgetTester tester, {
      String locale = 'en',
      http.Response Function()? answer,
      FakeConnectivity? connectivity,
      Size size = const Size(800, 2400),
      double textScale = 1,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final server = FakeDuelServer(
        (r) => answer != null ? answer() : jsonResponse(201, invitationJson()),
      );
      final conn = connectivity ?? FakeConnectivity();
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
          child: duelApp(
            home: const DuelInviteScreen(),
            duel: DuelProvider(service: server.service),
            connectivity: conn,
            locale: locale,
          ),
        ),
      );
      await tester.pumpAndSettle();
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      return conn;
    }

    testWidgets('the QR encodes exactly the invitation link', (tester) async {
      await pumpInvite(tester);
      expect(_qrFinder, findsOneWidget);
      expect(_handedOver(tester), _inviteLink);
      // Not the code, not the share message: only the link.
      expect(_handedOver(tester), isNot(contains('K7P-3QX')));
      expect(_handedOver(tester), isNot(contains(' ')));
      await expectDrawnFor(tester, _inviteLink, _callLink);
    });

    testWidgets('black on white, 192 dp, local rendering', (tester) async {
      await pumpInvite(tester);
      final view = _view(tester);
      expect(view.size, 192);
      expect(view.backgroundColor, Colors.white);
      expect(view.eyeStyle.color, Colors.black);
      expect(view.dataModuleStyle.color, Colors.black);
      expect(view.errorCorrectionLevel, QrErrorCorrectLevel.M);
      expect(tester.getSize(_qrFinder), const Size(192, 192));
      expect(view.semanticsLabel, _en.duelQrSemantics);
    });

    testWidgets('sits under Share and Copy, in the same card, centered, with its caption', (tester) async {
      await pumpInvite(tester);
      final share = tester.getRect(find.text(_en.duelShare));
      final copy = tester.getRect(find.text(_en.duelCopy));
      final qr = tester.getRect(_qrFinder);
      expect(qr.top, greaterThan(share.bottom));
      expect(qr.top, greaterThan(copy.bottom));
      expect(find.text(_en.duelInviteQrCaption), findsOneWidget);
      final caption = tester.getRect(_qrCaption);
      expect(caption.top, greaterThanOrEqualTo(qr.bottom));
      // Same card as the code.
      final card = find.ancestor(of: find.byKey(const Key('invitation-code')), matching: find.byType(DuelCard));
      expect(find.descendant(of: card, matching: _qrFinder), findsOneWidget);
      expect(qr.center.dx, closeTo(tester.getRect(card).center.dx, 1));
    });

    testWidgets('captions, FR and EN, as validated', (tester) async {
      await pumpInvite(tester);
      expect(
        find.text("Your friend can also scan this QR code with their phone's camera."),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await pumpInvite(tester, locale: 'fr');
      expect(
        find.text("Ton proche peut aussi scanner ce QR code avec l'appareil photo de son téléphone."),
        findsOneWidget,
      );
      expect(_fr.duelQrSemantics, 'QR code du lien');
    });

    testWidgets('while the invitation is created, and when it fails: no QR', (tester) async {
      await pumpInvite(tester, answer: () => errorResponse(500, 'server_error'));
      expect(_qrFinder, findsNothing);
      expect(_qrCaption, findsNothing);
    });

    testWidgets('offline before the invitation exists: the offline card, no QR', (tester) async {
      await pumpInvite(tester, connectivity: FakeConnectivity(online: false));
      expect(find.text(_en.duelInviteOfflineMessage), findsOneWidget);
      expect(_qrFinder, findsNothing);
    });

    testWidgets('offline after it was created: nothing changes, the QR is local', (tester) async {
      final conn = await pumpInvite(tester);
      expect(_qrFinder, findsOneWidget);
      conn.setOnline(false);
      await tester.pumpAndSettle();
      expect(_qrFinder, findsOneWidget);
      expect(_handedOver(tester), _inviteLink);
      expect(find.text(_en.duelInviteQrCaption), findsOneWidget);
    });

    testWidgets('an expired invitation keeps its QR, like its code (decision V3 A)', (tester) async {
      await pumpInvite(
        tester,
        answer: () => jsonResponse(201, {
          ...invitationJson(),
          'expires_at': '2020-01-01T00:00:00Z',
        }),
      );
      expect(_qrFinder, findsOneWidget);
      expect(find.byKey(const Key('invitation-code')), findsOneWidget);
      // No expiry text or button was invented for the QR.
      expect(find.textContaining('expired'), findsNothing);
      expect(find.text('New invitation'), findsNothing);
    });

    for (final locale in ['en', 'fr']) {
      testWidgets('320 dp, text x1.3, $locale: no overflow, QR reachable', (tester) async {
        await pumpInvite(
          tester,
          locale: locale,
          size: const Size(320, 640),
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          _qrFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
        expect(tester.getSize(_qrFinder), const Size(192, 192));
      });
    }
  });

  group('Waiting room', () {
    Map<String, Object?> waiting(Scenario s, {bool challenger = true, String status = 'waiting'}) =>
        {
          ...duelJson(
            serverTime: s.serverNow,
            challengedByMe: challenger,
            callLink: challenger ? _callLink : null,
            roomExpiresAt: FakeClock.base.add(const Duration(minutes: 10)),
          ),
          'status': status,
        };

    Scenario room({bool challenger = true, String status = 'waiting'}) {
      final s = Scenario();
      s.state = (_) => waiting(s, challenger: challenger, status: status);
      return s;
    }

    Future<FakeConnectivity> pumpRoom(
      WidgetTester tester,
      Scenario s, {
      String locale = 'en',
      Size size = const Size(800, 2400),
      double textScale = 1,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final conn = FakeConnectivity();
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
          child: duelApp(
            home: DuelLiveScreen(duelId: 1, now: s.clock.now),
            duel: DuelProvider(service: s.server.service),
            connectivity: conn,
            locale: locale,
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 1));
      }
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
      return conn;
    }

    testWidgets('challenger: the QR encodes exactly the call link, under Share and Copy', (tester) async {
      final s = room();
      await pumpRoom(tester, s);
      expect(_qrFinder, findsOneWidget);
      expect(_handedOver(tester), _callLink);
      final share = tester.getRect(find.byKey(const ValueKey('call-link-share')));
      final copy = tester.getRect(find.byKey(const ValueKey('call-link-copy')));
      final qr = tester.getRect(_qrFinder);
      expect(qr.top, greaterThan(share.bottom));
      expect(qr.top, greaterThan(copy.bottom));
      expect(_view(tester).size, 192);
      expect(_view(tester).backgroundColor, Colors.white);
      expect(_view(tester).eyeStyle.color, Colors.black);
      // In the call link card, centered in it.
      final card = find.ancestor(of: find.byKey(const ValueKey('call-link')), matching: find.byType(DuelCard));
      expect(find.descendant(of: card, matching: _qrFinder), findsOneWidget);
      expect(qr.center.dx, closeTo(tester.getRect(card).center.dx, 1));
      // Last: it replaces the tree with a reference code.
      await expectDrawnFor(tester, _callLink, _inviteLink);
    });

    testWidgets('the caption names the opponent, FR and EN', (tester) async {
      final s = room();
      await pumpRoom(tester, s);
      expect(
        find.text("alice can also scan this QR code with their phone's camera."),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      final s2 = room();
      await pumpRoom(tester, s2, locale: 'fr');
      expect(
        find.text("alice peut aussi scanner ce QR code avec l'appareil photo de son téléphone."),
        findsOneWidget,
      );
    });

    testWidgets('challenged: no call link card, so no QR', (tester) async {
      final s = room(challenger: false);
      await pumpRoom(tester, s);
      expect(find.text(_en.duelRoomHintChallenged('alice')), findsOneWidget);
      expect(_qrFinder, findsNothing);
      expect(_qrCaption, findsNothing);
    });

    testWidgets('offline: the QR stays, the offline line shows', (tester) async {
      final s = room();
      final conn = await pumpRoom(tester, s);
      conn.setOnline(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(_en.duelRoomOffline), findsOneWidget);
      expect(_qrFinder, findsOneWidget);
      expect(_handedOver(tester), _callLink);
    });

    for (final status in ['expired', 'cancelled']) {
      testWidgets('room $status: the card goes, so does the QR', (tester) async {
        final s = room(status: status);
        await pumpRoom(tester, s);
        expect(_qrFinder, findsNothing);
        expect(find.byKey(const ValueKey('call-link')), findsNothing);
      });
    }

    testWidgets('the start is fixed: the countdown replaces the room and the QR', (tester) async {
      final s = Scenario();
      var started = false;
      s.state = (_) => started
          ? duelJson(
              serverTime: s.serverNow,
              status: 'playing',
              startsAt: s.serverNow.add(const Duration(seconds: 8)),
              challengedByMe: true,
            )
          : waiting(s);
      s.startsAt = s.serverNow.add(const Duration(seconds: 8));
      await pumpRoom(tester, s);
      expect(_qrFinder, findsOneWidget);
      started = true;
      await elapse(tester, s.clock, const Duration(seconds: 3));
      expect(find.byKey(const ValueKey('countdown-number')), findsOneWidget);
      expect(_qrFinder, findsNothing);
    });

    for (final locale in ['en', 'fr']) {
      testWidgets('320 dp, text x1.3, $locale: no overflow, QR reachable', (tester) async {
        final s = room();
        await pumpRoom(
          tester,
          s,
          locale: locale,
          size: const Size(320, 640),
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          _qrFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
        expect(tester.getSize(_qrFinder), const Size(192, 192));
      });
    }
  });

  group('the widget', () {
    testWidgets('nothing is drawn for data that cannot be encoded', (tester) async {
      final tooLong = 'x' * (duelQrMaxChars + 1);
      expect(duelQrCanEncode(tooLong), isFalse);
      expect(duelQrCanEncode('x' * duelQrMaxChars), isTrue);
      expect(duelQrCanEncode(''), isFalse);
      expect(duelQrCanEncode(_inviteLink), isTrue);
      expect(duelQrCanEncode(_callLink), isTrue);

      await tester.pumpWidget(
        duelApp(
          home: Scaffold(body: DuelQrCode(data: tooLong, caption: 'caption')),
          duel: DuelProvider(service: FakeDuelServer((r) => jsonResponse(200, {})).service),
        ),
      );
      expect(_qrFinder, findsNothing);
      expect(find.text('caption'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    test('the duel links fit a small code: version 3, 29 x 29 modules at level M', () {
      for (final link in [_inviteLink, _callLink]) {
        final v = QrValidator.validate(data: link, errorCorrectionLevel: QrErrorCorrectLevel.M);
        expect(v.status, QrValidationStatus.valid);
        expect(v.qrCode!.typeNumber, 3);
        expect(v.qrCode!.moduleCount, 29);
      }
    });
  });
}
