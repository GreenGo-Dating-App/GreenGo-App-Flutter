/// Analytics Service
/// Points 251-260: Firebase Analytics integration and tracking
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../domain/entities/analytics_event.dart';

/// k-anonymity threshold. Any aggregated bucket (age range, country, interest,
/// tier) with FEWER than this many people is dropped so tiny groups can never
/// be de-anonymized. Charts only ever show counts/percentages of buckets that
/// clear this floor — never individual users.
const int kMinBucket = 5;

/// Ordered, privacy-safe age buckets. Individual ages are never surfaced; every
/// audience member is folded into one of these coarse ranges before counting.
const List<String> kAgeBucketOrder = <String>[
  '18-24',
  '25-34',
  '35-44',
  '45-54',
  '55+',
];

/// Immutable, already-anonymized snapshot of an audience's demographics.
///
/// Every map here has ALREADY had k-anonymity applied (buckets below
/// [kMinBucket] removed), so it is safe to render directly. Counts are of
/// people, never identities.
class AudienceAggregate {
  const AudienceAggregate({
    required this.sampleSize,
    required this.ageBuckets,
    required this.topCountries,
    required this.topInterests,
  });

  const AudienceAggregate.empty()
      : sampleSize = 0,
        ageBuckets = const {},
        topCountries = const {},
        topInterests = const {};

  /// How many profiles fed the aggregation (post-cap, pre-filter).
  final int sampleSize;

  /// Age range -> count (k-anon filtered, in [kAgeBucketOrder] order).
  final Map<String, int> ageBuckets;

  /// Country -> count (k-anon filtered, sorted desc, top slice).
  final Map<String, int> topCountries;

  /// Interest -> count (k-anon filtered, sorted desc, top slice).
  final Map<String, int> topInterests;

  /// True once at least one chart has enough people to be shown without risking
  /// de-anonymization. Below this the UI shows a "not enough data yet" state.
  bool get hasData =>
      sampleSize >= kMinBucket &&
      (ageBuckets.isNotEmpty ||
          topCountries.isNotEmpty ||
          topInterests.isNotEmpty);
}

/// Per-event analytics: headline counts + a k-anon [AudienceAggregate].
class EventAudienceAggregate {
  const EventAudienceAggregate({
    required this.goingCount,
    required this.waitlistCount,
    required this.checkedInCount,
    required this.totalAttendees,
    required this.tierBreakdown,
    required this.audience,
  });

  const EventAudienceAggregate.empty()
      : goingCount = 0,
        waitlistCount = 0,
        checkedInCount = 0,
        totalAttendees = 0,
        tierBreakdown = const {},
        audience = const AudienceAggregate.empty();

  final int goingCount;
  final int waitlistCount;
  final int checkedInCount;
  final int totalAttendees;

  /// Ticket-tier id -> going count (k-anon filtered).
  final Map<String, int> tierBreakdown;

  final AudienceAggregate audience;

