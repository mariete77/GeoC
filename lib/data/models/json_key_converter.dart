import 'package:json_annotation/json_annotation.dart';
import 'package:geoquiz_battle/domain/entities/match.dart';
import 'package:geoquiz_battle/domain/entities/question.dart';

/// Converter for MatchMode enum
class MatchModeConverter implements JsonConverter<MatchMode, String> {
  const MatchModeConverter();

  @override
  MatchMode fromJson(String json) {
    return MatchMode.values.firstWhere(
      (e) => e.name == json,
      orElse: () => MatchMode.realtime,
    );
  }

  @override
  String toJson(MatchMode object) {
    return object.name;
  }
}

/// Converter for MatchType enum
class MatchTypeConverter implements JsonConverter<MatchType, String> {
  const MatchTypeConverter();

  @override
  MatchType fromJson(String json) {
    return MatchType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => MatchType.casual,
    );
  }

  @override
  String toJson(MatchType object) {
    return object.name;
  }
}

/// Converter for MatchStatus enum
class MatchStatusConverter implements JsonConverter<MatchStatus, String> {
  const MatchStatusConverter();

  @override
  MatchStatus fromJson(String json) {
    return MatchStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () => MatchStatus.waiting,
    );
  }

  @override
  String toJson(MatchStatus object) {
    return object.name;
  }
}

/// Converter for QuestionType enum
class QuestionTypeConverter implements JsonConverter<QuestionType, String> {
  const QuestionTypeConverter();

  @override
  QuestionType fromJson(String json) {
    return QuestionType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => QuestionType.flag,
    );
  }

  @override
  String toJson(QuestionType object) {
    return object.name;
  }
}

/// Converter for Difficulty enum
class DifficultyConverter implements JsonConverter<Difficulty, String> {
  const DifficultyConverter();

  @override
  Difficulty fromJson(String json) {
    return Difficulty.values.firstWhere(
      (e) => e.name == json,
      orElse: () => Difficulty.medium,
    );
  }

  @override
  String toJson(Difficulty object) {
    return object.name;
  }
}