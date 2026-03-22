import '../constants/game_constants.dart';
import 'dart:math';

/// ELO Calculator for ranked games
class EloCalculator {
  /// Calculate new ELO after a match
  ///
  /// [playerElo] - Player's current ELO
  /// [opponentElo] - Opponent's ELO
  /// [score] - Result (0.0 to 1.0, where 1.0 = all correct answers)
  /// [gamesPlayed] - Total games played by the player
  int calculateNewElo({
    required int playerElo,
    required int opponentElo,
    required double score,
    required int gamesPlayed,
  }) {
    final change = calculateChange(
      playerElo: playerElo,
      opponentElo: opponentElo,
      score: score,
      gamesPlayed: gamesPlayed,
    );

    return (playerElo + change).clamp(GameConstants.minElo, 9999);
  }

  /// Calculate ELO change (positive or negative)
  int calculateChange({
    required int playerElo,
    required int opponentElo,
    required double score,
    required int gamesPlayed,
  }) {
    // K-factor: higher for new players
    final k = gamesPlayed < GameConstants.newPlayerThreshold
        ? GameConstants.kFactorNew
        : GameConstants.kFactorEstablished;

    // Expected score based on ELO difference
    final expected = _expectedScore(playerElo, opponentElo);

    // ELO change
    final change = k * (score - expected);

    return change.round();
  }

  /// Expected score based on ELO difference
  double _expectedScore(int playerElo, int opponentElo) {
    return 1.0 / (1.0 + pow(10, (opponentElo - playerElo) / 400.0));
  }

  /// Determine winner based on correct answers and time
  MatchOutcome determineWinner({
    required int player1Correct,
    required int player2Correct,
    required int player1TotalTime,
    required int player2TotalTime,
  }) {
    if (player1Correct > player2Correct) {
      return MatchOutcome.player1Wins;
    } else if (player2Correct > player1Correct) {
      return MatchOutcome.player2Wins;
    }

    // Tie in correct answers - decide by total time
    if (player1TotalTime < player2TotalTime) {
      return MatchOutcome.player1Wins;
    } else if (player2TotalTime < player1TotalTime) {
      return MatchOutcome.player2Wins;
    }

    return MatchOutcome.draw;
  }

  /// Get rank based on ELO
  String getRank(int elo) {
    if (elo >= GameConstants.rankDiamond) return 'Diamond';
    if (elo >= GameConstants.rankPlatinum) return 'Platinum';
    if (elo >= GameConstants.rankGold) return 'Gold';
    if (elo >= GameConstants.rankSilver) return 'Silver';
    return 'Bronze';
  }

  /// Get rank color based on ELO
  int getRankColor(int elo) {
    if (elo >= GameConstants.rankDiamond) return 0xFFB9F2FF;
    if (elo >= GameConstants.rankPlatinum) return 0xFFE5E4E2;
    if (elo >= GameConstants.rankGold) return 0xFFFFD700;
    if (elo >= GameConstants.rankSilver) return 0xFFC0C0C0;
    return 0xFFCD7F32;
  }
}

/// Match outcome enum
enum MatchOutcome { player1Wins, player2Wins, draw }
