# 🎯 ENCOST - Field Data Collection MVP

## ✅ PROBLEMA RESUELTO: Infinite Loading Screen

La aplicación ha sido **completamente refactorizada** para eliminar el bucle infinito de carga. Cambios críticos:

- ❌ **Eliminado**: Hive, build_runner, y toda generación de código
- ✅ **Implementado**: SQLite (sqflite) con esquema relacional robusto
- ✅ **Manejo de errores**: Pantalla roja visible si la DB falla al iniciar
- ✅ **Navegación funcional**: Splash → Home Screen con 3 tabs

---

## 🏗️ Arquitectura Implementada

### Stack Tecnológico (Clean Architecture)
- **Flutter**: SDK ^3.9.2
- **Estado**: `flutter_riverpod` ^2.6.1 (sintaxis clásica, sin anotaciones)
- **Persistencia**: `sqflite` ^2.4.1 (Offline-First)
- **UI**: NavigationBar con Bottom Nav persistente
- **Pattern**: Factory Pattern para renderizado dinámico

### Base de Datos SQLite (3 Tablas)

```sql
-- Tabla 1: Plantillas de encuestas
CREATE TABLE surveys (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  version TEXT,
  json_structure TEXT NOT NULL,  -- JSON completo del formulario
  created_at INTEGER,
  updated_at INTEGER
);

-- Tabla 2: Sesiones de recolección
CREATE TABLE responses (
  id TEXT PRIMARY KEY,
  survey_id TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  is_exported INTEGER DEFAULT 0,
  completed_at INTEGER,
  FOREIGN KEY (survey_id) REFERENCES surveys (id)
);

-- Tabla 3: Respuestas individuales
CREATE TABLE answers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  response_id TEXT NOT NULL,
  question_id TEXT NOT NULL,
  value TEXT NOT NULL,
  answered_at INTEGER,
  FOREIGN KEY (response_id) REFERENCES responses (id)
);
```

---

## 📱 Funcionalidades Implementadas

### ✅ Tab 1: Mis Encuestas
- **Lista de plantillas disponibles** para iniciar recolección
- **Botón flotante (+)**: Importar nuevo JSON desde portapapeles
- **Validación automática**: Verifica estructura JSON antes de guardar
- **Acción**: Al tocar "Iniciar" → Abre formulario dinámico

### ✅ Tab 2: Historial
- **Lista de respuestas registradas** con metadata
- **Filtro**: Mostrar solo exportadas / todas
- **Estados**: Pendiente ⏳ | Exportada ✅
- **Acciones**: Marcar como exportada, eliminar respuestas

### ✅ Tab 3: Ajustes
- **Estadísticas en tiempo real**:
  - Encuestas disponibles
  - Respuestas registradas
  - Respuestas individuales guardadas
  - Total exportadas
- **Gestión de datos**: Botón para limpiar toda la DB
- **Info técnica**: Versión, arquitectura, motor SQLite

### ✅ Motor de Renderizado (Factory Pattern)
**Clase**: `SurveyQuestionFactory`

Convierte JSON → Widgets automáticamente. Tipos soportados:

| Tipo JSON | Widget | Descripción |
|-----------|--------|-------------|
| `text` | `TextQuestionWidget` | Input de texto libre |
| `number` | `NumberQuestionWidget` | Input numérico |
| `radio` | `RadioQuestionWidget` | Opción única (botones radio) |
| `checkbox` | `CheckboxQuestionWidget` | Opción múltiple (checkboxes) |

---

## 🚀 Cómo Usar la Aplicación

### 1. Ejecutar la app
```bash
flutter run
```

### 2. Importar un JSON (Método manual)
1. Abre la app → **Tab "Mis Encuestas"**
2. Toca el botón flotante **"+ Importar JSON"**
3. Pega este ejemplo:

```json
{
  "id": "campo_v1",
  "title": "Encuesta Campo 2026",
  "version": "1.0",
  "fields": [
    {
      "id": "q1",
      "type": "text",
      "label": "Nombre del encuestado"
    },
    {
      "id": "q2",
      "type": "number",
      "label": "Edad"
    },
    {
      "id": "q3",
      "type": "radio",
      "label": "¿Tiene acceso a electricidad?",
      "options": ["Sí", "No"]
    },
    {
      "id": "q4",
      "type": "checkbox",
      "label": "Servicios disponibles (selecciona todos los que apliquen)",
      "options": ["Internet", "TV por cable", "Teléfono fijo", "Ninguno"]
    }
  ]
}
```

4. Toca **"Importar"**
5. La encuesta aparecerá en la lista

### 3. Realizar una encuesta
1. Toca **"Iniciar"** en cualquier encuesta disponible
2. Responde las preguntas (el progreso se muestra arriba)
3. Toca el ícono **✓** para guardar

