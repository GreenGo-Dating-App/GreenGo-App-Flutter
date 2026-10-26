import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../my_space/data/my_space_repository.dart';
import '../../profile/domain/entities/store_visibility.dart';
import '../../ticket_payments/domain/ticket_payments.dart';
import 'services/follow_service.dart';
import 'services/rating_service.dart';

/// This calendar month at a glance for a business (Business Center overview).
@immutable
class BusinessMonthStats {
  const BusinessMonthStats({
    this.ticketsSold = 0,
    this.orders = 0,
    this.currency,
    this.sales = 0,
    this.fees = 0,
    this.net = 0,
    this.followers = 0,
    this.newLeads = 0,
    this.ratingAvg = 0,
    this.ratingCount = 0,
  });

  final int ticketsSold;
  final int orders;

  /// Currency of [sales] / [fees] / [net] (the most used one this month;
  /// null when nothing was sold).
  final String? currency;

  /// Minor units of [currency]: what buyers paid, the GreenGo fee, the payout.
  final int sales;
  final int fees;
  final int net;
  final int followers;
  final int newLeads;
  final double ratingAvg;
  final int ratingCount;
}

/// Things waiting for the business (Business Center "Action needed").
@immutable
class BusinessTodo {
  const BusinessTodo({
    this.bookingRequests = 0,
    this.paymentsToConfirm = 0,
    this.paymentsConnected = true,
  });

  final int bookingRequests;
  final int paymentsToConfirm;

  /// Stripe or Mercado Pago connected and ready.
  final bool paymentsConnected;
}

abstract class BusinessCenterRepository {
  Future<BusinessMonthStats> monthStats(String uid, DateTime now);
  Future<BusinessTodo> todo(String uid);

  /// Owner's Store visibility choice (`profiles/{uid}.storeVisibility`).
  Future<void> setStoreVisibility(String uid, StoreVisibility v);
}

/// Reads only what already exists, bounded: paid orders of the organizer
/// (two equality filters, served without a composite index, capped at
/// [maxOrders] and filtered to this month on the device), the server-kept
/// follower counter, a count() of this month's leads and the denormalized
/// rating. Phase 3 replaces the order scan with server-kept monthly totals.
class FirestoreBusinessCenterRepository implements BusinessCenterRepository {
  FirestoreBusinessCenterRepository({
    FirebaseFirestore? firestore,
    FollowService? follows,
    RatingService? ratings,
    MySpaceRepository? mySpace,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _follows = follows,
        _ratings = ratings,
        _mySpace = mySpace;

  static const int maxOrders = 500;

  @override
  Future<void> setStoreVisibility(String uid, StoreVisibility v) =>
      _db.collection('profiles').doc(uid).update({'storeVisibility': v.wire});

  final FirebaseFirestore _db;
  final FollowService? _follows;
  final RatingService? _ratings;
  final MySpaceRepository? _mySpace;

  @override
  Future<BusinessMonthStats> monthStats(String uid, DateTime now) async {
    final start = DateTime(now.year, now.month);
    final results = await Future.wait<Object?>([
      _db
          .collection('ticket_orders')
          .where('organizerId', isEqualTo: uid)
          .where('status', isEqualTo: 'paid')
          .limit(maxOrders)
          .get()
          .then<Object?>((s) => s.docs.map((d) => d.data()).toList())
          .catchError((Object e) {
        debugPrint('[business-center] orders: $e');
        return <Map<String, dynamic>>[];
      }),
      (_follows ?? FollowService()).getFollowerCount(uid).catchError((Object _) => 0),
      _db
          .collection('business_leads')
          .doc(uid)
          .collection('leads')
          .where('updatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .count()
          .get()
          .then<Object?>((c) => c.count ?? 0)
          .catchError((Object _) => 0),
      (_ratings ?? RatingService()).getAggregate(uid).then<Object?>((r) => r).catchError((Object _) => (avg: 0.0, count: 0)),
    ]);
    final s = summarizeOrders(results[0]! as List<Map<String, dynamic>>, start);
    final rating = results[3]! as ({double avg, int count});
    return BusinessMonthStats(
      ticketsSold: s.ticketsSold,
      orders: s.orders,
      currency: s.currency,
      sales: s.sales,
      fees: s.fees,
      net: s.net,
      followers: results[1]! as int,
      newLeads: results[2]! as int,
      ratingAvg: rating.avg,
      ratingCount: rating.count,
    );
  }

  @override
  Future<BusinessTodo> todo(String uid) async {
    final my = _mySpace ?? FirestoreMySpaceRepository(firestore: _db);
    final r = await Future.wait<Object>([
      my.bookingRequestsToConfirm(uid).catchError((Object _) => 0),
      my.paymentsToConfirm(uid).catchError((Object _) => 0),
      _db.collection('payment_accounts').doc(uid).get()
          .then<Object>((d) => PaymentAccounts.fromMap(d.data()).anyReady)
          .catchError((Object _) => true),
    ]);
    return BusinessTodo(
      bookingRequests: r[0] as int,
      paymentsToConfirm: r[1] as int,
      paymentsConnected: r[2] as bool,
    );
  }
}

/// Paid orders of [since]'s month and later, in their most used currency.
/// Orders before 5.0.8 have no hostNet: net = total - fee.
({int ticketsSold, int orders, String? currency, int sales, int fees, int net}) summarizeOrders(
    List<Map<String, dynamic>> orders, DateTime since) {
  final inMonth = orders.where((o) {
    final t = o['paidAt'];
    final at = t is Timestamp ? t.toDate() : (t is DateTime ? t : null);
    return at != null && !at.isBefore(since);
  }).toList();
  final byCur = <String, int>{};
  for (final o in inMonth) {
    final c = '${o['currency'] ?? ''}'.toLowerCase();
    if (c.isNotEmpty) byCur[c] = (byCur[c] ?? 0) + 1;
  }
  final cur = byCur.isEmpty ? null : (byCur.entries.toList()..sort((a, b) => b.value - a.value)).first.key;
  var tickets = 0, sales = 0, fees = 0, net = 0, n = 0;
  for (final o in inMonth) {
    tickets += (o['quantity'] as num?)?.toInt() ?? 1;
    if ('${o['currency'] ?? ''}'.toLowerCase() != cur) continue;
    n++;
    final total = (o['totalAmount'] as num?)?.toInt() ?? 0;
    final fee = (o['feeTotal'] as num?)?.toInt() ?? 0;
    sales += total;
    fees += fee;
    net += (o['hostNet'] as num?)?.toInt() ?? (total - fee);
  }
  return (ticketsSold: tickets, orders: n, currency: cur, sales: sales, fees: fees, net: net);
}
