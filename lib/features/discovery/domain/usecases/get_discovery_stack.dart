import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../matching/domain/entities/match_candidate.dart';
import '../entities/match_preferences.dart';
import '../repositories/discovery_repository.dart';

/// Get Discovery Stack Use Case
///
/// Retrieves a stack of potential matches for the user to swipe through
class GetDiscoveryStack
    implements UseCase<List<MatchCandidate>, GetDiscoveryStackParams> {

  GetDiscoveryStack(this.repository);
  final DiscoveryRepository repository;

  @override
  Future<Either<Failure, List<MatchCandidate>>> call(
    GetDiscoveryStackParams params,
  ) async {
    return repository.getDiscoveryStack(
      userId: params.userId,
      preferences: params.preferences,
      limit: params.limit,
      forceRefresh: params.forceRefresh,
    );
  }
}

class GetDiscoveryStackParams {

  GetDiscoveryStackParams({
    required this.userId,
    required this.preferences,
    this.limit = 20,
    this.forceRefresh = false,
  });
  final String userId;
  final MatchPreferences preferences;
  final int limit;
  final bool forceRefresh;
}
