import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/catalog_provider.dart';
import '../providers/quizz_builder_provider.dart';
import '../providers/language_provider.dart';
import '../models/category.dart';
import '../models/theme.dart' as theme_model;

class QuizzBuilderThemesScreen extends StatefulWidget {
  const QuizzBuilderThemesScreen({super.key});

  @override
  State<QuizzBuilderThemesScreen> createState() => _QuizzBuilderThemesScreenState();
}

class _QuizzBuilderThemesScreenState extends State<QuizzBuilderThemesScreen> {
  @override
  Widget build(BuildContext context) {
    final builder = Provider.of<QuizzBuilderProvider>(context);
    final catalog = Provider.of<CatalogProvider>(context);
    final Category? category = builder.selectedCategory;

    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageProvider>(
          builder: (context, langProvider, _) => Text(category != null ? '${AppLocalizations.of(context)!.selectThemes} • ${langProvider.getLocalizedText(category.nameEn, category.nameFr)}' : AppLocalizations.of(context)!.selectThemes),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (catalog.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (catalog.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.errorLoadingThemes,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    catalog.error ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (category != null) {
                        catalog.loadThemesByCategory(category.id);
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            );
          }

          if (catalog.themes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.noThemes,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: catalog.themes.length,
                  itemBuilder: (context, index) {
                    final theme = catalog.themes[index];
                    final selected = builder.isSelected(theme.id);
                    return _ThemeSelectTile(
                      theme: theme,
                      selected: selected,
                      onChanged: (value) {
                        builder.toggleTheme(theme.id, theme.questionsCount);
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${builder.selectedCount} theme${builder.selectedCount == 1 ? '' : 's'} selected',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: builder.selectedCount == 0
                            ? null
                            : () {
                                // For now, just confirm and go back to Home
                                builder.commitSelections();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Selected ${builder.selectedCount} theme${builder.selectedCount == 1 ? '' : 's'} for your quiz'),
                                  ),
                                );
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                        icon: const Icon(Icons.check),
                        label: Text(AppLocalizations.of(context)!.done),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class _ThemeSelectTile extends StatelessWidget {
  final theme_model.Theme theme;
  final bool selected;
  final ValueChanged<bool?> onChanged;

  const _ThemeSelectTile({
    required this.theme,
    required this.selected,
    required this.onChanged,
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
        title: Consumer<LanguageProvider>(
          builder: (context, langProvider, _) {
            return Text(
              langProvider.getLocalizedText(
                theme.nameEn,
                theme.nameFr,
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            );
          },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${theme.questionsCount} question${theme.questionsCount == 1 ? '' : 's'}',
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.isFree
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    theme.isFree ? 'FREE' : 'PREMIUM',
                    style: TextStyle(
                      color: theme.isFree ? Colors.green : Colors.amber[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
