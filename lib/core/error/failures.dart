import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {

  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([super.message = 'Authentication failed']);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([super.message = 'Invalid email or password']);
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure([super.message = 'User not found']);
}

class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure([super.message = 'Email already in use']);
}

class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure([super.message = 'Password is too weak']);
}

class InvalidEmailFailure extends Failure {
  const InvalidEmailFailure([super.message = 'Invalid email format']);
}

// Upload failures
class UploadFailure extends Failure {
  const UploadFailure([super.message = 'Upload failed']);
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error']);
}

// Permission failures
class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure([super.message = 'Permission denied']);
}
