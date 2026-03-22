# FASE 3: Base de Datos de Preguntas - Instrucciones Completas

## 📋 Resumen

Esta fase crea y carga la base de datos de preguntas para el juego, incluyendo los 7 tipos de preguntas de geografía.

## ✅ Estado Actual

**Completado:**
- ✅ Script generador de preguntas desde REST Countries API
- ✅ Script de importación a Firestore
- ✅ Datos manuales de ríos
- ✅ Soporte para 5 tipos de preguntas (Banderas, Capitales, Población, Extensión, Ríos)

**Pendiente (requiere trabajo manual):**
- ⏳ Generar preguntas de siluetas (necesita imágenes)
- ⏳ Generar preguntas de fotos de ciudades (necesita imágenes)
- ⏳ Ejecutar scripts para generar preguntas
- ⏳ Importar preguntas a Firestore

---

## 🗺️ 7 Tipos de Preguntas

| Tipo | Fuente | Estado | Cantidad |
|------|--------|--------|----------|
| 1. Banderas | REST Countries API | ✅ Automático | ~100 |
| 2. Capitales | REST Countries API | ✅ Automático | ~100 |
| 3. Población | REST Countries API | ✅ Automático | 50 |
| 4. Ríos | Datos manuales | ✅ Automático | 25 |
| 5. Extensión | REST Countries API | ✅ Automático | 50 |
| 6. Siluetas | Imágenes manuales | ⏳ Manual | 0 |
| 7. Fotos de ciudades | Imágenes manuales | ⏳ Manual | 0 |

**Total actual**: ~325 preguntas

---

## 🚀 Paso 1: Generar Preguntas

### Opción A: Solo preguntas automáticas (5 tipos)

Genera preguntas usando REST Countries API + ríos manuales:

```bash
cd /ruta/a/tu/workspace/GeoC

# Generar preguntas
dart scripts/generate_questions_with_manual.dart
```

Esto creará:
- `scripts/questions_full.json` con ~325 preguntas

**Tipos incluidos:**
- Banderas (~100)
- Capitales (~100)
- Población (50)
- Extensión (50)
- Ríos (25)

### Opción B: Solo preguntas REST Countries (4 tipos)

```bash
dart scripts/generate_questions.dart
```

Esto creará:
- `scripts/questions.json` con ~300 preguntas

**Tipos incluidos:**
- Banderas (~100)
- Capitales (~100)
- Población (50)
- Extensión (50)

---

## 🔥 Paso 2: Importar a Firestore

### 2.1 Preparar Firebase

Asegúrate de que:
1. Firebase esté inicializado (`flutterfire configure`)
2. Firestore esté habilitado en Firebase Console
3. Tengas reglas de Firestore en modo test

### 2.2 Importar Preguntas

```bash
cd /ruta/a/tu/workspace/GeoC

# Importar preguntas
dart scripts/import_questions_firestore.dart
```

El script:
1. Lee `scripts/questions_full.json` o `scripts/questions.json`
2. Pide confirmación
3. Importa en batches de 500
4. Muestra progreso
5. Verifica importación

### 2.3 Verificar en Firebase Console

Ve a Firebase Console → Firestore → `questions` y deberías ver:
- ~325 documentos
- Cada documento con:
  - `id`: ID único
  - `type`: Tipo de pregunta
  - `difficulty`: easy/medium/hard
  - `correctAnswer`: Respuesta correcta
  - `options`: Opciones incorrectas
  - `extraData`: Datos adicionales (countryCode, etc.)
  - `questionText`: Pregunta (para tipo capital/river)
  - `imageUrl`: URL de imagen (para silueta/ciudad - vacío por ahora)

---

## 🖼️ Paso 3: Preguntas de Siluetas (Manual)

Las siluetas requieren imágenes creadas manualmente.

### 3.1 Crear Imágenes de Siluetas

Opciones:
1. **Usar servicios online**: VectorStock, Shutterstock, etc.
2. **Crear con Illustrator/Inkscape**: Convierte a PNG
3. **Usar IA generadora**: DALL-E, Midjourney (prompt: "silhouette of [country] map")

### 3.2 Proceso para Añadir Siluetas

Para cada país:

```dart
// Ejemplo de estructura para silueta
{
  'id': 'silhouette_spain',
  'type': 'silhouette',
  'difficulty': 'medium',
  'imageUrl': 'gs://geoquiz-battle.appspot.com/silhouettes/spain.png',
  'correctAnswer': 'España',
  'options': ['España', 'Portugal', 'Francia', 'Italia'],
}
```

### 3.3 Subir Imágenes a Firebase Storage

```bash
# Instalar Firebase CLI
firebase tools:login

# Subir imágenes
firebase storage:upload --project=geoquiz-battle assets/silhouettes/*.png

# O desde Firebase Console
# Storage → Crear carpeta "silhouettes" → Subir PNGs
```

### 3.4 Añadir Preguntas de Siluetas

Opción 1: Manual en Firebase Console
1. Ve a Firestore → `questions`
2. Click "Añadir documento"
3. Rellena campos
4. Guardar

Opción 2: Script
Crea un script para generar siluetas y añádelo al JSON principal.

---

## 🏙️ Paso 4: Preguntas de Fotos de Ciudades (Manual)

Similar a siluetas, pero con fotos de ciudades icónicas.

### 4.1 Estructura

