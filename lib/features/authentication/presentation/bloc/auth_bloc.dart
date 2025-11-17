import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  final LocalAuthentication localAuth;

  AuthBloc({
    required this.repository,
    required this.localAuth,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInWithEmailRequested>(_onSignInWithEmailRequested);
    on<AuthRegisterWithEmailRequested>(_onRegisterWithEmailRequested);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    // on<AuthSignInWithAppleRequested>(_onSignInWithAppleRequested);
    on<AuthSignInWithFacebookRequested>(_onSignInWithFacebookRequested);
    on<AuthSignInWithPhoneRequested>(_onSignInWithPhoneRequested);
    on<AuthVerifyPhoneCodeRequested>(_onVerifyPhoneCodeRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthEmailVerificationRequested>(_onEmailVerificationRequested);
    on<AuthBiometricSignInRequested>(_onBiometricSignInRequested);

    // Listen to auth state changes
    repository.authStateChanges.listen((user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await repository.getCurrentUser();
    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (user) => user != null
          ? emit(AuthAuthenticated(user))
          : emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onSignInWithEmailRequested(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await repository.signInWithEmail(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onRegisterWithEmailRequested(
    AuthRegisterWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await repository.registerWithEmail(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        // Send email verification after registration
        repository.sendEmailVerification();
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await repository.signInWithGoogle();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  // Future<void> _onSignInWithAppleRequested(
  //   AuthSignInWithAppleRequested event,
  //   Emitter<AuthState> emit,
  // ) async {
  //   emit(const AuthLoading());
  //   final result = await repository.signInWithApple();
  //   result.fold(
  //     (failure) => emit(AuthError(failure.message)),
  //     (user) => emit(AuthAuthenticated(user)),
  //   );
  // }

  Future<void> _onSignInWithFacebookRequested(
    AuthSignInWithFacebookRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await repository.signInWithFacebook();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignInWithPhoneRequested(
    AuthSignInWithPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    // This will be handled by the data source callbacks
    // The state will be updated when code is sent
  }

  Future<void> _onVerifyPhoneCodeRequested(
    AuthVerifyPhoneCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    // Phone verification will be implemented in the data source
    emit(const AuthError('Phone verification not yet implemented'));
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await repository.signOut();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await repository.sendPasswordResetEmail(event.email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthPasswordResetSent()),
    );
  }

  Future<void> _onEmailVerificationRequested(
    AuthEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await repository.sendEmailVerification();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthEmailVerificationSent()),
    );
  }

  Future<void> _onBiometricSignInRequested(
    AuthBiometricSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final canCheckBiometrics = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        emit(const AuthError('Biometric authentication not available'));
        return;
      }

      final authenticated = await localAuth.authenticate(
        localizedReason: 'Please authenticate to sign in',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        // If biometric auth succeeds, check for stored credentials
        // This is a simplified version - in production, you'd retrieve
        // stored credentials securely and use them to sign in
        final result = await repository.getCurrentUser();
        result.fold(
          (failure) => emit(const AuthUnauthenticated()),
          (user) => user != null
              ? emit(AuthAuthenticated(user))
              : emit(const AuthError('No stored credentials found')),
        );
      } else {
        emit(const AuthError('Biometric authentication failed'));
      }
    } catch (e) {
      emit(AuthError('Biometric error: ${e.toString()}'));
    }
  }
}
