// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogStats _$CatalogStatsFromJson(Map<String, dynamic> json) => CatalogStats(
      totalQuestions: json['total_questions'] as int,
      totalThemes: json['total_themes'] as int,
      totalCategories: json['total_categories'] as int,
    );

Map<String, dynamic> _$CatalogStatsToJson(CatalogStats instance) => <String, dynamic>{
      'total_questions': instance.totalQuestions,
      'total_themes': instance.totalThemes,
      'total_categories': instance.totalCategories,
    };
