import 'package:flutter/material.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/question_type.dart';
import 'question_widgets/text_question_widget.dart';
import 'question_widgets/numeric_question_widget.dart';
import 'question_widgets/single_choice_question_widget.dart';
import 'question_widgets/multiple_choice_question_widget.dart';
import 'question_widgets/range_question_widget.dart';

/// UI Factory - Patrón Factory para creación de widgets dinámicos
/// 
/// Principio Open/Closed (OCP):
/// Abierto para extensión (agregar nuevos tipos), cerrado para modificación
/// 
/// Principio de Inversión de Dependencias (DIP):
/// Depende de abstracciones (QuestionType enum), no de implementaciones concretas
class QuestionWidgetFactory {
  /// Crea el widget apropiado basado en el tipo de pregunta
  /// 
  /// El factory NO conoce el contenido de la pregunta,
  /// solo sabe cómo renderizar cada TIPO
  static Widget create({
    required Question question,
    required dynamic currentValue,
    required Function(dynamic) onChanged,
    String? errorText,
  }) {
    switch (question.type) {
      case QuestionType.text:
        return TextQuestionWidget(
          question: question,
          currentValue: currentValue as String?,
          onChanged: (value) => onChanged(value),
          errorText: errorText,
        );

      case QuestionType.numeric:
        return NumericQuestionWidget(
          question: question,
          currentValue: currentValue as num?,
          onChanged: (value) => onChanged(value),
          errorText: errorText,
        );

      case QuestionType.singleChoice:
        return SingleChoiceQuestionWidget(
          question: question,
          currentValue: currentValue as String?,
          onChanged: (value) => onChanged(value),
          errorText: errorText,
        );

      case QuestionType.multipleChoice:
        return MultipleChoiceQuestionWidget(
          question: question,
          currentValue: currentValue as List<String>?,
          onChanged: (value) => onChanged(value),
          errorText: errorText,
        );

      case QuestionType.range:
        return RangeQuestionWidget(
          question: question,
          currentValue: currentValue as num?,
          onChanged: (value) => onChanged(value),
          errorText: errorText,
        );
    }
  }

  /// Valida si un tipo de pregunta es soportado
  static bool isSupported(QuestionType type) {
    return [
      QuestionType.text,
      QuestionType.numeric,
      QuestionType.singleChoice,
      QuestionType.multipleChoice,
      QuestionType.range,
    ].contains(type);
  }
}

