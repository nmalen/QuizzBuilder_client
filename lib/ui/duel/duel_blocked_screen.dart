import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/duel.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/duel_provider.dart';
import 'duel_errors.dart';
import 'duel_format.dart';
import 'duel_widgets.dart';

/// Players I blocked, with "Unblock" (which does not recreate the pair).
class DuelBlockedScreen extends StatefulWidget {
  const DuelBlockedScreen({super.key});

  @override
  State<DuelBlockedScreen> createState() => _DuelBlockedScreenState();
}

class _DuelBlockedScreenState extends State<DuelBlockedScreen>
    with OnlineReloadMixin<DuelBlockedScreen> {
  List<BlockedPlayer>? _blocks;
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
      final loaded = await context.read<DuelProvider>().service.listBlocks();
      if (!mounted) return;
      setState(() {
        _blocks = loaded;
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

  Future<void> _unblock(BlockedPlayer player) async {
    final l = AppLocalizations.of(context)!;
    final service = context.read<DuelProvider>().service;
    final confirmed = await confirmDuelAction(
      context,
      title: l.duelUnblockTitle(player.username),
      body: l.duelUnblockBody(player.username),
      cancelLabel: l.cancel,
      confirmLabel: l.duelUnblock,
    );
    if (!confirmed || !mounted) return;
    try {
      await service.unblock(player.id);
      if (!mounted) return;
      setState(() {
        _blocks = _blocks?.where((b) => b.id != player.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.duelUnblocked(player.username))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(duelErrorMessage(l, e))));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final online = Provider.of<ConnectivityProvider>(context).isOnline;
    final blocks = _blocks;

    Widget body;
    if (!online && blocks == null) {
      body = DuelMessageCard(
        icon: Icons.wifi_off,
        message: l.duelOfflineListMessage,
      );
    } else if (_loading && blocks == null) {
      body = const DuelLoading();
    } else if (_error != null && blocks == null) {
      body = DuelMessageCard(
        message: duelErrorMessage(l, _error!),
        actionLabel: l.retry,
        onAction: _load,
      );
    } else if (blocks == null || blocks.isEmpty) {
      body = DuelMessageCard(message: l.duelNoBlocked);
    } else {
      body = Column(
        children: [
          for (final player in blocks) ...[
            DuelCard(
              child: Row(
                children: [
                  const DuelIconBadge(Icons.person),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.username,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.duelBlockedSince(duelDate(context, player.createdAt)),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: ValueKey('unblock-${player.id}'),
                    onPressed: online ? () => _unblock(player) : null,
                    child: Text(l.duelUnblock),
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
      title: l.duelBlockedTitle,
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
