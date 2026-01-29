import 'package:equatable/equatable.dart';
import 'question.dart';
import 'survey_metadata.dart';

/// Entidad de Dominio: Encuesta
/// 
/// Principio de Responsabilidad Única (SRP):
/// Representa la estructura completa de una encuesta
class Survey extends Equatable {
  final String id;
  final String version;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final SurveyMetadata metadata;
  final List<Question> questions;

  const Survey({
    required this.id,
    required this.version,
    required this.title,
    this.description,
    required this.createdAt,
    this.expiresAt,
    required this.metadata,
    required this.questions,
  });

  /// Verifica si la encuesta está activa (no expirada)
  bool get isActive {
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  /// Obtiene una pregunta por su ID
  Question? getQuestionById(String questionId) {
    try {
      return questions.firstWhere((q) => q.id == questionId);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el total de preguntas obligatorias
  int get requiredQuestionsCount =>
      questions.where((q) => q.required).length;

  @override
  List<Object?> get props => [
        id,
        version,
        title,
        description,
        createdAt,
        expiresAt,
        metadata,
        questions,
      ];

  @override
  String toString() => 'Survey(id: $id, title: $title, questions: ${questions.length})';
}
