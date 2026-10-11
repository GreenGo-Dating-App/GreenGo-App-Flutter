/**
 * Pure helpers of the server-owned usage counters (entitlements/usage.ts):
 * what counts as a new connection, an ongoing event and an event slot.
 */
jest.mock('firebase-functions/v2/firestore', () => ({
  onDocumentCreated: (_o: any, h: any) => h,
  onDocumentWritten: (_o: any, h: any) => h,
}));
jest.mock('../../src/shared/firebaseAdmin', () => ({}));
jest.mock('firebase-admin', () => ({
  firestore: Object.assign(() => ({}), { FieldValue: {}, Timestamp: {} }),
}));
jest.mock('../../src/shared/utils', () => ({ logInfo: jest.fn() }));
jest.mock('../../src/shared/monitoring', () => ({ monitored: (_n: string, h: any) => h }));

import {
  connectsToday,
  eventSlots,
  isOngoingEvent,
  isSupportConversation,
  slotKeyOf,
  sortedEnds,
} from '../../src/entitlements/usage';

const NOW = Date.parse('2026-10-11T12:00:00Z');
const DAY = 86_400_000;

test('support tickets are not new connections', () => {
  expect(isSupportConversation({ conversationType: 'support' })).toBe(true);
  expect(isSupportConversation({ userId2: 'support_system' })).toBe(true);
  expect(isSupportConversation({ matchId: 'support' })).toBe(true);
  expect(isSupportConversation({ userId1: 'a', userId2: 'b', matchId: 'search_a_b' })).toBe(false);
  expect(isSupportConversation(undefined)).toBe(false);
});

test('connects are counted per UTC day', () => {
  const start = Date.parse('2026-10-11T00:00:00Z');
  expect(connectsToday({ connectDayStartMs: start, connectCount: 7 }, NOW)).toBe(7);
  expect(connectsToday({ connectDayStartMs: start - DAY, connectCount: 7 }, NOW)).toBe(0);
  expect(connectsToday(undefined, NOW)).toBe(0);
});

test('ongoing events: end in the future, not cancelled / completed; a series is one slot', () => {
  const ev = (id: string, endMs: number | null, extra: any = {}) => ({ id, endMs, ...extra });
  expect(isOngoingEvent(ev('a', NOW + 1), NOW)).toBe(true);
  expect(isOngoingEvent(ev('a', NOW - 1), NOW)).toBe(false);
  expect(isOngoingEvent(ev('a', null), NOW)).toBe(false);
  expect(isOngoingEvent(ev('a', NOW + 1, { status: 'cancelled' }), NOW)).toBe(false);
  expect(isOngoingEvent(ev('a', NOW + 1, { status: 'completed' }), NOW)).toBe(false);
  expect(slotKeyOf({ id: 'x', seriesId: 's1' })).toBe('s:s1');
  expect(slotKeyOf({ id: 'x', seriesId: null })).toBe('e:x');

  const list = [
    ev('a', NOW + DAY), ev('b', NOW + 3 * DAY),
    ev('s1', NOW + 7 * DAY, { seriesId: 'S' }), ev('s2', NOW + 14 * DAY, { seriesId: 'S' }),
    ev('old', NOW - DAY), ev('gone', NOW + DAY, { status: 'cancelled' }),
  ];
  const { slots, series } = eventSlots(list, NOW);
  expect(slots.size).toBe(3);
  expect(series).toEqual({ S: 2 });
  // The rules index this list: ascending; a series slot ends with its LAST occurrence.
  expect(sortedEnds(slots)).toEqual([NOW + DAY, NOW + 3 * DAY, NOW + 14 * DAY]);
  expect(eventSlots(list, NOW, 's:S').slots.size).toBe(2);
});
