import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget para preguntas tipo Matriz (Tablas de entrada de datos)
/// 
/// Arquitectura: Gestiona estado complejo Map de String a Map de String a dynamic
/// Formato: rows = ["Fila A", "Fila B"], columns = [{"key": "c1", "label": "Precio", "type": "number"}]
class MatrixQuestionWidget extends StatefulWidget {
  final String id;
  final String label;
  final List<String> rows;
  final List<Map<String, dynamic>> columns;
  final Function(String, dynamic) onChanged;
  final Map<String, Map<String, dynamic>>? initialValue;

  const MatrixQuestionWidget({
    super.key,
    required this.id,
    required this.label,
    required this.rows,
    required this.columns,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<MatrixQuestionWidget> createState() => _MatrixQuestionWidgetState();
}

class _MatrixQuestionWidgetState extends State<MatrixQuestionWidget> {
  late Map<String, Map<String, dynamic>> _matrixData;
  final Map<String, Map<String, TextEditingController>> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeMatrix();
  }

  void _initializeMatrix() {
    _matrixData = widget.initialValue ?? {};
    
    // Inicializar controladores para cada celda
    for (final row in widget.rows) {
      _controllers[row] = {};
      if (!_matrixData.containsKey(row)) {
        _matrixData[row] = {};
      }
      
      for (final column in widget.columns) {
        final columnKey = column['key'] as String;
        final existingValue = _matrixData[row]![columnKey];
        
        _controllers[row]![columnKey] = TextEditingController(
          text: existingValue?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    // Limpiar todos los controladores
    for (final rowControllers in _controllers.values) {
      for (final controller in rowControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _updateCell(String row, String columnKey, String value, String columnType) {
    setState(() {
      if (value.isEmpty) {
        _matrixData[row]!.remove(columnKey);
      } else {
        // Convertir según tipo de columna
        if (columnType == 'number') {
          final numValue = double.tryParse(value);
          _matrixData[row]![columnKey] = numValue ?? value;
        } else {
          _matrixData[row]![columnKey] = value;
        }
      }
      
      // Notificar cambio con copia profunda
      widget.onChanged(widget.id, Map<String, Map<String, dynamic>>.from(
        _matrixData.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)))
      ));
    });
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
        
        // Scroll horizontal para tablas anchas
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade200),
                verticalInside: BorderSide(color: Colors.grey.shade200),
              ),
              columnSpacing: 16,
              dataRowMinHeight: 60,
              dataRowMaxHeight: 80,
              columns: [
                // Primera columna: nombres de filas
                const DataColumn(
                  label: Text(
                    '',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Columnas de datos
                ...widget.columns.map((column) {
                  return DataColumn(
                    label: Flexible(
                      child: Text(
                        column['label'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }),
              ],
              rows: widget.rows.map((row) {
                return DataRow(
                  cells: [
                    // Primera celda: nombre de fila
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          row,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    // Celdas de entrada
                    ...widget.columns.map((column) {
                      final columnKey = column['key'] as String;
                      final columnType = column['type'] as String;
                      final controller = _controllers[row]![columnKey]!;
                      
                      return DataCell(
                        Container(
                          constraints: const BoxConstraints(minWidth: 120),
                          child: TextField(
                            controller: controller,
                            keyboardType: columnType == 'number'
                                ? const TextInputType.numberWithOptions(decimal: true)
                                : TextInputType.text,
                            inputFormatters: columnType == 'number'
                                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
                                : null,
                            decoration: InputDecoration(
                              hintText: columnType == 'number' ? '0' : 'Escribe...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1565C0),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13),
                            onChanged: (value) => _updateCell(row, columnKey, value, columnType),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Indicador de progreso
        if (_matrixData.values.any((row) => row.isNotEmpty))
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
              const SizedBox(width: 6),
              Text(
                '${_countFilledCells()} de ${widget.rows.length * widget.columns.length} celdas completadas',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
      ],
    );
  }

  int _countFilledCells() {
    int count = 0;
    for (final rowData in _matrixData.values) {
      count += rowData.length;
    }
    return count;
  }
}
