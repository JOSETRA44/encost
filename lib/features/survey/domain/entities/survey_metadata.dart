import 'package:equatable/equatable.dart';

/// Entidad de Dominio: Metadatos de Encuesta
class SurveyMetadata extends Equatable {
  final String author;
  final String category;
  final List<String> tags;

  const SurveyMetadata({
    required this.author,
    required this.category,
    required this.tags,
  });

  @override
  List<Object?> get props => [author, category, tags];
}
