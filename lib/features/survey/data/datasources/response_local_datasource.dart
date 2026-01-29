import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../models/survey_response_model.dart';

/// Data Source Local para Respuestas con SQLite
abstract class ResponseLocalDataSource {
  Future<void> save(SurveyResponseModel response);
  Future<List<SurveyResponseModel>> getBySurveyId(String surveyId);
  Future<SurveyResponseModel> getById(String id);
  Future<List<SurveyResponseModel>> getAll();
  Future<void> update(SurveyResponseModel response);
  Future<void> delete(String id);
}

class ResponseLocalDataSourceImpl implements ResponseLocalDataSource {
  final DatabaseHelper dbHelper;

  ResponseLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<void> save(SurveyResponseModel response) async {
    try {
      final db = await dbHelper.database;
      await db.insert(
        'survey_responses',
        response.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Error al guardar respuesta: ${e.toString()}');
    }
  }

  @override
  Future<List<SurveyResponseModel>> getBySurveyId(String surveyId) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'survey_responses',
        where: 'surveyId = ?',
        whereArgs: [surveyId],
      );

      return maps.map((map) => SurveyResponseModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheException('Error al obtener respuestas: ${e.toString()}');
    }
  }

  @override
  Future<SurveyResponseModel> getById(String id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'survey_responses',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        throw CacheException('Respuesta no encontrada: $id');
      }

      return SurveyResponseModel.fromMap(maps.first);
    } catch (e) {
      throw CacheException('Error al obtener respuesta: ${e.toString()}');
    }
  }

  @override
  Future<List<SurveyResponseModel>> getAll() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('survey_responses');

      return maps.map((map) => SurveyResponseModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheException('Error al obtener respuestas: ${e.toString()}');
    }
  }

  @override
  Future<void> update(SurveyResponseModel response) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'survey_responses',
        response.toMap(),
        where: 'id = ?',
        whereArgs: [response.id],
      );
    } catch (e) {
      throw CacheException('Error al actualizar respuesta: ${e.toString()}');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        'survey_responses',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException('Error al eliminar respuesta: ${e.toString()}');
    }
  }
}
