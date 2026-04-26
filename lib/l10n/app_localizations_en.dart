// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GeoQuiz Battle';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get goHome => 'Go Home';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get explorer => 'EXPLORER';

  @override
  String streak(int count) {
    return 'Streak: $count';
  }

  @override
  String get globalRanking => 'GLOBAL RANKING';

  @override
  String get eloScore => 'ELO Score';

  @override
  String get quickPlay => 'Quick Play';

  @override
  String get quickPlayDesc => 'Jump into an instant casual match.';

  @override
  String get ranked => 'Ranked';

  @override
  String get rankedDesc => 'Compete for ELO and climb the global ranking.';

  @override
  String get multiplayer => 'Multiplayer';

  @override
  String get multiplayerDesc => 'Challenge other players in real-time.';

  @override
  String get ghostRun => 'Ghost Run';

  @override
  String get ghostRunDesc => 'Practice against the best past matches.';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get leaderboardDesc => 'See your position compared to other players.';

  @override
  String get leaderboardLoading => 'Loading leaderboard...';

  @override
  String get leaderboardError => 'Error loading leaderboard';

  @override
  String get noPlayers => 'No players yet';

  @override
  String get yourPosition => 'YOUR POSITION';

  @override
  String get elo => 'ELO';

  @override
  String get you => 'You';

  @override
  String get history => 'History';

  @override
  String get matchHistory => 'Match History';

  @override
  String get matchHistoryDesc => 'Review your past battles.';

  @override
  String get seeAll => 'See all';

  @override
  String get noMatchesYet => 'No matches yet';

  @override
  String get noMatchesHint => 'Play your first match to see your history.';

  @override
  String get victories => 'Victories';

  @override
  String get defeats => 'Defeats';

  @override
  String get winRate => 'Win Rate';

  @override
  String get eloChange => 'ELO';

  @override
  String get victory => 'Victory!';

  @override
  String get defeat => 'Defeat';

  @override
  String get draw => 'Draw';

  @override
  String get matchHistoryTitle => 'Match History';

  @override
  String get all => 'All';

  @override
  String get casual => 'Casual';

  @override
  String get rankedFilter => 'Ranked';

  @override
  String get youVs => 'You vs';

  @override
  String get eloChangeLabel => 'ELO';

  @override
  String get noMatchesFilter => 'No matches with this filter';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get matchmakingTitle => 'Finding match...';

  @override
  String get matchmakingSearching => 'Searching for opponent...';

  @override
  String get matchmakingCancel => 'Cancel';

  @override
  String get matchmakingFound => 'Opponent found!';

  @override
  String get loginWelcome => 'Welcome to GeoC';

  @override
  String get loginSubtitle => 'Show off your geography knowledge';

  @override
  String get loginGoogle => 'Sign in with Google';

  @override
  String get loginApple => 'Sign in with Apple';

  @override
  String get loginAnonymous => 'Continue without account';

  @override
  String get gameNext => 'Next';

  @override
  String get gameFinish => 'Finish';

  @override
  String get gameResults => 'Results';

  @override
  String gamePoints(int points) {
    return '$points points';
  }

  @override
  String get gameCorrect => 'Correct!';

  @override
  String get gameIncorrect => 'Incorrect';

  @override
  String gameTimeLeft(int seconds) {
    return '${seconds}s';
  }

  @override
  String get typeYourAnswer => 'Type your answer...';

  @override
  String get submitAnswer => 'Submit';

  @override
  String get reportQuestion => 'Report question';

  @override
  String get reportReason => 'Report reason';

  @override
  String get reportSubmitted => 'Report submitted. Thanks!';

  @override
  String get friends => 'Friends';

  @override
  String get addFriend => 'Add friend';

  @override
  String get noFriends => 'You don\'t have friends yet';

  @override
  String get noFriendsHint => 'Add friends to compete against them.';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }
}
