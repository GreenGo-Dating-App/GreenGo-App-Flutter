import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Register with email and password
  Future<Either<Failure, User>> registerWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google
  Future<Either<Failure, User>> signInWithGoogle();

  /// Sign in with Apple
  // Future<Either<Failure, User>> signInWithApple();

  /// Sign in with Facebook
  Future<Either<Failure, User>> signInWithFacebook();

  /// Sign out
  Future<Either<Failure, void>> signOut();

  /// Get current user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Verify email
  Future<Either<Failure, void>> sendEmailVerification();

  /// Update user profile
  Future<Either<Failure, void>> updateProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Check if user is signed in
  Future<Either<Failure, bool>> isSignedIn();

  /// Delete account
  Future<Either<Failure, void>> deleteAccount();

  /// Re-authenticate user
  Future<Either<Failure, void>> reAuthenticateWithCredential({
    required String email,
    required String password,
  });

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;
}
