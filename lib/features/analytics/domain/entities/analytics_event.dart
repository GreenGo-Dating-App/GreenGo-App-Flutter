/**
 * Analytics Event Entity
 * Points 251-255: User analytics and event tracking
 */

import 'package:equatable/equatable.dart';

/// Analytics event (Points 251-252)
class AnalyticsEvent extends Equatable {
  final String eventName;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;

  const AnalyticsEvent({
    required this.eventName,
    required this.parameters,
    required this.timestamp,
    this.userId,
    this.sessionId,
  });

  @override
  List<Object?> get props => [
        eventName,
        parameters,
        timestamp,
        userId,
        sessionId,
      ];
}

/// Critical events (Point 252)
enum CriticalEvent {
  matchMade,
  messageSent,
  videoCallStarted,
  subscriptionPurchased,
  profileCreated,
  photoUploaded,
  likeSent,
  superLikeSent,
  boostActivated,
  coinPurchased,
  achievementUnlocked,
  levelUp,
  reportSubmitted,
  verificationCompleted,
}

extension CriticalEventExtension on CriticalEvent {
  String get eventName {
    switch (this) {
      case CriticalEvent.matchMade:
        return 'match_made';
      case CriticalEvent.messageSent:
        return 'message_sent';
      case CriticalEvent.videoCallStarted:
        return 'video_call_started';
      case CriticalEvent.subscriptionPurchased:
        return 'subscription_purchased';
      case CriticalEvent.profileCreated:
        return 'profile_created';
      case CriticalEvent.photoUploaded:
        return 'photo_uploaded';
      case CriticalEvent.likeSent:
        return 'like_sent';
      case CriticalEvent.superLikeSent:
        return 'super_like_sent';
      case CriticalEvent.boostActivated:
        return 'boost_activated';
      case CriticalEvent.coinPurchased:
        return 'coin_purchased';
      case CriticalEvent.achievementUnlocked:
        return 'achievement_unlocked';
      case CriticalEvent.levelUp:
        return 'level_up';
      case CriticalEvent.reportSubmitted:
        return 'report_submitted';
      case CriticalEvent.verificationCompleted:
        return 'verification_completed';
    }
  }
}

/// Screen view event (Point 251)
class ScreenViewEvent extends AnalyticsEvent {
  final String screenName;
  final String? previousScreen;
  final Duration? timeOnPreviousScreen;

  ScreenViewEvent({
    required this.screenName,
    this.previousScreen,
    this.timeOnPreviousScreen,
    String? userId,
    String? sessionId,
  }) : super(
          eventName: 'screen_view',
          parameters: {
            'screen_name': screenName,
            if (previousScreen != null) 'previous_screen': previousScreen,
            if (timeOnPreviousScreen != null)
              'time_on_previous_screen': timeOnPreviousScreen.inSeconds,
          },
          timestamp: DateTime.now(),
          userId: userId,
          sessionId: sessionId,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        screenName,
        previousScreen,
        timeOnPreviousScreen,
      ];
}

/// User journey funnel (Point 253)
class UserJourneyFunnel extends Equatable {
  final String funnelName;
  final List<FunnelStep> steps;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final double conversionRate;

  const UserJourneyFunnel({
    required this.funnelName,
    required this.steps,
    required this.startedAt,
    this.completedAt,
    required this.isCompleted,
    required this.conversionRate,
  });

  @override
  List<Object?> get props => [
        funnelName,
        steps,
        startedAt,
        completedAt,
        isCompleted,
        conversionRate,
      ];
}

/// Funnel step
class FunnelStep extends Equatable {
  final String stepName;
  final int stepOrder;
  final DateTime? completedAt;
  final bool isCompleted;
  final Map<String, dynamic>? metadata;

  const FunnelStep({
    required this.stepName,
    required this.stepOrder,
    this.completedAt,
    required this.isCompleted,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        stepName,
        stepOrder,
        completedAt,
        isCompleted,
        metadata,
      ];
}

/// Predefined funnels (Point 253)
enum FunnelType {
  signupToFirstMatch,
  freeToSubscriber,
  firstMessageToVideoCall,
  discoveryToMatch,
  matchToConversation,
}

extension FunnelTypeExtension on FunnelType {
  String get name {
    switch (this) {
      case FunnelType.signupToFirstMatch:
        return 'Signup to First Match';
      case FunnelType.freeToSubscriber:
        return 'Free to Subscriber';
      case FunnelType.firstMessageToVideoCall:
        return 'First Message to Video Call';
      case FunnelType.discoveryToMatch:
        return 'Discovery to Match';
      case FunnelType.matchToConversation:
        return 'Match to Conversation';
    }
  }

