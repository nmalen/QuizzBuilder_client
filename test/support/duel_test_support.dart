import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/models/user.dart';
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/connectivity_provider.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/providers/invitation_link_provider.dart';
import 'package:QuizzBuilder/services/auth_service.dart';
import 'package:QuizzBuilder/services/duel_service.dart';

/// AuthService that never touches secure storage or the network.
class FakeAuthService extends AuthService {
  @override
  Future<Map<String, String>> getAuthHeaders() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer test-token',
  };

  @override
  Future<bool> refreshAccessToken() async => false;
}

/// AuthProvider with a fixed state (no storage, no network).
class FakeAuthProvider extends AuthProvider {
  FakeAuthProvider({
    this.loggedIn = true,
    this.initialized = true,
    this.userId = 7,
  }) : super(authService: FakeAuthService());

  bool loggedIn;
  bool initialized;
  final int userId;

  @override
  bool get isLoggedIn => loggedIn;

  @override
  bool get isInitialized => initialized;

  @override
  bool get isLoading => false;

  @override
  User? get user => loggedIn
      ? User(id: userId, username: 'tester', email: 'tester@example.test')
      : null;

  void setState({bool? loggedIn, bool? initialized}) {
    if (loggedIn != null) this.loggedIn = loggedIn;
    if (initialized != null) this.initialized = initialized;
    notifyListeners();
  }
}

class FakeConnectivity extends ChangeNotifier implements ConnectivityProvider {
  FakeConnectivity({bool online = true}) : _online = online;
  bool _online;

  @override
  bool get isOnline => _online;

  void setOnline(bool value) {
    _online = value;
    notifyListeners();
  }
}

/// A recorded request of the fake server.
class RecordedRequest {
  final String method;
  final String path;
  final String body;
  final String query;
  RecordedRequest(this.method, this.path, this.body, [this.query = '']);
  @override
  String toString() => '$method $path';
}

typedef Handler = http.Response Function(RecordedRequest request);

/// Fake duel server: every request goes to [handler] and is recorded.
class FakeDuelServer {
  FakeDuelServer(this.handler);
  Handler handler;
  final List<RecordedRequest> requests = [];

  MockClient get client => MockClient((request) async {
    final recorded = RecordedRequest(
      request.method,
      request.url.path,
      request.body,
      request.url.query,
    );
    requests.add(recorded);
    return handler(recorded);
  });

  DuelService get service =>
      DuelService(authService: FakeAuthService(), client: client);
}

http.Response jsonResponse(int status, Object? body) => http.Response(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response errorResponse(int status, String code) => jsonResponse(status, {
  'error': {'code': code, 'message': 'server text', 'status_code': status},
});

Map<String, Object?> invitationJson({
  String code = 'K7P3QX',
  String display = 'K7P-3QX',
}) => {
  'code': code,
  'code_display': display,
  'link': 'https://play.quizzbuilder.fr/d/$code',
  'created_at': '2026-11-12T10:00:00Z',
  'expires_at': '2026-11-13T10:00:00Z',
};

Map<String, Object?> opponentJson(int id, String username) => {
  'id': id,
  'username': username,
  'paired_at': '2026-11-12T10:00:00Z',
};

/// App shell for widget tests: providers + localized MaterialApp.
Widget duelApp({
  required Widget home,
  required DuelProvider duel,
  AuthProvider? auth,
  FakeConnectivity? connectivity,
  InvitationLinkProvider? links,
  String locale = 'en',
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<DuelProvider>.value(value: duel),
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth ?? FakeAuthProvider(),
      ),
      ChangeNotifierProvider<ConnectivityProvider>.value(
        value: connectivity ?? FakeConnectivity(),
      ),
      ChangeNotifierProvider<InvitationLinkProvider>.value(
        value: links ?? InvitationLinkProvider(),
      ),
    ],
    child: MaterialApp(
      navigatorKey: navigatorKey,
      locale: Locale(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}
