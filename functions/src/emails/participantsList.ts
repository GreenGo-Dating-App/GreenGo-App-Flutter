/**
 * Organizer participants list (CSV attachment by email).
 *
 *  - sendParticipantListsDue (every 10 min): events (status 'published') and
 *    experience slots (confirmed bookings) starting within the next hour ->
 *    the listing organizer / host gets the CSV once (email_dispatch claim per
 *    event start / slot). Indexed range queries only:
 *      events   status ==, startDate range        (existing index)
 *      bookings status ==, slotStart range        (new index, see firestore.indexes.json)
 *  - sendParticipantsList({kind, id, slotStart?}) callable: the organizer (or
 *    an event co-organizer; the host for experiences) gets the current list on
 *    demand at their account email. Rate limit: 1 per 5 min per listing/slot.
 *
 * CSV columns: name, email, booking code, ticket type / party size, status
 * (paid / confirmed / checked-in), headers in the organizer's language.
 * Emails are included for ticket buyers and experience guests only (both saw
 * the sharing notice at checkout / booking); free event RSVPs are listed by
 * name only.
 * PRIVACY: buyers are told at checkout/booking that their name and email are
 * shared with the organizer for entry (checkoutOrganizerShareNotice).
 */
import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { t } from '../shared/i18n';
import { resolveLocale } from '../shared/i18n/recipientLocale';
import { checkInCode } from '../experience_bookings/model';
import { checkInSecret } from '../experience_bookings/service';
import {
  authEmailOf, authEmailsOf, EMAIL_DISPATCH, dispatchId, emailDeps, escapeHtml, OutgoingEmail, sendEmail, sendEmailOnce,
} from './sendEmail';
import { emailFrame, formatWhen, hostTimeZone, millis } from './emailFormat';
import { orderBookingCode } from './ticketEmails';

const db = () => emailDeps.db();
const MIN = 60 * 1000;
export const LEAD_MS = 60 * MIN;
export const RATE_LIMIT_MS = 5 * MIN;
const PAGE = 300;
const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

export type ParticipantStatus = 'paid' | 'confirmed' | 'checked_in';

export interface ParticipantRow {
  name: string;
  email: string;
  bookingCode: string;
  ticket: string;
  status: ParticipantStatus;
}

// ─────────────────────────────────────────────────────────── CSV (pure)

/**
 * One CSV cell (RFC 4180): quoted when it contains a comma, quote, CR/LF or
 * edge spaces; quotes doubled. Cells starting with = + - @ TAB CR are prefixed
 * with ' so a spreadsheet never evaluates a user-chosen name as a formula.
 */
