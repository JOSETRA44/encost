import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../models/survey_model.dart';

/// Data Source Local para Encuestas con SQLite
abstract class SurveyLocalDataSource {
  Future<SurveyModel> loadFromJson(String filePath);
  Future<SurveyModel> loadFromString(String jsonString);
  Future<List<SurveyModel>> getAll();
  Future<SurveyModel> getById(String id);
  Future<void> save(SurveyModel survey);
  Future<void> delete(String id);
}

class SurveyLocalDataSourceImpl implements SurveyLocalDataSource {
  final DatabaseHelper dbHelper;

  SurveyLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<SurveyModel> loadFromJson(String filePath) async {
    try {
      final jsonString = await rootBundle.loadString(filePath);
      return loadFromString(jsonString);
    } catch (e) {
      throw FileNotFoundException('No se pudo cargar el archivo: $filePath');
    }
  }

  @override
  Future<SurveyModel> loadFromString(String jsonString) async {
    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return SurveyModel.fromJson(jsonMap);
    } catch (e) {
      throw ParsingException('Error al parsear JSON: ${e.toString()}');
    }
  }

  @override
  Future<List<SurveyModel>> getAll() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('surveys');
      
      return maps.map((map) => SurveyModel.fromMap(map)).toList();
    } catch (e) {
      throw CacheException('Error al obtener encuestas: ${e.toString()}');
    }
  }

  @override
  Future<SurveyModel> getById(String id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'surveys',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        throw CacheException('Encuesta no encontrada: $id');
      }

      return SurveyModel.fromMap(maps.first);
    } catch (e) {
      throw CacheException('Error al obtener encuesta: ${e.toString()}');
    }
  }

  @override
  Future<void> save(SurveyModel survey) async {
    try {
      final db = await dbHelper.database;
      await db.insert(
        'surveys',
        survey.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Error al guardar encuesta: ${e.toString()}');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        'surveys',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException('Error al eliminar encuesta: ${e.toString()}');
    }
  }
}
