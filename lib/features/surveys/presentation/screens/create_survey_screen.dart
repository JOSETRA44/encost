import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/database/database_helper.dart';

/// Constructor Visual de Encuestas (Sin JSON manual)
/// 
/// Permite crear plantillas de formularios mediante UI drag-and-drop
class CreateSurveyScreen extends StatefulWidget {
  const CreateSurveyScreen({super.key});

  @override
  State<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends State<CreateSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _versionController = TextEditingController(text: '1.0');
  final List<Map<String, dynamic>> _questions = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  Future<void> _saveSurvey() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos una pregunta'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Generar ID único
      final surveyId = 'survey_${DateTime.now().millisecondsSinceEpoch}';
      
      // Construir JSON internamente
      final surveyJson = {
        'id': surveyId,
        'title': _titleController.text.trim(),
        'version': _versionController.text.trim(),
        'fields': _questions,
      };

      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert('surveys', {
        'id': surveyId,
        'title': _titleController.text.trim(),
        'version': _versionController.text.trim(),
        'json_structure': jsonEncode(surveyJson),
        'created_at': now,
        'updated_at': now,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Encuesta creada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addQuestion(String type) {
    setState(() {
      final questionId = 'q${_questions.length + 1}';
      final question = <String, dynamic>{
        'id': questionId,
        'type': type,
        'label': '',
      };
      
      if (type == 'radio' || type == 'checkbox') {
        question['options'] = <String>[];
      }
      
      _questions.add(question);
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _showQuestionTypeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el tipo de pregunta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuestionTypeOption(
              icon: Icons.text_fields,
              title: 'Texto',
              subtitle: 'Respuesta de texto libre',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _addQuestion('text');
              },
            ),
            _buildQuestionTypeOption(
              icon: Icons.numbers,
              title: 'Número',
              subtitle: 'Respuesta numérica',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                _addQuestion('number');
              },
            ),
            _buildQuestionTypeOption(
              icon: Icons.radio_button_checked,
              title: 'Opción única',
              subtitle: 'Seleccionar una opción (radio buttons)',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _addQuestion('radio');
              },
            ),
            _buildQuestionTypeOption(
              icon: Icons.check_box,
              title: 'Opción múltiple',
              subtitle: 'Seleccionar varias opciones (checkboxes)',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                _addQuestion('checkbox');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionTypeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear Encuesta',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveSurvey,
              icon: const Icon(Icons.check),
              tooltip: 'Guardar encuesta',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información básica
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF1565C0)),
                        SizedBox(width: 8),
                        Text(
                          'Información de la Encuesta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Título de la encuesta *',
                        hintText: 'Ej: Encuesta de Satisfacción 2026',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El título es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _versionController,
                      decoration: InputDecoration(
                        labelText: 'Versión',
                        hintText: '1.0',
                        prefixIcon: const Icon(Icons.tag),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Lista de preguntas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Preguntas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Chip(
                  label: Text('${_questions.length} preguntas'),
                  backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                  side: BorderSide.none,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (_questions.isEmpty)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay preguntas aún',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega tu primera pregunta usando el botón de abajo',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return _buildQuestionCard(index, question);
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuestionTypeSelector,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Pregunta'),
        backgroundColor: const Color(0xFF1565C0),
      ),
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> question) {
    final type = question['type'] as String;
    final hasOptions = type == 'radio' || type == 'checkbox';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getQuestionTypeColor(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getQuestionTypeIcon(type),
                        size: 16,
                        color: _getQuestionTypeColor(type),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getQuestionTypeName(type),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getQuestionTypeColor(type),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _removeQuestion(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Eliminar pregunta',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: question['label'] as String,
              decoration: InputDecoration(
                labelText: 'Texto de la pregunta *',
                hintText: 'Escribe la pregunta...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  question['label'] = value;
                });
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La pregunta es obligatoria';
                }
                return null;
              },
            ),
            if (hasOptions) ...[
              const SizedBox(height: 12),
              _buildOptionsEditor(question),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsEditor(Map<String, dynamic> question) {
    final options = question['options'] as List<String>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opciones:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...options.asMap().entries.map((entry) {
          final optionIndex = entry.key;
          final option = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: option,
                    decoration: InputDecoration(
                      hintText: 'Opción ${optionIndex + 1}',
                      prefixIcon: Icon(
                        question['type'] == 'radio' 
                          ? Icons.radio_button_unchecked 
                          : Icons.check_box_outline_blank,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        options[optionIndex] = value;
                      });
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      options.removeAt(optionIndex);
                    });
                  },
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.red,
                ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              options.add('');
            });
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Agregar opción'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1565C0),
          ),
        ),
      ],
    );
  }

  IconData _getQuestionTypeIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.text_fields;
      case 'number':
        return Icons.numbers;
      case 'radio':
        return Icons.radio_button_checked;
      case 'checkbox':
        return Icons.check_box;
      default:
        return Icons.help_outline;
    }
  }

  Color _getQuestionTypeColor(String type) {
    switch (type) {
      case 'text':
        return Colors.blue;
      case 'number':
        return Colors.green;
      case 'radio':
        return Colors.orange;
      case 'checkbox':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getQuestionTypeName(String type) {
    switch (type) {
      case 'text':
        return 'Texto';
      case 'number':
        return 'Número';
      case 'radio':
        return 'Opción única';
      case 'checkbox':
        return 'Opción múltiple';
      default:
        return type;
    }
  }
}
