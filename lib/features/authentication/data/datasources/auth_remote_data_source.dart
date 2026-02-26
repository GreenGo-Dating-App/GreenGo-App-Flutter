import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// Conditional imports - uncomment when enabling features in AppConfig
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  /// Sign in with email and password
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  /// Register with email and password
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google
  Future<UserModel> signInWithGoogle();

  /// Sign in with Apple
  // Future<UserModel> signInWithApple();

  /// Sign in with Facebook
  Future<UserModel> signInWithFacebook();

  /// Sign out
  Future<void> signOut();

  /// Get current user
  Future<UserModel?> getCurrentUser();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Send email verification
  Future<void> sendEmailVerification();

  /// Verify phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(firebase_auth.FirebaseAuthException error) verificationFailed,
  });

  /// Sign in with phone credential
  Future<UserModel> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  });

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Re-authenticate user
  Future<void> reAuthenticateWithCredential({
    required String email,
    required String password,
  });

  /// Update password
  Future<void> updatePassword(String newPassword);

  /// Delete account
  Future<void> deleteAccount();

  /// Check if user is signed in
  Future<bool> isSignedIn();

  /// Get auth state changes stream
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final dynamic googleSignIn; // Will be GoogleSignIn? when enabled
  final dynamic facebookAuth; // Will be FacebookAuth? when enabled

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    this.googleSignIn,
    this.facebookAuth,
  });

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Check if input is a nickname rather than an email
      // Strip leading '@' since users often type @nickname
      String input = email.trim();
      if (input.startsWith('@')) {
        input = input.substring(1);
      }
      String resolvedEmail = input;
      if (!input.contains('@')) {
        // Treat as nickname - look up email from Firestore profiles
        resolvedEmail = await _resolveNicknameToEmail(input);
      }

      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthenticationException('Sign in failed');
      }

      // Store email on profile and users docs so nickname login works for all users
      final uid = userCredential.user!.uid;
      final firestore = FirebaseFirestore.instance;
      try {
        firestore.collection('profiles').doc(uid).update({'email': resolvedEmail});
        firestore.collection('users').doc(uid).set({'email': resolvedEmail}, SetOptions(merge: true));
      } catch (_) {}

      return UserModel.fromFirebaseUser(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      // Check if the error message contains network-related keywords
      final message = e.toString().toLowerCase();
      if (message.contains('network') ||
          message.contains('connection') ||
          message.contains('internet') ||
          message.contains('timeout') ||
          message.contains('unreachable') ||
          message.contains('host') ||
          message.contains('socket')) {
        throw AuthenticationException('NETWORK_ERROR: Please check your internet connection');
      }
      throw AuthenticationException(e.toString());
    }
  }

  /// Resolve a nickname to an email address by querying Firestore profiles
  Future<String> _resolveNicknameToEmail(String nickname) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final normalizedNickname = nickname.toLowerCase().replaceAll('@', '');

      // Query profiles collection for this nickname
      final querySnapshot = await firestore
          .collection('profiles')
          .where('nickname', isEqualTo: normalizedNickname)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw AuthenticationException('No account found with nickname "@$normalizedNickname"');
      }

      final profileData = querySnapshot.docs.first.data();
      final userId = querySnapshot.docs.first.id;

      // 1. Check if email is stored in the profile document
      if (profileData['email'] != null && (profileData['email'] as String).isNotEmpty) {
        return profileData['email'] as String;
      }

      // 2. Check the 'users' collection
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data()?['email'] != null) {
        return userDoc.data()!['email'] as String;
      }

      // 3. Fallback: check displayName field which sometimes contains email
      // This shouldn't normally happen — the email gets stored on first login
      throw AuthenticationException(
        'Email not found for nickname "@$normalizedNickname". '
        'Please log in with your email first, then nickname login will work.',
      );
    } on AuthenticationException {
      rethrow;
    } catch (e) {
      throw AuthenticationException('Failed to look up nickname: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthenticationException('Registration failed');
      }

      // Store email on users doc so nickname login works
      final uid = userCredential.user!.uid;
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'email': email}, SetOptions(merge: true))
          .catchError((_) => null);

      // Send branded welcome email via Resend (fire-and-forget, don't block registration)
      FirebaseFunctions.instance
          .httpsCallable('sendWelcomeEmail')
          .call({'email': email})
          .catchError((_) => null);

      return UserModel.fromFirebaseUser(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Try to clean up orphaned Auth user (no profile in Firestore)
        try {
          final result = await FirebaseFunctions.instance
              .httpsCallable('cleanupOrphanedAuthUser')
              .call({'email': email});
          final cleaned = result.data['cleaned'] == true;
          if (cleaned) {
            // Orphan removed — retry registration
            final retryCredential =
                await firebaseAuth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            if (retryCredential.user == null) {
              throw AuthenticationException('Registration failed');
            }
            // Send branded welcome email via Resend
            FirebaseFunctions.instance
                .httpsCallable('sendWelcomeEmail')
                .call({'email': email})
                .catchError((_) => null);
            return UserModel.fromFirebaseUser(retryCredential.user!);
          }
        } catch (_) {
          // Cleanup failed or email belongs to an active account — fall through
        }
      }
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthenticationException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    if (!AppConfig.enableGoogleAuth || googleSignIn == null) {
      throw AuthenticationException(
        'Google Sign-In is not enabled or configured. Enable it in AppConfig and add google_sign_in package.',
      );
    }

    try {
      // Trigger the authentication flow
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthenticationException('Google sign in aborted');
      }

      // Obtain the auth details from the request
      final googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw AuthenticationException('Google sign in failed');
      }

      return UserModel.fromFirebaseUser(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthenticationException(e.toString());
    }
  }

  // @override
  // Future<UserModel> signInWithApple() async {
  //   try {
  //     // Request credential from Apple
  //     final appleCredential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName,
  //       ],
  //     );

  //     // Create OAuth credential
  //     final oauthCredential = firebase_auth.OAuthProvider('apple.com').credential(
  //       idToken: appleCredential.identityToken,
  //       accessToken: appleCredential.authorizationCode,
  //     );

  //     // Sign in to Firebase
  //     final userCredential = await firebaseAuth.signInWithCredential(oauthCredential);

  //     if (userCredential.user == null) {
  //       throw AuthenticationException('Apple sign in failed');
  //     }

  //     // Update display name if available
  //     if (appleCredential.givenName != null || appleCredential.familyName != null) {
  //       final displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
  //       await userCredential.user!.updateDisplayName(displayName);
  //     }

  //     return UserModel.fromFirebaseUser(userCredential.user!);
  //   } on firebase_auth.FirebaseAuthException catch (e) {
  //     throw _handleFirebaseAuthException(e);
  //   } catch (e) {
  //     throw AuthenticationException(e.toString());
  //   }
  // }

  @override
  Future<UserModel> signInWithFacebook() async {
    if (!AppConfig.enableFacebookAuth || facebookAuth == null) {
      throw AuthenticationException(
        'Facebook Login is not enabled or configured. Enable it in AppConfig and add flutter_facebook_auth package.',
      );
    }

    try {
      // Trigger the sign-in flow
      final loginResult = await facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      if (loginResult.status.toString() != 'LoginStatus.success') {
        throw AuthenticationException('Facebook sign in failed: ${loginResult.message}');
      }

      // Create a credential from the access token
      final firebase_auth.OAuthCredential facebookAuthCredential =
          firebase_auth.FacebookAuthProvider.credential(
        loginResult.accessToken!.token,
      );

      // Sign in to Firebase
      final userCredential = await firebaseAuth.signInWithCredential(facebookAuthCredential);

      if (userCredential.user == null) {
        throw AuthenticationException('Facebook sign in failed');
      }

      return UserModel.fromFirebaseUser(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthenticationException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final futures = <Future>[
        firebaseAuth.signOut(),
      ];

      // Only sign out from social providers if they're enabled
      if (AppConfig.enableGoogleAuth && googleSignIn != null) {
        futures.add(googleSignIn.signOut());
      }
      if (AppConfig.enableFacebookAuth && facebookAuth != null) {
        futures.add(facebookAuth.logOut());
      }

      await Future.wait(futures);
    } catch (e) {
      throw AuthenticationException('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return null;
      return UserModel.fromFirebaseUser(user);
    } catch (e) {
      throw AuthenticationException('Failed to get current user: ${e.toString()}');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthenticationException(e.toString());
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw AuthenticationException('No user signed in');
      }
      await user.sendEmailVerification();
    } catch (e) {
      throw AuthenticationException('Failed to send verification email: ${e.toString()}');
    }
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(firebase_auth.FirebaseAuthException error) verificationFailed,
  }) async {
    try {
      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
          await firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: verificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      throw AuthenticationException('Phone verification failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw AuthenticationException('Phone sign in failed');
      }

      return UserModel.fromFirebaseUser(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthenticationException(e.toString());
    }
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw AuthenticationException('No user signed in');
      }

      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoUrl);
    } catch (e) {
      throw AuthenticationException('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<void> reAuthenticateWithCredential({
    required String email,
    required String password,
  }) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw AuthenticationException('No user signed in');
      }

      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthenticationException(e.toString());
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw AuthenticationException('No user signed in');
      }
      await user.updatePassword(newPassword);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      throw AuthenticationException('Failed to update password: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw AuthenticationException('No user signed in');
      }

      await user.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthenticationException(e.toString());
    }
  }

  @override
  Future<bool> isSignedIn() async {
    final user = firebaseAuth.currentUser;
    return user != null;
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return UserModel.fromFirebaseUser(firebaseUser);
    });
  }

  // Helper method to handle Firebase Auth exceptions
  AuthenticationException _handleFirebaseAuthException(
    firebase_auth.FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'user-not-found':
        return AuthenticationException('No user found with this email');
      case 'wrong-password':
        return AuthenticationException('Wrong password');
      case 'email-already-in-use':
        return AuthenticationException('Email already in use');
      case 'weak-password':
        return AuthenticationException('Password is too weak');
      case 'invalid-email':
        return AuthenticationException('Invalid email address');
      case 'user-disabled':
        return AuthenticationException('This account has been disabled');
      case 'too-many-requests':
        return AuthenticationException('Too many requests. Please try again later');
      case 'operation-not-allowed':
        return AuthenticationException('This operation is not allowed');
      case 'network-request-failed':
        return AuthenticationException('NETWORK_ERROR: Please check your internet connection');
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return AuthenticationException('Invalid email/nickname or password');
      default:
        // Check if the error message contains network-related keywords
        final message = (e.message ?? '').toLowerCase();
        if (message.contains('network') ||
            message.contains('connection') ||
            message.contains('internet') ||
            message.contains('timeout') ||
            message.contains('unreachable') ||
            message.contains('host')) {
          return AuthenticationException('NETWORK_ERROR: Please check your internet connection');
        }
        return AuthenticationException(e.message ?? 'Authentication failed');
    }
  }
}
