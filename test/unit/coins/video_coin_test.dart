import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/features/coins/domain/entities/video_coin.dart';

/// Master Test Plan — Coins / video-coin (per-minute) call economy.
/// Covers the video-call affordability math behind E2E matrix items #148/#149
/// (video call requires video coins). Pure tests against the real
/// [VideoCoinBalance], [VideoCoinPackage] and [VideoCoinPackages].
void main() {
  VideoCoinBalance bal({required int total, required int used}) =>
      VideoCoinBalance(
        userId: 'u1',
        totalVideoCoins: total,
        usedVideoCoins: used,
        lastUpdated: DateTime(2026, 7, 15),
      );

  group('VideoCoinBalance availability', () {
    test('availableVideoCoins is total minus used', () {
      expect(bal(total: 30, used: 12).availableVideoCoins, 18);
    });

    test('canMakeVideoCall respects the per-minute cost', () {
      final b = bal(total: 5, used: 0);
      expect(b.canMakeVideoCall(), isTrue); // default 1-minute cost
      expect(b.canMakeVideoCall(minutesCost: 5), isTrue);
      expect(b.canMakeVideoCall(minutesCost: 6), isFalse);
    });

    test('a fully-used balance cannot make a call', () {
      final b = bal(total: 10, used: 10);
      expect(b.availableVideoCoins, 0);
      expect(b.canMakeVideoCall(), isFalse);
    });

    test('empty factory has zero coins and cannot call', () {
      final b = VideoCoinBalance.empty('u9');
      expect(b.userId, 'u9');
      expect(b.availableVideoCoins, 0);
      expect(b.canMakeVideoCall(), isFalse);
    });
  });

  group('VideoCoinPackage math', () {
    test('totalMinutes adds bonus minutes when present', () {
      expect(VideoCoinPackages.starter.totalMinutes, 10); // no bonus
      expect(VideoCoinPackages.popular.totalMinutes, 35); // 30 + 5 bonus
    });

    test('pricePerMinute divides price by total (bonus-inclusive) minutes', () {
      // popular: $4.99 / 35 minutes.
      expect(VideoCoinPackages.popular.pricePerMinute,
          closeTo(4.99 / 35, 1e-9));
    });

    test('bonus minutes lower the effective price per minute', () {
      // premium (60+15) should beat starter (10, no bonus) on $/min.
      expect(VideoCoinPackages.premium.pricePerMinute,
          lessThan(VideoCoinPackages.starter.pricePerMinute));
    });

    test('displayPrice formats USD with a dollar sign', () {
      expect(VideoCoinPackages.starter.displayPrice, r'$1.99');
    });
  });

  group('VideoCoinPackages catalog', () {
    test('all exposes four packages', () {
      expect(VideoCoinPackages.all.length, 4);
    });

    test('getByProductId resolves known / unknown product ids', () {
      expect(VideoCoinPackages.getByProductId('greengo_video_30'),
          VideoCoinPackages.popular);
      expect(VideoCoinPackages.getByProductId('nope'), isNull);
    });
  });

  group('VideoCoinTransactionType credit/debit classification', () {
    test('purchase, gift, refund and bonus are credits', () {
      for (final t in [
        VideoCoinTransactionType.purchase,
        VideoCoinTransactionType.gift,
        VideoCoinTransactionType.refund,
        VideoCoinTransactionType.bonus,
      ]) {
        expect(t.isCredit, isTrue, reason: '$t should be a credit');
      }
    });

    test('used and expired are NOT credits', () {
      expect(VideoCoinTransactionType.used.isCredit, isFalse);
      expect(VideoCoinTransactionType.expired.isCredit, isFalse);
    });

    test('every type has a non-empty displayName', () {
      for (final t in VideoCoinTransactionType.values) {
        expect(t.displayName, isNotEmpty);
      }
    });
  });
}
