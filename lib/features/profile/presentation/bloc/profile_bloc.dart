import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/photo_validation_service.dart';
import '../../domain/usecases/create_profile.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/upload_photo.dart';
import '../../domain/usecases/verify_photo.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final CreateProfile createProfile;
  final UpdateProfile updateProfile;
  final UploadPhoto uploadPhoto;
  final VerifyPhoto verifyPhoto;

  ProfileBloc({
    required this.getProfile,
    required this.createProfile,
    required this.updateProfile,
    required this.uploadPhoto,
    required this.verifyPhoto,
  }) : super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileCreateRequested>(_onProfileCreateRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfilePhotoUploadRequested>(_onProfilePhotoUploadRequested);
    on<ProfilePhotoVerificationRequested>(_onProfilePhotoVerificationRequested);
    on<ProfileNicknameUpdateRequested>(_onProfileNicknameUpdateRequested);
    on<ProfileDeleteRequested>(_onProfileDeleteRequested);
  }

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await getProfile(GetProfileParams(userId: event.userId));

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  Future<void> _onProfileCreateRequested(
    ProfileCreateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result =
        await createProfile(CreateProfileParams(profile: event.profile));

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(ProfileCreated(profile: profile)),
    );
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result =
        await updateProfile(UpdateProfileParams(profile: event.profile));

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(ProfileUpdated(profile: profile)),
    );
  }

  Future<void> _onProfilePhotoUploadRequested(
    ProfilePhotoUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // ALL photos (public AND private) must pass nudity/explicit content checks
    emit(const ProfilePhotoValidating());

    final validationService = PhotoValidationService();
    PhotoValidationResult validationResult;

    if (!event.isPrivate && event.isMainPhoto) {
      // Main photo: must have face + no NSFW
      validationResult =
          await validationService.validateMainPhoto(event.photo);
      if (!validationResult.isValid) {
        emit(ProfilePhotoValidationFailed(
            errorCode: validationResult.errorCode));
        return;
      }
      if (!validationResult.hasFace) {
        emit(const ProfilePhotoValidationFailed(
            errorCode: PhotoValidationError.mainNoFace));
        return;
      }
    } else {
      // All other photos (public non-main + private): no NSFW check, no face required
      validationResult =
          await validationService.validatePublicPhoto(event.photo);
      if (!validationResult.isValid) {
        emit(ProfilePhotoValidationFailed(
            errorCode: validationResult.errorCode));
        return;
      }
    }

    // Validation passed — upload
    emit(const ProfileLoading());

    final result = await uploadPhoto(
      UploadPhotoParams(userId: event.userId, photo: event.photo),
    );

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (photoUrl) => emit(ProfilePhotoUploaded(photoUrl: photoUrl)),
    );
  }

  Future<void> _onProfilePhotoVerificationRequested(
    ProfilePhotoVerificationRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await verifyPhoto(VerifyPhotoParams(photo: event.photo));

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (isVerified) => emit(ProfilePhotoVerified(isVerified: isVerified)),
    );
  }

  Future<void> _onProfileNicknameUpdateRequested(
    ProfileNicknameUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    // First get the current profile
    final getResult = await getProfile(GetProfileParams(userId: event.userId));

    // Use isLeft/getOrElse pattern instead of fold with async callbacks
    if (getResult.isLeft()) {
      final failure = getResult.fold((f) => f, (_) => throw Exception('Unreachable'));
      emit(ProfileError(message: failure.message));
      return;
    }

    // Get the profile from successful result
    final profile = getResult.getOrElse(() => throw Exception('Unreachable'));

    // Update the profile with the new nickname
    final updatedProfile = profile.copyWith(nickname: event.nickname.toLowerCase());
    final updateResult = await updateProfile(UpdateProfileParams(profile: updatedProfile));

    // Handle update result
    if (updateResult.isLeft()) {
      final failure = updateResult.fold((f) => f, (_) => throw Exception('Unreachable'));
      emit(ProfileError(message: failure.message));
      return;
    }

    // Emit success with updated profile
    final updatedProfileResult = updateResult.getOrElse(() => throw Exception('Unreachable'));
    emit(ProfileUpdated(profile: updatedProfileResult));
  }

  Future<void> _onProfileDeleteRequested(
    ProfileDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      final userId = event.userId;
      final firestore = FirebaseFirestore.instance;

      // Delete all user data from Firestore collections
      // Top-level user documents
      final topLevelCollections = [
        'profiles',
        'users',
        'userSettings',
        'coinBalances',
        'subscriptions',
        'memberships',
        'membership_purchases',
        'userLevels',
        'userAchievements',
        'userBadges',
        'userChallenges',
        'userVibeTags',
        'user_levels',
        'user_vectors',
        'user_interactions',
        'notification_preferences',
        'match_preferences',
        'streaks',
        'dailyUsage',
        'usageLimits',
        'achievement_progress',
        'language_progress',
        'learning_progress',
        'daily_hints_progress',
        'videoCoinBalances',
      ];

      // Delete top-level docs in parallel batches
      await Future.wait(
        topLevelCollections.map((collection) async {
          try {
            final docRef = firestore.collection(collection).doc(userId);
            await _deleteSubcollections(docRef);
            await docRef.delete();
          } catch (e) {
            debugPrint('[DeleteAccount] Error deleting $collection/$userId: $e');
          }
        }),
      );

      // Delete documents where userId is a field (query-based)
      final queryCollections = <String, List<String>>{
        'swipes': ['userId'],
        'matches': ['userId1', 'userId2'],
        'conversations': ['participants'],
        'notifications': ['userId'],
        'blockedUsers': ['userId', 'blockedUserId'],
        'user_reports': ['reporterId', 'reportedUserId'],
        'message_reports': ['reporterId'],
        'coinTransactions': ['userId'],
        'coinGifts': ['senderId', 'receiverId'],
        'coinOrders': ['userId'],
        'purchases': ['userId'],
        'support_chats': ['userId'],
        'photo_likes': ['userId', 'targetUserId'],
        'sentVirtualGifts': ['senderId'],
        'secondChancePool': ['userId'],
        'blindMatches': ['userId1', 'userId2'],
        'scheduledDates': ['userId1', 'userId2'],
        'call_history': ['callerId', 'receiverId'],
        'album_access': ['ownerId', 'grantedToUserId'],
        'account_actions': ['userId'],
        'videoCoinTransactions': ['userId'],
        'xp_transactions': ['userId'],
      };

      // Run query-based deletions in parallel
      await Future.wait(
        queryCollections.entries.expand((entry) {
          return entry.value.map((field) async {
            try {
              if (field == 'participants') {
                final query = await firestore
                    .collection(entry.key)
                    .where(field, arrayContains: userId)
                    .get();
                for (final doc in query.docs) {
                  await _deleteSubcollections(doc.reference);
                  await doc.reference.delete();
                }
              } else {
                final query = await firestore
                    .collection(entry.key)
                    .where(field, isEqualTo: userId)
                    .get();
                for (final doc in query.docs) {
                  await _deleteSubcollections(doc.reference);
                  await doc.reference.delete();
                }
              }
            } catch (e) {
              debugPrint('[DeleteAccount] Error querying ${entry.key}.$field: $e');
            }
          });
        }),
      );

      debugPrint('[DeleteAccount] Account $userId Firestore data deleted');

      // Delete Firebase Auth user FIRST to free the email for re-registration.
      // We do this before emitting state because emit triggers sign-out which
      // may dispose the bloc and prevent Auth deletion from completing.
      // The user was already re-authenticated in the UI before dispatching this event.
      bool authDeleted = false;
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await currentUser.delete();
          authDeleted = true;
          debugPrint('[DeleteAccount] Firebase Auth user deleted');
        }
      } catch (e) {
        debugPrint('[DeleteAccount] Auth delete failed: $e');
      }

      // Now emit ProfileDeleted — this triggers sign-out and navigation
      emit(const ProfileDeleted());

      if (!authDeleted) {
        debugPrint('[DeleteAccount] WARNING: Auth user was NOT deleted — email may still be registered');
      }
    } catch (e) {
      debugPrint('[DeleteAccount] Error: $e');
      emit(ProfileError(message: 'Failed to delete account: $e'));
    }
  }

  /// Delete known subcollections of a document
  Future<void> _deleteSubcollections(DocumentReference docRef) async {
    final knownSubcollections = [
      'coinBatches',
      'coinTransactions',
      'messages',
      'support_messages',
      'days',
      'hours',
    ];

    await Future.wait(
      knownSubcollections.map((sub) async {
        try {
          final subDocs = await docRef.collection(sub).limit(500).get();
          for (final doc in subDocs.docs) {
            await doc.reference.delete();
          }
        } catch (_) {}
      }),
    );
  }
}
