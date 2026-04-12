/// Levenshtein distance for fuzzy answer matching
///
/// Measures how many single-character edits (insert, delete, replace)
/// are needed to transform one string into another.

/// Calculates the Levenshtein distance between two strings.
int levenshteinDistance(String s1, String s2) {
  if (s1 == s2) return 0;
  if (s1.isEmpty) return s2.length;
  if (s2.isEmpty) return s1.length;

  List<int> prev = List.generate(s2.length + 1, (i) => i);
  List<int> curr = List.filled(s2.length + 1, 0);

  for (int i = 1; i <= s1.length; i++) {
    curr[0] = i;
    for (int j = 1; j <= s2.length; j++) {
      int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
      curr[j] = [
        prev[j] + 1,      // deletion
        curr[j - 1] + 1,  // insertion
        prev[j - 1] + cost // substitution
      ].reduce((a, b) => a < b ? a : b);
    }
    final temp = prev;
    prev = curr;
    curr = temp;
  }

  return prev[s2.length];
}

/// Returns a similarity score between 0.0 and 1.0.
///
/// 1.0 = perfect match, 0.0 = completely different.
double answerSimilarity(String userAnswer, String correctAnswer) {
  final s1 = userAnswer.toLowerCase().trim();
  final s2 = correctAnswer.toLowerCase().trim();

  if (s1.isEmpty) return 0.0;
  if (s1 == s2) return 1.0;

  final distance = levenshteinDistance(s1, s2);
  final maxLen = s1.length > s2.length ? s1.length : s2.length;

  return 1.0 - (distance / maxLen);
}

/// Calculates score for a typed answer based on accuracy and speed.
///
/// [similarity] - 0.0 to 1.0 from answerSimilarity()
/// [timeRemaining] - Seconds left when answered (0-15 for type mode)
/// [maxTime] - Max seconds for the question
/// [streak] - Current streak
///
/// Returns score for this answer.
int calculateTypedScore({
  required double similarity,
  required int timeRemaining,
  required int maxTime,
  required int streak,
}) {
  if (similarity < 0.5) return 0; // Too far off

  // Accuracy multiplier
  double accuracyMultiplier;
  if (similarity >= 1.0) {
    accuracyMultiplier = 1.0; // Perfect
  } else if (similarity >= 0.85) {
    accuracyMultiplier = 0.75; // Almost perfect
  } else if (similarity >= 0.7) {
    accuracyMultiplier = 0.5; // Close
  } else {
    accuracyMultiplier = 0.25; // Barely
  }

  // Speed multiplier: faster = more points
  final speedRatio = timeRemaining / maxTime;
  final speedMultiplier = 0.5 + (speedRatio * 0.5); // 0.5x to 1.0x

  // Streak bonus
  final streakBonus = (streak * 25).toDouble();

  // Base score
  const baseScore = 150; // Higher base than multiple choice

  final score = (baseScore * accuracyMultiplier * speedMultiplier + streakBonus).round();
  return score;
}

/// Returns a label for the accuracy level.
String accuracyLabel(double similarity) {
  if (similarity >= 1.0) return '¡PERFECTO!';
  if (similarity >= 0.85) return '¡Casi!';
  if (similarity >= 0.7) return 'Cerca';
  if (similarity >= 0.5) return 'Aprobable';
  return 'Incorrecto';
}

/// Returns a color value for the accuracy level.
int accuracyColor(double similarity) {
  if (similarity >= 1.0) return 0xFFFFD700; // Gold
  if (similarity >= 0.85) return 0xFF4CAF50; // Green
  if (similarity >= 0.7) return 0xFFFF9800; // Orange
  if (similarity >= 0.5) return 0xFFFF5722; // Deep orange
  return 0xFFF44336; // Red
}
