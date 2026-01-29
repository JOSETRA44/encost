# 📋 Schema JSON para Encuestas Dinámicas - encost

## Principios del Diseño del Schema

1. **Agnóstico de Datos**: El motor no conoce el contenido, solo la estructura
2. **Extensible**: Fácil agregar nuevos tipos de pregunta sin modificar el core
3. **Validable**: Cada tipo tiene reglas claras de validación
4. **Tipado Fuerte**: Cada campo tiene su tipo explícito

---

## Estructura Raíz del Survey

```json
{
  "id": "string (UUID)",
  "version": "string (semver: 1.0.0)",
  "title": "string",
  "description": "string (opcional)",
  "createdAt": "string (ISO 8601)",
  "expiresAt": "string (ISO 8601, opcional)",
  "metadata": {
    "author": "string",
    "category": "string",
    "tags": ["string"]
  },
  "questions": [
    {/* Question Object */}
  ]
}
```

---

## Tipos de Preguntas Soportados

### 1. TEXT - Entrada de Texto Libre
```json
{
  "id": "q1",
  "type": "text",
  "title": "¿Cuál es tu nombre completo?",
  "description": "Ingresa nombre y apellidos",
  "required": true,
  "validation": {
    "minLength": 3,
    "maxLength": 100,
    "pattern": "^[a-zA-ZáéíóúÁÉÍÓÚñÑ\\s]+$"
  },
  "placeholder": "Ej: Juan Pérez"
}
```

**Campos de Validación:**
- `minLength`: Número mínimo de caracteres
- `maxLength`: Número máximo de caracteres
- `pattern`: Regex para validación (opcional)

---

### 2. NUMERIC - Entrada Numérica
```json
{
  "id": "q2",
  "type": "numeric",
  "title": "¿Cuántos años tienes?",
  "required": true,
  "validation": {
    "min": 18,
    "max": 120,
    "decimals": 0
  },
  "unit": "años"
}
```

**Campos de Validación:**
- `min`: Valor mínimo permitido
- `max`: Valor máximo permitido
- `decimals`: Cantidad de decimales (0 = entero)
- `unit`: Unidad de medida para mostrar

---

### 3. SINGLE_CHOICE - Selección Única (Radio Buttons)
```json
{
  "id": "q3",
  "type": "single_choice",
  "title": "¿Cuál es tu nivel de satisfacción?",
  "required": true,
  "options": [
    {
      "id": "opt1",
      "label": "Muy insatisfecho",
      "value": "1"
    },
    {
      "id": "opt2",
      "label": "Insatisfecho",
      "value": "2"
    },
    {
      "id": "opt3",
      "label": "Neutral",
      "value": "3"
    },
    {
      "id": "opt4",
      "label": "Satisfecho",
      "value": "4"
    },
    {
      "id": "opt5",
      "label": "Muy satisfecho",
      "value": "5"
    }
  ],
  "displayStyle": "radio" // "radio" | "dropdown"
}
```

**Campos de Options:**
- `id`: Identificador único de la opción
- `label`: Texto visible para el usuario
- `value`: Valor a guardar (puede ser diferente del label)

---

### 4. MULTIPLE_CHOICE - Selección Múltiple (Checkboxes)
```json
{
  "id": "q4",
  "type": "multiple_choice",
  "title": "¿Qué servicios utilizas? (Selecciona todos los que apliquen)",
  "required": false,
  "options": [
    {
      "id": "opt1",
      "label": "Internet",
      "value": "internet"
    },
    {
      "id": "opt2",
      "label": "Telefonía",
      "value": "phone"
    },
    {
      "id": "opt3",
      "label": "Televisión",
      "value": "tv"
    }
  ],
  "validation": {
    "minSelections": 1,
    "maxSelections": 3
  }
}
```

**Campos de Validación:**
- `minSelections`: Cantidad mínima de opciones a seleccionar
- `maxSelections`: Cantidad máxima de opciones a seleccionar

---

### 5. RANGE - Escala Numérica (Slider)
```json
{
  "id": "q5",
  "type": "range",
  "title": "Del 1 al 10, ¿qué tan probable es que nos recomiendes?",
  "required": true,
  "validation": {
    "min": 1,
    "max": 10,
    "step": 1
  },
  "labels": {
    "min": "Nada probable",
    "max": "Muy probable"
  }
}
```

**Campos Especiales:**
- `step`: Incremento del slider (1 = solo enteros, 0.5 = medios valores)
- `labels`: Etiquetas descriptivas en los extremos

---

## Lógica Condicional (Avanzado - Fase 2)

```json
{
  "id": "q6",
  "type": "text",
  "title": "¿Por qué nos recomendarías?",
  "conditionalLogic": {
    "show": true,
    "conditions": [
      {
        "questionId": "q5",
        "operator": ">=",
        "value": "8"
      }
    ]
  }
}
```

---

## Ejemplo Completo de Encuesta

Ver archivo: `sample_survey.json`

---

## Notas de Implementación

1. **Parser Factory**: Usar patrón Factory para instanciar widgets según `type`
2. **Validación en Capas**: 
   - Domain: Reglas de negocio
   - Data: Parsing y serialización
   - Presentation: Feedback visual inmediato
3. **Null Safety**: Todos los campos opcionales deben manejarse con `?`
4. **Internacionalización**: El schema soporta múltiples idiomas (futuro)
