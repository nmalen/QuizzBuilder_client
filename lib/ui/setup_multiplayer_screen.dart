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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.multiplayerMode),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Setup multiplayer game',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select number of players (1-4)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Players'),
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
            ElevatedButton(
              onPressed: () {
                if (_playerCount == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GameScreenSolo(questionCount: 10),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreenMultiplayer(playerCount: _playerCount),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
