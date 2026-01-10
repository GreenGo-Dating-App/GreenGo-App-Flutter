import 'package:flutter_bloc/flutter_bloc.dart';
// Conditional import - uncomment when AppConfig.enableBiometricAuth = true
// import 'package:local_auth/local_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/access_control_service.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  final dynamic localAuth; // Will be LocalAuthentication when biometric is enabled
  final AccessControlService _accessControlService;

  AuthBloc({
    required this.repository,
    this.localAuth,
    AccessControlService? accessControlService,
  }) : _accessControlService = accessControlService ?? AccessControlService(),
       super(const AuthInitial()) {
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
    on<AuthCheckAccessStatusRequested>(_onCheckAccessStatusRequested);
    on<AuthEnableNotificationsRequested>(_onEnableNotificationsRequested);
    on<_AuthStateChanged>(_onAuthStateChanged);

    // Listen to auth state changes and dispatch events
    repository.authStateChanges.listen((user) {
      add(_AuthStateChanged(user));
    });
  }

  Future<void> _onAuthStateChanged(
    _AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user != null) {
      emit(AuthAuthenticated(event.user!));
    } else {
      emit(const AuthUnauthenticated());
    }
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
    if (!AppConfig.enableGoogleAuth) {
      emit(const AuthError(
        'Google Sign-In is not enabled. Enable it in AppConfig.',
      ));
      return;
    }

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
    if (!AppConfig.enableFacebookAuth) {
      emit(const AuthError(
        'Facebook Login is not enabled. Enable it in AppConfig.',
      ));
      return;
    }

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
    if (!AppConfig.enableBiometricAuth) {
      emit(const AuthError(
        'Biometric authentication is not enabled. Enable it in AppConfig.',
      ));
      return;
    }

    if (localAuth == null) {
      emit(const AuthError(
        'Biometric authentication not configured. Add local_auth package.',
      ));
      return;
    }

    try {
      final canCheckBiometrics = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        emit(const AuthError('Biometric authentication not available on this device'));
        return;
      }

      // Call authenticate - using dynamic invocation to avoid import dependencies
      // When local_auth is enabled, uncomment the import and use proper types
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Please authenticate to sign in',
      ) as bool;

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

  Future<void> _onCheckAccessStatusRequested(
    AuthCheckAccessStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Check if app is in pre-launch mode
    if (!_accessControlService.isPreLaunchMode) {
      // After launch, all approved users can access
      final result = await repository.getCurrentUser();
      result.fold(
        (failure) => emit(const AuthUnauthenticated()),
        (user) => user != null
            ? emit(AuthAuthenticated(user))
            : emit(const AuthUnauthenticated()),
      );
      return;
    }

    // Pre-launch mode: check access status
    final accessData = await _accessControlService.getCurrentUserAccess();
    if (accessData == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    final result = await repository.getCurrentUser();
    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (user) {
        if (user == null) {
          emit(const AuthUnauthenticated());
          return;
        }

        // Check if user can access the app
        if (accessData.canAccessApp) {
          emit(AuthAuthenticated(user));
        } else {
          // User needs to wait
          emit(AuthWaitingForAccess(
            user: user,
            approvalStatus: accessData.approvalStatus.name,
            accessDate: accessData.accessDate,
            membershipTier: accessData.membershipTier.name,
            canAccessApp: accessData.canAccessApp,
          ));
        }
      },
    );
  }

  Future<void> _onEnableNotificationsRequested(
    AuthEnableNotificationsRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await repository.getCurrentUser();
    result.fold(
      (failure) => null,
      (user) async {
        if (user != null) {
          await _accessControlService.enableNotifications(user.id);
        }
      },
    );
  }
}

/// Private event for auth state changes from Firebase stream
class _AuthStateChanged extends AuthEvent {
  final dynamic user;

  const _AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}
