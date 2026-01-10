import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Report User Use Case
class ReportUser {
  final ChatRepository repository;

  ReportUser(this.repository);

  Future<Either<Failure, void>> call(ReportUserParams params) {
    return repository.reportUser(
      reporterId: params.reporterId,
      reportedUserId: params.reportedUserId,
      reason: params.reason,
      conversationId: params.conversationId,
      messageId: params.messageId,
      additionalDetails: params.additionalDetails,
    );
  }
}

/// Parameters for ReportUser use case
class ReportUserParams {
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String? conversationId;
  final String? messageId;
  final String? additionalDetails;

  ReportUserParams({
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    this.conversationId,
    this.messageId,
    this.additionalDetails,
  });
}
