import 'package:equatable/equatable.dart';

/// Message Report Entity
///
/// Represents a reported message in the system
class MessageReport extends Equatable {
  final String reportId;
  final String messageId;
  final String conversationId;
  final String messageContent;
  final DateTime messageSentAt;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final DateTime reportedAt;
  final ReportStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? actionTaken;

  const MessageReport({
    required this.reportId,
    required this.messageId,
    required this.conversationId,
    required this.messageContent,
    required this.messageSentAt,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.reportedAt,
    this.status = ReportStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    this.actionTaken,
  });

  MessageReport copyWith({
    String? reportId,
    String? messageId,
    String? conversationId,
    String? messageContent,
    DateTime? messageSentAt,
    String? reporterId,
    String? reportedUserId,
    String? reason,
    DateTime? reportedAt,
    ReportStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? actionTaken,
  }) {
    return MessageReport(
      reportId: reportId ?? this.reportId,
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      messageContent: messageContent ?? this.messageContent,
      messageSentAt: messageSentAt ?? this.messageSentAt,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reason: reason ?? this.reason,
      reportedAt: reportedAt ?? this.reportedAt,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      actionTaken: actionTaken ?? this.actionTaken,
    );
  }

  @override
  List<Object?> get props => [
        reportId,
        messageId,
        conversationId,
        messageContent,
        messageSentAt,
        reporterId,
        reportedUserId,
        reason,
        reportedAt,
        status,
        reviewedBy,
        reviewedAt,
        actionTaken,
      ];
}

/// Report Status
enum ReportStatus {
  pending,
  reviewed,
  actionTaken,
  dismissed,
}

extension ReportStatusExtension on ReportStatus {
  String get value {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.reviewed:
        return 'reviewed';
      case ReportStatus.actionTaken:
        return 'action_taken';
      case ReportStatus.dismissed:
        return 'dismissed';
    }
  }

  static ReportStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return ReportStatus.pending;
      case 'reviewed':
        return ReportStatus.reviewed;
      case 'action_taken':
        return ReportStatus.actionTaken;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }
}
