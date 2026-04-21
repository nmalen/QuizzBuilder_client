import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/theme.dart' as theme_model;
import '../providers/quizz_builder_provider.dart';
import '../providers/catalog_provider.dart';
import '../widgets/gradient_background.dart';
import 'credit_store_screen.dart';
import 'game_screen_solo.dart';
import 'setup_multiplayer_screen.dart';

class SelectedThemesScreen extends StatefulWidget {
  final String gameMode;
  final String? soloGameMode;
  final int? soloQuestionCount;
  final List<String>? soloSelectedDifficulties;

  const SelectedThemesScreen({
    super.key,
    required this.gameMode,
    this.soloGameMode,
    this.soloQuestionCount,
    this.soloSelectedDifficulties,
  });

  @override
  State<SelectedThemesScreen> createState() => _SelectedThemesScreenState();
}

class _SelectedThemesScreenState extends State<SelectedThemesScreen> {
  late List<String> _selectedDifficulties;
  Map<int, int> _filteredQuestionsCount = {};
  int _totalFilteredQuestions = 0;
  bool _loadingCounts = false;
  bool _isUnlocking = false;
  Future<void>? _pendingCountsUpdate;
  String? _activeCountsSignature;
  String? _lastCompletedCountsSignature;
  bool _queuedCountsRefresh = false;
  bool _hasLoadedCounts = false;

