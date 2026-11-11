// Data classes for the duel "find each other" API (`api/v1/duel/`).
//
// Hand-written (no code generation): the payloads are tiny and stable.

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

/// An invitation created by the current player.
class Invitation {
  /// Normalized 6-character code (e.g. `K7P3QX`).
  final String code;

  /// Display form of the code (e.g. `K7P-3QX`).
  final String codeDisplay;

  /// Universal link (`https://play.quizzbuilder.fr/d/<code>`).
  final String link;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const Invitation({
    required this.code,
    required this.codeDisplay,
    required this.link,
    this.createdAt,
    this.expiresAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
    code: json['code'] as String,
    codeDisplay: (json['code_display'] as String?) ?? json['code'] as String,
    link: json['link'] as String,
    createdAt: _parseDate(json['created_at']),
    expiresAt: _parseDate(json['expires_at']),
  );
}

/// What a player sees before accepting an invitation.
class InvitationPreview {
  final String inviterUsername;
  final DateTime? expiresAt;

  const InvitationPreview({required this.inviterUsername, this.expiresAt});

  factory InvitationPreview.fromJson(Map<String, dynamic> json) =>
      InvitationPreview(
        inviterUsername: json['inviter_username'] as String,
        expiresAt: _parseDate(json['expires_at']),
      );
}

/// An opponent. [id] is the identifier of the **pair**, never of the account.
class Opponent {
  final int id;
  final String username;
  final DateTime? pairedAt;

  const Opponent({required this.id, required this.username, this.pairedAt});

  factory Opponent.fromJson(Map<String, dynamic> json) => Opponent(
    id: json['id'] as int,
    username: json['username'] as String,
    pairedAt: _parseDate(json['paired_at']),
  );
}

/// A blocked player. [id] is the identifier of the **block**.
class BlockedPlayer {
  final int id;
  final String username;
  final DateTime? createdAt;

  const BlockedPlayer({
    required this.id,
    required this.username,
    this.createdAt,
  });

  factory BlockedPlayer.fromJson(Map<String, dynamic> json) => BlockedPlayer(
    id: json['id'] as int,
    username: json['username'] as String,
    createdAt: _parseDate(json['created_at']),
  );
}
