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

  Future<void> _showSuccessDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono de éxito animado
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Respuestas Guardadas!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Los datos se han registrado correctamente en el dispositivo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Botón primario: Registrar otra
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.replay),
                label: const Text('Registrar Otra Respuesta'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Botón secundario: Terminar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.home),
                label: const Text('Terminar por ahora'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      // Usuario eligió "Terminar"
      Navigator.pop(context, true);
    } else {
      // Usuario eligió "Registrar otra" - Resetear formulario
      setState(() {
        _answers.clear();
      });
      // Scroll al inicio
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
      // Feedback visual
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📝 Formulario listo para nueva respuesta'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  double _calculateProgress() {
    if (_surveyData == null) return 0.0;
    final fields = _surveyData!['fields'] as List;
    if (fields.isEmpty) return 0.0;
    return _answers.length / fields.length;
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      controller: _scrollController,
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
