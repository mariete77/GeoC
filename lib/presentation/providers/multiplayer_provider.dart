import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/match_repository_impl.dart';
import '../../data/repositories/ghost_run_repository_impl.dart';
import '../../data/repositories/question_repository_impl.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/match_repository.dart';
import '../../domain/repositories/ghost_run_repository.dart';
import '../../domain/repositories/question_repository.dart';
import '../../domain/repositories/quiz_attempt_repository.dart';
import '../../data/repositories/quiz_attempt_repository_impl.dart';
import '../../data/models/quiz_attempt_model.dart';
import '../../core/constants/game_constants.dart';
import '../../core/utils/score_calculator.dart';
import '../../core/utils/fuzzy_matcher.dart';
import '../../core/utils/elo_calculator.dart';
import '../../services/realtime_matchmaking_service.dart';
import 'match_history_provider.dart';
import 'invite_provider.dart';
import 'user_provider.dart';

/// Repository providers
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepositoryImpl();
});

final ghostRunRepositoryProvider = Provider<GhostRunRepository>((ref) {
  return GhostRunRepositoryImpl();
});

final questionRepositoryMultiProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepositoryImpl();
});

/// Quiz attempt repository provider for multiplayer
final quizAttemptRepositoryMultiProvider = Provider<QuizAttemptRepository>((ref) {
  return QuizAttemptRepositoryImpl();
});

final realtimeMatchmakingServiceProvider = Provider<RealtimeMatchmakingService>((ref) {
  return RealtimeMatchmakingService();
});

/// Multiplayer game mode
enum MultiplayerMode { casual, ranked, ghostRun, friendChallenge }

/// Multiplayer state
enum MultiplayerStatus {
  idle,
  searching,
  found,
  playing,
  finished,
  error,
}

/// Multiplayer game state
class MultiplayerState {
  final MultiplayerStatus status;
  final MultiplayerMode mode;
  final GameMatch? currentMatch;
  final GhostRun? ghostRun;
  final List<Question> questions;
  final int currentQuestionIndex;
  final int timeRemaining;
  final int playerScore;
  final int opponentScore;
  final List<Answer> playerAnswers;
  final int correctAnswers;
  final int streak;
  final String? errorMessage;
  final String? opponentName;
  final int? opponentElo;
  final int opponentCorrectAnswers;
  final List<Answer>? opponentAnswers;
  final int? eloChange;
  final int? newElo;
  final String? invitedFriendId;

  const MultiplayerState({
    this.status = MultiplayerStatus.idle,
    this.mode = MultiplayerMode.casual,
    this.currentMatch,
    this.ghostRun,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.timeRemaining = 0,
    this.playerScore = 0,
    this.opponentScore = 0,
    this.playerAnswers = const [],
    this.correctAnswers = 0,
    this.streak = 0,
    this.errorMessage,
    this.opponentName,
    this.opponentElo,
    this.opponentCorrectAnswers = 0,
    this.opponentAnswers,
    this.eloChange,
    this.newElo,
    this.invitedFriendId,
  });

  double calculatePerformanceScore() {
    double totalPerformance = 0.0;
    for (final answer in playerAnswers) {
      if (answer.isCorrect) {
        totalPerformance += 1.0;
        if (answer.timeMs < 2000) {
          totalPerformance += 0.5;
        } else if (answer.timeMs < 5000) {
          totalPerformance += 0.2;
        }
      }
    }
    return totalPerformance;
  }

  double? get opponentPerformanceScore {
    if (opponentAnswers == null) return null;
    
    double totalPerformance = 0.0;
    for (final answer in opponentAnswers!) {
      if (answer.isCorrect) {
        totalPerformance += 1.0;
        if (answer.timeMs < 2000) totalPerformance += 0.5;
        else if (answer.timeMs < 5000) totalPerformance += 0.2;
      }
    }
    return totalPerformance;
  }

  MultiplayerState copyWith({
    MultiplayerStatus? status,
    MultiplayerMode? mode,
    GameMatch? currentMatch,
    GhostRun? ghostRun,
    List<Question>? questions,
    int? currentQuestionIndex,
    int? timeRemaining,
    int? playerScore,
    int? opponentScore,
    List<Answer>? playerAnswers,
    int? correctAnswers,
    int? streak,
    String? errorMessage,
    String? opponentName,
    int? opponentElo,
    int? opponentCorrectAnswers,
    List<Answer>? opponentAnswers,
    int? eloChange,
    int? newElo,
    String? invitedFriendId,
  }) {
    return MultiplayerState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      currentMatch: currentMatch ?? this.currentMatch,
      ghostRun: ghostRun ?? this.ghostRun,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      playerScore: playerScore ?? this.playerScore,
      opponentScore: opponentScore ?? this.opponentScore,
      playerAnswers: playerAnswers ?? this.playerAnswers,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      streak: streak ?? this.streak,
      errorMessage: errorMessage ?? this.errorMessage,
      opponentName: opponentName ?? this.opponentName,
      opponentElo: opponentElo ?? this.opponentElo,
      opponentCorrectAnswers: opponentCorrectAnswers ?? this.opponentCorrectAnswers,
      opponentAnswers: opponentAnswers ?? this.opponentAnswers,
      eloChange: eloChange ?? this.eloChange,
      newElo: newElo ?? this.newElo,
      invitedFriendId: invitedFriendId ?? this.invitedFriendId,
    );
  }
}

/// Multiplayer game notifier
class MultiplayerNotifier extends StateNotifier<MultiplayerState> {
  final Ref _ref;
  Timer? _timer;
  Timer? _matchmakingTimer;
  Timer? _queuePollTimer;
  StreamSubscription? _matchSubscription;
  StreamSubscription? _rtdbMatchSubscription;
  StreamSubscription? _queueSubscription;
  StreamSubscription? _opponentStateSubscription;
  StreamSubscription? _inviteStatusSubscription;
  List<Question> _questions = [];
  String? _pendingRtdbMatchId;
  String? _pendingInviteId;
  String? _pendingInviteFriendId;

