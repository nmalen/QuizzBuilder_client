import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/quizz_builder_provider.dart';
import '../providers/catalog_provider.dart';
import 'categories_screen.dart';
import 'setup_solo_screen.dart';
import 'setup_multiplayer_screen.dart';

class SelectedThemesScreen extends StatefulWidget {
  final String gameMode;

  const SelectedThemesScreen({super.key, required this.gameMode});

  @override
  State<SelectedThemesScreen> createState() => _SelectedThemesScreenState();
}

class _SelectedThemesScreenState extends State<SelectedThemesScreen> {
  List<String> _selectedDifficulties = ['easy', 'medium', 'hard'];
  Map<int, int> _filteredQuestionsCount = {};
  int _totalFilteredQuestions = 0;
  bool _loadingCounts = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateFilteredCounts();
  }

  Future<void> _updateFilteredCounts() async {
    setState(() {
      _loadingCounts = true;
    });
    final catalogProvider = Provider.of<CatalogProvider>(context, listen: false);
    final builder = Provider.of<QuizzBuilderProvider>(context, listen: false);
    final selectedThemes = builder.selectedThemes;
    Map<int, int> themeCounts = {};
    int total = 0;
    for (final theme in selectedThemes) {
      final questions = await catalogProvider.loadQuestionsByTheme(theme.id);
      final filtered = questions.where((q) => _selectedDifficulties.contains(q.difficulty)).toList();
      themeCounts[theme.id] = filtered.length;
      total += filtered.length;
    }
    setState(() {
      _filteredQuestionsCount = themeCounts;
      _totalFilteredQuestions = total;
      _loadingCounts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectThemes),
        elevation: 0,
      ),
      body: Consumer2<QuizzBuilderProvider, CatalogProvider>(
        builder: (context, builder, catalogProvider, _) {
          final selectedCategories = builder.selectedCategories;
          final selectedThemeCount = builder.selectedCount;
          final selectedThemes = builder.selectedThemes;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Selected Categories Section (supports multi-select)
                  if (selectedCategories.isNotEmpty) ...[
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
                      children: selectedCategories
                          .map(
                            (c) => Chip(
                              avatar: const Icon(Icons.category, size: 16),
                              label: Text(
                                c.getName(
                                  Localizations.localeOf(context).languageCode,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Sélection des niveaux de difficulté
                  Text(
                    AppLocalizations.of(context)!.selectQuestionsLevels,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ToggleButtons(
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
                      await _updateFilteredCounts();
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(AppLocalizations.of(context)!.easy), // TODO: assurez-vous que 'easy' existe dans les ARB
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(AppLocalizations.of(context)!.medium), // TODO: assurez-vous que 'medium' existe dans les ARB
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(AppLocalizations.of(context)!.hard), // TODO: assurez-vous que 'hard' existe dans les ARB
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Selected Themes Section
                  Text(
                    AppLocalizations.of(context)!.themes,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedThemeCount == 0)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.noThemesSelected,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
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
                            ],
                          ),
                          const SizedBox(height: 12),
                          // List selected themes by name
                          ...selectedThemes.map(
                            (t) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      t.getName(
                                        Localizations.localeOf(
                                          context,
                                        ).languageCode,
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                  _loadingCounts
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text('${_filteredQuestionsCount[t.id] ?? 0}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),

                  // Summary Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withAlpha(80),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.quizSummary,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.bookmark,
                              size: 18,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$selectedThemeCount ${selectedThemeCount == 1 ? AppLocalizations.of(context)!.theme : AppLocalizations.of(context)!.themes}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.help_center,
                              size: 18,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            _loadingCounts
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text('$_totalFilteredQuestions ${_totalFilteredQuestions == 1 ? AppLocalizations.of(context)!.question : AppLocalizations.of(context)!.questions}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoriesScreen(gameMode: widget.gameMode),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.changeSelection,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: selectedThemeCount == 0
                        ? null
                        : () {
                            if (widget.gameMode == 'multiplayer') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SetupMultiplayerScreen(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SetupSoloScreen(),
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
    );
  }
}
