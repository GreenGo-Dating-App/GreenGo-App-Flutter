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
      isPrivate: params.isPrivate,
      requireFace: params.requireFace,
    );
  }
}

class UploadPhotoParams {

  UploadPhotoParams({
    required this.userId,
    required this.photo,
    this.folder,
    this.isPrivate = false,
    this.requireFace = false,
  });
  final String userId;
  final XFile photo;
  final String? folder;

  /// Private-album photo: exempt from the NSFW check by product decision.
  final bool isPrivate;

  /// Main profile photo: must contain a face (no headless photos).
  final bool requireFace;
}
