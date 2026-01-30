import 'package:flutter/material.dart';
import 'question_widgets/matrix_question_widget.dart';

/// Factory Pattern - Motor de renderizado dinámico de formularios
/// 
/// Arquitectura: Fábrica que convierte JSON en Widgets
/// Formato soportado: { "type": "text|number|radio|checkbox|matrix", ... }
class SurveyQuestionFactory {
  /// Crea un widget de pregunta basado en el JSON
  /// 
  /// Parámetros:
  /// - field: Mapa con estructura {"id", "type", "label", "options"?}
  /// - onChanged: Callback cuando el usuario responde
  /// - initialValue: Valor inicial (opcional)
  static Widget createQuestion({
    required Map<String, dynamic> field,
    required Function(String questionId, dynamic value) onChanged,
    dynamic initialValue,
  }) {
    final type = field['type'] as String;
    final id = field['id'] as String;
    final label = field['label'] as String;

    switch (type.toLowerCase()) {
      case 'text':
        return TextQuestionWidget(
          id: id,
          label: label,
          onChanged: onChanged,
          initialValue: initialValue as String?,
        );

      case 'number':
        return NumberQuestionWidget(
          id: id,
          label: label,
          onChanged: onChanged,
          initialValue: initialValue,
        );

      case 'radio':
        final options = (field['options'] as List?)?.cast<String>() ?? [];
        return RadioQuestionWidget(
          id: id,
          label: label,
          options: options,
          onChanged: onChanged,
          initialValue: initialValue as String?,
        );

      case 'checkbox':
        final options = (field['options'] as List?)?.cast<String>() ?? [];
        return CheckboxQuestionWidget(
          id: id,
          label: label,
          options: options,
          onChanged: onChanged,
          initialValue: initialValue as List<String>?,
        );

      case 'matrix':
        final rows = (field['rows'] as List?)?.cast<String>() ?? [];
        final columns = (field['columns'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        return MatrixQuestionWidget(
          id: id,
          label: label,
          rows: rows,
          columns: columns,
          onChanged: onChanged,
          initialValue: initialValue as Map<String, Map<String, dynamic>>?,
        );

      default:
        return ErrorQuestionWidget(
          message: 'Tipo de pregunta no soportado: $type',
        );
    }
  }
}

/// Widget para preguntas de texto libre
class TextQuestionWidget extends StatefulWidget {
  final String id;
  final String label;
  final Function(String, String) onChanged;
  final String? initialValue;

  const TextQuestionWidget({
    super.key,
    required this.id,
    required this.label,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<TextQuestionWidget> createState() => _TextQuestionWidgetState();
}

class _TextQuestionWidgetState extends State<TextQuestionWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          onChanged: (value) => widget.onChanged(widget.id, value),
          decoration: InputDecoration(
            hintText: 'Escribe tu respuesta...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}

/// Widget para preguntas numéricas
class NumberQuestionWidget extends StatefulWidget {
  final String id;
  final String label;
  final Function(String, dynamic) onChanged;
  final dynamic initialValue;

  const NumberQuestionWidget({
    super.key,
    required this.id,
    required this.label,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<NumberQuestionWidget> createState() => _NumberQuestionWidgetState();
}

class _NumberQuestionWidgetState extends State<NumberQuestionWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final numValue = num.tryParse(value);
            widget.onChanged(widget.id, numValue ?? value);
          },
          decoration: InputDecoration(
            hintText: 'Ingresa un número...',
            prefixIcon: const Icon(Icons.numbers),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}

/// Widget para preguntas de opción única (radio buttons)
class RadioQuestionWidget extends StatefulWidget {
  final String id;
  final String label;
  final List<String> options;
  final Function(String, String) onChanged;
  final String? initialValue;

  const RadioQuestionWidget({
    super.key,
    required this.id,
    required this.label,
    required this.options,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<RadioQuestionWidget> createState() => _RadioQuestionWidgetState();
}

class _RadioQuestionWidgetState extends State<RadioQuestionWidget> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.options.map((option) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _selectedValue == option 
                ? const Color(0xFF1565C0).withOpacity(0.1) 
                : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedValue == option 
                  ? const Color(0xFF1565C0) 
                  : Colors.grey.shade300,
                width: _selectedValue == option ? 2 : 1,
              ),
            ),
            child: RadioListTile<String>(
              title: Text(
                option,
                style: TextStyle(
                  fontWeight: _selectedValue == option 
                    ? FontWeight.w600 
                    : FontWeight.normal,
                ),
              ),
              value: option,
              groupValue: _selectedValue,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedValue = value);
                  widget.onChanged(widget.id, value);
                }
              },
              activeColor: const Color(0xFF1565C0),
            ),
          );
        }),
      ],
    );
  }
}

/// Widget para preguntas de opción múltiple (checkboxes)
class CheckboxQuestionWidget extends StatefulWidget {
  final String id;
  final String label;
  final List<String> options;
  final Function(String, List<String>) onChanged;
  final List<String>? initialValue;

  const CheckboxQuestionWidget({
    super.key,
    required this.id,
    required this.label,
    required this.options,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<CheckboxQuestionWidget> createState() => _CheckboxQuestionWidgetState();
}

class _CheckboxQuestionWidgetState extends State<CheckboxQuestionWidget> {
  final Set<String> _selectedValues = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _selectedValues.addAll(widget.initialValue!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.options.map((option) {
          final isSelected = _selectedValues.contains(option);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected 
                ? const Color(0xFF1565C0).withOpacity(0.1) 
                : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                  ? const Color(0xFF1565C0) 
                  : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: CheckboxListTile(
              title: Text(
                option,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedValues.add(option);
                  } else {
                    _selectedValues.remove(option);
                  }
                });
                widget.onChanged(widget.id, _selectedValues.toList());
              },
              activeColor: const Color(0xFF1565C0),
            ),
          );
        }),
      ],
    );
  }
}

/// Widget de error para tipos no soportados
class ErrorQuestionWidget extends StatelessWidget {
  final String message;

  const ErrorQuestionWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
