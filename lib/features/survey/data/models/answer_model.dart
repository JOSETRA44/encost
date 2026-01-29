import 'dart:convert';
import '../../domain/entities/survey_response.dart';

/// Modelo de datos - Answer (Manual)
class AnswerModel {
  final String questionId;
  final dynamic value;
  final DateTime answeredAt;

  AnswerModel({
    required this.questionId,
    required this.value,
    required this.answeredAt,
  });

  Answer toEntity() {
    return Answer(
      questionId: questionId,
      value: value,
      answeredAt: answeredAt,
    );
  }

  factory AnswerModel.fromEntity(Answer entity) {
    return AnswerModel(
      questionId: entity.questionId,
      value: entity.value,
      answeredAt: entity.answeredAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'value': value is List
          ? json.encode(value)
          : value.toString(),
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  factory AnswerModel.fromMap(Map<String, dynamic> map) {
    dynamic parsedValue = map['value'];
    
    // Intentar decodificar si es una lista JSON
    if (parsedValue is String && parsedValue.startsWith('[')) {
      try {
        parsedValue = json.decode(parsedValue);
      } catch (e) {
        // Mantener como string si falla
      }
    }
    
    return AnswerModel(
      questionId: map['questionId'] as String,
      value: parsedValue,
      answeredAt: DateTime.parse(map['answeredAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'value': value,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      questionId: json['questionId'] as String,
      value: json['value'],
      answeredAt: DateTime.parse(json['answeredAt'] as String),
    );
  }
}
