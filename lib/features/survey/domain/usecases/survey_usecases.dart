import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/survey.dart';
import '../repositories/survey_repository.dart';

/// Caso de Uso: Cargar Encuesta desde JSON
/// 
/// Principio de Responsabilidad Única (SRP):
/// Solo se encarga de cargar una encuesta desde un archivo
class LoadSurveyFromJson {
  final SurveyRepository repository;

  LoadSurveyFromJson(this.repository);

  Future<Either<Failure, Survey>> call(String filePath) async {
    return await repository.loadSurveyFromJson(filePath);
  }
}

/// Caso de Uso: Obtener Encuesta por ID
class GetSurveyById {
  final SurveyRepository repository;

  GetSurveyById(this.repository);

  Future<Either<Failure, Survey>> call(String surveyId) async {
    return await repository.getSurveyById(surveyId);
  }
}

/// Caso de Uso: Obtener Todas las Encuestas
class GetAllSurveys {
  final SurveyRepository repository;

  GetAllSurveys(this.repository);

  Future<Either<Failure, List<Survey>>> call() async {
    return await repository.getStoredSurveys();
  }
}

/// Caso de Uso: Guardar Encuesta
class SaveSurvey {
  final SurveyRepository repository;

  SaveSurvey(this.repository);

  Future<Either<Failure, void>> call(Survey survey) async {
    return await repository.saveSurvey(survey);
  }
}
