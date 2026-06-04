import 'package:equatable/equatable.dart';
import '../../../../core/services/photo_validation_service.dart';
import '../../domain/entities/profile.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {

  const ProfileLoaded({required this.profile});
  final Profile profile;

  @override
  List<Object?> get props => [profile];
}

class ProfileCreated extends ProfileState {

  const ProfileCreated({required this.profile});
  final Profile profile;

  @override
  List<Object?> get props => [profile];
}

class ProfileUpdated extends ProfileState {

  const ProfileUpdated({required this.profile});
  final Profile profile;

  @override
  List<Object?> get props => [profile];
}

class ProfilePhotoUploaded extends ProfileState {

  const ProfilePhotoUploaded({required this.photoUrl});
  final String photoUrl;

  @override
  List<Object?> get props => [photoUrl];
}

class ProfilePhotoVerified extends ProfileState {

  const ProfilePhotoVerified({required this.isVerified});
  final bool isVerified;

  @override
  List<Object?> get props => [isVerified];
}

class ProfileVoiceUploaded extends ProfileState {

  const ProfileVoiceUploaded({required this.voiceUrl});
  final String voiceUrl;

  @override
  List<Object?> get props => [voiceUrl];
}

class ProfileDeleted extends ProfileState {
  const ProfileDeleted();
}

class ProfileCompletionLoaded extends ProfileState {

  const ProfileCompletionLoaded({required this.completionPercentage});
  final int completionPercentage;

  @override
  List<Object?> get props => [completionPercentage];
}

class ProfilePhotoValidating extends ProfileState {
  const ProfilePhotoValidating();
}

class ProfilePhotoValidationFailed extends ProfileState {

  const ProfilePhotoValidationFailed({this.errorCode});
  final PhotoValidationError? errorCode;

  @override
  List<Object?> get props => [errorCode];
}

class ProfileError extends ProfileState {

  const ProfileError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class ProfileBoostActivated extends ProfileState {

  const ProfileBoostActivated({required this.profile, required this.expiry});
  final Profile profile;
  final DateTime expiry;

  @override
  List<Object?> get props => [profile, expiry];
}

class ProfileBoostInsufficientCoins extends ProfileState {

  const ProfileBoostInsufficientCoins({required this.required, required this.available});
  final int required;
  final int available;

  @override
  List<Object?> get props => [required, available];
}
