import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/theme.dart' as theme_model;

class QuizzBuilderProvider extends ChangeNotifier {
      Set<int>? _lastSyncedCategoryIds;
    // Track themes manually unselected by the user (session only)
    final Set<int> _manuallyUnselectedThemeIds = {};
  /// Sync selected themes with selected categories (auto-select all themes for selected categories, unselect others)
  void syncThemesWithSelectedCategories(List<theme_model.Theme> allThemes) {
        // Clear manual unselections if categories changed
        final currentCategoryIds = this.selectedCategoryIds;
        if (_lastSyncedCategoryIds == null || !_lastSyncedCategoryIds!.containsAll(currentCategoryIds) || !_lastSyncedCategoryIds!.containsAll(currentCategoryIds)) {
          _manuallyUnselectedThemeIds.clear();
        }
        _lastSyncedCategoryIds = Set<int>.from(currentCategoryIds);
    final selectedCategoryIds = this.selectedCategoryIds;
    debugPrint('SYNC THEMES:');
    debugPrint('Selected category IDs: ${selectedCategoryIds.join(', ')}');
    debugPrint('All themes:');
    for (final theme in allThemes) {
      debugPrint('  Theme id=${theme.id}, nameEn=${theme.nameEn}, nameFr=${theme.nameFr}, category=${theme.category}');
    }
    // Add all themes for selected categories
    for (final theme in allThemes) {
      final catId = int.tryParse(theme.category?.toString() ?? '');
      if (catId != null && selectedCategoryIds.contains(catId) && !isSelected(theme.id) && isThemeEntitled(theme) && theme.isActive && !_manuallyUnselectedThemeIds.contains(theme.id)) {
        debugPrint('  SELECT theme id=${theme.id} (${theme.nameEn}) for category=$catId');
        _selectedThemeIds.add(theme.id);
        _selectedThemeQuestionCounts[theme.id] = theme.questionsCount;
        _selectedThemesMeta[theme.id] = theme;
      }
    }
    // Remove themes from unselected categories or themes no longer entitled
    final toRemove = <int>[];
    for (final themeId in _selectedThemeIds) {
      final theme = _selectedThemesMeta[themeId];
      final catId = int.tryParse(theme?.category?.toString() ?? '');
      
      // Remove if category is no longer selected
      if (theme != null && (catId == null || !selectedCategoryIds.contains(catId))) {
        debugPrint('  UNSELECT theme id=${theme.id} (${theme.nameEn}) for category=$catId (category not selected)');
        toRemove.add(themeId);
      }
      // Remove if user no longer has entitlement (e.g., theme changed from free to paid)
      else if (theme != null && !isThemeEntitled(theme)) {
        debugPrint('  UNSELECT theme id=${theme.id} (${theme.nameEn}) (no longer entitled)');
        toRemove.add(themeId);
      }
    }
    for (final themeId in toRemove) {
      _selectedThemeIds.remove(themeId);
      _selectedThemeQuestionCounts.remove(themeId);
      _selectedThemesMeta.remove(themeId);
    }
    debugPrint('Selected theme IDs after sync: ${_selectedThemeIds.join(', ')}');
    _saveToPrefs();
    notifyListeners();
  }
      Map<int, theme_model.Theme> get selectedThemesMeta => _selectedThemesMeta;
    // Entitled (unlocked) paid theme IDs
    final Set<int> _entitledThemeIds = {};
    Set<int> get entitledThemeIds => _entitledThemeIds;

    // Fetch entitlements from backend (replace with real HTTP call)
    Future<void> fetchEntitlements(String? authToken) async {
      // TODO: Replace with real HTTP call using your auth header logic as needed
      // Example using http package:
      // final response = await http.get(Uri.parse('https://your.api/api/v1/entitlements/'), headers: {'Authorization': 'Bearer $authToken'});
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   _entitledThemeIds.clear();
      //   for (final item in data) {
      //     _entitledThemeIds.add(item['theme']);
      //   }
      //   notifyListeners();
      // }
      // For now, simulate: _entitledThemeIds = {1, 2, 3};
      // Remove this simulation in production:
      _entitledThemeIds.clear();
      _entitledThemeIds.addAll([1, 2, 3]);
      notifyListeners();
    }

