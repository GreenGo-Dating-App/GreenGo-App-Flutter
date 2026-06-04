import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/profile_repository.dart';

class VerifyPhoto implements UseCase<bool, VerifyPhotoParams> {

  VerifyPhoto(this.repository);
  final ProfileRepository repository;

  @override
  Future<Either<Failure, bool>> call(VerifyPhotoParams params) async {
    return repository.verifyPhotoWithAI(params.photo);
  }
}

class VerifyPhotoParams {

  VerifyPhotoParams({required this.photo});
  final File photo;
}
