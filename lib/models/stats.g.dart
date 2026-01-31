// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogStats _$CatalogStatsFromJson(Map<String, dynamic> json) => CatalogStats(
  totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
  totalThemes: (json['total_themes'] as num?)?.toInt() ?? 0,
  totalCategories: (json['total_categories'] as num?)?.toInt() ?? 0,
  totalQuestionsAll: (json['total_questions_all'] as num?)?.toInt() ??
      (json['total_questions'] as num?)?.toInt() ??
      0,
  totalThemesAll: (json['total_themes_all'] as num?)?.toInt() ??
      (json['total_themes'] as num?)?.toInt() ??
      0,
  totalCategoriesAll: (json['total_categories_all'] as num?)?.toInt() ??
      (json['total_categories'] as num?)?.toInt() ??
      0,
  totalQuestionsPurchased: (json['total_questions_purchased'] as num?)?.toInt() ?? 0,
  totalThemesPurchased: (json['total_themes_purchased'] as num?)?.toInt() ?? 0,
  totalCategoriesPurchased: (json['total_categories_purchased'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CatalogStatsToJson(CatalogStats instance) =>
    <String, dynamic>{
      'total_questions': instance.totalQuestions,
      'total_themes': instance.totalThemes,
      'total_categories': instance.totalCategories,
      'total_questions_all': instance.totalQuestionsAll,
      'total_themes_all': instance.totalThemesAll,
      'total_categories_all': instance.totalCategoriesAll,
      'total_questions_purchased': instance.totalQuestionsPurchased,
      'total_themes_purchased': instance.totalThemesPurchased,
      'total_categories_purchased': instance.totalCategoriesPurchased,
    };
