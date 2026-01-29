/// Enumeración de tipos de pregunta soportados
/// 
/// Principio Open/Closed: Abierto para extensión, cerrado para modificación
enum QuestionType {
  text,
  numeric,
  singleChoice,
  multipleChoice,
  range;

  static QuestionType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return QuestionType.text;
      case 'numeric':
        return QuestionType.numeric;
      case 'single_choice':
        return QuestionType.singleChoice;
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'range':
        return QuestionType.range;
      default:
        throw ArgumentError('Unknown question type: $type');
    }
  }

  String toJson() {
    switch (this) {
      case QuestionType.text:
        return 'text';
      case QuestionType.numeric:
        return 'numeric';
      case QuestionType.singleChoice:
        return 'single_choice';
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.range:
        return 'range';
    }
  }
}
