import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/gradient_background.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/daily_challenge_service.dart';
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
  DailyChallengeStatus? _dailyStatus;
  bool _dailyLoading = false;
  String? _dailyError;

  @override
  void initState() {
    super.initState();
    _selectedDifficulties = List<String>.from(widget.selectedDifficulties);
  }

  Future<void> _loadDailyStatus() async {
    setState(() {
      _dailyLoading = true;
      _dailyError = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final service = DailyChallengeService(authService: authProvider.authService);
      final status = await service.getStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _dailyStatus = status;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _dailyError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _dailyLoading = false;
        });
      }
    }
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
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 16),
            if (_gameMode != 'survival' && _gameMode != 'daily') ...[
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
                min: 5,
                max: 20,
                divisions: 15,
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
            ],
            Text(
              AppLocalizations.of(context)!.selectGameMode,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            RadioGroup<String>(
              groupValue: _gameMode,
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _gameMode = value;
                });
                if (value == 'daily' && _dailyStatus == null && !_dailyLoading) {
                  _loadDailyStatus();
                }
              },
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'standard',
                      activeColor: Colors.white,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        AppLocalizations.of(context)!.standardMode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'survival',
                      activeColor: Colors.white,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        AppLocalizations.of(context)!.survivalMode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'daily',
                      activeColor: Colors.white,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      title: const Text(
                        'Quotidien',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_gameMode == 'daily') ...[
              if (_dailyLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                )
              else if (_dailyError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Impossible de charger le statut quotidien.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (_dailyStatus != null)
                _buildDailyStatusCard(_dailyStatus!),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _gameMode == 'daily' && _dailyStatus != null && !_dailyStatus!.canPlayToday
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameScreenSolo(
                      questionCount: _gameMode == 'daily' ? 10 : _questionCount,
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

  Widget _buildDailyStatusCard(DailyChallengeStatus status) {
    final int normalizedTarget = status.target <= 0 ? 10 : status.target;
    final int normalizedProgress =
        status.currentStreak.clamp(0, normalizedTarget);
    final bool rewardReady = normalizedProgress >= normalizedTarget;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Defi quotidien',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Progression: ${status.currentStreak}/${status.target} sans erreur',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          Text(
            'Credits gratuits debloques: ${status.rewardsGranted}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          Text(
            status.canPlayToday ? 'Disponible aujourd\'hui' : 'Deja joue aujourd\'hui',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: status.canPlayToday ? Colors.greenAccent : Colors.orangeAccent,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: rewardReady
                  ? Colors.amber.withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: rewardReady ? Colors.amberAccent : Colors.white30,
                width: rewardReady ? 2 : 1,
              ),
              boxShadow: rewardReady
                  ? [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.45),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  rewardReady ? Icons.workspace_premium : Icons.stars,
                  color: rewardReady ? Colors.black : Colors.amberAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rewardReady
                        ? 'Palier atteint: +1 credit pret a etre debloque'
                      : 'Palier credit: atteint au ${normalizedTarget}eme succes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: rewardReady ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.of(context)!.dailyPathToFreeCredit,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(normalizedTarget, (index) {
              final int step = index + 1;
              final bool reached = step <= normalizedProgress;
              final bool isRewardMilestone = step == normalizedTarget;

              final Color bgColor;
              final Color borderColor;
              final Color textColor;

              if (isRewardMilestone) {
                bgColor = reached
                    ? Colors.amber.withValues(alpha: 0.9)
                    : Colors.amber.withValues(alpha: 0.2);
                borderColor = Colors.amberAccent;
                textColor = reached ? Colors.black : Colors.amberAccent;
              } else if (reached) {
                bgColor = Colors.greenAccent.withValues(alpha: 0.85);
                borderColor = Colors.greenAccent;
                textColor = Colors.black;
              } else {
                bgColor = Colors.white.withValues(alpha: 0.08);
                borderColor = Colors.white38;
                textColor = Colors.white70;
              }

              return Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: isRewardMilestone ? 2 : 1.3,
                  ),
                ),
                child: isRewardMilestone
                    ? Icon(
                        reached ? Icons.workspace_premium : Icons.lock_open,
                        size: 16,
                        color: textColor,
                      )
                    : Text(
                        '$step',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Le palier credit est mis en evidence en dore.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: status.timeline.map((entry) {
              final String state = (entry['status'] as String?) ?? 'pending';
              final bool isToday = entry['is_today'] as bool? ?? false;
              Color color;
              if (state == 'success') {
                color = Colors.greenAccent;
              } else if (state == 'failed') {
                color = Colors.redAccent;
              } else if (state == 'future') {
                color = Colors.white24;
              } else {
                color = Colors.white60;
              }

              return Container(
                width: isToday ? 14 : 10,
                height: isToday ? 14 : 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isToday ? Border.all(color: Colors.white, width: 1.5) : null,
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}
