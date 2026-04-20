import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/match.dart';

/// Ghost run model for Firestore serialization
class GhostRunModel {
  final String id;
  final String userId;
  final int elo;
  final List<String> questionIds;
  final List<GhostAnswerModel> answers;
  final DateTime createdAt;

  const GhostRunModel({
    required this.id,
    required this.userId,
    required this.elo,
    required this.questionIds,
    required this.answers,
    required this.createdAt,
  });

  /// Create from Firestore DocumentSnapshot
  factory GhostRunModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GhostRunModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      elo: data['elo'] as int? ?? 1000,
      questionIds: (data['questionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      answers: (data['answers'] as List<dynamic>?)
              ?.map((a) => GhostAnswerModel.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'elo': elo,
      'questionIds': questionIds,
      'answers': answers.map((a) => a.toJson()).toList(),
      'createdAt': createdAt,
    };
  }

  /// Convert to domain entity
  GhostRun toDomain() {
    return GhostRun(
      userId: userId,
      ghostRunId: id,
      elo: elo,
      questionIds: questionIds,
      answers: answers.map((a) => a.toDomain()).toList(),
      createdAt: createdAt,
    );
  }

  /// Create from domain entity
  factory GhostRunModel.fromDomain(GhostRun ghostRun) {
    return GhostRunModel(
      id: ghostRun.ghostRunId,
      userId: ghostRun.userId,
      elo: ghostRun.elo,
      questionIds: ghostRun.questionIds,
      answers: ghostRun.answers.map((a) => GhostAnswerModel.fromDomain(a)).toList(),
      createdAt: ghostRun.createdAt,
    );
  }

  /// Create from a completed game's answers
  factory GhostRunModel.fromGameSession({
    required String id,
    required String userId,
    required int elo,
    required List<String> questionIds,
    required List<Answer> playerAnswers,
  }) {
    return GhostRunModel(
      id: id,
      userId: userId,
      elo: elo,
      questionIds: questionIds,
      answers: playerAnswers.map((a) => GhostAnswerModel(
        questionIndex: a.questionIndex,
        isCorrect: a.isCorrect,
        timeMs: a.timeMs,
      )).toList(),
      createdAt: DateTime.now(),
    );
  }
}

/// Ghost answer model
class GhostAnswerModel {
  final int questionIndex;
  final bool isCorrect;
  final int timeMs;

  const GhostAnswerModel({
    required this.questionIndex,
    required this.isCorrect,
    required this.timeMs,
  });

  factory GhostAnswerModel.fromJson(Map<String, dynamic> json) {
    return GhostAnswerModel(
      questionIndex: json['questionIndex'] as int? ?? 0,
      isCorrect: json['isCorrect'] as bool? ?? false,
      timeMs: json['timeMs'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionIndex': questionIndex,
      'isCorrect': isCorrect,
      'timeMs': timeMs,
    };
  }

  GhostAnswer toDomain() {
    return GhostAnswer(
      questionIndex: questionIndex,
      isCorrect: isCorrect,
      timeMs: timeMs,
    );
  }

  factory GhostAnswerModel.fromDomain(GhostAnswer answer) {
    return GhostAnswerModel(
      questionIndex: answer.questionIndex,
      isCorrect: answer.isCorrect,
      timeMs: answer.timeMs,
    );
  }
}