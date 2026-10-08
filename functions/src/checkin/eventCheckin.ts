/**
 * Event QR check-in, server-verified.
 *
 * Before 4.4.0 the ticket QR was plain JSON (`greengo:{"e":eventId,"u":uid}`)
 * and the organizer's app wrote `checkedIn` straight to Firestore — anyone
 * could forge a ticket, and an attendee could even check THEMSELVES in.
 *
 * Now:
 *   - getEventTicketCode   (attendee, status 'going') returns a SIGNED ticket
 *                          `greengo:ev:{eventId}:{uid}:{code}`, code = 8 chars
 *                          of HMAC-SHA256(secret, "event:{eventId}:{uid}").
 *                          Deterministic, so the app can cache it and show it
 *                          offline at the venue.
 *   - checkInEventAttendee (organizer, co-organizer or delegated scanner)
 *                          verifies the ticket, the event, the time window and
 *                          the RSVP, then writes checkedIn/checkedInAt/
 *                          checkedInBy/checkInMethod and records a
 *                          "met in person" encounter (meetings.ts).
 *   - firestore.rules no longer let ANY client write the check-in fields.
 *
 * Legacy unsigned tickets (older app versions) are still accepted while
 * `app_config/event_checkin.allowLegacyTickets` is not false — checked in with
 * checkInMethod 'legacy' and a meeting recorded as NOT verified. Set the flag
 * to false once old versions are gone.
 */
import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import '../shared/firebaseAdmin';
import { recordMeeting } from './meetings';

const CALL_OPTS = { memory: '512MiB' as const, timeoutSeconds: 60 };
const HOUR_MS = 60 * 60 * 1000;
/** Doors open this long before the start … */
export const EVENT_CHECKIN_EARLY_HOURS = 3;
/** … and close this long after the end (or after the start when no end). */
export const EVENT_CHECKIN_LATE_HOURS = 12;
const DEFAULT_DURATION_HOURS = 6;

const B32 = 'ABCDEFGHJKMNPQRSTVWXYZ0123456789'; // no I, L, O, U

// ─────────────────────────────────────────────────────────── pure helpers

export function eventTicketCode(secret: string, eventId: string, uid: string): string {
  const mac = crypto.createHmac('sha256', secret).update(`event:${eventId}:${uid}`).digest();
  let out = '';
  for (let i = 0; i < 8; i++) out += B32[mac[i] % 32];
  return out;
}

export function verifyEventTicketCode(secret: string, eventId: string, uid: string, given: unknown): boolean {
  if (typeof given !== 'string') return false;
  const g = given.trim().toUpperCase();
  const want = eventTicketCode(secret, eventId, uid);
  if (g.length !== want.length) return false;
  return crypto.timingSafeEqual(Buffer.from(g), Buffer.from(want));
}

export function eventTicketPayload(eventId: string, uid: string, code: string): string {
  return `greengo:ev:${eventId}:${uid}:${code}`;
}

export type ParsedTicket =
  | { kind: 'signed'; eventId: string; userId: string; code: string }
  | { kind: 'legacy'; eventId: string; userId: string };

const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

/** Parses a scanned event ticket (signed or legacy JSON); null if neither. */
export function parseEventTicket(raw: unknown): ParsedTicket | null {
  if (typeof raw !== 'string') return null;
  const s = raw.trim();
  const m = /^greengo:ev:([^:]+):([^:]+):([A-Za-z0-9]{8})$/.exec(s);
  if (m) {
    if (!ID_RE.test(m[1]) || !ID_RE.test(m[2])) return null;
    return { kind: 'signed', eventId: m[1], userId: m[2], code: m[3].toUpperCase() };
  }
  if (s.startsWith('greengo:{')) {
    try {
      const j = JSON.parse(s.substring('greengo:'.length));
      const e = j?.e;
      const u = j?.u;
      if (typeof e === 'string' && typeof u === 'string' && ID_RE.test(e) && ID_RE.test(u)) {
        return { kind: 'legacy', eventId: e, userId: u };
      }
    } catch {
      return null;
    }
  }
  return null;
}

/** Whether [now] is inside the event's check-in window. */
export function inEventCheckInWindow(now: number, startMs: number | null, endMs: number | null): boolean {
  if (startMs === null) return true; // no schedule on file: do not lock the door
  const end = endMs !== null && endMs >= startMs ? endMs : startMs + DEFAULT_DURATION_HOURS * HOUR_MS;
  return now >= startMs - EVENT_CHECKIN_EARLY_HOURS * HOUR_MS
    && now <= end + EVENT_CHECKIN_LATE_HOURS * HOUR_MS;
}

export function canScanEvent(uid: string, ev: Record<string, any>): boolean {
  if (!uid) return false;
  if (ev.organizerId === uid) return true;
  const co: unknown = ev.coOrganizerIds;
  if (Array.isArray(co) && co.includes(uid)) return true;
  const sc: unknown = ev.allowedScannerIds;
  return Array.isArray(sc) && sc.includes(uid);
}

// ─────────────────────────────────────────────────────────── server side

function fail(code: ConstructorParameters<typeof HttpsError>[0], reason: string, extra: Record<string, unknown> = {}): never {
  throw new HttpsError(code, reason, { code: reason, ...extra });
}

