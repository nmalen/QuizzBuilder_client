import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/duel.dart';
import '../../models/duel_live.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/duel_provider.dart';
import '../../services/api_exception.dart';
import '../../utils/duel_clock.dart';
import '../../widgets/gradient_background.dart';
import 'duel_errors.dart';
import 'duel_live_screen.dart';
import 'duel_widgets.dart';

/// Question counts a duel can have (the API refuses anything else).
const List<int> duelQuestionCounts = [5, 10, 15, 20];

/// Difficulties, in the order shown.
const List<String> duelDifficultyOrder = ['easy', 'medium', 'hard'];

/// Pure rules of the choice screen, kept apart so they can be tested.
class DuelChoice {
  const DuelChoice._();

  /// Difficulties that have at least one question among [themes].
  static List<String> availableDifficulties(Iterable<DuelTheme> themes) {
    return [
      for (final d in duelDifficultyOrder)
        if (themes.any((t) => t.countFor(d) > 0)) d,
    ];
  }

  /// Questions that can be drawn from [themes] in [difficulties].
  static int availableQuestions(
    Iterable<DuelTheme> themes,
    Iterable<String> difficulties,
  ) {
    var total = 0;
    for (final theme in themes) {
      for (final d in difficulties) {
        total += theme.countFor(d);
      }
    }
    return total;
  }

  /// Counts the player can pick with [total] questions available.
  static List<int> allowedCounts(int total) =>
      duelQuestionCounts.where((c) => c <= total).toList();
}

/// Challenge one opponent: pick themes, difficulties and a number of
/// questions, then create the duel and land in its waiting room.
class DuelChallengeScreen extends StatefulWidget {
  final Opponent opponent;
  const DuelChallengeScreen({super.key, required this.opponent});

  @override
  State<DuelChallengeScreen> createState() => _DuelChallengeScreenState();
}

