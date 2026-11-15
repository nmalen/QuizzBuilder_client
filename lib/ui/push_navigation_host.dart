import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/push/push_notification_service.dart';
import '../services/push/push_payload.dart';
import 'duel/duel_hub_screen.dart';
import 'duel/duel_live_screen.dart';
import 'push_permission_prompt.dart';

/// Starts [PushNotificationService] and opens what a tapped notification
/// points to, through the shared navigator.
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

class _PushNavigationHostState extends State<PushNavigationHost> {
  final List<PushDestination> _queue = [];
  late final AuthProvider _auth;
  StreamSubscription<PushDestination>? _sub;
  bool _scheduled = false;
  late final PushPromptController _prompt;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();
    _prompt = PushPromptController(service: widget.service);
    _auth.addListener(_process);
    // Listen first: a notification that started the app comes out of start().
    _sub = widget.service.destinations.listen((destination) {
      _queue.add(destination);
      _process();
    });
    unawaited(widget.service.start());
  }

  @override
  void dispose() {
    _auth.removeListener(_process);
    _sub?.cancel();
    super.dispose();
  }

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
  Widget build(BuildContext context) =>
      PushPromptScope(controller: _prompt, child: widget.child);
}
