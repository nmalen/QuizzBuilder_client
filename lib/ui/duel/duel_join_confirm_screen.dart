import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/duel.dart';
import '../../providers/auth_provider.dart';
import '../../providers/duel_provider.dart';
import 'duel_errors.dart';
import 'duel_format.dart';
import 'duel_join_screen.dart';
import 'duel_widgets.dart';

/// "NAME challenges you: accept?" — the explicit confirmation before
/// becoming opponents. Pops with the new [Opponent] on success.
///
/// Reached with a [preview] from the typing screen, or with only a [code]
/// from a link: then the preview is loaded here, and a failure replaces this
/// screen with the typing screen showing the message.
class DuelJoinConfirmScreen extends StatefulWidget {
  final String code;
  final InvitationPreview? preview;

  const DuelJoinConfirmScreen({super.key, required this.code, this.preview});

  @override
  State<DuelJoinConfirmScreen> createState() => _DuelJoinConfirmScreenState();
}

class _DuelJoinConfirmScreenState extends State<DuelJoinConfirmScreen> {
  InvitationPreview? _preview;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _preview = widget.preview;
    if (_preview == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
    }
  }

  Future<void> _loadPreview() async {
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    try {
      final preview = await context
          .read<DuelProvider>()
          .service
          .previewInvitation(widget.code);
      if (!mounted) return;
      setState(() => _preview = preview);
    } catch (e) {
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => DuelJoinScreen(
            initialCode: widget.code,
            initialError: duelErrorMessage(l, e),
          ),
        ),
      );
    }
  }

  Future<void> _accept() async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final duel = context.read<DuelProvider>();
    final userId = context.read<AuthProvider>().user?.id;
    setState(() => _accepting = true);
    try {
      final opponent = await duel.acceptInvitation(widget.code, userId: userId);
      messenger.showSnackBar(
        SnackBar(content: Text(l.duelNowOpponent(opponent.username))),
      );
      if (mounted) navigator.pop(opponent);
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      messenger.showSnackBar(SnackBar(content: Text(duelErrorMessage(l, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final preview = _preview;
    return DuelScaffold(
      title: l.duelConfirmTitle,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (preview == null)
            const DuelLoading()
          else
            DuelCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: DuelIconBadge(Icons.person_add)),
                  const SizedBox(height: 12),
                  Text(
                    l.duelChallengesYou(preview.inviterUsername),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.duelAcceptBody(preview.inviterUsername),
                    textAlign: TextAlign.center,
                  ),
                  if (preview.expiresAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l.duelInvitationValidUntil(
                        duelDateTime(context, preview.expiresAt),
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _accepting ? null : _accept,
                    child: _accepting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.duelAccept),
                  ),
                  TextButton(
                    onPressed: _accepting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l.duelNotNow),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
