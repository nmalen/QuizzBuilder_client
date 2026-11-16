import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/duel_provider.dart';
import '../services/push/push_gateway.dart';
import '../services/push/push_log.dart';
import '../services/push/push_notification_service.dart';
import '../services/push/push_payload.dart';
import 'duel/duel_hub_screen.dart';
import 'duel/duel_live_screen.dart';
import 'push_banner.dart';
import 'push_permission_prompt.dart';

/// Starts [PushNotificationService] and opens what a tapped notification
/// points to, through the shared navigator.
///
/// A notification received while the app is open refreshes the open duels
/// (or the opponents) and, when it carries a `notification` block, shows a
/// banner whose button leads where a tap on the notification would.
///
/// Waits for the authentication state to be known (cold start). Signed out,
/// there is nothing to open: the notification is dropped and the usual sign-in
/// screen shows.
class PushNavigationHost extends StatefulWidget {
  const PushNavigationHost({
    super.key,
    required this.service,
    required this.navigatorKey,
    required this.child,
  });

  final PushNotificationService service;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<PushNavigationHost> createState() => _PushNavigationHostState();
}

class _PushNavigationHostState extends State<PushNavigationHost>
    with WidgetsBindingObserver {
  final List<PushDestination> _queue = [];
  late final AuthProvider _auth;
  StreamSubscription<PushDestination>? _sub;
  StreamSubscription<PushMessage>? _foregroundSub;
  bool _scheduled = false;
  late final PushPromptController _prompt;
  late final PushBannerController _banner;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();
    _prompt = PushPromptController(service: widget.service);
    _banner = PushBannerController(navigatorKey: widget.navigatorKey);
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_process);
    // Listen first: a notification that started the app comes out of start().
    _sub = widget.service.destinations.listen((destination) {
      _queue.add(destination);
      _process();
    });
    _foregroundSub = widget.service.foregroundMessages.listen(_onForeground);
    unawaited(widget.service.start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.removeListener(_process);
    _sub?.cancel();
    _foregroundSub?.cancel();
    _banner.dispose();
    super.dispose();
  }

  /// Back in the foreground: ask the provider again if notifications are
  /// allowed but no ID is known yet (the player may have allowed them in the
  /// phone settings, or the provider did not answer in time earlier).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.service.installationId == null) {
      unawaited(widget.service.refreshInstallationId());
    }
  }

  /// A notification received while the app is open.
  void _onForeground(PushMessage message) {
    if (!mounted || !_auth.isInitialized || !_auth.isLoggedIn) return;
    final destination = parsePushPayload(message.data);
    final duel = context.read<DuelProvider>();
    final userId = _auth.user?.id;
    final PushBannerAction? action;
    switch (destination) {
      case DuelCallDestination():
        unawaited(duel.loadOpenDuels());
        action = PushBannerAction.join;
      case InvitationAcceptedDestination():
        unawaited(duel.loadOpponents(userId: userId));
        action = PushBannerAction.view;
      case HomeDestination():
        unawaited(duel.loadOpenDuels());
        unawaited(duel.loadOpponents(userId: userId));
        action = null;
    }
    var shown = false;
    if (action != null && message.hasNotificationBlock) {
      shown = _banner.show(
        title: message.title,
        body: message.body,
        action: action,
        onAction: () {
          _banner.hide();
          final navigator = widget.navigatorKey.currentState;
          if (navigator != null) _open(navigator, destination);
        },
      );
    }
    pushLog(
      'Foreground message: ${_kindOf(destination)}, '
      'banner ${shown ? 'shown' : 'not shown'}',
    );
  }

  String _kindOf(PushDestination destination) => switch (destination) {
    DuelCallDestination() => PushPayloadKeys.duelCall,
    InvitationAcceptedDestination() => PushPayloadKeys.invitationAccepted,
    HomeDestination() => 'other',
  };

  void _process() {
    if (!mounted || _queue.isEmpty) return;
    if (!_auth.isInitialized || _auth.isLoading) return;
    if (!_auth.isLoggedIn) {
      _queue.clear();
      return;
    }
    if (_scheduled) return;
    _scheduled = true;
    // A post-frame callback alone schedules no frame: an idle app would keep
    // the tap waiting until something else redraws.
    WidgetsBinding.instance.ensureVisualUpdate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final navigator = widget.navigatorKey.currentState;
      if (!mounted || navigator == null) {
        // The navigator is not there yet: try again on the next frame.
        if (mounted && _queue.isNotEmpty) _process();
        return;
      }
      final pending = List<PushDestination>.of(_queue);
      _queue.clear();
      for (final destination in pending) {
        _open(navigator, destination);
      }
    });
  }

  void _open(NavigatorState navigator, PushDestination destination) {
    switch (destination) {
      case DuelCallDestination(:final duelId):
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => DuelLiveScreen(duelId: duelId),
          ),
        );
      case InvitationAcceptedDestination():
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const DuelHubScreen()),
        );
      case HomeDestination():
        navigator.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) => PushPromptScope(
    controller: _prompt,
    child: PushBannerScope(controller: _banner, child: widget.child),
  );
}
