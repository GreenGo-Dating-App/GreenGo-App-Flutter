import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/subscription/domain/entities/subscription.dart';

void main() {
  test('yearly savings badge never overstates: smaller of USD and BRL, rounded down', () {
    // USD: 41.6 / 50.0 / 50.0 — BRL: 40.3 / 44.4 / 44.4.
    expect(SubscriptionTier.silver.yearlySavingsPercent, 40);
    expect(SubscriptionTier.gold.yearlySavingsPercent, 44);
    expect(SubscriptionTier.platinum.yearlySavingsPercent, 44);
    expect(SubscriptionTier.basic.yearlySavingsPercent, 0);
  });
}
