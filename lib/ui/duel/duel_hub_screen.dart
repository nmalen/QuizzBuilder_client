import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/duel.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/duel_provider.dart';
import '../../services/api_exception.dart';
import 'duel_blocked_screen.dart';
import 'duel_challenge_screen.dart';
import 'duel_errors.dart';
import 'duel_format.dart';
import 'duel_history_screen.dart';
import 'duel_invitations_screen.dart';
import 'duel_invite_screen.dart';
import 'duel_join_screen.dart';
import 'duel_open_widgets.dart';
import 'duel_widgets.dart';

enum _OpponentAction { remove, block }

/// Entry of the duel: my opponents, invite, join, invitations, blocks.
/// Needs a connection: offline it says so and shows nothing cached.
class DuelHubScreen extends StatefulWidget {
  const DuelHubScreen({super.key});

  @override
  State<DuelHubScreen> createState() => _DuelHubScreenState();
}

class _DuelHubScreenState extends State<DuelHubScreen>
    with OnlineReloadMixin<DuelHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void onBackOnline() => _load();

  int? get _userId => context.read<AuthProvider>().user?.id;

  Future<void> _load() async {
    if (!mounted) return;
    if (!Provider.of<ConnectivityProvider>(context, listen: false).isOnline) {
      return;
    }
    final duel = context.read<DuelProvider>();
    await Future.wait([
      duel.loadOpponents(userId: _userId),
      duel.loadOpenDuels(),
    ]);
    if (!mounted) return;
    showNewOpponentsSnackBar(context, duel.takeAnnouncement());
  }

  void _showError(Object error) {
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(duelErrorMessage(l, error))));
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load();
  }

  Future<void> _onAction(_OpponentAction action, Opponent opponent) async {
    final l = AppLocalizations.of(context)!;
    final duel = context.read<DuelProvider>();
    final remove = action == _OpponentAction.remove;
    final confirmed = await confirmDuelAction(
      context,
      title: remove
          ? l.duelRemoveTitle(opponent.username)
          : l.duelBlockTitle(opponent.username),
      body: remove
          ? l.duelRemoveBody(opponent.username)
          : l.duelBlockBody(opponent.username),
      cancelLabel: l.cancel,
      confirmLabel: remove ? l.duelRemoveAction : l.duelBlockAction,
    );
    if (!confirmed || !mounted) return;

    try {
      if (remove) {
        await duel.removeOpponent(opponent.id);
      } else {
        await duel.blockOpponent(opponent.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remove
                ? l.duelRemoved(opponent.username)
                : l.duelBlocked(opponent.username),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
      if (e is ApiException && e.code == DuelErrorCodes.opponentNotFound) {
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final online = Provider.of<ConnectivityProvider>(context).isOnline;
    final duel = context.watch<DuelProvider>();

    return DuelScaffold(
      title: l.duelHubTitle,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (online && duel.openDuels.isNotEmpty) ...[
              DuelSectionTitle(l.duelOpenSection(duel.openDuels.length)),
              const SizedBox(height: 8),
              for (final open in duel.openDuels) ...[
                OpenDuelRow(duel: open),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
            ],
            DuelActionCard(
              icon: Icons.person_add,
              title: l.duelInviteTitle,
              subtitle: l.duelInviteSubtitle,
              onTap: online ? () => _push(const DuelInviteScreen()) : null,
            ),
            const SizedBox(height: 10),
            DuelActionCard(
              icon: Icons.pin,
              title: l.duelJoinTitle,
              subtitle: l.duelJoinSubtitle,
              onTap: online ? () => _push(const DuelJoinScreen()) : null,
            ),
            const SizedBox(height: 20),
            if (!online)
              DuelMessageCard(
                icon: Icons.wifi_off,
                message: l.duelOfflineMessage,
              )
            else ...[
              DuelSectionTitle(l.duelOpponentsSection(duel.opponents.length)),
              const SizedBox(height: 8),
              _opponents(context, duel, l),
            ],
            const SizedBox(height: 20),
            DuelActionCard(
              icon: Icons.history,
              title: l.duelHistoryTitle,
              onTap: online ? () => _push(const DuelHistoryScreen()) : null,
            ),
            const SizedBox(height: 10),
            DuelActionCard(
              icon: Icons.mail_outline,
              title: l.duelMyInvitations,
              onTap: online ? () => _push(const DuelInvitationsScreen()) : null,
            ),
            const SizedBox(height: 10),
            DuelActionCard(
              icon: Icons.block,
              title: l.duelBlockedPlayers,
              onTap: online ? () => _push(const DuelBlockedScreen()) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _opponents(
    BuildContext context,
    DuelProvider duel,
    AppLocalizations l,
  ) {
    if (duel.isLoading && duel.opponents.isEmpty) {
      return const DuelLoading();
    }
    if (duel.error != null && duel.opponents.isEmpty) {
      return DuelMessageCard(
        message: duelErrorMessage(l, duel.error!),
        actionLabel: l.retry,
        onAction: _load,
      );
    }
    if (duel.opponents.isEmpty) {
      return DuelMessageCard(message: l.duelNoOpponents);
    }
    return Column(
      children: [
        for (final opponent in duel.opponents) ...[
          DuelCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const DuelIconBadge(Icons.person),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opponent.username,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.duelOpponentSince(
                              duelDate(context, opponent.pairedAt),
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<_OpponentAction>(
                      key: ValueKey('opponent-menu-${opponent.id}'),
                      onSelected: (action) => _onAction(action, opponent),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: _OpponentAction.remove,
                          child: Text(l.duelMenuRemove),
                        ),
                        PopupMenuItem(
                          value: _OpponentAction.block,
                          child: Text(l.duelMenuBlock),
                        ),
                      ],
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: _challengeButton(context, duel, opponent, l),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// "Challenge", or "Open" when a duel is already open with this opponent.
  Widget _challengeButton(
    BuildContext context,
    DuelProvider duel,
    Opponent opponent,
    AppLocalizations l,
  ) {
    final open = duel.openDuelForPair(opponent.id);
    return ElevatedButton.icon(
      key: ValueKey('challenge-${opponent.id}'),
      onPressed: open != null
          ? () => openDuelScreen(context, open.id)
          : () => _push(DuelChallengeScreen(opponent: opponent)),
      icon: Icon(open != null ? Icons.open_in_new : Icons.bolt, size: 18),
      label: Text(open != null ? l.duelOpenAction : l.duelChallengeAction),
    );
  }
}
