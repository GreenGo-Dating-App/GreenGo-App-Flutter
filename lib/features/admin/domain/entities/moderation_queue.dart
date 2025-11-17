/**
 * Moderation Queue Entity
 * Points 246-250: Content moderation queue management
 */

import 'package:equatable/equatable.dart';

/// Moderation queue item (Point 246)
class ModerationQueueItem extends Equatable {
  final String queueId;
  final ModerationItemType itemType;
  final String itemId;
  final String userId;
  final ModerationPriority priority;
  final DateTime addedAt;
  final String? assignedTo;
  final DateTime? assignedAt;
  final List<String> relatedReportIds;
  final Map<String, dynamic> metadata;
  final ModerationItemStatus status;

  const ModerationQueueItem({
    required this.queueId,
    required this.itemType,
    required this.itemId,
    required this.userId,
    required this.priority,
    required this.addedAt,
    this.assignedTo,
    this.assignedAt,
    required this.relatedReportIds,
    required this.metadata,
    required this.status,
  });

  bool get isAssigned => assignedTo != null;
  bool get isPending => status == ModerationItemStatus.pending;

  @override
  List<Object?> get props => [
        queueId,
        itemType,
        itemId,
        userId,
        priority,
        addedAt,
        assignedTo,
        assignedAt,
        relatedReportIds,
        metadata,
        status,
      ];
}

/// Moderation item types
enum ModerationItemType {
  userReport,
  flaggedPhoto,
  flaggedMessage,
  flaggedProfile,
  appeal,
  suspiciousActivity,
}

/// Moderation priority
enum ModerationPriority {
  critical,
  high,
  medium,
  low;

  int get sortOrder {
    switch (this) {
      case ModerationPriority.critical:
        return 0;
      case ModerationPriority.high:
        return 1;
      case ModerationPriority.medium:
        return 2;
      case ModerationPriority.low:
        return 3;
    }
  }
}

/// Moderation item status
enum ModerationItemStatus {
  pending,
  assigned,
  inReview,
  resolved,
  dismissed,
}

/// Detailed moderation review interface (Point 247)
class ModerationReviewItem extends Equatable {
  final String queueId;
  final ModerationItemType itemType;
  final ModerationItemContent content;
  final UserContext userContext;
  final List<RelatedReport> relatedReports;
  final ModerationHistory? history;
  final List<SuggestedAction> suggestedActions;
  final DateTime addedAt;
  final ModerationPriority priority;

  const ModerationReviewItem({
    required this.queueId,
    required this.itemType,
    required this.content,
    required this.userContext,
    required this.relatedReports,
    this.history,
    required this.suggestedActions,
    required this.addedAt,
    required this.priority,
  });

  @override
  List<Object?> get props => [
        queueId,
        itemType,
        content,
        userContext,
        relatedReports,
        history,
        suggestedActions,
        addedAt,
        priority,
      ];
}

/// Moderation item content
class ModerationItemContent extends Equatable {
  final String itemId;
  final String? text;
  final List<String>? photoUrls;
  final Map<String, dynamic>? additionalData;
  final DateTime createdAt;

  const ModerationItemContent({
    required this.itemId,
    this.text,
    this.photoUrls,
    this.additionalData,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        itemId,
        text,
        photoUrls,
        additionalData,
        createdAt,
      ];
}

/// User context for moderation
class UserContext extends Equatable {
  final String userId;
  final String displayName;
  final int age;
  final String? photoUrl;
  final DateTime accountCreatedAt;
  final int reportCount;
  final int warningCount;
  final int suspensionCount;
  final bool isVerified;
  final double trustScore;
  final String accountStatus;

  const UserContext({
    required this.userId,
    required this.displayName,
    required this.age,
    this.photoUrl,
    required this.accountCreatedAt,
    required this.reportCount,
    required this.warningCount,
    required this.suspensionCount,
    required this.isVerified,
    required this.trustScore,
    required this.accountStatus,
  });

  @override
  List<Object?> get props => [
        userId,
        displayName,
        age,
        photoUrl,
        accountCreatedAt,
        reportCount,
        warningCount,
        suspensionCount,
        isVerified,
        trustScore,
        accountStatus,
      ];
}

/// Related report
class RelatedReport extends Equatable {
  final String reportId;
  final String reporterId;
  final String category;
  final String description;
  final DateTime createdAt;
  final List<String> screenshotUrls;

  const RelatedReport({
    required this.reportId,
    required this.reporterId,
    required this.category,
    required this.description,
    required this.createdAt,
    required this.screenshotUrls,
  });

  @override
  List<Object?> get props => [
        reportId,
        reporterId,
        category,
        description,
        createdAt,
        screenshotUrls,
      ];
}

/// Moderation history
class ModerationHistory extends Equatable {
  final List<PastModerationAction> pastActions;
  final int totalWarnings;
  final int totalSuspensions;
  final int totalBans;
  final DateTime? lastActionAt;

  const ModerationHistory({
    required this.pastActions,
    required this.totalWarnings,
    required this.totalSuspensions,
    required this.totalBans,
    this.lastActionAt,
  });

  @override
  List<Object?> get props => [
        pastActions,
        totalWarnings,
        totalSuspensions,
        totalBans,
        lastActionAt,
      ];
}

/// Past moderation action
class PastModerationAction extends Equatable {
  final String actionType;
  final String reason;
  final String moderatorId;
  final DateTime actionAt;

  const PastModerationAction({
    required this.actionType,
    required this.reason,
    required this.moderatorId,
    required this.actionAt,
  });

