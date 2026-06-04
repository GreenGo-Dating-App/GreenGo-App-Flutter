import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match.dart';
import '../repositories/discovery_repository.dart';

/// Get Matches Use Case
///
/// Retrieves the user's matches
class GetMatches implements UseCase<List<Match>, GetMatchesParams> {

  GetMatches(this.repository);
  final DiscoveryRepository repository;

  @override
  Future<Either<Failure, List<Match>>> call(GetMatchesParams params) async {
    return repository.getMatches(
      userId: params.userId,
      activeOnly: params.activeOnly,
    );
  }
}

class GetMatchesParams {

  GetMatchesParams({
    required this.userId,
    this.activeOnly = true,
  });
  final String userId;
  final bool activeOnly;
}
