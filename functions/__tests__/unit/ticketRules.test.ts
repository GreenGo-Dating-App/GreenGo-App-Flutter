/**
 * Event ticket / guest rules (owner request 2026-10-18), pure parts:
 * plus-ones only on free events, places = 1 + plus-ones, the 4-per-buyer
 * cap, attendee name validation, the guest form name rows, the participants
 * CSV holder column and the ticket e-mail caption.
 */
import {
  attendeeFullName, attendeeSeats, cleanAttendeeName, eventTicketLimit, parseAttendeeNames, plusOnesAllowed,
  requiresAttendeeNames,
} from '../../src/ticket_payments/ticketRules';
import { ATTENDEE_NAME_MAX, MAX_TICKETS_PER_BUYER } from '../../src/ticket_payments/config';
import { perUserLimit } from '../../src/ticket_payments/orders';
import { guestAttendees, typedAttendeeNames } from '../../src/guest/guestService';
import { renderListingPage, ListingView } from '../../src/guest/guestPages';
import { buildParticipantsCsv } from '../../src/emails/participantsList';
import { ticketQrCaption } from '../../src/emails/ticketEmails';

describe('plus-ones (rule 1) and places (rule 5)', () => {
  test('paid events allow no plus-ones, whatever is stored', () => {
    expect(plusOnesAllowed({ price: 0, guestsAllowedPerAttendee: 2 })).toBe(2);
    expect(plusOnesAllowed({ guestsAllowedPerAttendee: 3 })).toBe(3);
    expect(plusOnesAllowed({ price: 25, guestsAllowedPerAttendee: 2 })).toBe(0);
    expect(plusOnesAllowed({ price: 0, ticketProvider: 'stripe', guestsAllowedPerAttendee: 2 })).toBe(0);
    expect(plusOnesAllowed({ guestsAllowedPerAttendee: 40 })).toBe(10);
    expect(plusOnesAllowed({ guestsAllowedPerAttendee: -1 })).toBe(0);
    expect(plusOnesAllowed(null)).toBe(0);
  });

  test('a going attendee takes 1 + plus-ones places; others none', () => {
    expect(attendeeSeats({ status: 'going' })).toBe(1);
    expect(attendeeSeats({ status: 'going', guestCount: 1 })).toBe(2);
    expect(attendeeSeats({ status: 'going', guestCount: 3, ticketCount: 4 })).toBe(4);
    expect(attendeeSeats({ status: 'waitlist', guestCount: 1 })).toBe(0);
    expect(attendeeSeats({ status: 'interested' })).toBe(0);
    expect(attendeeSeats({ status: 'going', guestCount: -2 })).toBe(1);
    // capacity 20, one "+1" RSVP -> 18 left
    expect(20 - attendeeSeats({ status: 'going', guestCount: 1 })).toBe(18);
  });
});

describe('at most 4 paid tickets per buyer per event (rule 2)', () => {
  test('the constant', () => expect(MAX_TICKETS_PER_BUYER).toBe(4));
  test('the event limit is the listing limit, never above 4', () => {
    expect(eventTicketLimit(perUserLimit({}))).toBe(4);
    expect(eventTicketLimit(perUserLimit({ maxTicketsPerUser: null }))).toBe(4);
    expect(eventTicketLimit(perUserLimit({ maxTicketsPerUser: 0 }))).toBe(4);
    expect(eventTicketLimit(perUserLimit({ maxTicketsPerUser: 2 }))).toBe(2);
    expect(eventTicketLimit(perUserLimit({ maxTicketsPerUser: 50 }))).toBe(4);
  });
});

