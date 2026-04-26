import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
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
      
      final data = userDoc.data();
      if (data == null || !data.containsKey('friends')) return const Right([]);
      
      final friends = data['friends'] as List<dynamic>? ?? [];
      return Right(List<String>.from(friends.map((e) => e as String)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      return Left(ServerFailure(e.toString()));
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
      
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<String>> watchFriends(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <String>[];
      final friends = doc.get('friends') as List<dynamic>? ?? [];
      return List<String>.from(friends.map((e) => e as String));
    });
  }

  @override
  Stream<List<String>> watchPendingRequests(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <String>[];
      final requests = doc.get('pending_requests') as List<dynamic>? ?? [];
      return List<String>.from(requests.map((e) => e as String));
    });
  }

  @override
  Future<Either<Failure, Unit>> rejectFriendRequest(
      String rejectingUserId, String requestFromUserId) async {
    try {
      if (rejectingUserId == requestFromUserId) {
        return Left(ValidationFailure('Cannot reject your own request'));
      }

      final rejectingDoc =
          await _firestore.collection('users').doc(rejectingUserId).get();
      if (!rejectingDoc.exists) {
        return Left(UserNotFoundFailure('User not found'));
      }

      // Remove from pending_requests
      await _firestore.collection('users').doc(rejectingUserId).update({
        'pending_requests': FieldValue.arrayRemove([requestFromUserId]),
      });

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<User>>> searchUsers(
      String query, String currentUserId) async {
    try {
      if (query.trim().isEmpty) {
        return const Right([]);
      }

      final searchTerm = query.trim();
      final endQuery = '$searchTerm\uf8ff';

      // Query users whose displayName starts with the query (case-sensitive literal)
      final snapshot = await _firestore
          .collection('users')
          .where('displayName',
              isGreaterThanOrEqualTo: searchTerm,
              isLessThan: endQuery)
          .limit(20)
          .get();

      // Import avoided at top – we need UserModel here
      // Use dynamic mapping to construct User entities
      final users = snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) {
        final data = doc.data();
        final timestamps = data['createdAt'];
        final loginTimestamps = data['lastLoginAt'];

        return User(
          userId: doc.id,
          displayName: data['displayName'] as String? ?? 'Player',
          email: data['email'] as String?,
          photoUrl: data['photoUrl'] as String?,
          elo: data['elo'] as int? ?? 1000,
          stats: const UserStats(),
          subscription: const Subscription(),
          dailyGames: DailyGames.today(),
          createdAt: timestamps is Timestamp
              ? timestamps.toDate()
              : DateTime.now(),
          lastLoginAt: loginTimestamps is Timestamp
              ? loginTimestamps.toDate()
              : null,
        );
      }).toList();

      return Right(users);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> areFriends(
      String userId1, String userId2) async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(userId1).get();
      if (!userDoc.exists) return Left(UserNotFoundFailure('User not found'));

      final friends = userDoc.get('friends') as List<dynamic>? ?? [];
      final friendsList = List<String>.from(friends.map((e) => e as String));
      return Right(friendsList.contains(userId2));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasPendingRequest(
      String fromUserId, String toUserId) async {
    try {
      final targetDoc =
          await _firestore.collection('users').doc(toUserId).get();
      if (!targetDoc.exists) {
        return Left(UserNotFoundFailure('Target user not found'));
      }

      final requests =
          targetDoc.get('pending_requests') as List<dynamic>? ?? [];
      final requestsList =
          List<String>.from(requests.map((e) => e as String));
      return Right(requestsList.contains(fromUserId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
