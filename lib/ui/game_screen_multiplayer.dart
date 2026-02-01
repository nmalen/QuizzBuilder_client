import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/quizz_builder_provider.dart';
import '../providers/catalog_provider.dart';
import '../models/question.dart';
import '../models/theme.dart' as theme_model;
import '../db/local_db.dart';
import '../widgets/gradient_background.dart';
import 'home_screen.dart';
import 'setup_multiplayer_screen.dart';

class GameScreenMultiplayer extends StatefulWidget {
  final int playerCount;
  final int questionCount;
  final List<String> difficulties;

  const GameScreenMultiplayer({
    super.key,
    required this.playerCount,
    this.questionCount = 10,
    this.difficulties = const ['easy'],
  });

  @override
  State<GameScreenMultiplayer> createState() => _GameScreenMultiplayerState();
}

class _GameScreenMultiplayerState extends State<GameScreenMultiplayer> {
  int currentPlayerIndex = 0;
  int currentQuestionIndex = 0;
  bool answered = false;
  int? selectedAnswerIndex;
  late List<int> scores;
  List<List<Question>> playerQuestions = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    scores = List<int>.filled(widget.playerCount, 0);
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final builder = Provider.of<QuizzBuilderProvider>(context, listen: false);
      final catalog = Provider.of<CatalogProvider>(context, listen: false);

      final List<Question> allQuestions = [];
      for (int themeId in builder.selectedThemeIds) {
        final themeQuestions = await catalog.loadQuestionsByTheme(themeId);
        allQuestions.addAll(themeQuestions);
      }

      // Filter by selected difficulties
      final filtered = allQuestions.where((q) => widget.difficulties.contains(q.difficulty)).toList();

      // Validation: Ensure enough unique questions for all players
      final int requiredQuestions = widget.playerCount * widget.questionCount;
      if (filtered.length < requiredQuestions) {
        setState(() {
          error = 'Not enough unique questions available for $requiredQuestions total questions ($widget.playerCount players × ${widget.questionCount} questions each). Please select fewer players, reduce questions per player, or add more questions.';
          isLoading = false;
        });
        return;
      }

