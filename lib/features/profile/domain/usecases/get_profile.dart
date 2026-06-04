import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile implements UseCase<Profile, GetProfileParams> {

  GetProfile(this.repository);
  final ProfileRepository repository;

  @override
  Future<Either<Failure, Profile>> call(GetProfileParams params) async {
    return repository.getProfile(params.userId);
  }
}

class GetProfileParams {

  GetProfileParams({required this.userId});
  final String userId;
}
