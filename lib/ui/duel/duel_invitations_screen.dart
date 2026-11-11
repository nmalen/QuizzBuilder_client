import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/duel.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/duel_provider.dart';
import 'duel_errors.dart';
import 'duel_format.dart';
import 'duel_invite_screen.dart';
import 'duel_share.dart';
import 'duel_widgets.dart';

/// My active invitations: share again, or cancel.
class DuelInvitationsScreen extends StatefulWidget {
  /// Replaces the system share sheet (tests).
  final InvitationShareFn? shareFn;

  const DuelInvitationsScreen({super.key, this.shareFn});

  @override
  State<DuelInvitationsScreen> createState() => _DuelInvitationsScreenState();
}

class _DuelInvitationsScreenState extends State<DuelInvitationsScreen>
    with OnlineReloadMixin<DuelInvitationsScreen> {
  List<Invitation>? _invitations;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void onBackOnline() => _load();

  Future<void> _load() async {
    if (!mounted) return;
    if (!Provider.of<ConnectivityProvider>(context, listen: false).isOnline) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loaded = await context
          .read<DuelProvider>()
          .service
          .listInvitations();
      if (!mounted) return;
      setState(() {
        _invitations = loaded;
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

  Future<void> _cancel(Invitation invitation) async {
    final l = AppLocalizations.of(context)!;
    final service = context.read<DuelProvider>().service;
    final confirmed = await confirmDuelAction(
      context,
      title: l.duelCancelInvitationTitle,
      body: l.duelCancelInvitationBody(invitation.codeDisplay),
      cancelLabel: l.duelBack,
      confirmLabel: l.duelCancelInvitationAction,
    );
    if (!confirmed || !mounted) return;
    try {
      await service.cancelInvitation(invitation.code);
      if (!mounted) return;
      setState(() {
        _invitations = _invitations
            ?.where((i) => i.code != invitation.code)
            .toList();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.duelInvitationCancelled)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(duelErrorMessage(l, e))));
      // The code is gone or unknown: refresh what the server says.
      _load();
    }
  }

  Future<void> _invite() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DuelInviteScreen(shareFn: widget.shareFn)),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final online = Provider.of<ConnectivityProvider>(context).isOnline;
    final invitations = _invitations;

    Widget body;
    if (!online && invitations == null) {
      body = DuelMessageCard(
        icon: Icons.wifi_off,
        message: l.duelOfflineListMessage,
      );
    } else if (_loading && invitations == null) {
      body = const DuelLoading();
    } else if (_error != null && invitations == null) {
      body = DuelMessageCard(
        message: duelErrorMessage(l, _error!),
        actionLabel: l.retry,
        onAction: _load,
      );
    } else if (invitations == null || invitations.isEmpty) {
      body = DuelMessageCard(
        message: l.duelNoInvitations,
        actionLabel: l.duelInviteTitle,
        onAction: online ? _invite : null,
      );
    } else {
      body = Column(
        children: [
          for (final invitation in invitations) ...[
            DuelCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invitation.codeDisplay,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.duelInvitationExpires(
                            duelDateTime(context, invitation.expiresAt),
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (shareContext) => IconButton(
                      tooltip: l.duelShare,
                      icon: const Icon(Icons.share),
                      onPressed: () => shareInvitation(
                        shareContext,
                        invitation,
                        shareFn: widget.shareFn,
                      ),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('cancel-${invitation.code}'),
                    tooltip: l.duelCancelInvitationAction,
                    icon: const Icon(Icons.close),
                    onPressed: online ? () => _cancel(invitation) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    return DuelScaffold(
      title: l.duelMyInvitationsTitle,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [body],
        ),
      ),
    );
  }
}
