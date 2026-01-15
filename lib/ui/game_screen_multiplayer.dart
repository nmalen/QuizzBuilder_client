import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/quizz_builder_provider.dart';
import '../providers/catalog_provider.dart';
import '../models/question.dart';

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
  // Remove static const _totalQuestions, use questions.length
  int currentQuestionIndex = 0;
  int currentPlayerIndex = 0;
  bool answered = false;
  int? selectedAnswerIndex;
  late List<int> scores;
  List<Question> questions = [];
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
      filtered.shuffle();
      final limitedQuestions = filtered.take(widget.questionCount).toList();
      setState(() {
        questions = limitedQuestions;
        isLoading = false;
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
              const SizedBox(height: 16),
              Text('Error loading questions: $error'),
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

    if (questions.isEmpty) {
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

    if (currentQuestionIndex >= questions.length) {
      final int maxScore = scores.reduce((a, b) => a > b ? a : b);
      final List<int> winners = [];
      for (int i = 0; i < scores.length; i++) {
        if (scores[i] == maxScore) {
          winners.add(i + 1);
        }
      }
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.multiplayerMode)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
              const SizedBox(height: 24),
              Text(
                winners.length > 1 ? 'It\'s a Tie!' : 'Player(s) ${winners.join(", ")} Win!' ,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Winning Score: $maxScore/${questions.length}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Text('Final Scores:', style: Theme.of(context).textTheme.titleMedium),
              ...scores.asMap().entries.map((entry) {
                final idx = entry.key;
                final score = entry.value;
                return Text('Player ${idx + 1}: $score');
              }),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    final currentQuestion = questions[currentQuestionIndex];
    final answers = currentQuestion.getAnswers(languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.multiplayerMode),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),

              // Question progress
              Text(
                'Question ${currentQuestionIndex + 1} / ${questions.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Question content
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                  children: [
                    Text(
                      'Player ${currentPlayerIndex + 1}\'s Turn',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentQuestion.getQuestion(languageCode),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
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

                // Highlight logic
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
                    final bool isLastTurn = currentQuestionIndex == questions.length - 1 &&
                        currentPlayerIndex == widget.playerCount - 1;

                    if (isLastTurn) {
                      setState(() {
                        currentQuestionIndex++;
                      });
                      return;
                    }

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
                    currentQuestionIndex == questions.length - 1 && currentPlayerIndex == widget.playerCount - 1
                      ? 'Finish'
                      : 'Continue',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.orange.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.orange : Colors.grey[300]!,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'P$playerNumber',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.orange[800] : Colors.grey[600],
                ),
          ),
          const SizedBox(width: 8),
          Text(
            '$score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isActive ? Colors.orange : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
