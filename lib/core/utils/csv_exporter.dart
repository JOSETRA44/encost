import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

/// 📊 EXPORTADOR CSV - FORMATO HORIZONTAL (PIVOT)
/// 
/// Convierte respuestas verticales (una fila por pregunta) a formato tabular
/// donde cada fila = una respuesta completa con todas las preguntas como columnas.
/// 
/// ✅ Características:
/// - Cabeceras dinámicas desde JSON de la encuesta
/// - Limpieza de checkboxes: ["A","B"] → "A, B"
/// - Aplanamiento de matrices: {row1: {col1: val}} → "row1: col1=val"
/// - UTF-8 con BOM (\uFEFF) para Excel
/// - Sin filas vacías
class CsvExporter {
  
  /// 🔹 Exporta TODAS las respuestas de TODAS las encuestas
  /// Formato: Una fila por response_id con todas las preguntas como columnas
  static Future<ExportResult> exportAllResponses(List<Map<String, dynamic>> responses) async {
    if (responses.isEmpty) {
      return ExportResult.error('No hay datos para exportar');
    }

    try {
      final db = await DatabaseHelper.instance.database;
      
      // Agrupar respuestas por encuesta para mantener orden lógico
      final Map<String, List<Map<String, dynamic>>> responsesBySurvey = {};
      
      for (final response in responses) {
        final surveyId = response['survey_id'] as String;
        responsesBySurvey.putIfAbsent(surveyId, () => []).add(response);
      }
      
      final List<List<dynamic>> allCsvData = [];
      bool isFirstSurvey = true;
      
      // Procesar cada encuesta
      for (final entry in responsesBySurvey.entries) {
        final surveyId = entry.key;
        final surveyResponses = entry.value;
        
        // Obtener estructura de la encuesta
        final surveyData = await _getSurveyStructure(db, surveyId);
        if (surveyData == null) continue;
        
        // Agregar separador entre encuestas (excepto la primera)
        if (!isFirstSurvey) {
          allCsvData.add([]); // Fila vacía
          allCsvData.add(['=== ${surveyData['title']} ===']);
          allCsvData.add([]); // Fila vacía
        }
        isFirstSurvey = false;
        
        // Generar cabeceras dinámicas
        final headers = _buildHeaders(surveyData);
        allCsvData.add(headers);
        
        // Procesar cada respuesta
        for (final response in surveyResponses) {
          final row = await _buildResponseRow(db, response, surveyData);
          if (row != null) {
            allCsvData.add(row);
          }
        }
      }
      
      // Generar CSV con BOM UTF-8
      final csvString = '\uFEFF${const ListToCsvConverter().convert(allCsvData)}';
      
      // Guardar archivo
      final file = await _saveFile(csvString, 'todas_encuestas');
      
      return ExportResult.success(
        file: file,
        fileName: file.path.split('/').last,
        rowCount: allCsvData.length - responsesBySurvey.length, // Sin contar headers
      );
      
    } catch (e, stackTrace) {
      debugPrint('❌ CsvExporter.exportAllResponses ERROR: $e');
      debugPrint('Stack: $stackTrace');
      return ExportResult.error('Error al exportar: $e');
    }
  }
  
  /// 🔹 Exporta respuestas de UNA sola encuesta
  /// Formato: Pivot table con cabeceras dinámicas
  static Future<ExportResult> exportSurvey(String surveyId, String surveyTitle) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Obtener respuestas de esta encuesta
      final responses = await db.query(
        'responses',
        where: 'survey_id = ?',
        whereArgs: [surveyId],
        orderBy: 'timestamp DESC',
      );
      
      if (responses.isEmpty) {
        return ExportResult.error('No hay respuestas para esta encuesta');
      }
      
      // Obtener estructura de la encuesta
      final surveyData = await _getSurveyStructure(db, surveyId);
      if (surveyData == null) {
        return ExportResult.error('No se pudo cargar la estructura de la encuesta');
      }
      
      final List<List<dynamic>> csvData = [];
      
      // Cabeceras dinámicas
      final headers = _buildHeaders(surveyData);
      csvData.add(headers);
      
      // Procesar cada respuesta
      for (final response in responses) {
        final row = await _buildResponseRow(db, response, surveyData);
        if (row != null) {
          csvData.add(row);
        }
      }
      
      // Generar CSV con BOM UTF-8
      final csvString = '\uFEFF${const ListToCsvConverter().convert(csvData)}';
      
      // Guardar archivo
      final cleanTitle = surveyTitle.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').replaceAll(' ', '_');
      final file = await _saveFile(csvString, cleanTitle);
      
