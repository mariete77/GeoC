import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/errors/failures.dart';

part 'auth_provider.g.dart';

/// Auth repository provider
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl();
}

/// Auth state
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<User?> build() {
    // Listen to auth state changes
    ref.listen(authStateChangesProvider, (previous, next) {
      if (next.hasValue) {
        state = AsyncValue.data(next.value);
      }
    });

    return const AsyncValue.loading();
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).signInWithApple();
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).signInWithEmail(email, password);
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail(String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).signUpWithEmail(email, password, displayName);
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (user) => AsyncValue.data(user),
    );
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).signOut();
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  /// Get error message
  String getErrorMessage(Object error) {
    if (error is Failure) {
      return error.message;
    }
    return 'An unknown error occurred';
  }
}

/// Auth state changes provider (stream from repository)
@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

/// Current user provider
@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authRepositoryProvider).currentUser;
}

/// Is authenticated provider
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  return ref.watch(currentUserProvider) != null;
}
