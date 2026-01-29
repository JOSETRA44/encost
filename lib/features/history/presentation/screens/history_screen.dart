import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/database/database_helper.dart';

/// TAB 2: Historial de Respuestas
/// 
/// Features:
/// - Ver sesiones de recolección completadas
/// - Marcar como exportadas
/// - Exportar a CSV con compartir (WhatsApp, Email, etc.)
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<Map<String, dynamic>> _responses = [];
  bool _isLoading = true;
  bool _showExportedOnly = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      
      String whereClause = '';
      if (_showExportedOnly) {
        whereClause = 'WHERE responses.is_exported = 1';
      }
      
      final result = await db.rawQuery('''
        SELECT 
          responses.*,
          surveys.title as survey_title,
          (SELECT COUNT(*) FROM answers WHERE answers.response_id = responses.id) as answer_count
        FROM responses
        LEFT JOIN surveys ON responses.survey_id = surveys.id
        $whereClause
        ORDER BY responses.timestamp DESC
      ''');
      
      setState(() {
        _responses = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
    }
  }

  Future<void> _toggleExported(String responseId, bool currentValue) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'responses',
        {'is_exported': currentValue ? 0 : 1},
        where: 'id = ?',
        whereArgs: [responseId],
      );
      _loadResponses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    if (_responses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay respuestas para exportar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final List<List<dynamic>> csvData = [];
      
      // Encabezados
      csvData.add([
        'ID Respuesta',
        'Encuesta',
        'Fecha',
        'Hora',
        'Pregunta ID',
        'Pregunta',
        'Respuesta',
        'Estado'
      ]);

      // Obtener todas las respuestas con sus answers
      for (final response in _responses) {
        final responseId = response['id'] as String;
        final surveyId = response['survey_id'] as String;
        final surveyTitle = response['survey_title'] as String? ?? 'Sin título';
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
          response['timestamp'] as int,
        );
        final isExported = (response['is_exported'] as int) == 1;

        // Obtener estructura de la encuesta para etiquetas de preguntas
        final surveyResult = await db.query(
          'surveys',
          where: 'id = ?',
          whereArgs: [surveyId],
        );
        
        Map<String, String> questionLabels = {};
        if (surveyResult.isNotEmpty) {
          final jsonStructure = surveyResult.first['json_structure'] as String;
          final surveyJson = jsonDecode(jsonStructure) as Map<String, dynamic>;
          final fields = surveyJson['fields'] as List<dynamic>;
          for (final field in fields) {
            final fieldMap = field as Map<String, dynamic>;
            questionLabels[fieldMap['id'] as String] = fieldMap['label'] as String;
          }
        }

        // Obtener answers
        final answers = await db.query(
          'answers',
          where: 'response_id = ?',
          whereArgs: [responseId],
          orderBy: 'question_id ASC',
        );

        if (answers.isEmpty) {
          // Si no hay respuestas, agregar fila vacía
          csvData.add([
            responseId,
            surveyTitle,
            '${timestamp.day}/${timestamp.month}/${timestamp.year}',
            '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
            '',
            '',
            '(sin respuestas)',
            isExported ? 'Exportada' : 'Pendiente',
          ]);
        } else {
          // Agregar una fila por cada respuesta
          for (final answer in answers) {
            final questionId = answer['question_id'] as String;
            final value = answer['value'] as String;
            final questionLabel = questionLabels[questionId] ?? questionId;

            csvData.add([
              responseId,
              surveyTitle,
              '${timestamp.day}/${timestamp.month}/${timestamp.year}',
              '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
              questionId,
              questionLabel,
              value,
              isExported ? 'Exportada' : 'Pendiente',
            ]);
          }
        }
      }

      // Generar CSV
      final csvString = const ListToCsvConverter().convert(csvData);
      
      // Guardar archivo
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now();
      final fileName = 'encuestas_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour}${timestamp.minute}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvString, encoding: utf8);

      setState(() => _isExporting = false);

      // Compartir archivo
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Exportación de Encuestas',
        text: 'Datos de ${_responses.length} respuesta(s) exportadas en formato CSV',
      );

      if (result.status == ShareResultStatus.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ CSV exportado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteResponse(String responseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar esta respuesta? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('responses', where: 'id = ?', whereArgs: [responseId]);
        _loadResponses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Respuesta eliminada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _showExportedOnly = !_showExportedOnly);
              _loadResponses();
            },
            icon: Icon(_showExportedOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: _showExportedOnly ? 'Mostrar todas' : 'Solo exportadas',
          ),
          IconButton(
            onPressed: _loadResponses,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _responses.isEmpty
              ? _buildEmptyState()
              : _buildResponsesList(),
      floatingActionButton: _responses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isExporting ? null : _exportToCSV,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.file_download),
              label: Text(_isExporting ? 'Exportando...' : 'Exportar CSV'),
              backgroundColor: _isExporting ? Colors.grey : const Color(0xFF1565C0),
              tooltip: 'Exportar respuestas a CSV y compartir',
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              _showExportedOnly 
                ? 'No hay respuestas exportadas'
                : 'No hay respuestas registradas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _showExportedOnly
                ? 'Las respuestas exportadas aparecerán aquí'
                : 'Completa una encuesta para ver el historial',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsesList() {
    return RefreshIndicator(
      onRefresh: _loadResponses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _responses.length,
        itemBuilder: (context, index) {
          final response = _responses[index];
          final timestamp = DateTime.fromMillisecondsSinceEpoch(
            response['timestamp'] as int,
          );
          final isExported = (response['is_exported'] as int) == 1;
          final answerCount = response['answer_count'] as int;
          final surveyTitle = response['survey_title'] as String? ?? 'Encuesta eliminada';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isExported ? Colors.green.shade200 : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isExported 
                    ? Colors.green.shade50 
                    : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isExported ? Icons.check_circle : Icons.pending,
                  color: isExported ? Colors.green : Colors.orange,
                  size: 28,
                ),
              ),
              title: Text(
                surveyTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.question_answer, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '$answerCount respuestas',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      isExported ? 'Exportada' : 'Pendiente',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isExported ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                    backgroundColor: isExported 
                      ? Colors.green.shade50 
                      : Colors.orange.shade50,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => Future.delayed(
                      Duration.zero,
                      () => _toggleExported(response['id'] as String, isExported),
                    ),
                    child: Row(
                      children: [
                        Icon(isExported ? Icons.undo : Icons.check),
                        const SizedBox(width: 8),
                        Text(isExported ? 'Marcar pendiente' : 'Marcar exportada'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => Future.delayed(
                      Duration.zero,
                      () => _deleteResponse(response['id'] as String),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
