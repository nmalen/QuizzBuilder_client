import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/duel.dart';
import '../utils/invitation_link.dart';
import 'api_exception.dart';
import 'auth_service.dart';

/// Client of the duel API (`api/v1/duel/`), "find each other" part:
/// invitations, opponents and blocks. Requires a signed-in player; nothing
/// is cached.
///
/// Every failure is an [ApiException]: with the API's error `code` when the
/// server answered, or [ApiException.networkErrorCode] when it did not.
class DuelService {
  final AuthService authService;
  final http.Client _client;
  final String _base = '${ApiConfig.baseUrl}${ApiConfig.duelPrefix}';

  DuelService({required this.authService, http.Client? client})
    : _client = client ?? http.Client();

  // ---- Invitations ------------------------------------------------------

  /// Creates an invitation (at most 5 active at once).
  Future<Invitation> createInvitation() async {
    final response = await _send('POST', 'invitations/', expected: {201});
    return Invitation.fromJson(_object(response));
  }

  /// My active invitations, most recent first.
  Future<List<Invitation>> listInvitations() async {
    final response = await _send('GET', 'invitations/', expected: {200});
    return _results(response).map(Invitation.fromJson).toList(growable: false);
  }

  /// Cancels one of my active invitations.
  Future<void> cancelInvitation(String code) => _send(
    'DELETE',
    'invitations/${normalizeInvitationCode(code)}/',
    expected: {204},
  );

  /// Looks at an invitation before accepting it; consumes nothing.
  Future<InvitationPreview> previewInvitation(String code) async {
    final response = await _send(
      'GET',
      'invitations/${normalizeInvitationCode(code)}/',
      expected: {200},
    );
    return InvitationPreview.fromJson(_object(response));
  }

  /// Accepts an invitation; the returned [Opponent.id] is the pair id.
  Future<Opponent> acceptInvitation(String code) async {
    final response = await _send(
      'POST',
      'invitations/${normalizeInvitationCode(code)}/accept/',
      expected: {201},
    );
    return Opponent.fromJson(_object(response));
  }

  // ---- Opponents --------------------------------------------------------

  /// My opponents, most recent first.
  Future<List<Opponent>> listOpponents() async {
    final response = await _send('GET', 'opponents/', expected: {200});
    return _results(response).map(Opponent.fromJson).toList(growable: false);
  }

  /// Removes an opponent (by pair id).
  Future<void> removeOpponent(int pairId) =>
      _send('DELETE', 'opponents/$pairId/', expected: {204});

  /// Blocks an opponent (by pair id); this also removes the pair.
  Future<void> blockOpponent(int pairId) =>
      _send('POST', 'opponents/$pairId/block/', expected: {204});

  // ---- Blocks -----------------------------------------------------------

  /// The players I blocked.
  Future<List<BlockedPlayer>> listBlocks() async {
    final response = await _send('GET', 'blocks/', expected: {200});
    return _results(
      response,
    ).map(BlockedPlayer.fromJson).toList(growable: false);
  }

  /// Unblocks a player (by block id). Does not recreate the pair.
  Future<void> unblock(int blockId) =>
      _send('DELETE', 'blocks/$blockId/', expected: {204});

  // ---- Plumbing ---------------------------------------------------------

  Future<http.Response> _send(
    String method,
    String path, {
    required Set<int> expected,
  }) async {
    http.Response response;
    try {
      response = await _once(method, path);
      if (response.statusCode == 401 && await authService.refreshAccessToken()) {
        response = await _once(method, path);
      }
    } on TimeoutException {
      throw const ApiException.network('Connection timeout');
    } on SocketException {
      throw const ApiException.network('Cannot reach server');
    } on HandshakeException {
      throw const ApiException.network('Security certificate error');
    } on http.ClientException {
      throw const ApiException.network('Cannot reach server');
    }

    if (!expected.contains(response.statusCode)) {
      throw ApiException.fromResponse(response.statusCode, response.body);
    }
    return response;
  }

  Future<http.Response> _once(String method, String path) async {
    final request = http.Request(method, Uri.parse('$_base$path'))
      ..headers.addAll(await authService.getAuthHeaders());
    final streamed = await _client
        .send(request)
        .timeout(
          ApiConfig.connectionTimeout,
          onTimeout: () => throw TimeoutException('Connection timeout'),
        );
    return http.Response.fromStream(streamed);
  }

  static const ApiException _invalidResponse = ApiException(
    'Invalid response from server',
    code: 'invalid_response',
  );

  Map<String, dynamic> _object(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // Falls through to the typed error below.
    }
    throw _invalidResponse;
  }

  List<Map<String, dynamic>> _results(http.Response response) {
    final results = _object(response)['results'];
    if (results is List && results.every((e) => e is Map<String, dynamic>)) {
      return results.cast<Map<String, dynamic>>();
    }
    throw _invalidResponse;
  }
}
