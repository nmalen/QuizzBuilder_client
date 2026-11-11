/// Pure helpers for invitation codes and universal links.
library;

/// Host that serves the invitation links.
const String invitationLinkHost = 'play.quizzbuilder.fr';

/// Length of an invitation code ("become opponents").
const int invitationCodeLength = 6;

/// Length of a call code (live duel, handled by a later batch).
const int callCodeLength = 8;

/// Normalizes what a player typed or what a link carries: spaces and dashes
/// removed, upper case. The server reads codes the same way.
String normalizeInvitationCode(String raw) =>
    raw.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

/// True when [raw] normalizes to a complete invitation code.
bool isCompleteInvitationCode(String raw) =>
    normalizeInvitationCode(raw).length == invitationCodeLength;

/// A recognized `/d/<code>` link.
sealed class InvitationLink {
  const InvitationLink();
}

/// A 6-character invitation code: the "join" flow.
class JoinInvitationLink extends InvitationLink {
  final String code;
  const JoinInvitationLink(this.code);

  @override
  bool operator ==(Object other) =>
      other is JoinInvitationLink && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// An 8-character call code: reserved for the live duel batch.
class CallInvitationLink extends InvitationLink {
  final String code;
  const CallInvitationLink(this.code);

  @override
  bool operator ==(Object other) =>
      other is CallInvitationLink && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// Parses a link received by the app, cold or warm.
///
/// Accepts `/d/<code>` with or without a trailing slash, in any case, with or
/// without a dash inside the code, and with or without the scheme and host
/// (the engine may hand over only the path). A host, when present, must be
/// [invitationLinkHost]. Any other path returns null.
InvitationLink? parseInvitationUri(Uri uri) {
  if (uri.hasAuthority && uri.host.toLowerCase() != invitationLinkHost) {
    return null;
  }
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length != 2 || segments[0] != 'd') {
    return null;
  }
  final code = normalizeInvitationCode(segments[1]);
  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(code)) {
    return null;
  }
  return switch (code.length) {
    invitationCodeLength => JoinInvitationLink(code),
    callCodeLength => CallInvitationLink(code),
    _ => null,
  };
}

/// Same as [parseInvitationUri] for a raw route name or URL string.
InvitationLink? parseInvitationLocation(String location) {
  final uri = Uri.tryParse(location);
  return uri == null ? null : parseInvitationUri(uri);
}
