/**
 * setExperienceFeatured — pure day-window math (featuredPatch).
 */
import { FEATURE_MAX_DAYS, featuredPatch } from '../../src/user_experiences/featuredPatch';

const NOW = Date.UTC(2026, 9, 1, 12);
const DAY = 24 * 60 * 60 * 1000;

describe('featuredPatch', () => {
  it('features for 1..30 days from now', () => {
    expect(featuredPatch(1, NOW)).toEqual({ isFeatured: true, featuredUntilMs: NOW + DAY });
    expect(featuredPatch(FEATURE_MAX_DAYS, NOW)).toEqual({
      isFeatured: true,
      featuredUntilMs: NOW + 30 * DAY,
    });
  });

  it('0 unfeatures', () => {
    expect(featuredPatch(0, NOW)).toEqual({ isFeatured: false, featuredUntilMs: null });
  });

  it.each([-1, 31, 1.5, NaN, '3', null, undefined])('rejects %p', (days) => {
    expect(featuredPatch(days, NOW)).toEqual({ error: 'invalid_days' });
  });
});
