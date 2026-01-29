import 'dart:convert';
import '../../domain/entities/question.dart';
import '../../domain/entities/question_type.dart';
import 'question_option_model.dart';
import 'question_validation_model.dart';

/// Modelo de datos - Question (Manual)
class QuestionModel {
  final String id;
  final String type;
  final String title;
  final String? description;
  final bool required;
  final QuestionValidationModel? validation;
  final String? placeholder;
  final List<QuestionOptionModel>? options;
  final String? displayStyle;
  final String? unit;
  final Map<String, String>? labels;

  QuestionModel({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.required,
    this.validation,
    this.placeholder,
    this.options,
    this.displayStyle,
    this.unit,
    this.labels,
  });

  Question toEntity() {
    return Question(
      id: id,
      type: QuestionType.fromString(type),
      title: title,
      description: description,
      required: required,
      validation: validation?.toEntity(),
      placeholder: placeholder,
      options: options?.map((o) => o.toEntity()).toList(),
      displayStyle: displayStyle,
      unit: unit,
      labels: labels,
    );
  }

  factory QuestionModel.fromEntity(Question entity) {
    return QuestionModel(
      id: entity.id,
      type: entity.type.toJson(),
      title: entity.title,
      description: entity.description,
      required: entity.required,
      validation: entity.validation != null
          ? QuestionValidationModel.fromEntity(entity.validation!)
          : null,
      placeholder: entity.placeholder,
      options: entity.options
          ?.map((o) => QuestionOptionModel.fromEntity(o))
          .toList(),
      displayStyle: entity.displayStyle,
      unit: entity.unit,
      labels: entity.labels,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'required': required ? 1 : 0,
      'validation': validation?.toJsonString(),
      'placeholder': placeholder,
      'options': options != null ? json.encode(options!.map((o) => o.toMap()).toList()) : null,
      'displayStyle': displayStyle,
      'unit': unit,
      'labels': labels != null ? json.encode(labels) : null,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      required: (map['required'] as int) == 1,
      validation: map['validation'] != null
          ? QuestionValidationModel.fromJsonString(map['validation'])
          : null,
      placeholder: map['placeholder'] as String?,
      options: map['options'] != null
          ? (json.decode(map['options']) as List)
              .map((o) => QuestionOptionModel.fromMap(o))
              .toList()
          : null,
      displayStyle: map['displayStyle'] as String?,
      unit: map['unit'] as String?,
      labels: map['labels'] != null
          ? Map<String, String>.from(json.decode(map['labels']))
          : null,
    );
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      required: json['required'] as bool,
      validation: json['validation'] != null
          ? QuestionValidationModel.fromJson(json['validation'])
          : null,
      placeholder: json['placeholder'] as String?,
      options: json['options'] != null
          ? (json['options'] as List)
              .map((o) => QuestionOptionModel.fromJson(o))
              .toList()
          : null,
      displayStyle: json['displayStyle'] as String?,
      unit: json['unit'] as String?,
      labels: json['labels'] != null
          ? Map<String, String>.from(json['labels'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'required': required,
      'validation': validation?.toMap(),
      'placeholder': placeholder,
      'options': options?.map((o) => o.toMap()).toList(),
      'displayStyle': displayStyle,
      'unit': unit,
      'labels': labels,
    };
  }
}
