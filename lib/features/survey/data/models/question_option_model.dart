import '../../domain/entities/question_option.dart';

/// Modelo de datos - QuestionOption (Manual - Sin generadores)
class QuestionOptionModel {
  final String id;
  final String label;
  final String value;

  QuestionOptionModel({
    required this.id,
    required this.label,
    required this.value,
  });

  QuestionOption toEntity() {
    return QuestionOption(
      id: id,
      label: label,
      value: value,
    );
  }

  factory QuestionOptionModel.fromEntity(QuestionOption entity) {
    return QuestionOptionModel(
      id: entity.id,
      label: entity.label,
      value: entity.value,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'value': value,
    };
  }

  factory QuestionOptionModel.fromMap(Map<String, dynamic> map) {
    return QuestionOptionModel(
      id: map['id'] as String,
      label: map['label'] as String,
      value: map['value'] as String,
    );
  }

  factory QuestionOptionModel.fromJson(Map<String, dynamic> json) =>
      QuestionOptionModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}
