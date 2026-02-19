import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../profile/domain/entities/profile.dart';

abstract class VerificationAdminRepository {
  /// Get all profiles with pending verification
  Future<Either<Failure, List<Profile>>> getPendingVerifications();

  /// Get verification history (approved/rejected)
  Future<Either<Failure, List<Profile>>> getVerificationHistory({int limit = 50});

  /// Approve a user's verification
  Future<Either<Failure, void>> approveVerification(String userId, String adminId);

  /// Reject a user's verification
  Future<Either<Failure, void>> rejectVerification(
    String userId,
    String adminId,
    String reason,
  );

  /// Request better verification photo
  Future<Either<Failure, void>> requestBetterPhoto(
    String userId,
    String adminId,
    String reason,
  );

  /// Bulk approve verifications
  Future<Either<Failure, void>> bulkApproveVerifications(
    List<String> userIds,
    String adminId,
  );

  /// Bulk request better photo
  Future<Either<Failure, void>> bulkRequestBetterPhoto(
    List<String> userIds,
    String adminId,
    String reason,
  );
}
