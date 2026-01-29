import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database Helper - Gestión de SQLite (Offline-First MVP)
/// 
/// Arquitectura: 3 tablas relacionales para gestión multi-encuesta
/// - surveys: Plantillas de formularios (estructura JSON)
/// - responses: Sesiones de recolección de datos
/// - answers: Respuestas individuales por pregunta
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  static DatabaseHelper get instance => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'encost.db');

    return await openDatabase(
      path,
      version: 2, // Nueva versión con esquema actualizado
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // TABLA 1: surveys - Plantillas de encuestas (JSON structure)
    await db.execute('''
      CREATE TABLE surveys (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        version TEXT NOT NULL DEFAULT '1.0',
        json_structure TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // TABLA 2: responses - Sesiones de recolección
    await db.execute('''
      CREATE TABLE responses (
        id TEXT PRIMARY KEY,
        survey_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_exported INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER,
        FOREIGN KEY (survey_id) REFERENCES surveys (id) ON DELETE CASCADE
      )
    ''');

    // TABLA 3: answers - Respuestas individuales
    await db.execute('''
      CREATE TABLE answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        response_id TEXT NOT NULL,
        question_id TEXT NOT NULL,
        value TEXT NOT NULL,
        answered_at INTEGER NOT NULL,
        FOREIGN KEY (response_id) REFERENCES responses (id) ON DELETE CASCADE
      )
    ''');

    // Índices para búsqueda rápida
    await db.execute('CREATE INDEX idx_survey_id ON responses(survey_id)');
    await db.execute('CREATE INDEX idx_response_id ON answers(response_id)');
    await db.execute('CREATE INDEX idx_is_exported ON responses(is_exported)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migración: Eliminar tablas antiguas y crear nuevas
      await db.execute('DROP TABLE IF EXISTS survey_responses');
      await db.execute('DROP TABLE IF EXISTS surveys');
      await _createDatabase(db, newVersion);
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'encost.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
