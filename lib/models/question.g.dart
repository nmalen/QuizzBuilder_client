// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Question _$QuestionFromJson(Map<String, dynamic> json) => Question(
  id: (json['id'] as num).toInt(),
  theme: (json['theme'] as num).toInt(),
  questionEn: json['question_en'] as String,
  questionFr: json['question_fr'] as String,
  answer1En: json['answer_1_en'] as String,
  answer1Fr: json['answer_1_fr'] as String,
  answer2En: json['answer_2_en'] as String,
  answer2Fr: json['answer_2_fr'] as String,
  answer3En: json['answer_3_en'] as String,
  answer3Fr: json['answer_3_fr'] as String,
  answer4En: json['answer_4_en'] as String,
  answer4Fr: json['answer_4_fr'] as String,
  correctAnswer: (json['correct_answer'] as num).toInt(),
  difficulty: json['difficulty'] as String,
  verificationReason: json['verification_reason'] as String?,
  sourceUrl: json['source_url'] as String?,
);

Map<String, dynamic> _$QuestionToJson(Question instance) => <String, dynamic>{
  'id': instance.id,
  'theme': instance.theme,
  'question_en': instance.questionEn,
  'question_fr': instance.questionFr,
  'answer_1_en': instance.answer1En,
  'answer_1_fr': instance.answer1Fr,
  'answer_2_en': instance.answer2En,
  'answer_2_fr': instance.answer2Fr,
  'answer_3_en': instance.answer3En,
  'answer_3_fr': instance.answer3Fr,
  'answer_4_en': instance.answer4En,
  'answer_4_fr': instance.answer4Fr,
  'correct_answer': instance.correctAnswer,
  'difficulty': instance.difficulty,
  'verification_reason': instance.verificationReason,
  'source_url': instance.sourceUrl,
};
