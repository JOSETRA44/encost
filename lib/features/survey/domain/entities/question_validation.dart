import 'package:equatable/equatable.dart';

/// Entidad de Dominio: Validación de Pregunta
/// 
/// Principio de Responsabilidad Única (SRP):
/// Encapsula todas las reglas de validación
class QuestionValidation extends Equatable {
  // Validación de Texto
  final int? minLength;
  final int? maxLength;
  final String? pattern;

  // Validación Numérica
  final num? min;
  final num? max;
  final int? decimals;

  // Validación de Selección Múltiple
  final int? minSelections;
  final int? maxSelections;

  // Validación de Rango
  final num? step;

  const QuestionValidation({
    this.minLength,
    this.maxLength,
    this.pattern,
    this.min,
    this.max,
    this.decimals,
    this.minSelections,
    this.maxSelections,
    this.step,
  });

  /// Valida un valor de texto
  String? validateText(String? value) {
    if (value == null || value.isEmpty) return null;

    if (minLength != null && value.length < minLength!) {
      return 'Mínimo $minLength caracteres requeridos';
    }

    if (maxLength != null && value.length > maxLength!) {
      return 'Máximo $maxLength caracteres permitidos';
    }

    if (pattern != null) {
      final regex = RegExp(pattern!);
      if (!regex.hasMatch(value)) {
        return 'Formato inválido';
      }
    }

    return null;
  }

  /// Valida un valor numérico
  String? validateNumeric(num? value) {
    if (value == null) return null;

    if (min != null && value < min!) {
      return 'El valor mínimo es $min';
    }

    if (max != null && value > max!) {
      return 'El valor máximo es $max';
    }

    return null;
  }

  /// Valida selecciones múltiples
  String? validateMultipleSelections(List<String> selections) {
    if (minSelections != null && selections.length < minSelections!) {
      return 'Selecciona al menos $minSelections opciones';
    }

    if (maxSelections != null && selections.length > maxSelections!) {
      return 'Selecciona máximo $maxSelections opciones';
    }

    return null;
  }

  @override
  List<Object?> get props => [
        minLength,
        maxLength,
        pattern,
        min,
        max,
        decimals,
        minSelections,
        maxSelections,
        step,
      ];
}