  String _unlockableCreditsMessage(BuildContext context, int creditBalance) {
    final l10n = AppLocalizations.of(context)!;
    return l10n.storeCurrentBalance(
      l10n.storeQuestionPackCount(creditBalance),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedDifficulties = widget.soloSelectedDifficulties != null && widget.soloSelectedDifficulties!.isNotEmpty
        ? List<String>.from(widget.soloSelectedDifficulties!)
        : ['easy'];
    _loadSavedDifficulties();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuizzBuilderProvider>(
        context,
        listen: false,
      ).refreshThemeAccess();
      final catalogProvider = Provider.of<CatalogProvider>(
        context,
        listen: false,
      );
      if (catalogProvider.categories.isEmpty && !catalogProvider.isLoading) {
        catalogProvider.loadCategories();
      }
      _refreshThemesForSelectedCategories();
    });
  }

  Future<void> _promptUnlockTheme(theme_model.Theme theme) async {
    if (_isUnlocking) return;
    final builder = Provider.of<QuizzBuilderProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final themeName = theme.getName(
      Localizations.localeOf(context).languageCode,
    );
    final hasCredits = builder.creditBalance > 0;

    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(themeName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.unlockThemePrompt(themeName)),
              const SizedBox(height: 12),
              Text(
                _unlockableCreditsMessage(context, builder.creditBalance),
              ),
              if (!hasCredits) ...[
                const SizedBox(height: 12),
                Text(l10n.unlockThemeNoCredits),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('cancel'),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(hasCredits ? 'unlock' : 'store'),
              child: Text(hasCredits ? l10n.unlockThemeAction : l10n.openStore),
            ),
          ],
        );
      },
    );

    if (!mounted || action == null || action == 'cancel') {
      return;
    }

    if (action == 'store') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CreditStoreScreen()));
      if (mounted) {
        await builder.refreshThemeAccess();
      }
      return;
    }

    setState(() => _isUnlocking = true);
    try {
      final remaining = await builder.unlockThemeWithCredit(theme);
      builder.toggleTheme(theme);
      await _updateFilteredCounts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.unlockThemeSuccess(
              themeName,
              l10n.storeQuestionPackCount(remaining),
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUnlocking = false);
    }
  }

  Future<void> _loadSavedDifficulties() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('selected_difficulties');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        _selectedDifficulties = saved;
      });
      await _updateFilteredCounts();
    }
  }

  Future<void> _saveDifficulties() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_difficulties', _selectedDifficulties);
  }

  String _buildCountsSignature() {
    final builder = Provider.of<QuizzBuilderProvider>(context, listen: false);
    final themeIds = builder.selectedThemes
        .where((t) => t.isActive)
        .map((t) => t.id)
        .toList()
      ..sort();
    final difficulties = _selectedDifficulties
        .map((d) => d.trim().toLowerCase())
        .toList()
      ..sort();
    return '${themeIds.join(',')}|${difficulties.join(',')}';
  }

  // Removed _updateFilteredCounts from didChangeDependencies to prevent infinite loop

  Future<void> _updateFilteredCounts() async {
    final signature = _buildCountsSignature();
    if (_pendingCountsUpdate != null) {
      if (_activeCountsSignature != signature) {
        _queuedCountsRefresh = true;
      }
      return _pendingCountsUpdate!;
    }

    if (_hasLoadedCounts && _lastCompletedCountsSignature == signature) {
      return;
    }

    final future = _runCountsUpdate(signature);
    _pendingCountsUpdate = future;

    try {
      await future;
    } finally {
      _pendingCountsUpdate = null;
      if (_queuedCountsRefresh && mounted) {
        _queuedCountsRefresh = false;
        await _updateFilteredCounts();
      }
    }
  }

  Future<void> _runCountsUpdate(String signature) async {
    _activeCountsSignature = signature;
    setState(() {
      _loadingCounts = true;
    });
    final builder = Provider.of<QuizzBuilderProvider>(context, listen: false);
    final selectedThemes = builder.selectedThemes
        .where((t) => t.isActive)
        .toList();
    final normalizedDifficulties = _selectedDifficulties
        .map((d) => d.trim().toLowerCase())
        .toSet();
    Map<int, int> themeCounts = {};
    int total = 0;
    for (final theme in selectedThemes) {
      if (!builder.isThemeEntitled(theme)) {
        themeCounts[theme.id] = 0;
        continue;
      }
      final filteredCount = theme.getFilteredQuestionCount(normalizedDifficulties);
      themeCounts[theme.id] = filteredCount;
      total += filteredCount;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _filteredQuestionsCount = themeCounts;
      _totalFilteredQuestions = total;
      _loadingCounts = false;
      _hasLoadedCounts = true;
      _lastCompletedCountsSignature = signature;
    });
  }

  Future<void> _refreshThemesForSelectedCategories() async {
    final catalogProvider = Provider.of<CatalogProvider>(
      context,
      listen: false,
    );
    final builder = Provider.of<QuizzBuilderProvider>(context, listen: false);

    if (builder.selectedCategoryIds.isEmpty) {
      await _updateFilteredCounts();
      return;
    }

    await catalogProvider.loadThemesByCategories(
      builder.selectedCategoryIds.toList(),
    );
    builder.syncThemesWithSelectedCategories(List.of(catalogProvider.themes));
    await _updateFilteredCounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectThemes),
        elevation: 0,
      ),
      body: GradientBackground(
        child: Consumer2<QuizzBuilderProvider, CatalogProvider>(
          builder: (context, builder, catalogProvider, _) {
            final selectedCategories = builder.selectedCategories;
            final selectedThemeCount = builder.selectedCount;
            final allCategories = catalogProvider.categories;
            final activeThemes = catalogProvider.themes
                .where((t) => t.isActive)
                .toList();
            final selectedTotalQuestions = builder.selectedThemes
                .where((t) => t.isActive)
                .fold<int>(0, (sum, t) => sum + t.questionsCount);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Categories Section (supports multi-select)
                    Text(
                      AppLocalizations.of(context)!.selectCategory,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allCategories.map((c) {
                        final isSelected = selectedCategories.any(
                          (item) => item.id == c.id,
                        );
                        final highlightColor = Theme.of(context).primaryColor;
                        return FilterChip(
                          selected: isSelected,
                          onSelected: (_) async {
                            builder.toggleCategory(c);
                            await _refreshThemesForSelectedCategories();
                          },
                          avatar: Icon(
                            Icons.category,
                            size: 16,
                            color: isSelected ? highlightColor : null,
                          ),
                          label: Text(
                            c.getName(
                              Localizations.localeOf(context).languageCode,
                            ),
                            style: isSelected
                                ? Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: highlightColor,
                                    fontWeight: FontWeight.bold,
                                  )
                                : null,
                          ),
                          selectedColor: highlightColor.withValues(alpha: 0.12),
                          backgroundColor: Colors.grey[200],
                          side: isSelected
                              ? BorderSide(color: highlightColor)
                              : null,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Sélection des niveaux de difficulté
                    Text(
                      AppLocalizations.of(context)!.selectQuestionsLevels,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ToggleButtons(
                      color: Colors.white70,
                      selectedColor: Colors.white,
                      fillColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.35),
                      borderColor: Colors.white54,
                      selectedBorderColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      textStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      constraints: const BoxConstraints(
                        minHeight: 44,
                        minWidth: 90,
                      ),
                      isSelected: [
                        _selectedDifficulties.contains('easy'),
                        _selectedDifficulties.contains('medium'),
                        _selectedDifficulties.contains('hard'),
                      ],
                      onPressed: (index) async {
                        setState(() {
                          final diff = ['easy', 'medium', 'hard'][index];
                          if (_selectedDifficulties.contains(diff)) {
                            if (_selectedDifficulties.length > 1) {
                              _selectedDifficulties.remove(diff);
                            }
                          } else {
                            _selectedDifficulties.add(diff);
                          }
                        });
                        await _saveDifficulties();
                        await _updateFilteredCounts();
                      },
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            AppLocalizations.of(context)!.easy,
                          ), // TODO: assurez-vous que 'easy' existe dans les ARB
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            AppLocalizations.of(context)!.medium,
                          ), // TODO: assurez-vous que 'medium' existe dans les ARB
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            AppLocalizations.of(context)!.hard,
                          ), // TODO: assurez-vous que 'hard' existe dans les ARB
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Themes Section
                    Text(
                      AppLocalizations.of(context)!.themes,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<QuizzBuilderProvider>(
                      builder: (context, builder, _) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _unlockableCreditsMessage(context, builder.creditBalance),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.tapLockedThemeToUnlock,
                                    ),
                                    if (builder.themeAccessError != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.errorLoadingCredits,
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (builder.isSyncingThemeAccess)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (builder.selectedCategoryIds.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.selectCategory,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (catalogProvider.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (catalogProvider.error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.errorLoadingThemes,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              catalogProvider.error ?? 'Unknown error',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                catalogProvider.loadThemesByCategories(
                                  builder.selectedCategoryIds.toList(),
                                );
                              },
                              child: Text(AppLocalizations.of(context)!.retry),
                            ),
                          ],
                        ),
                      )
                    else if (activeThemes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.noThemesSelected,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bookmark,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$selectedThemeCount ${selectedThemeCount == 1 ? AppLocalizations.of(context)!.theme : AppLocalizations.of(context)!.themes}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.help_center,
                                  color: Theme.of(context).primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                _loadingCounts
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        '$_totalFilteredQuestions/$selectedTotalQuestions',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...activeThemes.map((theme) {
                              final selected = builder.isSelected(theme.id);
                              final canSelect = builder.isThemeEntitled(theme);
                              final trailing = _loadingCounts
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      '${_filteredQuestionsCount[theme.id] ?? 0}/${theme.questionsCount}',
                                    );
                              return _ThemeSelectTile(
                                theme: theme,
                                selected: selected && canSelect,
                                enabled: canSelect,
                                secondary: trailing,
                                onChanged: canSelect
                                    ? (value) async {
                                        final error = builder.toggleTheme(
                                          theme,
                                        );
                                        if (error != null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(error),
                                              backgroundColor: Colors.red[600],
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        await _updateFilteredCounts();
                                      }
                                    : (_) => _promptUnlockTheme(theme),
                              );
                            }),
                          ],
                        ),
                      ),
                    const SizedBox(height: 28),

                    // Action Buttons
                    ElevatedButton(
                      onPressed: selectedThemeCount == 0
                          ? null
                          : () {
                              if (widget.gameMode == 'multiplayer') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const SetupMultiplayerScreen(),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GameScreenSolo(
                                      questionCount: widget.soloQuestionCount ?? 10,
                                      gameMode: widget.soloGameMode ?? 'standard',
                                      difficulties: List<String>.from(
                                        _selectedDifficulties,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.startQuiz,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ThemeSelectTile extends StatelessWidget {
  final theme_model.Theme theme;
  final bool selected;
  final ValueChanged<bool?>? onChanged;
  final bool enabled;
  final Widget? secondary;

  const _ThemeSelectTile({
    required this.theme,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        secondary: secondary,
        title: Text(
          theme.getName(Localizations.localeOf(context).languageCode),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: enabled ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${theme.questionsCount} question${theme.questionsCount == 1 ? '' : 's'}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.isFree
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    theme.isFree
                        ? AppLocalizations.of(context)!.free
                        : AppLocalizations.of(context)!.premium,
                    style: TextStyle(
                      color: theme.isFree
                          ? Colors.green
                          : enabled
                          ? Colors.amber[800]
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (!enabled)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.lock, color: Colors.grey, size: 18),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