      // Assign a unique set of questions to each player
      List<List<Question>> playerSets = [];
      List<Question> pool = List<Question>.from(filtered);
      pool.shuffle();
      for (int i = 0; i < widget.playerCount; i++) {
        playerSets.add(pool.skip(i * widget.questionCount).take(widget.questionCount).toList());
      }
      setState(() {
        playerQuestions = playerSets;
        isLoading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.multiplayerMode)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.multiplayerMode)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 4),
            ],
          ),
        ),
      );
    }

    if (playerQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.multiplayerMode)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No questions found'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (currentQuestionIndex >= widget.questionCount) {
      return _MultiplayerResultsScreen(
        scores: scores,
        playerCount: widget.playerCount,
        questionCount: widget.questionCount,
      );
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    final currentQuestion = playerQuestions[currentPlayerIndex][currentQuestionIndex];
    final answers = currentQuestion.getAnswers(languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.multiplayerMode),
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Player scoreboard
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(widget.playerCount, (i) {
                  return _PlayerScore(
                    playerNumber: i + 1,
                    score: scores[i],
                    isActive: currentPlayerIndex == i,
                  );
                }),
              ),
              // Cat image
              Center(
                child: Image.asset(
                  'assets/images/QuizzbuilderCat.png',
                  width: 180,
                  height: 120,
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.topCenter,
                ),
              ),
              const SizedBox(height: 4),
              // Question content
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Question ${currentQuestionIndex + 1} / ${widget.questionCount}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<theme_model.Theme?>(
                      future: LocalDb.getThemeById(currentQuestion.theme),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Text(
                            snapshot.data!.getName(languageCode),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentQuestion.getQuestion(languageCode),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Answer options
              ...answers.asMap().entries.map((entry) {
                int index = entry.key;
                String answer = entry.value;
                Color? bgColor;
                if (answered) {
                  if (index + 1 == currentQuestion.correctAnswer) {
                    bgColor = Colors.green;
                  } else if (selectedAnswerIndex == index) {
                    bgColor = Colors.red;
                  } else {
                    bgColor = Colors.blue;
                  }
                } else {
                  bgColor = Colors.blue;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: answered
                        ? null
                        : () {
                            setState(() {
                              selectedAnswerIndex = index;
                              answered = true;
                              if (index + 1 == currentQuestion.correctAnswer) {
                                scores[currentPlayerIndex]++;
                              }
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      backgroundColor: bgColor,
                      disabledBackgroundColor: bgColor,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        answer,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              // Next/Finish button
              if (answered)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (currentPlayerIndex < widget.playerCount - 1) {
                        currentPlayerIndex++;
                      } else {
                        currentPlayerIndex = 0;
                        currentQuestionIndex++;
                      }
                      answered = false;
                      selectedAnswerIndex = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                  ),
                  child: Text(
                    currentQuestionIndex == widget.questionCount - 1 && currentPlayerIndex == widget.playerCount - 1
                        ? 'Finish'
                        : 'Continue',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (answered)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.flag, color: Colors.red),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      final catalog = Provider.of<CatalogProvider>(context, listen: false);
                      try {
                        await catalog.reportQuestionError(playerQuestions[currentPlayerIndex][currentQuestionIndex].id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Question flagged for verification.')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to report error: $e')),
                        );
                      }
                    },
                    label: const Text('Signaler une erreur'),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _PlayerScore extends StatelessWidget {
  final int playerNumber;
  final int score;
  final bool isActive;

  const _PlayerScore({
    required this.playerNumber,
    required this.score,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isActive ? Colors.orange : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.deepOrange : Colors.grey[400]!,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Player $playerNumber',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Score: $score',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiplayerResultsScreen extends StatefulWidget {
  final List<int> scores;
  final int playerCount;
  final int questionCount;

  const _MultiplayerResultsScreen({
    required this.scores,
    required this.playerCount,
    required this.questionCount,
  });

  @override
  State<_MultiplayerResultsScreen> createState() => _MultiplayerResultsScreenState();
}

class _MultiplayerResultsScreenState extends State<_MultiplayerResultsScreen> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int maxScore = widget.scores.reduce((a, b) => a > b ? a : b);
    final List<int> winners = [];
    for (int i = 0; i < widget.scores.length; i++) {
      if (widget.scores[i] == maxScore) {
        winners.add(i + 1);
      }
    }

    // Sort scores in descending order with player numbers
    final List<MapEntry<int, int>> sortedScores = [];
    for (int i = 0; i < widget.scores.length; i++) {
      sortedScores.add(MapEntry(i + 1, widget.scores[i]));
    }
    sortedScores.sort((a, b) => b.value.compareTo(a.value));

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Winner icon
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Icon(
                          Icons.emoji_events,
                          size: 80,
                          color: Colors.amber[700],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Winner announcement
                  Text(
                    winners.length > 1 ? 'It\'s a Tie!' : 'Player ${winners.first} Wins!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  // Winning score
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Winning Score',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.amber[900],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$maxScore/${widget.questionCount}',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Leaderboard
                  Text(
                    'Final Leaderboard',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...sortedScores.asMap().entries.map((entry) {
                    final position = entry.key;
                    final playerNumber = entry.value.key;
                    final score = entry.value.value;
                    final isWinner = winners.contains(playerNumber);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isWinner ? Colors.amber[50] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isWinner ? Colors.amber[200]! : Colors.grey[200]!,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isWinner ? Colors.amber[400] : Colors.grey[300],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '#${position + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isWinner ? Colors.white : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Player $playerNumber',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isWinner ? Colors.amber[900] : Colors.grey[900],
                                      ),
                                ),
                              ],
                            ),
                            Text(
                              '$score/${widget.questionCount}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isWinner ? Colors.amber[700] : Colors.grey[700],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 36),
                  // Action buttons
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to home screen, clearing the navigation stack
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: Text(AppLocalizations.of(context)!.home),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Navigate back to multiplayer setup screen
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SetupMultiplayerScreen()),
                      );
                    },
                    icon: const Icon(Icons.replay),
                    label: Text(AppLocalizations.of(context)!.playAgain),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.blue[600]!),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

