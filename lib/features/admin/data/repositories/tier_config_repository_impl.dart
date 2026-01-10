import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/tier_config.dart';
import '../../domain/repositories/tier_config_repository.dart';
import '../datasources/tier_config_datasource.dart';
import '../../../membership/domain/entities/membership.dart';

/// Implementation of TierConfigRepository
class TierConfigRepositoryImpl implements TierConfigRepository {
  final TierConfigRemoteDataSource remoteDataSource;

  TierConfigRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<TierConfig>>> getTierConfigs() async {
    try {
      final configs = await remoteDataSource.getTierConfigs();
      return Right(configs.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TierConfig?>> getTierConfig(
    MembershipTier tier,
  ) async {
    try {
      final config = await remoteDataSource.getTierConfig(tier);
      return Right(config?.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTierConfig(
    TierConfig config,
    String adminId,
  ) async {
    try {
      await remoteDataSource.updateTierConfig(config, adminId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetTierToDefaults(
    MembershipTier tier,
    String adminId,
  ) async {
    try {
      await remoteDataSource.resetTierToDefaults(tier, adminId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> initializeDefaultConfigs() async {
    try {
      await remoteDataSource.initializeDefaultConfigs();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<TierConfig>> watchTierConfigs() {
    return remoteDataSource
        .watchTierConfigs()
        .map((models) => models.map((m) => m.toEntity()).toList());
  }
}
