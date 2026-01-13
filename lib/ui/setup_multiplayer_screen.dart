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
  String _difficulty = 'easy';

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
            Text(
              'Select number of questions (5-20)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Questions'),
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
            Text(
              'Select question level',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ToggleButtons(
              isSelected: [
                _difficulty == 'easy',
                _difficulty == 'medium',
                _difficulty == 'hard',
              ],
              onPressed: (index) {
                setState(() {
                  _difficulty = ['easy', 'medium', 'hard'][index];
                });
              },
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Easy'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Medium'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Hard'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_playerCount == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreenSolo(questionCount: _questionCount, difficulty: _difficulty),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreenMultiplayer(
                        playerCount: _playerCount,
                        questionCount: _questionCount,
                        difficulty: _difficulty,
                      ),
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
