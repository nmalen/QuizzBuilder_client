import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/question.dart';
import '../providers/catalog_provider.dart';
import '../providers/quizz_builder_provider.dart';
import '../widgets/gradient_background.dart';
import 'game_screen_multiplayer.dart';
import 'game_screen_solo.dart';

/// Bounds of the two multiplayer sliders. Single source for the sliders and
/// for the hint shown on the themes screen.
class MultiplayerLimits {
  static const int minPlayers = 1;
  static const int maxPlayers = 4;
  static const int minQuestionsPerPlayer = 5;
  static const int maxQuestionsPerPlayer = 20;
}

/// Questions of [questions] whose difficulty is one of [difficulties].
/// Shared by the setup screen (count shown) and the game screen (pool used),
/// so the announced number is the one the game will actually draw from.
List<Question> filterQuestionsByDifficulties(
  Iterable<Question> questions,
  Iterable<String> difficulties,
) {
  final wanted = difficulties.toSet();
  return questions.where((q) => wanted.contains(q.difficulty)).toList();
}

class SetupMultiplayerScreen extends StatefulWidget {
  /// Difficulty levels ticked on the themes screen.
  final List<String> difficulties;

  const SetupMultiplayerScreen({super.key, required this.difficulties});

  @override
  State<SetupMultiplayerScreen> createState() => _SetupMultiplayerScreenState();
}

class _SetupMultiplayerScreenState extends State<SetupMultiplayerScreen> {
  int _playerCount = 2;
  int _questionCount = 10;
  final String _gameMode = 'standard';
  // Questions the game will really draw from; null while loading or if the
  // load failed (the game screen then remains the safety net).
  int? _availableQuestions;

  @override
  void initState() {
    super.initState();
    _loadAvailableQuestions();
  }

  Future<void> _loadAvailableQuestions() async {
    try {
      final builder = Provider.of<QuizzBuilderProvider>(context, listen: false);
      final catalog = Provider.of<CatalogProvider>(context, listen: false);
      final all = await catalog.loadQuestionsByThemes(
        builder.selectedThemeIds.toList(),
      );
      final count = filterQuestionsByDifficulties(all, widget.difficulties).length;
      if (!mounted) return;
      setState(() => _availableQuestions = count);
    } catch (_) {
      // Leave the count unknown: no warning, game screen reports any shortage.
    }
  }

  Widget _buildAvailability(BuildContext context, AppLocalizations l10n) {
    final available = _availableQuestions;
    if (available == null) {
      return const SizedBox.shrink();
    }
    final required = _playerCount * _questionCount;
    final shortage = _playerCount > 1 && available < required;
    final line = l10n.multiplayerQuestionsAvailability(
      available,
      required,
      _playerCount,
      _questionCount,
    );
    if (!shortage) {
      return Text(
        line,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      );
    }
    final maxPerPlayer = available ~/ _playerCount;
    final advice = maxPerPlayer >= MultiplayerLimits.minQuestionsPerPlayer
        ? l10n.multiplayerAdviceReduceQuestions(maxPerPlayer)
        : l10n.multiplayerAdviceReducePlayers;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line,
            style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(advice, style: TextStyle(color: Colors.red[700])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final available = _availableQuestions;
    final blocked = _playerCount > 1 &&
        available != null &&
        available < _playerCount * _questionCount;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.multiplayerMode),
      ),
      body: GradientBackground(
        child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.setupMultiplayerGame,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.selectNumberOfPlayers,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.players,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                Text(
                  '$_playerCount',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Slider(
              value: _playerCount.toDouble(),
              min: MultiplayerLimits.minPlayers.toDouble(),
              max: MultiplayerLimits.maxPlayers.toDouble(),
              divisions: MultiplayerLimits.maxPlayers - MultiplayerLimits.minPlayers,
              label: '$_playerCount',
              activeColor: Colors.white,
              inactiveColor: Colors.white54,
              onChanged: (value) {
                setState(() {
                  _playerCount = value.round();
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.selectNumberOfQuestions,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.questions,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                Text(
                  '$_questionCount',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Slider(
              value: _questionCount.toDouble(),
              min: MultiplayerLimits.minQuestionsPerPlayer.toDouble(),
              max: MultiplayerLimits.maxQuestionsPerPlayer.toDouble(),
              divisions: MultiplayerLimits.maxQuestionsPerPlayer -
                  MultiplayerLimits.minQuestionsPerPlayer,
              label: '$_questionCount',
              activeColor: Colors.white,
              inactiveColor: Colors.white54,
              onChanged: (value) {
                setState(() {
                  _questionCount = value.round();
                });
              },
            ),
            const SizedBox(height: 24),
            _buildAvailability(context, l10n),
            const SizedBox(height: 16),
            // Only standard mode is available for multiplayer
            ElevatedButton(
              onPressed: blocked ? null : () {
                if (_playerCount == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreenSolo(
                        questionCount: _questionCount,
                        gameMode: _gameMode,
                        difficulties: List<String>.from(widget.difficulties),
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
                        difficulties: List<String>.from(widget.difficulties),
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
      ),
    );
  }
}
