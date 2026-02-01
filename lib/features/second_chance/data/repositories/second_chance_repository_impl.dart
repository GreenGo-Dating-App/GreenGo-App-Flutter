import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/second_chance.dart';
import '../../domain/repositories/second_chance_repository.dart';
import '../datasources/second_chance_remote_datasource.dart';

/// Implementation of Second Chance repository
class SecondChanceRepositoryImpl implements SecondChanceRepository {
  final SecondChanceRemoteDataSource remoteDataSource;

  SecondChanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<SecondChanceProfile>>> getSecondChanceProfiles(
    String userId,
  ) async {
    try {
      final profiles = await remoteDataSource.getSecondChanceProfiles(userId);
      return Right(profiles);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SecondChanceUsage>> getUsage(String userId) async {
    try {
      final usage = await remoteDataSource.getUsage(userId);
      return Right(usage);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SecondChanceResult>> likeSecondChance({
    required String userId,
    required String entryId,
  }) async {
    try {
      final result = await remoteDataSource.likeSecondChance(
        userId: userId,
        entryId: entryId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> passSecondChance({
    required String userId,
    required String entryId,
  }) async {
    try {
      await remoteDataSource.passSecondChance(
        userId: userId,
        entryId: entryId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SecondChanceUsage>> purchaseUnlimited(
    String userId,
  ) async {
    try {
      final usage = await remoteDataSource.purchaseUnlimited(userId);
      return Right(usage);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<SecondChanceProfile>>> streamSecondChances(
    String userId,
  ) {
    return remoteDataSource
        .streamSecondChances(userId)
        .map((profiles) => Right<Failure, List<SecondChanceProfile>>(profiles));
  }
}
