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
  final String email;
  final String password;

  const AuthSignInWithEmailRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class AuthRegisterWithEmailRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthRegisterWithEmailRequested({
    required this.email,
    required this.password,
  });

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
  final String phoneNumber;

  const AuthSignInWithPhoneRequested(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
}

class AuthVerifyPhoneCodeRequested extends AuthEvent {
  final String verificationId;
  final String smsCode;

  const AuthVerifyPhoneCodeRequested({
    required this.verificationId,
    required this.smsCode,
  });

  @override
  List<Object> get props => [verificationId, smsCode];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested(this.email);

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
