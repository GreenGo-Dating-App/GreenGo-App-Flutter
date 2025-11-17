import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred']) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection']) : super(message);
}

// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([String message = 'Authentication failed']) : super(message);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([String message = 'Invalid email or password']) : super(message);
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure([String message = 'User not found']) : super(message);
}

class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure([String message = 'Email already in use']) : super(message);
}

class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure([String message = 'Password is too weak']) : super(message);
}

class InvalidEmailFailure extends Failure {
  const InvalidEmailFailure([String message = 'Invalid email format']) : super(message);
}

// Upload failures
class UploadFailure extends Failure {
  const UploadFailure([String message = 'Upload failed']) : super(message);
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Validation error']) : super(message);
}

// Permission failures
class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure([String message = 'Permission denied']) : super(message);
}
