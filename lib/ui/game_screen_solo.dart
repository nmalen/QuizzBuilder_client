import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/quizz_builder_provider.dart';
import '../providers/catalog_provider.dart';
import '../models/question.dart';

class GameScreenSolo extends StatefulWidget {
  final int questionCount;
  final List<String> difficulties;
  final String gameMode;

  const GameScreenSolo({
    super.key,
    this.questionCount = 10,
    this.difficulties = const ['easy'],
    this.gameMode = 'standard',
  });

  @override
  State<GameScreenSolo> createState() => _GameScreenSoloState();
}

class _GameScreenSoloState extends State<GameScreenSolo> {
  late String gameMode;
  int currentQuestionIndex = 0;
  int score = 0;
  bool answered = false;
  int? selectedAnswerIndex;
  List<Question> questions = [];
  bool isLoading = true;
  String? error;
  bool survivalFailed = false;

  @override
  void initState() {
    super.initState();
    gameMode = widget.gameMode;
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
      List<Question> usedQuestions;
      if (gameMode == 'survival') {
        usedQuestions = filtered;
      } else {
        usedQuestions = filtered.take(widget.questionCount).toList();
      }
      setState(() {
        questions = usedQuestions;
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
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.soloMode)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.soloMode)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 6),
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
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.soloMode)),
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

    if (currentQuestionIndex >= questions.length || survivalFailed) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.soloMode)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                survivalFailed ? Icons.cancel : Icons.check_circle,
                size: 80,
                color: survivalFailed ? Colors.red : Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                gameMode == 'survival'
                    ? (survivalFailed ? 'Game Over!' : 'Survival Complete!')
                    : 'Quiz Complete!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Final Score: $score',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: survivalFailed ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Finish'),
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
        title: Text(AppLocalizations.of(context)!.soloMode),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // const SizedBox(height: 48),
              // Header with progress
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Score: $score',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${currentQuestionIndex + 1}/${questions.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
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
                child: Text(
                  currentQuestion.getQuestion(languageCode),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
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
                    onPressed: answered ? null : () {
                      setState(() {
                        selectedAnswerIndex = index;
                        answered = true;
                        if (index + 1 == currentQuestion.correctAnswer) {
                          score++;
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
                      if (gameMode == 'survival' && (selectedAnswerIndex == null || selectedAnswerIndex! + 1 != currentQuestion.correctAnswer)) {
                        survivalFailed = true;
                        // End game immediately
                        return;
                      }
                      currentQuestionIndex++;
                      answered = false;
                      selectedAnswerIndex = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                  ),
                  child: Text(
                    (gameMode == 'survival')
                        ? (selectedAnswerIndex == null || selectedAnswerIndex! + 1 != currentQuestion.correctAnswer ? 'Finish' : 'Next')
                        : (currentQuestionIndex < questions.length - 1 ? 'Next' : 'Finish'),
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
