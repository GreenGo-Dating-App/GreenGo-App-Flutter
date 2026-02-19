import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/repositories/verification_admin_repository.dart';
import '../datasources/verification_admin_remote_data_source.dart';

class VerificationAdminRepositoryImpl implements VerificationAdminRepository {
  final VerificationAdminRemoteDataSource remoteDataSource;

  VerificationAdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Profile>>> getPendingVerifications() async {
    try {
      final result = await remoteDataSource.getPendingVerifications();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Profile>>> getVerificationHistory({int limit = 50}) async {
    try {
      final result = await remoteDataSource.getVerificationHistory(limit: limit);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveVerification(String userId, String adminId) async {
    try {
      await remoteDataSource.approveVerification(userId, adminId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectVerification(
    String userId,
    String adminId,
    String reason,
  ) async {
    try {
      await remoteDataSource.rejectVerification(userId, adminId, reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> requestBetterPhoto(
    String userId,
    String adminId,
    String reason,
  ) async {
    try {
      await remoteDataSource.requestBetterPhoto(userId, adminId, reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> bulkApproveVerifications(
    List<String> userIds,
    String adminId,
  ) async {
    try {
      await remoteDataSource.bulkApproveVerifications(userIds, adminId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> bulkRequestBetterPhoto(
    List<String> userIds,
    String adminId,
    String reason,
  ) async {
    try {
      await remoteDataSource.bulkRequestBetterPhoto(userIds, adminId, reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
