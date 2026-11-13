import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/duel.dart';
import '../models/duel_live.dart';
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

  // ---- Live duel (batch 2) ----------------------------------------------
  //
  // Nothing returned here is cached: the questions of a duel in particular
  // live in memory only (decision J1) and never reach the theme cache.

  /// Themes playable against one opponent (by pair id): free ones plus those
  /// either player owns. Nothing says who owns what.
  Future<List<DuelTheme>> listThemes(int pairId) async {
    final response = await _send(
      'GET',
      'opponents/$pairId/themes/',
      expected: {200},
    );
    return _results(response).map(DuelTheme.fromJson).toList(growable: false);
  }

  /// Challenges an opponent. `duel_already_open` (409) carries the existing
  /// duel in [ApiException.details] (`duel`).
  Future<Duel> createDuel({
    required int pairId,
    required List<int> themeIds,
    required List<String> difficulties,
    required int questionCount,
    required int secondsPerQuestion,
  }) async {
    final response = await _send(
      'POST',
      'duels/',
      expected: {201},
      body: {
        'pair_id': pairId,
        'themes': themeIds,
        'difficulties': difficulties,
        'question_count': questionCount,
        'seconds_per_question': secondsPerQuestion,
      },
    );
    return Duel.fromJson(_object(response));
  }

  /// My open duels, with the server clock.
  Future<OpenDuelsPage> listOpenDuels() async {
    final response = await _send('GET', 'duels/', expected: {200});
    final body = _object(response);
    return OpenDuelsPage(
      serverTime: DateTime.tryParse('${body['server_time']}'),
      duels: _results(response).map(OpenDuel.fromJson).toList(growable: false),
    );
  }

  /// My 20 most recent duels played.
  Future<List<DuelHistoryItem>> listHistory() async {
    final response = await _send('GET', 'duels/history/', expected: {200});
    return _results(
      response,
    ).map(DuelHistoryItem.fromJson).toList(growable: false);
  }

  /// State of one duel. Also marks my presence while the room waits.
  Future<Duel> getDuel(int duelId) async {
    final response = await _send('GET', 'duels/$duelId/', expected: {200});
    return Duel.fromJson(_object(response));
  }

  /// Opens a duel from its call code (8 characters; case, dashes and spaces
  /// are ignored by the server and by [normalizeInvitationCode]).
  Future<Duel> joinDuel(String callCode) async {
    final response = await _send(
      'POST',
      'duels/join/${normalizeInvitationCode(callCode)}/',
      expected: {200},
    );
    return Duel.fromJson(_object(response));
  }

  /// Cancels a room that has not started (either player). Idempotent.
  Future<Duel> cancelDuel(int duelId) async {
    final response = await _send(
      'POST',
      'duels/$duelId/cancel/',
      expected: {200},
    );
    return Duel.fromJson(_object(response));
  }

  /// The frozen questions, once the start is fixed. Never keep them on disk.
  Future<DuelQuestions> getQuestions(int duelId) async {
    final response = await _send(
      'GET',
      'duels/$duelId/questions/',
      expected: {200},
    );
    try {
      return DuelQuestions.fromJson(_object(response));
    } on FormatException {
      throw _invalidResponse;
    } on TypeError {
      throw _invalidResponse;
    }
  }

  /// Sends my answers (1-4 or null per question), once. Sending the same list
  /// again is safe; a different one is refused (`answers_already_submitted`).
  Future<Duel> submitAnswers(int duelId, List<int?> answers) async {
    final response = await _send(
      'POST',
      'duels/$duelId/answers/',
      expected: {200},
      body: {'answers': answers},
    );
    return Duel.fromJson(_object(response));
  }

  // ---- Plumbing ---------------------------------------------------------

  Future<http.Response> _send(
    String method,
    String path, {
    required Set<int> expected,
    Map<String, Object?>? body,
  }) async {
    http.Response response;
    try {
      response = await _once(method, path, body);
      if (response.statusCode == 401 &&
          await authService.refreshAccessToken()) {
        response = await _once(method, path, body);
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

  Future<http.Response> _once(
    String method,
    String path,
    Map<String, Object?>? body,
  ) async {
    final request = http.Request(method, Uri.parse('$_base$path'))
      ..headers.addAll(await authService.getAuthHeaders());
    if (body != null) request.body = jsonEncode(body);
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
