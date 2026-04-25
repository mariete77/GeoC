import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/match_repository_impl.dart';
import '../../data/repositories/ghost_run_repository_impl.dart';
import '../../data/repositories/question_repository_impl.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/user.dart';
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
  StreamSubscription? _matchSubscription;
  List<Question> _questions = [];
  String? _pendingMatchId; // Track match ID for cancellation

  MultiplayerNotifier(this._ref) : super(const MultiplayerState()) {
    // Cleanup on dispose
    _ref.onDispose(() {
      _timer?.cancel();
      _matchmakingTimer?.cancel();
      _matchSubscription?.cancel();
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
            state = state.copyWith(
              status: MultiplayerStatus.found,
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
      (questions) {
        _questions = questions;
        state = state.copyWith(
          status: MultiplayerStatus.found,
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

  /// Start a PvP match (try to find waiting match first, then create new)
  Future<void> _startPvPMatch(MultiplayerMode mode) async {
    final matchType = mode == MultiplayerMode.ranked ? MatchType.ranked : MatchType.casual;
    final userElo = _userElo;

    // Step 1: Try to find an existing waiting match
    final findResult = await _ref.read(matchRepositoryProvider).findWaitingMatch(
          mode: mode.name,
          playerElo: userElo,
          userId: _currentUserId!,
        );

    await findResult.fold(
      (failure) async => _createAndWaitForOpponent(matchType, userElo),
      (existingMatch) async {
        if (existingMatch != null) {
          // Found a waiting match - join it!
          await _joinExistingMatch(existingMatch);
        } else {
          // No waiting match - create a new one
          await _createAndWaitForOpponent(matchType, userElo);
        }
      },
    );
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

  /// Load questions by IDs from the match (so both players get same questions)
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

  /// Join an existing waiting match
  Future<void> _joinExistingMatch(GameMatch existingMatch) async {
    final joinResult = await _ref.read(matchRepositoryProvider).joinMatch(
          matchId: existingMatch.id,
          userId: _currentUserId!,
        );

    joinResult.fold(
      (failure) {
        // Join failed (someone else joined first) - create new match
        _createAndWaitForOpponent(existingMatch.type, _userElo);
      },
      (joinedMatch) async {
        // Load the SAME questions that the creator stored in the match
        final questions = await _loadQuestionsByIds(joinedMatch.questionIds);

        if (questions == null) {
          // Fallback: couldn't load shared questions, generate random (not ideal)
          final fallbackQuestions = await _generateQuestions();
          if (fallbackQuestions == null) {
            state = state.copyWith(
              status: MultiplayerStatus.error,
              errorMessage: 'Failed to load questions',
            );
            return;
          }
          _questions = fallbackQuestions;
        } else {
          _questions = questions;
        }

        state = state.copyWith(
          status: MultiplayerStatus.found,
          currentMatch: joinedMatch,
          opponentName: 'Opponent',
        );

        Future.delayed(const Duration(seconds: 2), () {
          _startPlaying();
        });
      },
    );
  }

  /// Create a new match and wait for opponent
  Future<void> _createAndWaitForOpponent(MatchType matchType, int creatorElo) async {
    // Pre-generate questions so both players get the same set
    final questions = await _generateQuestions();
    if (questions == null) {
      state = state.copyWith(
        status: MultiplayerStatus.error,
        errorMessage: 'Failed to generate questions',
      );
      return;
    }
    _questions = questions;

    // Create match with pre-generated question IDs
    final newMatch = GameMatch(
      id: '',
      players: [_currentUserId!],
      mode: MatchMode.async,
      type: matchType,
      status: MatchStatus.waiting,
      questionIds: questions.map((q) => q.id).toList(),
      answers: {},
      createdAt: DateTime.now(),
      creatorElo: creatorElo,
    );

    final result = await _ref.read(matchRepositoryProvider).createMatch(newMatch);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: MultiplayerStatus.error,
          errorMessage: 'Failed to create match: ${failure.message}',
        );
      },
      (matchId) {
        _pendingMatchId = matchId;
        // Watch the match for opponent joining
        _watchForOpponent(matchId);

        // Set a timeout (15s) - fall back to ghost run if no opponent found
        _matchmakingTimer = Timer(
          const Duration(seconds: 15),
          () {
            if (state.status == MultiplayerStatus.searching) {
              _cancelMatchmaking(matchId);
              // Fallback to ghost run mode for casual/ranked
              _fallbackToGhostRun();
            }
          },
        );
      },
    );
  }

  /// Watch match for opponent
  void _watchForOpponent(String matchId) {
    _matchSubscription?.cancel();
    _matchSubscription = _ref
        .read(matchRepositoryProvider)
        .watchMatch(matchId)
        .listen((gameMatch) {
      if (gameMatch.players.length >= 2 && state.status == MultiplayerStatus.searching) {
        _matchmakingTimer?.cancel();
        _onOpponentFound(gameMatch);
      }
    });
  }

  /// Called when opponent is found (creator side - questions already generated)
  Future<void> _onOpponentFound(GameMatch match) async {
    // Questions already set from _createAndWaitForOpponent
    // Just update match status to active
    final updatedMatch = GameMatch(
      id: match.id,
      players: match.players,
      mode: match.mode,
      type: match.type,
      status: MatchStatus.active,
      questionIds: match.questionIds.isNotEmpty
          ? match.questionIds
          : _questions.map((q) => q.id).toList(),
      answers: match.answers,
      createdAt: match.createdAt,
      startedAt: DateTime.now(),
    );

    await _ref.read(matchRepositoryProvider).updateMatch(match.id, updatedMatch);

    state = state.copyWith(
      status: MultiplayerStatus.found,
      currentMatch: updatedMatch,
      opponentName: 'Opponent',
    );

    // Auto-start after short delay
    await Future.delayed(const Duration(seconds: 2));
    _startPlaying();
  }

  /// Cancel matchmaking
  Future<void> _cancelMatchmaking(String matchId) async {
    _matchSubscription?.cancel();
    _matchmakingTimer?.cancel();

    await _ref.read(matchRepositoryProvider).finishMatch(matchId);
  }

  /// Cancel matchmaking from UI
  Future<void> cancelSearch() async {
    if (_pendingMatchId != null) {
      await _cancelMatchmaking(_pendingMatchId!);
      _pendingMatchId = null;
    }
    _reset();
  }

  /// Challenge a specific friend to a match
  /// Uses the friend's most recent ghost run if available, otherwise generates random questions
  Future<void> challengeFriend(
    String friendId, {
    String? friendName,
    int? friendElo,
  }) async {
    if (_currentUserId == null) {
      state = state.copyWith(
        status: MultiplayerStatus.error,
        errorMessage: 'Not authenticated',
      );
      return;
    }
    if (friendId == _currentUserId) {
      state = state.copyWith(
        status: MultiplayerStatus.error,
        errorMessage: 'Cannot challenge yourself',
      );
      return;
    }

    state = state.copyWith(
      status: MultiplayerStatus.searching,
      mode: MultiplayerMode.friendChallenge,
      errorMessage: null,
    );

    try {
      // Fetch friend info from Firestore if not provided
      String name = friendName ?? 'Amigo';
      int elo = friendElo ?? 1000;
      if (friendName == null || friendElo == null) {
        final friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .get();
        if (friendDoc.exists) {
          final data = friendDoc.data()!;
          name = data['displayName'] ?? name;
          elo = data['elo'] ?? elo;
        }
      }

      // Try to find friend's most recent ghost run to play against
      final ghostResult = await _ref
          .read(ghostRunRepositoryProvider)
          .getUserGhostRuns(friendId);

      await ghostResult.fold(
        (failure) async {
          // Couldn't fetch ghost runs — play with random questions
          await _startFriendChallengeSolo(name, elo, friendId);
        },
        (ghostRuns) async {
          if (ghostRuns.isEmpty) {
            await _startFriendChallengeSolo(name, elo, friendId);
            return;
          }

          // Use friend's most recent ghost run
          final friendGhostRun = ghostRuns.first;
          final questionsResult = await _ref
              .read(questionRepositoryMultiProvider)
              .getQuestionsByIds(friendGhostRun.questionIds);

          await questionsResult.fold(
            (failure) async {
              await _startFriendChallengeSolo(name, elo, friendId);
            },
            (questions) async {
              if (questions.isEmpty) {
                await _startFriendChallengeSolo(name, elo, friendId);
                return;
              }

              _questions = questions;
              state = state.copyWith(
                status: MultiplayerStatus.found,
                ghostRun: friendGhostRun,
                opponentName: name,
                opponentElo: elo,
                invitedFriendId: friendId,
              );

              // Auto-start after short delay
              await Future.delayed(const Duration(seconds: 2));
              _startPlaying();
            },
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: MultiplayerStatus.error,
        errorMessage: 'Error al crear reto: $e',
      );
    }
  }

  /// Start friend challenge with random questions (no ghost run available)
  Future<void> _startFriendChallengeSolo(
    String friendName,
    int friendElo,
    String friendId,
  ) async {
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
      (questions) {
        _questions = questions;
        state = state.copyWith(
          status: MultiplayerStatus.found,
          opponentName: friendName,
          opponentElo: friendElo,
          invitedFriendId: friendId,
        );

        Future.delayed(const Duration(seconds: 2), () {
          _startPlaying();
        });
      },
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
    _timer?.cancel();
    _matchSubscription?.cancel();

    // Save ghost run from all multiplayer games (so there is always a pool for others)
    if (_currentUserId != null && state.playerAnswers.isNotEmpty) {
      await _ref.read(ghostRunRepositoryProvider).saveGhostRun(
            userId: _currentUserId!,
            elo: _userElo,
            questionIds: _questions.map((q) => q.id).toList(),
            answers: state.playerAnswers,
          );
    }

    // Submit answers to match if PvP
    if (state.currentMatch != null && _currentUserId != null) {
      for (final answer in state.playerAnswers) {
        await _ref.read(matchRepositoryProvider).submitAnswer(
              state.currentMatch!.id,
              answer,
            );
      }

      // Fetch opponent's real answers and calculate their score
      final opponentId = state.currentMatch!.getOpponentId(_currentUserId!);
      if (opponentId != null && opponentId.isNotEmpty) {
        final answersResult = await _ref.read(matchRepositoryProvider).getPlayerAnswers(
              matchId: state.currentMatch!.id,
              userId: opponentId,
            );

        answersResult.fold(
          (failure) => null, // Keep current opponentScore (0)
          (opponentAnswers) {
            int calculatedOpponentScore = 0;
            int calculatedOpponentCorrect = 0;
            final convertedAnswers = <Answer>[];
            for (final ans in opponentAnswers) {
              if (ans.isCorrect) {
                calculatedOpponentCorrect++;
              }
              if (ans.isCorrect && ans.questionIndex < _questions.length) {
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
              convertedAnswers.add(ans);
            }
            state = state.copyWith(
              opponentScore: calculatedOpponentScore,
              opponentCorrectAnswers: calculatedOpponentCorrect,
              opponentAnswers: convertedAnswers,
            );
          },
        );
      }
    }

    // ── Calculate and update Elo (multiplayer only) ──────────────
    int? eloChange;
    int? newElo;
    MatchResult? matchResult;

    if (_currentUserId != null) {
      final userState = _ref.read(userNotifierProvider);
      final currentUser = userState.valueOrNull;
      final playerElo = currentUser?.elo ?? GameConstants.initialElo;
      final gamesPlayed = currentUser?.stats.totalGames ?? 0;

      // Determine opponent Elo for calculation
      final opponentId = state.currentMatch?.getOpponentId(_currentUserId!) ?? '';
      final opponentElo = state.opponentElo ?? GameConstants.initialElo;

      // Calculate score: based on win/loss/draw
      // 1.0 = win, 0.0 = loss, 0.5 = draw
      double score;
      if (state.playerScore > state.opponentScore) {
        score = 1.0; // Win
      } else if (state.playerScore < state.opponentScore) {
        score = 0.0; // Loss
      } else {
        score = 0.5; // Draw
      }

      final eloCalc = EloCalculator();
      eloChange = eloCalc.calculateChange(
        playerElo: playerElo,
        opponentElo: opponentElo,
        score: score,
        gamesPlayed: gamesPlayed,
      );
      newElo = eloCalc.calculateNewElo(
        playerElo: playerElo,
        opponentElo: opponentElo,
        score: score,
        gamesPlayed: gamesPlayed,
      );

      // Calculate opponent's ELO change (inverse of player's)
      final opponentScore = 1.0 - score; // 0.0 if win, 1.0 if loss, 0.5 if draw
      // Get opponent games (estimated for now - stored in match in future)
      final opponentGamesPlayed = gamesPlayed; // Simplified: same games count

      final opponentEloChange = eloCalc.calculateChange(
        playerElo: opponentElo,
        opponentElo: playerElo,
        score: opponentScore,
        gamesPlayed: opponentGamesPlayed,
      );
      final opponentNewElo = eloCalc.calculateNewElo(
        playerElo: opponentElo,
        opponentElo: playerElo,
        score: opponentScore,
        gamesPlayed: opponentGamesPlayed,
      );

      // Create MatchResult with both players' ELO changes
      if (opponentId.isNotEmpty && state.currentMatch != null) {
        matchResult = MatchResult(
          winnerId: score == 1.0 ? _currentUserId : (score == 0.0 ? null : opponentId),
          scores: {
            _currentUserId!: state.playerScore,
            if (opponentId.isNotEmpty) opponentId: state.opponentScore,
          },
          eloChanges: {
            _currentUserId!: eloChange!,
            if (opponentId.isNotEmpty) opponentId: opponentEloChange,
          },
          newElo: {
            _currentUserId!: newElo!,
            if (opponentId.isNotEmpty) opponentId: opponentNewElo,
          },
        );
      }

      // Save match result to Firestore
      if (state.currentMatch != null && matchResult != null) {
        await _ref.read(matchRepositoryProvider).saveMatchResult(
              matchId: state.currentMatch!.id,
              result: matchResult!,
            );
      }

      // Update user Elo and stats in Firestore (only our player)
      if (currentUser != null) {
        final isWin = score == 1.0;
        final isDraw = score == 0.5;
        final newStreak = isWin
            ? currentUser.stats.currentWinStreak + 1
            : 0;
        final bestStreak = newStreak > currentUser.stats.bestWinStreak
            ? newStreak
            : currentUser.stats.bestWinStreak;

        final updatedUser = User(
          userId: currentUser.userId,
          displayName: currentUser.displayName,
          email: currentUser.email,
          photoUrl: currentUser.photoUrl,
          elo: newElo,
          stats: UserStats(
            totalGames: currentUser.stats.totalGames + 1,
            wins: currentUser.stats.wins + (isWin ? 1 : 0),
            losses: currentUser.stats.losses + (!isWin && !isDraw ? 1 : 0),
            draws: currentUser.stats.draws + (isDraw ? 1 : 0),
            totalCorrectAnswers:
                currentUser.stats.totalCorrectAnswers + state.correctAnswers,
            currentWinStreak: newStreak,
            bestWinStreak: bestStreak,
          ),
          subscription: currentUser.subscription,
          dailyGames: currentUser.dailyGames,
          createdAt: currentUser.createdAt,
          lastLoginAt: currentUser.lastLoginAt,
        );

        await _ref.read(userNotifierProvider.notifier).updateUserProfile(updatedUser);
      }

      // Update state with opponent's new ELO for display and finish status
      state = state.copyWith(
        opponentElo: opponentId.isNotEmpty ? opponentNewElo : null,
        status: MultiplayerStatus.finished,
        eloChange: eloChange,
        newElo: newElo,
      );
    }
  }
  /// Fallback to ghost run when no opponent found
  Future<void> _fallbackToGhostRun() async {
    // Switch to ghost run mode and start match
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