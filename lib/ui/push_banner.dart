import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../l10n/app_localizations.dart';

/// What the banner's button does (and says).
enum PushBannerAction {
  /// "Join": opens the duel room.
  join,

  /// "View": opens the duel screen.
  view,
}

/// The in-app banner of a notification received while the app is open.
///
/// Shown at the top of the screen, on any screen, through the navigator's
/// overlay. One banner at a time (a new one replaces the previous). It goes
/// away by itself after [visibleFor], or with the close button; closing it
/// removes nothing from the lists. **Never shown while a live duel screen is
/// open** ([enterLive] / [leaveLive]).
class PushBannerController {
  PushBannerController({
    required this.navigatorKey,
    this.visibleFor = const Duration(seconds: 10),
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Duration visibleFor;

  OverlayEntry? _entry;
  Timer? _timer;
  int _live = 0;

  bool get isShowing => _entry != null;

  /// A live duel screen opened: no banner while it is there.
  void enterLive() {
    _live++;
    // Not now: this runs while the screen is being built.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_live > 0) hide();
    });
  }

  void leaveLive() {
    if (_live > 0) _live--;
  }

  /// Shows the banner. Returns false when it could not (live duel screen
  /// open, no navigator yet).
  bool show({
    required String? title,
    required String? body,
    required PushBannerAction action,
    required VoidCallback onAction,
  }) {
    if (_live > 0) return false;
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return false;
    hide();
    final entry = OverlayEntry(
      builder: (_) => _PushBanner(
        title: title,
        body: body,
        action: action,
        onAction: onAction,
        onClose: hide,
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(visibleFor, hide);
    return true;
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    if (entry == null) return;
    entry.remove();
    entry.dispose();
  }

  void dispose() => hide();
}

/// Makes the controller reachable from the live duel screen. Absent (most
/// tests): nothing to tell.
class PushBannerScope extends InheritedWidget {
  const PushBannerScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final PushBannerController controller;

  static PushBannerController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PushBannerScope>()?.controller;

  @override
  bool updateShouldNotify(PushBannerScope oldWidget) =>
      controller != oldWidget.controller;
}

class _PushBanner extends StatelessWidget {
  const _PushBanner({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
    required this.onClose,
  });

  final String? title;
  final String? body;
  final PushBannerAction action;
  final VoidCallback onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final label = action == PushBannerAction.join
        ? l.pushBannerJoin
        : l.pushBannerView;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Semantics(
            liveRegion: true,
            container: true,
            child: Material(
              key: const ValueKey('push-banner'),
              elevation: 8,
              borderRadius: BorderRadius.circular(14),
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (title != null && title!.trim().isNotEmpty)
                              Text(
                                title!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleSmall?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (body != null && body!.trim().isNotEmpty)
                              Text(
                                body!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('push-banner-action'),
                      onPressed: onAction,
                      child: Text(label),
                    ),
                    IconButton(
                      key: const ValueKey('push-banner-close'),
                      tooltip: l.pushBannerClose,
                      icon: Icon(Icons.close, color: scheme.onPrimaryContainer),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
