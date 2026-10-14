/**
 * Guest identity (people who book a shared event / experience WITHOUT a
 * GreenGo account; see functions/src/guest/).
 *
 * A guest never signs in, so it has no Firebase Auth uid. Everywhere the data
 * model expects a buyer / guest id (ticket_orders.buyerId, tickets.buyerId,
 * events/{id}/attendees/{id}, bookings.guestId, ticket_holdings) a guest gets
 * a GUEST KEY instead:
 *
 *   guest_{40 hex}  = "guest_" + HMAC-SHA256(key, "guest:v1:" + email)[0..40)
 *
 * - Stable per e-mail address, so per-buyer limits, "one live order per buyer"
 *   and order reuse work unchanged for guests.
 * - Never equal to a real uid (Auth uids are 28 alphanumerics; this has a "_"
 *   and is 46 chars), and the rules only ever compare ids to request.auth.uid,
 *   so nobody can read a guest's orders / tickets / bookings from a client.
 * - Reveals nothing: the e-mail cannot be recovered from the key.
 *
 * The e-mail itself lives ONLY in guest_contacts/{guestKey} (server-only,
 * default-deny in firestore.rules): { email, locale, updatedAt, expireAt }.
 * Server code that mails a "user" (authEmailOf, resolveLocale) looks it up
 * there when the id is a guest key; pushes / in-app notifications and
 * "met in person" records skip guest keys.
 *
 * Pure (no firebase-admin) apart from the Firestore handle callers pass in.
 */
import * as crypto from 'crypto';

export const GUEST_KEY_PREFIX = 'guest_';
export const GUEST_CONTACTS = 'guest_contacts';
const GUEST_KEY_RE = /^guest_[0-9a-f]{40}$/;

/** True for a guest key (never a real Firebase Auth uid). */
export function isGuestKey(v: unknown): v is string {
  return typeof v === 'string' && GUEST_KEY_RE.test(v);
}

/** Lower-cased, trimmed address (the identity of a guest). */
export function normalizeGuestEmail(email: string): string {
  return email.trim().toLowerCase();
}

/** Guest key for [email], keyed with a server secret (see header). */
export function guestKeyFor(secret: string, email: string): string {
  if (!secret) throw new Error('no guest key secret');
  const mac = crypto.createHmac('sha256', secret).update(`guest:v1:${normalizeGuestEmail(email)}`).digest('hex');
  return `${GUEST_KEY_PREFIX}${mac.slice(0, 40)}`;
}

export interface GuestContact {
  email: string;
  locale: string | null;
}

/** guest_contacts/{key}, or null (not a guest key / missing / unreadable). */
export async function guestContactOf(
  db: FirebaseFirestore.Firestore,
  key: string,
): Promise<GuestContact | null> {
  if (!isGuestKey(key)) return null;
  try {
    const d = (await db.collection(GUEST_CONTACTS).doc(key).get()).data();
    if (!d || typeof d.email !== 'string' || !d.email) return null;
    return { email: d.email, locale: typeof d.locale === 'string' ? d.locale : null };
  } catch {
    return null;
  }
}

/**
 * A guest buying through ticket_payments/orders.ts createTicketCheckout (the
 * SAME checkout members use, so pricing / fees / holds / webhooks apply to
 * guests unchanged). Only instant checkout (Stripe / Mercado Pago) or a free
 * order; never the "link" mode.
 */
export interface GuestBuyer {
  firstName: string;
  lastName: string;
  /** Where the provider sends the guest back (guest pages, not the app). */
  returnUrl: (result: 'success' | 'cancel' | 'pending', orderId: string) => string;
}

/** "First Last" (what hosts and attendee lists show for a guest). */
export function guestDisplayName(g: { firstName?: unknown; lastName?: unknown } | null | undefined): string {
  const f = typeof g?.firstName === 'string' ? g.firstName.trim() : '';
  const l = typeof g?.lastName === 'string' ? g.lastName.trim() : '';
  return `${f} ${l}`.trim();
}

/** Fields every guest order / booking carries (names only; the e-mail stays in guest_contacts). */
export function guestRecordFields(g: { firstName: string; lastName: string }): Record<string, unknown> {
  return {
    isGuest: true,
    guest: { firstName: g.firstName, lastName: g.lastName },
    guestName: guestDisplayName(g),
  };
}
