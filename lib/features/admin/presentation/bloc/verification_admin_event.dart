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

  const LoadVerificationHistory({this.limit = 100});
  final int limit;

  @override
  List<Object?> get props => [limit];
}

class ApproveVerification extends VerificationAdminEvent {

  const ApproveVerification({
    required this.userId,
    required this.adminId,
  });
  final String userId;
  final String adminId;

  @override
  List<Object?> get props => [userId, adminId];
}

class RejectVerification extends VerificationAdminEvent {

  const RejectVerification({
    required this.userId,
    required this.adminId,
    required this.reason,
  });
  final String userId;
  final String adminId;
  final String reason;

  @override
  List<Object?> get props => [userId, adminId, reason];
}

class RequestBetterPhoto extends VerificationAdminEvent {

  const RequestBetterPhoto({
    required this.userId,
    required this.adminId,
    required this.reason,
  });
  final String userId;
  final String adminId;
  final String reason;

  @override
  List<Object?> get props => [userId, adminId, reason];
}

class RefreshVerifications extends VerificationAdminEvent {
  const RefreshVerifications();
}

class BulkApproveVerifications extends VerificationAdminEvent {

  const BulkApproveVerifications({
    required this.userIds,
    required this.adminId,
  });
  final List<String> userIds;
  final String adminId;

  @override
  List<Object?> get props => [userIds, adminId];
}

class BulkRequestBetterPhoto extends VerificationAdminEvent {

  const BulkRequestBetterPhoto({
    required this.userIds,
    required this.adminId,
    required this.reason,
  });
  final List<String> userIds;
  final String adminId;
  final String reason;

  @override
  List<Object?> get props => [userIds, adminId, reason];
}
