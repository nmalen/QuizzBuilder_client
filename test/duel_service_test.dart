import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:QuizzBuilder/services/api_exception.dart';

import 'support/duel_test_support.dart';

void main() {
  test('createInvitation: POST invitations/, parses the 201', () async {
    final server = FakeDuelServer(
      (r) => jsonResponse(201, invitationJson()),
    );
    final invitation = await server.service.createInvitation();
    expect(server.requests.single.method, 'POST');
    expect(server.requests.single.path, endsWith('/duel/invitations/'));
    expect(invitation.code, 'K7P3QX');
    expect(invitation.codeDisplay, 'K7P-3QX');
    expect(invitation.link, 'https://play.quizzbuilder.fr/d/K7P3QX');
    expect(invitation.expiresAt, isNotNull);
  });

  test('previewInvitation / acceptInvitation: normalized code in the path', () async {
    final server = FakeDuelServer((r) {
      if (r.method == 'GET') {
        return jsonResponse(200, {
          'inviter_username': 'alice',
          'expires_at': '2026-11-13T10:00:00Z',
        });
      }
      return jsonResponse(201, opponentJson(5, 'alice'));
    });
    final preview = await server.service.previewInvitation('k7p-3qx');
    final opponent = await server.service.acceptInvitation(' k7p 3qx');
    expect(preview.inviterUsername, 'alice');
    expect(opponent.id, 5);
    expect(server.requests[0].path, endsWith('/duel/invitations/K7P3QX/'));
    expect(
      server.requests[1].path,
      endsWith('/duel/invitations/K7P3QX/accept/'),
    );
  });

  test('routes and methods of the other calls', () async {
    final server = FakeDuelServer((r) {
      if (r.method == 'GET') {
        return jsonResponse(200, {'count': 0, 'results': []});
      }
      return jsonResponse(204, null);
    });
    final s = server.service;
    await s.listOpponents();
    await s.removeOpponent(3);
    await s.blockOpponent(4);
    await s.listInvitations();
    await s.cancelInvitation('k7p-3qx');
    await s.listBlocks();
    await s.unblock(9);
    final seen = server.requests.map((r) => '${r.method} ${r.path.split('/duel/').last}');
    expect(seen.toList(), [
      'GET opponents/',
      'DELETE opponents/3/',
      'POST opponents/4/block/',
      'GET invitations/',
      'DELETE invitations/K7P3QX/',
      'GET blocks/',
      'DELETE blocks/9/',
    ]);
  });

  test('an error envelope becomes an ApiException with its code', () async {
    final server = FakeDuelServer(
      (r) => errorResponse(409, 'active_invitation_limit_reached'),
    );
    await expectLater(
      server.service.createInvitation(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'active_invitation_limit_reached')
            .having((e) => e.statusCode, 'status', 409),
      ),
    );
  });

  test('a connection failure becomes a network ApiException', () async {
    for (final failure in <Object>[
      const SocketException('down'),
      http.ClientException('down'),
    ]) {
      final server = FakeDuelServer((r) => throw failure);
      await expectLater(
        server.service.listOpponents(),
        throwsA(
          isA<ApiException>().having((e) => e.isNetworkError, 'network', isTrue),
        ),
      );
    }
  });

  test('a malformed success body is an invalid_response error', () async {
    final server = FakeDuelServer((r) => jsonResponse(200, ['not', 'a', 'map']));
    await expectLater(
      server.service.listOpponents(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'invalid_response')),
    );
  });
}
