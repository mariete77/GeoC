/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final int? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

/// Server exception thrown when server returns an error
class ServerException extends AppException {
  const ServerException(String message, [int? code]) : super(message, code);
}

/// Network exception thrown when network fails
class NetworkException extends AppException {
  const NetworkException([String message = 'Network error occurred'])
      : super(message);
}

/// Cache exception thrown when cache access fails
class CacheException extends AppException {
  const CacheException(String message) : super(message);
}

/// Authentication exception
class AuthException extends AppException {
  const AuthException(String message, [int? code]) : super(message, code);
}

/// Validation exception
class ValidationException extends AppException {
  const ValidationException(String message) : super(message);
}

/// Timeout exception
class TimeoutException extends AppException {
  const TimeoutException([String message = 'Request timed out'])
      : super(message);
}

/// Not found exception
class NotFoundException extends AppException {
  const NotFoundException(String message) : super(message);
}

/// Permission exception
class PermissionException extends AppException {
  const PermissionException(String message) : super(message);
}

/// Subscription exception
class SubscriptionException extends AppException {
  const SubscriptionException(String message) : super(message);
}
