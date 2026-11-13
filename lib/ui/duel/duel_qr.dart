import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/app_localizations.dart';

/// Side of the white square holding a QR code (dp): the code itself is 176 dp
/// and a white margin of 8 dp surrounds it.
const double duelQrSize = 192;

/// Longest text drawn as a QR code. The duel links are under 40 characters;
/// anything near this cap is not a duel link, and a code that dense would not
/// scan from a phone camera anyway. (`QrValidator` of `qr_flutter` 4.1.0 does
/// not refuse overlong text: measured valid up to 4000 characters.)
const int duelQrMaxChars = 500;

/// Whether [data] can be drawn as a QR code a camera can read (it always can
/// for the duel links).
bool duelQrCanEncode(String data) =>
    data.isNotEmpty &&
    data.length <= duelQrMaxChars &&
    QrValidator.validate(
          data: data,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        ).status ==
        QrValidationStatus.valid;

/// A QR code of [data] with its [caption], for the bottom of a card (below
/// the Share and Copy buttons): a thin line, the code, the caption.
///
/// Drawn locally, no network. Always black modules on a white square: an
/// inverted or tinted code does not scan. Nothing is drawn when [data] cannot
/// be encoded (the card stays complete without it).
class DuelQrCode extends StatelessWidget {
  final String data;
  final String caption;

  const DuelQrCode({super.key, required this.data, required this.caption});

  @override
  Widget build(BuildContext context) {
    if (!duelQrCanEncode(data)) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    return Column(
      // Stretch, so the code is centered whatever the parent's alignment.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Center(
          // A repaint boundary of its own: a test can capture the code alone.
          child: RepaintBoundary(
            key: const ValueKey('duel-qr-boundary'),
            child: QrImageView(
              key: const ValueKey('duel-qr'),
              data: data,
              size: duelQrSize,
              padding: const EdgeInsets.all(8),
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
              semanticsLabel: l.duelQrSemantics,
              errorStateBuilder: (context, error) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          caption,
          key: const ValueKey('duel-qr-caption'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
        ),
      ],
    );
  }
}
