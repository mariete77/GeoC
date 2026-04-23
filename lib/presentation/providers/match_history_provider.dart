import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';
import 'auth_provider.dart'; // Assuming AuthProvider gives us the current user ID

// Provider for the MatchRepository
final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => throw UnimplementedError(), // Will be overridden in main or test setup
);

// State for MatchHistoryProvider
class MatchHistoryState {
  final bool isLoading;
  final List<GameMatch> matches;
  final Failure? failure;

  MatchHistoryState({
    this.isLoading = false,
    this.matches = const [],
    this.failure,
  });

  MatchHistoryState copyWith({
    bool? isLoading,
    List<GameMatch>? matches,
    Failure? failure,
  }) {
    return MatchHistoryState(
      isLoading: isLoading ?? this.isLoading,
      matches: matches ?? this.matches,
      failure: failure ?? this.failure,
    );
  }
}

// MatchHistoryNotifier
class MatchHistoryNotifier extends StateNotifier<MatchHistoryState> {
  final MatchRepository _matchRepository;
  final String? _currentUserId;

  MatchHistoryNotifier(this._matchRepository, this._currentUserId) : super(MatchHistoryState()) {
    if (_currentUserId != null) {
      fetchMatchHistory();
    }
  }

  Future<void> fetchMatchHistory() async {
    if (_currentUserId == null) {
      state = state.copyWith(failure: AuthFailure('User not logged in'));
      return;
    }

    state = state.copyWith(isLoading: true, failure: null);
    final result = await _matchRepository.getUserMatches(
      _currentUserId!,
      status: MatchStatus.finished,
    );

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, failure: failure),
      (matches) => state = state.copyWith(isLoading: false, matches: matches),
    );
  }
}

// Provider for MatchHistoryNotifier
final matchHistoryProvider = StateNotifierProvider<MatchHistoryNotifier, MatchHistoryState>(
  (ref) {
    final matchRepository = ref.watch(matchRepositoryProvider);
    final currentUserId = ref.watch(authProvider).user?.id; // Assuming authProvider exposes user ID
    return MatchHistoryNotifier(matchRepository, currentUserId);
  },
);
