import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/profile.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {

  const ProfileLoadRequested({required this.userId});
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class ProfileCreateRequested extends ProfileEvent {

  const ProfileCreateRequested({required this.profile});
  final Profile profile;

  @override
  List<Object?> get props => [profile];
}

class ProfileUpdateRequested extends ProfileEvent {

  const ProfileUpdateRequested({required this.profile});
  final Profile profile;

  @override
  List<Object?> get props => [profile];
}

class ProfilePhotoUploadRequested extends ProfileEvent {

  const ProfilePhotoUploadRequested({
    required this.userId,
    required this.photo,
    this.isMainPhoto = false,
    this.isPrivate = false,
  });
  final String userId;
  final XFile photo;
  final bool isMainPhoto;
  final bool isPrivate;

  @override
  List<Object?> get props => [userId, photo, isMainPhoto, isPrivate];
}

class ProfilePhotoVerificationRequested extends ProfileEvent {

  const ProfilePhotoVerificationRequested({required this.photo});
  final File photo;

  @override
  List<Object?> get props => [photo];
}

class ProfileVoiceUploadRequested extends ProfileEvent {

  const ProfileVoiceUploadRequested({
    required this.userId,
    required this.recording,
  });
  final String userId;
  final File recording;

  @override
  List<Object?> get props => [userId, recording];
}

class ProfileDeleteRequested extends ProfileEvent {

  const ProfileDeleteRequested({required this.userId});
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class ProfileCompletionCheckRequested extends ProfileEvent {

  const ProfileCompletionCheckRequested({required this.userId});
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class ProfileNicknameUpdateRequested extends ProfileEvent {

  const ProfileNicknameUpdateRequested({
    required this.userId,
    required this.nickname,
  });
  final String userId;
  final String nickname;

  @override
  List<Object?> get props => [userId, nickname];
}

class ProfileBoostRequested extends ProfileEvent {

  const ProfileBoostRequested({required this.userId});
  final String userId;

  @override
  List<Object?> get props => [userId];
}
