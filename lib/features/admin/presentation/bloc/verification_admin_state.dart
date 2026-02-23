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

class VerificationAdminActionLoading extends VerificationAdminLoaded {
  final String userId;

  const VerificationAdminActionLoading({
    required super.pendingVerifications,
    required super.verificationHistory,
    required this.userId,
  });

  @override
  List<Object?> get props => [pendingVerifications, verificationHistory, userId];
}

class VerificationAdminBulkActionLoading extends VerificationAdminLoaded {
  final List<String> userIds;

  const VerificationAdminBulkActionLoading({
    required super.pendingVerifications,
    required super.verificationHistory,
    required this.userIds,
  });

  @override
  List<Object?> get props => [pendingVerifications, verificationHistory, userIds];
}

class VerificationAdminActionSuccess extends VerificationAdminLoaded {
  final String message;

  const VerificationAdminActionSuccess({
    required super.pendingVerifications,
    required super.verificationHistory,
    required this.message,
  });

  @override
  List<Object?> get props => [pendingVerifications, verificationHistory, message];
}

class VerificationAdminError extends VerificationAdminLoaded {
  final String message;

  const VerificationAdminError({
    required this.message,
    super.pendingVerifications = const [],
    super.verificationHistory = const [],
  });

  @override
  List<Object?> get props => [message, pendingVerifications, verificationHistory];
}
