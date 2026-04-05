import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'json_key_converter.dart';
import 'package:geoquiz_battle/domain/entities/match.dart';

part 'match_model.freezed.dart';
part 'match_model.g.dart';

@freezed
class MatchModel with _$MatchModel {
  const MatchModel._();

  const factory MatchModel({
    required String id,
    required List<String> players,
    @MatchModeConverter() required MatchMode mode,
    @MatchTypeConverter() required MatchType type,
    @MatchStatusConverter() required MatchStatus status,
    required List<String> questionIds,
    @Default({}) Map<String, List<AnswerModel>> answers,
    MatchResultModel? result,
    required DateTime createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) = _MatchModel;

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
          : DateTime.now().toIso8601String(),
      'startedAt': data['startedAt'] != null
          ? (data['startedAt'] as Timestamp).toDate().toIso8601String()
          : null,
      'finishedAt': data['finishedAt'] != null
          ? (data['finishedAt'] as Timestamp).toDate().toIso8601String()
          : null,
    });
  }

  /// Convert to domain entity
  GameMatch toDomain() {
    return GameMatch(
      id: id,
      players: players,
      mode: mode,
      type: type,
      status: status,
      questionIds: questionIds,
      answers: answers.map((key, value) =>
          MapEntry(key, value.map((a) => a.toDomain()).toList())),
      result: result?.toDomain(),
      createdAt: createdAt,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );
  }

  /// Convert from domain entity
  factory MatchModel.fromDomain(GameMatch gameMatch) {
    return MatchModel(
      id: gameMatch.id,
      players: gameMatch.players,
      mode: gameMatch.mode,
      type: gameMatch.type,
      status: gameMatch.status,
      questionIds: gameMatch.questionIds,
      answers: gameMatch.answers.map((key, value) =>
          MapEntry(key, value.map((a) => AnswerModel.fromDomain(a)).toList())),
      result: gameMatch.result != null
          ? MatchResultModel.fromDomain(gameMatch.result!)
          : null,
      createdAt: gameMatch.createdAt,
      startedAt: gameMatch.startedAt,
      finishedAt: gameMatch.finishedAt,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }
}

@freezed
class AnswerModel with _$AnswerModel {
  const AnswerModel._();

  const factory AnswerModel({
    required int questionIndex,
    required String selectedAnswer,
    required bool isCorrect,
    required int timeMs,
    required DateTime answeredAt,
  }) = _AnswerModel;

  factory AnswerModel.fromJson(Map<String, dynamic> json) =>
      _$AnswerModelFromJson(json);

  /// Convert to domain entity
  Answer toDomain() {
    return Answer(
      questionIndex: questionIndex,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      timeMs: timeMs,
      answeredAt: answeredAt,
    );
  }

  /// Convert from domain entity
  factory AnswerModel.fromDomain(Answer answer) {
    return AnswerModel(
      questionIndex: answer.questionIndex,
      selectedAnswer: answer.selectedAnswer,
      isCorrect: answer.isCorrect,
      timeMs: answer.timeMs,
      answeredAt: answer.answeredAt,
    );
  }
}

@freezed
class MatchResultModel with _$MatchResultModel {
  const MatchResultModel._();

  const factory MatchResultModel({
    String? winnerId,
    required Map<String, int> scores,
    required Map<String, int> eloChanges,
    required Map<String, int> newElo,
  }) = _MatchResultModel;

  factory MatchResultModel.fromJson(Map<String, dynamic> json) =>
      _$MatchResultModelFromJson(json);

  /// Convert to domain entity
  MatchResult toDomain() {
    return MatchResult(
      winnerId: winnerId,
      scores: scores,
      eloChanges: eloChanges,
      newElo: newElo,
    );
  }

  /// Convert from domain entity
  factory MatchResultModel.fromDomain(MatchResult result) {
    return MatchResultModel(
      winnerId: result.winnerId,
      scores: result.scores,
      eloChanges: result.eloChanges,
      newElo: result.newElo,
    );
  }
}
