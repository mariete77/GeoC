# 🤖 Guía para el Agente de Desarrollo - GeoQuiz Battle

**Fecha creación:** 11/04/2026  
**Proyecto:** GeoQuiz Battle - Juego de geografía multiplayer  
**Stack:** Flutter + Firebase (Firestore, Auth, Realtime DB) + Riverpod  
**Estado actual:** Fase 4 completada, debugging en progreso

---

## 📋 Índice

1. [Estado Actual y Bugs Conocidos](#1-estado-actual-y-bugs-conocidos)
2. [Tareas Prioritarias (Inmediatas)](#2-tareas-prioritarias-inmediatas)
3. [Arquitectura del Proyecto](#3-arquitectura-del-proyecto)
4. [Patrones y Convenciones](#4-patrones-y-convenciones)
5. [Flujo de la App](#5-flujo-de-la-app)
6. [Tareas por Fase (Roadmap)](#6-tareas-por-fase-roadmap)
7. [Comandos Útiles](#7-comandos-útiles)
8. [Notas Importantes](#8-notas-importantes)

---

## 1. Estado Actual y Bugs Conocidos

### ✅ Lo que funciona
- Splash → Login (Google Sign-In) → Home Screen
- Carga de preguntas desde Firestore
- Pantalla de juego: pregunta + timer + feedback + resultados
- Scoring con bonus de tiempo y streak
- Sistema de dificultad (fácil/medio/difícil)

### 🐛 Bug ACTIVO: Opciones de respuesta no aparecen
**Síntoma:** Al jugar, la pregunta de bandera se muestra correctamente (con imagen y texto "¿De qué país es esta bandera?") pero NO aparecen los botones de opciones de respuesta.

**Diagnóstico en progreso:**
- Se ha añadido un mensaje de debug en `game_screen.dart` (línea ~237) que muestra "⚠️ Debug: options vacías..." si `currentQuestion.options.isEmpty`
- **Posibles causas:**
  1. Las preguntas en Firestore NO tienen el campo `options` (o está vacío)
  2. El parseo en `QuestionModel.fromJson` no lee correctamente el campo

**Pasos para diagnosticar:**
1. Haz hot restart completo y juega una partida
2. Si ves el mensaje rojo de debug → las opciones están vacías en Firestore
3. Solución: reimportar preguntas usando el script Python:
   ```bash
   cd d:\Repos\GeoC && python scripts/import_questions_rest.py
   ```
4. Verificar en Firebase Console que las preguntas tienen el campo `options` como array

**Archivos involucrados:**
- `lib/presentation/screens/game/game_screen.dart` (línea ~237: debug message)
- `lib/data/models/question_model.dart` (fromJson, línea 32-35: parseo de options)
- `lib/presentation/screens/game/widgets/answer_options_widget.dart` (widget de opciones)
- `scripts/import_questions_rest.py` (script de importación)
- `scripts/questions.json` y `scripts/questions_python_generated.json` (datos JSON con options correctos)

### 🐛 Bug resuelto: Idiomas mezclados
**Estado:** ✅ RESUELTO  
**Fix:** `question_card.dart` ahora usa `question.questionText` de la BD (en español) en vez de textos hardcoded en inglés. Badges de dificultad cambiados a español (FÁCIL/MEDIO/DIFÍCIL).

### 🐛 Bug resuelto: Imagen de bandera no aparece  
**Estado:** ✅ RESUELTO  
**Fix:** Si `imageUrl` es null, se genera la URL desde `countryCode` en `extraData`:  
```dart
final flagUrl = question.imageUrl ?? 
    'https://flagcdn.com/w320/${question.extraData!['countryCode']}.png';
```

### 🐛 Bug resuelto: Juego no avanza tras responder
**Estado:** ✅ RESUELTO  
**Fix:** El provider `game_provider.dart` ahora usa variables de instancia `_currentQuestionIndex` y `_questions` en vez de depender del estado mutable.

### 🐛 Bug resuelto: Crashea al cancelar y volver al menú
**Estado:** ✅ RESUELTO  
**Fix:** `cancelGame()` ahora resetea a `GameState.initial()` y cierra el timer antes del `pop()`.

---

## 2. Tareas Prioritarias (Inmediatas)

### 🔴 PRIORIDAD 1: Fix opciones de respuesta (BUG ACTIVO)
**Orden:**
1. Hot restart y probar → ver si aparece mensaje de debug
2. Si options vacías → verificar datos en Firestore Console
3. Si datos mal → reimportar con `python scripts/import_questions_rest.py`
4. Si datos bien → investigar parseo en `QuestionModel.fromJson`
5. Una vez fijado, ELIMINAR el mensaje de debug de `game_screen.dart`

### 🔴 PRIORIDAD 2: Regenerar código con build_runner
Los archivos `.freezed.dart` y `.g.dart` pueden estar desactualizados.
```bash
cd d:\Repos\GeoC
dart run build_runner build --delete-conflicting-outputs
```

### 🟡 PRIORIDAD 3: Generar más preguntas
Solo hay ~30 preguntas en `questions.json`. Objetivo: 500+.
- Ejecutar `scripts/generate_questions_python.py` para generar más
- O crear un script mejorado que genere preguntas de todos los tipos
- Importar a Firestore con `scripts/import_questions_rest.py`

### 🟡 PRIORIDAD 4: Eliminar debug code
Una vez fijado el bug de opciones, eliminar:
- El bloque de debug en `game_screen.dart` (línea ~237-249)
- El método `_formatNumber` no usado en `question_card.dart` (se puede dejar, no molesta)

---

## 3. Arquitectura del Proyecto

### Estructura de carpetas
```
lib/
├── core/                          # Capa core (compartido)
│   ├── constants/
│   │   ├── app_constants.dart     # Constantes generales de la app
│   │   ├── firebase_constants.dart # Nombres de colecciones Firestore
│   │   └── game_constants.dart    # Constantes del juego (tiempos, ELO, scoring)
│   ├── errors/
│   │   ├── exceptions.dart        # Excepciones custom
│   │   └── failures.dart          # Failures para Either
│   ├── utils/
│   │   └── score_calculator.dart  # Cálculos de puntuación y ranks
│   └── theme/
│       └── app_theme.dart         # Tema de la app
│
├── data/                          # Capa de datos
│   ├── datasources/
│   │   └── remote/
│   │       └── auth_remote_datasource.dart  # Firebase Auth
│   ├── models/                    # Models (Freezed + json_serializable)
│   │   ├── question_model.dart
│   │   ├── match_model.dart
│   │   ├── user_model.dart
│   │   ├── ghost_run_model.dart
│   │   └── json_key_converter.dart  # Converters para enums
│   └── repositories/              # Implementaciones de repositorios
│       ├── auth_repository_impl.dart
│       ├── user_repository_impl.dart
│       ├── question_repository_impl.dart
│       ├── match_repository_impl.dart
│       └── ghost_run_repository_impl.dart
│
├── domain/                        # Capa de dominio (pura, sin dependencias)
│   ├── entities/
│   │   ├── question.dart          # Question, QuestionType enum, Difficulty enum
│   │   ├── match.dart             # Match, Answer, MatchResult
│   │   └── user.dart              # User entity
│   └── repositories/              # Interfaces abstractas
│       ├── auth_repository.dart
│       ├── user_repository.dart
│       ├── question_repository.dart
│       ├── match_repository.dart
│       └── ghost_run_repository.dart
│
├── presentation/                  # Capa de presentación
│   ├── providers/                 # Riverpod providers
│   │   ├── auth_provider.dart     # Estado de autenticación
│   │   ├── user_provider.dart     # Perfil y stats de usuario
│   │   └── game_provider.dart     # Estado del juego (freezed state machine)
│   ├── screens/
│   │   ├── splash/splash_screen.dart
│   │   ├── auth/login_screen.dart
│   │   ├── home/home_screen.dart
│   │   └── game/
│   │       ├── game_screen.dart           # Pantalla principal del juego
│   │       └── widgets/
│   │           ├── question_card.dart     # Card de pregunta (7 tipos)
│   │           ├── answer_options_widget.dart  # Botones A/B/C/D
│   │           ├── answer_feedback_widget.dart # Feedback correcto/incorrecto
│   │           ├── game_result_widget.dart     # Pantalla de resultados
│   │           └── timer_widget.dart           # Timer circular
│   └── widgets/common/
│       ├── loading_widget.dart
│       ├── error_widget.dart
│       └── custom_button.dart
│
├── app.dart                       # MaterialApp + GoRouter
└── main.dart                      # Entry point (Firebase init)
```

### Patrones utilizados
- **Clean Architecture:** domain → data → presentation (3 capas)
- **Freezed:** Para estados inmutables (GameState, QuestionModel, etc.)
- **Riverpod + codegen:** Providers con `@riverpod` annotation
- **dartz Either:** Manejo de errores funcional (Left failure, Right success)
- **Repository pattern:** Interfaces en domain, implementaciones en data

### Flujo de estado del juego (game_provider.dart)
```
initial → loading → playing ↔ answered → playing → ... → finished
                     ↑                               ↓
                     └────── error ←─────────────────┘
```

Estados:
- `initial`: Pantalla de "Ready to Play?"
- `loading`: Cargando preguntas de Firestore
- `playing`: Mostrando pregunta + timer + opciones
- `answered`: Feedback de respuesta (correcto/incorrecto/timeout)
- `finished`: Pantalla de resultados finales
- `error`: Error message

---

## 4. Patrones y Convenciones

### Estilo de código
- **Idioma:** Comentarios en inglés, textos UI en español
- **Colores principales:**
  - Background: `Color(0xFF1A1A2E)` (azul oscuro)
  - Cards: `Color(0xFF2D2D44)` (azul medio)
  - Botones: `Color(0xFF3D3D5C)` (azul claro)
  - Acento: `Colors.orange`
  - Texto: `Colors.white`
- **Fonts:** Sin font custom, usa la del sistema
- **Border radius:** 16-20 para cards, 12 para botones internos

### Cómo crear un nuevo provider
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_provider.freezed.dart';  // Solo si usa @freezed
part 'my_provider.g.dart';

@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  MyState build() => MyState.initial();
  
  void doSomething() {
    state = MyState.loading();
    // ...
    state = MyState.done();
  }
}
```

Después ejecutar:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Cómo añadir un nuevo tipo de pregunta
1. Añadir el tipo en `lib/domain/entities/question.dart` (enum QuestionType)
2. Actualizar `QuestionTypeConverter` en `lib/data/models/json_key_converter.dart`
3. Añadir caso en `_buildQuestionContent()` de `question_card.dart`
4. Crear método `_buildXxxQuestion()` en `question_card.dart`
5. Generar preguntas en `scripts/` e importar a Firestore

### Tipos de pregunta actuales
```dart
enum QuestionType {
  silhouette,  // Silueta de país (necesita imagen)
  flag,        // Bandera (usa flagcdn.com)
  capital,     // Capital de país
  population,  // Comparar población
  river,       // Río y país
  cityPhoto,   // Foto de ciudad (necesita imagen)
  area,        // Comparar extensión
}
```

---

## 5. Flujo de la App

### Navegación actual
```
SplashScreen → LoginScreen → HomeScreen → GameScreen
```

### Flujo del juego
1. Usuario selecciona dificultad en HomeScreen
2. `GameScreen` se abre con la dificultad
3. `GameNotifier.startGame()` carga 10 preguntas de Firestore
4. Para cada pregunta:
   - Muestra `QuestionCard` + `AnswerOptionsWidget` + `TimerWidget`
   - Usuario selecciona respuesta o se agota el tiempo (10s)
   - Muestra `AnswerFeedbackWidget` (1-2 segundos)
   - Pasa a siguiente pregunta
5. Al terminar: `GameResultWidget` con puntuación y stats

### Scoring
- Base: 100 puntos por respuesta correcta
- Bonus tiempo: 10 × segundos restantes
- Bonus streak: 50 × nivel de racha
- Máximo teórico: ~1000 puntos por partida perfecta

---

## 6. Tareas por Fase (Roadmap)

### FASE 5: Matchmaking Multiplayer 🔴 Alta Prioridad
**Archivos a crear:**
- `lib/data/datasources/remote/matchmaking_datasource.dart`
- `lib/data/repositories/matchmaking_repository_impl.dart`
- `lib/domain/repositories/matchmaking_repository.dart` (ya existe interfaz)
- `lib/presentation/providers/matchmaking_provider.dart`
- `lib/presentation/screens/matchmaking/matchmaking_screen.dart`
- `functions/src/index.ts` (Cloud Functions)
- `functions/src/matchmaking.ts`
- `functions/src/elo.ts`

**Qué hacer:**
1. Crear `MatchmakingService` que gestione la cola en Realtime Database
2. Cloud Function `onQueueJoin`: buscar oponente con ELO similar (±200)
3. Cloud Function `onMatchFinished`: calcular nuevo ELO de ambos jugadores
4. Cloud Function `resetDailyLimits`: resetear contadores a medianoche
5. UI: `MatchmakingScreen` con animación de búsqueda y countdown

**Referencia:** `docs/FASE5_INSTRUCCIONES.md` (si existe)

### FASE 6: Ghost Runs (Partidas Asíncronas) 🟡 Media
**Qué hacer:**
1. Guardar la "performance" del jugador como ghost run (respuestas + tiempos)
2. Buscar ghost run de jugador con ELO similar
3. Comparar resultado actual vs ghost run
4. Mostrar progreso en tiempo real contra el "fantasma"
5. Cleanup: mantener solo últimos 5 ghost runs por usuario

### FASE 7: Monetización 🟡 Media
**Qué hacer:**
1. Integrar RevenueCat (`purchases_flutter`)
2. Pantalla de suscripción con beneficios
3. Enforzar límites diarios (1 casual free, 1 ranked free)
4. Premium: 5 ranked/día, sin anuncios, stats avanzadas

### FASE 8: Polish y Despliegue 🟢 Baja
**Qué hacer:**
1. ProfileScreen (avatar, stats, historial partidas)
2. LeaderboardScreen (ranking global)
3. Tests (unit, widget, integration)
4. Firebase Analytics + Crashlytics
5. Build Android (AAB) + iOS (IPA)
6. Deploy Cloud Functions
7. Submit a Google Play + App Store

---

## 7. Comandos Útiles

### Desarrollo
```bash
# Instalar dependencias
cd d:\Repos\GeoC && flutter pub get

# Regenerar código (freezed, json_serializable, riverpod)
cd d:\Repos\GeoC && dart run build_runner build --delete-conflicting-outputs

# Regenerar en watch mode (durante desarrollo)
cd d:\Repos\GeoC && dart run build_runner watch --delete-conflicting-outputs

# Ejecutar app en Chrome (web)
cd d:\Repos\GeoC && flutter run -d chrome

# Ejecutar app en dispositivo conectado
cd d:\Repos\GeoC && flutter run

# Analizar código
cd d:\Repos\GeoC && flutter analyze
```

### Preguntas (scripts)
```bash
# Generar preguntas con Python (RECOMENDADO)
cd d:\Repos\GeoC && python scripts/generate_questions_python.py

# Importar preguntas a Firestore vía REST API
cd d:\Repos\GeoC && python scripts/import_questions_rest.py

# Generar preguntas con Dart
cd d:\Repos\GeoC && dart scripts/generate_questions_with_manual.dart
```

### Firebase
```bash
# Reconfigurar Firebase (si cambia el proyecto)
cd d:\Repos\GeoC && flutterfire configure

# Desplegar Cloud Functions (cuando existan)
cd d:\Repos\GeoC && firebase deploy --only functions

# Ver datos en Firestore Console
# https://console.firebase.google.com/project/geoquiz-7790d/firestore
```

---

## 8. Notas Importantes

### Firebase Configuration
- **Project ID:** `geoquiz-7790d`
- **API Key:** `AIzaSyCFOIzMkKStbRpsM2dtNoLJcTbWp83xe9w`
- **Colección de preguntas:** `questions`
- **Auth habilitado:** Google Sign-In
- **Firestore rules:** Modo de prueba (permitir todo temporalmente)

### Dependencias clave (pubspec.yaml)
- `flutter_riverpod` + `riverpod_annotation`: State management
- `freezed_annotation` + `json_annotation`: Modelos inmutables
- `cloud_firestore`: Base de datos
- `firebase_auth` + `google_sign_in`: Autenticación
- `cached_network_image`: Imágenes con caché
- `go_router`: Navegación
- `dartz`: Either para error handling

### Cómo seguir el estilo de trabajo
1. **Siempre explorar antes de implementar:** Usar `list_files`, `read_file`, `search_files` para entender el contexto
2. **Hacer cambios pequeños y testables:** Un fix a la vez, probar antes de seguir
3. **Seguir Clean Architecture:** domain (puro) → data (Firebase) → presentation (UI)
4. **Usar replace_in_file** para cambios pequeños, **write_to_file** para archivos nuevos
5. **Ejecutar build_runner** después de cambios en modelos o providers
6. **Actualizar PROGRESO_COMPLETO.md** después de cada fase o fix importante

### Problemas conocidos de la app web
- `google_sign_in_web`: Error "Future already completed" por doble inicialización. No es blocking.
- Hot reload puede no reflejar cambios en providers con estado. Usar hot restart (`R` mayúscula).

### Datos de preguntas en Firestore
Las preguntas tienen esta estructura:
```json
{
  "id": "flag_30000",
  "type": "flag",
  "difficulty": "medium",
  "questionText": "¿De qué país es esta bandera?",
  "correctAnswer": "España",
  "options": ["Polonia", "España", "Austria", "Suiza"],
  "imageUrl": "https://flagcdn.com/w320/es.png",
  "extraData": {
    "countryCode": "es",
    "countryName": "España"
  }
}
```

**⚠️ IMPORTANTE:** El campo `options` es un array de strings. Si está vacío o no existe, las opciones no se muestran.

---

## 📝 Checklist para empezar a trabajar

Cuando el agente arranque, debería seguir este orden:

- [ ] **1. Diagnosticar bug de opciones vacías** (ver sección 1)
- [ ] **2. Reimportar preguntas si es necesario** (`python scripts/import_questions_rest.py`)
- [ ] **3. Eliminar código de debug** una vez fijado
- [ ] **4. Regenerar código** (`dart run build_runner build --delete-conflicting-outputs`)
- [ ] **5. Generar más preguntas** (objetivo: 500+)
- [ ] **6. Probar flujo completo** del juego single-player
- [ ] **7. Empezar FASE 5** (Matchmaking) cuando el single-player funcione perfecto
- [ ] **8. Actualizar PROGRESO_COMPLETO.md** con cada avance

---

**¡Buena suerte, agente! 🚀**