function msOf(v: unknown): number | null {
  if (v instanceof admin.firestore.Timestamp) return v.toMillis();
  if (v instanceof Date) return v.getTime();
  if (typeof v === 'string') {
    const t = Date.parse(v);
    return Number.isNaN(t) ? null : t;
  }
  if (typeof v === 'number') return v;
  return null;
}

let cachedSecret: string | null = null;

/** HMAC key, created on first use in server_secrets/event_checkin (default-deny). */
async function ticketSecret(): Promise<string> {
  if (cachedSecret) return cachedSecret;
  const db = admin.firestore();
  const ref = db.collection('server_secrets').doc('event_checkin');
  cachedSecret = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const existing = snap.data()?.key;
    if (typeof existing === 'string' && existing.length >= 32) return existing;
    const fresh = crypto.randomBytes(32).toString('hex');
    tx.set(ref, { key: fresh, createdAt: admin.firestore.Timestamp.now() });
    return fresh;
  });
  return cachedSecret;
}

async function allowLegacyTickets(): Promise<boolean> {
  try {
    const snap = await admin.firestore().collection('app_config').doc('event_checkin').get();
    return snap.data()?.allowLegacyTickets !== false;
  } catch {
    return true;
  }
}

function withAuth(impl: (uid: string, data: any) => Promise<Record<string, unknown>>) {
  return onCall(CALL_OPTS, async (req: CallableRequest<any>) => {
    const uid = req.auth?.uid;
    if (!uid) fail('unauthenticated', 'unauthenticated');
    try {
      return await impl(uid, req.data ?? {});
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      console.error('[event_checkin] failed:', e);
      throw new HttpsError('internal', 'checkin_internal_error', { code: 'internal' });
    }
  });
}

/** Attendee: their signed ticket for an event they are going to. */
export const getEventTicketCode = withAuth(async (uid, data) => {
  const eventId = data?.eventId;
  if (typeof eventId !== 'string' || !ID_RE.test(eventId)) fail('invalid-argument', 'invalid_event_id');
  const att = await admin.firestore().collection('events').doc(eventId).collection('attendees').doc(uid).get();
  if (!att.exists || att.data()?.status !== 'going') fail('failed-precondition', 'not_going');
  const code = eventTicketCode(await ticketSecret(), eventId, uid);
  return { eventId, userId: uid, code, qrPayload: eventTicketPayload(eventId, uid, code) };
});

/**
 * Door: verify a scanned ticket and check the attendee in.
 * data: { eventId, payload } — eventId is the event the scanner has open (or,
 * from the QR hub, omitted: the ticket's own event is used and the caller's
 * rights on THAT event are checked).
 */
export const checkInEventAttendee = withAuth(async (uid, data) => {
  const ticket = parseEventTicket(data?.payload);
  if (!ticket) fail('invalid-argument', 'invalid_code');
  const openEventId = typeof data?.eventId === 'string' ? data.eventId : null;
  if (openEventId && openEventId !== ticket.eventId) fail('failed-precondition', 'wrong_event');

  const db = admin.firestore();
  const evRef = db.collection('events').doc(ticket.eventId);
  const evSnap = await evRef.get();
  if (!evSnap.exists) fail('not-found', 'event_not_found');
  const ev = evSnap.data() as Record<string, any>;
  if (!canScanEvent(uid, ev)) fail('permission-denied', 'not_scanner');

  let verified: boolean;
  if (ticket.kind === 'signed') {
    if (!verifyEventTicketCode(await ticketSecret(), ticket.eventId, ticket.userId, ticket.code)) {
      fail('permission-denied', 'invalid_code');
    }
    verified = true;
  } else {
    if (!(await allowLegacyTickets())) fail('permission-denied', 'legacy_ticket_rejected');
    verified = false;
  }
  if (!inEventCheckInWindow(Date.now(), msOf(ev.startDate), msOf(ev.endDate))) {
    fail('failed-precondition', 'outside_checkin_window');
  }

  const attRef = evRef.collection('attendees').doc(ticket.userId);
  const res = await db.runTransaction(async (tx) => {
    const att = await tx.get(attRef);
    if (!att.exists) fail('not-found', 'not_registered');
    const a = att.data() as Record<string, any>;
    if (a.status !== 'going') fail('failed-precondition', 'not_going', { status: a.status ?? null });
    if (a.checkedIn === true) return { already: true, a };
    tx.update(attRef, {
      checkedIn: true,
      checkedInAt: admin.firestore.FieldValue.serverTimestamp(),
      checkedInBy: uid,
      checkInMethod: verified ? 'signed' : 'legacy',
    });
    return { already: false, a };
  });

  if (!res.already) {
    const title = String(ev.title ?? '');
    const ctx = { type: 'event' as const, contextId: ticket.eventId, title, verified, byUid: uid };
    await recordMeeting(String(ev.organizerId ?? ''), ticket.userId, ctx);
    const co: string[] = Array.isArray(ev.coOrganizerIds) ? ev.coOrganizerIds : [];
    if (uid !== ev.organizerId && co.includes(uid)) await recordMeeting(uid, ticket.userId, ctx);
  }
  return {
    eventId: ticket.eventId,
    userId: ticket.userId,
    userName: res.a.userName ?? '',
    userPhotoUrl: res.a.userPhotoUrl ?? null,
    guestCount: Number(res.a.guestCount ?? 0),
    alreadyCheckedIn: res.already,
    verified,
  };
});
