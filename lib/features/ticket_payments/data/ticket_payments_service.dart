import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/ticket_payments.dart';

/// A callable failure with the server's reason code (`details.code`).
class TicketPaymentException implements Exception {
  const TicketPaymentException(this.reason, [this.message]);
  final String reason;
  final String? message;
  @override
  String toString() => 'TicketPaymentException($reason)';
}

/// Result of [TicketPaymentsService.createCheckout].
class TicketCheckoutResult {
  const TicketCheckoutResult({
    required this.orderId,
    required this.isLink,
    this.isFree = false,
    this.checkoutUrl,
  });
  final String orderId;
  final bool isLink;
  final bool isFree;
  final String? checkoutUrl;
}

/// Client of the ticket payment callables + per-user Firestore reads.
/// Every read is a single doc or a per-user indexed, bounded query.
class TicketPaymentsService {
  TicketPaymentsService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _functions = functions,
        _firestore = firestore,
        _storage = storage;

  final FirebaseFunctions? _functions;
  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _st => _storage ?? FirebaseStorage.instance;

  static TicketPaymentsConfig? _configCache;

  String get _platform => kIsWeb ? 'web' : 'app';

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    try {
      final r = await _fn
          .httpsCallable(name, options: HttpsCallableOptions(timeout: const Duration(seconds: 40)))
          .call<Object?>(data);
      final d = r.data;
      return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      final d = e.details;
      final reason = d is Map && d['code'] is String ? d['code'] as String : e.code;
      throw TicketPaymentException(reason, e.message);
    }
  }

  /// Which providers the server can use + the large-audience threshold.
  Future<TicketPaymentsConfig> config({bool refresh = false}) async {
    if (_configCache != null && !refresh) return _configCache!;
    var stripe = false;
    var mp = false;
    var hold = 30;
    var linkHold = 24;
    try {
      final m = await _call('getTicketPaymentsConfig', const {});
      stripe = m['stripe'] == true;
      mp = m['mercadoPago'] == true;
      hold = (m['holdMinutes'] as num?)?.toInt() ?? 30;
      linkHold = (m['linkHoldHours'] as num?)?.toInt() ?? 24;
    } catch (e) {
      debugPrint('[tickets] config: $e');
    }
    var threshold = kLargeAudienceThreshold;
    try {
      final d = await _db.collection('app_config').doc('ticket_payments').get();
      final t = d.data()?['largeAudienceThreshold'];
      if (t is num && t > 0) threshold = t.toInt();
    } catch (_) {/* default */}
    return _configCache = TicketPaymentsConfig(
      stripe: stripe,
      mercadoPago: mp,
      holdMinutes: hold,
      linkHoldHours: linkHold,
      largeAudienceThreshold: threshold,
    );
  }

  Stream<PaymentAccounts> watchAccounts(String uid) => _db
      .collection('payment_accounts')
      .doc(uid)
      .snapshots()
      .map((s) => PaymentAccounts.fromMap(s.data()))
      .handleError((Object e) => debugPrint('[tickets] accounts: $e'));

  Future<void> refreshAccounts() => _call('refreshPaymentAccount', const {});

  Future<String> onboardingUrl(TicketProvider p) async {
    final m = await _call(
      p == TicketProvider.stripe ? 'startStripeOnboarding' : 'startMercadoPagoOnboarding',
      {'platform': _platform},
    );
    final url = m['url'] as String?;
    if (url == null) throw const TicketPaymentException('provider_unavailable');
    return url;
  }

  /// Opens a provider page INSIDE the app: Custom Tab / SFSafariViewController
  /// on mobile, the same tab on web (the return page deep-links back).
  static Future<bool> openInApp(String url) async {
    final uri = Uri.parse(url);
    try {
      if (kIsWeb) {
        return await launchUrl(uri, webOnlyWindowName: '_self');
      }
      return await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// [items] = {typeId: qty} for events with ticket types (else [quantity]).
  Future<TicketCheckoutResult> createCheckout({
    required String kind,
    required String id,
    String? bookingId,
    int quantity = 1,
    Map<String, int>? items,
    String? locale,
  }) async {
    final m = await _call('createTicketCheckout', {
      'kind': kind,
      'id': id,
      if (bookingId != null) 'bookingId': bookingId,
      if (items != null && items.isNotEmpty)
        'items': [
          for (final e in items.entries)
            if (e.value > 0) {'typeId': e.key, 'qty': e.value},
        ]
      else
        'quantity': quantity,
      'platform': _platform,
      if (locale != null) 'locale': locale,
    });
    return TicketCheckoutResult(
      orderId: m['orderId'] as String,
      isLink: m['mode'] == 'link',
      isFree: m['mode'] == 'free',
      checkoutUrl: m['checkoutUrl'] as String?,
    );
  }

  // ─────────────────────────────── ticket types (events)

  Stream<List<TicketType>> watchTicketTypes(String eventId) => _db
      .collection('events')
      .doc(eventId)
      .collection('ticket_types')
      .orderBy('sortOrder')
      .limit(50)
      .snapshots()
      .map((q) => q.docs.map((d) => TicketType.fromMap(d.id, d.data())).toList());

  Future<void> saveTicketType(String eventId, TicketType t) {
    final col = _db.collection('events').doc(eventId).collection('ticket_types');
    final ref = t.id.isEmpty ? col.doc() : col.doc(t.id);
    return ref.set(t.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteTicketType(String eventId, String typeId) =>
      _db.collection('events').doc(eventId).collection('ticket_types').doc(typeId).delete();

  /// Tickets this buyer holds / owns for a listing ({held, owned, types}).
  Future<({int held, int owned, Map<String, int> perType})> holdings(
      String kind, String listingId, String uid) async {
    try {
      final d = (await _db.collection('ticket_holdings').doc('${kind}_${listingId}_$uid').get()).data();
      final types = <String, int>{};
      final raw = d?['types'];
      if (raw is Map) {
        raw.forEach((k, v) {
          if (v is Map) {
            types['$k'] = ((v['held'] as num?)?.toInt() ?? 0) + ((v['owned'] as num?)?.toInt() ?? 0);
          }
        });
      }
      return (
        held: (d?['held'] as num?)?.toInt() ?? 0,
        owned: (d?['owned'] as num?)?.toInt() ?? 0,
        perType: types,
      );
    } catch (_) {
      return (held: 0, owned: 0, perType: const <String, int>{});
    }
  }

  /// Buyer: every ticket issued to them, newest first (bounded).
  Future<List<IssuedTicket>> myTickets(String uid, {int limit = 50}) async {
    final q = await _db
        .collection('tickets')
        .where('buyerId', isEqualTo: uid)
        .orderBy('issuedAt', descending: true)
        .limit(limit)
        .get();
    return q.docs.map((d) => IssuedTicket.fromMap(d.id, d.data())).toList();
  }

  // ─────────────────────────────── issued tickets (offline-cached)

  static String _orderKey(String orderId) => 'tickets_order_v1_$orderId';

  /// Every ticket of an order (each with its own QR), cached for the door.
  Stream<List<IssuedTicket>> watchOrderTickets(String uid, String orderId) async* {
    final prefs = await _prefs();
    final cached = prefs?.getStringList(_orderKey(orderId));
    if (cached != null && cached.isNotEmpty) {
      yield [
        for (final c in cached)
          if (_decode(c) case final t?) t,
      ];
    }
    try {
      await for (final q in _db
          .collection('tickets')
          .where('buyerId', isEqualTo: uid)
          .where('orderId', isEqualTo: orderId)
          .limit(100)
          .snapshots()) {
        final list = q.docs.map((d) => IssuedTicket.fromMap(d.id, d.data())).toList()
          ..sort((a, b) => a.index.compareTo(b.index));
        await prefs?.setStringList(_orderKey(orderId), [
          for (final t in list)
            if (t.isValid) _encode(t),
        ]);
        yield list;
      }
    } catch (e) {
      debugPrint('[tickets] order tickets: $e');
    }
  }

  static String _encode(IssuedTicket t) =>
      [t.id, t.orderId, t.kind, t.listingId, t.qrPayload, t.typeName ?? '', '${t.partySize}', '${t.index}', '${t.of}', t.title ?? '']
          .map(Uri.encodeComponent)
          .join('|');

  static IssuedTicket? _decode(String s) {
    final p = s.split('|').map(Uri.decodeComponent).toList();
    if (p.length < 10) return null;
    return IssuedTicket(
      id: p[0], orderId: p[1], kind: p[2], listingId: p[3], status: 'valid', qrPayload: p[4],
      typeName: p[5].isEmpty ? null : p[5], partySize: int.tryParse(p[6]) ?? 1,
      index: int.tryParse(p[7]) ?? 1, of: int.tryParse(p[8]) ?? 1, title: p[9].isEmpty ? null : p[9],
    );
  }

  Stream<TicketOrder?> watchOrder(String orderId) => _db
      .collection('ticket_orders')
      .doc(orderId)
      .snapshots()
      .map((s) => s.exists ? TicketOrder.fromMap(s.id, s.data()!) : null);

  Future<void> syncOrder(String orderId) =>
      _call('syncTicketOrder', {'orderId': orderId}).catchError((Object e) {
        debugPrint('[tickets] sync: $e');
        return <String, dynamic>{};
      });

  Future<void> cancelOrder(String orderId) => _call('cancelTicketOrder', {'orderId': orderId});

  /// Optional receipt (image) for a link-mode order, then "I've paid".
  Future<void> markPaymentSent(String orderId, {Uint8List? receipt, String? contentType}) async {
    String? path;
    if (receipt != null) {
      path = 'ticket_receipts/$orderId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _st.ref(path).putData(
            receipt,
            SettableMetadata(
              contentType: contentType ?? 'image/jpeg',
              customMetadata: {'visibility': 'private'},
            ),
          );
    }
    await _call('markTicketPaymentSent', {'orderId': orderId, if (path != null) 'receiptPath': path});
  }

  Future<String?> receiptUrl(String path) async {
    try {
      return await _st.ref(path).getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  /// Organizer: confirm one or many link payments (<= 50 per call).
  Future<Map<String, String>> confirm(List<String> orderIds) async {
    final out = <String, String>{};
    for (var i = 0; i < orderIds.length; i += 50) {
      final chunk = orderIds.sublist(i, i + 50 > orderIds.length ? orderIds.length : i + 50);
      final m = await _call('confirmTicketPayment', {'orderIds': chunk});
      final r = m['results'];
      if (r is Map) r.forEach((k, v) => out['$k'] = '$v');
    }
    return out;
  }

  Future<void> reject(String orderId, String reason) =>
      _call('rejectTicketPayment', {'orderId': orderId, 'reason': reason});

  /// Organizer: link payments waiting for confirmation (oldest first).
  Stream<List<TicketOrder>> watchToConfirm(String organizerId, {int limit = 100}) => _db
      .collection('ticket_orders')
      .where('organizerId', isEqualTo: organizerId)
      .where('status', isEqualTo: 'awaiting_confirmation')
      .orderBy('sentAt')
      .limit(limit)
      .snapshots()
      .map((q) => q.docs.map((d) => TicketOrder.fromMap(d.id, d.data())).toList());

  /// Buyer: own orders, newest first.
  Future<List<TicketOrder>> myOrders(String buyerId, {int limit = 50}) async {
    final q = await _db
        .collection('ticket_orders')
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return q.docs.map((d) => TicketOrder.fromMap(d.id, d.data())).toList();
  }

  static Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }
}
