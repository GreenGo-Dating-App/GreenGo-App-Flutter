import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return Right(user);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.registerWithEmail(
        email: email,
        password: password,
      );
      return Right(user);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();
      return Right(user);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  // @override
  // Future<Either<Failure, User>> signInWithApple() async {
  //   try {
  //     final user = await remoteDataSource.signInWithApple();
  //     return Right(user);
  //   } on AuthenticationException catch (e) {
  //     return Left(AuthenticationFailure(e.message));
  //   } catch (e) {
  //     return Left(AuthenticationFailure(e.toString()));
  //   }
  // }

  @override
  Future<Either<Failure, User>> signInWithFacebook() async {
    try {
      final user = await remoteDataSource.signInWithFacebook();
      return Right(user);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      await remoteDataSource.sendEmailVerification();
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      await remoteDataSource.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isSignedIn() async {
    try {
      final isSignedIn = await remoteDataSource.isSignedIn();
      return Right(isSignedIn);
    } catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await remoteDataSource.deleteAccount();
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reAuthenticateWithCredential({
    required String email,
    required String password,
  }) async {
    try {
      await remoteDataSource.reAuthenticateWithCredential(
        email: email,
        password: password,
      );
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return remoteDataSource.authStateChanges;
  }
}
