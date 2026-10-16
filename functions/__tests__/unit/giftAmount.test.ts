/**
 * coins/ledger.ts - Terms 8.5 a: a Coin gift is between 10 and 1,000 Coins
 * (giftCoins and sendGift). Pure, no emulator.
 */

import { HttpsError } from 'firebase-functions/v2/https';
import {
  GIFT_MAX_AMOUNT,
  GIFT_MAX_COINS_PER_DAY,
  GIFT_MAX_PER_DAY,
  GIFT_MIN_AMOUNT,
  REASON,
  assertGiftAmount,
  isValidGiftAmount,
} from '../../src/coins/ledger';

describe('gift amount (Terms 8.5)', () => {
  test('limits match the Terms', () => {
    expect(GIFT_MIN_AMOUNT).toBe(10);
    expect(GIFT_MAX_AMOUNT).toBe(1000);
    expect(GIFT_MAX_PER_DAY).toBe(10);
    expect(GIFT_MAX_COINS_PER_DAY).toBe(5000);
  });

  test.each([10, 11, 500, 999, 1000])('%p is valid', (n) => {
    expect(isValidGiftAmount(n)).toBe(true);
    expect(() => assertGiftAmount(n)).not.toThrow();
  });

  test.each([0, 1, 9, 1001, 100000, 10.5, -10, NaN, '100', null, undefined])('%p is refused', (n) => {
    expect(isValidGiftAmount(n)).toBe(false);
    let err: any;
    try {
      assertGiftAmount(n);
    } catch (e) {
      err = e;
    }
    expect(err).toBeInstanceOf(HttpsError);
    expect(err.code).toBe('invalid-argument');
    expect(err.details).toEqual({ reason: REASON.giftAmountRange, min: 10, max: 1000 });
    expect(err.message.startsWith('gift-amount-range:')).toBe(true);
  });
});
