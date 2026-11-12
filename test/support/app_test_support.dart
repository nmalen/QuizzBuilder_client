import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:QuizzBuilder/main.dart';
import 'package:QuizzBuilder/models/user.dart';
import 'package:QuizzBuilder/services/auth_service.dart';
import 'package:QuizzBuilder/models/theme.dart' as theme_model;
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/catalog_provider.dart';
import 'package:QuizzBuilder/providers/connectivity_provider.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/providers/invitation_link_provider.dart';
import 'package:QuizzBuilder/providers/language_provider.dart';
import 'package:QuizzBuilder/providers/quizz_builder_provider.dart';
import 'package:QuizzBuilder/ui/duel/invitation_link_host.dart';

import 'duel_test_support.dart';

/// Catalog provider that never touches the network or the local database.
class FakeCatalogProvider extends CatalogProvider {
  FakeCatalogProvider() : super(authService: FakeAuthService());

  @override
  Future<void> loadStatistics() async {}

  @override
  Future<void> syncOfflineContent({
    required bool Function(theme_model.Theme theme) isEntitled,
  }) async {}
}

/// Quiz builder provider with no storage and no network.
class FakeQuizzBuilderProvider extends QuizzBuilderProvider {
  FakeQuizzBuilderProvider() : super(authService: FakeAuthService());

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refreshThemeAccess() async {}
}

/// Auth provider whose state the test controls, including "loading" (the
/// splash screen). `initialize` and `refreshToken` do nothing.
class AppFakeAuthProvider extends FakeAuthProvider {
  AppFakeAuthProvider({super.loggedIn, super.initialized, this.loading = false});

  bool loading;
  int refreshTokenCalls = 0;

  @override
  bool get isLoading => loading;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> refreshToken() async {
    refreshTokenCalls++;
    return true;
  }

  void setLoading(bool value) {
    loading = value;
    notifyListeners();
  }
}

/// Everything `main()` wires around [MyApp], with fakes for the network.
class AppHarness {
  AppHarness({
    bool loggedIn = true,
    bool loading = false,
    this.initialLocation,
    FakeDuelServer? server,
    AuthProvider? authProvider,
  }) : _authProvider = authProvider,
       auth = AppFakeAuthProvider(loggedIn: loggedIn, loading: loading),
       server =
           server ??
           FakeDuelServer((r) => jsonResponse(200, {'count': 0, 'results': []}));

  final AppFakeAuthProvider auth;

  /// A real [AuthProvider] (over a scripted service) to use instead of
  /// [auth], for tests that need the real loading transitions.
  final AuthProvider? _authProvider;
  final String? initialLocation;
  final FakeDuelServer server;
  final FakeConnectivity connectivity = FakeConnectivity();
  final InvitationLinkProvider links = InvitationLinkProvider();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late final DuelProvider duel = DuelProvider(service: server.service);

  /// The widget tree of `main()`: providers, link host above [MyApp].
  Widget get app => MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>.value(value: LanguageProvider()),
      ChangeNotifierProvider<AuthProvider>.value(value: _authProvider ?? auth),
      ChangeNotifierProvider<ConnectivityProvider>.value(value: connectivity),
      ChangeNotifierProvider<CatalogProvider>.value(
        value: FakeCatalogProvider(),
      ),
      ChangeNotifierProvider<QuizzBuilderProvider>.value(
        value: FakeQuizzBuilderProvider(),
      ),
      ChangeNotifierProvider<DuelProvider>.value(value: duel),
      ChangeNotifierProvider<InvitationLinkProvider>.value(value: links),
    ],
    child: InvitationLinkHost(
      navigatorKey: navigatorKey,
      initialLocation: initialLocation,
      child: MyApp(navigatorKey: navigatorKey),
    ),
  );
}

/// Starts the app the way the platform does: the engine's initial route name
/// is [route] (what a universal link used for a cold start looks like).
void setInitialRoute(WidgetTester tester, String route) {
  tester.binding.platformDispatcher.defaultRouteNameTestValue = route;
  addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
}

/// An [AuthService] with no storage and no network, whose calls take the
/// time the test says (on the test clock: `pump` advances it).
class ScriptedAuthService extends AuthService {
  ScriptedAuthService({
    this.hasSession = false,
    this.initializeDelay = Duration.zero,
    this.refreshDelay = Duration.zero,
    this.refreshAccepted = true,
    this.loginDelay = Duration.zero,
    this.registerDelay = Duration.zero,
    this.logoutDelay = Duration.zero,
  });

  /// A session is stored on the device.
  bool hasSession;
  Duration initializeDelay;
  Duration refreshDelay;

  /// The server accepts the refresh token (false: it rejects it and the
  /// stored session is cleared, like the real service does).
  bool refreshAccepted;
  Duration loginDelay;
  Duration registerDelay;
  Duration logoutDelay;

  static final User user = User(
    id: 7,
    username: 'tester',
    email: 'tester@example.test',
  );

  @override
  Future<void> initialize() => Future<void>.delayed(initializeDelay);

  @override
  Future<bool> isLoggedIn() async => hasSession;

  @override
  Future<User?> getStoredUser() async => hasSession ? user : null;

  @override
  Future<bool> refreshAccessToken() async {
    await Future<void>.delayed(refreshDelay);
    if (!refreshAccepted) hasSession = false;
    return refreshAccepted;
  }

  @override
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    await Future<void>.delayed(loginDelay);
    hasSession = true;
    return {'success': true, 'user': user};
  }

  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password1,
    required String password2,
    String? invitationCode,
  }) async {
    await Future<void>.delayed(registerDelay);
    return {'success': true, 'message': 'Check your e-mail'};
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(logoutDelay);
    hasSession = false;
  }

  @override
  Future<Map<String, String>> getAuthHeaders() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer test-token',
  };
}
