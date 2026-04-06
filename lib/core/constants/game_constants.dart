/// Game-specific constants
class GameConstants {
  // Match Settings
  static const int questionsPerMatch = 10;
  static const int secondsPerQuestion = 10;
  static const int millisecondsPerQuestion = 10000;
  static const int matchDurationSeconds = 100; // 10 questions * 10 seconds

  // Daily Game Limits
  static const int freeCasualGamesPerDay = 1;
  static const int freeRankedGamesPerDay = 1;
  static const int premiumRankedGamesPerDay = 5;

  // ELO Settings
  static const int initialElo = 1000;
  static const int minElo = 100;
  static const int kFactorNew = 32;
  static const int kFactorEstablished = 16;
  static const int newPlayerThreshold = 30; // games
  static const int matchmakingEloRange = 200;

  // Matchmaking
  static const int matchmakingTimeoutMs = 60000; // 60 seconds
  static const int matchmakingCleanupIntervalMs = 60000; // 1 minute

  // Ghost Runs
  static const int maxGhostRunsPerUser = 5;
  static const int ghostRunEloRange = 200;

  // Question Types
  static const int totalQuestionTypes = 7; // silhouette, flag, capital, population, river, cityPhoto, area
  static const int optionsPerQuestion = 4;

  // Answer Scoring
  static const int baseScorePerCorrectAnswer = 100; // Base points for correct answer
  static const int timeBonusMultiplier = 10; // Points per second remaining
  static const int streakBonusMultiplier = 50; // Points per streak level
  static const int maxPointsPerMatch = 1000; // 10 questions * (100 + max time + max streak)

  // Transitions
  static const int answeredDelayCorrectMs = 1000; // Delay after correct answer
  static const int answeredDelayIncorrectMs = 2000; // Delay after incorrect answer
  static const int answeredDelayTimeoutMs = 1500; // Delay after timeout

  // Ranks (ELO ranges)
  static const int rankBronze = 0;
  static const int rankSilver = 1200;
  static const int rankGold = 1400;
  static const int rankPlatinum = 1600;
  static const int rankDiamond = 1800;

  // Subscription
  static const String subscriptionTypePremium = 'premium';
  static const String subscriptionTypeFree = 'free';
  static const String entitlementPremium = 'premium';
}
