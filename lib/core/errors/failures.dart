import 'package:equatable/equatable.dart';

/// Base failure class for all app failures
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Server failure
class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

/// Network failure
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error occurred'])
      : super(message);
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure(String message) : super(message);
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

/// Timeout failure
class TimeoutFailure extends Failure {
  const TimeoutFailure([String message = 'Request timed out'])
      : super(message);
}

/// Not found failure
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message);
}

/// Permission failure
class PermissionFailure extends Failure {
  const PermissionFailure(String message) : super(message);
}

/// Subscription failure
class SubscriptionFailure extends Failure {
  const SubscriptionFailure(String message) : super(message);
}

/// Unknown failure for unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'An unknown error occurred'])
      : super(message);
}
