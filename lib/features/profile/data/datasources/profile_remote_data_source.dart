import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/photo_validation_service.dart';
import '../../../../core/utils/image_compression.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> createProfile(ProfileModel profile);
  Future<ProfileModel> getProfile(String userId);
  Future<ProfileModel> updateProfile(ProfileModel profile);
  Future<void> deleteProfile(String userId);
  Future<String> uploadPhoto(String userId, File photo, {String? folder});
  Future<void> deletePhoto(String userId, String photoUrl);
  Future<String> uploadVoiceRecording(String userId, File recording);
  Future<bool> verifyPhotoWithAI(File photo);
  Future<bool> profileExists(String userId);
  Future<int> getProfileCompletion(String userId);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ProfileRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  @override
  Future<ProfileModel> createProfile(ProfileModel profile) async {
    try {
      await firestore.collection('profiles').doc(profile.userId).set(
            profile.toJson(),
          );
      return profile;
    } on FirebaseException catch (e) {
      throw ServerException( e.message ?? 'Failed to create profile');
    } catch (e) {
      throw ServerException( e.toString());
    }
  }

  @override
  Future<ProfileModel> getProfile(String userId) async {
    try {
      final doc = await firestore.collection('profiles').doc(userId).get();

      if (!doc.exists) {
        throw CacheException( 'Profile not found');
      }

      // Inject doc.id as userId to ensure it's always present
      return ProfileModel.fromJson({...doc.data()!, 'userId': doc.id});
    } on FirebaseException catch (e) {
      throw ServerException( e.message ?? 'Failed to get profile');
    } catch (e) {
      if (e is CacheException) rethrow;
      throw ServerException( e.toString());
    }
  }

  @override
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    try {
      // Create updated profile with new timestamp, preserving ALL fields
      final updatedProfile = ProfileModel(
        userId: profile.userId,
        displayName: profile.displayName,
        nickname: profile.nickname,
        dateOfBirth: profile.dateOfBirth,
        gender: profile.gender,
        photoUrls: profile.photoUrls,
        privatePhotoUrls: profile.privatePhotoUrls,
        bio: profile.bio,
        interests: profile.interests,
        location: profile.location,
        languages: profile.languages,
        voiceRecordingUrl: profile.voiceRecordingUrl,
        personalityTraits: profile.personalityTraits,
        education: profile.education,
        occupation: profile.occupation,
        lookingFor: profile.lookingFor,
        height: profile.height,
        weight: profile.weight,
        createdAt: profile.createdAt,
        updatedAt: DateTime.now(),
        isComplete: profile.isComplete,
        verificationStatus: profile.verificationStatus,
        verificationPhotoUrl: profile.verificationPhotoUrl,
        verificationRejectionReason: profile.verificationRejectionReason,
        verificationSubmittedAt: profile.verificationSubmittedAt,
        verificationReviewedAt: profile.verificationReviewedAt,
        verificationReviewedBy: profile.verificationReviewedBy,
        isAdmin: profile.isAdmin,
        isSupport: profile.isSupport,
        socialLinks: profile.socialLinks,
        membershipTier: profile.membershipTier,
        membershipStartDate: profile.membershipStartDate,
        membershipEndDate: profile.membershipEndDate,
      );

      await firestore
          .collection('profiles')
          .doc(profile.userId)
          .update(updatedProfile.toJson());

      // Sync displayName, photoUrl, region to user_levels for leaderboard
      try {
        final userLevelDoc = await firestore.collection('user_levels').doc(profile.userId).get();
        if (userLevelDoc.exists) {
          final syncData = <String, dynamic>{
            'displayName': profile.displayName,
            'region': profile.location.country,
          };
          if (profile.photoUrls.isNotEmpty) {
            syncData['photoUrl'] = profile.photoUrls.first;
          }
          await firestore.collection('user_levels').doc(profile.userId).update(syncData);
        }
      } catch (_) {
        // Non-critical sync — don't fail the profile update
      }

      return updatedProfile;
    } on FirebaseException catch (e) {
      throw ServerException( e.message ?? 'Failed to update profile');
    } catch (e) {
      throw ServerException( e.toString());
    }
  }

  @override
  Future<void> deleteProfile(String userId) async {
    try {
      // Delete profile photos from storage
      final profile = await getProfile(userId);
      for (final photoUrl in profile.photoUrls) {
        await deletePhoto(userId, photoUrl);
      }

      // Delete voice recording if exists
      if (profile.voiceRecordingUrl != null) {
        final ref = storage.refFromURL(profile.voiceRecordingUrl!);
        await ref.delete();
      }

      // Delete profile document
      await firestore.collection('profiles').doc(userId).delete();
    } on FirebaseException catch (e) {
      throw ServerException( e.message ?? 'Failed to delete profile');
    } catch (e) {
      throw ServerException( e.toString());
    }
  }

  @override
  Future<String> uploadPhoto(String userId, File photo, {String? folder}) async {
    try {
      // Compress image before upload to reduce storage costs
      File photoToUpload = photo;
      try {
        photoToUpload = await ImageCompression.compressProfilePhoto(photo);
        debugPrint('Photo compressed for upload');
      } catch (e) {
        debugPrint('Compression failed, using original: $e');
        // Use original if compression fails
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final folderPath = folder ?? 'photos';
      final ref = storage.ref().child('profiles/$userId/$folderPath/$fileName');

      final uploadTask = await ref.putFile(
        photoToUpload,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': userId},
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw ServerException( e.message ?? 'Failed to upload photo');
    } catch (e) {
      throw ServerException( e.toString());
    }
  }

  @override
  Future<void> deletePhoto(String userId, String photoUrl) async {
    try {
      final ref = storage.refFromURL(photoUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw ServerException( e.message ?? 'Failed to delete photo');
    } catch (e) {
      throw ServerException( e.toString());
    }
  }

  @override
  Future<String> uploadVoiceRecording(String userId, File recording) async {
    try {
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ref = storage.ref().child('profiles/$userId/voice/$fileName');

      final uploadTask = await ref.putFile(
        recording,
        SettableMetadata(
          contentType: 'audio/m4a',
          customMetadata: {'userId': userId},
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw ServerException(
           e.message ?? 'Failed to upload voice recording');
    } catch (e) {
      throw ServerException( e.toString());
    }
  }

  @override
  Future<bool> verifyPhotoWithAI(File photo) async {
    try {
      final validationService = PhotoValidationService();
      final result = await validationService.validateMainPhoto(photo);
      return result.isValid && result.hasFace;
    } catch (e) {
      throw ServerException('Failed to verify photo: ${e.toString()}');
    }
  }

  @override
  Future<bool> profileExists(String userId) async {
    try {
      final doc = await firestore.collection('profiles').doc(userId).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      throw ServerException(
           e.message ?? 'Failed to check profile existence');
    } catch (e) {
      throw ServerException( e.toString());
    }
  }

  @override
  Future<int> getProfileCompletion(String userId) async {
    try {
      final profile = await getProfile(userId);

      int completedFields = 0;
      int totalFields = 9;

      if (profile.displayName.isNotEmpty) completedFields++;
      if (profile.photoUrls.isNotEmpty) completedFields++;
      if (profile.bio.isNotEmpty) completedFields++;
      if (profile.interests.isNotEmpty) completedFields++;
      if (profile.location.city.isNotEmpty) completedFields++;
      if (profile.languages.isNotEmpty) completedFields++;
      if (profile.voiceRecordingUrl != null) completedFields++;
      if (profile.personalityTraits != null) completedFields++;
      if (profile.gender.isNotEmpty) completedFields++;

      return ((completedFields / totalFields) * 100).round();
    } catch (e) {
      throw ServerException( 'Failed to calculate completion: ${e.toString()}');
    }
  }
}
