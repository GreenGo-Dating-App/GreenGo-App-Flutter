import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {

  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];

  // Surface the real message (instead of "Instance of 'ServerFailure'") so
  // callers that interpolate a failure into an error string show the cause.
  @override
  String toString() => message;
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

/// An upload the server refused on moderation grounds.
///
/// Distinct from ServerFailure because the UI treats it completely
/// differently: a rejection is explained to the user in a dialog, in their own
/// language, with a way forward - not shown as a generic red "upload failed"
/// snackbar that tells them nothing about what to do next.
class PhotoRejectedFailure extends Failure {
  const PhotoRejectedFailure(this.reasons)
      : super('image-rejected');

  /// Server reason codes: 'adult', 'racy', 'violence', 'no_face',
  /// 'verification_failed'.
  final List<String> reasons;

  bool get isNudity => reasons.contains('adult') || reasons.contains('racy');

  @override
  List<Object?> get props => [message, reasons];
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
