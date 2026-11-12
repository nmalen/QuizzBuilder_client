import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/invitation_link_provider.dart';
import '../../utils/invitation_link.dart';
import 'duel_join_confirm_screen.dart';
import 'duel_live_screen.dart';

/// Receives universal links (`https://play.quizzbuilder.fr/d/<code>`), cold
/// or warm, and routes them:
///
/// - 6 characters: the invitation code is kept in [InvitationLinkProvider];
///   signed in, the "join" confirmation opens at once; signed out, the
///   authentication screen reads it (sign-up mode, code pre-filled) and, if
///   the player signs in instead, the confirmation opens after sign-in.
/// - 8 characters (call code of a live duel): the code is kept in
///   [InvitationLinkProvider]; signed in, the waiting room of that duel opens
///   at once (an unknown duel says so, then the duel hub); signed out, the
///   usual sign-in screen shows and the room opens after sign-in.
/// - any other path: ignored.
///
/// Must sit **above** the `MaterialApp`: that way it registers as a
/// [WidgetsBindingObserver] before the app's own route handling, and swallows
/// the route information (the app has no named routes to push).
class InvitationLinkHost extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  /// Route the platform started the app with (a link, for a cold start).
  final String? initialLocation;

  const InvitationLinkHost({
    super.key,
    required this.navigatorKey,
    required this.child,
    this.initialLocation,
  });

  @override
  State<InvitationLinkHost> createState() => _InvitationLinkHostState();
}

class _InvitationLinkHostState extends State<InvitationLinkHost>
    with WidgetsBindingObserver {
  final List<InvitationLink> _queue = [];
  late final AuthProvider _auth;
  late final InvitationLinkProvider _links;
  bool _opening = false;
  String? _lastCode;
  DateTime? _lastCodeAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth = context.read<AuthProvider>();
    _links = context.read<InvitationLinkProvider>();
    _auth.addListener(_process);
    final initial = widget.initialLocation;
    if (initial != null) {
      final link = parseInvitationLocation(initial);
      if (link != null) _queue.add(link);
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_process);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    final link = parseInvitationUri(routeInformation.uri);
    if (link != null) {
      _queue.add(link);
      _process();
    }
    // Always handled: the app has no named routes, an unknown route would
    // only raise an error in the Navigator.
    return true;
  }

  /// Decides what to do with queued links and the pending code. Waits for
  /// the authentication state to be known (cold start).
  void _process() {
    if (!mounted || !_auth.isInitialized || _auth.isLoading) return;

    while (_queue.isNotEmpty) {
      final link = _queue.removeAt(0);
      switch (link) {
        case JoinInvitationLink(:final code):
          // Some platforms deliver a cold-start link twice.
          final now = DateTime.now();
          final duplicate =
              _lastCode == code &&
              _lastCodeAt != null &&
              now.difference(_lastCodeAt!) < const Duration(seconds: 3);
          if (!duplicate) {
            _lastCode = code;
            _lastCodeAt = now;
            _links.setPendingCode(code);
          }
        case CallInvitationLink(:final code):
          final now = DateTime.now();
          final duplicate =
              _lastCode == code &&
              _lastCodeAt != null &&
              now.difference(_lastCodeAt!) < const Duration(seconds: 3);
          if (!duplicate) {
            _lastCode = code;
            _lastCodeAt = now;
            _links.setPendingCallCode(code);
          }
      }
    }

    if (!_auth.isLoggedIn) return;

    final code = _links.pendingCode;
    final callCode = _links.pendingCallCode;
    if (code == null && callCode == null) return;
    _links.clear();
    _links.clearCallCode();
    if (_opening) return;
    _opening = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _opening = false;
      final navigator = widget.navigatorKey.currentState;
      if (!mounted || navigator == null) return;
      if (callCode != null) {
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) =>
                DuelLiveScreen(joinCode: callCode, openHubWhenNotFound: true),
          ),
        );
      }
      if (code != null) {
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => DuelJoinConfirmScreen(code: code),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // A cold-start link queued in initState is processed once the first frame
    // is out and the authentication state is known (see _process).
    WidgetsBinding.instance.addPostFrameCallback((_) => _process());
    return widget.child;
  }
}
