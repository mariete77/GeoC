import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_attempt_model.freezed.dart';
part 'quiz_attempt_model.g.dart';

/// Modelo para tracking individual de cada respuesta
/// Almacena cada intento de respuesta en Firestore para análisis de estadísticas
@freezed
class QuizAttemptModel with _$QuizAttemptModel {
  const QuizAttemptModel._();

  const factory QuizAttemptModel({
    required String questionId,
    required String questionType,
    required String correctAnswer,
    required String userAnswer,
    required bool isCorrect,
    required bool isTimeout,
    required int timeMs,
    required String matchId,
    required String matchMode,
    required String matchType,
    String? userId,
    int? userElo,
    String? questionDifficulty,
    required DateTime answeredAt,
    Map<String, dynamic>? questionData,
  }) = _QuizAttemptModel;

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) =>
      _$QuizAttemptModelFromJson(json);

  /// Crear desde Firestore
  factory QuizAttemptModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizAttemptModel.fromJson({
      ...data,
      'answeredAt': data['answeredAt'] != null
          ? (data['answeredAt'] as Timestamp).toDate().toIso8601String()
          : DateTime.now().toIso8601String(),
    });
  }

  /// Convertir a Firestore map
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    final firestoreJson = <String, dynamic>{
      'questionId': questionId,
      'questionType': questionType,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'isTimeout': isTimeout,
      'timeMs': timeMs,
      'matchId': matchId,
      'matchMode': matchMode,
      'matchType': matchType,
      'answeredAt': Timestamp.fromDate(answeredAt),
    };

    if (userId != null) firestoreJson['userId'] = userId;
    if (userElo != null) firestoreJson['userElo'] = userElo;
    if (questionDifficulty != null) {
      firestoreJson['questionDifficulty'] = questionDifficulty;
    }
    if (questionData != null) firestoreJson['questionData'] = questionData;

    return firestoreJson;
  }

  /// Calcular porcentaje de similitud entre respuesta y respuesta correcta
  /// Útil para preguntas de texto donde quieres ver qué tan cerca estuvo el usuario
  double get answerSimilarity {
    if (correctAnswer.toLowerCase() == userAnswer.toLowerCase()) {
      return 1.0;
    }
    // Implementación simple de distancia de Levenshtein
    final correct = correctAnswer.toLowerCase();
    final user = userAnswer.toLowerCase();

    if (correct.isEmpty || user.isEmpty) return 0.0;

    final maxLen = [correct.length, user.length].reduce((a, b) => a > b ? a : b);
    if (maxLen == 0) return 0.0;

    final distance = _levenshteinDistance(correct, user);
    return 1.0 - (distance / maxLen);
  }

  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );

    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }

    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        if (a[i - 1] == b[j - 1]) {
          matrix[i][j] = matrix[i - 1][j - 1];
        } else {
          matrix[i][j] = [
            matrix[i - 1][j] + 1, // deletion
            matrix[i][j - 1] + 1, // insertion
            matrix[i - 1][j - 1] + 1, // substitution
          ].reduce((a, b) => a < b ? a : b);
        }
      }
    }

    return matrix[a.length][b.length];
  }
}