### 4. Ver historial y exportar
1. Ve al **Tab "Historial"**
2. Verás todas las respuestas registradas
3. Toca **⋮** → "Marcar exportada" cuando la hayas respaldado

---

## 📂 Estructura de Carpetas

```
lib/
├── main.dart                          # Entry point + SplashScreen robusto
├── core/
│   ├── database/
│   │   └── database_helper.dart       # SQLite Singleton (3 tablas)
│   └── theme/
│       └── app_theme.dart             # Tema minimalista alto contraste
├── features/
    ├── home/
    │   └── presentation/
    │       └── screens/
    │           └── home_screen.dart   # Bottom Nav con 3 tabs
    ├── surveys/
    │   └── presentation/
    │       └── screens/
    │           └── surveys_list_screen.dart  # Tab 1: Lista + importar JSON
    ├── survey/
    │   └── presentation/
    │       ├── screens/
    │       │   └── survey_form_screen.dart   # Llenado de formulario
    │       └── widgets/
    │           └── survey_question_factory.dart  # Factory Pattern (4 tipos)
    ├── history/
    │   └── presentation/
    │       └── screens/
    │           └── history_screen.dart       # Tab 2: Historial
    └── settings/
        └── presentation/
            └── screens/
                └── settings_screen.dart      # Tab 3: Ajustes
```

---

## 🎨 Estética: Clean UI Minimalista

- **Colores**: Blanco/Negro/Azul Institucional (#1565C0)
- **Tipografía**: Sans-serif legible (sistema por defecto)
- **Bordes**: Redondeados (8-12px)
- **Elevación**: Sombras sutiles en Cards
- **Feedback visual**:
  - ✅ Preguntas respondidas → Ícono verde
  - ⏳ Preguntas pendientes → Número de pregunta
  - Progress bar animado en formulario

---

## 🔧 Comandos Útiles

```bash
# Verificar errores
flutter analyze --no-fatal-infos

# Ejecutar tests
flutter test

# Limpiar build
flutter clean && flutter pub get

# Ver logs
flutter run -v
```

---

## 📋 Contrato JSON (Standard)

**Estructura mínima obligatoria:**

```json
{
  "id": "unique_survey_id",        // OBLIGATORIO
  "title": "Título de la encuesta", // OBLIGATORIO
  "version": "1.0",                 // Opcional (default: "1.0")
  "fields": [                       // OBLIGATORIO
    {
      "id": "q1",                   // ID único de pregunta
      "type": "text|number|radio|checkbox",
      "label": "Texto de la pregunta",
      "options": ["Op1", "Op2"]     // Solo para radio/checkbox
    }
  ]
}
```

**Validaciones automáticas:**
- ❌ Rechaza JSON sin `id`, `title` o `fields`
- ❌ Muestra error en pantalla si hay problema de sintaxis
- ✅ Guarda el JSON completo en `surveys.json_structure`

---

## 🐛 Troubleshooting

### La app se queda en el splash screen
**Solución**: Verifica que SQLite esté inicializado correctamente. Si ves pantalla roja con error, revisa permisos de almacenamiento.

### "Error al importar JSON"
**Causa**: Estructura JSON inválida
**Solución**: Verifica que tenga los campos obligatorios: `id`, `title`, `fields`

### No se guardan las respuestas
**Causa**: Tabla `answers` no creada
**Solución**: Elimina la app y reinstala (o usa "Eliminar todos los datos" en Ajustes)

---

## 📈 Próximos Pasos Sugeridos

1. **Exportación CSV/Excel** (repositorio ya preparado para esto)
2. **Sincronización con servidor** (API REST)
3. **Validaciones avanzadas** (requeridos, regex, rangos)
4. **Tipos adicionales**: date, time, signature, photo
5. **Modo offline completo** con cola de sincronización

---

## ✅ Checklist de Validación

- [x] ✅ `flutter pub get` sin errores
- [x] ✅ `flutter analyze` - 0 errores (solo warnings de deprecación)
- [x] ✅ `flutter test` - Todos los tests pasan
- [x] ✅ App inicia sin bucle infinito
- [x] ✅ SQLite inicializa correctamente
- [x] ✅ Bottom Navigation funcional
- [x] ✅ Importar JSON desde portapapeles
- [x] ✅ Guardar plantillas en tabla `surveys`
- [x] ✅ Renderizar formularios dinámicamente
- [x] ✅ Guardar respuestas en tabla `answers`
- [x] ✅ Ver historial con filtros
- [x] ✅ Estadísticas en tiempo real

---

## 🎉 ¡LISTO PARA PRODUCCIÓN!

La aplicación está **100% funcional** y lista para recolección de datos en campo. El infinite loading ha sido eliminado y reemplazado por una inicialización robusta con manejo de errores visual.

**Desarrollado con Clean Architecture + Offline-First MVP**
