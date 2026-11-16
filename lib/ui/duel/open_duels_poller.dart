import 'dart:async';

import 'package:flutter/widgets.dart';

/// A light refresh of the open duels while the app is in the foreground and
/// a screen that shows them (home, duel hub) is the one on top.
///
/// Every [every], if [isActive] says so, [refresh] runs once (never two at
/// once). The timer stops as soon as the app leaves the foreground and starts
/// again when it comes back; [dispose] stops it for good. [isActive] is where
/// the screen says "I am visible, online and signed in".
class OpenDuelsPoller with WidgetsBindingObserver {
  OpenDuelsPoller({
    required this.isActive,
    required this.refresh,
    this.every = const Duration(seconds: 20),
  });

  /// About 3 requests a minute: far under the server limits (see the CR of
  /// QB-C-024).
  static const Duration defaultEvery = Duration(seconds: 20);

  final bool Function() isActive;
  final Future<void> Function() refresh;
  final Duration every;

  Timer? _timer;
  bool _busy = false;
  bool _disposed = false;

  bool get isRunning => _timer != null;

  void start() {
    if (_disposed) return;
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) _arm();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _arm();
    } else {
      _disarm();
    }
  }

  void _arm() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => unawaited(_tick()));
  }

  void _disarm() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_busy || _disposed || !isActive()) return;
    _busy = true;
    try {
      await refresh();
    } catch (_) {
      // Silent: the next tick tries again.
    } finally {
      _busy = false;
    }
  }

  void dispose() {
    _disposed = true;
    _disarm();
    WidgetsBinding.instance.removeObserver(this);
  }
}
