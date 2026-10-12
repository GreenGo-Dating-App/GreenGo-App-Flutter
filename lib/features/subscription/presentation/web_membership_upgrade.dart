import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../coins/presentation/bloc/coin_bloc.dart';
import '../../coins/presentation/bloc/coin_event.dart';
import '../../coins/presentation/screens/coin_shop_screen.dart';

// Web routing for the membership upgrade screens.
//
// [MembershipScreen] and [MembershipSelectionScreen] sell memberships through
// `in_app_purchase` only. On the web there is no store, so `SubscriptionBloc`
// fails `isAvailable()` and the user was left with an error and no products:
// a dead end at every Base gate (chat, tickets, bookings). The web build sells
// memberships in the Shop's Membership tab instead (Base / Silver / Gold /
// Platinum, canonical product IDs, `WebCheckoutDialog` -> Stripe), so on the
// web both screens show that tab. Native builds are untouched.

/// Platform check, overridable in tests (tests run on the VM, where `kIsWeb`
/// is always false).
@visibleForTesting
bool Function() membershipUpgradeIsWeb = () => kIsWeb;

/// Builds the web destination; overridable in tests so they need neither DI
/// nor Firebase.
@visibleForTesting
Widget Function(String userId) webMembershipShopBuilder =
    _defaultWebMembershipShop;

/// Index of the Membership tab in [CoinShopScreen].
const int kShopMembershipTabIndex = 1;

/// The Shop opened on its Membership tab, where the web Stripe flow lives.
CoinShopScreen webMembershipShopScreen(String userId) =>
    CoinShopScreen(userId: userId, initialTab: kShopMembershipTabIndex);

Widget _defaultWebMembershipShop(String userId) => BlocProvider<CoinBloc>(
      create: (_) => di.sl<CoinBloc>()
        ..add(LoadCoinBalance(userId))
        ..add(const LoadAvailablePackages()),
      child: webMembershipShopScreen(userId),
    );

/// What a membership upgrade screen should show instead of its in-app-purchase
/// UI: the Stripe-backed Shop membership tab on the web, `null` (keep the IAP
/// screen) everywhere else.
Widget? webMembershipUpgradeDestination(String? userId) {
  if (!membershipUpgradeIsWeb()) return null;
  final uid = (userId != null && userId.isNotEmpty)
      ? userId
      : (_currentUid() ?? '');
  return webMembershipShopBuilder(uid);
}

String? _currentUid() {
  try {
    return FirebaseAuth.instance.currentUser?.uid;
  } catch (_) {
    return null;
  }
}
