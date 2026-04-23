import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/friend_repository.dart';
import '../../domain/entities/user.dart';
import '../../core/errors/failures.dart';

/// Firestore implementation of FriendRepository
class FriendRepositoryImpl implements FriendRepository {
  final FirebaseFirestore _firestore;

  FriendRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, List<String>>> getFriends(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return Left(UserNotFoundFailure('User not found'));
      
      final friends = userDoc.get('friends') as List<dynamic>? ?? [];
      return Right(List<String>.from(friends.map((e) => e as String)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addFriend(String userId, String friendId) async {
    try {
      if (userId == friendId) return Left(ValidationFailure('Cannot add yourself as a friend'));
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return Left(UserNotFoundFailure('User not found'));
      
      await _firestore.collection('users').doc(userId).update({
        'friends': FieldValue.arrayUnion([friendId]),
      });
      
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeFriend(String userId, String friendId) async {
    try {
      if (userId == friendId) return Left(ValidationFailure('Cannot remove yourself as a friend'));
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return Left(UserNotFoundFailure('User not found'));
      
      await _firestore.collection('users').doc(userId).update({
        'friends': FieldValue.arrayRemove([friendId]),
      });
      
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendFriendRequest(
      String requestingUserId, String targetUserId) async {
    try {
      if (requestingUserId == targetUserId) return Left(ValidationFailure('Cannot send request to yourself'));
      
      final targetDoc = await _firestore.collection('users').doc(targetUserId).get();
      if (!targetDoc.exists) return Left(UserNotFoundFailure('Target user not found'));
      
      // Store request in pending_requests field
      await _firestore.collection('users').doc(targetUserId).update({
        'pending_requests': FieldValue.arrayUnion([requestingUserId]),
      });
      
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getPendingFriendRequests(
      String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return Left(UserNotFoundFailure('User not found'));
      
      final requests = userDoc.get('pending_requests') as List<dynamic>? ?? [];
      return Right(List<String>.from(requests.map((e) => e as String)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> acceptFriendRequest(
      String acceptingUserId, String requestFromUserId) async {
    try {
      if (acceptingUserId == requestFromUserId) return Left(ValidationFailure('Cannot accept your own request'));
      
      final acceptingDoc = await _firestore.collection('users').doc(acceptingUserId).get();
      if (!acceptingDoc.exists) return Left(UserNotFoundFailure('User not found'));
      
      final requestingDoc = await _firestore.collection('users').doc(requestFromUserId).get();
      if (!requestingDoc.exists) return Left(UserNotFoundFailure('Request from user not found'));
      
      // Add to friends for both parties
      await _firestore.collection('users').doc(acceptingUserId).update({
        'friends': FieldValue.arrayUnion([requestFromUserId]),
      });
      
      await _firestore.collection('users').doc(requestFromUserId).update({
        'friends': FieldValue.arrayUnion([acceptingUserId]),
      });
      
      // Remove pending request
      await _firestore.collection('users').doc(acceptingUserId).update({
        'pending_requests': FieldValue.arrayRemove([requestFromUserId]),
      });
      
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}