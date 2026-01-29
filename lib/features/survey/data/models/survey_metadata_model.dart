import 'dart:convert';
import '../../domain/entities/survey_metadata.dart';

/// Modelo de datos - SurveyMetadata (Manual)
class SurveyMetadataModel {
  final String author;
  final String category;
  final List<String> tags;

  SurveyMetadataModel({
    required this.author,
    required this.category,
    required this.tags,
  });

  SurveyMetadata toEntity() {
    return SurveyMetadata(
      author: author,
      category: category,
      tags: tags,
    );
  }

  factory SurveyMetadataModel.fromEntity(SurveyMetadata entity) {
    return SurveyMetadataModel(
      author: entity.author,
      category: entity.category,
      tags: entity.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'author': author,
      'category': category,
      'tags': json.encode(tags),
    };
  }

  factory SurveyMetadataModel.fromMap(Map<String, dynamic> map) {
    return SurveyMetadataModel(
      author: map['author'] as String,
      category: map['category'] as String,
      tags: List<String>.from(json.decode(map['tags'])),
    );
  }

  factory SurveyMetadataModel.fromJson(Map<String, dynamic> json) {
    return SurveyMetadataModel(
      author: json['author'] as String,
      category: json['category'] as String,
      tags: List<String>.from(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'category': category,
      'tags': tags,
    };
  }

  String toJsonString() => json.encode(toMap());

  factory SurveyMetadataModel.fromJsonString(String source) {
    final map = json.decode(source);
    return SurveyMetadataModel(
      author: map['author'] as String,
      category: map['category'] as String,
      tags: List<String>.from(json.decode(map['tags'])),
    );
  }
}
