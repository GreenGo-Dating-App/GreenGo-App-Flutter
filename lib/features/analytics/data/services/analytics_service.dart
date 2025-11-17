/**
 * Analytics Service
 * Points 251-260: Firebase Analytics integration and tracking
 */

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../domain/entities/analytics_event.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  String? _currentScreenName;
  DateTime? _screenStartTime;
  String? _currentSessionId;

  /// Initialize analytics (Point 251)
  Future<void> initialize() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();

    // Set default user properties
    await _analytics.setUserProperty(
      name: 'app_version',
      value: '1.0.0', // Replace with actual version
    );
  }

  /// Log screen view (Point 251)
  Future<void> logScreenView(String screenName) async {
    final now = DateTime.now();
    Duration? timeOnPreviousScreen;

    if (_currentScreenName != null && _screenStartTime != null) {
      timeOnPreviousScreen = now.difference(_screenStartTime!);

      // Log time spent on previous screen
      await _analytics.logEvent(
        name: 'screen_time',
        parameters: {
          'screen_name': _currentScreenName!,
          'duration_seconds': timeOnPreviousScreen.inSeconds,
        },
      );
    }

    // Log screen view
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );

    // Track additional screen view data
    await _analytics.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': screenName,
        'previous_screen': _currentScreenName ?? 'none',
        'time_on_previous_screen': timeOnPreviousScreen?.inSeconds ?? 0,
        'session_id': _currentSessionId,
      },
    );

    _currentScreenName = screenName;
    _screenStartTime = now;
  }

  /// Log button click (Point 251)
  Future<void> logButtonClick(String buttonName, {String? screenName}) async {
    await _analytics.logEvent(
      name: 'button_click',
      parameters: {
        'button_name': buttonName,
        'screen_name': screenName ?? _currentScreenName ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log feature usage (Point 251)
  Future<void> logFeatureUsage(
    String featureName, {
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: 'feature_used',
      parameters: {
        'feature_name': featureName,
        'screen_name': _currentScreenName ?? 'unknown',
        ...?parameters,
      },
    );
  }

  /// Log critical events (Point 252)
  Future<void> logCriticalEvent(
    CriticalEvent event, {
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: event.eventName,
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': _currentSessionId,
        ...?parameters,
      },
    );
  }

  /// Log match made (Point 252)
  Future<void> logMatchMade({
    required String matchId,
    required String otherUserId,
    required String matchSource,
  }) async {
    await logCriticalEvent(
      CriticalEvent.matchMade,
      parameters: {
        'match_id': matchId,
        'other_user_id': otherUserId,
        'match_source': matchSource,
      },
    );
  }

  /// Log message sent (Point 252)
  Future<void> logMessageSent({
    required String conversationId,
    required String messageType,
    bool isFirstMessage = false,
  }) async {
    await logCriticalEvent(
      CriticalEvent.messageSent,
      parameters: {
        'conversation_id': conversationId,
        'message_type': messageType,
        'is_first_message': isFirstMessage,
      },
    );
  }

  /// Log video call started (Point 252)
  Future<void> logVideoCallStarted({
    required String callId,
    required String otherUserId,
    required Duration callDuration,
  }) async {
    await logCriticalEvent(
      CriticalEvent.videoCallStarted,
      parameters: {
        'call_id': callId,
        'other_user_id': otherUserId,
        'call_duration_seconds': callDuration.inSeconds,
      },
    );
  }

  /// Log subscription purchased (Point 252)
  Future<void> logSubscriptionPurchased({
    required String tier,
    required String billingPeriod,
    required double price,
    required String currency,
  }) async {
    await logCriticalEvent(
      CriticalEvent.subscriptionPurchased,
      parameters: {
        'tier': tier,
        'billing_period': billingPeriod,
        'price': price,
        'currency': currency,
      },
    );

    // Also log as purchase event for revenue tracking
    await _analytics.logPurchase(
      value: price,
      currency: currency,
      parameters: {
        'item_name': 'subscription_$tier',
        'item_category': 'subscription',
      },
    );
  }

  /// Track funnel step (Point 253)
  Future<void> trackFunnelStep({
    required FunnelType funnelType,
    required String stepName,
    required int stepOrder,
    Map<String, dynamic>? metadata,
  }) async {
    await _analytics.logEvent(
      name: 'funnel_step',
      parameters: {
        'funnel_name': funnelType.name,
        'step_name': stepName,
        'step_order': stepOrder,
        'timestamp': DateTime.now().toIso8601String(),
        ...?metadata,
      },
    );
  }

  /// Track funnel completion (Point 253)
  Future<void> trackFunnelCompletion({
    required FunnelType funnelType,
    required Duration completionTime,
    required int totalSteps,
  }) async {
    await _analytics.logEvent(
      name: 'funnel_completed',
      parameters: {
        'funnel_name': funnelType.name,
        'completion_time_seconds': completionTime.inSeconds,
        'total_steps': totalSteps,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Set user properties (Point 254)
  Future<void> setUserProperties({
    required String userId,
    String? acquisitionDate,
    String? cohort,
    UserSegment? segment,
  }) async {
    await _analytics.setUserId(id: userId);

    if (acquisitionDate != null) {
      await _analytics.setUserProperty(
        name: 'acquisition_date',
        value: acquisitionDate,
      );
    }

    if (cohort != null) {
      await _analytics.setUserProperty(
        name: 'cohort',
        value: cohort,
      );
    }

    if (segment != null) {
      await _analytics.setUserProperty(
        name: 'user_segment',
        value: segment.displayName,
      );
    }
  }

  /// Track user segment change (Point 255)
  Future<void> trackUserSegmentChange({
    required UserSegment newSegment,
    required UserSegment? previousSegment,
    required double engagementScore,
  }) async {
    await _analytics.logEvent(
      name: 'user_segment_changed',
      parameters: {
        'new_segment': newSegment.displayName,
        'previous_segment': previousSegment?.displayName ?? 'none',
        'engagement_score': engagementScore,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Update user property
    await _analytics.setUserProperty(
      name: 'user_segment',
      value: newSegment.displayName,
    );
  }

  /// A/B Test - Get assigned variant (Point 257)
  Future<ABTestVariant> getABTestVariant(String experimentId) async {
    try {
      await _remoteConfig.fetchAndActivate();

      final variantValue = _remoteConfig.getString(experimentId);

      switch (variantValue.toLowerCase()) {
        case 'variant_a':
          return ABTestVariant.variantA;
        case 'variant_b':
          return ABTestVariant.variantB;
        case 'variant_c':
          return ABTestVariant.variantC;
        default:
          return ABTestVariant.control;
      }
    } catch (e) {
      // Default to control on error
      return ABTestVariant.control;
    }
  }

  /// A/B Test - Log variant assignment (Point 257)
  Future<void> logABTestAssignment({
    required String experimentId,
    required ABTestVariant variant,
  }) async {
    await _analytics.logEvent(
      name: 'ab_test_assigned',
      parameters: {
        'experiment_id': experimentId,
        'variant': variant.displayName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// A/B Test - Log conversion (Point 257)
  Future<void> logABTestConversion({
    required String experimentId,
    required ABTestVariant variant,
    String? conversionType,
  }) async {
    await _analytics.logEvent(
      name: 'ab_test_conversion',
      parameters: {
        'experiment_id': experimentId,
        'variant': variant.displayName,
        'conversion_type': conversionType ?? 'default',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track touch interaction for heatmap (Point 258)
  Future<void> trackTouchInteraction({
    required double x,
    required double y,
    required TouchType type,
    String? elementId,
  }) async {
    await _analytics.logEvent(
      name: 'touch_interaction',
      parameters: {
        'screen_name': _currentScreenName ?? 'unknown',
        'x': x,
        'y': y,
        'type': type.name,
        'element_id': elementId ?? 'none',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Set attribution data (Point 260)
  Future<void> setAttributionData({
    required String installSource,
    String? campaignId,
    String? adGroup,
    String? creative,
    Map<String, String>? utmParameters,
  }) async {
    await _analytics.setUserProperty(
      name: 'install_source',
      value: installSource,
    );

    if (campaignId != null) {
      await _analytics.setUserProperty(
        name: 'campaign_id',
        value: campaignId,
      );
    }

    if (adGroup != null) {
      await _analytics.setUserProperty(
        name: 'ad_group',
        value: adGroup,
      );
    }

    // Log attribution event
    await _analytics.logEvent(
      name: 'app_install',
      parameters: {
        'install_source': installSource,
        'campaign_id': campaignId ?? 'organic',
        'ad_group': adGroup ?? 'none',
        'creative': creative ?? 'none',
        ...?utmParameters,
      },
    );
  }

  /// Log custom event
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: {
        'screen_name': _currentScreenName ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      },
    );
  }

  /// Reset analytics (e.g., on logout)
  Future<void> reset() async {
    await _analytics.setUserId(id: null);
    _currentScreenName = null;
    _screenStartTime = null;
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }
}
