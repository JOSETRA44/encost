import 'package:flutter/material.dart';
import '../../../domain/entities/question.dart';
import '../../../domain/entities/question_option.dart';

/// Widget para Preguntas de SINGLE_CHOICE (Radio Buttons)
class SingleChoiceQuestionWidget extends StatelessWidget {
  final Question question;
  final String? currentValue;
  final Function(String) onChanged;
  final String? errorText;

  const SingleChoiceQuestionWidget({
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
        
        // Opciones de radio
        ...question.options!.map((option) => _buildRadioOption(
              context,
              option,
            )),
        
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

  Widget _buildRadioOption(BuildContext context, QuestionOption option) {
    final isSelected = currentValue == option.value;
    
    return InkWell(
      onTap: () => onChanged(option.value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[400]!,
            width: isSelected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: option.value,
              groupValue: currentValue,
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
              visualDensity: VisualDensity.comfortable,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