export function csvCell(v: unknown): string {
  let s = v === null || v === undefined ? '' : String(v);
  if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  if (/[",\r\n]/.test(s) || /^\s|\s$/.test(s)) s = `"${s.replace(/"/g, '""')}"`;
  return s;
}

export function statusLabel(locale: unknown, s: ParticipantStatus): string {
  return s === 'checked_in' ? t(locale, 'csvStatusCheckedIn') : s === 'paid' ? t(locale, 'csvStatusPaid') : t(locale, 'csvStatusConfirmed');
}

/** UTF-8 BOM (Excel) + header + rows, CRLF line endings. */
export function buildParticipantsCsv(locale: unknown, rows: ParticipantRow[]): string {
  const header = [t(locale, 'csvColName'), t(locale, 'csvColEmail'), t(locale, 'csvColBookingCode'), t(locale, 'csvColTicket'), t(locale, 'csvColStatus')];
  const lines = [header, ...rows.map((r) => [r.name, r.email, r.bookingCode, r.ticket, statusLabel(locale, r.status)])]
    .map((cells) => cells.map(csvCell).join(','));
  return '﻿' + lines.join('\r\n') + '\r\n';
}

/** Scheduler window: listings starting in (now, now + LEAD]. */
export function dueWindow(nowMs: number, leadMs = LEAD_MS): { from: number; to: number } {
  return { from: nowMs, to: nowMs + leadMs };
}

export function participantsDispatchKey(kind: 'event' | 'experience', id: string, startMs: number): string {
  return `participants_${kind}_${id}_${startMs}`;
}

export function safeFileName(title: string): string {
  const base = title.normalize('NFKD').replace(/[^\w\s-]/g, '').trim().replace(/\s+/g, '-').slice(0, 60);
  return `participants-${base || 'list'}.csv`;
}

/** Permission: organizer or co-organizer (events) / host (experiences). */
export function canReceiveList(kind: 'event' | 'experience', uid: string, listing: Record<string, any> | undefined): boolean {
  if (!listing || !uid) return false;
  if (kind === 'event') {
    if (listing.organizerId === uid) return true;
    return Array.isArray(listing.coOrganizerIds) && listing.coOrganizerIds.includes(uid);
  }
  return listing.hostId === uid;
}

function sortRows(rows: ParticipantRow[]): ParticipantRow[] {
  return rows.sort((a, b) => a.name.localeCompare(b.name) || a.bookingCode.localeCompare(b.bookingCode));
}

// ─────────────────────────────────────────────────────────── gather

async function displayNames(uids: string[]): Promise<Map<string, string>> {
  const out = new Map<string, string>();
  const unique = [...new Set(uids.filter(Boolean))];
  for (let i = 0; i < unique.length; i += PAGE) {
    const snaps = await db().getAll(...unique.slice(i, i + PAGE).map((u) => db().collection('profiles').doc(u)));
    snaps.forEach((s) => {
      const p = s.data();
      const n = String(p?.displayName ?? p?.nickname ?? p?.name ?? '').trim();
      if (n) out.set(s.id, n);
    });
  }
  return out;
}

export async function eventParticipants(eventId: string): Promise<ParticipantRow[]> {
  const evRef = db().collection('events').doc(eventId);
  const attendees: Array<{ id: string; d: Record<string, any> }> = [];
  let last: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  for (;;) {
    let q = evRef.collection('attendees').where('status', '==', 'going')
      .orderBy(admin.firestore.FieldPath.documentId()).limit(PAGE);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    snap.docs.forEach((d) => attendees.push({ id: d.id, d: d.data() }));
    if (snap.size < PAGE) break;
    last = snap.docs[snap.docs.length - 1];
  }
  if (!attendees.length) return [];

  // Paid tickets of this event, grouped by buyer (single-field listingId index).
  const byBuyer = new Map<string, Array<Record<string, any>>>();
  let lastT: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  for (;;) {
    let q = db().collection('tickets').where('listingId', '==', eventId)
      .orderBy(admin.firestore.FieldPath.documentId()).limit(PAGE);
    if (lastT) q = q.startAfter(lastT);
    const snap = await q.get();
    for (const d of snap.docs) {
      const tk = d.data();
      if (tk.kind !== 'event' || tk.status !== 'valid') continue;
      const list = byBuyer.get(String(tk.buyerId)) || [];
      list.push(tk);
      byBuyer.set(String(tk.buyerId), list);
    }
    if (snap.size < PAGE) break;
    lastT = snap.docs[snap.docs.length - 1];
  }

  // Emails only for ticket BUYERS: they saw "your name and email will be
  // shared with the organizer" at checkout. A free RSVP never showed that
  // notice, so its row carries the name only.
  const emails = await authEmailsOf(attendees.map((a) => String(a.d.userId || a.id)).filter((u) => byBuyer.has(u)));
  return sortRows(attendees.map(({ id, d }) => {
    const uid = String(d.userId || id);
    const tks = byBuyer.get(uid) || [];
    const codes = [...new Set(tks.map((tk) => orderBookingCode(String(tk.orderId || ''), { code: tk.code })).filter(Boolean))];
    const types = new Map<string, number>();
    for (const tk of tks) {
      const n = typeof tk.ticketTypeName === 'string' && tk.ticketTypeName ? tk.ticketTypeName : '';
      types.set(n, (types.get(n) || 0) + 1);
    }
    const party = tks.length || Math.max(1, Number(d.ticketCount) || (1 + (Number(d.guestCount) || 0)));
    const typeText = [...types.entries()].filter(([n]) => n).map(([n, c]) => `${n} × ${c}`).join('; ');
    const checkedIn = d.checkedIn === true || tks.some((tk) => !!tk.checkedInAt);
    return {
      name: String(d.userName || '').trim(),
      email: tks.length ? emails.get(uid) || '' : '',
      bookingCode: codes.join(' '),
      ticket: typeText ? `${typeText} (${party})` : String(party),
      status: checkedIn ? 'checked_in' : (tks.length ? 'paid' : 'confirmed'),
    } as ParticipantRow;
  }));
}

export async function experienceSlotParticipants(experienceId: string, slotStartMs: number): Promise<ParticipantRow[]> {
  const snap = await db().collection('bookings')
    .where('experienceId', '==', experienceId)
    .where('slotStart', '==', admin.firestore.Timestamp.fromMillis(slotStartMs))
    .limit(2000).get();
  const bookings = snap.docs.map((d) => ({ id: d.id, b: d.data() })).filter(({ b }) => b.status === 'confirmed');
  if (!bookings.length) return [];
  const guestIds = bookings.map(({ b }) => String(b.guestId || ''));
  const orderIds = bookings.map(({ b }) => b.payment?.orderId).filter((x): x is string => typeof x === 'string' && ID_RE.test(x));
  const [names, emails, secret, orderSnaps] = await Promise.all([
    displayNames(guestIds),
    authEmailsOf(guestIds),
    checkInSecret(),
    orderIds.length ? db().getAll(...orderIds.map((id) => db().collection('ticket_orders').doc(id))) : Promise.resolve([]),
  ]);
  const orders = new Map<string, Record<string, any>>();
  orderSnaps.forEach((s) => { if (s.exists) orders.set(s.id, s.data()!); });
  return sortRows(bookings.map(({ id, b }) => {
    const orderId = typeof b.payment?.orderId === 'string' ? b.payment.orderId : null;
    const paid = b.payment?.status === 'paid' || !!b.payment?.hostConfirmedPaidAt;
    return {
      name: names.get(String(b.guestId)) || '',
      email: emails.get(String(b.guestId)) || '',
      bookingCode: orderId ? orderBookingCode(orderId, orders.get(orderId)) : checkInCode(secret, id),
      ticket: String(Math.max(1, Number(b.guests) || 1)),
      status: b.checkIn ? 'checked_in' : (paid ? 'paid' : 'confirmed'),
    } as ParticipantRow;
  }));
}

// ─────────────────────────────────────────────────────────── email

export async function buildParticipantsEmail(opts: {
  to: string; locale: string; title: string; startMs: number | null; timeZone: string; rows: ParticipantRow[];
}): Promise<OutgoingEmail> {
  const { locale: L, rows } = opts;
  const when = formatWhen(opts.startMs, opts.timeZone, L);
  const intro = t(L, 'emailParticipantsIntro', { title: opts.title, when, count: rows.length });
  return {
    to: [opts.to],
    subject: t(L, 'emailParticipantsSubject', { title: opts.title }),
    html: emailFrame(`<p>${escapeHtml(intro)}</p><p style="color:#666;font-size:13px">${escapeHtml(t(L, 'emailParticipantsPrivacy'))}</p>`),
    text: `${intro}\n\n${t(L, 'emailParticipantsPrivacy')}`,
    attachments: [{
      filename: safeFileName(opts.title),
      content: Buffer.from(buildParticipantsCsv(L, rows), 'utf8'),
      contentType: 'text/csv; charset=utf-8',
    }],
  };
}

interface ListTarget {
  kind: 'event' | 'experience';
  id: string;
  startMs: number;
  title: string;
  timeZone: string;
}

async function rowsFor(target: ListTarget): Promise<ParticipantRow[]> {
  return target.kind === 'event'
    ? eventParticipants(target.id)
    : experienceSlotParticipants(target.id, target.startMs);
}

/** Scheduler path: one email per listing start, only with >= 1 participant. */
export async function sendDueList(target: ListTarget, organizerId: string): Promise<string> {
  const key = participantsDispatchKey(target.kind, target.id, target.startMs);
  if ((await db().collection(EMAIL_DISPATCH).doc(dispatchId(key)).get()).exists) return 'duplicate';
  const locale = await resolveLocale(organizerId);
  const rows = await rowsFor(target);
  if (!rows.length) return 'empty'; // not claimed: a later run may still send
  const r = await sendEmailOnce(key, async () => {
    const to = await authEmailOf(organizerId);
    return to ? buildParticipantsEmail({ to, locale, title: target.title, startMs: target.startMs, timeZone: target.timeZone, rows }) : null;
  }, { type: 'participants_list', kind: target.kind, listingId: target.id, organizerId });
  return r === 'duplicate' ? 'duplicate' : (r.sent ? 'sent' : `not_sent:${r.reason}`);
}

/** One scheduler pass. Exported for tests. */
export async function runParticipantListsDue(nowMs = emailDeps.now()): Promise<{ events: number; slots: number; sent: number }> {
  const { from, to } = dueWindow(nowMs);
  const fromTs = admin.firestore.Timestamp.fromMillis(from);
  const toTs = admin.firestore.Timestamp.fromMillis(to);
  let events = 0; let slots = 0; let sent = 0;

  // Events: status + startDate range (existing composite index), paginated.
  let lastE: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  for (;;) {
    let q = db().collection('events').where('status', '==', 'published')
      .where('startDate', '>', fromTs).where('startDate', '<=', toTs).orderBy('startDate').limit(200);
    if (lastE) q = q.startAfter(lastE);
    const snap = await q.get();
    for (const d of snap.docs) {
      const e = d.data();
      const startMs = millis(e.startDate);
      if (startMs === null || typeof e.organizerId !== 'string') continue;
      events++;
      try {
        const r = await sendDueList({ kind: 'event', id: d.id, startMs, title: String(e.title || 'Event'), timeZone: hostTimeZone(e) }, e.organizerId);
        if (r === 'sent') sent++;
      } catch (err) {
        console.error('[participants] event', d.id, (err as Error)?.message);
      }
    }
    if (snap.size < 200) break;
    lastE = snap.docs[snap.docs.length - 1];
  }

  // Experience slots: confirmed bookings by slotStart (status + slotStart index).
  const groups = new Map<string, { experienceId: string; hostId: string; startMs: number; title: string }>();
  let lastB: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  for (;;) {
    let q = db().collection('bookings').where('status', '==', 'confirmed')
      .where('slotStart', '>', fromTs).where('slotStart', '<=', toTs).orderBy('slotStart').limit(500);
    if (lastB) q = q.startAfter(lastB);
    const snap = await q.get();
    for (const d of snap.docs) {
      const b = d.data();
      const startMs = millis(b.slotStart);
      if (startMs === null || typeof b.experienceId !== 'string' || typeof b.hostId !== 'string') continue;
      const k = `${b.experienceId}_${startMs}`;
      if (!groups.has(k)) groups.set(k, { experienceId: b.experienceId, hostId: b.hostId, startMs, title: String(b.experienceTitle || '') });
    }
    if (snap.size < 500) break;
    lastB = snap.docs[snap.docs.length - 1];
  }
  for (const g of groups.values()) {
    slots++;
    try {
      const exp = (await db().collection('user_experiences').doc(g.experienceId).get()).data() || {};
      const r = await sendDueList({
        kind: 'experience', id: g.experienceId, startMs: g.startMs,
        title: g.title || String(exp.title || 'Experience'), timeZone: hostTimeZone(exp),
      }, g.hostId);
      if (r === 'sent') sent++;
    } catch (err) {
      console.error('[participants] slot', g.experienceId, g.startMs, (err as Error)?.message);
    }
  }
  return { events, slots, sent };
}

export const sendParticipantListsDue = onSchedule(
  { schedule: 'every 10 minutes', timeZone: 'UTC', memory: '512MiB', timeoutSeconds: 540 },
  async () => {
    const r = await runParticipantListsDue();
    if (r.events || r.slots) console.log(`[participants] due pass: ${r.events} events, ${r.slots} slots, ${r.sent} sent`);
  },
);

// ─────────────────────────────────────────────────────────── callable

function fail(code: 'invalid-argument' | 'permission-denied' | 'not-found' | 'failed-precondition' | 'resource-exhausted' | 'unavailable', reason: string): never {
  throw new HttpsError(code, reason, { code: reason });
}

/** 1 request per RATE_LIMIT_MS per (uid, listing, slot). Throws when limited. */
export async function takeRateLimit(uid: string, key: string, nowMs: number): Promise<void> {
  const ref = db().collection('participant_list_requests').doc(dispatchId(`${uid}_${key}`));
  await db().runTransaction(async (tx) => {
    const last = millis((await tx.get(ref)).data()?.lastAt);
    if (last !== null && nowMs - last < RATE_LIMIT_MS) fail('resource-exhausted', 'rate_limited');
    tx.set(ref, {
      uid, key, lastAt: admin.firestore.Timestamp.fromMillis(nowMs),
      expireAt: admin.firestore.Timestamp.fromMillis(nowMs + 2 * 86400000),
    });
  });
}

export async function sendParticipantsListImpl(uid: string, data: any): Promise<Record<string, unknown>> {
  const kind = data?.kind;
  const id = data?.id;
  if (kind !== 'event' && kind !== 'experience') fail('invalid-argument', 'invalid_kind');
  if (typeof id !== 'string' || !ID_RE.test(id)) fail('invalid-argument', 'invalid_id');
  const now = emailDeps.now();
  const listing = (await db().collection(kind === 'event' ? 'events' : 'user_experiences').doc(id).get()).data();
  if (!listing) fail('not-found', 'listing_not_found');
  if (!canReceiveList(kind, uid, listing)) fail('permission-denied', 'not_organizer');

  let startMs: number | null;
  if (kind === 'event') {
    startMs = millis(listing.startDate);
  } else {
    startMs = data?.slotStart !== undefined && data?.slotStart !== null ? millis(data.slotStart) : null;
    if (startMs === null) {
      // Next (or currently running) slot with bookings.
      const next = await db().collection('bookings').where('experienceId', '==', id)
        .where('slotStart', '>=', admin.firestore.Timestamp.fromMillis(now - 12 * 60 * MIN))
        .orderBy('slotStart').limit(1).get();
      startMs = next.empty ? null : millis(next.docs[0].data().slotStart);
      if (startMs === null) fail('failed-precondition', 'no_upcoming_slot');
    }
  }
  const to = await authEmailOf(uid);
  if (!to) fail('failed-precondition', 'no_email');
  const rateKey = `${kind}_${id}_${startMs ?? 0}`;
  await takeRateLimit(uid, rateKey, now);

  const locale = await resolveLocale(uid);
  const target: ListTarget = {
    kind, id, startMs: startMs ?? 0, title: String(listing.title || (kind === 'event' ? 'Event' : 'Experience')), timeZone: hostTimeZone(listing),
  };
  const rows = await rowsFor(target);
  const r = await sendEmail(await buildParticipantsEmail({ to, locale, title: target.title, startMs, timeZone: target.timeZone, rows }));
  if (!r.sent) {
    // Nothing was delivered: do not make the organizer wait out the limit.
    await db().collection('participant_list_requests').doc(dispatchId(`${uid}_${rateKey}`)).delete().catch(() => undefined);
    fail('unavailable', r.reason === 'not_configured' ? 'email_not_configured' : 'email_failed');
  }
  return { sent: true, count: rows.length };
}

export const sendParticipantsList = onCall({ memory: '512MiB', timeoutSeconds: 120 }, async (req: CallableRequest<any>) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.', { code: 'unauthenticated' });
  try {
    return await sendParticipantsListImpl(uid, req.data ?? {});
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    console.error('[participants] callable failed:', e);
    throw new HttpsError('internal', 'participants_internal_error', { code: 'internal' });
  }
});
