import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/entities/profile.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  final String userId;

  const ProfileLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class ProfileCreateRequested extends ProfileEvent {
  final Profile profile;

  const ProfileCreateRequested({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ProfileUpdateRequested extends ProfileEvent {
  final Profile profile;

  const ProfileUpdateRequested({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ProfilePhotoUploadRequested extends ProfileEvent {
  final String userId;
  final File photo;

  const ProfilePhotoUploadRequested({
    required this.userId,
    required this.photo,
  });

  @override
  List<Object?> get props => [userId, photo];
}

class ProfilePhotoVerificationRequested extends ProfileEvent {
  final File photo;

  const ProfilePhotoVerificationRequested({required this.photo});

  @override
  List<Object?> get props => [photo];
}

class ProfileVoiceUploadRequested extends ProfileEvent {
  final String userId;
  final File recording;

  const ProfileVoiceUploadRequested({
    required this.userId,
    required this.recording,
  });

  @override
  List<Object?> get props => [userId, recording];
}

class ProfileDeleteRequested extends ProfileEvent {
  final String userId;

  const ProfileDeleteRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class ProfileCompletionCheckRequested extends ProfileEvent {
  final String userId;

  const ProfileCompletionCheckRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}
