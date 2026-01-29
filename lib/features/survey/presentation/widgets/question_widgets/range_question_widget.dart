import 'package:flutter/material.dart';
import '../../../domain/entities/question.dart';

/// Widget para Preguntas de RANGE (Slider)
class RangeQuestionWidget extends StatelessWidget {
  final Question question;
  final num? currentValue;
  final Function(num) onChanged;
  final String? errorText;

  const RangeQuestionWidget({
    super.key,
    required this.question,
    this.currentValue,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final min = (question.validation?.min ?? 0).toDouble();
    final max = (question.validation?.max ?? 10).toDouble();
    final value = (currentValue ?? min).toDouble();
    
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
        
        const SizedBox(height: 24),
        
        // Valor actual destacado
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: Text(
              value.toStringAsFixed(
                question.validation?.decimals ?? 0,
              ),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Slider
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / (question.validation?.step ?? 1)).round(),
          onChanged: (newValue) => onChanged(newValue),
        ),
        
        // Labels min/max
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      min.toString(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    if (question.minLabel != null)
                      Text(
                        question.minLabel!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      max.toString(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    if (question.maxLabel != null)
                      Text(
                        question.maxLabel!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}
