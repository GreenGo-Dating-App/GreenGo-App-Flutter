import 'entities/user_experience.dart';

/// When (relative to the start) the guest cancels — one row of the policy
/// table shown on the detail page.
enum CancelWindow { moreThan7Days, between7DaysAnd24h, moreThan24h, lessThan24h, lessThan7Days }

/// One row: cancelling in [window] refunds [refund] (0..1) of the price.
class CancelTier {
  const CancelTier(this.window, this.refund);
  final CancelWindow window;
  final double refund;
}

/// The fixed cancellation policies (pure, unit-tested). GreenGo never holds
/// the money: these are the refunds the HOST owes the guest.
class CancellationRules {
  const CancellationRules._();

  static const Duration _day = Duration(hours: 24);
  static const Duration _week = Duration(days: 7);

  /// Rows of the policy table, earliest window first.
  static List<CancelTier> tiers(CancellationPolicy p) => switch (p) {
        CancellationPolicy.flexible => const [
            CancelTier(CancelWindow.moreThan24h, 1),
            CancelTier(CancelWindow.lessThan24h, 0),
          ],
        CancellationPolicy.moderate => const [
            CancelTier(CancelWindow.moreThan7Days, 1),
            CancelTier(CancelWindow.between7DaysAnd24h, 0.5),
            CancelTier(CancelWindow.lessThan24h, 0),
          ],
        CancellationPolicy.strict => const [
            CancelTier(CancelWindow.moreThan7Days, 1),
            CancelTier(CancelWindow.lessThan7Days, 0),
          ],
      };

  /// Refund (0..1) for a guest cancelling [beforeStart] ahead of the start,
  /// including the universal rules: [hostCancelled] → 100%; cancelling within
  /// 24 h of booking ([sinceBooking]) when the start is more than 48 h away
  /// → 100%.
  static double refund(
    CancellationPolicy p, {
    required Duration beforeStart,
    Duration? sinceBooking,
    bool hostCancelled = false,
  }) {
    if (hostCancelled) return 1;
    if (sinceBooking != null &&
        sinceBooking <= _day &&
        beforeStart > const Duration(hours: 48)) {
      return 1;
    }
    switch (p) {
      case CancellationPolicy.flexible:
        return beforeStart >= _day ? 1 : 0;
      case CancellationPolicy.moderate:
        if (beforeStart >= _week) return 1;
        return beforeStart >= _day ? 0.5 : 0;
      case CancellationPolicy.strict:
        return beforeStart >= _week ? 1 : 0;
    }
  }
}
