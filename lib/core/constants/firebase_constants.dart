/// Firebase collection and document names
class FirebaseConstants {
  // Firestore Collections
  static const String users = 'users';
  static const String matches = 'matches';
  static const String questions = 'questions';
  static const String ghostRuns = 'ghostRuns';
  static const String questionReports = 'questionReports';

  // Firestore Fields - Users
  static const String userId = 'userId';
  static const String displayName = 'displayName';
  static const String email = 'email';
  static const String photoUrl = 'photoUrl';
  static const String elo = 'elo';
  static const String stats = 'stats';
  static const String subscription = 'subscription';
  static const String dailyGames = 'dailyGames';
  static const String createdAt = 'createdAt';
  static const String lastLoginAt = 'lastLoginAt';

  // Firestore Fields - Matches
  static const String players = 'players';
  static const String mode = 'mode';
  static const String matchType = 'type';
  static const String status = 'status';
  static const String questionIds = 'questionIds';
  static const String answers = 'answers';
  static const String result = 'result';
  static const String startedAt = 'startedAt';
  static const String finishedAt = 'finishedAt';

  // Firestore Fields - Questions
  static const String questionType = 'type';
  static const String difficulty = 'difficulty';
  static const String correctAnswer = 'correctAnswer';
  static const String options = 'options';
  static const String imageUrl = 'imageUrl';
  static const String questionText = 'questionText';
  static const String extraData = 'extraData';

  // Firestore Fields - Ghost Runs
  static const String ghostUserId = 'userId';
  static const String ghostAnswers = 'answers';

  // Realtime Database Paths
  static const String matchmakingQueue = 'matchmaking/queue';
}
