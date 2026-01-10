import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/video_call.dart';
import '../repositories/video_calling_repository.dart';

/// Get Call History Use Case
class GetCallHistory {
  final VideoCallingRepository repository;

  GetCallHistory(this.repository);

  Future<Either<Failure, List<CallHistoryEntry>>> call(
      GetCallHistoryParams params) {
    return repository.getCallHistory(
      userId: params.userId,
      limit: params.limit,
      before: params.before,
    );
  }
}

/// Parameters for GetCallHistory use case
class GetCallHistoryParams {
  final String userId;
  final int limit;
  final DateTime? before;

  GetCallHistoryParams({
    required this.userId,
    this.limit = 50,
    this.before,
  });
}