  @override
  List<Object?> get props => [actionType, reason, moderatorId, actionAt];
}

/// Suggested action with AI confidence
class SuggestedAction extends Equatable {
  final ModerationActionType actionType;
  final double confidence; // 0-1
  final String reasoning;
  final Map<String, dynamic> parameters;

  const SuggestedAction({
    required this.actionType,
    required this.confidence,
    required this.reasoning,
    required this.parameters,
  });

  @override
  List<Object?> get props => [actionType, confidence, reasoning, parameters];
}

/// Moderation action types (Point 248)
enum ModerationActionType {
  approve,
  dismiss,
  removeContent,
  issueWarning,
  suspendUser,
  banUser,
  shadowBan,
  requireVerification,
  escalate,
  requestMoreInfo,
}

/// Moderation action result (Point 248)
class ModerationActionResult extends Equatable {
  final String queueId;
  final ModerationActionType action;
  final String moderatorId;
  final String? notes;
  final DateTime actionAt;
  final bool success;
  final String? errorMessage;

  const ModerationActionResult({
    required this.queueId,
    required this.action,
    required this.moderatorId,
    this.notes,
    required this.actionAt,
    required this.success,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        queueId,
        action,
        moderatorId,
        notes,
        actionAt,
        success,
        errorMessage,
      ];
}

/// Bulk moderation operation (Point 249)
class BulkModerationOperation extends Equatable {
  final String operationId;
  final List<String> queueIds;
  final ModerationActionType action;
  final String moderatorId;
  final String? notes;
  final DateTime initiatedAt;
  final BulkOperationStatus status;
  final int totalItems;
  final int processedItems;
  final int successCount;
  final int failureCount;
  final List<BulkOperationResult> results;

  const BulkModerationOperation({
    required this.operationId,
    required this.queueIds,
    required this.action,
    required this.moderatorId,
    this.notes,
    required this.initiatedAt,
    required this.status,
    required this.totalItems,
    required this.processedItems,
    required this.successCount,
    required this.failureCount,
    required this.results,
  });

  double get progressPercentage =>
      totalItems > 0 ? (processedItems / totalItems) * 100 : 0;

  @override
  List<Object?> get props => [
        operationId,
        queueIds,
        action,
        moderatorId,
        notes,
        initiatedAt,
        status,
        totalItems,
        processedItems,
        successCount,
        failureCount,
        results,
      ];
}

/// Bulk operation status
enum BulkOperationStatus {
  pending,
  inProgress,
  completed,
  failed,
  partialSuccess,
}

/// Bulk operation result
class BulkOperationResult extends Equatable {
  final String queueId;
  final bool success;
  final String? errorMessage;

  const BulkOperationResult({
    required this.queueId,
    required this.success,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [queueId, success, errorMessage];
}

/// Moderation statistics (Point 250)
class ModerationStatistics extends Equatable {
  final int totalPendingReports;
  final int totalAssignedReports;
  final int totalResolvedToday;
  final int totalResolvedWeek;
  final int totalResolvedMonth;
  final double avgResolutionTime; // Minutes
  final Map<String, int> reportsByCategory;
  final Map<String, int> actionsByType;
  final Map<String, ModeratorStats> moderatorStats;
  final List<TrendingIssue> trendingIssues;
  final DateTime calculatedAt;

  const ModerationStatistics({
    required this.totalPendingReports,
    required this.totalAssignedReports,
    required this.totalResolvedToday,
    required this.totalResolvedWeek,
    required this.totalResolvedMonth,
    required this.avgResolutionTime,
    required this.reportsByCategory,
    required this.actionsByType,
    required this.moderatorStats,
    required this.trendingIssues,
    required this.calculatedAt,
  });

  @override
  List<Object?> get props => [
        totalPendingReports,
        totalAssignedReports,
        totalResolvedToday,
        totalResolvedWeek,
        totalResolvedMonth,
        avgResolutionTime,
        reportsByCategory,
        actionsByType,
        moderatorStats,
        trendingIssues,
        calculatedAt,
      ];
}

/// Moderator statistics
class ModeratorStats extends Equatable {
  final String moderatorId;
  final String moderatorName;
  final int totalReviewed;
  final int reviewedToday;
  final int reviewedWeek;
  final int reviewedMonth;
  final double avgResolutionTime; // Minutes
  final Map<String, int> actionBreakdown;
  final double accuracy; // Percentage (based on appeal success rate)

  const ModeratorStats({
    required this.moderatorId,
    required this.moderatorName,
    required this.totalReviewed,
    required this.reviewedToday,
    required this.reviewedWeek,
    required this.reviewedMonth,
    required this.avgResolutionTime,
    required this.actionBreakdown,
    required this.accuracy,
  });

  @override
  List<Object?> get props => [
        moderatorId,
        moderatorName,
        totalReviewed,
        reviewedToday,
        reviewedWeek,
        reviewedMonth,
        avgResolutionTime,
        actionBreakdown,
        accuracy,
      ];
}

/// Trending issue
class TrendingIssue extends Equatable {
  final String category;
  final int reportCount;
  final double growthRate; // Percentage change from previous period
  final TrendDirection trend;

  const TrendingIssue({
    required this.category,
    required this.reportCount,
    required this.growthRate,
    required this.trend,
  });

  @override
  List<Object?> get props => [category, reportCount, growthRate, trend];
}

/// Trend direction
enum TrendDirection {
  increasing,
  decreasing,
  stable,
}
