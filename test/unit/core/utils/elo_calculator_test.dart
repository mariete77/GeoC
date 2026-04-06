import 'package:flutter_test/flutter_test.dart';
import 'package:geoquiz_battle/core/utils/elo_calculator.dart';
import 'package:geoquiz_battle/core/constants/game_constants.dart';

void main() {
  group('ELO Calculator', () {
    late EloCalculator calculator;

    setUp(() {
      calculator = EloCalculator();
    });

    group('calculateNewElo', () {
      test('returns initial ELO when no change', () {
        final newElo = calculator.calculateNewElo(
          playerElo: 1000,
          opponentElo: 1000,
          score: 0.5,
          gamesPlayed: 10,
        );
        expect(newElo, 1000);
      });

      test('increases ELO when player wins', () {
        final newElo = calculator.calculateNewElo(
          playerElo: 1000,
          opponentElo: 900,
          score: 1.0,
          gamesPlayed: 10,
        );
        expect(newElo, greaterThan(1000));
      });

      test('decreases ELO when player loses', () {
        final newElo = calculator.calculateNewElo(
          playerElo: 1000,
          opponentElo: 1100,
          score: 0.0,
          gamesPlayed: 10,
        );
        expect(newElo, lessThan(1000));
      });

      test('clamps ELO to minimum value', () {
        final newElo = calculator.calculateNewElo(
          playerElo: 150,
          opponentElo: 2000,
          score: 0.0,
          gamesPlayed: 50,
        );
        expect(newElo, GameConstants.minElo);
      });

      test('new players have larger ELO changes (K-factor 32)', () {
        final newPlayerChange = calculator.calculateChange(
          playerElo: 1000,
          opponentElo: 1000,
          score: 1.0,
          gamesPlayed: 5, // New player
        );

        final establishedChange = calculator.calculateChange(
          playerElo: 1000,
          opponentElo: 1000,
          score: 1.0,
          gamesPlayed: 50, // Established player
        );

        expect(newPlayerChange.abs(), greaterThan(establishedChange.abs()));
      });
    });

    group('calculateChange', () {
      test('returns positive change when player beats higher ELO opponent', () {
        final change = calculator.calculateChange(
          playerElo: 1000,
          opponentElo: 1200,
          score: 1.0,
          gamesPlayed: 30,
        );
        expect(change, greaterThan(0));
      });

      test('returns smaller positive change when player beats lower ELO opponent',
          () {
        final change1 = calculator.calculateChange(
          playerElo: 1000,
          opponentElo: 800,
          score: 1.0,
          gamesPlayed: 30,
        );

        final change2 = calculator.calculateChange(
          playerElo: 1000,
          opponentElo: 1200,
          score: 1.0,
          gamesPlayed: 30,
        );

        expect(change1.abs(), lessThan(change2.abs()));
      });

      test('calculates change correctly for draw (0.5 score)', () {
        final change = calculator.calculateChange(
          playerElo: 1000,
          opponentElo: 1200,
          score: 0.5,
          gamesPlayed: 30,
        );
        // For a draw vs higher ELO, player should gain some ELO
        expect(change, greaterThan(0));
      });

      test('respects K-factor for new players', () {
        final newPlayerChange = calculator.calculateChange(
          playerElo: 1000,
          opponentElo: 1000,
          score: 1.0,
          gamesPlayed: 5, // New player (K=32)
        );

        final establishedChange = calculator.calculateChange(
          playerElo: 1000,
          opponentElo: 1000,
          score: 1.0,
          gamesPlayed: 50, // Established player (K=16)
        );

        // New player should get 2x the change
        expect((newPlayerChange / 2).round(), establishedChange);
      });
    });

    group('_expectedScore', () {
      test('returns 0.5 for equal ELO players', () {
        // Using reflection to access private method for testing
        // In production, this would be refactored to public
        final calculator = EloCalculator();
        // We can't directly test private method, but we can verify through calculateChange
        final change = calculator.calculateChange(
          playerElo: 1000,
          opponentElo: 1000,
          score: 0.5,
          gamesPlayed: 30,
        );
        expect(change, 0);
      });

      test('expects lower score for player vs higher ELO opponent', () {
        final change = calculator.calculateChange(
          playerElo: 1000,
          opponentElo: 1200,
          score: 1.0,
          gamesPlayed: 30,
        );
        // Player beating higher ELO should gain more than beating equal ELO
        expect(change, greaterThan(8)); // More than the minimum gain
      });

      test('expects higher score for player vs lower ELO opponent', () {
        final change = calculator.calculateChange(
          playerElo: 1000,
          opponentElo: 800,
          score: 1.0,
          gamesPlayed: 30,
        );
        // Player beating lower ELO should gain less than beating equal ELO
        expect(change, lessThan(16)); // Less than the base gain for equal ELO
      });
    });

    group('determineWinner', () {
      test('player 1 wins when they have more correct answers', () {
        final outcome = calculator.determineWinner(
          player1Correct: 7,
          player2Correct: 5,
          player1TotalTime: 50000,
          player2TotalTime: 40000,
        );
        expect(outcome, MatchOutcome.player1Wins);
      });

      test('player 2 wins when they have more correct answers', () {
        final outcome = calculator.determineWinner(
          player1Correct: 5,
          player2Correct: 7,
          player1TotalTime: 40000,
          player2TotalTime: 50000,
        );
        expect(outcome, MatchOutcome.player2Wins);
      });

      test('player 1 wins on tie when they have less total time', () {
        final outcome = calculator.determineWinner(
          player1Correct: 6,
          player2Correct: 6,
          player1TotalTime: 45000,
          player2TotalTime: 55000,
        );
        expect(outcome, MatchOutcome.player1Wins);
      });

      test('player 2 wins on tie when they have less total time', () {
        final outcome = calculator.determineWinner(
          player1Correct: 6,
          player2Correct: 6,
          player1TotalTime: 55000,
          player2TotalTime: 45000,
        );
        expect(outcome, MatchOutcome.player2Wins);
      });

      test('draw when both have equal correct answers and time', () {
        final outcome = calculator.determineWinner(
          player1Correct: 6,
          player2Correct: 6,
          player1TotalTime: 50000,
          player2TotalTime: 50000,
        );
        expect(outcome, MatchOutcome.draw);
      });
    });

    group('getRank', () {
      test('returns Diamond for high ELO', () {
        expect(calculator.getRank(1900), 'Diamond');
        expect(calculator.getRank(1800), 'Diamond');
      });

      test('returns Platinum for medium-high ELO', () {
        expect(calculator.getRank(1700), 'Platinum');
        expect(calculator.getRank(1600), 'Platinum');
      });

      test('returns Gold for medium ELO', () {
        expect(calculator.getRank(1500), 'Gold');
        expect(calculator.getRank(1400), 'Gold');
      });

      test('returns Silver for medium-low ELO', () {
        expect(calculator.getRank(1300), 'Silver');
        expect(calculator.getRank(1200), 'Silver');
      });

      test('returns Bronze for low ELO', () {
        expect(calculator.getRank(1100), 'Bronze');
        expect(calculator.getRank(1000), 'Bronze');
        expect(calculator.getRank(500), 'Bronze');
      });

      test('handles edge cases', () {
        expect(calculator.getRank(GameConstants.minElo), 'Bronze');
        expect(calculator.getRank(1199), 'Bronze');
        expect(calculator.getRank(1200), 'Silver');
      });
    });

    group('getRankColor', () {
      test('returns correct color for Diamond', () {
        expect(calculator.getRankColor(1900), 0xFFB9F2FF);
        expect(calculator.getRankColor(1800), 0xFFB9F2FF);
      });

      test('returns correct color for Platinum', () {
        expect(calculator.getRankColor(1700), 0xFFE5E4E2);
        expect(calculator.getRankColor(1600), 0xFFE5E4E2);
      });

      test('returns correct color for Gold', () {
        expect(calculator.getRankColor(1500), 0xFFFFD700);
        expect(calculator.getRankColor(1400), 0xFFFFD700);
      });

      test('returns correct color for Silver', () {
        expect(calculator.getRankColor(1300), 0xFFC0C0C0);
        expect(calculator.getRankColor(1200), 0xFFC0C0C0);
      });

      test('returns correct color for Bronze', () {
        expect(calculator.getRankColor(1100), 0xFFCD7F32);
        expect(calculator.getRankColor(1000), 0xFFCD7F32);
        expect(calculator.getRankColor(500), 0xFFCD7F32);
      });
    });
  });
}