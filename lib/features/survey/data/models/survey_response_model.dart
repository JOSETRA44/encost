import 'dart:convert';
import '../../domain/entities/survey_response.dart';
import 'answer_model.dart';

/// Modelo de datos - SurveyResponse (Manual - Para SQLite)
class SurveyResponseModel {
  final String id;
  final String surveyId;
  final String surveyVersion;
  final List<AnswerModel> answers;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool isCompleted;

  SurveyResponseModel({
    required this.id,
    required this.surveyId,
    required this.surveyVersion,
    required this.answers,
    required this.startedAt,
    this.completedAt,
    required this.isCompleted,
  });

  SurveyResponse toEntity() {
    return SurveyResponse(
      id: id,
      surveyId: surveyId,
      surveyVersion: surveyVersion,
      answers: answers.map((a) => a.toEntity()).toList(),
      startedAt: startedAt,
      completedAt: completedAt,
      isCompleted: isCompleted,
    );
  }

  factory SurveyResponseModel.fromEntity(SurveyResponse entity) {
    return SurveyResponseModel(
      id: entity.id,
      surveyId: entity.surveyId,
      surveyVersion: entity.surveyVersion,
      answers: entity.answers.map((a) => AnswerModel.fromEntity(a)).toList(),
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      isCompleted: entity.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surveyId': surveyId,
      'surveyVersion': surveyVersion,
      'answers': json.encode(answers.map((a) => a.toJson()).toList()),
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory SurveyResponseModel.fromMap(Map<String, dynamic> map) {
    return SurveyResponseModel(
      id: map['id'] as String,
      surveyId: map['surveyId'] as String,
      surveyVersion: map['surveyVersion'] as String,
      answers: (json.decode(map['answers']) as List)
          .map((a) => AnswerModel.fromJson(a))
          .toList(),
      startedAt: DateTime.parse(map['startedAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      isCompleted: (map['isCompleted'] as int) == 1,
    );
  }
}
