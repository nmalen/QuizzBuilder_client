import 'package:json_annotation/json_annotation.dart';

part 'stats.g.dart';

@JsonSerializable()
class CatalogStats {
  @JsonKey(name: 'total_questions')
  final int totalQuestions;
  @JsonKey(name: 'total_themes')
  final int totalThemes;
  @JsonKey(name: 'total_categories')
  final int totalCategories;
  @JsonKey(name: 'total_questions_all')
  final int totalQuestionsAll;
  @JsonKey(name: 'total_themes_all')
  final int totalThemesAll;
  @JsonKey(name: 'total_categories_all')
  final int totalCategoriesAll;
  @JsonKey(name: 'total_questions_purchased')
  final int totalQuestionsPurchased;
  @JsonKey(name: 'total_themes_purchased')
  final int totalThemesPurchased;
  @JsonKey(name: 'total_categories_purchased')
  final int totalCategoriesPurchased;

  CatalogStats({
    required this.totalQuestions,
    required this.totalThemes,
    required this.totalCategories,
    required this.totalQuestionsAll,
    required this.totalThemesAll,
    required this.totalCategoriesAll,
    required this.totalQuestionsPurchased,
    required this.totalThemesPurchased,
    required this.totalCategoriesPurchased,
  });

  factory CatalogStats.fromJson(Map<String, dynamic> json) => _$CatalogStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CatalogStatsToJson(this);
}
