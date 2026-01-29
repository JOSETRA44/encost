# 🏗️ encost - Dynamic Survey Platform

## Arquitectura de Hierro para Aplicaciones de Encuestas Dinámicas

> **Stack:** Flutter • Clean Architecture • Riverpod • Hive • Factory Pattern

---

## 📐 Arquitectura

### Principios SOLID Aplicados

✅ **Single Responsibility Principle (SRP):**
- Cada clase tiene una única responsabilidad
- Casos de uso independientes por operación

✅ **Open/Closed Principle (OCP):**
- UI Factory extensible sin modificar código existente
- Nuevo tipo de pregunta = nueva clase widget

✅ **Liskov Substitution Principle (LSP):**
- Todas las implementaciones de repositorio son intercambiables

✅ **Interface Segregation Principle (ISP):**
- Contratos específicos por funcionalidad
- Clientes solo dependen de métodos que usan

✅ **Dependency Inversion Principle (DIP):**
- Dominio define contratos, Data los implementa
- Get_it desacopla completamente las capas

---

## 🗂️ Estructura de Carpetas

```
lib/
├── core/                          # Núcleo de la aplicación
│   ├── constants/                 # Constantes globales
│   ├── error/                     # Gestión de errores
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── theme/                     # Sistema de diseño
│   │   ├── app_colors.dart        # Paleta alto contraste
│   │   ├── app_text_styles.dart   # Tipografía optimizada
│   │   └── app_theme.dart         # Tema completo
│   ├── utils/                     # Utilidades
│   └── di/                        # Inyección de dependencias
│       └── injection_container.dart
│
├── features/
│   └── survey/                    # Feature: Encuestas
│       ├── domain/                # 🔵 CAPA DE DOMINIO
│       │   ├── entities/          # Entidades puras
│       │   │   ├── question_type.dart
│       │   │   ├── question_option.dart
│       │   │   ├── question_validation.dart
│       │   │   ├── question.dart
│       │   │   ├── survey_metadata.dart
│       │   │   ├── survey.dart
│       │   │   └── survey_response.dart
│       │   ├── repositories/      # Contratos (abstracciones)
│       │   │   ├── survey_repository.dart
│       │   │   └── response_repository.dart
│       │   └── usecases/          # Lógica de negocio
│       │       ├── survey_usecases.dart
│       │       └── response_usecases.dart
│       │
│       ├── data/                  # 🟢 CAPA DE DATOS
│       │   ├── models/            # Modelos con serialización
│       │   │   ├── question_option_model.dart
│       │   │   ├── question_validation_model.dart
│       │   │   ├── question_model.dart
│       │   │   ├── survey_metadata_model.dart
│       │   │   ├── survey_model.dart
│       │   │   ├── answer_model.dart
│       │   │   └── survey_response_model.dart
│       │   ├── datasources/       # Fuentes de datos
│       │   │   ├── survey_local_datasource.dart
│       │   │   └── response_local_datasource.dart
│       │   └── repositories/      # Implementaciones
│       │       ├── survey_repository_impl.dart
│       │       └── response_repository_impl.dart
│       │
│       └── presentation/          # 🟡 CAPA DE PRESENTACIÓN
│           ├── providers/         # Riverpod state management
│           ├── screens/           # Pantallas
│           └── widgets/           # Componentes UI
│               ├── question_widget_factory.dart  # 🏭 FACTORY
│               └── question_widgets/
│                   ├── text_question_widget.dart
│                   ├── numeric_question_widget.dart
│                   ├── single_choice_question_widget.dart
│                   ├── multiple_choice_question_widget.dart
│                   └── range_question_widget.dart
│
└── main.dart                      # Entry point
```

---

## 🚀 Setup Inicial

### 1. Instalar Dependencias

```powershell
flutter pub get
```

### 2. Generar Código (Hive Adapters + JSON Serialization)

