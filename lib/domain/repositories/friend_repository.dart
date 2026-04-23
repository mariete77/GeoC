import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

/// FriendRepository interface
abstract class FriendRepository {
  /// Get the list of friends for a user
  Future<Either<Failure, List<String>>> getFriends(String userId);

  /// Add a friend (sends a friend request)
  Future<Either<Failure, Unit>> addFriend(String userId, String friendId);

  /// Remove a friend from the list
  Future<Either<Failure, Unit>> removeFriend(String userId, String friendId);

  /// Send a friend request (stores pending request)
  Future<Either<Failure, Unit>> sendFriendRequest(
      String requestingUserId, String targetUserId);

  /// Get pending friend requests for a user
  Future<Either<Failure, List<String>>> getPendingFriendRequests(
      String userId);

  /// Accept a friend request (mutual friendship)
  Future<Either<Failure, Unit>> acceptFriendRequest(
      String acceptingUserId, String requestFromUserId);
}