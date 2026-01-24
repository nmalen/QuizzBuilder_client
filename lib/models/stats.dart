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

  CatalogStats({
    required this.totalQuestions,
    required this.totalThemes,
    required this.totalCategories,
  });

  factory CatalogStats.fromJson(Map<String, dynamic> json) => _$CatalogStatsFromJson(json);
  Map<String, dynamic> toJson() => _$CatalogStatsToJson(this);
}
