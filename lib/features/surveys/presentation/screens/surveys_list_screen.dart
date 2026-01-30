import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/csv_exporter.dart';
import 'package:uuid/uuid.dart';
import '../../../survey/presentation/screens/survey_form_screen.dart';
import 'create_survey_screen.dart';

/// TAB 1: Lista de Encuestas Disponibles
/// 
/// Features:
/// - Ver plantillas disponibles
/// - Importar nuevo JSON (pegar desde clipboard)
/// - Iniciar nueva recolección
class SurveysListScreen extends ConsumerStatefulWidget {
  const SurveysListScreen({super.key});

  @override
  ConsumerState<SurveysListScreen> createState() => _SurveysListScreenState();
}

class _SurveysListScreenState extends ConsumerState<SurveysListScreen> {
  List<Map<String, dynamic>> _surveys = [];
  Map<String, int> _responseCounts = {}; // Contador de respuestas por encuesta
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Cargar encuestas
      final result = await db.query(
        'surveys',
        orderBy: 'created_at DESC',
      );

      // Cargar conteo de respuestas para cada encuesta
      final counts = <String, int>{};
      for (var survey in result) {
        final surveyId = survey['id'] as String;
        final countResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM responses WHERE survey_id = ?',
          [surveyId],
        );
        counts[surveyId] = Sqflite.firstIntValue(countResult) ?? 0;
      }

      setState(() {
        _surveys = result;
        _responseCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar encuestas: $e')),
        );
      }
    }
  }

  Future<void> _exportSurveyToCSV(String surveyId, String surveyTitle) async {
    try {
      // 🚀 USAR NUEVO EXPORTADOR HORIZONTAL
      final result = await CsvExporter.exportSurvey(surveyId, surveyTitle);
      
      if (!result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Error desconocido'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Compartir archivo
      await CsvExporter.shareFile(
        result.file!,
        'Exportación: $surveyTitle',
        'Datos de ${result.rowCount} respuesta(s) en formato CSV horizontal',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ CSV exportado: ${result.rowCount} respuestas'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
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

  Future<void> _showImportDialog() async {
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.upload_file, color: Color(0xFF1565C0)),
            SizedBox(width: 12),
            Text('Importar Encuesta JSON'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pega aquí el JSON generado por IA:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 12,
                decoration: InputDecoration(
                  hintText: '{\n  "id": "campo_v1",\n  "title": "...",\n  "fields": [...]\n}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final clipboard = await Clipboard.getData('text/plain');
                  if (clipboard?.text != null) {
                    controller.text = clipboard!.text!;
                  }
                },
                icon: const Icon(Icons.content_paste, size: 18),
                label: const Text('Pegar desde portapapeles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final success = await _importSurvey(controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Encuesta importada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadSurveys();
                }
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Importar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _importSurvey(String jsonText) async {
    try {
      final json = jsonDecode(jsonText) as Map<String, dynamic>;
      
      // Validar estructura mínima
      if (!json.containsKey('id') || !json.containsKey('title') || !json.containsKey('fields')) {
        throw 'JSON inválido: requiere campos "id", "title" y "fields"';
      }

      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert('surveys', {
        'id': json['id'] as String,
        'title': json['title'] as String,
        'version': json['version'] ?? '1.0',
        'json_structure': jsonText,
        'created_at': now,
        'updated_at': now,
      });

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _startSurvey(String surveyId, String title) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final responseId = const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert('responses', {
        'id': responseId,
        'survey_id': surveyId,
        'timestamp': now,
        'is_exported': 0,
      });

      if (mounted) {
        // Navegar a pantalla de llenado de formulario
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SurveyFormScreen(
              responseId: responseId,
              surveyId: surveyId,
            ),
          ),
        );

        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✓ Encuesta "$title" completada')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar encuesta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Encuestas',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _loadSurveys,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _surveys.isEmpty
              ? _buildEmptyState()
              : _buildSurveysList(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateSurveyScreen(),
                ),
              );
              if (result == true && mounted) {
                _loadSurveys();
              }
            },
            heroTag: 'create_survey',
            icon: const Icon(Icons.edit),
            label: const Text('Crear Manualmente'),
            backgroundColor: const Color(0xFF1565C0),
            tooltip: 'Crear encuesta con constructor visual',
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: _showImportDialog,
            heroTag: 'import_json',
            icon: const Icon(Icons.code),
            label: const Text('Importar JSON'),
            backgroundColor: Colors.grey[700],
            tooltip: 'Importar encuesta desde JSON',
          ),
        ],
      ),
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
              Icons.assignment_outlined,
              size: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'No hay encuestas disponibles',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Importa tu primer cuestionario usando el botón de abajo',
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

  Widget _buildSurveysList() {
    return RefreshIndicator(
      onRefresh: _loadSurveys,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _surveys.length,
        itemBuilder: (context, index) {
          final survey = _surveys[index];
          final surveyId = survey['id'] as String;
          final createdAt = DateTime.fromMillisecondsSinceEpoch(
            survey['created_at'] as int,
          );
          final responseCount = _responseCounts[surveyId] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: Color(0xFF1565C0),
                      size: 28,
                    ),
                  ),
                  // Badge de contador
                  if (responseCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$responseCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                survey['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Versión: ${survey['version']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Creada: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  if (responseCount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$responseCount respuesta${responseCount != 1 ? 's' : ''} registrada${responseCount != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón de exportación
                  if (responseCount > 0)
                    IconButton(
                      onPressed: () => _exportSurveyToCSV(
                        surveyId,
                        survey['title'] as String,
                      ),
                      icon: const Icon(Icons.file_download),
                      color: Colors.green.shade700,
                      tooltip: 'Exportar CSV de esta encuesta',
                    ),
                  const SizedBox(width: 4),
                  // Botón de iniciar
                  FilledButton(
                    onPressed: () => _startSurvey(
                      surveyId,
                      survey['title'] as String,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Iniciar'),
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
