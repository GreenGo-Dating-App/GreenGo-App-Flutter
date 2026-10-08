import {
  canScanEvent,
  eventTicketCode,
  eventTicketPayload,
  inEventCheckInWindow,
  parseEventTicket,
  verifyEventTicketCode,
} from '../../src/checkin/eventCheckin';
import { encounterIdOf, pairIdOf } from '../../src/checkin/meetings';

const SECRET = 'a'.repeat(64);
const H = 60 * 60 * 1000;

describe('event ticket codes', () => {
  test('signed code is deterministic, 8 readable chars, bound to event AND user', () => {
    const c = eventTicketCode(SECRET, 'ev1', 'u1');
    expect(c).toMatch(/^[ABCDEFGHJKMNPQRSTVWXYZ0-9]{8}$/);
    expect(eventTicketCode(SECRET, 'ev1', 'u1')).toBe(c);
    expect(verifyEventTicketCode(SECRET, 'ev1', 'u1', c)).toBe(true);
    expect(verifyEventTicketCode(SECRET, 'ev1', 'u1', c.toLowerCase())).toBe(true);
    expect(verifyEventTicketCode(SECRET, 'ev2', 'u1', c)).toBe(false);
    expect(verifyEventTicketCode(SECRET, 'ev1', 'u2', c)).toBe(false);
    expect(verifyEventTicketCode('b'.repeat(64), 'ev1', 'u1', c)).toBe(false);
    expect(verifyEventTicketCode(SECRET, 'ev1', 'u1', 'AAAAAAA')).toBe(false);
    expect(verifyEventTicketCode(SECRET, 'ev1', 'u1', null)).toBe(false);
  });

  test('parses signed and legacy tickets, rejects everything else', () => {
    const code = eventTicketCode(SECRET, 'ev1', 'u1');
    expect(parseEventTicket(eventTicketPayload('ev1', 'u1', code)))
      .toEqual({ kind: 'signed', eventId: 'ev1', userId: 'u1', code });
    expect(parseEventTicket('greengo:{"e":"ev1","u":"u1"}'))
      .toEqual({ kind: 'legacy', eventId: 'ev1', userId: 'u1' });
    expect(parseEventTicket('greengo:checkin:bk_1:ABCDEFGH')).toBeNull();
    expect(parseEventTicket('greengo:ev:ev1:u1:SHORT')).toBeNull();
    expect(parseEventTicket('greengo:ev:ev/1:u1:ABCDEFGH')).toBeNull();
    expect(parseEventTicket('greengo:{"e":"ev1"}')).toBeNull();
    expect(parseEventTicket('greengo:{not json')).toBeNull();
    expect(parseEventTicket(42)).toBeNull();
  });
});

describe('door rules', () => {
  test('check-in window: 3h before the start to 12h after the end', () => {
    const start = 100 * H;
    const end = start + 2 * H;
    expect(inEventCheckInWindow(start - 3 * H, start, end)).toBe(true);
    expect(inEventCheckInWindow(start - 3 * H - 1, start, end)).toBe(false);
    expect(inEventCheckInWindow(end + 12 * H, start, end)).toBe(true);
    expect(inEventCheckInWindow(end + 12 * H + 1, start, end)).toBe(false);
    // no end on file: 6h default duration
    expect(inEventCheckInWindow(start + 18 * H, start, null)).toBe(true);
    expect(inEventCheckInWindow(start + 18 * H + 1, start, null)).toBe(false);
  });

  test('organizer, co-organizers and delegated scanners may scan; nobody else', () => {
    const ev = { organizerId: 'o', coOrganizerIds: ['c'], allowedScannerIds: ['s'] };
    expect(canScanEvent('o', ev)).toBe(true);
    expect(canScanEvent('c', ev)).toBe(true);
    expect(canScanEvent('s', ev)).toBe(true);
    expect(canScanEvent('x', ev)).toBe(false);
    expect(canScanEvent('', ev)).toBe(false);
  });

  test('a pair of members has ONE id whatever the order', () => {
    expect(pairIdOf('b', 'a')).toBe('a_b');
    expect(pairIdOf('a', 'b')).toBe('a_b');
    expect(encounterIdOf('event', 'ev1')).toBe('event_ev1');
  });
});
