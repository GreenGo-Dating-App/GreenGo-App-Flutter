/// Platform-selected Stripe Checkout.
///
/// - **Web** → `stripe_web_checkout_web.dart` (the real hosted-checkout flow).
/// - **iOS / Android** → `stripe_web_checkout_stub.dart` (inert no-ops).
///
/// The selection happens at COMPILE TIME, so the Stripe implementation is never
/// linked into a mobile binary. That is the point: an external payment path for
/// digital goods inside a store build is an automatic App Store 3.1.1 / Google
/// Play Payments rejection, and a compile-time split is the only guarantee that
/// a missed `kIsWeb` check can't reach one.
///
/// Import this file; never import the `_web` or `_stub` variants directly.
export 'stripe_web_checkout_stub.dart'
    if (dart.library.js_interop) 'stripe_web_checkout_web.dart';
