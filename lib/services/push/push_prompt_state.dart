import 'package:shared_preferences/shared_preferences.dart';

/// What the app remembers, on this phone only, about the one-time
/// "turn on notifications?" proposal.
class PushPromptState {
  static const String proposedKey = 'push_prompt_proposed';
  static const String inviteePendingKey = 'push_prompt_invitee_pending';

  /// The proposal was shown (accepted or not): it is never shown again.
  Future<bool> wasProposed() async =>
      (await SharedPreferences.getInstance()).getBool(proposedKey) ?? false;

  Future<void> markProposed() async =>
      (await SharedPreferences.getInstance()).setBool(proposedKey, true);

  /// The player signed up with an invitation code: the proposal is due on the
  /// home screen at the first sign-in (they never see the "join" screen).
  Future<bool> isInviteePending() async =>
      (await SharedPreferences.getInstance()).getBool(inviteePendingKey) ??
      false;

  Future<void> setInviteePending(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(inviteePendingKey, true);
    } else {
      await prefs.remove(inviteePendingKey);
    }
  }
}
