import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/theme.dart' as theme_model;
import '../models/stats.dart';
import '../models/question.dart';
import '../services/catalog_service.dart';
import '../services/auth_service.dart';

class CatalogProvider extends ChangeNotifier {
  final CatalogService _catalogService;

  List<Category> _categories = [];
  List<theme_model.Theme> _themes = [];
  Category? _selectedCategory;
  theme_model.Theme? _selectedTheme;
  bool _isLoading = false;
  bool _isStatsLoading = false;
  String? _error;
  String? _statsError;
  CatalogStats? _stats;

  CatalogProvider({required AuthService authService})
    : _catalogService = CatalogService(authService: authService);

  // Getters
  List<Category> get categories => _categories;
  List<theme_model.Theme> get themes => _themes;
  Category? get selectedCategory => _selectedCategory;
  theme_model.Theme? get selectedTheme => _selectedTheme;
  bool get isLoading => _isLoading;
  bool get isStatsLoading => _isStatsLoading;
  String? get error => _error;
  String? get statsError => _statsError;
  CatalogStats? get stats => _stats;

  /// Load all categories
  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _catalogService.getCategories();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _categories = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load themes for selected category
  Future<void> loadThemesByCategory(int categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final allThemes = await _catalogService.getThemesByCategory(categoryId);
      _themes = allThemes.where((t) => t.isActive).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _themes = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load themes for multiple categories and aggregate results
  Future<void> loadThemesByCategories(List<int> categoryIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Set<int> seen = {};
      final List<theme_model.Theme> all = [];
      for (final id in categoryIds) {
        final items = await _catalogService.getThemesByCategory(id);
        for (final t in items) {
          if (!seen.contains(t.id) && t.isActive) {
            seen.add(t.id);
            all.add(t);
          }
        }
      }
      _themes = all;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _themes = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Select a category
  void selectCategory(Category category) {
    _selectedCategory = category;
    _selectedTheme = null;
    notifyListeners();
  }

  /// Select a theme
  void selectTheme(theme_model.Theme theme) {
    _selectedTheme = theme;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedCategory = null;
    _selectedTheme = null;
    notifyListeners();
  }

  /// Load catalog statistics
  Future<void> loadStatistics() async {
    _isStatsLoading = true;
    _statsError = null;
    notifyListeners();

    try {
      _stats = await _catalogService.getStatistics();
      _statsError = null;
    } catch (e) {
      _statsError = e.toString();
      _stats = null;
    }

    _isStatsLoading = false;
    notifyListeners();
  }

  /// Load questions for a specific theme
  Future<List<Question>> loadQuestionsByTheme(int themeId) async {
    try {
      final questions = await _catalogService.getQuestionsByTheme(themeId);
      return questions;
    } catch (e) {
      throw Exception('Failed to load questions: $e');
    }
  }
}
