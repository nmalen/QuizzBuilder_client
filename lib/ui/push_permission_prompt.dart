import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/push/push_gateway.dart';
import '../services/push/push_log.dart';
import '../services/push/push_notification_service.dart';
import '../services/push/push_prompt_state.dart';

/// The one-time "turn on notifications?" proposal, shown in context (after an
/// invitation is created or accepted) before the system prompt.
///
/// Shown at most once on this phone, whatever the answer: "Not now" and a
/// system refusal are never asked again. Nothing is shown when the permission
/// is already granted (Android 12 and older, which have no prompt, always are)
/// or can no longer be asked (refused earlier, provider unavailable).
class PushPromptController {
  PushPromptController({required this.service, PushPromptState? state})
    : _state = state ?? PushPromptState();

  final PushNotificationService service;
  final PushPromptState _state;
  bool _busy = false;

  /// Proposes once, if there is something to ask. Never throws.
  Future<void> propose(BuildContext context) async {
    if (_busy) return;
    _busy = true;
    try {
      if (await _state.wasProposed()) {
        pushLog('Prompt skipped: already proposed on this phone');
        return;
      }
      final permission = await service.permission();
      if (permission != PushPermission.notDetermined) {
        pushLog('Prompt skipped: permission ${permission.name}');
        return;
      }
      if (!context.mounted) return;
      pushLog('Prompt proposed');
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final l = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l.pushPromptTitle),
            content: Text(l.pushPromptBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l.pushPromptLater),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l.pushPromptTurnOn),
              ),
            ],
          );
        },
      );
      await _state.markProposed();
      pushLog('Prompt answered: ${accepted == true ? 'turn on' : 'later'}');
      if (accepted == true) await service.requestPermission();
    } catch (e) {
      pushLog('Prompt failed: ${e.runtimeType}');
    } finally {
      _busy = false;
    }
  }

  /// A player who signed up with an invitation code never sees the "join"
  /// screen: remember it, to propose on the home screen at the first sign-in.
  Future<void> markInviteePending() => _state.setInviteePending(true);

  /// On the home screen: proposes once to a player who signed up with a code.
  Future<void> proposeToInvitee(BuildContext context) async {
    try {
      if (!await _state.isInviteePending()) return;
      if (!context.mounted) return;
      await propose(context);
      await _state.setInviteePending(false);
    } catch (e) {
      pushLog('Invitee prompt failed: ${e.runtimeType}');
    }
  }
}

/// Makes the controller reachable from any screen. Absent (most tests): the
/// screens simply propose nothing.
class PushPromptScope extends InheritedWidget {
  const PushPromptScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final PushPromptController controller;

  static PushPromptController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PushPromptScope>()?.controller;

  @override
  bool updateShouldNotify(PushPromptScope oldWidget) =>
      controller != oldWidget.controller;
}
