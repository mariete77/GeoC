import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoquiz_battle/core/errors/exceptions.dart';
import 'package:geoquiz_battle/core/errors/failures.dart';
import 'package:geoquiz_battle/domain/entities/user.dart';
import 'package:geoquiz_battle/domain/repositories/auth_repository.dart';
import 'package:geoquiz_battle/data/datasources/remote/auth_remote_datasource.dart';

/// Authentication repository implementation
class AuthRepositoryImpl implements AuthRepository {
  final firebase.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  final AuthRemoteDataSource? _authRemoteDataSource;

  AuthRepositoryImpl({
    firebase.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
    AuthRemoteDataSource? authRemoteDataSource,
  })  : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _authRemoteDataSource = authRemoteDataSource ??
            AuthRemoteDataSource(
              firebaseAuth: firebaseAuth,
              googleSignIn: googleSignIn,
            );

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null ? User.fromFirebaseUser(firebaseUser) : null;
    });
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      if (_authRemoteDataSource == null) {
        return const Left(AuthFailure('AuthRemoteDataSource not initialized'));
      }
      final firebaseUser = await _authRemoteDataSource!.signInWithGoogle();

      // Create or update user in Firestore (await to ensure profile exists)
      await _createOrUpdateUser(firebaseUser);

      return Right(User.fromFirebaseUser(firebaseUser));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _createOrUpdateUser(userCredential.user!);
      return Right(User.fromFirebaseUser(userCredential.user!));
    } on firebase.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseAuthError(e.code)));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmail(String email, String password, String displayName) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      _createOrUpdateUser(userCredential.user!).catchError((_) {});
      return Right(User.fromFirebaseUser(userCredential.user!));
    } on firebase.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseAuthError(e.code)));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email';
      case 'weak-password':
        return 'La contraseña es demasiado débil (mínimo 6 caracteres)';
      case 'invalid-email':
        return 'Email no válido';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      default:
        return 'Error de autenticación: $code';
    }
  }

  @override
  Future<Either<Failure, User>> signInWithApple() async {
    try {
      if (_authRemoteDataSource == null) {
        return const Left(AuthFailure('AuthRemoteDataSource not initialized'));
      }
      final firebaseUser = await _authRemoteDataSource!.signInWithApple();

      // Create or update user in Firestore (non-blocking)
      _createOrUpdateUser(firebaseUser).catchError((_) {});

      return Right(User.fromFirebaseUser(firebaseUser));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  User? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null ? User.fromFirebaseUser(firebaseUser) : null;
  }

  /// Create or update user in Firestore
  Future<void> _createOrUpdateUser(firebase.User firebaseUser) async {
    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // New user
      await userDoc.set({
        'displayName': firebaseUser.displayName ?? 'Player',
        'email': firebaseUser.email,
        'photoUrl': firebaseUser.photoURL,
        'elo': 1000,
        'stats': {
          'totalGames': 0,
          'wins': 0,
          'losses': 0,
          'draws': 0,
          'totalCorrectAnswers': 0,
          'currentWinStreak': 0,
          'bestWinStreak': 0,
        },
        'subscription': {
          'type': 'free',
          'isActive': false,
        },
        'dailyGames': {
          'casualPlayed': 0,
          'rankedPlayed': 0,
          'date': FieldValue.serverTimestamp(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Existing user - update last login
      await userDoc.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
