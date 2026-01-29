import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/survey_response.dart';
import '../repositories/response_repository.dart';

/// Caso de Uso: Guardar Respuesta
class SaveResponse {
  final ResponseRepository repository;

  SaveResponse(this.repository);

  Future<Either<Failure, void>> call(SurveyResponse response) async {
    return await repository.saveResponse(response);
  }
}

/// Caso de Uso: Actualizar Respuesta
class UpdateResponse {
  final ResponseRepository repository;

  UpdateResponse(this.repository);

  Future<Either<Failure, void>> call(SurveyResponse response) async {
    return await repository.updateResponse(response);
  }
}

/// Caso de Uso: Obtener Respuestas por ID de Encuesta
class GetResponsesBySurveyId {
  final ResponseRepository repository;

  GetResponsesBySurveyId(this.repository);

  Future<Either<Failure, List<SurveyResponse>>> call(String surveyId) async {
    return await repository.getResponsesBySurveyId(surveyId);
  }
}

/// Caso de Uso: Exportar a Excel
class ExportResponsesToExcel {
  final ResponseRepository repository;

  ExportResponsesToExcel(this.repository);

  Future<Either<Failure, String>> call(
    List<SurveyResponse> responses,
    String surveyTitle,
  ) async {
    return await repository.exportResponsesToExcel(responses, surveyTitle);
  }
}

/// Caso de Uso: Exportar a CSV
class ExportResponsesToCsv {
  final ResponseRepository repository;

  ExportResponsesToCsv(this.repository);

  Future<Either<Failure, String>> call(
    List<SurveyResponse> responses,
    String surveyTitle,
  ) async {
    return await repository.exportResponsesToCsv(responses, surveyTitle);
  }
}
