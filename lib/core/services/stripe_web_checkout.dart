import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Web-only purchasing via Stripe Checkout.
///
/// The mobile app uses native in-app-purchase; the web build has no IAP plugin,
/// so coin packages and memberships are sold through Stripe's hosted checkout:
///   1. [startCheckout] asks the `createStripeCheckoutSession` Cloud Function for
///      a session and opens the hosted page in a new tab.
///   2. The `stripeWebhook` Cloud Function credits coins / activates membership.
///   3. [waitForCompletion] polls `stripe_orders` in the original tab so we know
///      when the purchase landed (independent of where the new tab redirects).
class StripeWebCheckout {
  StripeWebCheckout._();

  /// Whether Stripe checkout should be used for this platform.
  static bool get isSupported => kIsWeb;

  /// Opens Stripe Checkout for [productId] in a new tab. Returns the Stripe
  /// session id, or null if the user is not signed in / no URL was returned.
  /// Throws [FirebaseFunctionsException] on backend errors.
  static Future<String?> startCheckout(String productId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final country = await _resolveCountry(uid);
    final origin = Uri.base.origin;

    final callable =
        FirebaseFunctions.instance.httpsCallable('createStripeCheckoutSession');
    final res = await callable.call<Map<String, dynamic>>({
      'productId': productId,
      'successUrl': '$origin/?payment=success',
      'cancelUrl': '$origin/?payment=cancel',
      'userCountry': country,
    });

    final data = Map<String, dynamic>.from(res.data as Map);
    final url = data['url'] as String?;
    final sessionId = data['sessionId'] as String?;
    if (url == null) return null;

    await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    return sessionId;
  }

  /// IDs of the user's already-completed Stripe orders, captured before checkout
  /// so [waitForCompletion] can detect the NEW one precisely.
  static Future<Set<String>> existingCompletedOrderIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return <String>{};
    try {
      final snap = await FirebaseFirestore.instance
          .collection('stripe_orders')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .get();
      return snap.docs.map((d) => d.id).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// Polls `stripe_orders` until a completed order not in [knownIds] appears
  /// (i.e. the purchase just made). Returns true on success, false on timeout.
  static Future<bool> waitForCompletion(
    Set<String> knownIds, {
    Duration timeout = const Duration(minutes: 6),
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('stripe_orders')
            .where('userId', isEqualTo: uid)
            .where('status', isEqualTo: 'completed')
            .get();
        final hasNew = snap.docs.any((d) => !knownIds.contains(d.id));
        if (hasNew) return true;
      } catch (_) {/* keep polling */}
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return false;
  }

  static Future<String> _resolveCountry(String uid) async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('profiles').doc(uid).get();
      final data = snap.data();
      final loc = data?['location'];
      if (loc is Map && loc['country'] != null) {
        return loc['country'].toString();
      }
      if (data?['country'] != null) return data!['country'].toString();
    } catch (_) {}
    return '';
  }
}