  List<String> get steps {
    switch (this) {
      case FunnelType.signupToFirstMatch:
        return [
          'account_created',
          'profile_completed',
          'photo_uploaded',
          'first_like_sent',
          'first_match_made',
        ];
      case FunnelType.freeToSubscriber:
        return [
          'subscription_page_viewed',
          'tier_selected',
          'payment_initiated',
          'subscription_purchased',
        ];
      case FunnelType.firstMessageToVideoCall:
        return [
          'first_message_sent',
          'conversation_active',
          'video_call_button_tapped',
          'video_call_started',
        ];
      case FunnelType.discoveryToMatch:
        return [
          'discovery_page_opened',
          'profile_viewed',
          'like_sent',
          'match_made',
        ];
      case FunnelType.matchToConversation:
        return [
          'match_made',
          'match_notification_tapped',
          'conversation_opened',
          'first_message_sent',
        ];
    }
  }
}

/// User cohort (Point 254)
class UserCohort extends Equatable {
  final String cohortId;
  final String cohortName;
  final DateTime acquisitionDate;
  final int totalUsers;
  final Map<int, double> retentionByDay; // Day 1, 7, 14, 30, 60, 90
  final Map<String, dynamic> characteristics;

  const UserCohort({
    required this.cohortId,
    required this.cohortName,
    required this.acquisitionDate,
    required this.totalUsers,
    required this.retentionByDay,
    required this.characteristics,
  });

  double get day1Retention => retentionByDay[1] ?? 0.0;
  double get day7Retention => retentionByDay[7] ?? 0.0;
  double get day30Retention => retentionByDay[30] ?? 0.0;

  @override
  List<Object?> get props => [
        cohortId,
        cohortName,
        acquisitionDate,
        totalUsers,
        retentionByDay,
        characteristics,
      ];
}

/// User segment (Point 255)
enum UserSegment {
  powerUser,
  casualUser,
  dormantUser,
  churnedUser,
  newUser,
  returningUser;

  String get displayName {
    switch (this) {
      case UserSegment.powerUser:
        return 'Power User';
      case UserSegment.casualUser:
        return 'Casual User';
      case UserSegment.dormantUser:
        return 'Dormant User';
      case UserSegment.churnedUser:
        return 'Churned User';
      case UserSegment.newUser:
        return 'New User';
      case UserSegment.returningUser:
        return 'Returning User';
    }
  }

  String get description {
    switch (this) {
      case UserSegment.powerUser:
        return 'Active daily, high engagement (10+ sessions/week)';
      case UserSegment.casualUser:
        return 'Active weekly, moderate engagement (2-5 sessions/week)';
      case UserSegment.dormantUser:
        return 'Inactive for 14-30 days, low engagement';
      case UserSegment.churnedUser:
        return 'Inactive for 30+ days, likely churned';
      case UserSegment.newUser:
        return 'Signed up within last 7 days';
      case UserSegment.returningUser:
        return 'Returned after 30+ days of inactivity';
    }
  }
}

/// User segmentation profile (Point 255)
class UserSegmentProfile extends Equatable {
  final String userId;
  final UserSegment segment;
  final DateTime assignedAt;
  final Map<String, dynamic> behaviorMetrics;
  final double engagementScore; // 0-100

  const UserSegmentProfile({
    required this.userId,
    required this.segment,
    required this.assignedAt,
    required this.behaviorMetrics,
    required this.engagementScore,
  });

  @override
  List<Object?> get props => [
        userId,
        segment,
        assignedAt,
        behaviorMetrics,
        engagementScore,
      ];
}

/// Behavior metrics for segmentation
class BehaviorMetrics extends Equatable {
  final int sessionsPerWeek;
  final int messagesPerWeek;
  final int matchesPerWeek;
  final Duration avgSessionDuration;
  final int daysSinceLastActive;
  final int totalDaysActive;
  final double featureAdoptionRate; // Percentage of features used

  const BehaviorMetrics({
    required this.sessionsPerWeek,
    required this.messagesPerWeek,
    required this.matchesPerWeek,
    required this.avgSessionDuration,
    required this.daysSinceLastActive,
    required this.totalDaysActive,
    required this.featureAdoptionRate,
  });

  /// Calculate user segment based on metrics (Point 255)
  UserSegment calculateSegment() {
    // Churned: 30+ days inactive
    if (daysSinceLastActive >= 30) {
      return UserSegment.churnedUser;
    }

    // Dormant: 14-30 days inactive
    if (daysSinceLastActive >= 14) {
      return UserSegment.dormantUser;
    }

    // New: Account less than 7 days old
    if (totalDaysActive <= 7) {
      return UserSegment.newUser;
    }

    // Power User: 10+ sessions/week, high engagement
    if (sessionsPerWeek >= 10 &&
        messagesPerWeek >= 20 &&
        avgSessionDuration.inMinutes >= 15) {
      return UserSegment.powerUser;
    }

    // Casual User: 2-5 sessions/week
    if (sessionsPerWeek >= 2 && sessionsPerWeek <= 5) {
      return UserSegment.casualUser;
    }

    // Returning User: Was inactive 30+ days, now active
    if (daysSinceLastActive == 0 && totalDaysActive > 7) {
      return UserSegment.returningUser;
    }

    return UserSegment.casualUser; // Default
  }

