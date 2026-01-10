/**
 * User Report Entity
 * Points 211-220: User reporting and blocking system
 */

import 'package:equatable/equatable.dart';

/// User report (Point 211-214)
class UserReport extends Equatable {
  final String reportId;
  final String reporterId;
  final String reportedUserId;
  final ReportCategory category;
  final String description;
  final List<String> screenshotUrls;
  final String? conversationId;
  final String? messageId;
  final DateTime createdAt;
  final ReportStatus status;
  final ReportPriority priority;
  final String? assignedModeratorId;
  final DateTime? reviewedAt;
  final String? moderatorNotes;
  final ReportAction? action;

  const UserReport({
    required this.reportId,
    required this.reporterId,
    required this.reportedUserId,
    required this.category,
    required this.description,
    required this.screenshotUrls,
    this.conversationId,
    this.messageId,
    required this.createdAt,
    required this.status,
    required this.priority,
    this.assignedModeratorId,
    this.reviewedAt,
    this.moderatorNotes,
    this.action,
  });

  bool get isPending => status == ReportStatus.pending;
  bool get isResolved => status == ReportStatus.resolved;
  bool get requiresUrgentAction => priority == ReportPriority.critical;

  @override
  List<Object?> get props => [
        reportId,
        reporterId,
        reportedUserId,
        category,
        description,
        screenshotUrls,
        conversationId,
        messageId,
        createdAt,
        status,
        priority,
        assignedModeratorId,
        reviewedAt,
        moderatorNotes,
        action,
      ];
}

/// Report categories (Point 211)
enum ReportCategory {
  inappropriateContent,
  harassment,
  scam,
  fakeProfile,
  spam,
  hateSpeech,
  violence,
  minorSafety,
  impersonation,
  other,
}

/// Report status
enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed,
  appealed,
}

/// Report priority (Point 214)
enum ReportPriority {
  low,
  medium,
  high,
  critical,
}

/// Actions taken on reports
enum ReportAction {
  noAction,
  warningIssued, // Point 208
  contentRemoved,
  accountSuspended,
  accountBanned,
  shadowBanned, // Point 219
  requiresVerification,
}

/// Report appeal (Point 210)
class ReportAppeal extends Equatable {
  final String appealId;
  final String reportId;
  final String userId;
  final String appealReason;
  final List<String> evidenceUrls;
  final DateTime createdAt;
  final AppealStatus status;
  final String? reviewerNotes;
  final DateTime? reviewedAt;
  final AppealDecision? decision;

  const ReportAppeal({
    required this.appealId,
    required this.reportId,
    required this.userId,
    required this.appealReason,
    required this.evidenceUrls,
    required this.createdAt,
    required this.status,
    this.reviewerNotes,
    this.reviewedAt,
    this.decision,
  });

  @override
  List<Object?> get props => [
        appealId,
        reportId,
        userId,
        appealReason,
        evidenceUrls,
        createdAt,
        status,
        reviewerNotes,
        reviewedAt,
        decision,
      ];
}

/// Appeal status
enum AppealStatus {
  pending,
  underReview,
  resolved,
}

/// Appeal decision
enum AppealDecision {
  upheld, // Original decision stands
  overturned, // User's appeal accepted
  partiallyUpheld, // Some aspects changed
}

/// User block (Points 215-220)
class UserBlock extends Equatable {
  final String blockId;
  final String blockerId;
  final String blockedUserId;
  final BlockType type;
  final String? reason;
  final DateTime createdAt;
  final bool isActive;

  const UserBlock({
    required this.blockId,
    required this.blockerId,
    required this.blockedUserId,
    required this.type,
    this.reason,
    required this.createdAt,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        blockId,
        blockerId,
        blockedUserId,
        type,
        reason,
        createdAt,
        isActive,
      ];
}

/// Block types
enum BlockType {
  manual, // Point 215: User-initiated
  automatic, // Point 218: High report volume
  mutual, // Point 217: Both users blocked each other
  shadowBan, // Point 219: Reduced visibility
}

/// Block list
class BlockList extends Equatable {
  final String userId;
  final List<UserBlock> blocks;
  final int totalBlocked;

  const BlockList({
    required this.userId,
    required this.blocks,
    required this.totalBlocked,
  });

  @override
  List<Object?> get props => [userId, blocks, totalBlocked];
}

/// Warning issued to user (Point 208)
class UserWarning extends Equatable {
  final String warningId;
  final String userId;
  final WarningReason reason;
  final String description;
  final WarningSeverity severity;
  final DateTime issuedAt;
  final bool acknowledged;
  final DateTime? acknowledgedAt;

  const UserWarning({
    required this.warningId,
    required this.userId,
    required this.reason,
    required this.description,
    required this.severity,
    required this.issuedAt,
    required this.acknowledged,
    this.acknowledgedAt,
  });

  @override
  List<Object?> get props => [
        warningId,
        userId,
        reason,
        description,
        severity,
        issuedAt,
        acknowledged,
        acknowledgedAt,
      ];
}

/// Warning reasons
enum WarningReason {
  inappropriateContent,
  harassment,
  spam,
  fakeInformation,
  communityGuidelines,
  termsOfService,
}

/// Warning severity
enum WarningSeverity {
  minor, // First-time offense
  moderate,
  severe,
  finalWarning, // Last warning before ban
}

/// Moderation queue entry (Point 209)
class ModerationQueueEntry extends Equatable {
  final String queueId;
  final ModerationItemType itemType;
  final String itemId;
  final String? userId;
  final ReportPriority priority;
  final DateTime addedAt;
  final String? assignedTo;
  final List<String> relatedReportIds;
  final Map<String, dynamic> metadata;

  const ModerationQueueEntry({
    required this.queueId,
    required this.itemType,
    required this.itemId,
    this.userId,
    required this.priority,
    required this.addedAt,
    this.assignedTo,
    required this.relatedReportIds,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
        queueId,
        itemType,
        itemId,
        userId,
        priority,
        addedAt,
        assignedTo,
        relatedReportIds,
        metadata,
      ];
}

/// Types of items in moderation queue
enum ModerationItemType {
  userReport,
  flaggedContent,
  suspiciousProfile,
  appeal,
  highRiskTransaction,
}
