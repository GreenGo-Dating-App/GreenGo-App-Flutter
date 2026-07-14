# Complete Implementation Guide: Points 31-60

## Status: Implementation In Progress

This document provides the complete code implementation for points 31-60 of the GreenGoChat blueprint.

---

## ✅ Already Implemented Files

### Authentication Data Layer (Points 31-40)
1. ✅ `lib/features/authentication/domain/usecases/sign_in_with_email.dart`
2. ✅ `lib/features/authentication/domain/usecases/register_with_email.dart`
3. ✅ `lib/features/authentication/data/datasources/auth_remote_data_source.dart` - Complete OAuth implementation
4. ✅ `lib/features/authentication/data/repositories/auth_repository_impl.dart`
5. ✅ `lib/features/authentication/data/models/user_model.dart` - Updated with Firebase Auth import

---

## 🚧 Files To Create

### PHASE 1: Authentication BLoC & UI (Points 31-40)

#### 1. Authentication BLoC

**File**: `lib/features/authentication/presentation/bloc/auth_bloc.dart`
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/register_with_email.dart';
import '../../domain/repositories/auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;

  AuthSignInWithEmailRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthRegisterWithEmailRequested extends AuthEvent {
  final String email;
  final String password;

  AuthRegisterWithEmailRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthSignInWithGoogleRequested extends AuthEvent {}
class AuthSignInWithAppleRequested extends AuthEvent {}
class AuthSignInWithFacebookRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  AuthPasswordResetRequested(this.email);

  @override
  List<Object> get props => [email];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class AuthPasswordResetSent extends AuthState {}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  final SignInWithEmail signInWithEmail;
  final RegisterWithEmail registerWithEmail;

  AuthBloc({
    required this.repository,
    required this.signInWithEmail,
    required this.registerWithEmail,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInWithEmailRequested>(_onSignInWithEmailRequested);
    on<AuthRegisterWithEmailRequested>(_onRegisterWithEmailRequested);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<AuthSignInWithAppleRequested>(_onSignInWithAppleRequested);
    on<AuthSignInWithFacebookRequested>(_onSignInWithFacebookRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);

    // Listen to auth state changes
    repository.authStateChanges.listen((user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await repository.getCurrentUser();
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) => user != null
          ? emit(AuthAuthenticated(user))
          : emit(AuthUnauthenticated()),
    );
  }

  Future<void> _onSignInWithEmailRequested(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await signInWithEmail(
      SignInWithEmailParams(email: event.email, password: event.password),
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
    emit(AuthLoading());
    final result = await registerWithEmail(
      RegisterWithEmailParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await repository.signInWithGoogle();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignInWithAppleRequested(
    AuthSignInWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await repository.signInWithApple();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignInWithFacebookRequested(
    AuthSignInWithFacebookRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await repository.signInWithFacebook();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await repository.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await repository.sendPasswordResetEmail(event.email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthPasswordResetSent()),
    );
  }
}
```

#### 2. Login Screen (Point 32)

**File**: `lib/features/authentication/presentation/screens/login_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthSignInWithEmailRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            } else if (state is AuthAuthenticated) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    // Logo and Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.goldGradient,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              size: 60,
                              color: AppColors.deepBlack,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            AppStrings.appName,
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(color: AppColors.richGold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.appTagline,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Form Fields
                    SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          // Email Field
                          AuthTextField(
                            controller: _emailController,
                            label: AppStrings.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                            prefixIcon: Icons.email_outlined,
                            enabled: !isLoading,
                          ),

                          const SizedBox(height: 16),

                          // Password Field
                          AuthTextField(
                            controller: _passwordController,
                            label: AppStrings.password,
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.passwordRequired;
                              }
                              return null;
                            },
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textTertiary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            enabled: !isLoading,
                          ),

                          const SizedBox(height: 8),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context)
                                          .pushNamed('/forgot-password');
                                    },
                              child: Text(
                                AppStrings.forgotPassword,
                                style: TextStyle(
                                  color: AppColors.richGold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login Button
                          AuthButton(
                            text: AppStrings.login,
                            onPressed: isLoading ? null : _handleLogin,
                            isLoading: isLoading,
                          ),

                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider(color: AppColors.divider)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  AppStrings.orContinueWith,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              const Expanded(child: Divider(color: AppColors.divider)),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Social Login Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SocialLoginButton(
                                icon: 'assets/icons/google.png',
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        context.read<AuthBloc>().add(
                                              AuthSignInWithGoogleRequested(),
                                            );
                                      },
                              ),
                              SocialLoginButton(
                                icon: 'assets/icons/apple.png',
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        context.read<AuthBloc>().add(
                                              AuthSignInWithAppleRequested(),
                                            );
                                      },
                              ),
                              SocialLoginButton(
                                icon: 'assets/icons/facebook.png',
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        context.read<AuthBloc>().add(
                                              AuthSignInWithFacebookRequested(),
                                            );
                                      },
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppStrings.dontHaveAccount,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context)
                                            .pushReplacementNamed('/register');
                                      },
                                child: Text(
                                  AppStrings.signUp,
                                  style: TextStyle(
                                    color: AppColors.richGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

#### 3. Registration Screen (Point 33)

**File**: `lib/features/authentication/presentation/screens/register_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../widgets/password_strength_indicator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() {
      _passwordStrength = Validators.getPasswordStrength(_passwordController.text);
    });
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthRegisterWithEmailRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            } else if (state is AuthAuthenticated) {
              Navigator.of(context).pushReplacementNamed('/onboarding');
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppColors.richGold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join GreenGoChat and find your perfect match',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),

                    const SizedBox(height: 40),

                    // Email Field
                    AuthTextField(
                      controller: _emailController,
                      label: AppStrings.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                      prefixIcon: Icons.email_outlined,
                      enabled: !isLoading,
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    AuthTextField(
                      controller: _passwordController,
                      label: AppStrings.password,
                      obscureText: _obscurePassword,
                      validator: Validators.validatePassword,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textTertiary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      enabled: !isLoading,
                    ),

                    const SizedBox(height: 8),

                    // Password Strength Indicator
                    PasswordStrengthIndicator(strength: _passwordStrength),

                    const SizedBox(height: 16),

                    // Confirm Password Field
                    AuthTextField(
                      controller: _confirmPasswordController,
                      label: AppStrings.confirmPassword,
                      obscureText: _obscureConfirmPassword,
                      validator: (value) => Validators.validateConfirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textTertiary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      enabled: !isLoading,
                    ),

                    const SizedBox(height: 32),

                    // Register Button
                    AuthButton(
                      text: AppStrings.register,
                      onPressed: isLoading ? null : _handleRegister,
                      isLoading: isLoading,
                    ),

                    const SizedBox(height: 24),

                    // Sign In Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.alreadyHaveAccount,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.of(context)
                                      .pushReplacementNamed('/login');
                                },
                          child: Text(
                            AppStrings.signIn,
                            style: TextStyle(
                              color: AppColors.richGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

## 📋 Complete File List for Points 31-60

Due to the extensive scope, here's the complete list of files that need to be created:

### Authentication (Points 31-40): 15 files
1. ✅ Auth use cases (2 files)
2. ✅ Auth data sources (1 file)
3. ✅ Auth repository impl (1 file)
4. 🔨 Auth BLoC (1 file) - Code provided above
5. 🔨 Login screen (1 file) - Code provided above
6. 🔨 Register screen (1 file) - Code provided above
7. 🔨 Forgot password screen (1 file)
8. 🔨 Phone auth screen (1 file)
9. 🔨 2FA screen (1 file)
10. 🔨 Biometric auth (1 file)
11. 🔨 Auth widgets (5 files)

### Profile Creation (Points 41-50): 20+ files
12. 🔨 Profile entities & models (3 files)
13. 🔨 Profile repository (2 files)
14. 🔨 Profile use cases (5 files)
15. 🔨 Profile BLoC (1 file)
16. 🔨 Onboarding screens (7 files)
17. 🔨 Profile widgets (10+ files)

### User Data Management (Points 51-60): 15+ files
18. ✅ Firestore rules (already complete)
19. ✅ Storage rules (already complete)
20. 🔨 Photo compression functions (2 files)
21. 🔨 Cloud Functions for photo processing (3 files)
22. 🔨 GDPR export/deletion (4 files)
23. 🔨 Activity tracking (2 files)
24. 🔨 Reporting system (3 files)

### **Total**: ~50+ files to complete points 31-60

---

## ⏱️ Estimated Completion Time

With the foundation in place:
- **Authentication (31-40)**: 5-7 days
- **Profile Creation (41-50)**: 10-14 days
- **Data Management (51-60)**: 7-10 days

**Total**: 22-31 days with 1 developer

---

## 🎯 Next Steps

1. Create remaining auth screens
2. Build profile creation flow
3. Implement Cloud Functions
4. Add photo processing
5. Build GDPR features

Would you like me to:
1. Continue creating all remaining files?
2. Focus on specific sections?
3. Provide implementation for specific features?
