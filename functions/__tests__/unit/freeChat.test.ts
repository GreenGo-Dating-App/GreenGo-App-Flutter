/**
 * Free chats without Base (entitlements/freeChat.ts): 3 people per UTC day.
 */
jest.mock('firebase-functions/v2/firestore', () => ({
  onDocumentCreated: (_o: any, h: any) => h,
  onDocumentWritten: (_o: any, h: any) => h,
}));
jest.mock('firebase-functions/v2/https', () => ({
  onCall: (_o: any, h: any) => h,
  HttpsError: class extends Error {},
}));
jest.mock('../../src/shared/firebaseAdmin', () => ({}));
jest.mock('firebase-admin', () => ({
  firestore: Object.assign(() => ({}), { FieldValue: {}, Timestamp: {} }),
}));
jest.mock('../../src/shared/utils', () => ({ logInfo: jest.fn() }));
jest.mock('../../src/shared/monitoring', () => ({ monitored: (_n: string, h: any) => h }));

import { decideFreeChat, freeChatsToday, isOneToOneMember } from '../../src/entitlements/freeChat';
import { FREE_DAILY_CHATS } from '../../src/shared/tierLimits';

const NOW = Date.parse('2026-10-13T15:00:00Z');
const DAY = 86_400_000;
const TODAY = Math.floor(NOW / DAY) * DAY;

test('the free allowance is 3 people a day', () => {
  expect(FREE_DAILY_CHATS).toBe(3);
});

test('a new user gets a first free chat', () => {
  expect(decideFreeChat(undefined, 'c1', NOW)).toEqual({ allowed: true, convs: ['c1'], added: true });
});

test('the 4th different person on the same day is refused', () => {
  const usage = { freeChatDayStartMs: TODAY, freeChatConvs: ['a', 'b', 'c'] };
  expect(decideFreeChat(usage, 'd', NOW)).toEqual({ allowed: false, convs: ['a', 'b', 'c'], added: false });
});

test('replying to someone already chatted with today is always allowed', () => {
  const usage = { freeChatDayStartMs: TODAY, freeChatConvs: ['a', 'b', 'c'] };
  expect(decideFreeChat(usage, 'b', NOW)).toEqual({ allowed: true, convs: ['a', 'b', 'c'], added: false });
});

test('the list resets at the next UTC day', () => {
  const usage = { freeChatDayStartMs: TODAY - DAY, freeChatConvs: ['a', 'b', 'c'] };
  expect(freeChatsToday(usage, NOW)).toEqual([]);
  expect(decideFreeChat(usage, 'd', NOW).allowed).toBe(true);
});

test('only plain 1:1 conversations the caller belongs to count', () => {
  expect(isOneToOneMember({ userId1: 'me', userId2: 'you' }, 'me')).toBe(true);
  expect(isOneToOneMember({ userId1: 'you', userId2: 'me' }, 'me')).toBe(true);
  expect(isOneToOneMember({ userId1: 'x', userId2: 'y' }, 'me')).toBe(false);
  expect(isOneToOneMember({ userId1: 'me', userId2: 'support_system' }, 'me')).toBe(false);
  expect(isOneToOneMember({ userId1: 'me', userId2: 'you', participants: ['me', 'you', 'z'] }, 'me')).toBe(false);
  expect(isOneToOneMember(undefined, 'me')).toBe(false);
});
