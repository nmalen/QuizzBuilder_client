import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';
import '../models/theme.dart' as theme_model;
import '../services/auth_service.dart';
import '../services/credit_store_service.dart';

class QuizzBuilderProvider extends ChangeNotifier {
  QuizzBuilderProvider({required AuthService authService})
    : _creditStoreService = CreditStoreService(authService: authService);

  final CreditStoreService _creditStoreService;
  Set<int>? _lastSyncedCategoryIds;
  final Set<int> _manuallyUnselectedThemeIds = {};
  final Set<int> _entitledThemeIds = {};

  bool _isSyncingThemeAccess = false;
  String? _themeAccessError;
  int _creditBalance = 0;

  bool get isSyncingThemeAccess => _isSyncingThemeAccess;
  String? get themeAccessError => _themeAccessError;
  int get creditBalance => _creditBalance;
  Set<int> get entitledThemeIds => _entitledThemeIds;

  /// Sync selected themes with selected categories (auto-select all themes for selected categories, unselect others)
  void syncThemesWithSelectedCategories(List<theme_model.Theme> allThemes) {
    final activeCategoryIds = selectedCategoryIds;
    if (_lastSyncedCategoryIds == null ||
        !_lastSyncedCategoryIds!.containsAll(activeCategoryIds) ||
        !activeCategoryIds.containsAll(_lastSyncedCategoryIds!)) {
      _manuallyUnselectedThemeIds.clear();
    }
    _lastSyncedCategoryIds = Set<int>.from(activeCategoryIds);

    for (final theme in allThemes) {
      final catId = int.tryParse(theme.category?.toString() ?? '');
      if (catId != null &&
          activeCategoryIds.contains(catId) &&
          !isSelected(theme.id) &&
          isThemeEntitled(theme) &&
          theme.isActive &&
          !_manuallyUnselectedThemeIds.contains(theme.id)) {
        _selectedThemeIds.add(theme.id);
        _selectedThemeQuestionCounts[theme.id] = theme.questionsCount;
        _selectedThemesMeta[theme.id] = theme;
      }
    }

    final toRemove = <int>[];
    for (final themeId in _selectedThemeIds) {
      final theme = _selectedThemesMeta[themeId];
      final catId = int.tryParse(theme?.category?.toString() ?? '');

      if (theme != null &&
          (catId == null || !selectedCategoryIds.contains(catId))) {
        toRemove.add(themeId);
      } else if (theme != null && !isThemeEntitled(theme)) {
        toRemove.add(themeId);
      }
    }

    for (final themeId in toRemove) {
      _selectedThemeIds.remove(themeId);
      _selectedThemeQuestionCounts.remove(themeId);
      _selectedThemesMeta.remove(themeId);
    }
    _saveToPrefs();
    notifyListeners();
  }

  Map<int, theme_model.Theme> get selectedThemesMeta => _selectedThemesMeta;

  Future<void> fetchEntitlements([String? _]) async {
    await refreshThemeAccess();
  }

  Future<void> refreshThemeAccess() async {
    if (_isSyncingThemeAccess) return;

    _isSyncingThemeAccess = true;
    _themeAccessError = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        _creditStoreService.getUnlockedThemeIds(),
        _creditStoreService.getMyCredits(),
      ]);

      _entitledThemeIds
        ..clear()
        ..addAll(results[0] as Set<int>);
      _creditBalance = (results[1] as dynamic).balance as int;
      validateAndCleanupEntitlements(notify: false);
    } catch (e) {
      _themeAccessError = e.toString();
    } finally {
      _isSyncingThemeAccess = false;
      notifyListeners();
    }
  }

  Future<int> unlockThemeWithCredit(theme_model.Theme theme) async {
    final result = await _creditStoreService.unlockThemeWithCredit(theme.id);
    _entitledThemeIds.add(theme.id);
    _creditBalance =
        (result['credits_remaining'] as num?)?.toInt() ??
        (_creditBalance > 0 ? _creditBalance - 1 : 0);
    _themeAccessError = null;
    notifyListeners();
    return _creditBalance;
  }

  bool isThemeEntitled(theme_model.Theme theme) {
    return theme.isFree || _entitledThemeIds.contains(theme.id);
  }

  void validateAndCleanupEntitlements({bool notify = true}) {
    final toRemove = <int>[];
    for (final themeId in _selectedThemeIds) {
      final theme = _selectedThemesMeta[themeId];
      if (theme != null && !isThemeEntitled(theme)) {
        toRemove.add(themeId);
      }
    }

    if (toRemove.isEmpty) return;

    for (final themeId in toRemove) {
      _selectedThemeIds.remove(themeId);
      _selectedThemeQuestionCounts.remove(themeId);
      _selectedThemesMeta.remove(themeId);
    }
    _saveToPrefs();
    if (notify) {
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
          .where(
            (entry) =>
                entry.value.category == category.nameEn ||
                entry.value.category == category.nameFr,
          )
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
      _selectedThemeIds.remove(themeId);
      _selectedThemeQuestionCounts.remove(themeId);
      _selectedThemesMeta.remove(themeId);
      _manuallyUnselectedThemeIds.add(themeId);
    } else {
      if (!isThemeEntitled(theme)) {
        return 'You need to purchase this theme to unlock it';
      }
      _selectedThemeIds.add(themeId);
      _selectedThemeQuestionCounts[themeId] = theme.questionsCount;
      _selectedThemesMeta[themeId] = theme;
      _manuallyUnselectedThemeIds.remove(themeId);
    }
    _saveToPrefs();
    notifyListeners();
    return null;
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
