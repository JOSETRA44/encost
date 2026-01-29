import 'package:equatable/equatable.dart';

/// Entidad de Dominio: Opción de Respuesta
/// 
/// Principio de Responsabilidad Única (SRP):
/// Solo representa una opción seleccionable en una pregunta
class QuestionOption extends Equatable {
  final String id;
  final String label;
  final String value;

  const QuestionOption({
    required this.id,
    required this.label,
    required this.value,
  });

  @override
  List<Object?> get props => [id, label, value];

  @override
  String toString() => 'QuestionOption(id: $id, label: $label, value: $value)';
}