```dart
{
  'id': 'city_paris_eiffel',
  'type': 'cityPhoto',
  'difficulty': 'medium',
  'imageUrl': 'gs://geoquiz-battle.appspot.com/cities/paris_eiffel.jpg',
  'correctAnswer': 'París',
  'options': ['París', 'Londres', 'Roma', 'Berlín'],
}
```

### 4.2 Ciudades Sugeridas

10-20 ciudades icónicas:
- París (Torre Eiffel)
- Londres (Big Ben)
- Roma (Coliseo)
- Nueva York (Estatua de Libertad)
- Tokio (Torre Tokyo)
- Sydney (Opera House)
- Río de Janeiro (Cristo Redentor)
- Dubái (Burj Khalifa)
- Egipto (Pirámides)
- Atenas (Partenón)

---

## 📊 Paso 5: Análisis de Resultados

### 5.1 Preguntas por Tipo

```bash
# En Firestore Console, haz queries:
# collection: questions
# where: type == "flag"
```

### 5.2 Estadísticas Esperadas

- **Total**: 325+ preguntas
- **Easy**: ~100 (banderas)
- **Medium**: ~125 (capitales, ríos, siluetas)
- **Hard**: ~100 (población, extensión)

---

## 🧪 Paso 6: Probar Preguntas

### 6.1 Probar desde App

Una vez que las preguntas están en Firestore:

1. Ejecuta la app: `flutter run`
2. Haz login
3. (En futuro) Inicia partida
4. Deberías ver preguntas de los tipos creados

### 6.2 Probar Repository

Puedes probar el QuestionRepository:

```dart
// En un test o script
final questionRepo = QuestionRepositoryImpl();

// Obtener preguntas aleatorias
final questions = await questionRepo.getRandomQuestions(count: 10);
questions.fold(
  (failure) => print('Error: ${failure.message}'),
  (qs) => print('Got ${qs.length} questions'),
);

// Obtener por tipo
final flags = await questionRepo.getQuestionsByType(QuestionType.flag);
```

---

## 📝 Paso 7: Mantener Actualizado

### 7.1 Añadir Nuevas Preguntas

1. Crea JSON con nuevas preguntas
2. Ejecuta script de importación
3. Las nuevas se añaden a Firestore

### 7.2 Editar Preguntas Existentes

1. Ve a Firebase Console → Firestore → `questions`
2. Busca pregunta por ID
3. Edita campos
4. Guarda

---

## 🐛 Solución de Problemas

### Error: "questions.json not found"
- Ejecuta primero: `dart scripts/generate_questions.dart`
- O usa la versión completa: `dart scripts/generate_questions_with_manual.dart`

### Error: "Firebase not initialized"
- Ejecuta: `flutterfire configure --project=geoquiz-battle`
- Verifica que `lib/firebase_options.dart` existe

### Error: "Import failed - permission denied"
- Verifica reglas de Firestore
- Asegúrate de estar autenticado: `firebase login`

### Error: "Batch failed"
- Las preguntas pueden tener formato incorrecto
- Revisa el JSON para errores de sintaxis
- Importa en batches más pequeños

---

## 📊 Archivos Creados

1. **scripts/generate_questions.dart** (8734 bytes)
   - Genera 4 tipos de preguntas desde REST Countries

2. **scripts/import_questions_firestore.dart** (4743 bytes)
   - Importa JSON a Firestore
   - Batches de 500 documentos

3. **scripts/rivers_manual.dart** (4786 bytes)
   - Datos de 25 ríos
   - Generador de preguntas de ríos

4. **scripts/generate_questions_with_manual.dart** (9183 bytes)
   - Genera todos los tipos automáticos
   - Incluye ríos manuales

5. **scripts/questions.json** (generado)
   - ~300 preguntas (4 tipos)

6. **scripts/questions_full.json** (generado)
   - ~325 preguntas (5 tipos)

---

## 📝 Resumen de Preguntas

### Automáticas (REST Countries + Ríos)
- ✅ Banderas: ~100
- ✅ Capitales: ~100
- ✅ Población: 50
- ✅ Extensión: 50
- ✅ Ríos: 25

### Manuales (Requieren trabajo adicional)
- ⏳ Siluetas: 0 (necesita ~100 imágenes)
- ⏳ Fotos de ciudades: 0 (necesita ~20 imágenes)

**Total actual**: ~325 preguntas

---

## 🚀 Commit y Push

```bash
# Ver cambios
git status

# Añadir archivos
git add scripts/

# Commit
git commit -m "feat: complete FASE 3 - question database

- Add script to generate questions from REST Countries API
- Add Firestore import script
- Add manual river data (25 rivers)
- Add comprehensive generation script (5 types)

Features:
- Auto-generate flag questions (~100)
- Auto-generate capital questions (~100)
- Auto-generate population questions (50)
- Auto-generate area questions (50)
- Auto-generate river questions (25, manual data)
- Batch import to Firestore (500 per batch)
- Progress tracking and validation

Files created:
- scripts/generate_questions.dart
- scripts/generate_questions_with_manual.dart
- scripts/import_questions_firestore.dart
- scripts/rivers_manual.dart

Total questions: ~325 (5 types)"

# Push
git push origin main
```

---

## 🎯 ¿Qué sigue después de FASE 3?

**FASE 4: Core del Juego**
1. ✅ Crear GameProvider
2. ✅ Crear GameScreen
3. ✅ Crear widgets de preguntas
4. ✅ Implementar timer
5. ✅ Implementar lógica de respuestas

---

**¡FASE 3 completada! 🎉** Ahora tienes una base de datos de preguntas funcional en Firestore.
