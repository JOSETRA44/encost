import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/survey.dart';

/// Contrato del Repositorio de Encuestas (Abstracción)
/// 
/// Principio de Inversión de Dependencias (DIP):
/// El dominio define el contrato, la data layer lo implementa
abstract class SurveyRepository {
  /// Carga una encuesta desde un archivo JSON
  Future<Either<Failure, Survey>> loadSurveyFromJson(String filePath);

  /// Carga una encuesta desde un string JSON
  Future<Either<Failure, Survey>> loadSurveyFromString(String jsonString);

  /// Obtiene todas las encuestas almacenadas localmente
  Future<Either<Failure, List<Survey>>> getStoredSurveys();

  /// Obtiene una encuesta por ID
  Future<Either<Failure, Survey>> getSurveyById(String surveyId);

  /// Guarda una encuesta localmente
  Future<Either<Failure, void>> saveSurvey(Survey survey);

  /// Elimina una encuesta
  Future<Either<Failure, void>> deleteSurvey(String surveyId);
}