  @override
  List<Object?> get props => [
        sessionsPerWeek,
        messagesPerWeek,
        matchesPerWeek,
        avgSessionDuration,
        daysSinceLastActive,
        totalDaysActive,
        featureAdoptionRate,
      ];
}

/// Churn prediction (Point 256)
class ChurnPrediction extends Equatable {
  final String userId;
  final double churnProbability; // 0.0 - 1.0
  final ChurnRisk riskLevel;
  final List<ChurnFactor> contributingFactors;
  final DateTime predictedAt;
  final DateTime? predictedChurnDate;
  final List<String> recommendedInterventions;

  const ChurnPrediction({
    required this.userId,
    required this.churnProbability,
    required this.riskLevel,
    required this.contributingFactors,
    required this.predictedAt,
    this.predictedChurnDate,
    required this.recommendedInterventions,
  });

  @override
  List<Object?> get props => [
        userId,
        churnProbability,
        riskLevel,
        contributingFactors,
        predictedAt,
        predictedChurnDate,
        recommendedInterventions,
      ];
}

/// Churn risk levels
enum ChurnRisk {
  low, // < 30%
  medium, // 30-60%
  high, // 60-80%
  critical; // > 80%

  static ChurnRisk fromProbability(double probability) {
    if (probability >= 0.8) return ChurnRisk.critical;
    if (probability >= 0.6) return ChurnRisk.high;
    if (probability >= 0.3) return ChurnRisk.medium;
    return ChurnRisk.low;
  }
}

/// Churn contributing factor
class ChurnFactor extends Equatable {
  final String factorName;
  final double impact; // -1.0 to 1.0 (negative = increases churn)
  final String description;

  const ChurnFactor({
    required this.factorName,
    required this.impact,
    required this.description,
  });

  @override
  List<Object?> get props => [factorName, impact, description];
}

/// A/B Test experiment (Point 257)
class ABTestExperiment extends Equatable {
  final String experimentId;
  final String experimentName;
  final String description;
  final ABTestVariant assignedVariant;
  final DateTime assignedAt;
  final Map<String, dynamic> variantConfig;
  final bool hasConverted;
  final DateTime? convertedAt;

  const ABTestExperiment({
    required this.experimentId,
    required this.experimentName,
    required this.description,
    required this.assignedVariant,
    required this.assignedAt,
    required this.variantConfig,
    required this.hasConverted,
    this.convertedAt,
  });

  @override
  List<Object?> get props => [
        experimentId,
        experimentName,
        description,
        assignedVariant,
        assignedAt,
        variantConfig,
        hasConverted,
        convertedAt,
      ];
}

/// A/B test variant
enum ABTestVariant {
  control,
  variantA,
  variantB,
  variantC;

  String get displayName {
    switch (this) {
      case ABTestVariant.control:
        return 'Control';
      case ABTestVariant.variantA:
        return 'Variant A';
      case ABTestVariant.variantB:
        return 'Variant B';
      case ABTestVariant.variantC:
        return 'Variant C';
    }
  }
}

/// Heatmap data (Point 258)
class HeatmapData extends Equatable {
  final String screenName;
  final List<TouchPoint> touchPoints;
  final DateTime collectedAt;
  final String deviceType;
  final String screenResolution;

  const HeatmapData({
    required this.screenName,
    required this.touchPoints,
    required this.collectedAt,
    required this.deviceType,
    required this.screenResolution,
  });

  @override
  List<Object?> get props => [
        screenName,
        touchPoints,
        collectedAt,
        deviceType,
        screenResolution,
      ];
}

/// Touch point for heatmap
class TouchPoint extends Equatable {
  final double x; // Normalized 0-1
  final double y; // Normalized 0-1
  final TouchType type;
  final DateTime timestamp;
  final String? elementId;

  const TouchPoint({
    required this.x,
    required this.y,
    required this.type,
    required this.timestamp,
    this.elementId,
  });

  @override
  List<Object?> get props => [x, y, type, timestamp, elementId];
}

/// Touch types
enum TouchType {
  tap,
  longPress,
  swipe,
  scroll,
}

/// Attribution data (Point 260)
class AttributionData extends Equatable {
  final String userId;
  final String installSource; // Google Ads, Facebook, Organic, etc.
  final String? campaignId;
  final String? adGroup;
  final String? creative;
  final String? keyword;
  final DateTime installDate;
  final Map<String, dynamic> utmParameters;

  const AttributionData({
    required this.userId,
    required this.installSource,
    this.campaignId,
    this.adGroup,
    this.creative,
    this.keyword,
    required this.installDate,
    required this.utmParameters,
  });

  @override
  List<Object?> get props => [
        userId,
        installSource,
        campaignId,
        adGroup,
        creative,
        keyword,
        installDate,
        utmParameters,
      ];
}
