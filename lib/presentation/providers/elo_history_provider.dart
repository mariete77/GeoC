import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/match.dart';
import 'auth_provider.dart';
import 'match_history_provider.dart';

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

/// Provider for ELO history data — derived from match history
/// Extracts ELO values from finished matches to build the sparkline
final eloHistoryProvider = Provider<EloHistoryState>((ref) {
  final currentUserId = ref.watch(currentUserProvider)?.userId;
  final matchHistory = ref.watch(matchHistoryProvider);

  if (currentUserId == null || matchHistory.matches.isEmpty) {
    return const EloHistoryState();
  }

  // Extract ELO values from finished matches (sorted oldest → newest)
  final finishedMatches = matchHistory.matches
      .where((m) =>
          m.status == MatchStatus.finished &&
          m.result != null &&
          m.finishedAt != null)
      .toList()
    ..sort((a, b) => a.finishedAt!.compareTo(b.finishedAt!));

  final eloValues = <int>[];
  int? latestElo;
  int delta = 0;

  for (final match in finishedMatches) {
    final newElo = match.result?.newElo[currentUserId];
    if (newElo != null) {
      eloValues.add(newElo);
      latestElo = newElo;
    }
  }

  // Calculate delta: last match ELO change, or diff between last two values
  if (eloValues.length >= 2) {
    delta = eloValues.last - eloValues[eloValues.length - 2];
  }

  // Take last 20 values for the sparkline
  final displayValues = eloValues.length > 20
      ? eloValues.sublist(eloValues.length - 20)
      : eloValues;

  return EloHistoryState(
    eloValues: displayValues,
    currentElo: latestElo ?? 1000,
    eloDelta: delta,
  );
});