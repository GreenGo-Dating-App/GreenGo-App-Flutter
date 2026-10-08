import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/error/failures.dart';
import '../../../coins/data/datasources/coin_remote_datasource.dart'
    show CoinRefusalException;
import '../../../coins/domain/usecases/purchase_feature.dart';
import '../../../events/data/datasources/events_remote_datasource.dart';
import '../../../events/domain/entities/event.dart';
// Reuse the EXISTING "Feature this event" cost so event boosting stays priced
// consistently with the organizer flow in events_screen.dart.
import '../../../events/presentation/screens/events_screen.dart'
    show kFeatureEventCost;

/// Duration + coin-cost options offered on the Promote screen.
///
/// Costs are paid in GreenGoCoins (the in-app economy) — never real money.
/// The 7-day event option intentionally mirrors [kFeatureEventCost] so it
/// matches the organizer's existing "Feature this event" action.
class PromoteDurationOption {
  const PromoteDurationOption({
    required this.days,
    required this.businessCost,
    required this.eventCost,
  });

  final int days;
  final int businessCost;
  final int eventCost;
}

/// Canonical promotion catalog. Adjustable, revenue-only, zero run-cost.
const List<PromoteDurationOption> kPromoteDurationOptions =
    <PromoteDurationOption>[
  PromoteDurationOption(days: 7, businessCost: 250, eventCost: kFeatureEventCost),
  PromoteDurationOption(days: 14, businessCost: 450, eventCost: 180),
  PromoteDurationOption(days: 30, businessCost: 800, eventCost: 350),
];

/// Denormalized field written on `profiles/{uid}`: the timestamp until which
/// the business storefront is boosted in Explore. Read cheaply per-user.
const String kBusinessPromotedUntilField = 'businessPromotedUntil';

/// Outcome of a promotion attempt, so the UI can branch (e.g. route to the
/// coin store on [insufficientCoins]) without inspecting Failure types.
enum PromotionOutcome { success, insufficientCoins, error }

class PromotionResult {
  const PromotionResult._(this.outcome, {this.promotedUntil});

  factory PromotionResult.success(DateTime until) =>
      PromotionResult._(PromotionOutcome.success, promotedUntil: until);
  factory PromotionResult.insufficientCoins() =>
      const PromotionResult._(PromotionOutcome.insufficientCoins);
  factory PromotionResult.error() =>
      const PromotionResult._(PromotionOutcome.error);

  final PromotionOutcome outcome;

  /// The (possibly extended) active-until timestamp on success.
  final DateTime? promotedUntil;

  bool get isSuccess => outcome == PromotionOutcome.success;
}

