import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Entidad de Dominio: Respuesta Individual
/// 
/// Representa la respuesta a una pregunta específica
class Answer extends Equatable {
  final String questionId;
  final dynamic value; // Puede ser String, num, List<String>, etc.
  final DateTime answeredAt;

  const Answer({
    required this.questionId,
    required this.value,
    required this.answeredAt,
  });

  /// Crea una respuesta con timestamp actual
  factory Answer.now({
    required String questionId,
    required dynamic value,
  }) {
    return Answer(
      questionId: questionId,
      value: value,
      answeredAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [questionId, value, answeredAt];

  @override
  String toString() => 'Answer(questionId: $questionId, value: $value)';
}

/// Entidad de Dominio: Respuesta de Encuesta Completa
/// 
/// Agrupa todas las respuestas de un usuario a una encuesta
class SurveyResponse extends Equatable {
  final String id;
  final String surveyId;
  final String surveyVersion;
  final List<Answer> answers;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool isCompleted;

  const SurveyResponse({
    required this.id,
    required this.surveyId,
    required this.surveyVersion,
    required this.answers,
    required this.startedAt,
    this.completedAt,
    required this.isCompleted,
  });

  /// Crea una nueva respuesta vacía
  factory SurveyResponse.create({
    required String surveyId,
    required String surveyVersion,
  }) {
    return SurveyResponse(
      id: const Uuid().v4(),
      surveyId: surveyId,
      surveyVersion: surveyVersion,
      answers: [],
      startedAt: DateTime.now(),
      completedAt: null,
      isCompleted: false,
    );
  }

  /// Agrega o actualiza una respuesta
  SurveyResponse updateAnswer(Answer answer) {
    final updatedAnswers = List<Answer>.from(answers);
    final existingIndex = updatedAnswers.indexWhere(
      (a) => a.questionId == answer.questionId,
    );

    if (existingIndex >= 0) {
      updatedAnswers[existingIndex] = answer;
    } else {
      updatedAnswers.add(answer);
    }

    return SurveyResponse(
      id: id,
      surveyId: surveyId,
      surveyVersion: surveyVersion,
      answers: updatedAnswers,
      startedAt: startedAt,
      completedAt: completedAt,
      isCompleted: isCompleted,
    );
  }

  /// Marca la encuesta como completada
  SurveyResponse complete() {
    return SurveyResponse(
      id: id,
      surveyId: surveyId,
      surveyVersion: surveyVersion,
      answers: answers,
      startedAt: startedAt,
      completedAt: DateTime.now(),
      isCompleted: true,
    );
  }

  /// Obtiene la respuesta a una pregunta específica
  Answer? getAnswerByQuestionId(String questionId) {
    try {
      return answers.firstWhere((a) => a.questionId == questionId);
    } catch (e) {
      return null;
    }
  }

  /// Calcula el progreso de la encuesta (0.0 - 1.0)
  double getProgress(int totalQuestions) {
    if (totalQuestions == 0) return 1.0;
    return answers.length / totalQuestions;
  }

  @override
  List<Object?> get props => [
        id,
        surveyId,
        surveyVersion,
        answers,
        startedAt,
        completedAt,
        isCompleted,
      ];

  @override
  String toString() => 'SurveyResponse(id: $id, answers: ${answers.length}, completed: $isCompleted)';
}
