import 'package:equatable/equatable.dart';
import '../../../profile/domain/entities/profile.dart';

abstract class VerificationAdminState extends Equatable {
  const VerificationAdminState();

  @override
  List<Object?> get props => [];
}

class VerificationAdminInitial extends VerificationAdminState {
  const VerificationAdminInitial();
}

class VerificationAdminLoading extends VerificationAdminState {
  const VerificationAdminLoading();
}

class VerificationAdminLoaded extends VerificationAdminState {
  final List<Profile> pendingVerifications;
  final List<Profile> verificationHistory;

  const VerificationAdminLoaded({
    required this.pendingVerifications,
    this.verificationHistory = const [],
  });

  VerificationAdminLoaded copyWith({
    List<Profile>? pendingVerifications,
    List<Profile>? verificationHistory,
  }) {
    return VerificationAdminLoaded(
      pendingVerifications: pendingVerifications ?? this.pendingVerifications,
      verificationHistory: verificationHistory ?? this.verificationHistory,
    );
  }

  @override
  List<Object?> get props => [pendingVerifications, verificationHistory];
}

class VerificationAdminActionLoading extends VerificationAdminState {
  final List<Profile> pendingVerifications;
  final List<Profile> verificationHistory;
  final String userId;

  const VerificationAdminActionLoading({
    required this.pendingVerifications,
    required this.verificationHistory,
    required this.userId,
  });

  @override
  List<Object?> get props => [pendingVerifications, verificationHistory, userId];
}

class VerificationAdminBulkActionLoading extends VerificationAdminState {
  final List<Profile> pendingVerifications;
  final List<Profile> verificationHistory;
  final List<String> userIds;

  const VerificationAdminBulkActionLoading({
    required this.pendingVerifications,
    required this.verificationHistory,
    required this.userIds,
  });

  @override
  List<Object?> get props => [pendingVerifications, verificationHistory, userIds];
}

class VerificationAdminActionSuccess extends VerificationAdminState {
  final List<Profile> pendingVerifications;
  final List<Profile> verificationHistory;
  final String message;

  const VerificationAdminActionSuccess({
    required this.pendingVerifications,
    required this.verificationHistory,
    required this.message,
  });

  @override
  List<Object?> get props => [pendingVerifications, verificationHistory, message];
}

class VerificationAdminError extends VerificationAdminState {
  final String message;
  final List<Profile> pendingVerifications;
  final List<Profile> verificationHistory;

  const VerificationAdminError({
    required this.message,
    this.pendingVerifications = const [],
    this.verificationHistory = const [],
  });

  @override
  List<Object?> get props => [message, pendingVerifications, verificationHistory];
}
