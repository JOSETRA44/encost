import 'dart:convert';
import '../../domain/entities/question_validation.dart';

/// Modelo de datos - QuestionValidation (Manual)
class QuestionValidationModel {
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final num? min;
  final num? max;
  final int? decimals;
  final int? minSelections;
  final int? maxSelections;
  final num? step;

  QuestionValidationModel({
    this.minLength,
    this.maxLength,
    this.pattern,
    this.min,
    this.max,
    this.decimals,
    this.minSelections,
    this.maxSelections,
    this.step,
  });

  QuestionValidation toEntity() {
    return QuestionValidation(
      minLength: minLength,
      maxLength: maxLength,
      pattern: pattern,
      min: min,
      max: max,
      decimals: decimals,
      minSelections: minSelections,
      maxSelections: maxSelections,
      step: step,
    );
  }

  factory QuestionValidationModel.fromEntity(QuestionValidation entity) {
    return QuestionValidationModel(
      minLength: entity.minLength,
      maxLength: entity.maxLength,
      pattern: entity.pattern,
      min: entity.min,
      max: entity.max,
      decimals: entity.decimals,
      minSelections: entity.minSelections,
      maxSelections: entity.maxSelections,
      step: entity.step,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minLength': minLength,
      'maxLength': maxLength,
      'pattern': pattern,
      'min': min,
      'max': max,
      'decimals': decimals,
      'minSelections': minSelections,
      'maxSelections': maxSelections,
      'step': step,
    };
  }

  factory QuestionValidationModel.fromMap(Map<String, dynamic> map) {
    return QuestionValidationModel(
      minLength: map['minLength'] as int?,
      maxLength: map['maxLength'] as int?,
      pattern: map['pattern'] as String?,
      min: map['min'] as num?,
      max: map['max'] as num?,
      decimals: map['decimals'] as int?,
      minSelections: map['minSelections'] as int?,
      maxSelections: map['maxSelections'] as int?,
      step: map['step'] as num?,
    );
  }

  factory QuestionValidationModel.fromJson(Map<String, dynamic> json) =>
      QuestionValidationModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  String toJsonString() => json.encode(toMap());

  factory QuestionValidationModel.fromJsonString(String source) =>
      QuestionValidationModel.fromMap(json.decode(source));
}
