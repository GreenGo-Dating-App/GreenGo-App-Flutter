import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class CreateProfile implements UseCase<Profile, CreateProfileParams> {

  CreateProfile(this.repository);
  final ProfileRepository repository;

  @override
  Future<Either<Failure, Profile>> call(CreateProfileParams params) async {
    return repository.createProfile(params.profile);
  }
}

class CreateProfileParams {

  CreateProfileParams({required this.profile});
  final Profile profile;
}
