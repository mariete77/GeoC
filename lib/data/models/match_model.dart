import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/match.dart';

/// Match model for Firestore serialization
class MatchModel {
  final String id;
  final List<String> players;
  final String mode;
  final String type;
  final String status;
  final List<String> questionIds;
  final Map<String, List<Map<String, dynamic>>> answers;
  final Map<String, dynamic>? result;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int creatorElo;

  const MatchModel({
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
    this.creatorElo = 1000,
  });

  /// Create from Firestore DocumentSnapshot
  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    return MatchModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Create from JSON map
  factory MatchModel.fromJson(Map<String, dynamic> json, String docId) {
    final answersMap = <String, List<Map<String, dynamic>>>{};
    final rawAnswers = json['answers'] as Map<String, dynamic>?;
    if (rawAnswers != null) {
      rawAnswers.forEach((key, value) {
        if (value is List) {
          answersMap[key] = value.map((a) => a as Map<String, dynamic>).toList();
        }
      });
    }

    return MatchModel(
      id: docId,
      players: (json['players'] as List<dynamic>).map((e) => e as String).toList(),
      mode: json['mode'] as String? ?? 'async',
      type: json['type'] as String? ?? 'casual',
      status: json['status'] as String? ?? 'waiting',
      questionIds: (json['questionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      answers: answersMap,
      result: json['result'] as Map<String, dynamic>?,
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      startedAt: (json['startedAt'] as dynamic)?.toDate(),
      finishedAt: (json['finishedAt'] as dynamic)?.toDate(),
      creatorElo: json['creatorElo'] as int? ?? 1000,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final answersJson = <String, dynamic>{};
    answers.forEach((key, value) {
      answersJson[key] = value;
    });

    return {
      'players': players,
      'mode': mode,
      'type': type,
      'status': status,
      'questionIds': questionIds,
      'answers': answersJson,
      if (result != null) 'result': result,
      'creatorElo': creatorElo,
      'createdAt': FieldValue.serverTimestamp(),
      if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
      if (finishedAt != null) 'finishedAt': Timestamp.fromDate(finishedAt!),
    };
  }

  /// Convert to domain entity
  GameMatch toDomain() {
    final domainAnswers = <String, List<Answer>>{};
    answers.forEach((userId, answerList) {
      domainAnswers[userId] = answerList
          .map((a) => Answer(
                questionIndex: a['questionIndex'] as int? ?? 0,
                selectedAnswer: a['selectedAnswer'] as String? ?? '',
                isCorrect: a['isCorrect'] as bool? ?? false,
                timeMs: a['timeMs'] as int? ?? 0,
                answeredAt: a['answeredAt'] != null
                    ? (a['answeredAt'] as dynamic).toDate()
                    : DateTime.now(),
              ))
          .toList();
    });

    MatchResult? domainResult;
    if (result != null) {
      final scores = (result!['scores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {};
      final eloChanges = (result!['eloChanges'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {};
      final newElo = (result!['newElo'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {};
      domainResult = MatchResult(
        winnerId: result!['winnerId'] as String?,
        scores: scores,
        eloChanges: eloChanges,
        newElo: newElo,
      );
    }

    return GameMatch(
      id: id,
      players: players,
      mode: mode == 'realtime' ? MatchMode.realtime : MatchMode.async,
      type: type == 'ranked' ? MatchType.ranked : MatchType.casual,
      status: _parseStatus(status),
      questionIds: questionIds,
      answers: domainAnswers,
      result: domainResult,
      createdAt: createdAt,
      startedAt: startedAt,
      finishedAt: finishedAt,
      creatorElo: creatorElo,
    );
  }

  /// Create from domain entity
  factory MatchModel.fromDomain(GameMatch match) {
    final answersMap = <String, List<Map<String, dynamic>>>{};
    match.answers.forEach((userId, answerList) {
      answersMap[userId] = answerList
          .map((a) => {
                'questionIndex': a.questionIndex,
                'selectedAnswer': a.selectedAnswer,
                'isCorrect': a.isCorrect,
                'timeMs': a.timeMs,
                'answeredAt': a.answeredAt,
              })
          .toList();
    });

    Map<String, dynamic>? resultMap;
    if (match.result != null) {
      resultMap = {
        'winnerId': match.result!.winnerId,
        'scores': match.result!.scores,
        'eloChanges': match.result!.eloChanges,
        'newElo': match.result!.newElo,
      };
    }

    return MatchModel(
      id: match.id,
      players: match.players,
      mode: match.mode == MatchMode.realtime ? 'realtime' : 'async',
      type: match.type == MatchType.ranked ? 'ranked' : 'casual',
      status: _statusToString(match.status),
      questionIds: match.questionIds,
      answers: answersMap,
      result: resultMap,
      createdAt: match.createdAt,
      startedAt: match.startedAt,
      finishedAt: match.finishedAt,
      creatorElo: match.creatorElo,
    );
  }

  static MatchStatus _parseStatus(String s) {
    switch (s) {
      case 'waiting':
        return MatchStatus.waiting;
      case 'active':
        return MatchStatus.active;
      case 'finished':
        return MatchStatus.finished;
      case 'cancelled':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.waiting;
    }
  }

  static String _statusToString(MatchStatus s) {
    switch (s) {
      case MatchStatus.waiting:
        return 'waiting';
      case MatchStatus.active:
        return 'active';
      case MatchStatus.finished:
        return 'finished';
      case MatchStatus.cancelled:
        return 'cancelled';
    }
  }
}