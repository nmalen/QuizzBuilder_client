import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/duel_live.dart';
import '../../providers/duel_provider.dart';
import 'duel_format.dart';
import 'duel_hub_screen.dart';
import 'duel_live_screen.dart';
import 'duel_widgets.dart';

/// How an open duel reads in a list (hub) or a banner (home).
class OpenDuelText {
  final String title;
  final String subtitle;
  final IconData icon;
  const OpenDuelText(this.title, this.subtitle, this.icon);
}

/// Title, subtitle and icon for one open duel, as validated in the mock-ups.
OpenDuelText describeOpenDuel(
  BuildContext context,
  AppLocalizations l,
  OpenDuel duel,
) {
  final name = duel.opponentUsername;
  if (duel.status == DuelStatus.playing) {
    if (duel.mySubmitted == true) {
      return OpenDuelText(
        l.duelOpenAwaitingResult(name),
        l.duelOpenAwaitingResultSub,
        Icons.hourglass_top,
      );
    }
    return OpenDuelText(
      l.duelOpenPlaying(name),
      l.duelOpenPlayingSub,
      Icons.play_circle,
    );
  }
  if (duel.challengedByMe) {
    return OpenDuelText(
      l.duelOpenMyChallenge(name),
      l.duelOpenMyChallengeSub(duelTime(context, duel.roomExpiresAt)),
      Icons.hourglass_top,
    );
  }
  return OpenDuelText(
    l.duelOpenWaitingForMe(name),
    l.duelOpenWaitingForMeSub,
    Icons.notifications_active,
  );
}

/// Opens a duel by id, and re-checks the open duels when the player comes
/// back.
Future<void> openDuelScreen(BuildContext context, int duelId) async {
  final provider = context.read<DuelProvider>();
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => DuelLiveScreen(duelId: duelId)),
  );
  await provider.loadOpenDuels();
}

/// A row of the "Open duels" section of the hub.
class OpenDuelRow extends StatelessWidget {
  final OpenDuel duel;
  final bool enabled;
  const OpenDuelRow({super.key, required this.duel, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final text = describeOpenDuel(context, l, duel);
    return DuelActionCard(
      icon: text.icon,
      title: text.title,
      subtitle: text.subtitle,
      onTap: enabled ? () => openDuelScreen(context, duel.id) : null,
    );
  }
}

/// The "{name} is waiting for you" banner of the home screen (decision H2).
/// Shows nothing when there is nothing to do.
class DuelBanner extends StatelessWidget {
  const DuelBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final duels = context.watch<DuelProvider>().bannerDuels;
    if (duels.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;

    final String title;
    final String subtitle;
    final IconData icon;
    final VoidCallback onTap;
    if (duels.length > 1) {
      title = l.duelBannerMany(duels.length);
      subtitle = l.duelBannerManySub;
      icon = Icons.notifications_active;
      onTap = () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const DuelHubScreen()));
    } else {
      final duel = duels.first;
      final playing = duel.status == DuelStatus.playing;
      title = playing
          ? l.duelBannerPlaying(duel.opponentUsername)
          : l.duelBannerWaiting(duel.opponentUsername);
      subtitle = playing ? l.duelBannerPlayingSub : l.duelBannerWaitingSub;
      icon = playing ? Icons.play_circle : Icons.notifications_active;
      onTap = () => openDuelScreen(context, duel.id);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DuelActionCard(
        key: const ValueKey('duel-banner'),
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }
}
