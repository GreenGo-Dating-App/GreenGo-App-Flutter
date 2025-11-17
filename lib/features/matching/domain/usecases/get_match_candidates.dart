import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match_candidate.dart';
import '../entities/match_preferences.dart';
import '../repositories/matching_repository.dart';

/// Get Match Candidates Use Case
///
/// Retrieves potential matches for a user based on their preferences.
/// Uses hybrid matching algorithm combining collaborative and content-based filtering.
class GetMatchCandidates implements UseCase<List<MatchCandidate>, GetMatchCandidatesParams> {
  final MatchingRepository repository;

  GetMatchCandidates(this.repository);

  @override
  Future<Either<Failure, List<MatchCandidate>>> call(
    GetMatchCandidatesParams params,
  ) async {
    return await repository.getHybridMatches(
      userId: params.userId,
      preferences: params.preferences,
      limit: params.limit,
    );
  }
}

class GetMatchCandidatesParams {
  final String userId;
  final MatchPreferences preferences;
  final int limit;

  GetMatchCandidatesParams({
    required this.userId,
    required this.preferences,
    this.limit = 20,
  });
}
