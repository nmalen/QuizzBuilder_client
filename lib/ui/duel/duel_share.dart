import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../models/duel.dart';
import 'duel_format.dart';

/// Opens the system share sheet with [text]. Replaceable in tests.
typedef InvitationShareFn = Future<void> Function(
  BuildContext context,
  String text,
);

/// Default sharer: the system share sheet (`share_plus`).
Future<void> shareInvitationText(BuildContext context, String text) {
  final box = context.findRenderObject() as RenderBox?;
  // iPad needs an anchor rectangle for the share popover.
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  return SharePlus.instance.share(
    ShareParams(text: text, sharePositionOrigin: origin),
  );
}

/// The message shared (and copied) for an invitation: link and code.
String invitationShareText(BuildContext context, Invitation invitation) {
  return AppLocalizations.of(context)!.duelShareMessage(
    invitation.link,
    invitation.codeDisplay,
    duelDateTime(context, invitation.expiresAt),
  );
}

/// Shares [invitation]; a failure of the share sheet shows the generic error.
Future<void> shareInvitation(
  BuildContext context,
  Invitation invitation, {
  InvitationShareFn? shareFn,
}) async {
  final text = invitationShareText(context, invitation);
  final messenger = ScaffoldMessenger.of(context);
  final generic = AppLocalizations.of(context)!.errorGenericTryAgain;
  try {
    await (shareFn ?? shareInvitationText)(context, text);
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(generic)));
  }
}

/// Copies the same message to the clipboard and says so.
Future<void> copyInvitation(BuildContext context, Invitation invitation) async {
  final text = invitationShareText(context, invitation);
  final messenger = ScaffoldMessenger.of(context);
  final copied = AppLocalizations.of(context)!.duelCopied;
  await Clipboard.setData(ClipboardData(text: text));
  messenger.showSnackBar(SnackBar(content: Text(copied)));
}
