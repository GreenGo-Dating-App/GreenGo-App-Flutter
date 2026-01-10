import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Profile>> createProfile(Profile profile) async {
    try {
      final profileModel = ProfileModel.fromEntity(profile);
      final result = await remoteDataSource.createProfile(profileModel);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure( e.message));
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, Profile>> getProfile(String userId) async {
    try {
      final result = await remoteDataSource.getProfile(userId);
      return Right(result);
    } on CacheException catch (e) {
      return Left(CacheFailure( e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure( e.message));
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, Profile>> updateProfile(Profile profile) async {
    try {
      final profileModel = ProfileModel.fromEntity(profile);
      final result = await remoteDataSource.updateProfile(profileModel);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure( e.message));
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProfile(String userId) async {
    try {
      await remoteDataSource.deleteProfile(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure( e.message));
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadPhoto(String userId, File photo, {String? folder}) async {
    try {
      final result = await remoteDataSource.uploadPhoto(userId, photo, folder: folder);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure( e.message));
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePhoto(
      String userId, String photoUrl) async {
    try {
      await remoteDataSource.deletePhoto(userId, photoUrl);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure( e.message));
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadVoiceRecording(
      String userId, File recording) async {
    try {
      final result = await remoteDataSource.uploadVoiceRecording(userId, recording);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure( e.message));
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPhotoWithAI(File photo) async {
    try {
      final result = await remoteDataSource.verifyPhotoWithAI(photo);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure( e.message));
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> profileExists(String userId) async {
    try {
      final result = await remoteDataSource.profileExists(userId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure( e.message));
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getProfileCompletion(String userId) async {
    try {
      final result = await remoteDataSource.getProfileCompletion(userId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure( e.message));
    } catch (e) {
      return Left(ServerFailure( e.toString()));
    }
  }
}
