import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/quizz_builder_provider.dart';
import 'providers/language_provider.dart';
import 'services/auth_service.dart';
import 'ui/splash_screen.dart';
import 'ui/auth_screen.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize AuthService and LanguageProvider
  final authService = AuthService();
  await authService.initialize();
  
  final languageProvider = LanguageProvider();
  await languageProvider.initialize();
  
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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool? _wasOnline;
  ConnectivityProvider? _connectivityProvider;

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
      authProvider.refreshToken().then((_) {
        unawaited(_syncAccessibleContentIfOnline());
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityProvider?.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
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


