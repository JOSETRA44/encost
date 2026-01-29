import 'package:flutter/material.dart';
import '../../../domain/entities/question.dart';

/// Widget para Preguntas de Tipo NUMERIC
class NumericQuestionWidget extends StatelessWidget {
  final Question question;
  final num? currentValue;
  final Function(num?) onChanged;
  final String? errorText;

  const NumericQuestionWidget({
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
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineSmall,
            children: [
              TextSpan(text: question.title),
              if (question.required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
        
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
        
        TextField(
          controller: TextEditingController(
            text: currentValue?.toString() ?? '',
          )..selection = TextSelection.collapsed(
              offset: currentValue?.toString().length ?? 0,
            ),
          onChanged: (value) {
            if (value.isEmpty) {
              onChanged(null);
              return;
            }
            
            final parsed = question.validation?.decimals == 0
                ? int.tryParse(value)
                : double.tryParse(value);
            onChanged(parsed);
          },
          keyboardType: TextInputType.numberWithOptions(
            decimal: (question.validation?.decimals ?? 0) > 0,
            signed: (question.validation?.min ?? 0) < 0,
          ),
          decoration: InputDecoration(
            hintText: question.placeholder,
            errorText: errorText,
            suffixText: question.unit,
            suffixStyle: Theme.of(context).textTheme.bodyLarge,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        
        // Indicadores de rango
        if (question.validation?.min != null || 
            question.validation?.max != null) ...[
          const SizedBox(height: 8),
          Text(
            'Rango: ${question.validation?.min ?? '...'} - ${question.validation?.max ?? '...'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ],
    );
  }
}