      return ExportResult.success(
        file: file,
        fileName: file.path.split('/').last,
        rowCount: responses.length,
      );
      
    } catch (e, stackTrace) {
      debugPrint('❌ CsvExporter.exportSurvey ERROR: $e');
      debugPrint('Stack: $stackTrace');
      return ExportResult.error('Error al exportar: $e');
    }
  }
  
  /// 📋 Obtiene estructura de la encuesta desde la base de datos
  static Future<Map<String, dynamic>?> _getSurveyStructure(dynamic db, String surveyId) async {
    try {
      final result = await db.query(
        'surveys',
        where: 'id = ?',
        whereArgs: [surveyId],
      );
      
      if (result.isEmpty) return null;
      
      final survey = result.first;
      final jsonStructure = survey['json_structure'] as String;
      final surveyJson = jsonDecode(jsonStructure) as Map<String, dynamic>;
      
      return {
        'id': surveyId,
        'title': survey['title'] as String,
        'fields': surveyJson['fields'] as List<dynamic>,
      };
    } catch (e) {
      debugPrint('⚠️ Error al obtener estructura de encuesta: $e');
      return null;
    }
  }
  
  /// 🏷️ Construye cabeceras dinámicas desde el JSON de la encuesta
  static List<dynamic> _buildHeaders(Map<String, dynamic> surveyData) {
    final headers = <dynamic>[
      'ID',
      'Fecha',
      'Hora',
    ];
    
    final fields = surveyData['fields'] as List<dynamic>;
    for (final field in fields) {
      final fieldMap = field as Map<String, dynamic>;
      final label = fieldMap['label'] as String;
      
      // Para matrices, agregar una columna consolidada
      if (fieldMap['type'] == 'matrix') {
        headers.add(label);
      } else {
        headers.add(label);
      }
    }
    
    headers.add('Estado');
    
    return headers;
  }
  
  /// 📝 Construye una fila de datos para una respuesta
  static Future<List<dynamic>?> _buildResponseRow(
    dynamic db,
    Map<String, dynamic> response,
    Map<String, dynamic> surveyData,
  ) async {
    try {
      final responseId = response['id'] as String;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(response['timestamp'] as int);
      final isExported = (response['is_exported'] as int) == 1;
      
      // Obtener todas las answers para esta respuesta
      final answers = await db.query(
        'answers',
        where: 'response_id = ?',
        whereArgs: [responseId],
      );
      
      if (answers.isEmpty) {
        debugPrint('⚠️ Response $responseId sin answers, omitiendo...');
        return null; // No agregar filas vacías
      }
      
      // Crear mapa de respuestas por question_id
      final Map<String, String> answerMap = {};
      for (final answer in answers) {
        final questionId = answer['question_id'] as String;
        final value = answer['value'] as String;
        answerMap[questionId] = value;
      }
      
      // Construir fila
      final row = <dynamic>[
        responseId.substring(0, 8), // ID corto
        '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}',
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
      ];
      
      // Agregar valores de cada pregunta en orden
      final fields = surveyData['fields'] as List<dynamic>;
      for (final field in fields) {
        final fieldMap = field as Map<String, dynamic>;
        final fieldId = fieldMap['id'] as String;
        final fieldType = fieldMap['type'] as String;
        final rawValue = answerMap[fieldId] ?? '';
        
        // Limpiar datos según tipo
        final cleanValue = _cleanValue(rawValue, fieldType);
        row.add(cleanValue);
      }
      
      row.add(isExported ? 'Exportada' : 'Pendiente');
      
      return row;
      
    } catch (e) {
      debugPrint('⚠️ Error al construir fila: $e');
      return null;
    }
  }
  
  /// 🧹 Limpia y formatea valores según el tipo de pregunta
  static String _cleanValue(String rawValue, String questionType) {
    if (rawValue.isEmpty) return '';
    
    try {
      switch (questionType) {
        case 'checkbox':
          // ["Opción A", "Opción B"] → "Opción A, Opción B"
          final list = jsonDecode(rawValue) as List<dynamic>;
          return list.join(', ');
          
        case 'matrix':
          // {row1: {col1: val1, col2: val2}} → "row1: col1=val1, col2=val2"
          final matrixData = jsonDecode(rawValue) as Map<String, dynamic>;
          final List<String> parts = [];
          
          matrixData.forEach((row, columns) {
            final columnData = columns as Map<String, dynamic>;
            final colParts = columnData.entries
                .where((e) => e.value.toString().isNotEmpty)
                .map((e) => '${e.key}=${e.value}')
                .join(', ');
            if (colParts.isNotEmpty) {
              parts.add('$row: $colParts');
            }
          });
          
          return parts.join(' | ');
          
        default:
          return rawValue;
      }
    } catch (e) {
      debugPrint('⚠️ Error limpiando valor: $e');
      return rawValue; // Fallback a valor original
    }
  }
  
  /// 💾 Guarda el CSV en el sistema de archivos
  static Future<File> _saveFile(String csvContent, String baseName) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now();
    final fileName = '${baseName}_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour}${timestamp.minute}.csv';
    final filePath = '${directory.path}/$fileName';
    
    final file = File(filePath);
    await file.writeAsString(csvContent, encoding: utf8);
    
    debugPrint('✅ CSV guardado: $fileName (${csvContent.length} bytes)');
    
    return file;
  }
  
  /// 📤 Comparte el archivo CSV usando Share Plus
  static Future<void> shareFile(File file, String subject, String text) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
      text: text,
    );
  }
}

/// 📦 Resultado de la exportación
class ExportResult {
  final bool success;
  final String? errorMessage;
  final File? file;
  final String? fileName;
  final int? rowCount;
  
  ExportResult._({
    required this.success,
    this.errorMessage,
    this.file,
    this.fileName,
    this.rowCount,
  });
  
  factory ExportResult.success({
    required File file,
    required String fileName,
    required int rowCount,
  }) {
    return ExportResult._(
      success: true,
      file: file,
      fileName: fileName,
      rowCount: rowCount,
    );
  }
  
  factory ExportResult.error(String message) {
    return ExportResult._(
      success: false,
      errorMessage: message,
    );
  }
}