```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Ejecutar la Aplicación

```powershell
flutter run
```

---

## 📋 Esquema JSON de Encuestas

Ver documentación completa: [`assets/surveys/survey_schema.md`](assets/surveys/survey_schema.md)

### Tipos de Preguntas Soportados:

1. **TEXT** - Entrada de texto libre
2. **NUMERIC** - Valores numéricos con validación
3. **SINGLE_CHOICE** - Selección única (radio buttons)
4. **MULTIPLE_CHOICE** - Selección múltiple (checkboxes)
5. **RANGE** - Escala numérica (slider)

### Ejemplo Mínimo:

```json
{
  "id": "survey-001",
  "version": "1.0.0",
  "title": "Mi Encuesta",
  "createdAt": "2026-01-29T10:00:00Z",
  "metadata": {
    "author": "Autor",
    "category": "categoria",
    "tags": ["tag1"]
  },
  "questions": [
    {
      "id": "q1",
      "type": "text",
      "title": "¿Cuál es tu nombre?",
      "required": true
    }
  ]
}
```

---

## 🎨 Sistema de Diseño

### Paleta de Colores (Alto Contraste)

- **Primary:** `#1565C0` (Azul intenso)
- **Secondary:** `#FF6F00` (Naranja vibrante)
- **Success:** `#00C853` (Verde)
- **Error:** `#D32F2F` (Rojo)

### Optimizaciones para Exteriores:

- ✅ Bordes gruesos (2-3px)
- ✅ Sombras pronunciadas
- ✅ Tipografía grande (16-18px base)
- ✅ Contraste AAA
- ✅ Inputs elevados

---

## 🏭 UI Factory Pattern

El corazón del renderizado dinámico:

```dart
Widget widget = QuestionWidgetFactory.create(
  question: question,         // Entidad del dominio
  currentValue: value,        // Estado actual
  onChanged: (newValue) {},   // Callback
  errorText: 'Error',         // Validación
);
```

**Ventajas:**
- ✅ Agnóstico del contenido
- ✅ Extensible sin modificar core
- ✅ Tipado fuerte
- ✅ Testeable

---

## 🔄 Flujo de Datos

```
[JSON File] 
    ↓
[DataSource] → Parsea JSON
    ↓
[Repository] → Convierte a Entity
    ↓
[Use Case] → Lógica de negocio
    ↓
[Provider/State] → Gestión de estado
    ↓
[UI Factory] → Renderiza widget apropiado
    ↓
[User Interaction]
```

---

## 📦 Exportación de Datos

### Excel

```dart
final result = await exportToExcel.call(responses, 'Encuesta 1');
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (filePath) => print('Guardado en: $filePath'),
);
```

### CSV

```dart
final result = await exportToCsv.call(responses, 'Encuesta 1');
```

---

## 🧪 Testing (Próximos Pasos)

```
test/
├── unit/
│   ├── domain/
│   ├── data/
│   └── usecases/
├── widget/
│   └── presentation/
└── integration/
```

---

## 📝 Próximas Funcionalidades

- [ ] Lógica condicional entre preguntas
- [ ] Modo offline completo con sincronización
- [ ] Internacionalización (i18n)
- [ ] Firma digital en encuestas
- [ ] Geolocalización de respuestas
- [ ] Exportación con gráficos incluidos
- [ ] Dashboard de análisis

---

## 🛠️ Comandos Útiles

```powershell
# Limpiar build
flutter clean

# Analizar código
flutter analyze

# Formatear código
dart format lib/

# Generar código nuevamente
flutter pub run build_runner watch
```

---

## 👥 Contribución

Este proyecto sigue **Clean Architecture** estrictamente:

1. **NO** mezclar capas
2. **Siempre** usar abstracciones (contratos)
3. **Cada** clase = una responsabilidad
4. **Documentar** principios SOLID aplicados
5. **Testear** antes de merge

---

## 📄 Licencia

Proyecto privado - encost © 2026

---

**Arquitectura de Hierro. Zero Código Espagueti. 100% SOLID.**
