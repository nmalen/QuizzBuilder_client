import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';

class _SurvivalHighScoreEntry {
  const _SurvivalHighScoreEntry({
    required this.id,
    required this.name,
    required this.score,
    required this.theme,
    required this.achievedAt,
  });

  final String id;
  final String name;
  final int score;
  final String theme;
  final DateTime achievedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'score': score,
        'theme': theme,
        'achieved_at': achievedAt.toIso8601String(),
      };

  factory _SurvivalHighScoreEntry.fromJson(Map<String, dynamic> json) {
    return _SurvivalHighScoreEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      theme: json['theme'] as String? ?? '',
      achievedAt: DateTime.tryParse(json['achieved_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  _SurvivalHighScoreEntry copyWith({String? name}) {
    return _SurvivalHighScoreEntry(
      id: id,
      name: name ?? this.name,
      score: score,
      theme: theme,
      achievedAt: achievedAt,
    );
  }
}

class _BestScoreNameDialog extends StatefulWidget {
  const _BestScoreNameDialog({
    required this.initialName,
    required this.title,
    required this.message,
    required this.fieldLabel,
    required this.saveLabel,
  });

  final String initialName;
  final String title;
  final String message;
  final String fieldLabel;
  final String saveLabel;

  @override
  State<_BestScoreNameDialog> createState() => _BestScoreNameDialogState();
}

class _BestScoreNameDialogState extends State<_BestScoreNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: widget.fieldLabel,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              Navigator.of(context).pop(value.trim());
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}

class ResultsScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String gameMode; // 'standard', 'survival', 'timed'
  final int? duration; // Duration in seconds (for timed mode)
  final bool survivalFailed; // Whether game ended due to failure
  final String theme; // Theme name

  const ResultsScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    this.gameMode = 'standard',
    this.duration,
    this.survivalFailed = false,
    this.theme = '',
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with TickerProviderStateMixin {
  static const String _survivalHighScoresKey = 'survival_high_scores_v1';
  static const int _maxSurvivalHighScores = 5;

  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  List<_SurvivalHighScoreEntry> _survivalHighScores = const [];
  int? _currentSurvivalRank;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _saveScore();
  }

  void _setupAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () => _slideController.forward());
  }

  Future<void> _saveScore() async {
    if (widget.gameMode != 'survival') {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedRaw = prefs.getString(_survivalHighScoresKey);
    final List<_SurvivalHighScoreEntry> savedScores;
    if (savedRaw == null || savedRaw.isEmpty) {
      savedScores = <_SurvivalHighScoreEntry>[];
    } else {
      final decoded = jsonDecode(savedRaw) as List<dynamic>;
      savedScores = decoded
          .map((entry) => _SurvivalHighScoreEntry.fromJson(entry as Map<String, dynamic>))
          .toList(growable: true);
    }

    final entry = _SurvivalHighScoreEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _getDefaultSurvivalPlayerName(),
      score: widget.score,
      theme: widget.theme,
      achievedAt: DateTime.now(),
    );

    savedScores.add(entry);
    savedScores.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) {
        return scoreComparison;
      }
      return a.achievedAt.compareTo(b.achievedAt);
    });

    final rank = savedScores.indexWhere((saved) => saved.id == entry.id);
    final trimmedScores = savedScores.take(_maxSurvivalHighScores).toList(growable: false);
    final currentRank = rank >= 0 && rank < _maxSurvivalHighScores ? rank : null;

    await prefs.setString(
      _survivalHighScoresKey,
      jsonEncode(trimmedScores.map((score) => score.toJson()).toList(growable: false)),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _survivalHighScores = trimmedScores;
      _currentSurvivalRank = currentRank;
    });

    if (currentRank != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _promptForBestScoreName(entry.id);
      });
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _getPercentage() {
    return ((widget.score / widget.totalQuestions) * 100).toStringAsFixed(0);
  }

  String _getDefaultSurvivalPlayerName() {
    final authProvider = context.read<AuthProvider>();
    final displayName = authProvider.user?.displayName.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return 'Player';
  }

  Future<void> _promptForBestScoreName(String scoreId) async {
    final loc = AppLocalizations.of(context)!;
    _SurvivalHighScoreEntry? currentEntry;
    for (final entry in _survivalHighScores) {
      if (entry.id == scoreId) {
        currentEntry = entry;
        break;
      }
    }
    if (currentEntry == null) {
      return;
    }

    final selectedName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _BestScoreNameDialog(
          initialName: currentEntry!.name,
          title: loc.survivalNewBestTitle,
          message: loc.survivalNewBestMessage,
          fieldLabel: loc.survivalPlayerName,
          saveLabel: loc.save,
        );
      },
    );

    if (!mounted) {
      return;
    }

    final normalizedName = (selectedName ?? currentEntry.name).trim();
    await _renameSurvivalScore(
      scoreId: scoreId,
      newName: normalizedName.isEmpty ? _getDefaultSurvivalPlayerName() : normalizedName,
    );
  }

  Future<void> _renameSurvivalScore({
    required String scoreId,
    required String newName,
  }) async {
    final updatedScores = _survivalHighScores
        .map((entry) => entry.id == scoreId ? entry.copyWith(name: newName) : entry)
        .toList(growable: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _survivalHighScoresKey,
      jsonEncode(updatedScores.map((score) => score.toJson()).toList(growable: false)),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _survivalHighScores = updatedScores;
    });
  }

  String _getPerformanceMessage(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final percentage = double.parse(_getPercentage());
    if (percentage >= 90) return loc.outstanding;
    if (percentage >= 80) return loc.excellent;
    if (percentage >= 70) return loc.greatJob;
    if (percentage >= 60) return loc.goodEffort;
    if (percentage >= 50) return loc.notBad;
    return loc.keepPracticing;
  }

  Color _getPerformanceColor() {
    if (widget.gameMode == 'survival') {
      return Colors.amber[700]!;
    }
    final percentage = double.parse(_getPercentage());
    if (percentage >= 90) return Colors.green[700]!;
    if (percentage >= 80) return Colors.green[600]!;
    if (percentage >= 70) return Colors.blue[600]!;
    if (percentage >= 60) return Colors.orange[600]!;
    if (percentage >= 50) return Colors.orange[700]!;
    return Colors.red[600]!;
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(
                widget.gameMode == 'survival'
                    ? Icons.emoji_events
                    : (widget.survivalFailed ? Icons.cancel : Icons.check_circle),
                size: 80,
                color: widget.gameMode == 'survival'
                    ? Colors.amber[700]
                    : (widget.survivalFailed ? Colors.red[600] : Colors.green[600]),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        SlideTransition(
          position: _slideAnimation,
          child: Text(
            _getResultTitle(context),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  String _getResultTitle(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (widget.survivalFailed) {
      return loc.gameOver;
    }
    if (widget.gameMode == 'survival') {
      return loc.survivalComplete;
    }
    if (widget.gameMode == 'timed') {
      return loc.timesUp;
    }
    return loc.quizComplete;
  }

  Widget _buildScoreCard() {
    final loc = AppLocalizations.of(context)!;
    final bool isSurvival = widget.gameMode == 'survival';

    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getPerformanceColor().withValues(alpha: 0.1),
                _getPerformanceColor().withValues(alpha: 0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Column(
            children: [
              Text(
                loc.yourScore,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    widget.score.toString(),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getPerformanceColor(),
                        ),
                  ),
                  if (!isSurvival) ...[
                    const SizedBox(width: 4),
                    Text(
                      '/ ${widget.totalQuestions}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ],
              ),
              if (isSurvival && _currentSurvivalRank != null) ...[
                const SizedBox(height: 12),
                Text(
                  loc.survivalRankLabel((_currentSurvivalRank ?? 0) + 1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getPerformanceColor(),
                      ),
                ),
              ] else if (!isSurvival) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: widget.score / widget.totalQuestions,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(_getPerformanceColor()),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPercentageWidget() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getPerformanceColor().withValues(alpha: 0.1),
          border: Border.all(
            color: _getPerformanceColor(),
            width: 3,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '${_getPercentage()}%',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getPerformanceColor(),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.correct,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMessage(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: _getPerformanceColor().withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getPerformanceColor().withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          _getPerformanceMessage(context),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getPerformanceColor(),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStats(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bool hasTimedStat = widget.gameMode == 'timed' && widget.duration != null;
    final bool hasThemeStat = widget.theme.isNotEmpty;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            if (hasTimedStat) ...[
              _buildStatRow(loc.timeUsed, _formatDuration(widget.duration!)),
            ],
            if (hasThemeStat) ...[
              if (hasTimedStat)
                const Divider(height: 12),
              _buildStatRow(loc.theme, widget.theme),
            ],
            if (hasTimedStat || hasThemeStat)
              const Divider(height: 12),
            _buildStatRow(loc.correctAnswers, '${widget.score}'),
            const Divider(height: 12),
            _buildStatRow(loc.wrongAnswers, '${widget.totalQuestions - widget.score}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSurvivalSection() {
    return Column(
      children: [
        _buildSurvivalHighScores(),
        if (widget.theme.isNotEmpty) ...[
          const SizedBox(height: 20),
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: _buildStatRow(AppLocalizations.of(context)!.theme, widget.theme),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSurvivalHighScores() {
    final loc = AppLocalizations.of(context)!;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.survivalBestScores,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
            ),
            const SizedBox(height: 16),
            if (_survivalHighScores.isEmpty)
              Text(
                loc.survivalNoBestScores,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              )
            else
              ..._survivalHighScores.asMap().entries.map((entry) {
                final index = entry.key;
                final scoreEntry = entry.value;
                final bool isCurrent = _currentSurvivalRank == index;

                return Container(
                  margin: EdgeInsets.only(bottom: index == _survivalHighScores.length - 1 ? 0 : 10),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent ? Colors.amber[300]! : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '#${index + 1}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scoreEntry.name,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[900],
                                  ),
                            ),
                            if (scoreEntry.theme.isNotEmpty)
                              Text(
                                scoreEntry.theme,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            scoreEntry.score.toString(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getPerformanceColor(),
                                ),
                          ),
                          if (isCurrent)
                            Text(
                              loc.survivalCurrentResult,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  Widget _buildActionButtons(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to home screen, clearing the navigation stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (Route<dynamic> route) => false,
              );
            },
            icon: const Icon(Icons.home),
            label: Text(loc.home),
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
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.replay),
            label: Text(loc.playAgain),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 36),
                  _buildScoreCard(),
                  if (widget.gameMode != 'survival') ...[
                    const SizedBox(height: 28),
                    _buildPercentageWidget(),
                    const SizedBox(height: 20),
                    _buildPerformanceMessage(context),
                  ],
                  const SizedBox(height: 28),
                  if (widget.gameMode == 'survival')
                    _buildSurvivalSection()
                  else
                    _buildDetailStats(context),
                  const SizedBox(height: 36),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
