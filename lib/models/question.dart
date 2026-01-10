import 'package:json_annotation/json_annotation.dart';

part 'question.g.dart';

@JsonSerializable()
class Question {
  final String id;
  final String theme;
  @JsonKey(name: 'question_en')
  final String questionEn;
  @JsonKey(name: 'question_fr')
  final String questionFr;
  @JsonKey(name: 'answer_1_en')
  final String answer1En;
  @JsonKey(name: 'answer_1_fr')
  final String answer1Fr;
  @JsonKey(name: 'answer_2_en')
  final String answer2En;
  @JsonKey(name: 'answer_2_fr')
  final String answer2Fr;
  @JsonKey(name: 'answer_3_en')
  final String answer3En;
  @JsonKey(name: 'answer_3_fr')
  final String answer3Fr;
  @JsonKey(name: 'answer_4_en')
  final String answer4En;
  @JsonKey(name: 'answer_4_fr')
  final String answer4Fr;
  @JsonKey(name: 'correct_answer')
  final int correctAnswer; // 1-4
  final String difficulty; // easy, medium, hard
  @JsonKey(name: 'verification_reason')
  final String? verificationReason;
  @JsonKey(name: 'source_url')
  final String? sourceUrl;

  Question({
    required this.id,
    required this.theme,
    required this.questionEn,
    required this.questionFr,
    required this.answer1En,
    required this.answer1Fr,
    required this.answer2En,
    required this.answer2Fr,
    required this.answer3En,
    required this.answer3Fr,
    required this.answer4En,
    required this.answer4Fr,
    required this.correctAnswer,
    required this.difficulty,
    required this.verificationReason,
    required this.sourceUrl,
  });

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionToJson(this);

  String getQuestion(String languageCode) {
    return languageCode == 'fr' ? questionFr : questionEn;
  }

  List<String> getAnswers(String languageCode) {
    return languageCode == 'fr'
        ? [answer1Fr, answer2Fr, answer3Fr, answer4Fr]
        : [answer1En, answer2En, answer3En, answer4En];
  }

  String getCorrectAnswer(String languageCode) {
    final answers = getAnswers(languageCode);
    return answers[correctAnswer - 1];
  }
}