  MultiplayerNotifier(this._ref) : super(const MultiplayerState()) {
    _ref.onDispose(() {
      _timer?.cancel();
      _matchmakingTimer?.cancel();
      _queuePollTimer?.cancel();
      _matchSubscription?.cancel();
      _rtdbMatchSubscription?.cancel();
      _queueSubscription?.cancel();
      _opponentStateSubscription?.cancel();
      _inviteStatusSubscription?.cancel();
    });
  }

  /// Get current user ID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Start searching for a match
  Future<void> startMatchmaking(MultiplayerMode mode) async {
    if (_currentUserId == null) {
      state = state.copyWith(
        status: MultiplayerStatus.error,
        errorMessage: 'Not authenticated',
      );
      return;
    }

    state = state.copyWith(
      status: MultiplayerStatus.searching,
      mode: mode,
      errorMessage: null,
    );

    try {
      if (mode == MultiplayerMode.ghostRun) {
        await _startGhostRunMatch();
      } else {
        await _startPvPMatch(mode);
      }
    } catch (e) {
      state = state.copyWith(
        status: MultiplayerStatus.error,
        errorMessage: 'Failed to start matchmaking: $e',
      );
    }
  }

  /// Start a ghost run match (play against a previous player's answers)
  Future<void> _startGhostRunMatch() async {
    final userElo = _userElo;
    final result = await _ref.read(ghostRunRepositoryProvider).findGhostRun(
          userId: _currentUserId!,
          playerElo: userElo,
        );

    await result.fold(
      (failure) async {
        // No ghost run found - play solo and save as ghost run
        await _startSoloAndSaveGhost();
      },
      (ghostRun) async {
        if (ghostRun == null) {
          await _startSoloAndSaveGhost();
          return;
        }

        // Load the SAME questions the ghost played with
        final questionsResult = await _ref
            .read(questionRepositoryMultiProvider)
            .getQuestionsByIds(ghostRun.questionIds);

        await questionsResult.fold(
          (failure) async {
            // Fall back to solo
            await _startSoloAndSaveGhost();
          },
          (questions) async {
            if (questions.isEmpty) {
              await _startSoloAndSaveGhost();
              return;
            }

            _questions = questions;
            
            // Create a GameMatch to persist the async game in history
            final matchType = state.mode == MultiplayerMode.ranked ? MatchType.ranked : MatchType.casual;
            final fsMatch = GameMatch(
              id: '',
              players: [_currentUserId!, ghostRun.userId],
              mode: MatchMode.async,
              type: matchType,
              status: MatchStatus.active,
              questionIds: _questions.map((q) => q.id).toList(),
              answers: {},
              createdAt: DateTime.now(),
              startedAt: DateTime.now(),
              creatorElo: userElo,
            );

            GameMatch? createdMatch;
            final fsResult = await _ref.read(matchRepositoryProvider).createMatch(fsMatch);
            fsResult.fold(
              (_) {},
              (matchId) {
                createdMatch = fsMatch.copyWith(id: matchId);
              },
            );

            state = state.copyWith(
              status: MultiplayerStatus.found,
              currentMatch: createdMatch,
              ghostRun: ghostRun,
              opponentName: 'Ghost Runner',
              opponentElo: ghostRun.elo,
            );

            // Auto-start after short delay
            await Future.delayed(const Duration(seconds: 2));
            _startPlaying();
          },
        );
      },
    );
  }

  /// Start solo game and save as ghost run
  Future<void> _startSoloAndSaveGhost() async {
    final questionsResult = await _ref
        .read(questionRepositoryMultiProvider)
        .getRandomQuestions(count: GameConstants.questionsPerMatch);

    questionsResult.fold(
      (failure) {
        state = state.copyWith(
          status: MultiplayerStatus.error,
          errorMessage: 'Failed to load questions',
        );
      },
      (questions) async {
        _questions = questions;
        
        // Create a GameMatch to persist the solo game in history
        final matchType = state.mode == MultiplayerMode.ranked ? MatchType.ranked : MatchType.casual;
        final fsMatch = GameMatch(
          id: '',
          players: [_currentUserId!],
          mode: MatchMode.async,
          type: matchType,
          status: MatchStatus.active,
          questionIds: _questions.map((q) => q.id).toList(),
          answers: {},
          createdAt: DateTime.now(),
          startedAt: DateTime.now(),
          creatorElo: _userElo,
        );

        GameMatch? createdMatch;
        final fsResult = await _ref.read(matchRepositoryProvider).createMatch(fsMatch);
        fsResult.fold(
          (_) {},
          (matchId) {
            createdMatch = fsMatch.copyWith(id: matchId);
          },
        );

        state = state.copyWith(
          status: MultiplayerStatus.found,
          currentMatch: createdMatch,
          opponentName: 'Solo Practice',
        );

        Future.delayed(const Duration(seconds: 2), () {
          _startPlaying();
        });
      },
    );
  }

  /// Get current user ELO from user provider
  int get _userElo {
    final userState = _ref.read(userNotifierProvider);
    return userState.when(
      data: (user) => user?.elo ?? 1000,
      loading: () => 1000,
      error: (_, __) => 1000,
    );
  }

