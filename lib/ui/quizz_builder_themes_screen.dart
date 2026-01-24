import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/catalog_provider.dart';
import '../providers/quizz_builder_provider.dart';
// Removed unused imports after multi-category support
import '../models/theme.dart' as theme_model;
import '../providers/language_provider.dart';
import 'selected_themes_screen.dart';

class QuizzBuilderThemesScreen extends StatefulWidget {
  final String gameMode;

  const QuizzBuilderThemesScreen({super.key, required this.gameMode});

  @override
  State<QuizzBuilderThemesScreen> createState() =>
      _QuizzBuilderThemesScreenState();
}

class _QuizzBuilderThemesScreenState extends State<QuizzBuilderThemesScreen> {
  @override
  void initState() {
    super.initState();
    // Validate and clean up any selected themes that user no longer has access to
    // (e.g., themes changed from free to paid by admin after initial selection)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuizzBuilderProvider>(context, listen: false)
          .validateAndCleanupEntitlements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final builder = Provider.of<QuizzBuilderProvider>(context);
    final catalog = Provider.of<CatalogProvider>(context);

    // Auto-select themes for selected categories only once after themes are loaded
    // Auto-selection logic moved to categories_screen.dart before navigation
    // Ensure themes for selected categories are loaded
    if (!catalog.isLoading &&
        catalog.themes.isEmpty &&
        builder.selectedCategoryIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<CatalogProvider>(
          context,
          listen: false,
        ).loadThemesByCategories(builder.selectedCategoryIds.toList());
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          builder.selectedCategoriesCount > 1
              ? '${AppLocalizations.of(context)!.selectThemes} • ${builder.selectedCategoriesCount} categories'
              : AppLocalizations.of(context)!.selectThemes,
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.errorLoadingThemes,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    catalog.error ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: builder.selectedCategoryIds.isEmpty
                        ? null
                        : () {
                            catalog.loadThemesByCategories(
                              builder.selectedCategoryIds.toList(),
                            );
                          },
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            );
          }

          if (catalog.themes.isEmpty) {
            return const Center(child: Text('No themes available'));
          }

          final activeThemes = catalog.themes.where((t) => t.isActive).toList();
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activeThemes.length,
                  itemBuilder: (context, index) {
                    final theme = activeThemes[index];
                    final selected = builder.isSelected(theme.id);
                    final canSelect = builder.isThemeEntitled(theme);
                    return _ThemeSelectTile(
                      theme: theme,
                      selected: selected && canSelect,
                      onChanged: canSelect
                          ? (value) {
                              debugPrint('USER ${value == true ? 'CHECKED' : 'UNCHECKED'} theme id=${theme.id} (${theme.nameEn}), category=${theme.category}');
                              final error = builder.toggleTheme(theme);
                              if (error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor: Colors.red[600],
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          : null,
                      enabled: canSelect,
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
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
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
                                builder.commitSelections();
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SelectedThemesScreen(gameMode: widget.gameMode),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.check),
                        label: Text(AppLocalizations.of(context)!.done),
                      ),
                    ],
                  ),
                ),
              ),
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
  final ValueChanged<bool?>? onChanged;
  final bool enabled;

  const _ThemeSelectTile({
    required this.theme,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
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
        onChanged: enabled ? onChanged : null,
        controlAffinity: ListTileControlAffinity.leading,
        title: Consumer<LanguageProvider>(
          builder: (context, langProvider, _) {
            return Text(
              langProvider.getLocalizedText(theme.nameEn, theme.nameFr),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: enabled ? null : Colors.grey),
            );
          },
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
                    theme.isFree ? 'FREE' : 'PREMIUM',
                    style: TextStyle(
                      color: theme.isFree ? Colors.green : enabled ? Colors.amber[800] : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (!enabled)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
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
