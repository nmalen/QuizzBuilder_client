import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/theme.dart' as theme_model;

class QuizzBuilderProvider extends ChangeNotifier {
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
  void toggleTheme(theme_model.Theme theme) {
    final themeId = theme.id;
    if (_selectedThemeIds.contains(themeId)) {
      _selectedThemeIds.remove(themeId);
      _selectedThemeQuestionCounts.remove(themeId);
      _selectedThemesMeta.remove(themeId);
    } else {
      _selectedThemeIds.add(themeId);
      _selectedThemeQuestionCounts[themeId] = theme.questionsCount;
      _selectedThemesMeta[themeId] = theme;
    }
    _saveToPrefs();
    notifyListeners();
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
