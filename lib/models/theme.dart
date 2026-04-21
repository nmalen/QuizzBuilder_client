import 'package:json_annotation/json_annotation.dart';

part 'theme.g.dart';

@JsonSerializable()
class Theme {
  final int id;
  final String? category;
  @JsonKey(name: 'name_en')
  final String nameEn;
  @JsonKey(name: 'name_fr')
  final String nameFr;
  @JsonKey(name: 'description_en')
  final String? descriptionEn;
  @JsonKey(name: 'description_fr')
  final String? descriptionFr;
  @JsonKey(name: 'is_free')
  final bool isFree;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'questions_count')
  final int questionsCount;
  @JsonKey(name: 'easy_questions_count')
  final int easyQuestionsCount;
  @JsonKey(name: 'medium_questions_count')
  final int mediumQuestionsCount;
  @JsonKey(name: 'hard_questions_count')
  final int hardQuestionsCount;
  @JsonKey(name: 'source_url')
  final String? sourceUrl;

  Theme({
    required this.id,
    required this.category,
    required this.nameEn,
    required this.nameFr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.isFree,
    required this.isActive,
    required this.questionsCount,
    this.easyQuestionsCount = 0,
    this.mediumQuestionsCount = 0,
    this.hardQuestionsCount = 0,
    required this.sourceUrl,
  });

  factory Theme.fromJson(Map<String, dynamic> json) => _$ThemeFromJson(json);

  Map<String, dynamic> toJson() => _$ThemeToJson(this);

  String getName(String languageCode) {
    return languageCode == 'fr' ? nameFr : nameEn;
  }

  String? getDescription(String languageCode) {
    return languageCode == 'fr' ? descriptionFr : descriptionEn;
  }

  int getFilteredQuestionCount(Iterable<String> difficulties) {
    final normalized = difficulties
        .map((difficulty) => difficulty.trim().toLowerCase())
        .toSet();

    var total = 0;
    if (normalized.contains('easy')) {
      total += easyQuestionsCount;
    }
    if (normalized.contains('medium')) {
      total += mediumQuestionsCount;
    }
    if (normalized.contains('hard')) {
      total += hardQuestionsCount;
    }
    return total;
  }
}
