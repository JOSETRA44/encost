import 'package:equatable/equatable.dart';

/// Clase base para todos los errores de la aplicación
/// 
/// Principio de Segregación de Interfaces (ISP):
/// Cada tipo de error tiene su propia clase específica
abstract class Failure extends Equatable {
  final String message;
  final String? details;

  const Failure({
    required this.message,
    this.details,
  });

  @override
  List<Object?> get props => [message, details];
}

/// Error de caché/almacenamiento
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.details,
  });
}

/// Error de parseo de JSON
class ParsingFailure extends Failure {
  const ParsingFailure({
    required super.message,
    super.details,
  });
}

/// Error de validación
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.details,
  });
}

/// Error de archivo no encontrado
class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure({
    required super.message,
    super.details,
  });
}

/// Error de operación de exportación
class ExportFailure extends Failure {
  const ExportFailure({
    required super.message,
    super.details,
  });
}

/// Error general/inesperado
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required super.message,
    super.details,
  });
}
