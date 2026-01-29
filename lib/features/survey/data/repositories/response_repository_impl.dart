import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/survey_response.dart';
import '../../domain/repositories/response_repository.dart';
import '../datasources/response_local_datasource.dart';
import '../models/survey_response_model.dart';

/// Implementación del Repositorio de Respuestas con SQLite
class ResponseRepositoryImpl implements ResponseRepository {
  final ResponseLocalDataSource localDataSource;

  ResponseRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, void>> saveResponse(SurveyResponse response) async {
    try {
      final model = SurveyResponseModel.fromEntity(response);
      await localDataSource.save(model);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SurveyResponse>>> getResponsesBySurveyId(
    String surveyId,
  ) async {
    try {
      final models = await localDataSource.getBySurveyId(surveyId);
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SurveyResponse>> getResponseById(String responseId) async {
    try {
      final model = await localDataSource.getById(responseId);
      return Right(model.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SurveyResponse>>> getAllResponses() async {
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
  Future<Either<Failure, void>> updateResponse(SurveyResponse response) async {
    try {
      final model = SurveyResponseModel.fromEntity(response);
      await localDataSource.update(model);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteResponse(String responseId) async {
    try {
      await localDataSource.delete(responseId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> exportResponsesToExcel(
    List<SurveyResponse> responses,
    String surveyTitle,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Respuestas'];

      // Headers
      sheet.appendRow([
        TextCellValue('ID Respuesta') as CellValue?,
        TextCellValue('ID Pregunta') as CellValue?,
        TextCellValue('Respuesta') as CellValue?,
        TextCellValue('Fecha') as CellValue?,
      ]);

      // Data rows
      for (var response in responses) {
        for (var answer in response.answers) {
          sheet.appendRow([
            TextCellValue(response.id) as CellValue?,
            TextCellValue(answer.questionId) as CellValue?,
            TextCellValue(answer.value.toString()) as CellValue?,
            TextCellValue(answer.answeredAt.toString()) as CellValue?,
          ]);
        }
      }

      // Save file
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${dir.path}/${surveyTitle}_$timestamp.xlsx';
      
      final fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        return Right(filePath);
      } else {
        return const Left(ExportFailure(message: 'Error al generar Excel'));
      }
    } catch (e) {
      return Left(ExportFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> exportResponsesToCsv(
    List<SurveyResponse> responses,
    String surveyTitle,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${dir.path}/${surveyTitle}_$timestamp.csv';
      
      final buffer = StringBuffer();
      buffer.writeln('ID Respuesta,ID Pregunta,Respuesta,Fecha');
      
      for (var response in responses) {
        for (var answer in response.answers) {
          buffer.writeln(
            '${response.id},${answer.questionId},"${answer.value}",${answer.answeredAt}',
          );
        }
      }
      
      File(filePath).writeAsStringSync(buffer.toString());
      return Right(filePath);
    } catch (e) {
      return Left(ExportFailure(message: e.toString()));
    }
  }
}
