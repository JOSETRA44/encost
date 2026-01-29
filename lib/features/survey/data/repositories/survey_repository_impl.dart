import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/survey.dart';
import '../../domain/repositories/survey_repository.dart';
import '../datasources/survey_local_datasource.dart';
import '../models/survey_model.dart';

/// Implementación del Repositorio de Encuestas con SQLite
class SurveyRepositoryImpl implements SurveyRepository {
  final SurveyLocalDataSource localDataSource;

  SurveyRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Survey>> loadSurveyFromJson(String filePath) async {
    try {
      final model = await localDataSource.loadFromJson(filePath);
      return Right(model.toEntity());
    } on FileNotFoundException catch (e) {
      return Left(FileNotFoundFailure(message: e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Survey>> loadSurveyFromString(String jsonString) async {
    try {
      final model = await localDataSource.loadFromString(jsonString);
      return Right(model.toEntity());
    } on ParsingException catch (e) {
      return Left(ParsingFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Survey>>> getStoredSurveys() async {
    try {
      final models = await localDataSource.getAll();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Survey>> getSurveyById(String surveyId) async {
    try {
      final model = await localDataSource.getById(surveyId);
      return Right(model.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveSurvey(Survey survey) async {
    try {
      final model = SurveyModel.fromEntity(survey);
      await localDataSource.save(model);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSurvey(String surveyId) async {
    try {
      await localDataSource.delete(surveyId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
