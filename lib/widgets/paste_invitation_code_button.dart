import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../utils/invitation_link.dart';

/// "Paste" button of the invitation code fields: reads the clipboard and
/// hands over the invitation code found there (a code alone, or a text with a
/// `play.quizzbuilder.fr/d/<code>` link; see [invitationCodeFromPastedText]).
///
/// Nothing usable (empty clipboard, any other text, the link of a live duel
/// call) ⇒ a message, and the field is left as it is. On iOS the system asks
/// "Allow Paste" whenever the copied content changes; a refusal reads as an
/// empty clipboard, so the same message shows.
class PasteInvitationCodeButton extends StatelessWidget {
  const PasteInvitationCodeButton({
    super.key,
    required this.onCode,
    this.enabled = true,
    this.color,
  });

  /// Receives the normalized 6-character code.
  final ValueChanged<String> onCode;
  final bool enabled;
  final Color? color;

  Future<void> _paste(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context)!.noInvitationCodeInClipboard;
    String? text;
    try {
      text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    } catch (_) {
      text = null;
    }
    final code = invitationCodeFromPastedText(text);
    if (code == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    onCode(code);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('paste-invitation-code'),
      tooltip: AppLocalizations.of(context)!.pasteInvitationCode,
      icon: Icon(Icons.content_paste, color: color),
      onPressed: enabled ? () => _paste(context) : null,
    );
  }
}
