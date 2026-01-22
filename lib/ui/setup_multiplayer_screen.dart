import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'game_screen_multiplayer.dart';
import 'game_screen_solo.dart';

class SetupMultiplayerScreen extends StatefulWidget {
  const SetupMultiplayerScreen({super.key});

  @override
  State<SetupMultiplayerScreen> createState() => _SetupMultiplayerScreenState();
}

class _SetupMultiplayerScreenState extends State<SetupMultiplayerScreen> {
  int _playerCount = 2;
  int _questionCount = 10;
  final String _gameMode = 'standard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.multiplayerMode),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.setupMultiplayerGame,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.selectNumberOfPlayers,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.players),
                Text('$_playerCount'),
              ],
            ),
            Slider(
              value: _playerCount.toDouble(),
              min: 1,
              max: 4,
              divisions: 3,
              label: '$_playerCount',
              onChanged: (value) {
                setState(() {
                  _playerCount = value.round();
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.selectNumberOfQuestions,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.questions),
                Text('$_questionCount'),
              ],
            ),
            Slider(
              value: _questionCount.toDouble(),
              min: 5,
              max: 20,
              divisions: 15,
              label: '$_questionCount',
              onChanged: (value) {
                setState(() {
                  _questionCount = value.round();
                });
              },
            ),
            const SizedBox(height: 24),
            // Only standard mode is available for multiplayer
            ElevatedButton(
              onPressed: () {
                if (_playerCount == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreenSolo(
                        questionCount: _questionCount,
                        gameMode: _gameMode,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreenMultiplayer(
                        playerCount: _playerCount,
                        questionCount: _questionCount,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                AppLocalizations.of(context)!.continueText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
