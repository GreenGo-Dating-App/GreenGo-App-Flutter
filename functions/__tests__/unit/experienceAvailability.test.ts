/**
 * Experience availability engine (pure): generation math, overrides
 * precedence, notice / advance limits, time zones and DST.
 */
import { dayTimes, generateSlots, localToUtc, overlaps, rulesError, AvailabilityRules } from '../../src/experience_bookings/availability';

const base: AvailabilityRules = {
  timezone: 'America/Sao_Paulo',
  windowStart: '09:00',
  windowEnd: '20:00',
  durationMinutes: 120,
  weekdays: [1, 2, 3, 4, 5, 6, 7],
  capacityPerSlot: 10,
  minNoticeHours: 0,
  maxAdvanceDays: 365,
};
const NOW = Date.UTC(2026, 9, 1); // 1 Oct 2026

describe('generation math', () => {
  test('last slot must fit: 09-20 with 2 h -> 09, 11, 13, 15, 17 (not 19)', () => {
    expect(dayTimes(base, '2026-10-12')).toEqual(['09:00', '11:00', '13:00', '15:00', '17:00']);
  });
  test('start every 1 h -> 09..18', () => {
    expect(dayTimes({ ...base, startEveryMinutes: 60 }, '2026-10-12')).toEqual(
      ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00']);
  });
  test('buffer between sessions', () => {
    expect(dayTimes({ ...base, bufferMinutes: 30 }, '2026-10-12')).toEqual(['09:00', '11:30', '14:00', '16:30']);
  });
  test('weekdays filter (Mon=1 .. Sun=7)', () => {
    expect(dayTimes({ ...base, weekdays: [6, 7] }, '2026-10-12')).toEqual([]); // Monday
    expect(dayTimes({ ...base, weekdays: [6, 7] }, '2026-10-17')).toHaveLength(5); // Saturday
  });
});

describe('overrides precedence: closed > explicit slots > window change > generated - removed + added', () => {
  const ov = {
    dayOverrides: {
      '2026-10-12': { closed: true, slots: ['10:00'] },
      '2026-10-13': { slots: ['10:00', '14:00'], windowStart: '06:00' },
      '2026-10-14': { windowStart: '12:00', windowEnd: '16:00' },
    },
    removedSlots: ['2026-10-15T11:00'],
    addedSlots: ['2026-10-15T19:30', '2026-10-12T19:00'],
  };
  const from = Date.UTC(2026, 9, 12, 3);
  const to = Date.UTC(2026, 9, 16, 3);
  const keys = generateSlots(base, ov, from, to, NOW).map((s) => s.key);
  test('closed day has nothing, even added slots', () => {
    expect(keys.filter((k) => k.startsWith('2026-10-12'))).toEqual([]);
  });
  test('explicit slots replace the generated ones', () => {
    expect(keys.filter((k) => k.startsWith('2026-10-13'))).toEqual(['2026-10-13T10:00', '2026-10-13T14:00']);
  });
  test('window change for one day', () => {
    expect(keys.filter((k) => k.startsWith('2026-10-14'))).toEqual(['2026-10-14T12:00', '2026-10-14T14:00']);
  });
  test('removed and added single slots', () => {
    expect(keys.filter((k) => k.startsWith('2026-10-15'))).toEqual(
      ['2026-10-15T09:00', '2026-10-15T13:00', '2026-10-15T15:00', '2026-10-15T17:00', '2026-10-15T19:30']);
  });
});

describe('limits and time zones', () => {
  test('min notice and max advance', () => {
    const now = Date.UTC(2026, 9, 12, 12); // 09:00 in São Paulo
    const s = generateSlots({ ...base, minNoticeHours: 5, maxAdvanceDays: 1 }, undefined, now - 86400000, now + 3 * 86400000, now);
    expect(s[0].key).toBe('2026-10-12T15:00'); // 09/11/13 too soon
    expect(s.every((x) => x.startMs <= now + 86400000)).toBe(true);
  });
  test('local time to UTC in the host zone', () => {
    expect(localToUtc('2026-10-12', '09:00', 'America/Sao_Paulo')).toBe(Date.UTC(2026, 9, 12, 12));
    expect(localToUtc('2026-10-12', '09:00', 'Europe/Rome')).toBe(Date.UTC(2026, 9, 12, 7));
  });
  test('DST transition: Europe/Rome 25 Oct 2026 (CEST -> CET) keeps local times', () => {
    const r = { ...base, timezone: 'Europe/Rome' };
    const day = generateSlots(r, undefined, Date.UTC(2026, 9, 24, 22), Date.UTC(2026, 9, 25, 22), NOW);
    expect(day.map((s) => s.time)).toEqual(['09:00', '11:00', '13:00', '15:00', '17:00']);
    expect(day[0].startMs).toBe(Date.UTC(2026, 9, 25, 8)); // UTC+1 after the change
    const before = localToUtc('2026-10-24', '09:00', 'Europe/Rome');
    expect(before).toBe(Date.UTC(2026, 9, 24, 7)); // UTC+2 before
  });
  test('non-existent local time (spring forward) is skipped', () => {
    expect(localToUtc('2026-03-29', '02:30', 'Europe/Rome')).toBeNull();
  });
});

test('overlap + rule validation', () => {
  expect(overlaps({ startMs: 0, endMs: 10 }, { startMs: 5, endMs: 15 })).toBe(true);
  expect(overlaps({ startMs: 0, endMs: 10 }, { startMs: 10, endMs: 15 })).toBe(false);
  expect(rulesError(base)).toBeNull();
  expect(rulesError({ ...base, startEveryMinutes: 60 })).toBe('overlapping_slots');
  expect(rulesError({ ...base, timezone: 'Mars/Base' })).toBe('invalid_timezone');
  expect(rulesError({ ...base, windowEnd: '08:00' })).toBe('invalid_window');
  expect(rulesError({ ...base, capacityPerSlot: 0 })).toBe('invalid_capacity');
});
