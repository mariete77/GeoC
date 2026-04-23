import 'package:dartz/dartz.dart';
import 'package:geoquiz_battle/core/errors/failures.dart';
import 'package:geoquiz_battle/data/models/quiz_attempt_model.dart';

/// Repositorio para tracking de respuestas individuales
/// Almacena cada intento de respuesta en Firestore para análisis estadístico
abstract class QuizAttemptRepository {
  /// Guarda un intento de respuesta en Firestore
  /// Returns: Right con el ID del documento creado, o Left con Failure
  Future<Either<Failure, String>> recordAttempt(QuizAttemptModel attempt);

  /// Obtiene todos los intentos para una pregunta específica
  /// Útil para calcular tasa de éxito de una pregunta
  Future<Either<Failure, List<QuizAttemptModel>>> getAttemptsByQuestion(
    String questionId, {
    int limit = 1000,
  });

  /// Obtiene todos los intentos para un tipo de pregunta
  /// Útil para analizar dificultad por categoría (flag, capital, region, etc.)
  Future<Either<Failure, List<QuizAttemptModel>>> getAttemptsByType(
    String questionType, {
    int limit = 1000,
  });

  /// Obtiene intentos en un rango de fechas
  /// Útil para análisis temporales (últimos 7 días, último mes, etc.)
  Future<Either<Failure, List<QuizAttemptModel>>> getAttemptsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? questionType,
    int limit = 1000,
  });

  /// Obtiene intentos de un usuario específico
  /// Útil para estadísticas personales del usuario
  Future<Either<Failure, List<QuizAttemptModel>>> getAttemptsByUser(
    String userId, {
    int limit = 100,
  });

  /// Calcula estadísticas de éxito para una pregunta
  /// Returns: porcentaje de aciertos (0.0 - 1.0)
  Future<Either<Failure, double>> getSuccessRate(String questionId);

  /// Obtiene las preguntas más falladas
  /// limit: número de resultados a devolver
  /// minAttempts: mínimo de intentos para considerar una pregunta
  Future<Either<Failure, List<QuestionStats>>> getMostFailedQuestions({
    int limit = 10,
    int minAttempts = 10,
  });

  /// Obtiene las preguntas más fáciles (menos fallos)
  /// limit: número de resultados a devolver
  /// minAttempts: mínimo de intentos para considerar una pregunta
  Future<Either<Failure, List<QuestionStats>>> getEasiestQuestions({
    int limit = 10,
    int minAttempts = 10,
  });

  /// Obtiene estadísticas agregadas por tipo de pregunta
  /// Returns: mapa tipo de pregunta -> estadísticas
  Future<Either<Failure, Map<String, TypeStats>>> getStatsByType({
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// Estadísticas de una pregunta específica
class QuestionStats {
  final String questionId;
  final String questionType;
  final int totalAttempts;
  final int correctAttempts;
  final int incorrectAttempts;
  final double successRate;
  final double avgTimeMs;
  final double avgSimilarity; // Promedio de similitud de respuestas incorrectas
  final int timeoutCount;

  QuestionStats({
    required this.questionId,
    required this.questionType,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.incorrectAttempts,
    required this.successRate,
    required this.avgTimeMs,
    required this.avgSimilarity,
    required this.timeoutCount,
  });

  /// Calcular tasa de éxito
  double get successPercentage => successRate * 100;
}

/// Estadísticas agregadas por tipo de pregunta
class TypeStats {
  final String type;
  final int totalAttempts;
  final int correctAttempts;
  final double successRate;
  final double avgTimeMs;
  final int uniqueQuestions;

  TypeStats({
    required this.type,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.successRate,
    required this.avgTimeMs,
    required this.uniqueQuestions,
  });

  /// Calcular tasa de éxito
  double get successPercentage => successRate * 100;
}
