/**
 * declareAge counts an 18th birthday from the caller's LOCAL midnight.
 *
 * Before: the server used the UTC date, so an adult in UTC+X picking their
 * exact birthday in the first hours of the day was answered "17" and
 * permanently recorded in age_gate.
 */

import { ageOn, callerToday, parseDob } from '../../src/auth/ageGate';

describe('callerToday', () => {
  // 2026-10-08 23:30 UTC: already 2026-10-09 in UTC+1 .. UTC+14.
  const now = new Date(Date.UTC(2026, 9, 8, 23, 30));

  it('accepts the next calendar day when it is already today somewhere', () => {
    expect(callerToday('2026-10-09', now)).toEqual(parseDob('2026-10-09'));
  });

  it('accepts the UTC date and the previous day within UTC-12', () => {
    expect(callerToday('2026-10-08', now)).toEqual(parseDob('2026-10-08'));
    const early = new Date(Date.UTC(2026, 9, 8, 5, 0)); // 2026-10-07 17:00 in UTC-12
    expect(callerToday('2026-10-07', early)).toEqual(parseDob('2026-10-07'));
  });

  it('rejects dates that are not today anywhere, and garbage', () => {
    const utcToday = parseDob('2026-10-08');
    expect(callerToday('2026-10-10', now)).toEqual(utcToday);
    expect(callerToday('2025-10-09', now)).toEqual(utcToday);
    expect(callerToday(undefined, now)).toEqual(utcToday);
    expect(callerToday('tomorrow', now)).toEqual(utcToday);
  });

  it('exact 18th birthday in UTC+2 counts as 18; one day short stays 17', () => {
    const today = callerToday('2026-10-09', now);
    expect(ageOn(parseDob('2008-10-09')!, today)).toBe(18);
    expect(ageOn(parseDob('2008-10-10')!, today)).toBe(17);
    // Without the local date the same pick used to be 17.
    expect(ageOn(parseDob('2008-10-09')!, now)).toBe(17);
  });
});
