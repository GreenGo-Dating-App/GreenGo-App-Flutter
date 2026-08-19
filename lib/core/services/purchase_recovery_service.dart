import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../constants/product_catalog.dart';
import '../di/injection_container.dart' as di;
import '../../features/coins/data/datasources/coin_remote_datasource.dart';
import '../../features/coins/domain/entities/coin_package.dart';

/// App-wide in-app-purchase safety net.
///
/// WHY THIS EXISTS
/// ---------------
/// The store delivers purchases on `InAppPurchase.purchaseStream`, and only to
/// listeners that are attached *at that moment*. Before this service, the only
/// listener lived on the coin shop screen. So a purchase that completed after
/// the user closed the shop — a slow card, a "pending" boleto/family-approval
/// flow, or simply the app being killed on the store's confirmation screen —
/// was delivered to nobody. The receipt was never verified, never granted, and
/// never acknowledged.
///
/// Google auto-refunds any purchase that is not acknowledged within **3 days**,
/// and Apple keeps re-delivering an unfinished transaction forever. Both mean
/// the user paid and got nothing.
///
/// This service attaches a listener for the whole app lifetime and replays
/// `restorePurchases()` at startup, so every unfinished purchase is verified,
/// granted and acknowledged exactly once.
///
/// SAFETY
/// ------
/// The shop screen keeps its own listener for immediate UI feedback, so both
/// can see the same purchase. That is intentional and safe: the backend claims
/// each receipt in an atomic `purchaseLedger` transaction, so the second call
/// returns `alreadyProcessed: true` and credits nothing.
class PurchaseRecoveryService {
  PurchaseRecoveryService({
    InAppPurchase? inAppPurchase,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _injectedIap = inAppPurchase;

  final InAppPurchase? _injectedIap;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  InAppPurchase? _iap;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Receipts handled in this process, so a redelivery inside one session
  /// doesn't cause a redundant round trip. Cross-session dedup is the server's
  /// job (`purchaseLedger`), not ours.
  final Set<String> _handled = <String>{};

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Start listening. Safe to call more than once; later calls are ignored.
  Future<void> initialize() async {
    if (_subscription != null) return;
    if (!_isMobile) return; // web checkout goes through Stripe, not the stores

    try {
      _iap = _injectedIap ?? InAppPurchase.instance;
      if (!await _iap!.isAvailable()) {
        debugPrint('[PurchaseRecovery] Store unavailable — not starting');
        return;
      }

      _subscription = _iap!.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) => debugPrint('[PurchaseRecovery] stream error: $e'),
      );

      // Replay anything the store still considers unfinished. Restored items
      // arrive on the same stream and are handled by _onPurchases.
      await _iap!.restorePurchases();
      debugPrint('[PurchaseRecovery] listening + restore requested');
    } catch (e) {
      debugPrint('[PurchaseRecovery] init failed: $e');
      _iap = null;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      // Only completed purchases carry a usable receipt. `pending` must NOT
      // grant anything — the user has not been charged yet.
      final isGrantable = purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored;

      if (!isGrantable) {
        if (purchase.status == PurchaseStatus.pending) {
          debugPrint('[PurchaseRecovery] pending: ${purchase.productID}');
        } else if (purchase.pendingCompletePurchase) {
          // error / canceled: finish it so the store stops redelivering.
          await _finish(purchase);
        }
        continue;
      }

      await _recover(purchase);
    }
  }

  Future<void> _recover(PurchaseDetails purchase) async {
    final receipt = purchase.verificationData.serverVerificationData;
    final key = '${purchase.productID}:$receipt';
    if (_handled.contains(key)) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      // Not signed in yet — leave the purchase unfinished on purpose so the
      // store redelivers it after login. Do not acknowledge, do not drop.
      debugPrint('[PurchaseRecovery] no user yet, deferring ${purchase.productID}');
      return;
    }

    final canonicalId = ProductCatalog.canonicalId(purchase.productID);
    final isMembership = ProductCatalog.canonicalIds.contains(canonicalId);
    final coinPackage = CoinPackages.getByProductId(purchase.productID);

    if (!isMembership && coinPackage == null) {
      debugPrint('[PurchaseRecovery] unknown product ${purchase.productID} — finishing');
      await _finish(purchase);
      return;
    }

    try {
      if (isMembership) {
        // Restored subscriptions are already granted; re-verifying is harmless
        // (the server is idempotent) and repairs an entitlement that was lost
        // between a successful charge and a failed write.
        await _functions.httpsCallable('verifyPurchase').call<Object?>({
          'userId': userId,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'productId': purchase.productID,
          'purchaseToken':
              Platform.isAndroid ? receipt : (purchase.purchaseID ?? receipt),
          'verificationData': receipt,
        });
      } else {
        await di.sl<CoinRemoteDataSource>().verifyCoinPurchase(
              productId: purchase.productID,
              purchaseToken:
                  Platform.isAndroid ? receipt : (purchase.purchaseID ?? receipt),
              verificationData: receipt,
              platform: Platform.isIOS ? 'ios' : 'android',
            );
      }

      _handled.add(key);
      await _finish(purchase);
      debugPrint('[PurchaseRecovery] recovered ${purchase.productID}');
    } catch (e) {
      // Leave it unfinished so the store redelivers it next launch. Better a
      // retry than a silently swallowed purchase.
      debugPrint('[PurchaseRecovery] verify failed for ${purchase.productID}: $e');
    }
  }

  /// Acknowledge, and consume ONLY for consumables. Consuming a subscription
  /// triggers a Google auto-refund.
  Future<void> _finish(PurchaseDetails purchase) async {
    final iap = _iap;
    if (iap == null) return;

    try {
      if (purchase.pendingCompletePurchase) {
        await iap.completePurchase(purchase);
      }

      final canonicalId = ProductCatalog.canonicalId(purchase.productID);
      final isMembership = ProductCatalog.canonicalIds.contains(canonicalId);

      if (Platform.isAndroid && !isMembership) {
        final android =
            iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        await android.consumePurchase(purchase);
      }
    } catch (e) {
      debugPrint('[PurchaseRecovery] finish failed for ${purchase.productID}: $e');
    }
  }
}