    bool isThemeEntitled(theme_model.Theme theme) {
      return theme.isFree || _entitledThemeIds.contains(theme.id);
    }

    /// Validate and clean up selected themes based on current entitlements
    /// Removes any themes that user no longer has access to (e.g., changed from free to paid)
    void validateAndCleanupEntitlements() {
      debugPrint('VALIDATE ENTITLEMENTS:');
      final toRemove = <int>[];
      for (final themeId in _selectedThemeIds) {
        final theme = _selectedThemesMeta[themeId];
        if (theme != null && !isThemeEntitled(theme)) {
          debugPrint('  REMOVE theme id=${theme.id} (${theme.nameEn}) - user no longer entitled');
          toRemove.add(themeId);
        }
      }
      if (toRemove.isNotEmpty) {
        for (final themeId in toRemove) {
          _selectedThemeIds.remove(themeId);
          _selectedThemeQuestionCounts.remove(themeId);
          _selectedThemesMeta.remove(themeId);
        }
        _saveToPrefs();
        notifyListeners();
      }
    }

  // Categories (multi-select)
  final Set<int> _selectedCategoryIds = {};
  final Map<int, Category> _selectedCategoriesMeta = {};

  // Themes (multi-select)
  final Set<int> _selectedThemeIds = {};
  final Map<int, int> _selectedThemeQuestionCounts = {};
  final Map<int, theme_model.Theme> _selectedThemesMeta = {};

  // Getters
  Set<int> get selectedCategoryIds => _selectedCategoryIds;
  List<Category> get selectedCategories => _selectedCategoryIds
      .map((id) => _selectedCategoriesMeta[id])
      .whereType<Category>()
      .toList(growable: false);
  int get selectedCategoriesCount => _selectedCategoryIds.length;

  Set<int> get selectedThemeIds => _selectedThemeIds;
    List<theme_model.Theme> get selectedThemes => _selectedThemeIds
      .map((id) => _selectedThemesMeta[id])
      .whereType<theme_model.Theme>()
      .where((t) => t.isActive)
      .toList(growable: false);
  int get selectedCount => _selectedThemeIds.length;
  int get selectedQuestionsCount =>
      _selectedThemeQuestionCounts.values.fold(0, (sum, count) => sum + count);

  // Initialization from persistent storage
  Future<void> initialize() async {
    await _loadFromPrefs();
    notifyListeners();
  }

  // Category selection
  void toggleCategory(Category category) {
    if (_selectedCategoryIds.contains(category.id)) {
      _selectedCategoryIds.remove(category.id);
      _selectedCategoriesMeta.remove(category.id);

      // Unselect all themes belonging to this category
      final themeIdsToRemove = _selectedThemesMeta.entries
          .where((entry) => entry.value.category == category.nameEn || entry.value.category == category.nameFr)
          .map((entry) => entry.key)
          .toList();
      for (final themeId in themeIdsToRemove) {
        _selectedThemeIds.remove(themeId);
        _selectedThemeQuestionCounts.remove(themeId);
        _selectedThemesMeta.remove(themeId);
      }
    } else {
      _selectedCategoryIds.add(category.id);
      _selectedCategoriesMeta[category.id] = category;
    }
    _saveToPrefs();
    notifyListeners();
  }

  bool isCategorySelected(int categoryId) =>
      _selectedCategoryIds.contains(categoryId);

  void clearCategories() {
    _selectedCategoryIds.clear();
    _selectedCategoriesMeta.clear();
    _saveToPrefs();
    notifyListeners();
  }

  // Theme selection
  /// Toggle theme selection. Returns null if successful, or an error message if theme cannot be selected.
  String? toggleTheme(theme_model.Theme theme) {
    final themeId = theme.id;
    if (!theme.isActive) return 'Theme is not active';
    
    if (_selectedThemeIds.contains(themeId)) {
      // Unselect the theme
      _selectedThemeIds.remove(themeId);
      _selectedThemeQuestionCounts.remove(themeId);
      _selectedThemesMeta.remove(themeId);
      _manuallyUnselectedThemeIds.add(themeId);
    } else {
      // Try to select the theme - check entitlement for paid themes
      if (!isThemeEntitled(theme)) {
        // User doesn't have access to this paid theme
        return 'You need to purchase this theme to unlock it';
      }
      _selectedThemeIds.add(themeId);
      _selectedThemeQuestionCounts[themeId] = theme.questionsCount;
      _selectedThemesMeta[themeId] = theme;
      _manuallyUnselectedThemeIds.remove(themeId);
    }
    _saveToPrefs();
    notifyListeners();
    return null; // Success
  }

