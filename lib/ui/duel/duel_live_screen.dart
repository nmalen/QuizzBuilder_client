import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/duel_live.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/duel_provider.dart';
import '../../utils/duel_clock.dart';
import '../../widgets/gradient_background.dart';
import 'duel_controller.dart';
import 'duel_errors.dart';
import 'duel_hub_screen.dart';
import 'duel_share.dart';
import 'duel_widgets.dart';

/// The whole live duel in one route: waiting room, countdown, timed game,
/// sending, waiting for the result, and the result with its review.
///
/// Open it with exactly one of [duelId] (banner, hub), [initial] (right after
/// creating the duel) or [joinCode] (call link).
class DuelLiveScreen extends StatefulWidget {
  const DuelLiveScreen({
    super.key,
    this.duelId,
    this.initial,
    this.joinCode,
    this.openHubWhenNotFound = false,
    this.shareFn,
    this.now,
    this.roomPollInterval = const Duration(seconds: 2),
    this.resultPollInterval = const Duration(milliseconds: 2500),
    this.retryEvery = const Duration(seconds: 2),
  });

  final int? duelId;
  final Duel? initial;
  final String? joinCode;

  /// Opened from a call link: an unknown duel says so, then lands on the hub.
  final bool openHubWhenNotFound;
  final InvitationShareFn? shareFn;

  /// Clock of the screen (tests drive a whole game with a fake one).
  final DateTime Function()? now;
  final Duration roomPollInterval;
  final Duration resultPollInterval;
  final Duration retryEvery;

  @override
  State<DuelLiveScreen> createState() => _DuelLiveScreenState();
}

class _DuelLiveScreenState extends State<DuelLiveScreen>
    with WidgetsBindingObserver {
  late final DuelController _controller;
  bool _handledNotFound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = DuelController(
      provider: context.read<DuelProvider>(),
      duelId: widget.duelId,
      initial: widget.initial,
      joinCode: widget.joinCode,
      now: widget.now,
      roomPollInterval: widget.roomPollInterval,
      resultPollInterval: widget.resultPollInterval,
      retryEvery: widget.retryEvery,
    );
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.open();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.setOnline(Provider.of<ConnectivityProvider>(context).isOnline);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  /// A call link to an unknown duel: say so, then the hub (decision of the
  /// batch: "message, puis hub").
  void _onChanged() {
    if (_handledNotFound || !widget.openHubWhenNotFound) return;
    if (_controller.phase == DuelPhase.ended &&
        _controller.endKind == DuelEndKind.notFound) {
      _handledNotFound = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        final message = AppLocalizations.of(context)!.duelErrDuelNotFound;
        final navigator = Navigator.of(context);
        navigator.pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const DuelHubScreen()),
        );
        messenger.showSnackBar(SnackBar(content: Text(message)));
      });
    }
  }

  Future<void> _confirmQuit() async {
    final l = AppLocalizations.of(context)!;
    final leave = await confirmDuelAction(
      context,
      title: l.duelQuitTitle,
      body: l.duelQuitBody,
      cancelLabel: l.duelKeepPlaying,
      confirmLabel: l.duelQuitAction,
    );
    if (leave && mounted) _controller.quit();
  }

  Future<void> _confirmCancel() async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final yes = await confirmDuelAction(
      context,
      title: l.duelCancelDuelTitle,
      body: l.duelCancelDuelBody,
      cancelLabel: l.duelBack,
      confirmLabel: l.duelCancelDuel,
    );
    if (!yes || !mounted) return;
    final error = await _controller.cancelDuel();
    if (!mounted) return;
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(duelLiveErrorMessage(l, error))),
      );
      return;
    }
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(l.duelDuelCancelled)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        final l = AppLocalizations.of(context)!;
        final name = c.duel?.opponentUsername ?? '';
        final inGame = c.phase == DuelPhase.game;
        final locked = inGame || c.phase == DuelPhase.countdown;

        final String title = switch (c.phase) {
          DuelPhase.countdown ||
          DuelPhase.game ||
          DuelPhase.sending ||
          DuelPhase.awaitingResult => l.duelGameTitle(name),
          DuelPhase.result => l.duelResultTitle,
          _ => l.duelRoomTitle,
        };

        return PopScope(
          canPop: !locked,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && inGame) _confirmQuit();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(title),
              automaticallyImplyLeading: !locked || inGame,
              leading: inGame
                  ? BackButton(onPressed: _confirmQuit)
                  : (locked ? const SizedBox.shrink() : null),
            ),
            body: GradientBackground(child: SafeArea(child: _body(context, l))),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, AppLocalizations l) {
    final c = _controller;
    switch (c.phase) {
      case DuelPhase.opening:
        return _Opening(message: l.duelRoomOpening);
      case DuelPhase.openFailed:
        return _Padded(
          child: DuelMessageCard(
            message: duelLiveErrorMessage(l, c.openError ?? ''),
            actionLabel: l.retry,
            onAction: c.open,
          ),
        );
      case DuelPhase.room:
        return _RoomView(
          controller: c,
          shareFn: widget.shareFn,
          onCancel: _confirmCancel,
        );
      case DuelPhase.countdown:
        return _CountdownView(controller: c);
      case DuelPhase.game:
        return _GameView(controller: c);
      case DuelPhase.sending:
      case DuelPhase.awaitingResult:
        return _WaitingView(controller: c);
      case DuelPhase.result:
        return _ResultView(controller: c);
      case DuelPhase.ended:
        return _EndedView(controller: c);
    }
  }
}

