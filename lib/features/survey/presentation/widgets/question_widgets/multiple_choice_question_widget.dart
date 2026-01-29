import 'package:flutter/material.dart';
import '../../../domain/entities/question.dart';
import '../../../domain/entities/question_option.dart';

/// Widget para Preguntas de MULTIPLE_CHOICE (Checkboxes)
class MultipleChoiceQuestionWidget extends StatelessWidget {
  final Question question;
  final List<String>? currentValue;
  final Function(List<String>) onChanged;
  final String? errorText;

  const MultipleChoiceQuestionWidget({
    super.key,
    required this.question,
    this.currentValue,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final selectedValues = currentValue ?? [];
    
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
        
        ...question.options!.map((option) => _buildCheckboxOption(
              context,
              option,
              selectedValues,
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

  Widget _buildCheckboxOption(
    BuildContext context,
    QuestionOption option,
    List<String> selectedValues,
  ) {
    final isSelected = selectedValues.contains(option.value);
    
    return InkWell(
      onTap: () {
        final newSelection = List<String>.from(selectedValues);
        if (isSelected) {
          newSelection.remove(option.value);
        } else {
          newSelection.add(option.value);
        }
        onChanged(newSelection);
      },
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
            Checkbox(
              value: isSelected,
              onChanged: (checked) {
                final newSelection = List<String>.from(selectedValues);
                if (checked == true) {
                  newSelection.add(option.value);
                } else {
                  newSelection.remove(option.value);
                }
                onChanged(newSelection);
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