class _DuelChallengeScreenState extends State<DuelChallengeScreen>
    with OnlineReloadMixin<DuelChallengeScreen> {
  List<DuelTheme>? _themes;
  bool _loading = true;
  Object? _error;
  bool _creating = false;

  final Set<int> _selectedThemes = {};
  Set<String> _selectedDifficulties = {};
  bool _difficultiesTouched = false;
  int _questionCount = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void onBackOnline() {
    if (_themes == null) _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    if (!Provider.of<ConnectivityProvider>(context, listen: false).isOnline) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final themes = await context.read<DuelProvider>().service.listThemes(
        widget.opponent.id,
      );
      if (!mounted) return;
      setState(() {
        _themes = themes;
        _selectedThemes.removeWhere((id) => !themes.any((t) => t.id == id));
        _loading = false;
        _refreshDifficulties();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
      if (e is ApiException && e.code == DuelErrorCodes.opponentNotFound) {
        _showError(e);
        Navigator.of(context).pop();
      }
    }
  }

  void _showError(Object error) {
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(duelLiveErrorMessage(l, error))));
  }

  List<DuelTheme> get _chosenThemes => [
    for (final t in _themes ?? const <DuelTheme>[])
      if (_selectedThemes.contains(t.id)) t,
  ];

  /// Difficulties offered: those with questions among the ticked themes (all
  /// themes while none is ticked).
  List<String> get _offeredDifficulties {
    final pool = _chosenThemes.isEmpty ? (_themes ?? const []) : _chosenThemes;
    return DuelChoice.availableDifficulties(pool);
  }

  void _refreshDifficulties() {
    final offered = _offeredDifficulties;
    _selectedDifficulties = _difficultiesTouched
        ? _selectedDifficulties.intersection(offered.toSet())
        : offered.toSet();
    _fitQuestionCount();
  }

  /// A count that can no longer be served falls back to the largest one that
  /// can.
  void _fitQuestionCount() {
    if (_chosenThemes.isEmpty) return;
    final allowed = DuelChoice.allowedCounts(
      DuelChoice.availableQuestions(_chosenThemes, _selectedDifficulties),
    );
    if (allowed.isNotEmpty && !allowed.contains(_questionCount)) {
      _questionCount = allowed.last;
    }
  }

  bool get _canStart {
    if (_creating || _chosenThemes.isEmpty || _selectedDifficulties.isEmpty) {
      return false;
    }
    final allowed = DuelChoice.allowedCounts(
      DuelChoice.availableQuestions(_chosenThemes, _selectedDifficulties),
    );
    return allowed.contains(_questionCount);
  }

  Future<void> _start() async {
    if (!_canStart) return;
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final duelProvider = context.read<DuelProvider>();
    setState(() => _creating = true);
    try {
      final duel = await duelProvider.service.createDuel(
        pairId: widget.opponent.id,
        themeIds: _selectedThemes.toList()..sort(),
        difficulties: [
          for (final d in duelDifficultyOrder)
            if (_selectedDifficulties.contains(d)) d,
        ],
        questionCount: _questionCount,
      );
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => DuelLiveScreen(initial: duel)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      if (e is ApiException && e.code == DuelErrorCodes.duelAlreadyOpen) {
        final existing = e.details?['duel'];
        final existingId = existing is Map ? existing['id'] : null;
        if (existingId is int) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l.duelAlreadyOpenOpened(widget.opponent.username)),
            ),
          );
          navigator.pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => DuelLiveScreen(duelId: existingId),
            ),
          );
          return;
        }
      }
      _showError(e);
      if (e is ApiException) {
        if (e.code == DuelErrorCodes.opponentNotFound) {
          navigator.pop();
        } else if (e.code == DuelErrorCodes.themeNotPlayable) {
          _load();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final online = Provider.of<ConnectivityProvider>(context).isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.duelChallengeTitle(widget.opponent.username)),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child: _content(context, l, online)),
              if (online && _themes != null && _themes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const ValueKey('start-challenge'),
                      onPressed: _canStart ? _start : null,
                      child: _creating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.duelStartChallenge),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, AppLocalizations l, bool online) {
    if (!online) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DuelMessageCard(icon: Icons.wifi_off, message: l.duelOfflineMessage),
        ],
      );
    }
    if (_loading && _themes == null) return const DuelLoading();
    if (_error != null && _themes == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DuelMessageCard(
            message: duelLiveErrorMessage(l, _error!),
            actionLabel: l.retry,
            onAction: _load,
          ),
        ],
      );
    }
    final themes = _themes ?? const <DuelTheme>[];
    if (themes.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [DuelMessageCard(message: l.duelNoPlayableThemes)],
      );
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    final byCategory = <int, List<DuelTheme>>{};
    for (final t in themes) {
      byCategory.putIfAbsent(t.categoryId, () => []).add(t);
    }
    final offered = _offeredDifficulties;
    final chosen = _chosenThemes;
    final total = DuelChoice.availableQuestions(chosen, _selectedDifficulties);
    final allowed = chosen.isEmpty
        ? duelQuestionCounts
        : DuelChoice.allowedCounts(total);
    final someGreyed = allowed.length < duelQuestionCounts.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            DuelSectionTitle(l.duelThemesSection),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.duelThemesChosen(_selectedThemes.length),
                key: const ValueKey('themes-chosen'),
                textAlign: TextAlign.end,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final entry in byCategory.entries) ...[
          DuelCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            // The tiles paint their ink on the nearest Material: the white
            // card must not hide it.
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: Text(
                      entry.value.first.categoryName(languageCode),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (final theme in entry.value)
                    CheckboxListTile(
                      key: ValueKey('theme-${theme.id}'),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _selectedThemes.contains(theme.id),
                      title: Text(theme.name(languageCode)),
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          _selectedThemes.add(theme.id);
                        } else {
                          _selectedThemes.remove(theme.id);
                        }
                        _refreshDifficulties();
                      }),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        DuelSectionTitle(l.duelDifficultiesSection),
        const SizedBox(height: 8),
        DuelCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final d in offered)
                FilterChip(
                  key: ValueKey('difficulty-$d'),
                  label: Text(switch (d) {
                    'easy' => l.easy,
                    'medium' => l.medium,
                    _ => l.hard,
                  }),
                  selected: _selectedDifficulties.contains(d),
                  onSelected: (value) => setState(() {
                    _difficultiesTouched = true;
                    if (value) {
                      _selectedDifficulties.add(d);
                    } else {
                      _selectedDifficulties.remove(d);
                    }
                    _fitQuestionCount();
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DuelSectionTitle(l.duelQuestionCountSection),
        const SizedBox(height: 8),
        DuelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final n in duelQuestionCounts)
                    ChoiceChip(
                      key: ValueKey('count-$n'),
                      label: Text('$n'),
                      selected: _questionCount == n,
                      onSelected: allowed.contains(n)
                          ? (_) => setState(() => _questionCount = n)
                          : null,
                    ),
                ],
              ),
              if (someGreyed) ...[
                const SizedBox(height: 8),
                Text(
                  l.duelCountsGreyedHint,
                  key: const ValueKey('counts-hint'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                l.duelSecondsPerQuestion(duelSecondsPerQuestion),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
