# Encost — Dynamic Survey Platform

Cross-platform mobile application for structured field data collection, built with Flutter and Clean Architecture principles. Designed for offline-first use in environments where connectivity is unreliable.

---

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Architecture](#architecture)
- [Features](#features)
- [Survey Schema](#survey-schema)
- [Data Flow](#data-flow)
- [Design System](#design-system)
- [Data Export](#data-export)
- [Project Structure](#project-structure)
- [Development Commands](#development-commands)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

Encost enables organizations to define, distribute, and collect structured surveys through a JSON-based template system. Survey forms are rendered dynamically at runtime without requiring application updates. All data is persisted locally using SQLite, and results can be exported to CSV or Excel format for downstream analysis.

**Version:** 1.0.0+1
**SDK:** Dart ^3.9.2
**Supported Platforms:** Android, iOS, Web, Windows

---

## Requirements

| Dependency | Minimum Version |
|---|---|
| Flutter SDK | 3.9.2 |
| Dart SDK | 3.9.2 |
| Android SDK | API 21+ |
| iOS | 12.0+ |

---

## Installation

**1. Clone the repository**

```bash
git clone <repository-url>
cd encost
```

**2. Install dependencies**

```bash
flutter pub get
```

**3. Run the application**

```bash
flutter run
```

**4. Build for production**

```bash
# Android
flutter build apk --release

# iOS
flutter build ipa --release

# Web
flutter build web --release
```

---

## Architecture

The application follows Clean Architecture with a strict separation of concerns across three layers. All inter-layer communication is mediated through abstract contracts, making each layer independently testable and replaceable.

```
Presentation Layer  (UI, state management, widgets)
        |
        v
  Domain Layer      (entities, use cases, repository contracts)
        |
        v
   Data Layer       (models, datasources, repository implementations)
```

### SOLID Principles

**Single Responsibility Principle**
Each class has a single, well-defined purpose. Use cases encapsulate exactly one business operation.

**Open/Closed Principle**
The `QuestionWidgetFactory` allows new question types to be added by creating a new widget class, without modifying any existing code.

**Liskov Substitution Principle**
All repository implementations are interchangeable through their abstract interfaces.

**Interface Segregation Principle**
Repository contracts are split by domain (surveys vs. responses), so consumers depend only on the methods they require.

**Dependency Inversion Principle**
The domain layer defines contracts. The data layer implements them. `GetIt` resolves dependencies at runtime, fully decoupling layers.

### State Management

State is managed with `flutter_riverpod` (classic provider syntax). Providers are scoped to features and expose reactive streams consumed by the presentation layer.

### Dependency Injection

`GetIt` serves as the service locator. All dependencies are registered in `lib/core/di/injection_container.dart` and resolved without importing concrete implementations from consumer code.

---

## Features

### Dynamic Survey Rendering

Surveys are defined as JSON files and loaded at runtime. The `QuestionWidgetFactory` inspects each question's `type` field and instantiates the corresponding widget. No code changes are required to introduce new survey content.

**Supported question types:**

| Type | Description | Validation |
|---|---|---|
| `text` | Free-text input | `minLength`, `maxLength`, `pattern` (regex) |
| `numeric` | Numeric input | `min`, `max`, `decimals` |
| `single_choice` | Single selection from a list | Required/optional |
| `multiple_choice` | Multiple selections from a list | `minSelections`, `maxSelections` |
| `range` | Slider with configurable step | `min`, `max`, `step`, custom labels |

### Offline-First Persistence

All survey templates, response sessions, and individual answers are stored in a local SQLite database. The application has no network dependency at runtime.

**Database schema:**

| Table | Purpose |
|---|---|
| `surveys` | Survey templates stored as JSON |
| `responses` | Response sessions with export tracking |
| `answers` | Individual question responses |

### Survey History

Users can review previously completed responses, grouped by survey. Export status is tracked per response session.

### Data Export

Completed responses can be exported to CSV or Excel. See the [Data Export](#data-export) section for format details.

---

## Survey Schema

Survey templates are JSON files placed in `assets/surveys/`. Full schema documentation is available at [`assets/surveys/survey_schema.md`](assets/surveys/survey_schema.md).

### Minimal example

```json
{
  "id": "survey-001",
  "version": "1.0.0",
  "title": "Customer Satisfaction Survey",
  "createdAt": "2026-01-01T00:00:00Z",
  "metadata": {
    "author": "Field Operations Team",
    "category": "customer-feedback",
    "tags": ["satisfaction", "q1-2026"]
  },
  "questions": [
    {
      "id": "q1",
      "type": "text",
      "title": "Describe your experience.",
      "required": true,
      "validation": {
        "minLength": 10,
        "maxLength": 500
      }
    },
    {
      "id": "q2",
      "type": "single_choice",
      "title": "Overall rating",
      "required": true,
      "options": [
        { "id": "opt1", "label": "Excellent" },
        { "id": "opt2", "label": "Good" },
        { "id": "opt3", "label": "Poor" }
      ]
    },
    {
      "id": "q3",
      "type": "range",
      "title": "Rate our response time (1–10)",
      "required": false,
      "validation": {
        "min": 1,
        "max": 10,
        "step": 1
      }
    }
  ]
}
```

### Optional survey-level fields

| Field | Type | Description |
|---|---|---|
| `expiresAt` | ISO 8601 string | Survey expiration date |
| `metadata.description` | string | Long-form description |
| `metadata.tags` | string[] | Arbitrary categorization tags |

---

## Data Flow

```
JSON Template File
      |
      v
Local Datasource        — parses and deserializes JSON
      |
      v
Repository              — converts models to domain entities
      |
      v
Use Case                — executes business logic
      |
      v
Riverpod Provider       — manages and exposes reactive state
      |
      v
QuestionWidgetFactory   — instantiates the appropriate widget per question type
      |
      v
User Interaction        — captured and persisted as Answer entities
```

---

## Design System

The color palette and typography are optimized for outdoor use under direct sunlight, targeting WCAG AAA contrast ratios.

### Color Palette

| Role | Hex | Usage |
|---|---|---|
| Primary | `#1565C0` | Primary actions, navigation |
| Secondary | `#FF6F00` | Accent, highlights |
| Success | `#00C853` | Confirmation, valid states |
| Error | `#D32F2F` | Validation errors |
| Warning | `#FFA000` | Non-blocking alerts |

### Typography and Component Guidelines

- Base font size: 16–18 px for legibility in field conditions
- Input borders: 2–3 px to improve visibility in high-glare environments
- Elevated inputs with pronounced shadows for depth perception
- All interactive targets meet minimum touch area requirements

---

## Data Export

### CSV

Responses are exported in a horizontal pivot format: one row per completed response session, with each question occupying a dedicated column. The file is UTF-8 encoded with a BOM for compatibility with Microsoft Excel, and uses a semicolon delimiter.

```dart
final result = await exportToCsv.call(responses, surveyTitle);
result.fold(
  (failure) => handleError(failure.message),
  (filePath) => shareFile(filePath),
);
```

### Excel

Responses are exported as a structured `.xlsx` workbook with one sheet per survey.

```dart
final result = await exportToExcel.call(responses, surveyTitle);
result.fold(
  (failure) => handleError(failure.message),
  (filePath) => shareFile(filePath),
);
```

---

## Project Structure

```
lib/
├── core/
│   ├── constants/                 # Application-wide constants
│   ├── database/                  # SQLite helper and schema management
│   ├── di/                        # GetIt service locator registration
│   ├── error/                     # Exception and failure types
│   ├── theme/                     # Colors, typography, and theme configuration
│   └── utils/                     # CSV and shared export utilities
│
├── features/
│   ├── survey/                    # Core survey feature
│   │   ├── domain/
│   │   │   ├── entities/          # Survey, Question, SurveyResponse, etc.
│   │   │   ├── repositories/      # Abstract repository contracts
│   │   │   └── usecases/          # GetSurveys, SaveResponse, ExportToCsv, etc.
│   │   ├── data/
│   │   │   ├── models/            # Serializable counterparts of domain entities
│   │   │   ├── datasources/       # SQLite read/write operations
│   │   │   └── repositories/      # Concrete repository implementations
│   │   └── presentation/
│   │       ├── screens/           # SurveyFormScreen
│   │       └── widgets/
│   │           ├── question_widget_factory.dart
│   │           └── question_widgets/
│   │               ├── text_question_widget.dart
│   │               ├── numeric_question_widget.dart
│   │               ├── single_choice_question_widget.dart
│   │               ├── multiple_choice_question_widget.dart
│   │               └── range_question_widget.dart
│   │
│   ├── surveys/                   # Survey list and creation screens
│   ├── history/                   # Response history screen
│   └── settings/                  # Application settings screen
│
└── main.dart                      # Entry point with splash screen and DI initialization

assets/
└── surveys/
    ├── sample_survey.json
    ├── example_campo_2026.json
    └── survey_schema.md
```

---

## Development Commands

```bash
# Fetch dependencies
flutter pub get

# Analyze code
flutter analyze

# Format source files
dart format lib/

# Run tests
flutter test

# Clean build artifacts
flutter clean

# Run with a specific device
flutter run -d <device-id>

# List connected devices
flutter devices
```

---

## Contributing

All contributions must comply with the Clean Architecture constraints enforced in this project.

**Rules:**

1. Do not reference concrete implementations across layer boundaries. Use abstractions.
2. Domain entities must remain free of framework dependencies.
3. Each class must have a single responsibility. Split if in doubt.
4. New question types require only a new widget class; no existing files should be modified.
5. All use cases must be covered by unit tests before merge.
6. Run `flutter analyze` and `dart format lib/` before committing.

**Layer import rules:**

- `presentation` may import `domain` only
- `data` may import `domain` only
- `domain` has no imports from other feature layers

---

## License

Private — encost © 2026. All rights reserved.
