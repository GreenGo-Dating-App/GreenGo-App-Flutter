import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/features/coins/domain/entities/coin_gift.dart';

/// Master Test Plan — Coins / P2P coin-gift validation & status.
/// Covers E2E matrix items #245 (send coins P2P), #246 (send-coin validation
/// edges: min/max amount), and #258 (accept/decline received gift status).
/// Pure tests against the real [CoinGift] entity, [CoinGiftConstraints] and
/// [CoinGiftStatus].
void main() {
  CoinGift gift({
    int amount = 50,
    CoinGiftStatus status = CoinGiftStatus.pending,
    DateTime? expiresAt,
  }) =>
      CoinGift(
        giftId: 'g1',
        senderId: 'sender',
        receiverId: 'receiver',
        amount: amount,
        status: status,
        sentAt: DateTime(2026, 7, 15),
        expiresAt: expiresAt,
      );

  group('CoinGiftConstraints.isValidAmount', () {
    test('accepts amounts inside the [10, 1000] band inclusively', () {
      expect(CoinGiftConstraints.isValidAmount(10), isTrue);
      expect(CoinGiftConstraints.isValidAmount(500), isTrue);
      expect(CoinGiftConstraints.isValidAmount(1000), isTrue);
    });

    test('rejects amounts below the minimum (incl. zero / negative)', () {
      expect(CoinGiftConstraints.isValidAmount(9), isFalse);
      expect(CoinGiftConstraints.isValidAmount(0), isFalse);
      expect(CoinGiftConstraints.isValidAmount(-5), isFalse);
    });

    test('rejects amounts above the maximum', () {
      expect(CoinGiftConstraints.isValidAmount(1001), isFalse);
      expect(CoinGiftConstraints.isValidAmount(999999), isFalse);
    });

    test('constants match the documented gift economy limits', () {
      expect(CoinGiftConstraints.minAmount, 10);
      expect(CoinGiftConstraints.maxAmount, 1000);
      expect(CoinGiftConstraints.maxPendingGifts, 10);
      expect(CoinGiftConstraints.expirationPeriod, const Duration(days: 7));
    });

    test('suggested amounts are all themselves valid and ascending', () {
      final suggestions = CoinGiftConstraints.suggestedAmounts;
      expect(suggestions, isNotEmpty);
      for (final a in suggestions) {
        expect(CoinGiftConstraints.isValidAmount(a), isTrue,
            reason: '$a should be a valid gift amount');
      }
      final sorted = [...suggestions]..sort();
      expect(suggestions, sorted, reason: 'suggestions should be ascending');
    });
  });

  group('CoinGift expiration & status flags', () {
    test('a null expiresAt gift never expires', () {
      expect(gift().isExpired, isFalse);
    });

    test('a past expiresAt gift is expired', () {
      expect(
        gift(expiresAt: DateTime.now().subtract(const Duration(days: 1)))
            .isExpired,
        isTrue,
      );
    });

    test('a future expiresAt gift is not expired', () {
      expect(
        gift(expiresAt: DateTime.now().add(const Duration(days: 1))).isExpired,
        isFalse,
      );
    });

    test('isPending / isAccepted reflect the status', () {
      expect(gift(status: CoinGiftStatus.pending).isPending, isTrue);
      expect(gift(status: CoinGiftStatus.pending).isAccepted, isFalse);
      expect(gift(status: CoinGiftStatus.accepted).isAccepted, isTrue);
      expect(gift(status: CoinGiftStatus.accepted).isPending, isFalse);
    });
  });

  group('CoinGiftStatus wire mapping', () {
    test('fromString round-trips every status name', () {
      for (final s in CoinGiftStatus.values) {
        expect(CoinGiftStatusExtension.fromString(s.name), s);
      }
    });

    test('fromString is case-insensitive', () {
      expect(CoinGiftStatusExtension.fromString('DECLINED'),
          CoinGiftStatus.declined);
      expect(CoinGiftStatusExtension.fromString('Cancelled'),
          CoinGiftStatus.cancelled);
    });

    test('fromString falls back to pending on garbage', () {
      expect(
          CoinGiftStatusExtension.fromString('nope'), CoinGiftStatus.pending);
    });

    test('every status has a non-empty displayName', () {
      for (final s in CoinGiftStatus.values) {
        expect(s.displayName, isNotEmpty);
      }
    });
  });
}