  /// Start a PvP match using Firebase Realtime Database for matchmaking.
  /// Uses `rtdb_matches` directly as the queue — no separate queue collection.
  Future<void> _startPvPMatch(MultiplayerMode mode) async {
    final modeStr = mode == MultiplayerMode.ranked ? 'ranked' : 'casual';
    final userId = _currentUserId!;
    final elo = _userElo;
    final rtdb = _ref.read(realtimeMatchmakingServiceProvider);

    final questions = await _generateQuestions();
    if (questions == null) {
      state = state.copyWith(
        status: MultiplayerStatus.error,
        errorMessage: 'No se pudieron cargar las preguntas',
      );
      return;
    }
    _questions = questions;

    final displayName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Jugador';

    // ── 1. Try to join an existing waiting match ─────
    print('[MM] Searching for waiting match (mode=$modeStr, user=$userId, elo=$elo)');
    final existing = await rtdb.findWaitingMatch(mode: modeStr, excludeUserId: userId, elo: elo);
    print('[MM] findWaitingMatch result: ${existing != null ? 'found ${existing.matchId}' : 'none'}');
    if (existing != null) {
      print('[MM] Attempting to join match ${existing.matchId}...');
      final joined = await rtdb.joinRtdbMatch(matchId: existing.matchId, userId: userId, displayName: displayName);
      print('[MM] joinRtdbMatch result: $joined');
      if (joined) {
        await _loadQuestionsFromRtdbMatch(existing.matchId);
        await _startGameWithOpponent(
          rtdbMatchId: existing.matchId,
          opponentId: existing.creatorId,
          opponentName: existing.creatorName ?? 'Oponente',
          opponentElo: existing.creatorElo,
        );
        return;
      }
    }

    // ── 2. Create own match ──────────────────────────
    final rtdbMatchId = await rtdb.createRtdbMatch(
      creatorId: userId,
      questionIds: questions.map((q) => q.id).toList(),
      mode: modeStr,
      creatorElo: elo,
      displayName: displayName,
    );
    print('[MM] Created own match: $rtdbMatchId');
    _pendingRtdbMatchId = rtdbMatchId;

    // ── 3. Watch own match for opponent joining ──────
    _rtdbMatchSubscription?.cancel();
    _rtdbMatchSubscription =
        rtdb.watchRtdbMatch(rtdbMatchId).listen((matchData) {
      print('[MM] Match update: status=${matchData?['status']}, player2=${matchData?['player2']}');
      if (matchData == null || state.status != MultiplayerStatus.searching) return;
      if (matchData['status'] == 'active' && matchData['player2'] != null) {
        final opponentId = matchData['player2'] as String;
        print('[MM] Opponent joined! id=$opponentId');
        _rtdbMatchSubscription?.cancel();
        _queuePollTimer?.cancel();
        _matchmakingTimer?.cancel();
        final opponentDisplayName = matchData['player2DisplayName'] as String? ?? 'Oponente';
        _startGameWithOpponent(
          rtdbMatchId: rtdbMatchId,
          opponentId: opponentId,
          opponentName: opponentDisplayName,
          opponentElo: null,
        );
      }
    });

    // ── 4. Poll rtdb_matches for other waiting matches ──
    _queuePollTimer?.cancel();
    _queuePollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (state.status != MultiplayerStatus.searching) return;
      try {
        final match = await rtdb.findWaitingMatch(mode: modeStr, excludeUserId: userId, elo: elo);
        if (match == null || match.matchId == rtdbMatchId) {
          if (match != null) print('[MM] Poll: skipped own match');
          else print('[MM] Poll: no waiting match found');
          return;
        }
        print('[MM] Poll: found match ${match.matchId} from ${match.creatorId}');
        final joined = await rtdb.joinRtdbMatch(
          matchId: match.matchId,
          userId: userId,
          displayName: displayName,
        );
        print('[MM] Poll: join result=$joined');
        if (!joined) return;
        _queuePollTimer?.cancel();
        _rtdbMatchSubscription?.cancel();
        _matchmakingTimer?.cancel();
        await rtdb.cancelRtdbMatch(rtdbMatchId);
        await _loadQuestionsFromRtdbMatch(match.matchId);
        await _startGameWithOpponent(
          rtdbMatchId: match.matchId,
          opponentId: match.creatorId,
          opponentName: match.creatorName ?? 'Oponente',
          opponentElo: match.creatorElo,
        );
      } catch (e) {
        print('[MM] Poll error: $e');
      }
    });

    // ── 5. Timeout → ghost run fallback ──────────────
    _matchmakingTimer = Timer(
      Duration(milliseconds: GameConstants.matchmakingTimeoutMs),
      () {
        if (state.status != MultiplayerStatus.searching) return;
        _rtdbMatchSubscription?.cancel();
        _queuePollTimer?.cancel();
        rtdb.cancelRtdbMatch(rtdbMatchId);
        _pendingRtdbMatchId = null;
        _fallbackToGhostRun();
      },
    );
  }

  /// Loads the question IDs stored in an RTDB match and fetches them from Firestore.
  /// Overwrites _questions so both players share the creator's question set.
  Future<void> _loadQuestionsFromRtdbMatch(String rtdbMatchId) async {
    final snapshot =
        await FirebaseDatabase.instance.ref('rtdb_matches/$rtdbMatchId').get();
    if (!snapshot.exists || snapshot.value == null) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final ids = List<String>.from(data['questionIds'] ?? []);
    if (ids.isEmpty) return;

    final loaded = await _loadQuestionsByIds(ids);
    if (loaded != null && loaded.isNotEmpty) _questions = loaded;
  }

  /// Creates a Firestore match record (for persistence + ELO history),
  /// then transitions state to 'found' and starts the game after a short delay.
  Future<void> _startGameWithOpponent({
    required String rtdbMatchId,
    required String opponentId,
    required String opponentName,
    required int? opponentElo,
  }) async {
    _pendingRtdbMatchId = rtdbMatchId;

    // Create Firestore match for persistence (ghost runs, history, ELO Cloud Fn)
    final matchType =
        state.mode == MultiplayerMode.ranked ? MatchType.ranked : MatchType.casual;
    final fsMatch = GameMatch(
      id: '',
      players: [_currentUserId!, opponentId],
      mode: MatchMode.async,
      type: matchType,
      status: MatchStatus.active,
      questionIds: _questions.map((q) => q.id).toList(),
      answers: {},
      createdAt: DateTime.now(),
      startedAt: DateTime.now(),
      creatorElo: _userElo,
    );

    GameMatch? createdMatch;
    final fsResult = await _ref.read(matchRepositoryProvider).createMatch(fsMatch);
    fsResult.fold(
      (_) {},
      (matchId) {
        createdMatch = GameMatch(
          id: matchId,
          players: fsMatch.players,
          mode: fsMatch.mode,
          type: fsMatch.type,
          status: fsMatch.status,
          questionIds: fsMatch.questionIds,
          answers: fsMatch.answers,
          createdAt: fsMatch.createdAt,
          startedAt: fsMatch.startedAt,
          creatorElo: fsMatch.creatorElo,
        );
      },
    );

    state = state.copyWith(
      status: MultiplayerStatus.found,
      currentMatch: createdMatch,
      opponentName: opponentName,
      opponentElo: opponentElo,
    );

    await Future.delayed(const Duration(seconds: 2));
    if (state.status != MultiplayerStatus.found) return;

    _startPlaying();
    _watchOpponentRtdbState(rtdbMatchId, opponentId);
  }

  /// Streams the opponent's live score from RTDB and updates state in real-time.
  void _watchOpponentRtdbState(String matchId, String opponentId) {
    _opponentStateSubscription?.cancel();
    _opponentStateSubscription = _ref
        .read(realtimeMatchmakingServiceProvider)
        .watchOpponentState(matchId: matchId, opponentId: opponentId)
        .listen((data) {
      if (data == null || state.status != MultiplayerStatus.playing) return;
      final score = data['score'] as int? ?? 0;
      if (score != state.opponentScore) {
        state = state.copyWith(opponentScore: score);
      }
    });
  }

  /// Pre-generate random questions for a new match
  Future<List<Question>?> _generateQuestions() async {
    final result = await _ref
        .read(questionRepositoryMultiProvider)
        .getRandomQuestions(count: GameConstants.questionsPerMatch);

    return result.fold(
      (failure) => null,
      (questions) => questions.isEmpty ? null : questions,
    );
  }

  /// Load questions by IDs (so both players share the same question set)
  Future<List<Question>?> _loadQuestionsByIds(List<String> questionIds) async {
    if (questionIds.isEmpty) return null;

    final result = await _ref
        .read(questionRepositoryMultiProvider)
        .getQuestionsByIds(questionIds);

    return result.fold(
      (failure) => null,
      (questions) => questions.isEmpty ? null : questions,
    );
  }

  /// Cancel matchmaking and clean up RTDB state.
  Future<void> cancelSearch() async {
    final rtdb = _ref.read(realtimeMatchmakingServiceProvider);
    final userId = _currentUserId;
    final modeStr = state.mode == MultiplayerMode.ranked ? 'ranked' : 'casual';

    _rtdbMatchSubscription?.cancel();
    _queueSubscription?.cancel();
    _matchmakingTimer?.cancel();
    _inviteStatusSubscription?.cancel();

    if (userId != null) {
      rtdb.leaveQueue(mode: modeStr, userId: userId).catchError((_) {});
    }
    if (_pendingRtdbMatchId != null) {
      rtdb.cancelRtdbMatch(_pendingRtdbMatchId!).catchError((_) {});
      _pendingRtdbMatchId = null;
    }
    if (_pendingInviteId != null && _pendingInviteFriendId != null) {
      rtdb.cancelInvite(_pendingInviteFriendId!, _pendingInviteId!).catchError((_) {});
      _pendingInviteId = null;
      _pendingInviteFriendId = null;
    }
    _reset();
  }

  /// Challenge a specific friend to a match
  /// Uses the friend's most recent ghost run if available, otherwise generates random questions
  /// Sends a real-time invite to a friend and waits for them to accept.
  Future<void> challengeFriend(
    String friendId, {
    String? friendName,
    int? friendElo,
  }) async {
    if (_currentUserId == null || friendId == _currentUserId) return;

    final userId = _currentUserId!;
    final displayName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Jugador';
    final rtdb = _ref.read(realtimeMatchmakingServiceProvider);

    state = state.copyWith(
      status: MultiplayerStatus.searching,
      mode: MultiplayerMode.friendChallenge,
      opponentName: friendName ?? 'Amigo',
      opponentElo: friendElo,
      errorMessage: null,
    );

    try {
      // Resolve friend info if not provided
      String name = friendName ?? 'Amigo';
      int opponentEloValue = friendElo ?? 1000;
      if (friendName == null || friendElo == null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .get();
        if (doc.exists) {
          name = doc.data()!['displayName'] as String? ?? name;
          opponentEloValue = doc.data()!['elo'] as int? ?? opponentEloValue;
        }
      }

      // Generate questions for the match
      final questions = await _generateQuestions();
      if (questions == null) {
        state = state.copyWith(
          status: MultiplayerStatus.error,
          errorMessage: 'No se pudieron cargar las preguntas',
        );
        return;
      }
      _questions = questions;

      // Create RTDB match (creator side)
      final rtdbMatchId = await rtdb.createRtdbMatch(
        creatorId: userId,
        questionIds: questions.map((q) => q.id).toList(),
        mode: 'friendChallenge',
      );
      _pendingRtdbMatchId = rtdbMatchId;

      // Send RTDB invite to friend
      final inviteId = await rtdb.sendInvite(
        toUserId: friendId,
        fromUserId: userId,
        fromDisplayName: displayName,
        fromElo: _userElo,
        rtdbMatchId: rtdbMatchId,
        questionIds: questions.map((q) => q.id).toList(),
      );
      _pendingInviteId = inviteId;
      _pendingInviteFriendId = friendId;

      // Watch RTDB match: fires when friend accepts and joins
      _rtdbMatchSubscription?.cancel();
      _rtdbMatchSubscription =
          rtdb.watchRtdbMatch(rtdbMatchId).listen((matchData) {
        if (matchData == null ||
            state.status != MultiplayerStatus.searching) return;
        if (matchData['status'] == 'active' &&
            matchData['player2'] != null) {
          _rtdbMatchSubscription?.cancel();
          _inviteStatusSubscription?.cancel();
          _matchmakingTimer?.cancel();
          _pendingInviteId = null;
          _pendingInviteFriendId = null;
          _startGameWithOpponent(
            rtdbMatchId: rtdbMatchId,
            opponentId: friendId,
            opponentName: name,
            opponentElo: opponentEloValue,
          );
        }
      });

      // Watch invite status: fires if friend rejects or invite expires
      _inviteStatusSubscription?.cancel();
      _inviteStatusSubscription =
          rtdb.watchInviteStatus(friendId, inviteId).listen((status) {
        if (status == null ||
            state.status != MultiplayerStatus.searching) return;
        if (status == 'rejected' || status == 'expired') {
          _rtdbMatchSubscription?.cancel();
          _inviteStatusSubscription?.cancel();
          _matchmakingTimer?.cancel();
          rtdb.cancelRtdbMatch(rtdbMatchId);
          _pendingRtdbMatchId = null;
          _pendingInviteId = null;
          _pendingInviteFriendId = null;
          state = state.copyWith(
            status: MultiplayerStatus.error,
            errorMessage: status == 'rejected'
                ? '$name rechazó el reto'
                : '$name no respondió al reto',
          );
        }
      });

      // Timeout after 60 s
      _matchmakingTimer = Timer(const Duration(seconds: 60), () {
        if (state.status != MultiplayerStatus.searching) return;
        _rtdbMatchSubscription?.cancel();
        _inviteStatusSubscription?.cancel();
        rtdb.cancelInvite(friendId, inviteId);
        rtdb.cancelRtdbMatch(rtdbMatchId);
        _pendingRtdbMatchId = null;
        _pendingInviteId = null;
        _pendingInviteFriendId = null;
        state = state.copyWith(
          status: MultiplayerStatus.error,
          errorMessage: '$name no respondió al reto',
        );
      });
    } catch (e) {
      state = state.copyWith(
        status: MultiplayerStatus.error,
        errorMessage: 'Error al crear reto: $e',
      );
    }
  }

  /// Called when the local user accepts an incoming friend invite.
  Future<void> joinFromInvite(InviteData invite) async {
    state = state.copyWith(
      status: MultiplayerStatus.searching,
      mode: MultiplayerMode.friendChallenge,
      opponentName: invite.fromDisplayName,
      opponentElo: invite.fromElo,
      errorMessage: null,
    );

    await _loadQuestionsFromRtdbMatch(invite.rtdbMatchId);

    if (_questions.isEmpty) {
      state = state.copyWith(
        status: MultiplayerStatus.error,
        errorMessage: 'No se pudieron cargar las preguntas del reto',
      );
      return;
    }

    await _startGameWithOpponent(
      rtdbMatchId: invite.rtdbMatchId,
      opponentId: invite.fromUserId,
      opponentName: invite.fromDisplayName,
      opponentElo: invite.fromElo,
    );
  }

  /// Start playing the match
  void _startPlaying() {
    if (_questions.isEmpty) {
      state = state.copyWith(
        status: MultiplayerStatus.error,
        errorMessage: 'No questions loaded',
      );
      return;
    }

    final secondsPerQuestion = _questions.first.options.isEmpty
        ? GameConstants.secondsPerTypeQuestion
        : GameConstants.secondsPerQuestion;

    state = state.copyWith(
      status: MultiplayerStatus.playing,
      questions: _questions,
      currentQuestionIndex: 0,
      timeRemaining: secondsPerQuestion,
      playerScore: 0,
      opponentScore: 0,
      playerAnswers: [],
      correctAnswers: 0,
      streak: 0,
    );

    _startTimer();
  }

  /// Start timer for current question
  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (state.status != MultiplayerStatus.playing) {
          timer.cancel();
          return;
        }

        if (state.timeRemaining <= 1) {
          timer.cancel();
          submitAnswer(selectedAnswer: '', isTimeout: true);
        } else {
          state = state.copyWith(timeRemaining: state.timeRemaining - 1);
        }
      },
    );
  }

  /// Submit answer for current question
  void submitAnswer({
    required String selectedAnswer,
    bool isTimeout = false,
  }) {
    if (state.status != MultiplayerStatus.playing) return;
    _timer?.cancel();

    final currentIndex = state.currentQuestionIndex;
    if (currentIndex >= _questions.length) return;

    final question = _questions[currentIndex];
    final isCorrect = !isTimeout && question.isCorrect(selectedAnswer);

    final questionScore = calculateQuestionScore(
      isCorrect: isCorrect,
      timeRemaining: state.timeRemaining,
      streak: state.streak,
      isTimeout: isTimeout,
    );

    final maxTime = question.options.isEmpty
        ? GameConstants.secondsPerTypeQuestion
        : GameConstants.secondsPerQuestion;

    final answer = Answer(
      questionIndex: currentIndex,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      timeMs: (maxTime - state.timeRemaining) * 1000,
      answeredAt: DateTime.now(),
    );

    // Track quiz attempt for analytics (fire and forget, don't block gameplay)
    _trackQuizAttempt(
      question: question,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      isTimeout: isTimeout,
      timeMs: answer.timeMs,
    );

    final updatedAnswers = [...state.playerAnswers, answer];
    final newScore = state.playerScore + questionScore;
    final newCorrect = isCorrect ? state.correctAnswers + 1 : state.correctAnswers;
    final newStreak = isCorrect ? state.streak + 1 : 0;

    // Calculate ghost opponent score
    int newOpponentScore = state.opponentScore;
    if (state.ghostRun != null && currentIndex < state.ghostRun!.answers.length) {
      final ghostAnswer = state.ghostRun!.answers[currentIndex];
      if (ghostAnswer.isCorrect) {
        newOpponentScore += calculateQuestionScore(
          isCorrect: true,
          timeRemaining: maxTime - (ghostAnswer.timeMs ~/ 1000),
          streak: 0,
          isTimeout: false,
        );
      }
    }

    // Move to next question or finish
    final nextIndex = currentIndex + 1;

    // Update state with answer result then transition
    state = state.copyWith(
      playerScore: newScore,
      opponentScore: newOpponentScore,
      playerAnswers: updatedAnswers,
      correctAnswers: newCorrect,
      streak: newStreak,
    );

    // Push live score to RTDB and submit answer to Firestore (PvP only)
    if (_pendingRtdbMatchId != null &&
        _currentUserId != null &&
        state.ghostRun == null) {
      _ref.read(realtimeMatchmakingServiceProvider).updateGameState(
        matchId: _pendingRtdbMatchId!,
        userId: _currentUserId!,
        score: newScore,
        currentQuestion: nextIndex,
        finished: nextIndex >= _questions.length,
      ).catchError((Object _) {});
      // Fire-and-forget: submit answer to Firestore so opponent can see it
      if (state.currentMatch != null) {
        _ref.read(matchRepositoryProvider).submitAnswer(
          state.currentMatch!.id,
          answer,
        );
      }
    }

    // Transition after delay
    final delayMs = isTimeout
        ? GameConstants.answeredDelayTimeoutMs
        : isCorrect
            ? GameConstants.answeredDelayCorrectMs
            : GameConstants.answeredDelayIncorrectMs;

    Future.delayed(Duration(milliseconds: delayMs), () {
      if (nextIndex >= _questions.length) {
        _finishMatch();
      } else {
        final nextQuestion = _questions[nextIndex];
        final seconds = nextQuestion.options.isEmpty
            ? GameConstants.secondsPerTypeQuestion
            : GameConstants.secondsPerQuestion;

        state = state.copyWith(
          currentQuestionIndex: nextIndex,
          timeRemaining: seconds,
        );
        _startTimer();
      }
    });
  }

  /// Track quiz attempt to Firestore for analytics in multiplayer mode
  /// This is a fire-and-forget operation that doesn't block gameplay
  void _trackQuizAttempt({
    required Question question,
    required String selectedAnswer,
    required bool isCorrect,
    required bool isTimeout,
    required int timeMs,
  }) {
    try {
      final attemptRepository = _ref.read(quizAttemptRepositoryMultiProvider);
      final auth = FirebaseAuth.instance;

      final matchModeStr = state.mode == MultiplayerMode.ranked
          ? 'ranked'
          : state.mode == MultiplayerMode.friendChallenge
              ? 'friend_challenge'
              : 'casual';

      final attempt = QuizAttemptModel(
        questionId: question.id,
        questionType: question.type.name,
        questionDifficulty: question.difficulty.name,
        correctAnswer: question.correctAnswer,
        userAnswer: selectedAnswer,
        isCorrect: isCorrect,
        isTimeout: isTimeout,
        timeMs: timeMs,
        matchId: state.currentMatch?.id ?? 'unknown',
        matchMode: state.currentMatch?.mode == MatchMode.realtime ? 'realtime' : 'async',
        matchType: matchModeStr,
        userId: auth.currentUser?.uid,
        userElo: _userElo,
        answeredAt: DateTime.now(),
        questionData: question.extraData,
      );

      // Record attempt asynchronously, don't await to avoid blocking gameplay
      attemptRepository.recordAttempt(attempt).then((_) {
        // Success - optionally log for debugging
      }).catchError((error) {
        // Log error but don't crash the game
        print('Failed to track quiz attempt: $error');
      });
    } catch (e) {
      // Catch all errors to prevent affecting gameplay
      print('Error tracking quiz attempt: $e');
    }
  }

  /// Submit typed answer
  void submitTypedAnswer({required String typedAnswer}) {
    if (state.status != MultiplayerStatus.playing) return;
    _timer?.cancel();

    final currentIndex = state.currentQuestionIndex;
    if (currentIndex >= _questions.length) return;

    final question = _questions[currentIndex];
    final similarity = answerSimilarity(typedAnswer, question.correctAnswer);
    final isCorrect = similarity >= 0.85;

    final maxTime = question.options.isEmpty
        ? GameConstants.secondsPerTypeQuestion
        : GameConstants.secondsPerQuestion;

    final questionScore = calculateTypedScore(
      similarity: similarity,
      timeRemaining: state.timeRemaining,
      maxTime: maxTime,
      streak: state.streak,
    );

    final answer = Answer(
      questionIndex: currentIndex,
      selectedAnswer: typedAnswer,
      isCorrect: isCorrect,
      timeMs: (maxTime - state.timeRemaining) * 1000,
      answeredAt: DateTime.now(),
    );

    final updatedAnswers = [...state.playerAnswers, answer];
    final newScore = state.playerScore + questionScore;
    final newCorrect = isCorrect ? state.correctAnswers + 1 : state.correctAnswers;
    final newStreak = isCorrect ? state.streak + 1 : 0;

    int newOpponentScore = state.opponentScore;
    if (state.ghostRun != null && currentIndex < state.ghostRun!.answers.length) {
      final ghostAnswer = state.ghostRun!.answers[currentIndex];
      if (ghostAnswer.isCorrect) {
        newOpponentScore += calculateQuestionScore(
          isCorrect: true,
          timeRemaining: maxTime - (ghostAnswer.timeMs ~/ 1000),
          streak: 0,
          isTimeout: false,
        );
      }
    }

    state = state.copyWith(
      playerScore: newScore,
      opponentScore: newOpponentScore,
      playerAnswers: updatedAnswers,
      correctAnswers: newCorrect,
      streak: newStreak,
    );

    final nextIndex = currentIndex + 1;

    // Push live score to RTDB (PvP only, fire-and-forget)
    if (_pendingRtdbMatchId != null &&
        _currentUserId != null &&
        state.ghostRun == null) {
      _ref.read(realtimeMatchmakingServiceProvider).updateGameState(
        matchId: _pendingRtdbMatchId!,
        userId: _currentUserId!,
        score: newScore,
        currentQuestion: nextIndex,
        finished: nextIndex >= _questions.length,
      ).catchError((_) {});
    }

    final delayMs = isCorrect
        ? GameConstants.answeredDelayCorrectMs
        : GameConstants.answeredDelayIncorrectMs;

    Future.delayed(Duration(milliseconds: delayMs), () {
      if (nextIndex >= _questions.length) {
        _finishMatch();
      } else {
        final nextQuestion = _questions[nextIndex];
        final seconds = nextQuestion.options.isEmpty
            ? GameConstants.secondsPerTypeQuestion
            : GameConstants.secondsPerQuestion;

        state = state.copyWith(
          currentQuestionIndex: nextIndex,
          timeRemaining: seconds,
        );
        _startTimer();
      }
    });
  }

  /// Finish the match
  Future<void> _finishMatch() async {
    try {
      _timer?.cancel();

      final currentMatch = state.currentMatch;
      final currentUserId = _currentUserId;

      // ── 1. Submit local answers and save ghost ────────────────
      if (currentUserId != null && state.playerAnswers.isNotEmpty) {
        _ref.read(ghostRunRepositoryProvider).saveGhostRun(
              userId: currentUserId,
              elo: _userElo,
              questionIds: _questions.map((q) => q.id).toList(),
              answers: state.playerAnswers,
            ).then((_) {});

        if (currentMatch != null) {
          for (final answer in state.playerAnswers) {
            await _ref.read(matchRepositoryProvider).submitAnswer(
                  currentMatch.id,
                  answer,
                );
          }
        }
      }

      // ── 2. Signal finished in RTDB and WAIT for opponent ──────
      if (_pendingRtdbMatchId != null && currentUserId != null && state.ghostRun == null) {
        await _ref.read(realtimeMatchmakingServiceProvider).updateGameState(
          matchId: _pendingRtdbMatchId!,
          userId: currentUserId!,
          score: state.playerScore,
          currentQuestion: _questions.length,
          finished: true,
        );

        // Wait for opponent to finish (up to 90s)
        final opponentId = currentMatch?.getOpponentId(currentUserId);
        if (opponentId != null && opponentId.isNotEmpty) {
          bool opponentDone = false;
          for (int retry = 0; retry < 180; retry++) {
            final oppState = await _ref.read(realtimeMatchmakingServiceProvider)
                .watchOpponentState(matchId: _pendingRtdbMatchId!, opponentId: opponentId)
                .first;
            if (oppState != null && oppState['finished'] == true && oppState['score'] != null) {
              state = state.copyWith(opponentScore: oppState['score'] as int? ?? 0);
              opponentDone = true;
              break;
            }
            await Future.delayed(const Duration(milliseconds: 500));
          }
          if (!opponentDone) {
            print('[finishMatch] opponent did not finish in time, proceeding with partial data');
          }
        }
      }

      // ── 3. Fetch opponent answers ─────────────────────────────
      List<Answer>? opponentAnswers;
      int calculatedOpponentScore = 0;
      int calculatedOpponentCorrect = 0;

      if (currentMatch != null && currentUserId != null) {
        final opponentId = currentMatch.getOpponentId(currentUserId);
        if (opponentId != null && opponentId.isNotEmpty) {
          for (int retry = 0; retry < 10; retry++) {
            final answersResult = await _ref.read(matchRepositoryProvider).getPlayerAnswers(
                  matchId: currentMatch.id,
                  userId: opponentId,
                );
            final got = answersResult.fold((_) => <Answer>[], (answers) => answers);
            if (got.isNotEmpty || retry >= 9) {
              opponentAnswers = got;
              for (final ans in got) {
                if (ans.isCorrect) {
                  calculatedOpponentCorrect++;
                  if (ans.questionIndex < _questions.length) {
                    final q = _questions[ans.questionIndex];
                    final maxTime = q.options.isEmpty
                        ? GameConstants.secondsPerTypeQuestion
                        : GameConstants.secondsPerQuestion;
                    calculatedOpponentScore += calculateQuestionScore(
                      isCorrect: true,
                      timeRemaining: maxTime - (ans.timeMs ~/ 1000),
                      streak: 0,
                      isTimeout: false,
                    );
                  }
                }
              }
              break;
            }
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      // ── 4. Update state with opponent data ────────────────────
      state = state.copyWith(
        opponentScore: calculatedOpponentScore > 0 ? calculatedOpponentScore : state.opponentScore,
        opponentCorrectAnswers: calculatedOpponentCorrect,
        opponentAnswers: opponentAnswers,
      );

      // ── 5. ELO calculation (only when we have OPPONENT data) ──
      int? eloChange;
      int? newElo;
      MatchResult? matchResult;

      if (currentUserId != null && opponentAnswers != null && opponentAnswers!.isNotEmpty) {
        final userState = _ref.read(userNotifierProvider);
        final currentUser = userState.valueOrNull;
        final playerElo = currentUser?.elo ?? GameConstants.initialElo;
        final gamesPlayed = currentUser?.stats.totalGames ?? 0;
        final opponentElo = state.opponentElo ?? GameConstants.initialElo;

        final playerPerf = state.calculatePerformanceScore();
        final oppPerf = state.opponentPerformanceScore ?? 0.0;

        double score;
        if (playerPerf > oppPerf) score = 1.0;
        else if (playerPerf < oppPerf) score = 0.0;
        else score = 0.5;

        final eloCalc = EloCalculator();
        eloChange = eloCalc.calculateChange(playerElo: playerElo, opponentElo: opponentElo, score: score, gamesPlayed: gamesPlayed);
        newElo = eloCalc.calculateNewElo(playerElo: playerElo, opponentElo: opponentElo, score: score, gamesPlayed: gamesPlayed);

        final opponentScore = 1.0 - score;
        final oppEloChange = eloCalc.calculateChange(playerElo: opponentElo, opponentElo: playerElo, score: opponentScore, gamesPlayed: gamesPlayed);
        final oppNewElo = eloCalc.calculateNewElo(playerElo: opponentElo, opponentElo: playerElo, score: opponentScore, gamesPlayed: gamesPlayed);

        final opponentId = currentMatch?.getOpponentId(currentUserId);
        if (currentMatch != null && opponentId != null && opponentId.isNotEmpty) {
          matchResult = MatchResult(
            winnerId: score == 1.0 ? currentUserId : (score == 0.0 ? opponentId : null),
            scores: {currentUserId: state.playerScore, opponentId: state.opponentScore},
            eloChanges: {currentUserId: eloChange, opponentId: oppEloChange},
            newElo: {currentUserId: newElo, opponentId: oppNewElo},
          );
          await _ref.read(matchRepositoryProvider).saveMatchResult(
            matchId: currentMatch.id, result: matchResult,
          ).then((_) {});
        }

        if (currentUser != null) {
          final isWin = score == 1.0;
          final isDraw = score == 0.5;
          final newStreak = isWin ? currentUser.stats.currentWinStreak + 1 : 0;
          final bestStreak = newStreak > currentUser.stats.bestWinStreak ? newStreak : currentUser.stats.bestWinStreak;
          final updatedUser = currentUser.copyWith(
            elo: newElo,
            stats: currentUser.stats.copyWith(
              totalGames: currentUser.stats.totalGames + 1,
              wins: currentUser.stats.wins + (isWin ? 1 : 0),
              losses: currentUser.stats.losses + (!isWin && !isDraw ? 1 : 0),
              draws: currentUser.stats.draws + (isDraw ? 1 : 0),
              totalCorrectAnswers: currentUser.stats.totalCorrectAnswers + state.correctAnswers,
              currentWinStreak: newStreak,
              bestWinStreak: bestStreak,
            ),
          );
          await _ref.read(userNotifierProvider.notifier).updateUserProfile(updatedUser)
              .catchError((Object e) => print('Error updating user profile: $e'));
        }

        state = state.copyWith(
          status: MultiplayerStatus.finished,
          eloChange: eloChange,
          newElo: newElo,
          opponentElo: (matchResult != null && opponentId != null)
              ? matchResult.newElo[opponentId]
              : state.opponentElo,
        );
      } else if (state.ghostRun != null && currentUserId != null) {
        // Ghost run: update user stats without touching ELO
        final userState = _ref.read(userNotifierProvider);
        final currentUser = userState.valueOrNull;
        if (currentUser != null) {
          final won = state.playerScore > state.opponentScore;
          final isDraw = state.playerScore == state.opponentScore;
          final newStreak = won ? currentUser.stats.currentWinStreak + 1 : 0;
          final bestStreak = newStreak > currentUser.stats.bestWinStreak
              ? newStreak
              : currentUser.stats.bestWinStreak;

          final updatedUser = currentUser.copyWith(
            stats: currentUser.stats.copyWith(
              totalGames: currentUser.stats.totalGames + 1,
              wins: currentUser.stats.wins + (won ? 1 : 0),
              losses: currentUser.stats.losses + (!won && !isDraw ? 1 : 0),
              draws: currentUser.stats.draws + (isDraw ? 1 : 0),
              totalCorrectAnswers:
                  currentUser.stats.totalCorrectAnswers + state.correctAnswers,
              currentWinStreak: newStreak,
              bestWinStreak: bestStreak,
            ),
          );
          await _ref
              .read(userNotifierProvider.notifier)
              .updateUserProfile(updatedUser)
              .catchError((Object e) => print('Error updating ghost run stats: $e'));
        }
        state = state.copyWith(status: MultiplayerStatus.finished);
      } else {
        // No opponent data — show results without ELO
        state = state.copyWith(status: MultiplayerStatus.finished);
      }
    } catch (e, stack) {
      print('CRITICAL ERROR in _finishMatch: $e\n$stack');
      state = state.copyWith(
        status: MultiplayerStatus.error,
        errorMessage: 'Error al finalizar la partida: $e',
      );
    }
  }

  /// Fallback to ghost run when no opponent found
  Future<void> _fallbackToGhostRun() async {
    state = state.copyWith(
      mode: MultiplayerMode.ghostRun,
      currentMatch: null,
    );
    await _startGhostRunMatch();
  }

  /// Reset state
  void _reset() {
    _timer?.cancel();
    _matchmakingTimer?.cancel();
    _matchSubscription?.cancel();
    _rtdbMatchSubscription?.cancel();
    _queueSubscription?.cancel();
    _opponentStateSubscription?.cancel();
    _inviteStatusSubscription?.cancel();
    _pendingRtdbMatchId = null;
    _pendingInviteId = null;
    _pendingInviteFriendId = null;
    _questions = [];
    state = const MultiplayerState();
  }

  /// Reset from UI
  void reset() => _reset();
}

/// Multiplayer provider
final multiplayerProvider =
    StateNotifierProvider<MultiplayerNotifier, MultiplayerState>((ref) {
  return MultiplayerNotifier(ref);
});