  bool isSelected(int themeId) => _selectedThemeIds.contains(themeId);

  /// Force a notification to refresh any listeners (e.g., after navigation)
  void commitSelections() {
    _saveToPrefs();
    notifyListeners();
  }

  void clearThemes() {
    _selectedThemeIds.clear();
    _selectedThemeQuestionCounts.clear();
    _selectedThemesMeta.clear();
    _saveToPrefs();
    notifyListeners();
  }

  void clearAll() {
    clearCategories();
    clearThemes();
  }

  // Persistence
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Categories
    prefs.setStringList(
      'qb_selected_category_ids',
      _selectedCategoryIds.map((e) => e.toString()).toList(),
    );
    // Save minimal category meta (names) for quick display
    final categoriesMeta = _selectedCategoriesMeta.map(
      (key, value) => MapEntry(key.toString(), {
        'nameEn': value.nameEn,
        'nameFr': value.nameFr,
      }),
    );
    prefs.setString('qb_selected_categories_meta', jsonEncode(categoriesMeta));

    // Themes
    prefs.setStringList(
      'qb_selected_theme_ids',
      _selectedThemeIds.map((e) => e.toString()).toList(),
    );
    final themesMeta = _selectedThemesMeta.map(
      (key, value) => MapEntry(key.toString(), {
        'nameEn': value.nameEn,
        'nameFr': value.nameFr,
        'questionsCount': value.questionsCount,
        'isFree': value.isFree,
        'isActive': value.isActive,
        'category': value.category,
      }),
    );
    prefs.setString('qb_selected_themes_meta', jsonEncode(themesMeta));
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Categories
    final catIds = prefs.getStringList('qb_selected_category_ids') ?? [];
    _selectedCategoryIds
      ..clear()
      ..addAll(catIds.map((e) => int.tryParse(e)).whereType<int>());
    final categoriesMetaStr = prefs.getString('qb_selected_categories_meta');
    _selectedCategoriesMeta.clear();
    if (categoriesMetaStr != null && categoriesMetaStr.isNotEmpty) {
      final map = jsonDecode(categoriesMetaStr) as Map<String, dynamic>;
      map.forEach((key, value) {
        final id = int.tryParse(key);
        if (id != null && value is Map) {
          _selectedCategoriesMeta[id] = Category(
            id: id,
            nameEn: value['nameEn'] as String? ?? '',
            nameFr: value['nameFr'] as String? ?? '',
            isActive: true,
            themesCount: 0,
          );
        }
      });
    }

    // Themes
    final themeIds = prefs.getStringList('qb_selected_theme_ids') ?? [];
    _selectedThemeIds
      ..clear()
      ..addAll(themeIds.map((e) => int.tryParse(e)).whereType<int>());
    final themesMetaStr = prefs.getString('qb_selected_themes_meta');
    _selectedThemesMeta.clear();
    _selectedThemeQuestionCounts.clear();
    if (themesMetaStr != null && themesMetaStr.isNotEmpty) {
      final map = jsonDecode(themesMetaStr) as Map<String, dynamic>;
      map.forEach((key, value) {
        final id = int.tryParse(key);
        if (id != null && value is Map) {
          final questions = (value['questionsCount'] as num?)?.toInt() ?? 0;
          _selectedThemeQuestionCounts[id] = questions;
          _selectedThemesMeta[id] = theme_model.Theme(
            id: id,
            category: value['category'] as String?,
            nameEn: value['nameEn'] as String? ?? '',
            nameFr: value['nameFr'] as String? ?? '',
            descriptionEn: null,
            descriptionFr: null,
            isFree: (value['isFree'] as bool?) ?? true,
            isActive: (value['isActive'] as bool?) ?? true,
            questionsCount: questions,
            sourceUrl: null,
          );
        }
      });
    }
  }
}
