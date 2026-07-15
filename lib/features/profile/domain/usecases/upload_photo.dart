import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/profile_repository.dart';

class UploadPhoto implements UseCase<String, UploadPhotoParams> {

  UploadPhoto(this.repository);
  final ProfileRepository repository;

  @override
  Future<Either<Failure, String>> call(UploadPhotoParams params) async {
    return repository.uploadPhoto(
      params.userId,
      params.photo,
      folder: params.folder,
    );
  }
}

class UploadPhotoParams {

  UploadPhotoParams({
    required this.userId,
    required this.photo,
    this.folder,
  });
  final String userId;
  final XFile photo;
  final String? folder;
}
