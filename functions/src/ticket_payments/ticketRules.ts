/**
 * Event ticket / guest rules (owner request 2026-10-17/18). Pure: no
 * firebase-admin, unit-tested in __tests__/unit/ticketRules.test.ts and
 * mirrored in the app (lib/features/ticket_payments/domain/ticket_rules.dart).
 *
 *  1. PAID events have no plus-ones. "Plus-ones" = the guests a member
 *     brings along on their own RSVP: the event's `guestsAllowedPerAttendee`
 *     (organizer setting) and the attendee doc's `guestCount` (the member's
 *     choice). On a paid event every person needs a ticket, so the setting is
 *     read as 0 whatever is stored ([plusOnesAllowed]). The attendee doc of a
 *     ticket BUYER still carries `guestCount = ticketCount - 1`, written by
 *     the server only (orders.ts markOrderPaid): those are paid seats, not
 *     plus-ones. (Shared-link guest booking without an account, the event's
 *     `guestsAllowed`, is a different feature.)
 *  2. At most MAX_TICKETS_PER_BUYER (4) paid tickets per buyer per event
 *     ([eventTicketLimit]; the ticket_holdings counter of orders.ts counts
 *     open holds + paid tickets and is released wherever seats are released).
 *  3. `requireAttendeeNames` events: a first + last name for EVERY ticket
 *     ([parseAttendeeNames]); stored on the order, each ticket and the
 *     organizer-only events/{id}/attendee_names/{buyerId}.
 *  5. Free events count PLACES: a going attendee takes 1 + guestCount
 *     ([attendeeSeats]); `events.attendeeCount` is that sum.
 */
import { ATTENDEE_NAME_MAX, MAX_TICKETS_PER_BUYER } from './config';

/** Paid event = price > 0 or a ticket provider set (mirrors firestore.rules isPaidEventData). */
function paid(ev: Record<string, any> | undefined | null): boolean {
  if (!ev) return false;
  const p = ev.price;
  return (typeof p === 'number' && p > 0) || ev.ticketProvider != null;
}

/** Plus-ones a member may bring on [ev]: 0 on paid events, else the organizer's setting (0..10). */
export function plusOnesAllowed(ev: Record<string, any> | undefined | null): number {
  if (!ev || paid(ev)) return 0;
  const n = Number(ev.guestsAllowedPerAttendee);
  return Number.isInteger(n) && n > 0 ? Math.min(n, 10) : 0;
}

/** Places a roster entry takes: going = 1 + guestCount (paid buyers: their tickets), else 0. */
export function attendeeSeats(a: Record<string, any> | undefined | null): number {
  if (!a || a.status !== 'going') return 0;
  const g = Math.floor(Number(a.guestCount) || 0);
  return 1 + Math.max(0, g);
}

/** The per-buyer cap of an event: its own limit (null = none) but never above MAX_TICKETS_PER_BUYER. */
export function eventTicketLimit(listingLimit: number | null): number {
  return listingLimit === null ? MAX_TICKETS_PER_BUYER : Math.min(listingLimit, MAX_TICKETS_PER_BUYER);
}

export interface AttendeeName {
  firstName: string;
  lastName: string;
}

// Control / format characters (incl. bidi overrides) never belong in a name.
// eslint-disable-next-line no-control-regex
const BAD_CHARS = /[\u0000-\u001f\u007f-\u009f\u200b-\u200f\u202a-\u202e\u2066-\u2069\ufeff<>]/;

/** A trimmed name (inner whitespace collapsed), 1..ATTENDEE_NAME_MAX chars, or null. */
export function cleanAttendeeName(v: unknown): string | null {
  if (typeof v !== 'string') return null;
  const s = v.replace(/\s+/g, ' ').trim();
  if (!s || [...s].length > ATTENDEE_NAME_MAX || BAD_CHARS.test(s)) return null;
  return s;
}

/**
 * `attendees` of a checkout for [quantity] tickets: exactly one
 * { firstName, lastName } per ticket, each valid. null = invalid / missing.
 */
export function parseAttendeeNames(raw: unknown, quantity: number): AttendeeName[] | null {
  if (!Array.isArray(raw) || raw.length !== quantity || quantity < 1 || quantity > 100) return null;
  const out: AttendeeName[] = [];
  for (const x of raw) {
    if (!x || typeof x !== 'object') return null;
    const firstName = cleanAttendeeName((x as any).firstName);
    const lastName = cleanAttendeeName((x as any).lastName);
    if (!firstName || !lastName) return null;
    out.push({ firstName, lastName });
  }
  return out;
}

/** "First Last". */
export function attendeeFullName(n: AttendeeName | null | undefined): string | null {
  return n ? `${n.firstName} ${n.lastName}` : null;
}

/** Does this event ask for a name per ticket? (paid events only). */
export function requiresAttendeeNames(ev: Record<string, any> | undefined | null): boolean {
  return !!ev && ev.requireAttendeeNames === true && paid(ev);
}
