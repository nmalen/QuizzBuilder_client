import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {
  final String id;
  @JsonKey(name: 'name_en')
  final String nameEn;
  @JsonKey(name: 'name_fr')
  final String nameFr;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'themes_count')
  final int themesCount;

  Category({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.isActive,
    required this.themesCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  String getName(String languageCode) {
    return languageCode == 'fr' ? nameFr : nameEn;
  }
}
