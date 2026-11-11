import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/duel.dart';
import '../../providers/connectivity_provider.dart';
import '../../widgets/gradient_background.dart';

/// Scaffold shared by the duel screens: standard app bar, gradient body.
class DuelScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const DuelScaffold({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: GradientBackground(child: SafeArea(child: child)),
    );
  }
}

/// White rounded card, same look as the home screen cards.
class DuelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DuelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Round icon badge tinted with the primary color (as on the home cards).
class DuelIconBadge extends StatelessWidget {
  final IconData icon;
  const DuelIconBadge(this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

/// Tappable card: icon badge, title, optional subtitle, chevron. A null
/// [onTap] greys it out (offline).
class DuelActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const DuelActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: InkWell(
        onTap: onTap,
        child: DuelCard(
          child: Row(
            children: [
              DuelIconBadge(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card with a message and an optional action: offline, empty, error states.
class DuelMessageCard extends StatelessWidget {
  final IconData? icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DuelMessageCard({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return DuelCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 8),
          ],
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// White bold section title on the gradient.
class DuelSectionTitle extends StatelessWidget {
  final String text;
  const DuelSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

/// Centered white progress indicator for the gradient background.
class DuelLoading extends StatelessWidget {
  const DuelLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

/// Reloads a duel screen when the connection comes back.
mixin OnlineReloadMixin<T extends StatefulWidget> on State<T> {
  bool? _wasOnline;

  /// Called when connectivity goes from offline to online.
  void onBackOnline();

  bool get isOnline => _wasOnline ?? true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final online = Provider.of<ConnectivityProvider>(context).isOnline;
    final back = _wasOnline == false && online;
    _wasOnline = online;
    if (back) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) onBackOnline();
      });
    }
  }
}

/// Says "you are now opponents with …" once, for one or several new pairs.
void showNewOpponentsSnackBar(BuildContext context, List<Opponent> fresh) {
  if (fresh.isEmpty) return;
  final l = AppLocalizations.of(context)!;
  final message = fresh.length == 1
      ? l.duelNowOpponent(fresh.first.username)
      : l.duelNewOpponents(fresh.length);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Plain confirmation dialog: returns true when the player confirms.
Future<bool> confirmDuelAction(
  BuildContext context, {
  required String title,
  required String body,
  required String cancelLabel,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
