# GeoC Quiz Analytics System

## Overview

Este sistema implementa tracking completo de respuestas individuales en GeoC, permitiendo análisis de estadísticas detalladas como:
- Preguntas más falladas
- Preguntas más fáciles
- Tasa de éxito por categoría (flag, capital, region, etc.)
- Tendencias temporales
- Estadísticas por usuario

## Architecture

### Data Flow

```
User answers question
       ↓
Provider (game_provider.dart / multiplayer_provider.dart)
       ↓
QuizAttemptModel (data model)
       ↓
QuizAttemptRepository (repository layer)
       ↓
Firestore (quizAttempts collection)
       ↓
Analytics Queries (for statistics)
```

### Collections

#### `quizAttempts`

Cada respuesta individual de cada partida:

```dart
{
  questionId: "capital-france",
  questionType: "capital",
  questionDifficulty: "medium",
  correctAnswer: "Paris",
  userAnswer: "Lyon",
  isCorrect: false,
  isTimeout: false,
  timeMs: 12345,
  matchId: "match_abc123",
  matchMode: "realtime",
  matchType: "ranked",
  userId: "user_456",
  userElo: 1250,
  answeredAt: Timestamp,
  questionData: {...}
}
```

## Files Created/Modified

### New Files

1. **`lib/data/models/quiz_attempt_model.dart`**
   - Modelo para cada respuesta individual
   - Incluye cálculo de similitud de respuestas (Levenshtein)
   - Conversión desde/hacia Firestore

2. **`lib/domain/repositories/quiz_attempt_repository.dart`**
   - Interfaz del repositorio
   - Métodos de consulta y estadísticas

3. **`lib/data/repositories/quiz_attempt_repository_impl.dart`**
   - Implementación completa del repositorio
   - Queries optimizadas para Firestore

4. **`lib/presentation/providers/quiz_attempt_provider.dart`**
   - Provider de Riverpod para el repositorio

### Modified Files

1. **`lib/core/constants/firebase_constants.dart`**
   - Added: `quizAttempts` collection

2. **`lib/presentation/providers/game_provider.dart`**
   - Added: tracking automático en modo practice
   - Method: `_trackQuizAttempt()`

3. **`lib/presentation/providers/multiplayer_provider.dart`**
   - Added: tracking automático en modo multiplayer
   - Method: `_trackQuizAttempt()`

## Firestore Indexes Required

### Single Field Indexes

These should be created automatically in Firestore console:

- `questionId` (for querying by question)
- `questionType` (for querying by category)
- `answeredAt` (descending) (for date range queries)

### Composite Indexes

Create these manually in Firestore console → Indexes:

1. **For date range queries by type:**
   - Collection: `quizAttempts`
   - Fields: `answeredAt` (DESC), `questionType` (ASC)
   - Query Scope: Collection

2. **For user attempts by date:**
   - Collection: `quizAttempts`
   - Fields: `userId` (ASC), `answeredAt` (DESC)
   - Query Scope: Collection

3. **For question attempts by date:**
   - Collection: `quizAttempts`
   - Fields: `questionId` (ASC), `answeredAt` (DESC)
   - Query Scope: Collection

## API Usage Examples

### Basic Tracking (Automatic)

```dart
// In your game provider, tracking is now automatic
ref.read(gameProvider.notifier).submitAnswer(
  selectedAnswer: "Paris",
  isTimeout: false,
);
// Response is automatically saved to Firestore
```

### Manual Statistics Queries

```dart
// Get most failed questions
final result = await ref.read(quizAttemptRepositoryProvider)
    .getMostFailedQuestions(limit: 10, minAttempts: 10);

result.fold(
  (failure) => print('Error: $failure'),
  (stats) {
    stats.forEach((stat) {
      print('${stat.questionId}: ${stat.successPercentage}% success');
    });
  },
);
```

```dart
// Get statistics by type
final result = await ref.read(quizAttemptRepositoryProvider)
    .getStatsByType(
      startDate: DateTime.now().subtract(Duration(days: 7)),
      endDate: DateTime.now(),
    );

result.fold(
  (failure) => print('Error: $failure'),
  (stats) {
    stats.forEach((type, stat) {
      print('$type: ${stat.successPercentage}% success (${stat.totalAttempts} attempts)');
    });
  },
);
```

```dart
// Get success rate for a specific question
final result = await ref.read(quizAttemptRepositoryProvider)
    .getSuccessRate('capital-france');

result.fold(
  (failure) => print('Error: $failure'),
  (rate) => print('Success rate: ${rate * 100}%'),
);
```

## Performance Considerations

### Non-blocking Design

- All tracking operations use "fire and forget" pattern
- Errors don't crash the game
- Uses `Future.then()` without `await`

### Firestore Costs

Each answer creates one document. With these assumptions:
- 1000 active users
- 10 questions per game
- 3 games per day per user

Total: 30,000 documents/day ~ 900,000 documents/month

Estimated cost: ~$1-2/month (Firestore pricing: read/write operations)

### Query Optimization

- Limit queries with `limit()` parameter
- Use composite indexes for date range queries
- Consider TTL (Time to Live) for old data if needed

## Cron Job for Daily Analytics

Once data is being collected, you can create a cron job:

```python
cronjob(
  action="create",
  name="GeoC Analytics - Daily",
  schedule="0 9 * * *",  # Every day at 9 AM
  prompt="""
Generate daily analytics report for GeoC quiz app.

1. Get statistics from Firestore for last 24 hours
2. Report:
   - Most failed questions (top 10)
   - Easiest questions (top 10)
   - Success rate by category
   - Total attempts in period
   - Average response time
3. Send formatted report to Telegram
""",
  deliver="origin"
)
```

## Next Steps

1. **Build the app** to generate freezed files:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **Deploy to Firebase**:
   ```bash
   flutter run
   ```

3. **Create Firestore indexes** in Firebase Console

4. **Test tracking** by answering questions in the app

5. **Verify data** in Firestore Console → quizAttempts collection

6. **Create cron job** for daily analytics (once you have data)

## Troubleshooting

### Missing Firestore indexes

If you get errors like "The query requires an index", check the Firebase Console → Firestore → Indexes and create the missing index.

### Build runner errors

If freezed generation fails:
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### No data in Firestore

Check the console logs for error messages when submitting answers. Tracking failures are logged to console but don't crash the app.
