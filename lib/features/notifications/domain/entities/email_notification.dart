/**
 * Email Notification Entity
 * Points 281-285: Email communication system
 */

import 'package:equatable/equatable.dart';

/// Email notification (Point 281)
class EmailNotification extends Equatable {
  final String emailId;
  final String userId;
  final String recipientEmail;
  final EmailType type;
  final String subject;
  final String htmlBody;
  final String? textBody;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final EmailStatus status;
  final String? sendGridId;
  final Map<String, dynamic> templateData;

  const EmailNotification({
    required this.emailId,
    required this.userId,
    required this.recipientEmail,
    required this.type,
    required this.subject,
    required this.htmlBody,
    this.textBody,
    required this.createdAt,
    this.scheduledFor,
    this.sentAt,
    required this.status,
    this.sendGridId,
    required this.templateData,
  });

  @override
  List<Object?> get props => [
        emailId,
        userId,
        recipientEmail,
        type,
        subject,
        htmlBody,
        textBody,
        createdAt,
        scheduledFor,
        sentAt,
        status,
        sendGridId,
        templateData,
      ];
}

/// Email types (Points 283-285)
enum EmailType {
  welcome,
  welcomeSeries,
  weeklyDigest,
  matchNotification,
  messageNotification,
  subscriptionConfirmation,
  subscriptionExpiring,
  reEngagement,
  passwordReset,
  emailVerification,
  accountSuspended,
  promotional;

  String get displayName {
    switch (this) {
      case EmailType.welcome:
        return 'Welcome Email';
      case EmailType.welcomeSeries:
        return 'Welcome Series';
      case EmailType.weeklyDigest:
        return 'Weekly Digest';
      case EmailType.matchNotification:
        return 'Match Notification';
      case EmailType.messageNotification:
        return 'Message Notification';
      case EmailType.subscriptionConfirmation:
        return 'Subscription Confirmation';
      case EmailType.subscriptionExpiring:
        return 'Subscription Expiring';
      case EmailType.reEngagement:
        return 'Re-engagement';
      case EmailType.passwordReset:
        return 'Password Reset';
      case EmailType.emailVerification:
        return 'Email Verification';
      case EmailType.accountSuspended:
        return 'Account Suspended';
      case EmailType.promotional:
        return 'Promotional';
    }
  }
}

/// Email status
enum EmailStatus {
  pending,
  scheduled,
  sent,
  delivered,
  opened,
  clicked,
  bounced,
  failed;

  bool get isSuccessful => this == EmailStatus.delivered ||
                          this == EmailStatus.opened ||
                          this == EmailStatus.clicked;
}

/// Welcome email series (Point 283)
class WelcomeEmailSeries extends Equatable {
  final String seriesId;
  final String userId;
  final DateTime startedAt;
  final List<WelcomeEmailStep> steps;
  final int currentStep;
  final bool isCompleted;

  const WelcomeEmailSeries({
    required this.seriesId,
    required this.userId,
    required this.startedAt,
    required this.steps,
    required this.currentStep,
    required this.isCompleted,
  });

  /// 7-day welcome series (Point 283)
  static List<WelcomeEmailStep> get defaultSteps => [
        const WelcomeEmailStep(
          stepNumber: 1,
          delayDays: 0,
          subject: 'Welcome to GreenGo! Let\'s get started',
          template: 'welcome_day_1',
        ),
        const WelcomeEmailStep(
          stepNumber: 2,
          delayDays: 1,
          subject: 'Complete your profile to get more matches',
          template: 'welcome_day_2',
        ),
        const WelcomeEmailStep(
          stepNumber: 3,
          delayDays: 3,
          subject: 'Tips for making great connections',
          template: 'welcome_day_3',
        ),
        const WelcomeEmailStep(
          stepNumber: 4,
          delayDays: 5,
          subject: 'Unlock premium features',
          template: 'welcome_day_5',
        ),
        const WelcomeEmailStep(
          stepNumber: 5,
          delayDays: 7,
          subject: 'Your first week recap',
          template: 'welcome_day_7',
        ),
      ];

  @override
  List<Object?> get props => [
        seriesId,
        userId,
        startedAt,
        steps,
        currentStep,
        isCompleted,
      ];
}

/// Welcome email step
class WelcomeEmailStep extends Equatable {
  final int stepNumber;
  final int delayDays;
  final String subject;
  final String template;
  final DateTime? sentAt;
  final bool isSent;

  const WelcomeEmailStep({
    required this.stepNumber,
    required this.delayDays,
    required this.subject,
    required this.template,
    this.sentAt,
    this.isSent = false,
  });

  @override
  List<Object?> get props => [
        stepNumber,
        delayDays,
        subject,
        template,
        sentAt,
        isSent,
      ];
}

/// Weekly digest email (Point 284)
class WeeklyDigestEmail extends Equatable {
  final String digestId;
  final String userId;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final WeeklyDigestData data;
  final bool wasSent;
  final DateTime? sentAt;

  const WeeklyDigestEmail({
    required this.digestId,
    required this.userId,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.data,
    required this.wasSent,
    this.sentAt,
  });

  @override
  List<Object?> get props => [
        digestId,
        userId,
        weekStartDate,
        weekEndDate,
        data,
        wasSent,
        sentAt,
      ];
}

/// Weekly digest data (Point 284)
class WeeklyDigestData extends Equatable {
  final int newMatches;
  final int newMessages;
  final int profileViews;
  final int newLikes;
  final List<MatchHighlight> matchHighlights;
  final List<String> weeklyTips;
  final String? featuredPromotion;

