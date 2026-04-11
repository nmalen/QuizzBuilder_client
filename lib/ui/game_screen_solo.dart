import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/quizz_builder_provider.dart';
import '../providers/catalog_provider.dart';
import '../models/question.dart';
import '../models/theme.dart' as theme_model;
import '../db/local_db.dart';
import '../providers/auth_provider.dart';
import '../services/daily_challenge_service.dart';
import '../widgets/gradient_background.dart';
import 'results_screen.dart';

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
  bool dailyFailed = false;
  DailyChallengeService? _dailyService;
  bool _dailyCompletionSubmitted = false;
  DailyChallengeCompletion? _dailyCompletion;

  String _localized(BuildContext context, String en, String fr) {
    return Localizations.localeOf(context).languageCode == 'fr' ? fr : en;
  }

  @override
  void initState() {
    super.initState();
    gameMode = widget.gameMode;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _dailyService = DailyChallengeService(authService: authProvider.authService);
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      if (gameMode == 'daily') {
        final status = await _dailyService!.getStatus();
        if (!status.canPlayToday) {
          setState(() {
            error = _localized(
              context,
              'Daily challenge already completed today.',
              'Défi quotidien déjà terminé aujourd\'hui.',
            );
            isLoading = false;
          });
          return;
        }

        final quiz = await _dailyService!.getQuestions();
        setState(() {
          questions = quiz.questions;
          isLoading = false;
        });
        return;
      }

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

  Future<void> _completeDailyIfNeeded(bool isCurrentAnswerCorrect) async {
    if (gameMode != 'daily' || _dailyCompletionSubmitted) {
      return;
    }

    // In daily mode we submit immediately on first failure, or on last question if still successful.
    final bool isLastQuestion = currentQuestionIndex == questions.length - 1;
    if (isCurrentAnswerCorrect && !isLastQuestion) {
      return;
    }

    _dailyCompletionSubmitted = true;
    final bool success = !dailyFailed && isCurrentAnswerCorrect && score == questions.length;

    try {
      final completion = await _dailyService!.complete(success: success);
      _dailyCompletion = completion;
      if (!mounted) {
        return;
      }

      final builder = Provider.of<QuizzBuilderProvider>(context, listen: false);
      await builder.refreshThemeAccess();
      if (!mounted) {
        return;
      }

      if (completion.rewardGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _localized(
                context,
                'Daily challenge completed: +1 free credit.',
                'Défi quotidien validé : +1 crédit offert.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _localized(
              context,
              'Daily result could not be synced.',
              'Résultat quotidien non synchronisé.',
            ),
          ),
        ),
      );
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
              Text(
                '${AppLocalizations.of(context)!.errorLoadingThemes}: $error',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.goBack),
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
              Text(AppLocalizations.of(context)!.noQuestionsFound),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.goBack),
              ),
            ],
          ),
        ),
      );
    }

    if (currentQuestionIndex >= questions.length || survivalFailed || dailyFailed) {
      return ResultsScreen(
        score: score,
        totalQuestions: questions.length,
        gameMode: gameMode,
        survivalFailed: survivalFailed,
        theme: '',
        dailyCurrentStreak: _dailyCompletion?.currentStreak,
        dailyTarget: _dailyCompletion?.target,
        dailyRewardGranted: _dailyCompletion?.rewardGranted ?? false,
        dailyRewardsGranted: _dailyCompletion?.rewardsGranted,
      );
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    final currentQuestion = questions[currentQuestionIndex];
    final answers = currentQuestion.getAnswers(languageCode);
    final bool blockBackNavigation = gameMode == 'survival' || gameMode == 'daily';

    return PopScope(
      canPop: !blockBackNavigation,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.soloMode),
          elevation: 0,
          automaticallyImplyLeading: !blockBackNavigation,
        ),
        body: GradientBackground(
          child: SingleChildScrollView(
            child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Header with progress
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${AppLocalizations.of(context)!.score}: $score',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Image.asset(
                      'assets/images/QuizzbuilderCat.png',
                      width: 180,
                      height: 120,
                      fit: BoxFit.fitHeight,
                      alignment: Alignment.topCenter,
                    ),
                  ],
                ),
              ),
              // Question content
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.08),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.question} ${currentQuestionIndex + 1}/${questions.length}',
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
                    onPressed: answered ? null : () async {
                      final bool isCurrentAnswerCorrect = index + 1 == currentQuestion.correctAnswer;

                      setState(() {
                        selectedAnswerIndex = index;
                        answered = true;
                        if (isCurrentAnswerCorrect) {
                          score++;
                        }
                      });

                      if (gameMode == 'daily' && !isCurrentAnswerCorrect) {
                        dailyFailed = true;
                        await _completeDailyIfNeeded(false);
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          // Force immediate transition to results on first error in daily mode.
                          currentQuestionIndex = questions.length;
                          answered = false;
                          selectedAnswerIndex = null;
                        });
                      }
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
                  onPressed: () async {
                    final bool isCurrentAnswerCorrect =
                        selectedAnswerIndex != null && selectedAnswerIndex! + 1 == currentQuestion.correctAnswer;

                    if (gameMode == 'daily' && !isCurrentAnswerCorrect) {
                      dailyFailed = true;
                    }

                    await _completeDailyIfNeeded(isCurrentAnswerCorrect);

                    setState(() {
                      if (gameMode == 'survival' && !isCurrentAnswerCorrect) {
                        survivalFailed = true;
                        return;
                      }
                      currentQuestionIndex++;
                      answered = false;
                      selectedAnswerIndex = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text(
                    (gameMode == 'survival')
                        ? (selectedAnswerIndex == null || selectedAnswerIndex! + 1 != currentQuestion.correctAnswer ? AppLocalizations.of(context)!.done : AppLocalizations.of(context)!.next)
                      : (gameMode == 'daily')
                        ? (currentQuestionIndex < questions.length - 1 ? AppLocalizations.of(context)!.next : AppLocalizations.of(context)!.done)
                        : (currentQuestionIndex < questions.length - 1 ? AppLocalizations.of(context)!.next : AppLocalizations.of(context)!.done),
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
                      final messenger = ScaffoldMessenger.of(context);
                      final loc = AppLocalizations.of(context)!;
                      try {
                        await catalog.reportQuestionError(questions[currentQuestionIndex].id);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text(loc.questionFlagged)),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text(loc.failedToReportError(e.toString()))),
                        );
                      }
                    },
                    label: Text(AppLocalizations.of(context)!.reportError),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }
}
