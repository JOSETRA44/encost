import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/survey_response.dart';

/// Contrato del Repositorio de Respuestas
abstract class ResponseRepository {
  /// Guarda una respuesta de encuesta
  Future<Either<Failure, void>> saveResponse(SurveyResponse response);

  /// Obtiene todas las respuestas a una encuesta específica
  Future<Either<Failure, List<SurveyResponse>>> getResponsesBySurveyId(
    String surveyId,
  );

  /// Obtiene una respuesta específica por ID
  Future<Either<Failure, SurveyResponse>> getResponseById(String responseId);

  /// Obtiene todas las respuestas guardadas
  Future<Either<Failure, List<SurveyResponse>>> getAllResponses();

  /// Actualiza una respuesta existente
  Future<Either<Failure, void>> updateResponse(SurveyResponse response);

  /// Elimina una respuesta
  Future<Either<Failure, void>> deleteResponse(String responseId);

  /// Exporta respuestas a Excel
  Future<Either<Failure, String>> exportResponsesToExcel(
    List<SurveyResponse> responses,
    String surveyTitle,
  );

  /// Exporta respuestas a CSV
  Future<Either<Failure, String>> exportResponsesToCsv(
    List<SurveyResponse> responses,
    String surveyTitle,
  );
}
