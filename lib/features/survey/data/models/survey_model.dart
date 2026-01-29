import 'dart:convert';
import '../../domain/entities/survey.dart';
import 'question_model.dart';
import 'survey_metadata_model.dart';

/// Modelo de datos - Survey (Manual - Para SQLite)
class SurveyModel {
  final String id;
  final String version;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final SurveyMetadataModel metadata;
  final List<QuestionModel> questions;

  SurveyModel({
    required this.id,
    required this.version,
    required this.title,
    this.description,
    required this.createdAt,
    this.expiresAt,
    required this.metadata,
    required this.questions,
  });

  Survey toEntity() {
    return Survey(
      id: id,
      version: version,
      title: title,
      description: description,
      createdAt: createdAt,
      expiresAt: expiresAt,
      metadata: metadata.toEntity(),
      questions: questions.map((q) => q.toEntity()).toList(),
    );
  }

  factory SurveyModel.fromEntity(Survey entity) {
    return SurveyModel(
      id: entity.id,
      version: entity.version,
      title: entity.title,
      description: entity.description,
      createdAt: entity.createdAt,
      expiresAt: entity.expiresAt,
      metadata: SurveyMetadataModel.fromEntity(entity.metadata),
      questions: entity.questions.map((q) => QuestionModel.fromEntity(q)).toList(),
    );
  }

  /// Para SQLite - Campos individuales
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'version': version,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata.toJsonString(),
      'questions': json.encode(questions.map((q) => q.toJson()).toList()),
    };
  }

  factory SurveyModel.fromMap(Map<String, dynamic> map) {
    return SurveyModel(
      id: map['id'] as String,
      version: map['version'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : null,
      metadata: SurveyMetadataModel.fromJsonString(map['metadata']),
      questions: (json.decode(map['questions']) as List)
          .map((q) => QuestionModel.fromJson(q))
          .toList(),
    );
  }

  /// Para parsing de JSON externo
  factory SurveyModel.fromJson(Map<String, dynamic> json) {
    return SurveyModel(
      id: json['id'] as String,
      version: json['version'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      metadata: SurveyMetadataModel.fromJson(json['metadata']),
      questions: (json['questions'] as List)
          .map((q) => QuestionModel.fromJson(q))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata.toJson(),
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}
