import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tier_config.dart';
import '../../../membership/domain/entities/membership.dart';

/// Tier Config Repository Interface
abstract class TierConfigRepository {
  /// Get all tier configurations
  Future<Either<Failure, List<TierConfig>>> getTierConfigs();

  /// Get config for a specific tier
  Future<Either<Failure, TierConfig?>> getTierConfig(MembershipTier tier);

  /// Update a tier configuration
  Future<Either<Failure, void>> updateTierConfig(
    TierConfig config,
    String adminId,
  );

  /// Reset tier to default configuration
  Future<Either<Failure, void>> resetTierToDefaults(
    MembershipTier tier,
    String adminId,
  );

  /// Initialize default configs if they don't exist
  Future<Either<Failure, void>> initializeDefaultConfigs();

  /// Stream of tier configs for real-time updates
  Stream<List<TierConfig>> watchTierConfigs();
}
