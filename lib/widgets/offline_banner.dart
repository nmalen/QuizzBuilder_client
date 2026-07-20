import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/connectivity_provider.dart';

/// Shows a persistent warning banner while the device is offline.
///
/// Renders nothing when online, so it can be dropped at the top of any
/// screen without affecting layout.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.select<ConnectivityProvider, bool>(
      (provider) => provider.isOnline,
    );

    if (isOnline) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD59E)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.wifi_off, color: Color(0xFF9A5B00)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.offlineBannerMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF7A4B00),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
