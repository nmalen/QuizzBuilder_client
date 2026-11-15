/// Where a tapped notification leads.
sealed class PushDestination {
  const PushDestination();
}

/// "X is waiting for you": the waiting room of that duel.
class DuelCallDestination extends PushDestination {
  const DuelCallDestination(this.duelId);
  final int duelId;
}

/// An invitation was accepted: the duel hub ("My opponents").
class InvitationAcceptedDestination extends PushDestination {
  const InvitationAcceptedDestination();
}

/// Unknown type or missing field: the home screen, no error.
class HomeDestination extends PushDestination {
  const HomeDestination();
}

/// Names of the notification data keys and values, **in one place**.
///
/// PROVISIONAL: the backend (QB-B-025) fixes the real contract; QB-C-021 only
/// has to change these constants.
abstract final class PushPayloadKeys {
  static const String type = 'type';
  static const String duelId = 'duel_id';
  static const String pairId = 'pair_id';

  static const String duelCall = 'duel_call';
  static const String invitationAccepted = 'invitation_accepted';
}

/// Reads the data of a tapped notification. Never throws: whatever is
/// unknown or incomplete leads to [HomeDestination].
PushDestination parsePushPayload(Map<String, Object?>? data) {
  if (data == null) return const HomeDestination();
  switch (data[PushPayloadKeys.type]?.toString()) {
    case PushPayloadKeys.duelCall:
      // FCM data values travel as strings.
      final duelId = int.tryParse('${data[PushPayloadKeys.duelId] ?? ''}');
      if (duelId == null || duelId <= 0) return const HomeDestination();
      return DuelCallDestination(duelId);
    case PushPayloadKeys.invitationAccepted:
      return const InvitationAcceptedDestination();
    default:
      return const HomeDestination();
  }
}
