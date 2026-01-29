import 'package:equatable/equatable.dart';
import 'question_type.dart';
import 'question_option.dart';
import 'question_validation.dart';

/// Entidad de Dominio: Pregunta de Encuesta
/// 
/// Principio de Responsabilidad Única (SRP):
/// Representa una pregunta con todas sus propiedades y comportamiento
class Question extends Equatable {
  final String id;
  final QuestionType type;
  final String title;
  final String? description;
  final bool required;
  final QuestionValidation? validation;
  final String? placeholder;
  final List<QuestionOption>? options;
  final String? displayStyle;
  final String? unit;
  final Map<String, String>? labels;

  const Question({
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

  /// Verifica si la pregunta tiene opciones (choice questions)
  bool get hasOptions => 
      type == QuestionType.singleChoice || 
      type == QuestionType.multipleChoice;

  /// Obtiene el label mínimo del rango
  String? get minLabel => labels?['min'];

  /// Obtiene el label máximo del rango
  String? get maxLabel => labels?['max'];

  /// Valida una respuesta según el tipo de pregunta
  /// 
  /// Principio de Segregación de Interfaces (ISP):
  /// Cada tipo de pregunta tiene su propia validación
  String? validateAnswer(dynamic answer) {
    if (required && (answer == null || _isEmptyAnswer(answer))) {
      return 'Este campo es obligatorio';
    }

    if (answer == null) return null;

    switch (type) {
      case QuestionType.text:
        return validation?.validateText(answer as String?);
      case QuestionType.numeric:
        return validation?.validateNumeric(answer as num?);
      case QuestionType.multipleChoice:
        return validation?.validateMultipleSelections(answer as List<String>);
      case QuestionType.singleChoice:
      case QuestionType.range:
        return null; // Validación básica ya cubierta
    }
  }

  bool _isEmptyAnswer(dynamic answer) {
    if (answer is String) return answer.isEmpty;
    if (answer is List) return answer.isEmpty;
    return false;
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        required,
        validation,
        placeholder,
        options,
        displayStyle,
        unit,
        labels,
      ];

  @override
  String toString() => 'Question(id: $id, type: $type, title: $title)';
}
