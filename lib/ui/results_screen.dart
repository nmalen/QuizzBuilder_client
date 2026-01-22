import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';

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
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

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
    // Score saving is handled at the service level
    // This is a placeholder for future local persistence
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
                widget.survivalFailed ? Icons.cancel : Icons.check_circle,
                size: 80,
                color: widget.survivalFailed ? Colors.red[600] : Colors.green[600],
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
                _getPerformanceColor().withOpacity(0.1),
                _getPerformanceColor().withOpacity(0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.yourScore,
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
                  const SizedBox(width: 4),
                  Text(
                    '/ ${widget.totalQuestions}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress indicator
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
          color: _getPerformanceColor().withOpacity(0.1),
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
          color: _getPerformanceColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getPerformanceColor().withOpacity(0.3),
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
            if (widget.gameMode == 'timed' && widget.duration != null) ...[
              _buildStatRow(loc.timeUsed, _formatDuration(widget.duration!)),
              const Divider(height: 12),
            ],
            _buildStatRow(loc.correctAnswers, '${widget.score}'),
            const Divider(height: 12),
            _buildStatRow(loc.wrongAnswers, '${widget.totalQuestions - widget.score}'),
            if (widget.theme.isNotEmpty) ...[
              const Divider(height: 12),
              _buildStatRow(loc.theme, widget.theme),
            ],
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
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
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
                  const SizedBox(height: 28),
                  _buildPercentageWidget(),
                  const SizedBox(height: 20),
                  _buildPerformanceMessage(context),
                  const SizedBox(height: 28),
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
