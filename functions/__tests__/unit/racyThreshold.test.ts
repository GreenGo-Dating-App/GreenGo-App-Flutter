/**
 * Owner decision 2026-10-21: a "racy" (suggestive) photo is held back only at
 * VERY_LIKELY; holiday/beach photos scored LIKELY are published. Nudity
 * ("adult") stays at POSSIBLE.
 */
import { RACY_HOLD_AT, atLeast } from '../../src/safety/moderateUploadedImage';

describe('racy hold threshold', () => {
  test('is VERY_LIKELY', () => {
    expect(RACY_HOLD_AT).toBe('VERY_LIKELY');
  });

  test('LIKELY racy is not held, VERY_LIKELY is', () => {
    expect(atLeast('LIKELY', RACY_HOLD_AT)).toBe(false);
    expect(atLeast('POSSIBLE', RACY_HOLD_AT)).toBe(false);
    expect(atLeast('VERY_LIKELY', RACY_HOLD_AT)).toBe(true);
  });

  test('nudity is still held from POSSIBLE', () => {
    expect(atLeast('POSSIBLE', 'POSSIBLE')).toBe(true);
    expect(atLeast('UNLIKELY', 'POSSIBLE')).toBe(false);
  });
});
