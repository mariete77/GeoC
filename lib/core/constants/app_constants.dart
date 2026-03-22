/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'GeoQuiz Battle';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String matchesCollection = 'matches';
  static const String questionsCollection = 'questions';
  static const String ghostRunsCollection = 'ghostRuns';

  // Firebase Realtime Database
  static const String matchmakingQueue = 'matchmaking/queue';

  // Storage Paths
  static const String silhouettesPath = 'silhouettes';
  static const String flagsPath = 'flags';
  static const String citiesPath = 'cities';
  static const String avatarsPath = 'avatars';

  // Deep Links
  static const String deepLinkScheme = 'geoquizbattle';
  static const String deepLinkHost = 'open';
}
