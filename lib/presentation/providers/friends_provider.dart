import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart' hide State;

import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/friend_repository.dart';
import '../../data/models/user_model.dart';
import 'friend_repository_provider.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class FriendsState {
  final bool isLoading;
  final List<User> friends;
  final List<String> pendingRequests;
  final List<User> searchResults;
  final bool isSearching;
  final String? errorMessage;
  final Set<String> sentRequests;

  const FriendsState({
    this.isLoading = false,
    this.friends = const [],
    this.pendingRequests = const [],
    this.searchResults = const [],
    this.isSearching = false,
    this.errorMessage,
    this.sentRequests = const {},
  });

  FriendsState copyWith({
    bool? isLoading,
    List<User>? friends,
    List<String>? pendingRequests,
    List<User>? searchResults,
    bool? isSearching,
    String? errorMessage,
    Set<String>? sentRequests,
    bool clearError = false,
  }) {
    return FriendsState(
      isLoading: isLoading ?? this.isLoading,
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sentRequests: sentRequests ?? this.sentRequests,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class FriendsNotifier extends StateNotifier<FriendsState> {
  final FriendRepository _friendRepository;
  final String? _currentUserId;

  FriendsNotifier(this._friendRepository, this._currentUserId)
      : super(const FriendsState()) {
    if (_currentUserId != null) {
      refresh();
    }
  }

  // ── Fetch full User objects for every friend ID ─────────────────────────

  Future<void> fetchFriends() async {
    if (_currentUserId == null) {
      state = state.copyWith(
        errorMessage: 'User not logged in',
        clearError: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _friendRepository.getFriends(_currentUserId!);

      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
        (friendIds) async {
          // Fetch each friend's full User document from Firestore
          final List<User> friendsList = [];
          for (final friendId in friendIds) {
            try {
              final doc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendId)
                  .get();
              if (doc.exists) {
                friendsList.add(UserModel.fromFirestore(doc).toDomain());
              }
            } catch (_) {
              // Skip individual failures so one bad doc doesn't break the list
            }
          }
          state = state.copyWith(isLoading: false, friends: friendsList);
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Pending friend requests ─────────────────────────────────────────────

  Future<void> fetchPendingRequests() async {
    if (_currentUserId == null) return;

    try {
      final result =
          await _friendRepository.getPendingFriendRequests(_currentUserId!);

      result.fold(
        (failure) => state = state.copyWith(errorMessage: failure.message),
        (requests) => state = state.copyWith(pendingRequests: requests),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // ── Send a friend request ───────────────────────────────────────────────

  Future<void> sendFriendRequest(String targetUserId) async {
    if (_currentUserId == null) {
      state = state.copyWith(errorMessage: 'User not logged in');
      return;
    }

    // Guard: can't add yourself
    if (targetUserId == _currentUserId) {
      state = state.copyWith(errorMessage: 'You cannot add yourself');
      return;
    }

    // Guard: already sent
    if (state.sentRequests.contains(targetUserId)) {
      state = state.copyWith(errorMessage: 'Friend request already sent');
      return;
    }

    try {
      final result = await _friendRepository.sendFriendRequest(
        _currentUserId!,
        targetUserId,
      );

      result.fold(
        (failure) => state = state.copyWith(errorMessage: failure.message),
        (_) {
          // Optimistically add to sent set
          state = state.copyWith(
            sentRequests: {...state.sentRequests, targetUserId},
            clearError: true,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // ── Accept a friend request ─────────────────────────────────────────────

  Future<void> acceptFriendRequest(String fromUserId) async {
    if (_currentUserId == null) return;

    try {
      final result = await _friendRepository.acceptFriendRequest(
        _currentUserId!,
        fromUserId,
      );

      result.fold(
        (failure) => state = state.copyWith(errorMessage: failure.message),
        (_) {
          // Remove from pending, refresh friends list
          final updated = List<String>.from(state.pendingRequests)
            ..remove(fromUserId);
          state = state.copyWith(pendingRequests: updated, clearError: true);
          fetchFriends();
        },
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // ── Reject a friend request ─────────────────────────────────────────────

  Future<void> rejectFriendRequest(String fromUserId) async {
    if (_currentUserId == null) return;

    try {
      final result = await _friendRepository.rejectFriendRequest(
        _currentUserId!,
        fromUserId,
      );

      result.fold(
        (failure) => state = state.copyWith(errorMessage: failure.message),
        (_) {
          final updated = List<String>.from(state.pendingRequests)
            ..remove(fromUserId);
          state = state.copyWith(pendingRequests: updated, clearError: true);
        },
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // ── Remove a friend ─────────────────────────────────────────────────────

  Future<void> removeFriend(String friendId) async {
    if (_currentUserId == null) return;

    try {
      final result = await _friendRepository.removeFriend(
        _currentUserId!,
        friendId,
      );

      result.fold(
        (failure) => state = state.copyWith(errorMessage: failure.message),
        (_) {
          final updated = List<User>.from(state.friends)
            ..removeWhere((u) => u.userId == friendId);
          state = state.copyWith(friends: updated, clearError: true);
        },
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // ── Search users ────────────────────────────────────────────────────────

  Future<void> searchUsers(String query) async {
    if (_currentUserId == null) return;

    // Require at least 2 characters
    if (query.length < 2) {
      state = state.copyWith(searchResults: const [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true, clearError: true);

    try {
      final result = await _friendRepository.searchUsers(
        query,
        _currentUserId!,
      );

      result.fold(
        (failure) => state = state.copyWith(
          isSearching: false,
          errorMessage: failure.message,
        ),
        (users) {
          // Filter out users already friends or already sent a request to
          final friendIds = state.friends.map((u) => u.userId).toSet();
          final filtered = users.where((u) =>
              u.userId != _currentUserId &&
              !friendIds.contains(u.userId) &&
              !state.sentRequests.contains(u.userId)).toList();
          state = state.copyWith(isSearching: false, searchResults: filtered);
        },
      );
    } catch (e) {
      state = state.copyWith(isSearching: false, errorMessage: e.toString());
    }
  }

  // ── Refresh both friends and pending requests ───────────────────────────

  Future<void> refresh() async {
    await Future.wait([
      fetchFriends(),
      fetchPendingRequests(),
    ]);
  }

  // ── Clear search results ────────────────────────────────────────────────

  void clearSearch() {
    state = state.copyWith(searchResults: const [], isSearching: false);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final friendsProvider =
    StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  final repository = ref.watch(friendRepositoryProvider);
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  return FriendsNotifier(repository, currentUserId);
});
