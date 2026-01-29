import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../../core/database/database_helper.dart';
import 'package:uuid/uuid.dart';
import '../../../survey/presentation/screens/survey_form_screen.dart';

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
      final result = await db.query(
        'surveys',
        orderBy: 'created_at DESC',
      );
      setState(() {
        _surveys = result;
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImportDialog,
        icon: const Icon(Icons.add),
        label: const Text('Importar JSON'),
        tooltip: 'Importar nuevo cuestionario desde JSON',
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
          final createdAt = DateTime.fromMillisecondsSinceEpoch(
            survey['created_at'] as int,
          );

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
              leading: Container(
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
                ],
              ),
              trailing: FilledButton(
                onPressed: () => _startSurvey(
                  survey['id'] as String,
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
            ),
          );
        },
      ),
    );
  }
}
