import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'game_screen_solo.dart';

class SetupSoloScreen extends StatefulWidget {
  const SetupSoloScreen({super.key});

  @override
  State<SetupSoloScreen> createState() => _SetupSoloScreenState();
}

class _SetupSoloScreenState extends State<SetupSoloScreen> {
  int _questionCount = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.soloMode),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Setup solo game',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameScreenSolo(questionCount: _questionCount),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Start Game',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
