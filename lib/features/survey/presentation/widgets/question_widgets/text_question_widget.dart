import 'package:flutter/material.dart';
import '../../../domain/entities/question.dart';

/// Widget para Preguntas de Tipo TEXT
/// 
/// Principio de Responsabilidad Única (SRP):
/// Solo renderiza inputs de texto
class TextQuestionWidget extends StatelessWidget {
  final Question question;
  final String? currentValue;
  final Function(String) onChanged;
  final String? errorText;

  const TextQuestionWidget({
    super.key,
    required this.question,
    this.currentValue,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título con indicador de obligatorio
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineSmall,
            children: [
              TextSpan(text: question.title),
              if (question.required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
        
        // Descripción (si existe)
        if (question.description != null) ...[
          const SizedBox(height: 8),
          Text(
            question.description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Campo de texto
        TextField(
          controller: TextEditingController(text: currentValue)
            ..selection = TextSelection.collapsed(
              offset: currentValue?.length ?? 0,
            ),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: question.placeholder,
            errorText: errorText,
            counterText: question.validation?.maxLength != null
                ? '${currentValue?.length ?? 0}/${question.validation!.maxLength}'
                : null,
          ),
          maxLength: question.validation?.maxLength,
          maxLines: question.validation?.maxLength != null &&
                  question.validation!.maxLength! > 100
              ? 5
              : 1,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
