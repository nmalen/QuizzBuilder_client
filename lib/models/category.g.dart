// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: (json['id'] as num).toInt(),
  nameEn: json['name_en'] as String,
  nameFr: json['name_fr'] as String,
  isActive: json['is_active'] as bool,
  themesCount: (json['themes_count'] as num).toInt(),
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name_en': instance.nameEn,
  'name_fr': instance.nameFr,
  'is_active': instance.isActive,
  'themes_count': instance.themesCount,
};
