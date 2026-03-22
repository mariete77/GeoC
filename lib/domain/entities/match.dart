import 'package:equatable/equatable.dart';

/// Match status
enum MatchStatus { waiting, active, finished, cancelled }

/// Match mode
enum MatchMode { realtime, async }

/// Match type
enum MatchType { casual, ranked }

/// Match entity
class Match extends Equatable {
  final String id;
  final List<String> players;
  final MatchMode mode;
  final MatchType type;
  final MatchStatus status;
  final List<String> questionIds;
  final Map<String, List<Answer>> answers;
  final MatchResult? result;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  const Match({
    required this.id,
    required this.players,
    required this.mode,
    required this.type,
    required this.status,
    required this.questionIds,
    required this.answers,
    this.result,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
  });

  /// Check if user is a player in this match
  bool isPlayer(String userId) => players.contains(userId);

  /// Get opponent's user ID
  String? getOpponentId(String myUserId) {
    return players.firstWhere((id) => id != myUserId, orElse: () => '');
  }

  @override
  List<Object?> get props => [
        id,
        players,
        mode,
        type,
        status,
        questionIds,
        answers,
        result,
        createdAt,
        startedAt,
        finishedAt,
      ];
}

/// Answer entity
class Answer extends Equatable {
  final int questionIndex;
  final String selectedAnswer;
  final bool isCorrect;
  final int timeMs;
  final DateTime answeredAt;

  const Answer({
    required this.questionIndex,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.timeMs,
    required this.answeredAt,
  });

  @override
  List<Object?> get props => [
        questionIndex,
        selectedAnswer,
        isCorrect,
        timeMs,
        answeredAt,
      ];
}

/// Match result
class MatchResult extends Equatable {
  final String? winnerId;
  final Map<String, int> scores;
  final Map<String, int> eloChanges;
  final Map<String, int> newElo;

  const MatchResult({
    this.winnerId,
    required this.scores,
    required this.eloChanges,
    required this.newElo,
  });

  /// Check if match was a draw
  bool get isDraw => winnerId == null;

  @override
  List<Object?> get props => [winnerId, scores, eloChanges, newElo];
}

/// Ghost run for async matches
class GhostRun extends Equatable {
  final String userId;
  final String ghostRunId;
  final int elo;
  final List<String> questionIds;
  final List<GhostAnswer> answers;
  final DateTime createdAt;

  const GhostRun({
    required this.userId,
    required this.ghostRunId,
    required this.elo,
    required this.questionIds,
    required this.answers,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        userId,
        ghostRunId,
        elo,
        questionIds,
        answers,
        createdAt,
      ];
}

/// Ghost answer (simplified answer for ghost runs)
class GhostAnswer extends Equatable {
  final int questionIndex;
  final bool isCorrect;
  final int timeMs;

  const GhostAnswer({
    required this.questionIndex,
    required this.isCorrect,
    required this.timeMs,
  });

  @override
  List<Object?> get props => [questionIndex, isCorrect, timeMs];
}
