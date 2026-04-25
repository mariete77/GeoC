import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for ELO history (sparkline data)
class EloHistoryState {
  final List<int> eloValues;
  final int currentElo;
  final int eloDelta;

  const EloHistoryState({
    this.eloValues = const [],
    this.currentElo = 1000,
    this.eloDelta = 0,
  });

  EloHistoryState copyWith({
    List<int>? eloValues,
    int? currentElo,
    int? eloDelta,
  }) {
    return EloHistoryState(
      eloValues: eloValues ?? this.eloValues,
      currentElo: currentElo ?? this.currentElo,
      eloDelta: eloDelta ?? this.eloDelta,
    );
  }
}

/// Notifier for ELO history data
class EloHistoryNotifier extends StateNotifier<EloHistoryState> {
  EloHistoryNotifier() : super(const EloHistoryState());

  /// Update ELO history with new values
  void updateEloHistory(List<int> values, int currentElo, int delta) {
    state = EloHistoryState(
      eloValues: values,
      currentElo: currentElo,
      eloDelta: delta,
    );
  }

  /// Add a new ELO value
  void addEloValue(int newElo) {
    final values = [...state.eloValues, newElo];
    final delta = values.length >= 2 ? newElo - state.currentElo : 0;
    state = EloHistoryState(
      eloValues: values,
      currentElo: newElo,
      eloDelta: delta,
    );
  }
}

/// Provider for ELO history data
final eloHistoryProvider =
    StateNotifierProvider<EloHistoryNotifier, EloHistoryState>(
  (ref) => EloHistoryNotifier(),
);