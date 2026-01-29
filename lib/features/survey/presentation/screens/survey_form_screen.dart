import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/database/database_helper.dart';
import '../widgets/survey_question_factory.dart';

/// Pantalla de llenado de formulario (Motor de renderizado dinámico)
/// 
/// Features:
/// - Renderiza formularios desde JSON usando Factory Pattern
/// - Guarda respuestas individuales en tabla 'answers'
/// - Progress indicator con validación
class SurveyFormScreen extends StatefulWidget {
  final String responseId;
  final String surveyId;

  const SurveyFormScreen({
    super.key,
    required this.responseId,
    required this.surveyId,
  });

  @override
  State<SurveyFormScreen> createState() => _SurveyFormScreenState();
}

class _SurveyFormScreenState extends State<SurveyFormScreen> {
  Map<String, dynamic>? _surveyData;
  final Map<String, dynamic> _answers = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSurvey();
  }

  Future<void> _loadSurvey() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'surveys',
        where: 'id = ?',
        whereArgs: [widget.surveyId],
      );

      if (result.isEmpty) {
        throw 'Encuesta no encontrada';
      }

      final jsonString = result.first['json_structure'] as String;
      setState(() {
        _surveyData = jsonDecode(jsonString) as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar encuesta: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveAndFinish() async {
    if (_answers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Responde al menos una pregunta'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Guardar cada respuesta en la tabla answers
      for (final entry in _answers.entries) {
        await db.insert('answers', {
          'response_id': widget.responseId,
          'question_id': entry.key,
          'value': entry.value is List 
            ? jsonEncode(entry.value) 
            : entry.value.toString(),
          'answered_at': now,
        });
      }

      // Actualizar response como completada
      await db.update(
        'responses',
        {'completed_at': now},
        where: 'id = ?',
        whereArgs: [widget.responseId],
      );

      setState(() => _isSaving = false);

      if (mounted) {
        _showSuccessDialog();
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

  void _handleAnswer(String questionId, dynamic value) {
    setState(() {
      _answers[questionId] = value;
    });
  }

  double _calculateProgress() {
    if (_surveyData == null) return 0.0;
    final fields = _surveyData!['fields'] as List;
    if (fields.isEmpty) return 0.0;
    return _answers.length / fields.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _surveyData?['title'] ?? 'Cargando...',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_surveyData != null)
              Text(
                '${_answers.length} de ${(_surveyData!['fields'] as List).length} respondidas',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
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
              onPressed: _saveAndFinish,
              icon: const Icon(Icons.check),
              tooltip: 'Finalizar y guardar',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _calculateProgress(),
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    final fields = _surveyData!['fields'] as List;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: fields.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final field = fields[index] as Map<String, dynamic>;
        final questionId = field['id'] as String;

        return Card(
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
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _answers.containsKey(questionId)
                          ? Colors.green
                          : const Color(0xFF1565C0).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: _answers.containsKey(questionId)
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pregunta ${index + 1} de ${fields.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SurveyQuestionFactory.createQuestion(
                  field: field,
                  onChanged: _handleAnswer,
                  initialValue: _answers[questionId],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
