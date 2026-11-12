import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/duel_live.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/duel_provider.dart';
import 'duel_errors.dart';
import 'duel_format.dart';
import 'duel_live_screen.dart' show duelResultStyle;
import 'duel_widgets.dart';

/// Short form of a result, for lists ("Win", "Loss by forfeit"...).
String duelOutcomeLabel(AppLocalizations l, DuelResultKind kind) =>
    switch (kind) {
      DuelResultKind.win => l.duelOutcomeWin,
      DuelResultKind.loss => l.duelOutcomeLoss,
      DuelResultKind.draw => l.duelOutcomeDraw,
      DuelResultKind.winByForfeit => l.duelOutcomeWinForfeit,
      DuelResultKind.lossByForfeit => l.duelOutcomeLossForfeit,
      DuelResultKind.none => l.duelOutcomeNone,
    };

/// My 20 most recent duels played. No review of the questions from here: the
/// API does not give them back.
class DuelHistoryScreen extends StatefulWidget {
  const DuelHistoryScreen({super.key});

  @override
  State<DuelHistoryScreen> createState() => _DuelHistoryScreenState();
}

class _DuelHistoryScreenState extends State<DuelHistoryScreen>
    with OnlineReloadMixin<DuelHistoryScreen> {
  List<DuelHistoryItem>? _items;
  bool _loading = true;
  Object? _error;

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
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<DuelProvider>().service.listHistory();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final online = Provider.of<ConnectivityProvider>(context).isOnline;

    final Widget body;
    if (!online) {
      body = DuelMessageCard(
        icon: Icons.wifi_off,
        message: l.duelOfflineListMessage,
      );
    } else if (_loading && _items == null) {
      body = const DuelLoading();
    } else if (_error != null && _items == null) {
      body = DuelMessageCard(
        message: duelLiveErrorMessage(l, _error!),
        actionLabel: l.retry,
        onAction: _load,
      );
    } else if (_items!.isEmpty) {
      body = DuelMessageCard(message: l.duelHistoryEmpty);
    } else {
      body = Column(
        children: [
          for (final item in _items!) ...[
            _HistoryRow(item: item),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    return DuelScaffold(
      title: l.duelHistoryTitle,
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

class _HistoryRow extends StatelessWidget {
  final DuelHistoryItem item;
  const _HistoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final kind = item.kind;
    final style = duelResultStyle(kind);
    final hasScores = item.myScore != null && item.opponentScore != null;
    final small = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]);

    return DuelCard(
      key: ValueKey('history-${item.id}'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(style.icon, color: style.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.opponentUsername,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  l.duelHistoryLine(
                    duelOutcomeLabel(l, kind),
                    item.questionCount,
                  ),
                  style: small,
                ),
                Text(
                  duelDate(context, item.closedAt ?? item.createdAt),
                  style: small,
                ),
              ],
            ),
          ),
          if (hasScores) ...[
            const SizedBox(width: 8),
            Text(
              '${item.myScore} – ${item.opponentScore}',
              key: ValueKey('history-score-${item.id}'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
