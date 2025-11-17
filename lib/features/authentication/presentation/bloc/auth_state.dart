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

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
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
