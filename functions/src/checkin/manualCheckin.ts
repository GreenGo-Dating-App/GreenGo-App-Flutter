/**
 * My Space — event check-in CHECKLIST (organizer ticks attendees by hand).
 *
 * The door stays server-verified: clients still cannot write the check-in
 * fields (firestore.rules). This callable is the code-less path for the
 * organizer's checklist — a guest whose phone died, a name on a printed list:
 *
 *   setEventAttendeeCheckIn { eventId, userId, checkedIn: boolean }
 *
 *   - ONLY the event's organizer or a co-organizer (a delegated scanner must
 *     scan the ticket QR; it cannot tick names).
 *   - checkedIn true : same rules as the door (attendee 'going', paid ticket
 *     still valid on a ticketed event, inside the check-in window), written
 *     through admitEventAttendee with checkInMethod 'manual'; the "met in
 *     person" record is NOT verified (no code was shown).
 *   - checkedIn false: undo a mistaken check-in (any method). Clears the
 *     check-in fields; any time.
 *   - Both are audited in checkin_audit (server-only, no client rule).
 * Idempotent: ticking an already-ticked attendee returns alreadyCheckedIn.
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import {
  CHECKIN_AUDIT,
  admitEventAttendee,
  fail,
  sellsTickets,
  validTicketFor,
  withAuth,
} from './eventCheckin';

const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

/** Creator or co-owner (NOT a delegated scanner). */
export function canManageEventCheckIn(uid: string, ev: Record<string, any>): boolean {
  if (!uid) return false;
  if (ev.organizerId === uid) return true;
  const co: unknown = ev.coOrganizerIds;
  return Array.isArray(co) && co.includes(uid);
}

export async function setEventAttendeeCheckInImpl(uid: string, data: any): Promise<Record<string, unknown>> {
  const eventId = data?.eventId;
  const userId = data?.userId;
  if (typeof eventId !== 'string' || !ID_RE.test(eventId)) fail('invalid-argument', 'invalid_event_id');
  if (typeof userId !== 'string' || !ID_RE.test(userId)) fail('invalid-argument', 'invalid_user_id');
  if (typeof data?.checkedIn !== 'boolean') fail('invalid-argument', 'invalid_checked_in');
  const checkedIn: boolean = data.checkedIn;

  const db = admin.firestore();
  const evRef = db.collection('events').doc(eventId);
  const evSnap = await evRef.get();
  if (!evSnap.exists) fail('not-found', 'event_not_found');
  const ev = evSnap.data() as Record<string, any>;
  if (!canManageEventCheckIn(uid, ev)) fail('permission-denied', 'not_organizer');

  if (checkedIn) {
    let ticketId: string | null = null;
    if (sellsTickets(ev)) {
      // Ticketed event: the attendee's paid ticket must be valid NOW.
      const att = (await evRef.collection('attendees').doc(userId).get()).data();
      const t = await validTicketFor(att?.ticketId, eventId, userId);
      if (!t) fail('permission-denied', 'ticket_required');
      if (t.status !== 'valid') fail('permission-denied', 'ticket_not_valid', { status: t.status });
      ticketId = att?.ticketId ?? null;
    }
    const r = await admitEventAttendee(uid, eventId, userId, ev, false, ticketId, 'manual');
    return { ...r, checkedIn: true };
  }

  // Undo.
  const attRef = evRef.collection('attendees').doc(userId);
  const undone = await db.runTransaction(async (tx) => {
    const att = await tx.get(attRef);
    if (!att.exists) fail('not-found', 'not_registered');
    const a = att.data() as Record<string, any>;
    if (a.checkedIn !== true) return false;
    const del = admin.firestore.FieldValue.delete();
    tx.update(attRef, { checkedIn: false, checkedInAt: del, checkedInBy: del, checkInMethod: del });
    tx.create(db.collection(CHECKIN_AUDIT).doc(), {
      kind: 'event', action: 'undo', method: 'manual', eventId, targetUid: userId,
      previousMethod: a.checkInMethod ?? null, byUid: uid,
      at: admin.firestore.FieldValue.serverTimestamp(),
    });
    return true;
  });
  return { kind: 'event', eventId, userId, checkedIn: false, changed: undone };
}

export const setEventAttendeeCheckIn = withAuth(setEventAttendeeCheckInImpl);
