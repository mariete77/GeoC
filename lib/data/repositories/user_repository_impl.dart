import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';

/// User repository implementation
class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _firestore;

  UserRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, User>> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        // Auto-create user profile on first login
        return _createUserProfile(userId);
      }

      final userModel = UserModel.fromFirestore(doc);
      return Right(userModel.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Create a new user profile in Firestore
  Future<Either<Failure, User>> _createUserProfile(String userId) async {
    try {
      final firebaseUser = firebase.FirebaseAuth.instance.currentUser;
      final userModel = UserModel(
        userId: userId,
        displayName: firebaseUser?.displayName ?? 'Player',
        email: firebaseUser?.email,
        photoUrl: firebaseUser?.photoURL,
        elo: 1000,
        stats: const UserStatsModel(),
        subscription: const SubscriptionModel(),
        dailyGames: DailyGamesModel.today(),
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(userId).set(userModel.toFirestore());
      return Right(userModel.toDomain());
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserProfile(User user) async {
    try {
      final userModel = UserModel.fromDomain(user);
      await _firestore
          .collection('users')
          .doc(user.userId)
          .update(userModel.toFirestore());
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserStats>> getUserStats(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        throw const NotFoundException('User not found');
      }

      final data = doc.data()!;
      final statsData = data['stats'] as Map<String, dynamic>;

      final stats = UserStats(
        totalGames: statsData['totalGames'] ?? 0,
        wins: statsData['wins'] ?? 0,
        losses: statsData['losses'] ?? 0,
        draws: statsData['draws'] ?? 0,
        totalCorrectAnswers: statsData['totalCorrectAnswers'] ?? 0,
        currentWinStreak: statsData['currentWinStreak'] ?? 0,
        bestWinStreak: statsData['bestWinStreak'] ?? 0,
      );

      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserStats(
    String userId,
    Map<String, dynamic> statsUpdate,
  ) async {
    try {
      final updateMap = <String, dynamic>{};
      statsUpdate.forEach((key, value) {
        updateMap['stats.$key'] = value;
      });

      await _firestore.collection('users').doc(userId).update(updateMap);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DailyGames>> getDailyGames(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        throw const NotFoundException('User not found');
      }

      final data = doc.data()!;
      final dailyData = data['dailyGames'] as Map<String, dynamic>;

      final dailyGames = DailyGames(
        casualPlayed: dailyData['casualPlayed'] ?? 0,
        rankedPlayed: dailyData['rankedPlayed'] ?? 0,
        date: dailyData['date'] != null
            ? (dailyData['date'] as Timestamp).toDate()
            : DateTime.now(),
      );

      return Right(dailyGames);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordGamePlayed(
    String userId,
    bool isRanked,
  ) async {
    try {
      final field = isRanked ? 'rankedPlayed' : 'casualPlayed';

      await _firestore.collection('users').doc(userId).update({
        'dailyGames.$field': FieldValue.increment(1),
        'dailyGames.date': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<User>>> getLeaderboard({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('elo', descending: true)
          .limit(limit)
          .get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc).toDomain())
          .toList();

      return Right(users);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSubscription(
    String userId,
    String type,
    bool isActive,
    DateTime? expiresAt,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscription': {
          'type': type,
          'isActive': isActive,
          'expiresAt': expiresAt?.toIso8601String(),
        },
      });
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