  const WeeklyDigestData({
    required this.newMatches,
    required this.newMessages,
    required this.profileViews,
    required this.newLikes,
    required this.matchHighlights,
    required this.weeklyTips,
    this.featuredPromotion,
  });

  bool get hasActivity =>
      newMatches > 0 || newMessages > 0 || profileViews > 0 || newLikes > 0;

  @override
  List<Object?> get props => [
        newMatches,
        newMessages,
        profileViews,
        newLikes,
        matchHighlights,
        weeklyTips,
        featuredPromotion,
      ];
}

/// Match highlight for digest
class MatchHighlight extends Equatable {
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final int messageCount;
  final DateTime matchedAt;

  const MatchHighlight({
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    required this.messageCount,
    required this.matchedAt,
  });

  @override
  List<Object?> get props => [
        matchId,
        otherUserId,
        otherUserName,
        otherUserPhotoUrl,
        messageCount,
        matchedAt,
      ];
}

/// Re-engagement campaign (Point 285)
class ReEngagementCampaign extends Equatable {
  final String campaignId;
  final String name;
  final ReEngagementTrigger trigger;
  final int targetDaysInactive;
  final EmailTemplate template;
  final PersonalizationStrategy personalization;
  final bool isActive;
  final DateTime createdAt;

  const ReEngagementCampaign({
    required this.campaignId,
    required this.name,
    required this.trigger,
    required this.targetDaysInactive,
    required this.template,
    required this.personalization,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        campaignId,
        name,
        trigger,
        targetDaysInactive,
        template,
        personalization,
        isActive,
        createdAt,
      ];
}

/// Re-engagement triggers (Point 285)
enum ReEngagementTrigger {
  dormant14Days,
  dormant30Days,
  dormant60Days,
  noMatches,
  noMessages,
  incompleteProfile,
  expiredSubscription;

  String get displayName {
    switch (this) {
      case ReEngagementTrigger.dormant14Days:
        return '14 Days Inactive';
      case ReEngagementTrigger.dormant30Days:
        return '30 Days Inactive';
      case ReEngagementTrigger.dormant60Days:
        return '60 Days Inactive';
      case ReEngagementTrigger.noMatches:
        return 'No Matches Yet';
      case ReEngagementTrigger.noMessages:
        return 'No Messages Sent';
      case ReEngagementTrigger.incompleteProfile:
        return 'Incomplete Profile';
      case ReEngagementTrigger.expiredSubscription:
        return 'Expired Subscription';
    }
  }
}

/// Email template (Point 282)
class EmailTemplate extends Equatable {
  final String templateId;
  final String name;
  final String subject;
  final String htmlContent;
  final String? textContent;
  final EmailBranding branding;
  final List<TemplatePlaceholder> placeholders;

  const EmailTemplate({
    required this.templateId,
    required this.name,
    required this.subject,
    required this.htmlContent,
    this.textContent,
    required this.branding,
    required this.placeholders,
  });

  @override
  List<Object?> get props => [
        templateId,
        name,
        subject,
        htmlContent,
        textContent,
        branding,
        placeholders,
      ];
}

/// Email branding (Point 282)
class EmailBranding extends Equatable {
  final String backgroundColor; // #000000 (black)
  final String primaryColor; // #FFD700 (gold)
  final String textColor; // #FFFFFF (white)
  final String logoUrl;
  final String footerText;
  final Map<String, String> socialLinks;

  const EmailBranding({
    this.backgroundColor = '#000000',
    this.primaryColor = '#FFD700',
    this.textColor = '#FFFFFF',
    required this.logoUrl,
    required this.footerText,
    required this.socialLinks,
  });

  @override
  List<Object?> get props => [
        backgroundColor,
        primaryColor,
        textColor,
        logoUrl,
        footerText,
        socialLinks,
      ];
}

/// Template placeholder
class TemplatePlaceholder extends Equatable {
  final String key;
  final String description;
  final bool isRequired;

  const TemplatePlaceholder({
    required this.key,
    required this.description,
    required this.isRequired,
  });

  @override
  List<Object?> get props => [key, description, isRequired];
}

/// Personalization strategy (Point 285)
enum PersonalizationStrategy {
  basic,
  advanced,
  aiPowered;

  String get description {
    switch (this) {
      case PersonalizationStrategy.basic:
        return 'Use name and basic profile info';
      case PersonalizationStrategy.advanced:
        return 'Include activity stats and preferences';
      case PersonalizationStrategy.aiPowered:
        return 'AI-generated personalized content based on behavior';
    }
  }
}

/// Email analytics
class EmailAnalytics extends Equatable {
  final String emailId;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? openedAt;
  final DateTime? clickedAt;
  final int openCount;
  final int clickCount;
  final List<String> clickedLinks;
  final String? bounceReason;
  final String? failureReason;

  const EmailAnalytics({
    required this.emailId,
    required this.sentAt,
    this.deliveredAt,
    this.openedAt,
    this.clickedAt,
    required this.openCount,
    required this.clickCount,
    required this.clickedLinks,
    this.bounceReason,
    this.failureReason,
  });

  bool get wasDelivered => deliveredAt != null;
  bool get wasOpened => openedAt != null;
  bool get wasClicked => clickedAt != null;
  bool get hasBounced => bounceReason != null;

  @override
  List<Object?> get props => [
        emailId,
        sentAt,
        deliveredAt,
        openedAt,
        clickedAt,
        openCount,
        clickCount,
        clickedLinks,
        bounceReason,
        failureReason,
      ];
}