describe('attendee names (rule 3)', () => {
  test('names are trimmed, collapsed, non-empty, bounded, no control / bidi characters', () => {
    expect(cleanAttendeeName('  Ana   Maria ')).toBe('Ana Maria');
    expect(cleanAttendeeName('')).toBeNull();
    expect(cleanAttendeeName('   ')).toBeNull();
    expect(cleanAttendeeName(42)).toBeNull();
    expect(cleanAttendeeName('x'.repeat(ATTENDEE_NAME_MAX))).toBe('x'.repeat(ATTENDEE_NAME_MAX));
    expect(cleanAttendeeName('x'.repeat(ATTENDEE_NAME_MAX + 1))).toBeNull();
    expect(cleanAttendeeName('Ana\u0000')).toBeNull();
    expect(cleanAttendeeName('Ana\u202eLima')).toBeNull();
    expect(cleanAttendeeName('<b>Ana</b>')).toBeNull();
    expect(cleanAttendeeName('José Ñúñez')).toBe('José Ñúñez');
  });

  test('exactly one valid name per ticket', () => {
    const two = [{ firstName: 'Ana', lastName: 'Lima' }, { firstName: ' João ', lastName: 'Silva' }];
    expect(parseAttendeeNames(two, 2)).toEqual([{ firstName: 'Ana', lastName: 'Lima' }, { firstName: 'João', lastName: 'Silva' }]);
    expect(parseAttendeeNames(two, 3)).toBeNull();
    expect(parseAttendeeNames(two.slice(0, 1), 2)).toBeNull();
    expect(parseAttendeeNames([{ firstName: 'Ana', lastName: '' }], 1)).toBeNull();
    expect(parseAttendeeNames('Ana Lima', 1)).toBeNull();
    expect(parseAttendeeNames(undefined, 1)).toBeNull();
    expect(attendeeFullName({ firstName: 'Ana', lastName: 'Lima' })).toBe('Ana Lima');
  });

  test('only paid events with the option ask for names', () => {
    expect(requiresAttendeeNames({ price: 20, requireAttendeeNames: true })).toBe(true);
    expect(requiresAttendeeNames({ price: 20 })).toBe(false);
    expect(requiresAttendeeNames({ price: 0, requireAttendeeNames: true })).toBe(false);
  });

  test('guest checkout: ticket 1 in the guest name, the others from the form rows', () => {
    const me = { firstName: 'Maria', lastName: 'Souza', email: 'm@x.test' };
    const body = { att_2_first: 'Ana', att_2_last: 'Lima', att_3_first: '', att_3_last: 'X' };
    expect(guestAttendees(body, me, 1)).toEqual([{ firstName: 'Maria', lastName: 'Souza' }]);
    expect(guestAttendees(body, me, 2)).toEqual([{ firstName: 'Maria', lastName: 'Souza' }, { firstName: 'Ana', lastName: 'Lima' }]);
    expect(guestAttendees(body, me, 3)).toBeNull();
    expect(guestAttendees(body, me, 5)).toBeNull();
    expect(typedAttendeeNames(body)).toHaveLength(MAX_TICKETS_PER_BUYER - 1);
  });

  test('the guest form renders an escaped name row per extra ticket', () => {
    const v: ListingView = {
      kind: 'e', id: 'ev1', locale: 'en', title: 'T', description: '', imageUrl: null, facts: [], seatsLeft: null,
      notice: null, error: null,
      form: { mode: 'pay', action: '/guest/e/ev1', token: 'tok', quantityMax: 4, attendeeNames: 4, provider: 'Stripe' },
      attendeeValues: [{ firstName: '<script>', lastName: 'Lima' }],
    };
    const html = renderListingPage(v);
    expect(html).toContain('Name on each ticket');
    for (const i of [2, 3, 4]) expect(html).toContain(`name="att_${i}_first"`);
    expect(html).not.toContain('name="att_1_first"');
    expect(html).not.toContain('<script>');
    expect(html).toContain('&lt;script&gt;');
  });

  test('participants CSV: a ticket holders column only when names were asked', () => {
    const base = { name: 'Maria', email: 'm@x.test', bookingCode: 'GG-AAAAAA', ticket: '2', status: 'paid' as const };
    const without = buildParticipantsCsv('en', [base]);
    expect(without).not.toContain('Ticket holders');
    const withNames = buildParticipantsCsv('en', [{ ...base, ticketHolders: 'Maria Souza; Ana Lima' }, { ...base, name: 'Zé' }]);
    const lines = withNames.replace('\ufeff', '').split('\r\n');
    expect(lines[0].endsWith(',Ticket holders')).toBe(true);
    expect(lines[1].endsWith(',Maria Souza; Ana Lima')).toBe(true);
    expect(lines[2].endsWith(',')).toBe(true);
  });

  test('the ticket e-mail caption names the holder', () => {
    expect(ticketQrCaption('Ticket 1 of 2', { attendeeName: 'Ana Lima' })).toBe('Ticket 1 of 2 · Ana Lima');
    expect(ticketQrCaption('Ticket 1 of 2', {})).toBe('Ticket 1 of 2');
  });
});
