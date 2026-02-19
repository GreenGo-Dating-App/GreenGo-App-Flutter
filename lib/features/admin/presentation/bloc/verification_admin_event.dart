import 'package:equatable/equatable.dart';

abstract class VerificationAdminEvent extends Equatable {
  const VerificationAdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingVerifications extends VerificationAdminEvent {
  const LoadPendingVerifications();
}

class LoadVerificationHistory extends VerificationAdminEvent {
  final int limit;

  const LoadVerificationHistory({this.limit = 50});

  @override
  List<Object?> get props => [limit];
}

class ApproveVerification extends VerificationAdminEvent {
  final String userId;
  final String adminId;

  const ApproveVerification({
    required this.userId,
    required this.adminId,
  });

  @override
  List<Object?> get props => [userId, adminId];
}

class RejectVerification extends VerificationAdminEvent {
  final String userId;
  final String adminId;
  final String reason;

  const RejectVerification({
    required this.userId,
    required this.adminId,
    required this.reason,
  });

  @override
  List<Object?> get props => [userId, adminId, reason];
}

class RequestBetterPhoto extends VerificationAdminEvent {
  final String userId;
  final String adminId;
  final String reason;

  const RequestBetterPhoto({
    required this.userId,
    required this.adminId,
    required this.reason,
  });

  @override
  List<Object?> get props => [userId, adminId, reason];
}

class RefreshVerifications extends VerificationAdminEvent {
  const RefreshVerifications();
}

class BulkApproveVerifications extends VerificationAdminEvent {
  final List<String> userIds;
  final String adminId;

  const BulkApproveVerifications({
    required this.userIds,
    required this.adminId,
  });

  @override
  List<Object?> get props => [userIds, adminId];
}

class BulkRequestBetterPhoto extends VerificationAdminEvent {
  final List<String> userIds;
  final String adminId;
  final String reason;

  const BulkRequestBetterPhoto({
    required this.userIds,
    required this.adminId,
    required this.reason,
  });

  @override
  List<Object?> get props => [userIds, adminId, reason];
}
