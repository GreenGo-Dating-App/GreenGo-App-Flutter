import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/photo_validation_service.dart';
import '../../../coins/data/datasources/coin_remote_datasource.dart'
    show CoinRefusalException;
import '../../../coins/domain/entities/coin_transaction.dart';
import '../../../coins/domain/repositories/coin_repository.dart';
import '../../domain/usecases/create_profile.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/upload_photo.dart';
import '../../domain/usecases/verify_photo.dart';
import 'profile_event.dart';
import 'profile_state.dart';
import '../../../../core/error/failures.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {

  ProfileBloc({
    required this.getProfile,
    required this.createProfile,
    required this.updateProfile,
    required this.uploadPhoto,
    required this.verifyPhoto,
    this.coinRepository,
    this.deleteAccountCall,
  }) : super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileCreateRequested>(_onProfileCreateRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfilePhotoUploadRequested>(_onProfilePhotoUploadRequested);
    on<ProfilePhotoVerificationRequested>(_onProfilePhotoVerificationRequested);
    on<ProfileNicknameUpdateRequested>(_onProfileNicknameUpdateRequested);
    on<ProfileDeleteRequested>(_onProfileDeleteRequested);
    on<ProfileBoostRequested>(_onProfileBoostRequested);
  }
  final GetProfile getProfile;
  final CreateProfile createProfile;
  final UpdateProfile updateProfile;
  final UploadPhoto uploadPhoto;
  final VerifyPhoto verifyPhoto;
  final CoinRepository? coinRepository;

  /// `deleteMyAccount` callable (overridable in tests).
  final Future<Map<String, dynamic>> Function()? deleteAccountCall;

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

  /// Server moderation reasons -> the localized message the user sees.
  ///
  /// Reuses PhotoValidationError so a server rejection and an on-device one
  /// read identically to the user - they do not care which side caught it.
  PhotoValidationError _codeForRejection(List<String> reasons) {
    if (reasons.contains('adult')) return PhotoValidationError.explicitNudity;
    if (reasons.contains('racy')) return PhotoValidationError.tooMuchSkin;
    if (reasons.contains('violence')) return PhotoValidationError.explicitContent;
    if (reasons.contains('no_face')) return PhotoValidationError.mainNoFace;
    return PhotoValidationError.explicitContent;
  }

  Future<void> _onProfilePhotoUploadRequested(
    ProfilePhotoUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // ALL photos (public AND private) must pass nudity/explicit content checks.
    // These run on-device ML Kit (face + NSFW labels), which is native-only —
    // on web we skip client validation and rely on server-side moderation.
    if (!kIsWeb && !event.isPrivate) {
      emit(const ProfilePhotoValidating());

      final validationService = PhotoValidationService();
      final photoFile = File(event.photo.path);
      PhotoValidationResult validationResult;

      if (!event.isPrivate && event.isMainPhoto) {
        // Main photo: must have face + no NSFW
        validationResult =
            await validationService.validateMainPhoto(photoFile);
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
        // All other photos (public non-main incl. business gallery/storefront +
        // private): NSFW/nudity check runs (skin-ratio + on-device ML Kit
        // labels), no face required. Business/public images that fail the
        // explicit-content check are rejected here on upload.
        validationResult =
            await validationService.validatePublicPhoto(photoFile);
        if (!validationResult.isValid) {
          emit(ProfilePhotoValidationFailed(
              errorCode: validationResult.errorCode));
          return;
        }
      }
    }

    // Validation passed (or skipped on web) — upload
    emit(const ProfileLoading());

    final result = await uploadPhoto(
      UploadPhotoParams(
        userId: event.userId,
        photo: event.photo,
        isPrivate: event.isPrivate,
        requireFace: !event.isPrivate && event.isMainPhoto,
      ),
    );

    result.fold(
      (failure) {
        // A moderation rejection gets the explained dialog, in the user's
        // language, with the private-album route out. Everything else stays a
        // generic error.
        if (failure is PhotoRejectedFailure) {
          emit(ProfilePhotoValidationFailed(
            errorCode: _codeForRejection(failure.reasons),
          ));
          return;
        }
        emit(ProfileError(message: failure.message));
      },
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

  Future<void> _onProfileBoostRequested(
    ProfileBoostRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      // Get current profile to check tier
      final result = await getProfile(GetProfileParams(userId: event.userId));
      if (result.isLeft()) {
        final failure = result.fold((f) => f, (_) => throw Exception('Unreachable'));
        emit(ProfileError(message: failure.message));
        return;
      }
      final profile = result.getOrElse(() => throw Exception('Unreachable'));

      // Check if already boosted
      if (profile.isBoosted &&
          profile.boostExpiry != null &&
          profile.boostExpiry!.isAfter(DateTime.now())) {
        emit(ProfileBoostAlreadyActive(expiry: profile.boostExpiry!));
        emit(ProfileLoaded(profile: profile));
        return;
      }

      // All users pay 50 coins for boost
      const cost = CoinFeaturePrices.boost;

      if (coinRepository == null) {
        emit(const ProfileBoostInsufficientCoins(required: cost, available: 0));
        if (state is! ProfileLoaded) emit(ProfileLoaded(profile: profile));
        return;
      }

      // Check balance
      final balanceResult = await coinRepository!.getBalance(event.userId);
      final balance = balanceResult.fold(
        (failure) => 0,
        (b) => b.availableCoins,
      );

      if (balance < cost) {
        emit(ProfileBoostInsufficientCoins(required: cost, available: balance));
        emit(ProfileLoaded(profile: profile));
        return;
      }

      // Pay AND activate in one server transaction (spendCoins sets
      // isBoosted / boostExpiry, 30 minutes): no coins without a boost, and no
      // boost without coins.
      final spend = await coinRepository!.purchaseFeature(
        userId: event.userId,
        featureName: 'boost',
        cost: cost,
      );
      DateTime? serverExpiry;
      String? failure;
      spend.fold(
        (f) => failure = f.message,
        (txn) {
          final effect = txn.metadata?['effect'];
          final ms = effect is Map ? effect['boostExpiry'] : null;
          if (ms is num) {
            serverExpiry = DateTime.fromMillisecondsSinceEpoch(ms.toInt());
          }
        },
      );
      if (failure != null) {
        if (CoinRefusalException.reasonIn(failure) ==
            CoinRefusalException.insufficientCoins) {
          emit(ProfileBoostInsufficientCoins(required: cost, available: balance));
          emit(ProfileLoaded(profile: profile));
          return;
        }
        throw Exception(failure);
      }
      final expiry =
          serverExpiry ?? DateTime.now().add(const Duration(minutes: 30));

      // Reload profile
      final updatedResult = await getProfile(GetProfileParams(userId: event.userId));
      final updatedProfile = updatedResult.getOrElse(() => profile.copyWith(
        isBoosted: true,
        boostExpiry: expiry,
      ));

      emit(ProfileBoostActivated(profile: updatedProfile, expiry: expiry));
      emit(ProfileLoaded(profile: updatedProfile));
    } catch (e) {
      debugPrint('[ProfileBoost] Error: $e');
      emit(ProfileError(message: 'Failed to activate boost: $e')); // i18n-ignore: raw error, UI localizes via showUserError
    }
  }

  Future<void> _onProfileDeleteRequested(
    ProfileDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    // The server deletes everything (Auth user LAST) and keeps the records
    // the law requires (payments), so success is reported only when it
    // confirms (audit H-15, plan P1-10). The client no longer deletes
    // anything itself: its old cascade destroyed financial records and could
    // report success after a partial deletion.
    try {
      final result = await (deleteAccountCall ?? _callDeleteMyAccount)();
      if (result['success'] == true) {
        emit(const ProfileDeleted());
      } else {
        emit(const ProfileDeleteFailed(reason: ProfileDeleteFailure.failed));
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[DeleteAccount] deleteMyAccount failed: ${e.code}');
      emit(ProfileDeleteFailed(reason: deleteFailureFor(e.code, e.details)));
    } catch (e) {
      debugPrint('[DeleteAccount] deleteMyAccount failed: $e');
      emit(const ProfileDeleteFailed(reason: ProfileDeleteFailure.failed));
    }
  }

  static Future<Map<String, dynamic>> _callDeleteMyAccount() async {
    final res = await FirebaseFunctions.instance
        .httpsCallable('deleteMyAccount',
            // The server cascade may take minutes for large accounts.
            options: HttpsCallableOptions(timeout: const Duration(seconds: 540)))
        .call<Map<String, dynamic>>(<String, dynamic>{});
    return Map<String, dynamic>.from(res.data);
  }

  /// Maps a `deleteMyAccount` error to what the UI does next.
  @visibleForTesting
  static ProfileDeleteFailure deleteFailureFor(String code, Object? details) {
    final detailCode = details is Map ? details['code'] ?? details['reason'] : null;
    if (detailCode == 'REQUIRES_RECENT_LOGIN') {
      return ProfileDeleteFailure.requiresRecentLogin;
    }
    if (code == 'unavailable' || code == 'deadline-exceeded') {
      return ProfileDeleteFailure.network;
    }
    return ProfileDeleteFailure.failed;
  }
}
