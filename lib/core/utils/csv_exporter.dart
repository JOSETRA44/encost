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
/// - Limpieza de checkboxes: ["A","B"] → "A - B" (guiones para Excel)
/// - Aplanamiento de matrices: {row1: {col1: val}} → "row1: col1=val | row2: col2=val"
/// - UTF-8 con BOM (\uFEFF) para Excel
/// - Delimitador punto y coma (;) para Excel en español
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
        debugPrint('📊 Encuesta "${surveyData['title']}": ${surveyResponses.length} respuestas');
        
        // Procesar cada respuesta
        int rowsGenerated = 0;
        for (final response in surveyResponses) {
          final row = await _buildResponseRow(db, response, surveyData);
          if (row != null) {
            allCsvData.add(row);
            rowsGenerated++;
          }
        }
        debugPrint('   ✅ Filas generadas: $rowsGenerated');
      }
      
      debugPrint('📄 Total de filas en CSV: ${allCsvData.length}');
      
      // Generar CSV con BOM UTF-8 y delimitador punto y coma (;) para Excel LatAm
      final csvString = '\uFEFF${const ListToCsvConverter(fieldDelimiter: ';').convert(allCsvData)}';
      debugPrint('💾 CSV generado: ${csvString.length} caracteres');
      
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
      debugPrint('📊 Procesando ${responses.length} respuestas para "$surveyTitle"...');
      
      // Procesar cada respuesta
      int rowsGenerated = 0;
      for (final response in responses) {
        final row = await _buildResponseRow(db, response, surveyData);
        if (row != null) {
          csvData.add(row);
          rowsGenerated++;
        }
      }
      
      debugPrint('✅ Filas generadas en CSV: $rowsGenerated (de ${responses.length} respuestas en DB)');
      
      if (rowsGenerated == 0) {
        return ExportResult.error('No se pudo generar ninguna fila de datos');
      }
      
      // Generar CSV con BOM UTF-8 y delimitador punto y coma (;) para Excel LatAm
      final csvString = '\uFEFF${const ListToCsvConverter(fieldDelimiter: ';').convert(csvData)}';
      debugPrint('📄 CSV generado: ${csvString.length} caracteres');
      
      // Guardar archivo
      final cleanTitle = surveyTitle.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').replaceAll(' ', '_');
      final file = await _saveFile(csvString, cleanTitle);
      
      return ExportResult.success(
        file: file,
        fileName: file.path.split('/').last,
        rowCount: rowsGenerated,
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
      
      debugPrint('🔍 Procesando response ID: $responseId');
      
      // Obtener todas las answers para esta respuesta
      final answers = await db.query(
        'answers',
        where: 'response_id = ?',
        whereArgs: [responseId],
      );
      
      debugPrint('   ✅ Encontradas ${answers.length} respuestas para la encuesta ID: $responseId');
      
      // Crear mapa de respuestas por question_id
      final Map<String, String> answerMap = {};
      if (answers.isNotEmpty) {
        for (final answer in answers) {
          final questionId = answer['question_id'] as String;
          final value = answer['value'] as String;
          answerMap[questionId] = value;
          debugPrint('      📋 Pregunta $questionId: ${value.length > 50 ? value.substring(0, 50) + "..." : value}');
        }
      } else {
        debugPrint('   ⚠️ Sin answers, pero generando fila con campos vacíos');
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
          // ["Opción A", "Opción B"] → "Opción A - Opción B" (guión para evitar conflicto con separador)
          final list = jsonDecode(rawValue) as List<dynamic>;
          return list.join(' - ');
          
        case 'matrix':
          // {row1: {col1: val1, col2: val2}} → "[row1: col1=val1 - col2=val2] | [row2: col1=val3]"
          final matrixData = jsonDecode(rawValue) as Map<String, dynamic>;
          final List<String> parts = [];
          
          matrixData.forEach((row, columns) {
            final columnData = columns as Map<String, dynamic>;
            final colParts = columnData.entries
                .where((e) => e.value.toString().isNotEmpty)
                .map((e) => '\${e.key}=\${e.value}')
                .join(' - '); // Usar guión en lugar de coma
            if (colParts.isNotEmpty) {
              parts.add('[\$row: \$colParts]'); // Agregar corchetes para claridad
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
    
    final fileSize = await file.length();
    debugPrint('✅ CSV guardado: $fileName');
    debugPrint('   📁 Ruta: $filePath');
    debugPrint('   📊 Tamaño: $fileSize bytes (${csvContent.length} chars)');
    
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
