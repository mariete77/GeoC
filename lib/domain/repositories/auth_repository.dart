import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Stream of auth state changes
  Stream<User?> get authStateChanges;

  /// Sign in with Google
  Future<Either<Failure, User>> signInWithGoogle();

  /// Sign in with Apple
  Future<Either<Failure, User>> signInWithApple();

  /// Sign out
  Future<Either<Failure, void>> signOut();

  /// Get current user
  User? get currentUser;
}
