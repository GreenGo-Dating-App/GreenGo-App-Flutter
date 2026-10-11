import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// Conditional imports - uncomment when enabling features in AppConfig
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';
import 'nickname_sign_in.dart';
import '../../../profile/data/private_profile.dart';

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

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource { // Will be FacebookAuth? when enabled

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    this.googleSignIn,
    this.facebookAuth,
    FirebaseFirestore? firestore,
    NicknameTokenFetcher? nicknameTokenFetcher,
  })  : _firestore = firestore,
        _nicknameTokenFetcher = nicknameTokenFetcher;
  final firebase_auth.FirebaseAuth firebaseAuth;
  final dynamic googleSignIn; // Will be GoogleSignIn? when enabled
  final dynamic facebookAuth;
  final FirebaseFirestore? _firestore;
  final NicknameTokenFetcher? _nicknameTokenFetcher;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // The field accepts "Email / Nickname". A nickname (no '@' once a
      // leading '@' is stripped) signs in through the server, which verifies
      // the password and returns a custom token (INC-2026-001: the email is
      // no longer readable from nicknames/{nick}).
      final nickname = NicknameSignIn.nicknameFromIdentifier(email);
      final firebase_auth.UserCredential userCredential;
      if (nickname != null) {
        final String token;
        try {
          token = await (_nicknameTokenFetcher ?? NicknameSignIn.fetchToken)(
            nickname,
            password,
          );
        } on FirebaseFunctionsException catch (e) {
          throw NicknameSignIn.mapError(e.code, e.details);
        }
        userCredential = await firebaseAuth.signInWithCustomToken(token);
      } else {
        userCredential = await firebaseAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      }

      if (userCredential.user == null) {
        throw AuthenticationException('Sign in failed');
      }

      final uid = userCredential.user!.uid;
      final accountEmail = userCredential.user!.email ??
          (nickname == null ? email.trim() : null);
      try {
        final firestore = _db;
        if (accountEmail != null && accountEmail.isNotEmpty) {
          // Email is private (security P1-4): owner-only profiles_private,
          // never the public profile.
          writePrivateProfile(firestore, uid, {
            'email': accountEmail,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          firestore
              .collection('users')
              .doc(uid)
              .set({'email': accountEmail}, SetOptions(merge: true))
              .catchError((_) => null);
        }
        await _syncNicknameMapping(firestore, uid);
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

  /// Keeps the public `nicknames/{nick}` -> uid mapping (nickname sign-in and
  /// availability) in place for the signed-in user. The doc holds ONLY
  /// `{uid, nickname, createdAt}`: never the email (INC-2026-001; the rules
  /// reject any other key). A legacy doc that still carries the email is
  /// rewritten without it.
  Future<void> _syncNicknameMapping(FirebaseFirestore firestore, String uid) async {
    final profileDoc = await firestore.collection('profiles').doc(uid).get();
    final nick = (profileDoc.data()?['nickname'] as String?)?.trim().toLowerCase();
    if (nick == null || nick.isEmpty || nick.contains('/')) return;
    final ref = firestore.collection('nicknames').doc(nick);
    final existing = await ref.get();
    final data = existing.data();
    if (existing.exists && data?['uid'] != uid) return; // someone else's
    final clean = existing.exists &&
        data!.keys.every((k) => k == 'uid' || k == 'nickname' || k == 'createdAt') &&
        data['nickname'] == nick;
    if (clean) return;
    await ref.set({
      'uid': uid,
      'nickname': nick,
      'createdAt': data?['createdAt'] ?? FieldValue.serverTimestamp(),
    });
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

      // The language picked on the pre-auth screens. Read before the async
      // calls below so the welcome email goes out in the language the user is
      // actually looking at, not English.
      final locale = await LanguageProvider.currentLanguageCode();

      // Store email on users doc so nickname login works. `locale` is kept too
      // so later transactional mail can reuse it without guessing.
      final uid = userCredential.user!.uid;
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'email': email, 'locale': locale}, SetOptions(merge: true))
          .catchError((_) => null);

      // Send branded welcome email via Resend (fire-and-forget, don't block registration)
      FirebaseFunctions.instance
          .httpsCallable('sendWelcomeEmail')
          .call({'email': email, 'locale': locale})
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
            final retryLocale = await LanguageProvider.currentLanguageCode();
            FirebaseFirestore.instance
                .collection('users')
                .doc(retryCredential.user!.uid)
                .set({'email': email, 'locale': retryLocale},
                    SetOptions(merge: true))
                .catchError((_) => null);
            FirebaseFunctions.instance
                .httpsCallable('sendWelcomeEmail')
                .call({'email': email, 'locale': retryLocale})
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
      final facebookAuthCredential =
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
        return AuthenticationException('Invalid email or password');
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