  /// Fraction of "going" attendees who actually checked in (0..1).
  double get checkInRate =>
      goingCount <= 0 ? 0 : (checkedInCount / goingCount).clamp(0.0, 1.0);
}

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        'session_id': _currentSessionId ?? '',
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
        'session_id': _currentSessionId ?? '',
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

  // ── Lightweight product-analytics helpers (free Firebase Analytics) ─────────
  // Thin wrappers other screens can call to log the core GreenGo funnel.
  // See `// TODO(analytics-wiring)` notes: call sites live in screens owned by
  // other agents (explore/network/events/etc.), so wiring is deferred.

  /// Log a screen view by name (delegates to [logScreenView]).
  Future<void> logScreen(String screenName) => logScreenView(screenName);

  /// Log that a user opened/viewed a specific event.
  Future<void> logEventView(String eventId) async {
    await _analytics.logEvent(
      name: 'event_view',
      parameters: {
        'event_id': eventId,
        'screen_name': _currentScreenName ?? 'unknown',
      },
    );
  }

  /// Log a search query (trimmed; empty queries are ignored).
  Future<void> logSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    await _analytics.logEvent(
      name: 'search',
      parameters: {
        'search_term': q,
        'screen_name': _currentScreenName ?? 'unknown',
      },
    );
  }

  /// Log a new-people connect action.
  Future<void> logConnect({String? otherUserId, String? source}) async {
    await _analytics.logEvent(
      name: 'connect',
      parameters: {
        'other_user_id': otherUserId ?? 'unknown',
        'source': source ?? _currentScreenName ?? 'unknown',
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

  // ══════════════════════════════════════════════════════════════════════════
  // AGGREGATED audience analytics (privacy-safe, k-anonymized).
  //
  // These read the organizer's OWN events + their attendees, then load those
  // attendees' public profiles to build BUCKETED demographics. Nothing here
  // ever returns or renders an individual — only counts of anonymized buckets,
  // and every bucket below [kMinBucket] is dropped.
  //
  // The reads are bounded (capped event count + capped attendee/profile sample)
  // so a single organizer cannot fan out an unbounded query.
  //
  // TODO(cf-preaggregate): At millions-of-users scale this client-side fan-out
  // (events -> attendees -> profiles) is too expensive per open. A Cloud
  // Function should incrementally maintain a pre-computed, already-k-anonymized
  // demographics document (e.g. `organizer_audience/{organizerId}` and
  // `events/{eventId}/audienceAgg`) on each RSVP/check-in write, so the client
  // reads ONE small doc instead of aggregating live. This method is the
  // read-time fallback / small-organizer path only.
  // ══════════════════════════════════════════════════════════════════════════

  /// Aggregate the demographics of a business/organizer's whole audience — the
  /// "going" attendees across their events — into k-anonymized buckets.
  ///
  /// [maxEvents] caps how many of the organizer's events are scanned and
  /// [sampleCap] caps the total number of distinct attendees loaded, so the
  /// work stays bounded regardless of how large the organizer is.
  Future<AudienceAggregate> aggregateBusinessAudience(
    String organizerId, {
    int maxEvents = 50,
    int sampleCap = 500,
  }) async {
    final uids = <String>{};
    try {
      // Single-field equality (organizerId) — no composite index needed.
      final events = await _firestore
          .collection('events')
          .where('organizerId', isEqualTo: organizerId)
          .limit(maxEvents)
          .get();

      for (final ev in events.docs) {
        if (uids.length >= sampleCap) break;
        final attendees = await ev.reference
            .collection('attendees')
            .where('status', isEqualTo: 'going')
            .limit(sampleCap)
            .get();
        for (final a in attendees.docs) {
          final uid = (a.data()['userId'] as String?) ?? a.id;
          if (uid.isNotEmpty) uids.add(uid);
          if (uids.length >= sampleCap) break;
        }
      }
    } catch (_) {
      // Non-fatal: fall through with whatever we gathered.
    }

    final profiles = await _loadProfiles(uids.take(sampleCap).toList());
    return _bucketProfiles(profiles);
  }

  /// Aggregate a SINGLE event's attendees: headline counts (going / waitlist /
  /// checked-in), tier breakdown from the denormalized `tierGoingCounts`, and
  /// a k-anonymized [AudienceAggregate] of the "going" attendees.
  Future<EventAudienceAggregate> aggregateEventAudience(
    String eventId, {
    int sampleCap = 500,
  }) async {
    var going = 0;
    var waitlist = 0;
    var checkedIn = 0;
    var total = 0;
    final tierBreakdown = <String, int>{};
    final goingUids = <String>[];
    Map<String, dynamic>? eventData;

    try {
      final eventSnap =
          await _firestore.collection('events').doc(eventId).get();
      eventData = eventSnap.data();
      final tg = eventData?['tierGoingCounts'];
      if (tg is Map) {
        tg.forEach((k, v) {
          final n = (v as num?)?.toInt() ?? 0;
          if (n > 0) tierBreakdown[k.toString()] = n;
        });
      }
    } catch (_) {
      // Non-fatal.
    }

    try {
      final attendees = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('attendees')
          .limit(sampleCap)
          .get();
      for (final a in attendees.docs) {
        final d = a.data();
        total++;
        final status = d['status'] as String?;
        if (status == 'going') {
          going++;
          if (d['checkedIn'] == true) checkedIn++;
          final uid = (d['userId'] as String?) ?? a.id;
          if (uid.isNotEmpty) goingUids.add(uid);
        } else if (status == 'waitlist') {
          waitlist++;
        }
      }
    } catch (_) {
      // Non-fatal.
    }

    // Trust the maintained counter if it exceeds what the (capped) subcollection
    // read returned, so the headline "going" number is never under-reported.
    final denormGoing = (eventData?['attendeeCount'] as num?)?.toInt() ?? 0;
    if (denormGoing > going) going = denormGoing;

    final profiles = await _loadProfiles(goingUids.take(sampleCap).toList());
    final audience = _bucketProfiles(profiles);

    return EventAudienceAggregate(
      goingCount: going,
      waitlistCount: waitlist,
      checkedInCount: checkedIn,
      totalAttendees: total,
      tierBreakdown: _kAnon(tierBreakdown),
      audience: audience,
    );
  }

  // ── Private aggregation helpers ─────────────────────────────────────────────

  /// Load raw profile docs for [uids] in batches of 10 (Firestore `whereIn`
  /// limit) from the `profiles` collection. Returns the raw data maps.
  Future<List<Map<String, dynamic>>> _loadProfiles(List<String> uids) async {
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < uids.length; i += 10) {
      final batch = uids.skip(i).take(10).toList();
      if (batch.isEmpty) break;
      try {
        final snap = await _firestore
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final d in snap.docs) {
          out.add(d.data());
        }
      } catch (_) {
        // Skip this batch on error; aggregation degrades gracefully.
      }
    }
    return out;
  }

  /// Fold raw profile maps into k-anonymized demographic buckets.
  AudienceAggregate _bucketProfiles(List<Map<String, dynamic>> profiles) {
    final ages = <String, int>{for (final b in kAgeBucketOrder) b: 0};
    final countries = <String, int>{};
    final interests = <String, int>{};

    for (final p in profiles) {
      // Age -> coarse bucket (never the exact age).
      final bucket = _ageBucketOf(p['dateOfBirth']);
      if (bucket != null) ages[bucket] = (ages[bucket] ?? 0) + 1;

      // Country: prefer human-readable location.country, else ISO primaryOrigin.
      final country = _countryOf(p);
      if (country != null && country.isNotEmpty) {
        countries[country] = (countries[country] ?? 0) + 1;
      }

      // Interests (each counted once per person).
      final raw = p['interests'];
      if (raw is List) {
        for (final it in raw) {
          final s = it?.toString().trim() ?? '';
          if (s.isNotEmpty) interests[s] = (interests[s] ?? 0) + 1;
        }
      }
    }

    // k-anon each dimension; keep age order, slice top countries/interests.
    final ageFiltered = <String, int>{
      for (final b in kAgeBucketOrder)
        if ((ages[b] ?? 0) >= kMinBucket) b: ages[b]!,
    };

    return AudienceAggregate(
      sampleSize: profiles.length,
      ageBuckets: ageFiltered,
      topCountries: _topSlice(_kAnon(countries), 8),
      topInterests: _topSlice(_kAnon(interests), 10),
    );
  }

  /// Drop every entry whose count is below [kMinBucket] (k-anonymity).
  Map<String, int> _kAnon(Map<String, int> input) => <String, int>{
        for (final e in input.entries)
          if (e.value >= kMinBucket) e.key: e.value,
      };

  /// Sort by count desc and keep the top [n] entries (insertion-ordered).
  Map<String, int> _topSlice(Map<String, int> input, int n) {
    final entries = input.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return <String, int>{
      for (final e in entries.take(n)) e.key: e.value,
    };
  }

  /// Compute the coarse age bucket from a stored `dateOfBirth` (Firestore
  /// Timestamp). Returns null for missing/implausible values.
  String? _ageBucketOf(Object? dob) {
    DateTime? birth;
    if (dob is Timestamp) {
      birth = dob.toDate();
    } else if (dob is DateTime) {
      birth = dob;
    }
    if (birth == null) return null;

    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    if (age < 18 || age > 120) return null; // implausible / under-age guard
    if (age <= 24) return '18-24';
    if (age <= 34) return '25-34';
    if (age <= 44) return '35-44';
    if (age <= 54) return '45-54';
    return '55+';
  }

  /// Extract a country label from a raw profile map.
  String? _countryOf(Map<String, dynamic> p) {
    final loc = p['location'];
    if (loc is Map) {
      final c = (loc['country'] as String?)?.trim();
      if (c != null && c.isNotEmpty) return c;
    }
    final origin = (p['primaryOrigin'] as String?)?.trim();
    if (origin != null && origin.isNotEmpty) return origin;
    final flat = (p['country'] as String?)?.trim();
    if (flat != null && flat.isNotEmpty) return flat;
    return null;
  }
}
