import 'package:flutter/material.dart';
import '../models/category.dart';

class QuizzBuilderProvider extends ChangeNotifier {
  Category? _selectedCategory;
  final Set<int> _selectedThemeIds = {};
  final Map<int, int> _selectedThemeQuestionCounts = {};

  Category? get selectedCategory => _selectedCategory;
  Set<int> get selectedThemeIds => _selectedThemeIds;
  int get selectedCategoriesCount => _selectedCategory == null ? 0 : 1;
  int get selectedCount => _selectedThemeIds.length;
  int get selectedQuestionsCount =>
      _selectedThemeQuestionCounts.values.fold(0, (sum, count) => sum + count);

  void startWithCategory(Category category) {
    _selectedCategory = category;
    _selectedThemeIds.clear();
    notifyListeners();
  }

  void toggleTheme(int themeId, int questionsCount) {
    if (_selectedThemeIds.contains(themeId)) {
      _selectedThemeIds.remove(themeId);
      _selectedThemeQuestionCounts.remove(themeId);
    } else {
      _selectedThemeIds.add(themeId);
      _selectedThemeQuestionCounts[themeId] = questionsCount;
    }
    notifyListeners();
  }

  bool isSelected(int themeId) => _selectedThemeIds.contains(themeId);

  /// Force a notification to refresh any listeners (e.g., after navigation)
  void commitSelections() {
    notifyListeners();
  }

  void clear() {
    _selectedCategory = null;
    _selectedThemeIds.clear();
    _selectedThemeQuestionCounts.clear();
    notifyListeners();
  }
}
