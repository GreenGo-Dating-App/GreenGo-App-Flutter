import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile implements UseCase<Profile, UpdateProfileParams> {
  final ProfileRepository repository;

  UpdateProfile(this.repository);

  @override
  Future<Either<Failure, Profile>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(params.profile);
  }
}

class UpdateProfileParams {
  final Profile profile;

  UpdateProfileParams({required this.profile});
}
