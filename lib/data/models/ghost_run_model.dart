import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/entities/match.dart';

part 'ghost_run_model.freezed.dart';
part 'ghost_run_model.g.dart';

@freezed
class GhostRunModel with _$GhostRunModel {
  const factory GhostRunModel({
    required String userId,
    required String ghostRunId,
    required int elo,
    required List<String> questionIds,
    required List<GhostAnswerModel> answers,
    required DateTime createdAt,
  }) = _GhostRunModel;

  factory GhostRunModel.fromJson(Map<String, dynamic> json) =>
      _$GhostRunModelFromJson(json);

  factory GhostRunModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GhostRunModel.fromJson({
      ...data,
      'createdAt': data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
          : DateTime.now().toIso8601String(),
    });
  }

  /// Convert to domain entity
  GhostRun toDomain() {
    return GhostRun(
      userId: userId,
      ghostRunId: ghostRunId,
      elo: elo,
      questionIds: questionIds,
      answers: answers.map((a) => a.toDomain()).toList(),
      createdAt: createdAt,
    );
  }

  /// Convert from domain entity
  factory GhostRunModel.fromDomain(GhostRun ghostRun) {
    return GhostRunModel(
      userId: ghostRun.userId,
      ghostRunId: ghostRun.ghostRunId,
      elo: ghostRun.elo,
      questionIds: ghostRun.questionIds,
      answers: ghostRun.answers
          .map((a) => GhostAnswerModel.fromDomain(a))
          .toList(),
      createdAt: ghostRun.createdAt,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    return json;
  }
}

@freezed
class GhostAnswerModel with _$GhostAnswerModel {
  const factory GhostAnswerModel({
    required int questionIndex,
    required bool isCorrect,
    required int timeMs,
  }) = _GhostAnswerModel;

  factory GhostAnswerModel.fromJson(Map<String, dynamic> json) =>
      _$GhostAnswerModelFromJson(json);

  /// Convert to domain entity
  GhostAnswer toDomain() {
    return GhostAnswer(
      questionIndex: questionIndex,
      isCorrect: isCorrect,
      timeMs: timeMs,
    );
  }

  /// Convert from domain entity
  factory GhostAnswerModel.fromDomain(GhostAnswer ghostAnswer) {
    return GhostAnswerModel(
      questionIndex: ghostAnswer.questionIndex,
      isCorrect: ghostAnswer.isCorrect,
      timeMs: ghostAnswer.timeMs,
    );
  }
}