# FASE 4: Core del Juego - Guía Completa

Última actualización: 2026-04-04

---

## 📋 Resumen de la FASE 4

**Objetivo:** Implementar el core del juego single-player con todos los tipos de preguntas, timer, sistema de puntuación y feedback visual.

**Estado:** 🟡 En progreso (archivos creados, pendiente probar)

---

## ✅ Archivos Creados (7 archivos)

### Providers
- ✅ `lib/presentation/providers/game_provider.dart` - State management completo
  - GameState con 5 estados: initial, loading, playing, answered, finished
  - Lógica de timer (10 segundos por pregunta)
  - Sistema de puntuación (base 100 + bonus por tiempo + bonus por streak)
  - Auto-transición entre preguntas
  - Manejo de respuestas correctas/incorrectas
  - Cálculo de estadísticas finales

### Screens
- ✅ `lib/presentation/screens/game/game_screen.dart` - UI principal del juego
  - Integración con GameProvider
  - Muestra score, progreso y timer
  - Manejo de diferentes estados del juego
  - Diálogo de confirmación al salir

### Widgets
- ✅ `lib/presentation/screens/game/widgets/timer_widget.dart` - Timer circular
  - Animación de progreso (verde → naranja → rojo)
  - Dibujo customizado con CustomPainter
  - Indica segundos restantes

- ✅ `lib/presentation/screens/game/widgets/question_card.dart` - Card de preguntas
  - Implementación para 7 tipos de preguntas:
    1. Flag (banderas)
    2. Silhouette (siluetas de países)
    3. Capital (capitales)
    4. Population (población)
    5. River (ríos)
    6. City Photo (fotos de ciudades)
    7. Area (extensión territorial)
  - Badge de dificultad (easy/medium/hard)
  - Carga de imágenes con CachedNetworkImage
  - Manejo de errores en imágenes

- ✅ `lib/presentation/screens/game/widgets/answer_options_widget.dart` - Opciones de respuesta
  - 4 opciones aleatorias (A, B, C, D)
  - Animaciones de escala al presionar
  - Feedback visual al interactuar
  - Diseño consistente con el tema de la app

- ✅ `lib/presentation/screens/game/widgets/answer_feedback_widget.dart` - Feedback de respuesta
  - Animaciones de escala y fade
  - Muestra si fue correcta o incorrecta
  - Muestra los puntos ganados
  - Muestra la respuesta correcta si fue incorrecta
  - Muestra la imagen de la pregunta si la hay

- ✅ `lib/presentation/screens/game/widgets/game_result_widget.dart` - Resultados finales
  - Rank basado en accuracy y score (ROOKIE → LEGENDARY)
  - 4 stat cards: correctas, tiempo medio, accuracy, score medio
  - Mensaje de performance basado en accuracy
  - Botones: "Play Again" y "Back to Home"

---

## 🎯 Sistema de Puntuación

### Cálculo de Puntos por Pregunta

```
Base Score: 100 puntos (si es correcta)
Time Bonus: (segundos restantes) × 10
Streak Bonus: (racha de aciertos) × 50

Total = Base + Time Bonus + Streak Bonus
```

**Ejemplos:**
- Respuesta correcta en 8 segundos: 100 + 80 + 0 = **180 pts**
- Respuesta correcta en 3 segundos (streak 2): 100 + 30 + 100 = **230 pts**
- Respuesta incorrecta: **0 pts**

### Ranks de Resultado

| Rank | Accuracy | Score | Color |
|------|----------|--------|-------|
| LEGENDARY | ≥90% | ≥1500 | 🟡 Gold |
| MASTER | ≥80% | ≥1200 | ⚪ Silver |
| EXPERT | ≥70% | ≥900 | 🟤 Bronze |
| SKILLED | ≥60% | ≥600 | 🟢 Green |
| BEGINNER | ≥50% | - | 🔵 Blue |
| ROOKIE | <50% | - | ⚫ Grey |

---

## ⏳ Flujo del Juego

1. **Start Game** → Carga 10 preguntas aleatorias de la dificultad seleccionada
2. **Playing** → Timer de 10 segundos, muestra pregunta y opciones
3. **Answer Selected** → Valida respuesta, muestra feedback (1-2 segundos)
4. **Auto-Transition** → Siguiente pregunta o finaliza juego
5. **Finished** → Muestra resultados con rank, stats y opciones

---

## 🚀 Pasos para Completar la FASE 4

### Paso 1: Generar código con build_runner

En tu PC (PowerShell):

```powershell
cd D:\Repos\GeoC

# Generar código para freezed, json_serializable, riverpod
dart run build_runner build --delete-conflicting-outputs
```

Esto generará:
- `game_provider.freezed.dart`
- `game_provider.g.dart`
- Código de otros archivos que usan freezed/json_serializable

### Paso 2: Actualizar dependencias (si es necesario)

```powershell
# Instalar dependencias faltantes
flutter pub get
```

Verifica que `pubspec.yaml` incluye:
```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  cached_network_image: ^3.3.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  riverpod_generator: ^2.3.0
```

### Paso 3: Agregar ruta de GameScreen en `app.dart`

Asegúrate de que la ruta esté configurada en `lib/app.dart`:

```dart
GoRoute(
  path: '/game',
  name: 'game',
  builder: (context, state) {
    final difficulty = state.uri.queryParameters['difficulty'] as Difficulty? ??
                      Difficulty.medium;
    return GameScreen(difficulty: difficulty);
  },
),
```