/// Charges GreenGoCoins to promote a business storefront or feature one of its
/// events. Coin affordability + deduction go exclusively through the EXISTING
/// coin API ([CanAffordFeature] / [PurchaseFeature]) — no hand-rolled balance
/// math. Promotions only set denormalized visibility flags.
class PromotionService {
  PromotionService({
    FirebaseFirestore? firestore,
    EventsRemoteDataSource? eventsDataSource,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _eventsDataSource = eventsDataSource ?? sl<EventsRemoteDataSource>();

  final FirebaseFirestore _firestore;
  final EventsRemoteDataSource _eventsDataSource;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('profiles');

  /// Current business-promotion expiry for [uid], or null if never/expired.
  Future<DateTime?> getBusinessPromotedUntil(String uid) async {
    final snap = await _profiles.doc(uid).get();
    final raw = snap.data()?[kBusinessPromotedUntilField];
    if (raw is Timestamp) {
      final date = raw.toDate();
      return date.isAfter(DateTime.now()) ? date : null;
    }
    return null;
  }

  /// Check affordability via the EXISTING coin API.
  Future<bool> canAfford({required String uid, required int cost}) async {
    final result = await sl<CanAffordFeature>()(userId: uid, cost: cost);
    return result.fold((_) => false, (v) => v);
  }

  /// Promote a business storefront for [days] at [cost] coins.
  ///
  /// Deducts coins through [PurchaseFeature] then sets/extends the denormalized
  /// [kBusinessPromotedUntilField] on `profiles/{uid}`. If a promotion is still
  /// active, the new window is appended (extends rather than resets).
  Future<PromotionResult> promoteBusiness(
    String uid, {
    required int days,
    required int cost,
  }) async {
    if (!await canAfford(uid: uid, cost: cost)) {
      return PromotionResult.insufficientCoins();
    }

    // The server prices [days], debits and extends businessPromotedUntil
    // (from the current expiry when still active) in ONE transaction.
    final charge = await sl<PurchaseFeature>()(
      userId: uid,
      featureName: 'business_promotion',
      cost: cost,
      relatedId: uid,
      option: days,
    );
    return charge.fold(
      (failure) => _isInsufficient(failure)
          ? PromotionResult.insufficientCoins()
          : PromotionResult.error(),
      (txn) {
        final until = _effectTime(txn.metadata, kBusinessPromotedUntilField);
        return until != null
            ? PromotionResult.success(until)
            : PromotionResult.error();
      },
    );
  }

  /// Feature an event for [days] at [cost] coins.
  ///
  /// Reuses the EXISTING feature-event mechanics (charge via [PurchaseFeature],
  /// then flip `isFeatured` / `featuredUntil` so it surfaces in Explore's
  /// featured carousel, which reads [Event.isCurrentlyFeatured]). Extends the
  /// window if the event is already featured.
  Future<PromotionResult> promoteEvent(
    Event event, {
    required int days,
    required int cost,
  }) async {
    final uid = event.organizerId;
    if (!await canAfford(uid: uid, cost: cost)) {
      return PromotionResult.insufficientCoins();
    }

    final charge = await sl<PurchaseFeature>()(
      userId: uid,
      featureName: 'event_featured',
      cost: cost,
      relatedId: event.id,
      option: days, // the server sets isFeatured / featuredUntil (extends)
    );
    final failure = charge.fold((f) => f, (_) => null);
    if (failure != null) {
      return _isInsufficient(failure)
          ? PromotionResult.insufficientCoins()
          : PromotionResult.error();
    }

    try {
      var base = DateTime.now();
      if (event.isCurrentlyFeatured &&
          event.featuredUntil != null &&
          event.featuredUntil!.isAfter(base)) {
        base = event.featuredUntil!;
      }
      final until = charge.fold(
            (_) => null,
            (txn) => _effectTime(txn.metadata, 'featuredUntil'),
          ) ??
          base.add(Duration(days: days));

      await _eventsDataSource.updateEvent(
        event.copyWith(isFeatured: true, featuredUntil: until),
      );
      return PromotionResult.success(until);
    } catch (_) {
      return PromotionResult.error();
    }
  }

  static bool _isInsufficient(Failure failure) =>
      CoinRefusalException.reasonIn(failure.message) ==
      CoinRefusalException.insufficientCoins;

  static DateTime? _effectTime(Map<String, dynamic>? metadata, String key) {
    final effect = metadata?['effect'];
    final ms = effect is Map ? effect[key] : null;
    return ms is num ? DateTime.fromMillisecondsSinceEpoch(ms.toInt()) : null;
  }

  /// The business's own events from TODAY into the future, eligible to be
  /// featured. Uses "not before the start of today" (rather than strictly
  /// `isUpcoming`, which excludes anything earlier today) so an event happening
  /// today can still be promoted.
  Future<List<Event>> getPromotableEvents(String uid) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    // Server-narrowed (organizerId == uid, startDate >= today, soonest
    // first) instead of the full organized + co-owned + attending set; the
    // datasource falls back to that set if the narrow query fails.
    final events =
        await _eventsDataSource.getOrganizedEventsFrom(uid, startOfToday);
    return events
        .where((e) =>
            e.organizerId == uid && !e.startDate.isBefore(startOfToday))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }
}
