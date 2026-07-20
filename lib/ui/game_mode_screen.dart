import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/gradient_background.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import 'selected_themes_screen.dart';
import 'setup_solo_screen.dart';

class GameModeScreen extends StatefulWidget {
  const GameModeScreen({super.key});

  @override
  State<GameModeScreen> createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isLoggedIn) {
        return;
      }

      final refreshed = await authProvider.refreshToken();
      if (!mounted || refreshed) {
        return;
      }

      // refreshToken() only clears the session when the server explicitly
      // rejected it. If the session is still considered valid, the failure
      // was a network issue (e.g. offline) and the user should keep playing
      // with locally downloaded quizzes instead of being forced to log in.
      if (authProvider.isLoggedIn) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AuthScreen(
            infoMessage: 'Session expired. Please sign in again.',
          ),
        ),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.selectGameMode)),
      body: GradientBackground(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double tileWidth = constraints.maxWidth;
              return ListView(
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.chooseYourChallenge,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Solo Mode Button
                  SizedBox(
                    width: tileWidth,
                    height: 220,
                    child: _GameModeCard(
                      icon: Icons.person,
                      title: AppLocalizations.of(context)!.soloMode,
                      description: AppLocalizations.of(context)!.soloModeDesc,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SetupSoloScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Multiplayer Mode Button
                  SizedBox(
                    width: tileWidth,
                    height: 220,
                    child: _GameModeCard(
                      icon: Icons.people,
                      title: AppLocalizations.of(context)!.multiplayerMode,
                      description: AppLocalizations.of(
                        context,
                      )!.multiplayerModeDesc,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SelectedThemesScreen(
                              gameMode: 'multiplayer',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      ),
    );
  }
}

class _GameModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _GameModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.8),
              color.withValues(alpha: 0.6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
