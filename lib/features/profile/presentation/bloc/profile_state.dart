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
  final Profile profile;

  const ProfileLoaded({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ProfileCreated extends ProfileState {
  final Profile profile;

  const ProfileCreated({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ProfileUpdated extends ProfileState {
  final Profile profile;

  const ProfileUpdated({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ProfilePhotoUploaded extends ProfileState {
  final String photoUrl;

  const ProfilePhotoUploaded({required this.photoUrl});

  @override
  List<Object?> get props => [photoUrl];
}

class ProfilePhotoVerified extends ProfileState {
  final bool isVerified;

  const ProfilePhotoVerified({required this.isVerified});

  @override
  List<Object?> get props => [isVerified];
}

class ProfileVoiceUploaded extends ProfileState {
  final String voiceUrl;

  const ProfileVoiceUploaded({required this.voiceUrl});

  @override
  List<Object?> get props => [voiceUrl];
}

class ProfileDeleted extends ProfileState {
  const ProfileDeleted();
}

class ProfileCompletionLoaded extends ProfileState {
  final int completionPercentage;

  const ProfileCompletionLoaded({required this.completionPercentage});

  @override
  List<Object?> get props => [completionPercentage];
}

class ProfilePhotoValidating extends ProfileState {
  const ProfilePhotoValidating();
}

class ProfilePhotoValidationFailed extends ProfileState {
  final PhotoValidationError? errorCode;

  const ProfilePhotoValidationFailed({this.errorCode});

  @override
  List<Object?> get props => [errorCode];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}