### Paso 4: Probar compilación

```powershell
# Verificar que compila
flutter analyze

# Verificar errores específicos
flutter build apk --debug
```

### Paso 5: Ejecutar y probar

```powershell
# Ejecutar en emulador o dispositivo
flutter run
```

**Flujo de prueba:**
1. Abre la app
2. Haz login
3. En Home, selecciona una dificultad
4. Start game → Debería cargar preguntas
5. Responde algunas preguntas
6. Verifica que:
   - Timer funciona correctamente
   - Puntuación se actualiza
   - Feedback se muestra
   - Transición a siguiente pregunta
   - Resultados finales se muestran

---

## 🐛 Posibles Errores y Soluciones

### Error 1: `GameRepository not implemented yet`

**Solución:** Inyectar la implementación real en el provider:

```dart
// En lib/app.dart o donde configures providers
@riverpod
GameRepository gameRepository(GameRepositoryRef ref) {
  return GameRepositoryImpl(
    firestore: ref.watch(firestoreProvider),
  );
}
```

### Error 2: `QuestionRepository not implemented yet`

**Solución:** Similar al anterior, inyectar la implementación:

```dart
@riverpod
QuestionRepository questionRepository(QuestionRepositoryRef ref) {
  return QuestionRepositoryImpl(
    firestore: ref.watch(firestoreProvider),
  );
}
```

### Error 3: `build_runner` no genera archivos

**Solución:**
```powershell
# Limpiar cache
flutter clean

# Volver a generar
dart run build_runner build --delete-conflicting-outputs
```

### Error 4: `cached_network_image` no muestra imágenes

**Solución:**
- Verifica que las URLs de imágenes en Firestore son válidas
- Verifica que Firebase Storage tiene las imágenes
- Añade permisos de lectura en Storage

### Error 5: Timer no se detiene

**Solución:** Verifica que `_timer?.cancel()` se llame en todos los casos:
- Al responder
- Al timeout
- Al salir del juego

---

## 📊 Métricas de la FASE 4

### Archivos
- **Total:** 7 archivos
- **Líneas de código:** ~1,500 líneas
- **Widgets:** 6 widgets reutilizables

### Funcionalidades implementadas
- ✅ 7 tipos de preguntas
- ✅ Timer circular con animaciones
- ✅ Sistema de puntuación (base + tiempo + streak)
- ✅ Feedback visual instantáneo
- ✅ Resultados finales con ranks
- ✅ Auto-transición entre preguntas
- ✅ Manejo de errores y timeouts

### Pendiente
- ⏳ Generar código con build_runner
- ⏳ Probar en emulador
- ⏳ Corregir errores de compilación (si hay)
- ⏳ Probar flujo completo single-player

---

## 🎯 Checklist de Completado

- [ ] Generar código con `dart run build_runner build`
- [ ] Verificar que `flutter analyze` no tenga errores
- [ ] Verificar que `flutter run` compila
- [ ] Probar carga de preguntas desde Firestore
- [ ] Probar timer (10 segundos por pregunta)
- [ ] Probar todas las preguntas (7 tipos)
- [ ] Verificar puntuación (base + tiempo + streak)
- [ ] Probar feedback correcta/incorrecta
- [ ] Probar transición a siguiente pregunta
- [ ] Probar resultados finales con rank
- [ ] Probar botón "Play Again"
- [ ] Probar botón "Back to Home"
- [ ] Probar salir del juego (confirmación)

---

## 🚀 Próximos Pasos después de la FASE 4

Una vez completada la FASE 4:

1. **Probar integración completa:**
   - Splash → Login → Home → Game → Resultados → Home

2. **Optimizar performance:**
   - Carga de imágenes
   - Transiciones entre preguntas
   - Animaciones

3. **Corregir bugs encontrados:**

4. **FASE 5: Matchmaking Multiplayer**
   - Implementar MatchmakingService
   - Cloud Functions para matchmaking
   - Conexión con Realtime Database

---

## 📝 Notas Importantes

### Imágenes de Preguntas

Actualmente, la implementación asume que las preguntas tienen `imageUrl` configurado en Firestore. Necesitas:

1. **Subir imágenes a Firebase Storage:**
   - Banderas (~100 imágenes)
   - Siluetas de países (~100 imágenes)
   - Fotos de ciudades (~20 imágenes)

2. **Actualizar preguntas en Firestore:**
   - Añadir campo `imageUrl` a las preguntas correspondientes
   - Verificar que las URLs son públicas y accesibles

### Tipos de preguntas sin imágenes
- Capital (usa icono)
- Population (usa icono)
- River (usa icono)
- Area (usa icono)

Estos NO requieren imágenes, funcionan con el código actual.

### Dificultad de preguntas
Asegúrate de que las preguntas en Firestore tienen el campo `difficulty`:
- `easy` (fácil)
- `medium` (medio)
- `hard` (difícil)

---

## 🆘 Ayuda

Si encuentras errores:

1. **Lee el error completo** - A veces tiene pistas sobre qué falta
2. **Verifica imports** - Asegúrate de que todos los imports sean correctos
3. **Limpia cache** - `flutter clean`
4. **Reinstala dependencias** - `flutter pub get`
5. **Contacta a Koda** - Estoy aquí para ayudarte

---

**Última actualización:** 2026-04-04
**Estado:** Archivos creados, pendiente probar en PC local
**Tiempo estimado:** 1-2 horas para completar y probar
