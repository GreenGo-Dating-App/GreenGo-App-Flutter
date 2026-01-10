import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/profile.dart';

abstract class ProfileRepository {
  /// Create a new profile
  Future<Either<Failure, Profile>> createProfile(Profile profile);

  /// Get profile by user ID
  Future<Either<Failure, Profile>> getProfile(String userId);

  /// Update existing profile
  Future<Either<Failure, Profile>> updateProfile(Profile profile);

  /// Delete profile
  Future<Either<Failure, void>> deleteProfile(String userId);

  /// Upload profile photo
  Future<Either<Failure, String>> uploadPhoto(String userId, File photo, {String? folder});

  /// Delete profile photo
  Future<Either<Failure, void>> deletePhoto(String userId, String photoUrl);

  /// Upload voice recording
  Future<Either<Failure, String>> uploadVoiceRecording(
      String userId, File recording);

  /// Verify photo with AI (checks if it's a real face)
  Future<Either<Failure, bool>> verifyPhotoWithAI(File photo);

  /// Check if profile exists
  Future<Either<Failure, bool>> profileExists(String userId);

  /// Get profile completion percentage
  Future<Either<Failure, int>> getProfileCompletion(String userId);
}
