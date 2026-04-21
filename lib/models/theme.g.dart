// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Theme _$ThemeFromJson(Map<String, dynamic> json) => Theme(
  id: (json['id'] as num).toInt(),
  category: json['category'] as String?,
  nameEn: json['name_en'] as String,
  nameFr: json['name_fr'] as String,
  descriptionEn: json['description_en'] as String?,
  descriptionFr: json['description_fr'] as String?,
  isFree: json['is_free'] as bool,
  isActive: json['is_active'] as bool,
  questionsCount: (json['questions_count'] as num).toInt(),
  easyQuestionsCount: (json['easy_questions_count'] as num?)?.toInt() ?? 0,
  mediumQuestionsCount: (json['medium_questions_count'] as num?)?.toInt() ?? 0,
  hardQuestionsCount: (json['hard_questions_count'] as num?)?.toInt() ?? 0,
  sourceUrl: json['source_url'] as String?,
);

Map<String, dynamic> _$ThemeToJson(Theme instance) => <String, dynamic>{
  'id': instance.id,
  'category': instance.category,
  'name_en': instance.nameEn,
  'name_fr': instance.nameFr,
  'description_en': instance.descriptionEn,
  'description_fr': instance.descriptionFr,
  'is_free': instance.isFree,
  'is_active': instance.isActive,
  'questions_count': instance.questionsCount,
  'easy_questions_count': instance.easyQuestionsCount,
  'medium_questions_count': instance.mediumQuestionsCount,
  'hard_questions_count': instance.hardQuestionsCount,
  'source_url': instance.sourceUrl,
};
