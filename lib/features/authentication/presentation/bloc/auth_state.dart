import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  final DateTime timestamp;

  AuthError(this.message) : timestamp = DateTime.now();

  @override
  List<Object> get props => [message, timestamp];
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

class AuthEmailVerificationSent extends AuthState {
  const AuthEmailVerificationSent();
}

class AuthPhoneCodeSent extends AuthState {
  final String verificationId;

  const AuthPhoneCodeSent(this.verificationId);

  @override
  List<Object> get props => [verificationId];
}

class AuthBiometricAvailable extends AuthState {
  final bool isAvailable;

  const AuthBiometricAvailable(this.isAvailable);

  @override
  List<Object> get props => [isAvailable];
}

/// State when user is authenticated but waiting for access
/// (pending approval or waiting for access date)
class AuthWaitingForAccess extends AuthState {
  final User user;
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  final DateTime accessDate;
  final String membershipTier;
  final bool canAccessApp;

  const AuthWaitingForAccess({
    required this.user,
    required this.approvalStatus,
    required this.accessDate,
    required this.membershipTier,
    required this.canAccessApp,
  });

  @override
  List<Object> get props => [user, approvalStatus, accessDate, membershipTier, canAccessApp];
}
