import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        throw const NotFoundException('User not found');
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
