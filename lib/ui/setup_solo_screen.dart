import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../l10n/app_localizations.dart';
import 'game_screen_solo.dart';


class SetupSoloScreen extends StatefulWidget {
  final List<String> selectedDifficulties;
  const SetupSoloScreen({super.key, this.selectedDifficulties = const ['easy', 'medium', 'hard']});

  @override
  State<SetupSoloScreen> createState() => _SetupSoloScreenState();
}

class _SetupSoloScreenState extends State<SetupSoloScreen> {
  int _questionCount = 10;
  String _gameMode = 'standard';
  late List<String> _selectedDifficulties;
  @override
  void initState() {
    super.initState();
    _selectedDifficulties = List<String>.from(widget.selectedDifficulties);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.soloMode),
      ),
      body: GradientBackground(
        child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.setupSoloGame,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (_gameMode != 'survival') ...[
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
            ],
            Text(
              AppLocalizations.of(context)!.selectGameMode,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    value: 'standard',
                    groupValue: _gameMode,
                    onChanged: (value) {
                      setState(() {
                        _gameMode = value!;
                      });
                    },
                    title: Text(AppLocalizations.of(context)!.standardMode),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    value: 'survival',
                    groupValue: _gameMode,
                    onChanged: (value) {
                      setState(() {
                        _gameMode = value!;
                      });
                    },
                    title: Text(AppLocalizations.of(context)!.survivalMode),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameScreenSolo(
                      questionCount: _questionCount,
                      gameMode: _gameMode,
                      difficulties: List<String>.from(_selectedDifficulties),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                AppLocalizations.of(context)!.startGame,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
