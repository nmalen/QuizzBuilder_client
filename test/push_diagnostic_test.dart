import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/services/auth_service.dart';
import 'package:QuizzBuilder/services/push/device_registration_api.dart';
import 'package:QuizzBuilder/services/push/push_notification_service.dart';
import 'package:QuizzBuilder/services/push/push_payload.dart';

import 'support/push_test_support.dart';

/// QB-C-024 points 1 and 2: where the registration chain could break, and the
/// `[PUSH]` journal that says where it does. Firebase is simulated.

class _TokenAuth extends AuthService {
  @override
  Future<String?> getAccessToken() async => 'test-token';
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the registration chain', () {
    test(
      'an ID handed out BEFORE the permission is kept, and used once it is granted, '
      'even if register() hands none out again',
      () async {
        final gateway = FakePushGateway(authorized: false);
        final service = PushNotificationService(gateway: gateway);
        await service.start();

        // The provider registers the installation at launch, before the
        // player has answered anything.
        gateway.refreshes.add('fid-early-fictional');
        await pumpEventQueue();
        expect(service.installationId, isNull, reason: 'no permission yet');

        // "Turn on": the provider already knows this installation and hands
        // nothing out this time (what the 15 s timeout reads as: null).
        gateway.authorized = true;
        gateway.installationId = null;
        await service.refreshInstallationId();
        expect(service.installationId, 'fid-early-fictional');
        await service.dispose();
      },
    );

    test('no ID handed out at all: nothing is invented', () async {
      final gateway = FakePushGateway(authorized: true)..installationId = null;
      final service = PushNotificationService(gateway: gateway);
      await service.start();
      expect(service.installationId, isNull);
      await service.dispose();
    });

    test(
      'the notification that started the app is not held back by a slow provider',
      () async {
        final gateway = FakePushGateway(
          authorized: true,
          initial: {
            PushPayloadKeys.type: 'duel_call',
            PushPayloadKeys.duelId: '9',
          },
        )..registerGate = Completer<void>();
        final service = PushNotificationService(gateway: gateway);
        final out = <PushDestination>[];
        service.destinations.listen(out.add);
        unawaited(service.start());
        await pumpEventQueue();
        expect(
          out,
          hasLength(1),
          reason: 'register() has not answered yet (15 s at worst)',
        );
        gateway.registerGate!.complete();
        await pumpEventQueue();
        expect(service.installationId, fakeInstallationId);
        await service.dispose();
      },
    );
  });

  group('the [PUSH] journal', () {
    late List<String> lines;
    late DebugPrintCallback original;

    setUp(() {
      lines = [];
      original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          lines.add(message ?? '');
    });
    tearDown(() => debugPrint = original);

    test(
      'permission, system answer and ID are told as states; never the ID or its length',
      () async {
        final gateway = FakePushGateway();
        final service = PushNotificationService(gateway: gateway);
        await service.start();
        await service.requestPermission();
        final text = lines.join('\n');
        expect(lines, everyElement(startsWith('[PUSH] ')));
        expect(text, contains('Permission: notDetermined'));
        expect(text, contains('System prompt answered: granted'));
        expect(text, contains('Permission: granted'));
        expect(text, contains('Installation ID: yes'));
        expect(text, isNot(contains(fakeInstallationId)));
        expect(text, isNot(contains('${fakeInstallationId.length}')));
        await service.dispose();
      },
    );

    test('the provider gave nothing: the journal says "no"', () async {
      final gateway = FakePushGateway(authorized: true)..installationId = null;
      final service = PushNotificationService(gateway: gateway);
      await service.start();
      expect(lines.join('\n'), contains('Installation ID: no'));
      await service.dispose();
    });

    test(
      'the POST is told: attempted, then the HTTP code (204, 429) or the kind of error; no ID, no token',
      () async {
        final answers = <Object>[204, 429, 'network'];
        final api = DeviceRegistrationApi(
          authService: _TokenAuth(),
          client: MockClient((request) async {
            final next = answers.removeAt(0);
            if (next is int) return http.Response('', next);
            throw http.ClientException('offline');
          }),
        );
        for (var i = 0; i < 3; i++) {
          await api.register(fakeInstallationId, 'ios');
        }
        final text = lines.join('\n');
        expect(text, contains('POST devices attempted'));
        expect(text, contains('POST devices answered HTTP 204'));
        expect(text, contains('POST devices answered HTTP 429'));
        expect(text, contains('POST devices failed: ClientException'));
        expect(text, isNot(contains(fakeInstallationId)));
        expect(text, isNot(contains('test-token')));
        expect(
          utf8.decode(utf8.encode(text)),
          isNot(contains(fakeInstallationId)),
        );
      },
    );
  });
}
