import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String oderId,
    required String displayName,
    String? email,
    String? photoUrl,
    @Default(1000) int elo,
    @Default(UserStatsModel()) UserStatsModel stats,
    @Default(SubscriptionModel()) SubscriptionModel subscription,
    @Default(DailyGamesModel()) DailyGamesModel dailyGames,
    required DateTime createdAt,
    DateTime? lastLoginAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({
      'userId': doc.id,
      ...data,
      'createdAt': data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
          : DateTime.now().toIso8601String(),
      'lastLoginAt': data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate().toIso8601String()
          : null,
    });
  }

  /// Convert to domain entity
  User toDomain() {
    return User(
      userId: userId,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      elo: elo,
      stats: UserStats(
        totalGames: stats.totalGames,
        wins: stats.wins,
        losses: stats.losses,
        draws: stats.draws,
        totalCorrectAnswers: stats.totalCorrectAnswers,
        currentWinStreak: stats.currentWinStreak,
        bestWinStreak: stats.bestWinStreak,
      ),
      subscription: Subscription(
        type: subscription.type,
        expiresAt: subscription.expiresAt,
        isActive: subscription.isActive,
      ),
      dailyGames: DailyGames(
        casualPlayed: dailyGames.casualPlayed,
        rankedPlayed: dailyGames.rankedPlayed,
        date: dailyGames.date,
      ),
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  /// Convert from domain entity
  factory UserModel.fromDomain(User user) {
    return UserModel(
      userId: user.userId,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoUrl,
      elo: user.elo,
      stats: UserStatsModel(
        totalGames: user.stats.totalGames,
        wins: user.stats.wins,
        losses: user.stats.losses,
        draws: user.stats.draws,
        totalCorrectAnswers: user.stats.totalCorrectAnswers,
        currentWinStreak: user.stats.currentWinStreak,
        bestWinStreak: user.stats.bestWinStreak,
      ),
      subscription: SubscriptionModel(
        type: user.subscription.type,
        expiresAt: user.subscription.expiresAt,
        isActive: user.subscription.isActive,
      ),
      dailyGames: DailyGamesModel(
        casualPlayed: user.dailyGames.casualPlayed,
        rankedPlayed: user.dailyGames.rankedPlayed,
        date: user.dailyGames.date,
      ),
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    return json..remove('oderId');
  }
}

@freezed
class UserStatsModel with _$UserStatsModel {
  const factory UserStatsModel({
    @Default(0) int totalGames,
    @Default(0) int wins,
    @Default(0) int losses,
    @Default(0) int draws,
    @Default(0) int totalCorrectAnswers,
    @Default(0) int currentWinStreak,
    @Default(0) int bestWinStreak,
  }) = _UserStatsModel;

  factory UserStatsModel.fromJson(Map<String, dynamic> json) =>
      _$UserStatsModelFromJson(json);
}

@freezed
class SubscriptionModel with _$SubscriptionModel {
  const factory SubscriptionModel({
    @Default('free') String type,
    DateTime? expiresAt,
    @Default(false) bool isActive,
  }) = _SubscriptionModel;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);
}

@freezed
class DailyGamesModel with _$DailyGamesModel {
  const factory DailyGamesModel({
    @Default(0) int casualPlayed,
    @Default(0) int rankedPlayed,
    required DateTime date,
  }) = _DailyGamesModel;

  factory DailyGamesModel.fromJson(Map<String, dynamic> json) =>
      _$DailyGamesModelFromJson(json);

  factory DailyGamesModel.today() => DailyGamesModel(
        date: DateTime.now(),
      );
}
