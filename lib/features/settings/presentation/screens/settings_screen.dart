import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

/// TAB 3: Configuración y Ajustes
/// 
/// Features:
/// - Información de la base de datos
/// - Estadísticas de uso
/// - Gestión de datos (limpiar, exportar)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      
      final surveysCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM surveys'),
      ) ?? 0;
      
      final responsesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM responses'),
      ) ?? 0;
      
      final answersCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM answers'),
      ) ?? 0;
      
      final exportedCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM responses WHERE is_exported = 1'),
      ) ?? 0;

      setState(() {
        _stats = {
          'surveys': surveysCount,
          'responses': responsesCount,
          'answers': answersCount,
          'exported': exportedCount,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar estadísticas: $e')),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('¿Eliminar todos los datos?'),
          ],
        ),
        content: const Text(
          'Esta acción eliminará TODAS las encuestas, respuestas y configuraciones. '
          'No se puede deshacer.\n\n¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper.instance.deleteDatabase();
        await DatabaseHelper.instance.database; // Recrear DB
        _loadStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Todos los datos han sido eliminados'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar datos: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar estadísticas',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatsSection(),
                const SizedBox(height: 24),
                _buildDatabaseSection(),
                const SizedBox(height: 24),
                _buildAboutSection(),
              ],
            ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Text(
                  'Estadísticas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatItem(
              icon: Icons.assignment,
              label: 'Encuestas disponibles',
              value: _stats['surveys']?.toString() ?? '0',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              icon: Icons.checklist,
              label: 'Respuestas registradas',
              value: _stats['responses']?.toString() ?? '0',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              icon: Icons.question_answer,
              label: 'Respuestas individuales',
              value: _stats['answers']?.toString() ?? '0',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              icon: Icons.file_upload,
              label: 'Exportadas',
              value: _stats['exported']?.toString() ?? '0',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDatabaseSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.storage, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Text(
                  'Base de Datos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Motor de persistencia'),
            subtitle: const Text('SQLite (Offline-First)'),
            trailing: Chip(
              label: const Text('v2.0'),
              backgroundColor: Colors.green.shade50,
              side: BorderSide.none,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('Eliminar todos los datos'),
            subtitle: const Text('Borra encuestas, respuestas y configuración'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _clearAllData,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Text(
                  'Acerca de',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.app_settings_alt),
            title: Text('Aplicación'),
            subtitle: Text('Encost - Field Data Collection MVP'),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Versión'),
            subtitle: Text('1.0.0+1'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.architecture),
            title: const Text('Arquitectura'),
            subtitle: const Text('Clean Architecture + Riverpod'),
            trailing: Chip(
              label: const Text('SQLite'),
              backgroundColor: Colors.blue.shade50,
              side: BorderSide.none,
            ),
          ),
        ],
      ),
    );
  }
}
