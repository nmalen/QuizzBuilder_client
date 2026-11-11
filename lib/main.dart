import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/duel_provider.dart';
import 'providers/invitation_link_provider.dart';
import 'providers/quizz_builder_provider.dart';
import 'providers/language_provider.dart';
import 'services/auth_service.dart';
import 'services/duel_service.dart';
import 'ui/splash_screen.dart';
import 'ui/auth_screen.dart';
import 'ui/duel/invitation_link_host.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize AuthService and LanguageProvider
  final authService = AuthService();
  await authService.initialize();
  
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();
  
  final navigatorKey = GlobalKey<NavigatorState>();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: languageProvider,
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => ConnectivityProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CatalogProvider(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => QuizzBuilderProvider(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => DuelProvider(
            service: DuelService(authService: authService),
          ),
        ),
        ChangeNotifierProvider(create: (_) => InvitationLinkProvider()),
      ],
      // Universal links (/d/<code>): the host sits above MaterialApp so it
      // sees the route information before the app's own route handling.
      child: InvitationLinkHost(
        navigatorKey: navigatorKey,
        initialLocation: PlatformDispatcher.instance.defaultRouteName,
        child: MyApp(navigatorKey: navigatorKey),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  /// Navigator key shared with the universal link host.
  final GlobalKey<NavigatorState>? navigatorKey;

  const MyApp({super.key, this.navigatorKey});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool? _wasOnline;
  ConnectivityProvider? _connectivityProvider;
  AuthProvider? _authProvider;
  bool _wasLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize auth provider on app start
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final quizzBuilderProvider = Provider.of<QuizzBuilderProvider>(
        context,
        listen: false,
      );
      await authProvider.initialize();
      // Restore previous quiz selections (categories/themes)
      await quizzBuilderProvider.initialize();
      if (!mounted) return;
      unawaited(_syncAccessibleContentIfOnline());
    });

    final connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );
    _connectivityProvider = connectivityProvider;
    _wasOnline = connectivityProvider.isOnline;
    connectivityProvider.addListener(_onConnectivityChanged);

    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _authProvider!.addListener(_onAuthChanged);
  }

  /// Forgets per-account duel state when the player signs out.
  void _onAuthChanged() {
    if (!mounted) return;
    final loggedIn = _authProvider?.isLoggedIn ?? false;
    if (_wasLoggedIn && !loggedIn) {
      Provider.of<DuelProvider>(context, listen: false).reset();
    }
    _wasLoggedIn = loggedIn;
  }

  void _onConnectivityChanged() {
    if (!mounted) return;
    final isOnline = _connectivityProvider?.isOnline ?? true;
    final justReconnected = _wasOnline == false && isOnline;
    _wasOnline = isOnline;
    if (justReconnected) {
      unawaited(_syncAccessibleContentIfOnline());
    }
  }

  /// Downloads everything the logged-in player can access (free themes +
  /// already-purchased/unlocked ones) so it stays playable offline. No-op
  /// when offline or logged out; locked paid themes only get their catalog
  /// metadata cached (via CatalogProvider.syncOfflineContent), never their
  /// questions.
  Future<void> _syncAccessibleContentIfOnline() async {
    if (!mounted) return;
    if (_connectivityProvider?.isOnline != true) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;

    final quizzBuilderProvider = Provider.of<QuizzBuilderProvider>(
      context,
      listen: false,
    );
    await quizzBuilderProvider.refreshThemeAccess();
    if (!mounted) return;

    final catalogProvider = Provider.of<CatalogProvider>(
      context,
      listen: false,
    );
    await catalogProvider.syncOfflineContent(
      isEntitled: quizzBuilderProvider.isThemeEntitled,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      // Content sync already runs on startup and reconnect (each with its
      // own cooldown/pacing); avoid firing it again on every foreground
      // resume, which would add extra catalog-access-refresh requests on
      // top of the rate-limited budget for no real benefit.
      authProvider.refreshToken();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityProvider?.removeListener(_onConnectivityChanged);
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          navigatorKey: widget.navigatorKey,
          title: 'QuizzBuilder',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          locale: languageProvider.locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _AppRouter(),
          // Always start on the app router: a universal link used to start
          // the app is handled by InvitationLinkHost, not as a named route.
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: Navigator.defaultRouteName),
              builder: (_) => const _AppRouter(),
            ),
          ],
        );
      },
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const SplashScreen();
        }

        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        }

        return const AuthScreen();
      },
    );
  }
}