// ---- Small shared pieces ---------------------------------------------------

class _Padded extends StatelessWidget {
  final Widget child;
  const _Padded({required this.child});

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(16), children: [child]);
}

class _Opening extends StatelessWidget {
  final String message;
  const _Opening({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

/// Difficulties as the player reads them ("Easy, Medium").
String _difficultyNames(AppLocalizations l, List<String> difficulties) {
  String name(String d) => switch (d) {
    'easy' => l.easy,
    'medium' => l.medium,
    'hard' => l.hard,
    _ => d,
  };
  return difficulties.map(name).join(', ');
}

// ---- Waiting room ----------------------------------------------------------

class _RoomView extends StatelessWidget {
  final DuelController controller;
  final InvitationShareFn? shareFn;
  final VoidCallback onCancel;

  const _RoomView({
    required this.controller,
    required this.shareFn,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final duel = controller.duel!;
    final name = duel.opponentUsername;
    final left = controller.roomTimeLeft;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DuelCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 12),
              Text(
                l.duelRoomWaitingFor(name),
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                duel.challengedByMe
                    ? l.duelRoomHintChallenger(name)
                    : l.duelRoomHintChallenged(name),
                textAlign: TextAlign.center,
              ),
              if (left != null) ...[
                const SizedBox(height: 10),
                Text(
                  l.duelRoomTimeLeft(duelFormatClock(left)),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (!controller.online) ...[
                const SizedBox(height: 10),
                Text(
                  l.duelRoomOffline,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ] else if (controller.unstable) ...[
                const SizedBox(height: 10),
                Text(
                  l.duelRoomUnstable,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ],
          ),
        ),
        if (duel.challengedByMe && duel.callLink != null) ...[
          const SizedBox(height: 12),
          DuelCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.duelCallLinkTitle,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(l.duelCallLinkHelp(name)),
                const SizedBox(height: 8),
                SelectableText(
                  duel.callLink!,
                  key: const ValueKey('call-link'),
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      key: const ValueKey('call-link-share'),
                      onPressed: () =>
                          shareCallLink(context, duel, shareFn: shareFn),
                      icon: const Icon(Icons.share),
                      label: Text(l.duelShare),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('call-link-copy'),
                      onPressed: () => copyCallLink(context, duel),
                      icon: const Icon(Icons.copy),
                      label: Text(l.duelCopy),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          l.duelRoomSummary(
            duel.questionCount,
            duel.secondsPerQuestion,
            _difficultyNames(l, duel.difficulties),
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const ValueKey('cancel-duel'),
          onPressed: onCancel,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Text(l.duelCancelDuel),
        ),
      ],
    );
  }
}

// ---- Countdown -------------------------------------------------------------

class _CountdownView extends StatelessWidget {
  final DuelController controller;
  const _CountdownView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final duel = controller.duel!;
    final seconds = duelCeilSeconds(
      controller.moment?.untilStart ?? Duration.zero,
    );
    const white = TextStyle(color: Colors.white);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.duelCountdownIntro(duel.opponentUsername),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              seconds > 0 ? '$seconds' : l.duelCountdownGo,
              key: const ValueKey('countdown-number'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 96,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.duelNoCorrectionHint,
              textAlign: TextAlign.center,
              style: white,
            ),
            const SizedBox(height: 4),
            Text(
              l.duelQuestionsAndSeconds(
                duel.questionCount,
                duel.secondsPerQuestion,
              ),
              textAlign: TextAlign.center,
              style: white,
            ),
            if (controller.questions == null) ...[
              const SizedBox(height: 12),
              Text(
                l.duelLoadingQuestions,
                textAlign: TextAlign.center,
                style: white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---- Timed game --------------------------------------------------------------

class _GameView extends StatelessWidget {
  final DuelController controller;
  const _GameView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = controller;
    final duel = c.duel!;
    final question = c.currentQuestion;
    final moment = c.moment;

    if (c.questions == null || question == null || moment == null) {
      if (c.questionsError != null) {
        return _Padded(
          child: DuelMessageCard(
            message: duelLiveErrorMessage(l, c.questionsError!),
            actionLabel: l.retry,
            onAction: c.retryQuestions,
          ),
        );
      }
      return _Opening(message: l.duelLoadingQuestions);
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    final index = moment.questionIndex!;
    final answers = question.answers(languageCode);
    final chosen = c.currentAnswer;
    final answered = chosen != null;
    final remaining = moment.questionRemaining;
    final total = Duration(seconds: duel.secondsPerQuestion);
    final progress = (remaining.inMilliseconds / total.inMilliseconds).clamp(
      0.0,
      1.0,
    );
    final urgent = remaining <= const Duration(seconds: 5);
    final isLast = index == duel.questionCount - 1;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              key: const ValueKey('duel-timer'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    size: 18,
                    color: urgent ? Colors.red : Colors.black87,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    duelFormatClock(remaining),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: urgent ? Colors.red : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: const ValueKey('duel-progress'),
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: urgent ? Colors.red : Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (c.showTimeUp)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: Container(
                  key: const ValueKey('time-up'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l.duelTimeUp,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.duelQuestionOf(index + 1, duel.questionCount),
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.themeName(languageCode),
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Text(
                  question.text(languageCode),
                  key: const ValueKey('duel-question-text'),
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < answers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AnswerButton(
                key: ValueKey('duel-answer-${i + 1}'),
                text: answers[i],
                selected: chosen == i + 1,
                dimmed: answered && chosen != i + 1,
                onPressed: answered ? null : () => c.answer(i + 1),
              ),
            ),
          if (answered)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                key: const ValueKey('answer-saved'),
                isLast
                    ? l.duelAnswerSavedLast(
                        duelFormatClock(moment.untilNextWindow),
                      )
                    : l.duelAnswerSaved(
                        duelFormatClock(moment.untilNextWindow),
                      ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Answer button of the game: blue like in solo; once answered, the chosen one
/// is dark blue with a check and the others are grey. Never green or red (F2).
class _AnswerButton extends StatelessWidget {
  final String text;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onPressed;

  const _AnswerButton({
    super.key,
    required this.text,
    required this.selected,
    required this.dimmed,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.blue.shade900
        : dimmed
        ? Colors.grey
        : Colors.blue;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        backgroundColor: color,
        disabledBackgroundColor: color,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (selected) const Icon(Icons.check, color: Colors.white),
        ],
      ),
    );
  }
}

// ---- Sending and waiting for the result ---------------------------------------

class _WaitingView extends StatelessWidget {
  final DuelController controller;
  const _WaitingView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = controller;
    final duel = c.duel!;
    final sending = c.phase == DuelPhase.sending;
    final textTheme = Theme.of(context).textTheme;
    final left = c.deadlineLeft;

    return _Padded(
      child: DuelCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 12),
            Text(
              sending ? l.duelSendingAnswers : l.duelAnswersSent,
              key: const ValueKey('waiting-title'),
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!sending) ...[
              const SizedBox(height: 6),
              Text(
                duel.opponentSubmitted
                    ? l.duelComputingResult
                    : l.duelWaitingOpponentFinish(duel.opponentUsername),
                textAlign: TextAlign.center,
              ),
              if (left != null) ...[
                const SizedBox(height: 10),
                Text(
                  l.duelResultAtLatest(duelFormatClock(left)),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
            if (sending && c.retryingSend) ...[
              const SizedBox(height: 10),
              Text(
                l.duelSendRetry,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ] else if (!sending && c.unstable) ...[
              const SizedBox(height: 10),
              Text(
                l.duelRoomUnstable,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---- Ended without a result --------------------------------------------------------

class _EndedView extends StatelessWidget {
  final DuelController controller;
  const _EndedView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final message = switch (controller.endKind) {
      DuelEndKind.expired => l.duelRoomExpired,
      DuelEndKind.cancelled => l.duelRoomCancelled,
      DuelEndKind.notFound => l.duelErrDuelNotFound,
      _ => l.duelErrDuelClosed,
    };
    return _Padded(
      child: DuelMessageCard(
        icon: Icons.event_busy,
        message: message,
        actionLabel: l.duelBackToDuels,
        onAction: () => Navigator.of(context).pop(),
      ),
    );
  }
}

// ---- Result with review ----------------------------------------------------------------

/// Icon and color of each kind of result, shared with the history.
({IconData icon, Color color}) duelResultStyle(DuelResultKind kind) =>
    switch (kind) {
      DuelResultKind.win || DuelResultKind.winByForfeit => (
        icon: Icons.emoji_events,
        color: Colors.green,
      ),
      DuelResultKind.loss || DuelResultKind.lossByForfeit => (
        icon: Icons.sentiment_dissatisfied,
        color: Colors.red,
      ),
      DuelResultKind.draw => (icon: Icons.handshake, color: Colors.blue),
      DuelResultKind.none => (
        icon: Icons.hourglass_disabled,
        color: Colors.grey,
      ),
    };

class _ResultView extends StatelessWidget {
  final DuelController controller;
  const _ResultView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = controller;
    final duel = c.duel!;
    final result = duel.result ?? const DuelResult();
    final kind = result.kind;
    final style = duelResultStyle(kind);
    final name = duel.opponentUsername;
    final textTheme = Theme.of(context).textTheme;

    final (title, sub) = switch (kind) {
      DuelResultKind.win => (l.duelResultWin, l.duelResultWinSub(name)),
      DuelResultKind.loss => (l.duelResultLoss, l.duelResultLossSub(name)),
      DuelResultKind.draw => (l.duelResultDraw, l.duelResultDrawSub),
      DuelResultKind.winByForfeit => (
        l.duelResultWinForfeit,
        l.duelResultWinForfeitSub(name),
      ),
      DuelResultKind.lossByForfeit => (
        l.duelResultLossForfeit,
        l.duelResultLossForfeitSub,
      ),
      DuelResultKind.none => (l.duelResultNone, l.duelResultNoneSub),
    };
    final hasScores = result.myScore != null && result.opponentScore != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DuelCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.color, size: 36),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                key: const ValueKey('result-title'),
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: style.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(sub, textAlign: TextAlign.center),
              if (hasScores) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ScoreBox(
                        label: l.duelScoreYou,
                        value: l.duelScoreOutOf(
                          result.myScore!,
                          duel.questionCount,
                        ),
                        valueKey: const ValueKey('score-me'),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('—'),
                    ),
                    Expanded(
                      child: _ScoreBox(
                        label: name,
                        value: l.duelScoreOutOf(
                          result.opponentScore!,
                          duel.questionCount,
                        ),
                        valueKey: const ValueKey('score-opponent'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        DuelSectionTitle(l.duelReviewTitle),
        const SizedBox(height: 8),
        if (c.reviewUnavailable)
          Text(
            l.duelReviewUnavailable,
            key: const ValueKey('review-unavailable'),
            style: const TextStyle(color: Colors.white),
          )
        else if (c.reviewQuestions == null)
          const DuelLoading()
        else
          for (var i = 0; i < result.questions.length; i++) ...[
            _ReviewCard(
              number: i + 1,
              line: result.questions[i],
              question: c.reviewQuestions!
                  .where((q) => q.id == result.questions[i].questionId)
                  .firstOrNull,
              opponentName: name,
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 8),
        ElevatedButton(
          key: const ValueKey('back-to-duels'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.duelBackToDuels),
        ),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final String value;
  final Key valueKey;
  const _ScoreBox({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            key: valueKey,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int number;
  final DuelResultQuestion line;
  final DuelQuestion? question;
  final String opponentName;

  const _ReviewCard({
    required this.number,
    required this.line,
    required this.question,
    required this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final q = question;
    final textTheme = Theme.of(context).textTheme;
    final answers = q?.answers(languageCode) ?? const <String>[];

    return DuelCard(
      key: ValueKey('review-$number'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.duelReviewQuestionHeader(
              number,
              q?.themeName(languageCode) ?? '',
            ),
            style: textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
          ),
          if (q != null) ...[
            const SizedBox(height: 4),
            Text(
              q.text(languageCode),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 8),
          for (var i = 0; i < answers.length; i++)
            _ReviewAnswer(
              text: answers[i],
              correct: line.correctAnswer == i + 1,
              mine: line.myAnswer == i + 1,
              theirs: line.opponentAnswer == i + 1,
              opponentName: opponentName,
            ),
          if (line.myAnswer == null) ...[
            const SizedBox(height: 4),
            Text(
              l.duelReviewNoAnswerYou,
              style: textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ],
          if (line.opponentAnswer == null) ...[
            const SizedBox(height: 2),
            Text(
              l.duelReviewNoAnswerOpponent(opponentName),
              style: textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewAnswer extends StatelessWidget {
  final String text;
  final bool correct;
  final bool mine;
  final bool theirs;
  final String opponentName;

  const _ReviewAnswer({
    required this.text,
    required this.correct,
    required this.mine,
    required this.theirs,
    required this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Widget pill(String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: correct ? Colors.green.withValues(alpha: 0.15) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          if (correct || mine || theirs) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (correct)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 14, color: Colors.green[800]),
                      const SizedBox(width: 2),
                      Text(
                        l.duelReviewCorrect,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (mine) pill(l.duelScoreYou),
                if (theirs) pill(opponentName),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
