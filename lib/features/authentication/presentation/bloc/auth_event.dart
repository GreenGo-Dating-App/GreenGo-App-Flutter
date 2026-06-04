import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthSignInWithEmailRequested extends AuthEvent {

  const AuthSignInWithEmailRequested({
    required this.email,
    required this.password,
  });
  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}

class AuthRegisterWithEmailRequested extends AuthEvent {

  const AuthRegisterWithEmailRequested({
    required this.email,
    required this.password,
  });
  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}

class AuthSignInWithGoogleRequested extends AuthEvent {
  const AuthSignInWithGoogleRequested();
}

// class AuthSignInWithAppleRequested extends AuthEvent {
//   const AuthSignInWithAppleRequested();
// }

class AuthSignInWithFacebookRequested extends AuthEvent {
  const AuthSignInWithFacebookRequested();
}

class AuthSignInWithPhoneRequested extends AuthEvent {

  const AuthSignInWithPhoneRequested(this.phoneNumber);
  final String phoneNumber;

  @override
  List<Object> get props => [phoneNumber];
}

class AuthVerifyPhoneCodeRequested extends AuthEvent {

  const AuthVerifyPhoneCodeRequested({
    required this.verificationId,
    required this.smsCode,
  });
  final String verificationId;
  final String smsCode;

  @override
  List<Object> get props => [verificationId, smsCode];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {

  const AuthPasswordResetRequested(this.email);
  final String email;

  @override
  List<Object> get props => [email];
}

class AuthEmailVerificationRequested extends AuthEvent {
  const AuthEmailVerificationRequested();
}

class AuthBiometricSignInRequested extends AuthEvent {
  const AuthBiometricSignInRequested();
}

/// Event to check user's access status (approval and access date)
class AuthCheckAccessStatusRequested extends AuthEvent {
  const AuthCheckAccessStatusRequested();
}

/// Event to enable notifications for waiting users
class AuthEnableNotificationsRequested extends AuthEvent {
  const AuthEnableNotificationsRequested();
}

/// Event fired when the user successfully completes selfie verification on login.
class AuthSelfieVerificationCompleted extends AuthEvent {

  const AuthSelfieVerificationCompleted({required this.userId});
  final String userId;

  @override
  List<Object> get props => [userId];
}

/// Event fired when the user cancels selfie verification on login (triggers sign-out).
class AuthSelfieVerificationCancelled extends AuthEvent {
  const AuthSelfieVerificationCancelled();
}
