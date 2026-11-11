import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/duel.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/duel_provider.dart';
import '../../services/api_exception.dart';
import 'duel_errors.dart';
import 'duel_format.dart';
import 'duel_invitations_screen.dart';
import 'duel_share.dart';
import 'duel_widgets.dart';

/// Creates an invitation on opening and shows its code, with Share and Copy.
/// Opening it again creates a new invitation (visible in "My invitations").
class DuelInviteScreen extends StatefulWidget {
  /// Replaces the system share sheet (tests).
  final InvitationShareFn? shareFn;

  const DuelInviteScreen({super.key, this.shareFn});

  @override
  State<DuelInviteScreen> createState() => _DuelInviteScreenState();
}

class _DuelInviteScreenState extends State<DuelInviteScreen>
    with OnlineReloadMixin<DuelInviteScreen> {
  Invitation? _invitation;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _create());
  }

  @override
  void onBackOnline() {
    if (_invitation == null) _create();
  }

  Future<void> _create() async {
    if (!mounted || _loading) return;
    if (!Provider.of<ConnectivityProvider>(context, listen: false).isOnline) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invitation = await context
          .read<DuelProvider>()
          .service
          .createInvitation();
      if (!mounted) return;
      setState(() {
        _invitation = invitation;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _openInvitations() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DuelInvitationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final online = Provider.of<ConnectivityProvider>(context).isOnline;

    return DuelScaffold(
      title: l.duelInviteTitle,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_invitation != null)
            _codeCard(context, l, _invitation!)
          else if (_loading)
            const DuelLoading()
          else if (!online)
            DuelMessageCard(
              icon: Icons.wifi_off,
              message: l.duelInviteOfflineMessage,
            )
          else if (_error is ApiException &&
              (_error as ApiException).code ==
                  DuelErrorCodes.activeInvitationLimitReached)
            DuelMessageCard(
              message: duelErrorMessage(l, _error!),
              actionLabel: l.duelMyInvitations,
              onAction: _openInvitations,
            )
          else if (_error != null)
            DuelMessageCard(
              message: duelErrorMessage(l, _error!),
              actionLabel: l.retry,
              onAction: _create,
            ),
          if (_invitation != null) ...[
            const SizedBox(height: 16),
            Text(
              l.duelInviteHelp,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _openInvitations,
                child: Text(
                  l.duelSeeMyInvitations,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _codeCard(BuildContext context, AppLocalizations l, Invitation inv) {
    return DuelCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(l.duelInviteCodeLabel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Text(
            inv.codeDisplay,
            key: const Key('invitation-code'),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(l.duelInviteValidUntil(duelDateTime(context, inv.expiresAt))),
          Text(
            l.duelInviteSingleUse,
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (shareContext) => ElevatedButton.icon(
                    onPressed: () => shareInvitation(
                      shareContext,
                      inv,
                      shareFn: widget.shareFn,
                    ),
                    icon: const Icon(Icons.share),
                    label: Text(l.duelShare),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => copyInvitation(context, inv),
                  icon: const Icon(Icons.copy),
                  label: Text(l.duelCopy),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
