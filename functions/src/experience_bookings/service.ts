/**
 * Experience bookings — server operations (callable bodies, job bodies).
 * See ./model.ts for the data model, state machine and policy rules.
 *
 * Every status change goes through `transition()`: ONE Firestore transaction
 * that re-reads the booking, checks `canTransition(from, to)`, writes the
 * booking, gives seats back to the slot when the new status no longer holds
 * them, and counts host cancellations. Re-running any operation is safe: an
 * operation that already happened returns its result instead of failing
 * (`noop`), and createBooking is keyed by a client requestId.
 *
 * Nothing here moves money: `refundDue` is an obligation recorded for both
 * parties (paid experiences are paid through the host's external link).
 */

import { MODERATION_ROLES } from '../shared/adminAuth';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { HttpsError, FunctionsErrorCode } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { tierDateFromValue } from '../shared/effectiveTier';
import { emitNotification, resolveActor, Actor } from '../notifications/notifyHelpers';
import { recordMeeting } from '../checkin/meetings';
import { requestOrderRefund } from '../ticket_payments/orders';
import { SLOT_COUNTERS, counterId as slotCounterId, generateSlots, rulesError, AvailabilityRules } from './availability';
import {
  ACTIVE_STATUSES,
  BOOKINGS,
  BookingConfig,
  BookingStatus,
  CancelledBy,
  DAY_MS,
  EXPERIENCES,
  HOST_ACTIONS,
  HOST_CANCEL_STATS,
  HOST_FLAGS,
  HOST_SUSPENSIONS,
  HostAction,
  PENDING_REVIEWS,
  PaymentMode,
  REVIEW_ELIGIBILITY,
  SERVER_SECRETS,
  SLOTS,
  acceptedPaymentMethods,
  bookingIdFor,
  choosePaymentMethod,
  canMarkNoShow,
  canTransition,
  checkInCode,
  checkInQrPayload,
  cleanText,
  completeAtMs,
  computeBookingPrice,
  idDocumentStateOf,
  inCheckInWindow,
  inDisputeWindow,
  isBannedProfile,
  isDocId,
  isRequestId,
  policyOf,
  pruneCancellations,
  refundDueFor,
  refundFor,
  reminderAtMs,
  requestExpiresAtMs,
  resolveConfig,
  seatsReleased,
  shouldFlagHost,
  verifyCheckInCode,
  onlineProviderOf,
  pricingModeOf,
  resolveDatePrice,
  groupSizeError,
  linkMethodOf,
  MAX_BOOKING_LENGTH_MS,
  bookingLengthMs,
  chooseStart,
  overlapsAny,
  windowStarts,
} from './model';

// ─────────────────────────────────────────────────────────── dependencies

export interface NotifyParams {
  recipientId: string;
  type: string;
  title: string;
  body: string;
  data: Record<string, string>;
  actor?: Actor;
}

/** Overridable in unit tests; production uses the defaults. */
export const bookingDeps = {
  db: (): FirebaseFirestore.Firestore => admin.firestore(),
  now: (): Date => new Date(),
  notify: (p: NotifyParams): Promise<void> => emitNotification(p),
  actor: (uid: string): Promise<Actor> => resolveActor(uid),
};

const fdb = () => bookingDeps.db();
const nowMs = () => bookingDeps.now().getTime();
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const del = () => admin.firestore.FieldValue.delete();

export function msOf(v: unknown): number | null {
  const d = tierDateFromValue(v);
  return d ? d.getTime() : null;
}

function fail(code: FunctionsErrorCode, reason: string, extra: Record<string, unknown> = {}): never {
  throw new HttpsError(code, reason, { code: reason, ...extra });
}

async function safeNotify(p: NotifyParams): Promise<void> {
  try {
    await bookingDeps.notify(p);
  } catch (e) {
    console.error(`[bookings] notify ${p.type} -> ${p.recipientId} failed:`, e);
  }
}

async function safeActor(uid: string): Promise<Actor | undefined> {
  try {
    return await bookingDeps.actor(uid);
  } catch {
    return undefined;
  }
}

export async function loadConfig(): Promise<BookingConfig> {
  try {
    const snap = await fdb().collection('app_config').doc('experience_bookings').get();
    return resolveConfig(snap.data() ?? null);
  } catch {
    return resolveConfig(null);
  }
}

/**
 * Admin for booking disputes = superAdmin | moderator in admin_users (central
 * shared/adminAuth). P1-6: legacy users.role == 'admin' is no longer accepted.
 */
export async function isAdminUid(uid: string): Promise<boolean> {
  // Same source of truth as shared/adminAuth (active admin_users doc), read via
  // the injectable bookingDeps db. Legacy role spellings that notifyAdmins
  // below also uses ('admin', 'super_admin') are kept.
  const a = await fdb().collection('admin_users').doc(uid).get();
  const d = a.data();
  if (!a.exists || d?.isActive === false) return false;
  return [...MODERATION_ROLES, 'admin', 'super_admin'].includes(String(d?.role ?? ''));
}

/** Either user blocked the other (root blockedUsers + the profile block list). */
export async function isBlockedEitherWay(a: string, b: string): Promise<boolean> {
  const db = fdb();
  const [ab, ba, pa, pb] = await Promise.all([
    db.collection('blockedUsers').where('blockerId', '==', a).where('blockedUserId', '==', b).limit(1).get(),
    db.collection('blockedUsers').where('blockerId', '==', b).where('blockedUserId', '==', a).limit(1).get(),
    db.collection('profiles').doc(a).collection('blocked_users').doc(b).get(),
    db.collection('profiles').doc(b).collection('blocked_users').doc(a).get(),
  ]);
  return !ab.empty || !ba.empty || pa.exists || pb.exists;
}

export async function notifyAdmins(type: string, title: string, body: string, data: Record<string, string>): Promise<void> {
  try {
    const admins = await fdb().collection('admin_users')
      .where('role', 'in', ['super_admin', 'superAdmin', 'admin', 'moderator']).limit(50).get();
    await Promise.all(admins.docs.map((d) => safeNotify({ recipientId: d.id, type, title, body, data })));
  } catch (e) {
    console.error('[bookings] admin notification failed:', e);
  }
}

let cachedSecret: string | null = null;

/**
 * HMAC key for check-in codes. Generated on first use and kept in
 * server_secrets/booking_checkin (no client rule matches: default deny), so
 * nothing has to be provisioned before deploying.
 */
export async function checkInSecret(): Promise<string> {
  if (cachedSecret) return cachedSecret;
  const ref = fdb().collection(SERVER_SECRETS).doc('booking_checkin');
  const key = await fdb().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const existing = snap.data()?.key;
    if (typeof existing === 'string' && existing.length >= 32) return existing;
    const fresh = crypto.randomBytes(32).toString('hex');
    tx.set(ref, { key: fresh, createdAt: ts(nowMs()) });
    return fresh;
  });
  cachedSecret = key;
  return key;
}

/** Test hook. */
export function resetCachedSecret(): void {
  cachedSecret = null;
}

// ─────────────────────────────────────────────────────────── output shape

function iso(v: unknown): string | null {
  const m = msOf(v);
  return m === null ? null : new Date(m).toISOString();
}

/** What every callable returns about a booking (JSON-safe). */
export function bookingView(id: string, b: Record<string, any>): Record<string, unknown> {
  return {
    bookingId: id,
    experienceId: b.experienceId,
    slotId: b.slotId,
    hostId: b.hostId,
    guestId: b.guestId,
    guests: b.guests,
    status: b.status,
    requestToBook: b.requestToBook === true,
    policy: b.policy,
    price: b.price ?? null,
    payment: {
      mode: b.payment?.mode ?? 'free',
      link: b.payment?.link ?? null,
      provider: b.payment?.provider ?? null,
      linkMethod: b.payment?.linkMethod ?? null,
      status: b.payment?.status ?? null,
      orderId: b.payment?.orderId ?? null,
      paidAt: iso(b.payment?.paidAt),
      guestMarkedPaidAt: iso(b.payment?.guestMarkedPaidAt),
      hostConfirmedPaidAt: iso(b.payment?.hostConfirmedPaidAt),
    },
    refundDue: b.refundDue
      ? { ...b.refundDue, decidedAt: iso(b.refundDue.decidedAt) }
      : null,
    slotStart: iso(b.slotStart),
    slotEnd: iso(b.slotEnd),
    requestExpiresAt: iso(b.requestExpiresAt),
    checkedInAt: iso(b.checkIn?.at),
    dispute: b.dispute
      ? { status: b.dispute.status, openedAt: iso(b.dispute.openedAt), resolution: b.dispute.resolution
        ? { ...b.dispute.resolution, at: iso(b.dispute.resolution.at) }
        : null }
      : null,
  };
}

function notifData(bookingId: string, b: Record<string, any>): Record<string, string> {
  return { action: 'booking', bookingId, experienceId: String(b.experienceId || '') };
}

/** Confirmation text that tells the guest how to pay. */
function payHint(b: Record<string, any>): string {
  const mode = b.payment?.mode;
  if (mode === 'link') return `${title(b)} — pay the host with their payment link.`;
  if (mode === 'online') return `${title(b)} — pay in the app to get your ticket.`;
  if (mode === 'cash') return `${title(b)} — pay the host in cash when you meet.`;
  return title(b);
}

function title(b: Record<string, any>): string {
  const t = typeof b.experienceTitle === 'string' ? b.experienceTitle.trim() : '';
  return t.length > 80 ? `${t.slice(0, 79)}…` : (t || 'Experience');
}

// ─────────────────────────────────────────────────────────── transition core

interface Plan {
  /** Target status; omitted for field-only updates (check-in, paid marks). */
  to?: BookingStatus;
  patch?: Record<string, unknown>;
  /** Count a host cancellation (host cancels a CONFIRMED booking). */
  hostPenalty?: boolean;
  /** Already done: no write, return the current booking. */
  noop?: boolean;
  /** Extra writes inside the same transaction (after all reads). */
  extra?: (tx: FirebaseFirestore.Transaction, b: Record<string, any>) => void;
}

export interface TransitionResult {
  id: string;
  before: Record<string, any>;
  after: Record<string, any>;
  noop: boolean;
  hostFlagged: boolean;
}

/** Host cancellation bookkeeping, inside a transaction (reads done by caller). */
function writeHostPenalty(
  tx: FirebaseFirestore.Transaction,
  hostId: string,
  statsSnap: FirebaseFirestore.DocumentSnapshot,
  now: number,
  cfg: BookingConfig,
  context: Record<string, unknown>,
): boolean {
  const d = statsSnap.data() || {};
  const prev: number[] = (Array.isArray(d.recent) ? d.recent : [])
    .map((x: unknown) => msOf(x)).filter((x: number | null): x is number => x !== null);
  const recent = pruneCancellations(prev, now, cfg);
  const flag = shouldFlagHost(recent, msOf(d.flaggedAt), now, cfg);
  tx.set(statsSnap.ref, {
    hostId,
    recent: recent.map(ts),
    count: recent.length,
    updatedAt: ts(now),
    ...(flag ? { flaggedAt: ts(now) } : {}),
  }, { merge: true });
  if (flag) {
    tx.set(fdb().collection(HOST_FLAGS).doc(hostId), {
      hostId,
      type: 'excess_host_cancellations',
      status: 'open',
      count: recent.length,
      windowDays: cfg.hostCancelWindowDays,
      ...context,
      createdAt: ts(now),
      updatedAt: ts(now),
    }, { merge: true });
  }
  return flag;
}

export async function transition(
  bookingId: string,
  decide: (b: Record<string, any>, now: number) => Plan,
  cfg: BookingConfig,
): Promise<TransitionResult> {
  const db = fdb();
  const ref = db.collection(BOOKINGS).doc(bookingId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) fail('not-found', 'booking_not_found');
    const b = snap.data() as Record<string, any>;
    const now = nowMs();
    const plan = decide(b, now);
    if (plan.noop) return { id: bookingId, before: b, after: b, noop: true, hostFlagged: false };
    if (plan.to && !canTransition(b.status, plan.to)) {
      fail('failed-precondition', 'invalid_transition', { from: b.status, to: plan.to });
    }
    const guestsHeld = b.pricingMode === 'per_group' ? 1 : (Number(b.guests) || 0);
    const release = plan.to ? seatsReleased(b.status, plan.to, guestsHeld) : 0;
    const slotRef = b.counterId
      ? db.collection(SLOT_COUNTERS).doc(String(b.counterId))
      : db.collection(EXPERIENCES).doc(b.experienceId).collection(SLOTS).doc(b.slotId);
    const statsRef = db.collection(HOST_CANCEL_STATS).doc(b.hostId);
    // All reads before any write.
    const slotSnap = release > 0 ? await tx.get(slotRef) : null;
    const statsSnap = plan.hostPenalty ? await tx.get(statsRef) : null;

    const after = { ...b, ...(plan.patch || {}), ...(plan.to ? { status: plan.to } : {}), updatedAt: ts(now) };
    tx.update(ref, { ...(plan.patch || {}), ...(plan.to ? { status: plan.to } : {}), updatedAt: ts(now) });
    if (slotSnap?.exists) {
      const field = b.counterId ? 'booked' : 'bookedCount';
      const booked = Number(slotSnap.data()?.[field]) || 0;
      tx.update(slotRef, { [field]: Math.max(0, booked - release), updatedAt: ts(now) });
    }
    let hostFlagged = false;
    if (statsSnap) {
      hostFlagged = writeHostPenalty(tx, b.hostId, statsSnap, now, cfg, {
        lastBookingId: bookingId, lastExperienceId: b.experienceId,
      });
    }
    plan.extra?.(tx, after);
    return { id: bookingId, before: b, after, noop: false, hostFlagged };
  });
}

function roleOf(uid: string, b: Record<string, any>): CancelledBy | null {
  if (uid === b.guestId) return 'guest';
  if (uid === b.hostId) return 'host';
  return null;
}

function requireBookingId(data: any): string {
  const id = data?.bookingId;
  if (!isDocId(id)) fail('invalid-argument', 'invalid_booking_id');
  return id;
}

function eligibilityWrite(tx: FirebaseFirestore.Transaction, b: Record<string, any>, bookingId: string, now: number, cfg: BookingConfig) {
  const end = msOf(b.slotEnd) ?? now;
  tx.set(
    fdb().collection(EXPERIENCES).doc(b.experienceId).collection(REVIEW_ELIGIBILITY).doc(b.guestId),
    {
      bookingId,
      guestId: b.guestId,
      hostId: b.hostId,
      experienceId: b.experienceId,
      reviewUntil: ts(Math.max(end, now) + cfg.reviewWindowDays * DAY_MS),
      createdAt: ts(now),
    },
  );
}

async function flaggedHostFollowUp(r: TransitionResult | { hostFlagged: boolean }, hostId: string): Promise<void> {
  if (!r.hostFlagged) return;
  await notifyAdmins(
    'admin_host_cancellations',
    'Host flagged for cancellations',
    `Host ${hostId} cancelled confirmed bookings repeatedly. Review host_flags/${hostId}.`,
    { action: 'admin_host_flag', hostId },
  );
}

// ─────────────────────────────────────────────────────────── createBooking

/** Per-host lock doc: every booking of a host writes it in its transaction,
 * so two bookings for the same host can never be decided concurrently
 * (server-only collection; no client rule matches). */
const HOST_SCHEDULES = 'host_schedules';

/** Query of a host's bookings that could overlap [fromMs, toMs). */
function hostBookingsQuery(hostId: string, fromMs: number, toMs: number) {
  return fdb().collection(BOOKINGS)
    .where('hostId', '==', hostId)
    .where('slotStart', '>=', ts(fromMs - MAX_BOOKING_LENGTH_MS))
    .where('slotStart', '<', ts(toMs))
    .limit(500);
}

/** [start, end) of the host's ACTIVE bookings (requested + confirmed). */
function busyFrom(docs: FirebaseFirestore.QueryDocumentSnapshot[], excludeId?: string): Array<[number, number]> {
  const out: Array<[number, number]> = [];
  for (const d of docs) {
    if (d.id === excludeId) continue;
    const b = d.data();
    if (!(ACTIVE_STATUSES as readonly string[]).includes(b.status)) continue;
    const s0 = msOf(b.slotStart);
    const e0 = msOf(b.slotEnd);
    if (s0 !== null && e0 !== null && e0 > s0) out.push([s0, e0]);
  }
  return out;
}

function requestedStartOf(v: unknown): number | null {
  if (typeof v === 'number' && Number.isFinite(v)) return Math.round(v);
  if (typeof v === 'string' && v.trim()) {
    const t = Date.parse(v);
    return Number.isNaN(t) ? null : t;
  }
  return null;
}

/**
 * Start times of one availability window for the booking screen:
 * { lengthMinutes, starts: [{ start, end, free }] }. Free = in the future and
 * not overlapping ANY active booking of the host (all their experiences).
 * Reveals only busy/free, never who booked.
 */
export async function getSlotAvailability(uid: string, data: any): Promise<Record<string, unknown>> {
  const { experienceId, slotId } = data || {};
  if (!isDocId(experienceId)) fail('invalid-argument', 'invalid_experience_id');
  if (!isDocId(slotId)) fail('invalid-argument', 'invalid_slot_id');
  const expRef = fdb().collection(EXPERIENCES).doc(experienceId);
  const [exp, slot] = await Promise.all([expRef.get(), expRef.collection(SLOTS).doc(slotId).get()]);
  const e = exp.data();
  const sl = slot.data();
  if (!e || (e.status !== 'published' && e.hostId !== uid)) fail('not-found', 'experience_not_found');
  if (!sl) fail('not-found', 'slot_not_found');
  const ws = msOf(sl.start);
  const we = msOf(sl.end);
  if (ws === null || we === null || we <= ws) fail('failed-precondition', 'slot_invalid');
  const len = bookingLengthMs(e.durationMinutes, ws, we);
  const busySnap = await hostBookingsQuery(String(e.hostId), ws, we).get();
  const busy = busyFrom(busySnap.docs);
  const now = nowMs();
  const open = sl.status === 'open';
  return {
    slotId,
    lengthMinutes: Math.round(len / 60000),
    starts: windowStarts(ws, we, len).map((t) => ({
      start: new Date(t).toISOString(),
      end: new Date(t + len).toISOString(),
      free: open && t > now && !overlapsAny(t, t + len, busy),
    })),
  };
}

export async function createBooking(uid: string, data: any): Promise<Record<string, unknown>> {
  const { experienceId, guests, requestId } = data || {};
  const requestedStart = requestedStartOf(data?.startAt);
  // Recurring availability (availability.ts): slotId 'recurring' + startAt.
  // The booking's slotId becomes r_{startMs} and seats live in
  // experience_slot_counters/{experienceId}_{startMs} (created lazily).
  const recurring = data?.slotId === 'recurring';
  if (recurring && requestedStart === null) fail('invalid-argument', 'invalid_start');
  const slotId: string = recurring ? `r_${requestedStart}` : data?.slotId;
  if (!isDocId(experienceId)) fail('invalid-argument', 'invalid_experience_id');
  if (!isDocId(slotId)) fail('invalid-argument', 'invalid_slot_id');
  if (!isRequestId(requestId)) fail('invalid-argument', 'invalid_request_id');
  // The booking terms the guest accepted: passed explicitly (string or int),
  // or taken from their user_experiences/{id}/booking_consents/{uid} record.
  let consentVersion = Number.isInteger(data?.consentVersion)
    ? String(data.consentVersion)
    : cleanText(data?.consentVersion, 32);
  if (!consentVersion) {
    const consent = await fdb().collection(EXPERIENCES).doc(experienceId)
      .collection('booking_consents').doc(uid).get();
    const v = consent.data()?.version;
    if (consent.exists && consent.data()?.experienceId === experienceId && Number.isInteger(v)) {
      consentVersion = String(v);
    }
  }
  if (!consentVersion) fail('invalid-argument', 'consent_required');
  const cfg = await loadConfig();
  if (!Number.isInteger(guests) || guests < 1 || guests > cfg.maxGuestsPerBooking) {
    fail('invalid-argument', 'invalid_guests', { max: cfg.maxGuestsPerBooking });
  }

  const db = fdb();
  const bookingId = bookingIdFor(uid, requestId);
  const bookingRef = db.collection(BOOKINGS).doc(bookingId);
  const expRef = db.collection(EXPERIENCES).doc(experienceId);
  const slotRef = recurring
    ? db.collection(SLOT_COUNTERS).doc(slotCounterId(experienceId, requestedStart as number))
    : expRef.collection(SLOTS).doc(slotId);

  // Retry of a booking that already exists: answer without re-validating.
  const prior = await bookingRef.get();
  if (prior.exists) {
    const p = prior.data() as Record<string, any>;
    if (p.guestId !== uid) fail('already-exists', 'request_id_conflict');
    return { ...bookingView(bookingId, p), alreadyExisted: true };
  }

  const pre = await expRef.get();
  if (!pre.exists) fail('not-found', 'experience_not_found');
  const hostId = String(pre.data()?.hostId || '');
  if (!hostId) fail('failed-precondition', 'experience_not_bookable');
  if (hostId === uid) fail('failed-precondition', 'own_experience');
  if (await isBlockedEitherWay(hostId, uid)) fail('permission-denied', 'not_available');

  const result = await db.runTransaction(async (tx) => {
    const dupQ = db.collection(BOOKINGS)
      .where('guestId', '==', uid)
      .where('slotId', '==', slotId)
      .where('status', 'in', ACTIVE_STATUSES as unknown as string[])
      .limit(10);
    const lockRef = db.collection(HOST_SCHEDULES).doc(hostId);
    const [existing, exp, slot, guestP, hostP, susp, dup, lock] = await Promise.all([
      tx.get(bookingRef), tx.get(expRef), tx.get(slotRef),
      tx.get(db.collection('profiles').doc(uid)),
      tx.get(db.collection('profiles').doc(hostId)),
      tx.get(db.collection(HOST_SUSPENSIONS).doc(hostId)),
      tx.get(dupQ),
      tx.get(lockRef),
    ]);
    void lock; // read so this transaction conflicts with the host's other bookings
    if (existing.exists) {
      const e = existing.data() as Record<string, any>;
      if (e.guestId !== uid) fail('already-exists', 'request_id_conflict');
      return { created: false, booking: e };
    }
    const now = nowMs();
    const e = exp.data() as Record<string, any> | undefined;
    if (!e || e.hostId !== hostId) fail('not-found', 'experience_not_found');
    if (e.status !== 'published') fail('failed-precondition', 'experience_not_bookable');
    const host = hostP.data() ?? null;
    if (!hostP.exists || isBannedProfile(host)) fail('failed-precondition', 'host_unavailable');
    if (susp.exists && susp.data()?.active !== false) fail('failed-precondition', 'host_unavailable');
    const guest = guestP.data() ?? null;
    if (!guestP.exists || isBannedProfile(guest)) fail('permission-denied', 'account_restricted');
    if (idDocumentStateOf(guest) === 'none') fail('failed-precondition', 'id_document_required');

    const sizeErr = groupSizeError(e, guests);
    if (sizeErr) fail('invalid-argument', sizeErr, { min: e.minGroupSize ?? 1, max: e.maxGroupSize ?? null });
    const priced = computeBookingPrice(e, guests);
    if (priced.ok === false) fail('failed-precondition', 'experience_price_invalid', { reason: priced.reason });
    let mode: PaymentMode = 'free';
    let link: { type: string; value: string } | null = null;
    let provider: string | null = null;
    if (!priced.free) {
      if (idDocumentStateOf(host) !== 'approved') fail('failed-precondition', 'host_not_verified');
      const choice = choosePaymentMethod(e, data?.paymentMethod);
      if (choice.ok === false) {
        fail(choice.reason === 'no_payment_method' ? 'failed-precondition' : 'invalid-argument', choice.reason, {
          accepted: acceptedPaymentMethods(e),
        });
      }
      mode = (choice as { ok: true; method: PaymentMode }).method;
      if (mode === 'link') {
        const pl = e.paymentLink as Record<string, any>;
        link = { type: String(pl.type), value: String(pl.value).trim() };
      }
      if (mode === 'online') provider = onlineProviderOf(e);
    }

    let s = slot.data() as Record<string, any> | undefined;
    let recurringCap = 0;
    if (recurring) {
      // The time must be one the host's rules generate right now.
      const rules = e.availabilityRules as AvailabilityRules | undefined;
      if (!rules || rulesError(rules)) fail('not-found', 'slot_not_found');
      const at = requestedStart as number;
      const gen = generateSlots(rules, e.availabilityOverrides, at - 60000, at + 60000, now);
      const g = gen.find((x) => x.startMs === at);
      if (!g) fail('failed-precondition', 'slot_closed');
      recurringCap = rules.capacityPerSlot;
      s = { status: 'open', start: ts(g.startMs), end: ts(g.endMs), bookedCount: Number(s?.booked) || 0 };
    }
    if (!s) fail('not-found', 'slot_not_found');
    if (s.status !== 'open') fail('failed-precondition', 'slot_closed');
    const windowStart = msOf(s.start);
    const windowEnd = msOf(s.end);
    if (windowStart === null || windowEnd === null || windowEnd <= windowStart) {
      fail('failed-precondition', 'slot_invalid');
    }
    if (dup.docs.some((d) => d.data()?.experienceId === experienceId)) {
      fail('already-exists', 'already_booked', { bookingId: dup.docs[0].id });
    }
    // Private time slots: one start in the window, for the experience's
    // duration, never overlapping any active booking of this host.
    const lengthMs = bookingLengthMs(e.durationMinutes, windowStart, windowEnd);
    const busySnap = await tx.get(hostBookingsQuery(hostId, windowStart, windowEnd));
    // A recurring slot is shared by its capacity: only OTHER bookings of the
    // host (other experiences / times) make it busy.
    const busyDocs = recurring
      ? busySnap.docs.filter((d) => !(d.data().experienceId === experienceId && d.data().slotId === slotId))
      : busySnap.docs;
    const picked = chooseStart(
      requestedStart, windowStarts(windowStart, windowEnd, lengthMs), lengthMs,
      busyFrom(busyDocs), now,
    );
    if (picked.ok === false) {
      fail(picked.reason === 'time_taken' ? 'resource-exhausted' : 'failed-precondition', picked.reason);
    }
    const start = (picked as { ok: true; start: number }).start;
    const end = start + lengthMs;
    if (Number.isInteger(e.maxGroupSize) && guests > e.maxGroupSize) {
      fail('invalid-argument', 'too_many_guests', { max: e.maxGroupSize });
    }
    // Date-based price (host time zone): day override > weekend > base.
    const dated = resolveDatePrice(e, start);
    const pricedAt = priced.free ? priced : computeBookingPrice(e, guests, start);
    if (pricedAt.ok === false) fail('failed-precondition', 'experience_price_invalid', { reason: pricedAt.reason });
    // bookedCount is informational now (people booked in this window); the
    // party size is bounded by maxGroupSize / maxGuestsPerBooking above.
    const booked = Number(s.bookedCount) || 0;
    const seatsTaken = pricingModeOf(e) === 'per_group' ? 1 : guests;
    if (recurring && booked + seatsTaken > recurringCap) {
      fail('resource-exhausted', 'slot_full', { seatsLeft: Math.max(0, recurringCap - booked) });
    }

    // Request to book is mandatory: the host accepts or declines every booking.
    const requested = true;
    const booking: Record<string, any> = {
      experienceId,
      slotId,
      hostId,
      guestId: uid,
      guests,
      status: requested ? 'requested' : 'confirmed',
      requestToBook: requested,
      policy: policyOf(e),
      experienceTitle: typeof e.title === 'string' ? e.title.slice(0, 120) : null,
      slotStart: ts(start),
      slotEnd: ts(end),
      ...(recurring ? { counterId: slotCounterId(experienceId, start) } : {}),
      price: (pricedAt as { ok: true; price: any }).price,
      priceRule: priced.free ? 'base' : dated.rule,
      pricingMode: pricingModeOf(e),
      maxGroupSize: Number.isInteger(e.maxGroupSize) ? e.maxGroupSize : null,
      payment: {
        mode,
        link,
        guestMarkedPaidAt: null,
        hostConfirmedPaidAt: null,
        ...(mode === 'online'
          ? { provider, status: 'unpaid', orderId: null, ...(provider === 'link' ? { linkMethod: linkMethodOf(e) } : {}) }
          : {}),
      },
      refundDue: null,
      cancellation: null,
      checkIn: null,
      dispute: null,
      consentVersion,
      requestId,
      createdAt: ts(now),
      updatedAt: ts(now),
      ...(requested
        ? { requestExpiresAt: ts(requestExpiresAtMs(now, start, cfg)) }
        : {
          confirmedAt: ts(now),
          reminderAt: ts(reminderAtMs(start, cfg)),
          completeAt: ts(completeAtMs(end, cfg)),
        }),
    };
    tx.set(bookingRef, booking);
    // per_group slots count GROUPS, per_person slots count people.
    if (recurring) {
      tx.set(slotRef, {
        experienceId, startMs: start, endMs: end, capacity: recurringCap,
        booked: booked + seatsTaken, updatedAt: ts(now),
      }, { merge: true });
    } else {
      tx.update(slotRef, { bookedCount: booked + seatsTaken, updatedAt: ts(now) });
    }
    tx.set(lockRef, { lastBookingId: bookingId, updatedAt: ts(now) }, { merge: true });
    return { created: true, booking };
  });

  const b = result.booking;
  if (result.created) {
    const actor = await safeActor(uid);
    const d = notifData(bookingId, b);
    if (b.status === 'requested') {
      await safeNotify({ recipientId: hostId, type: 'booking_request', title: 'requested to book your experience', body: title(b), data: d, actor });
    } else {
      await safeNotify({ recipientId: hostId, type: 'booking_new', title: 'booked your experience', body: title(b), data: d, actor });
      await safeNotify({
        recipientId: uid, type: 'booking_confirmed', title: 'Booking confirmed',
        body: payHint(b),
        data: d,
      });
    }
  }
  return { ...bookingView(bookingId, b), alreadyExisted: !result.created };
}

// ─────────────────────────────────────────────────────────── host responds

export async function respondToBookingRequest(uid: string, data: any): Promise<Record<string, unknown>> {
  const bookingId = requireBookingId(data);
  if (typeof data?.accept !== 'boolean') fail('invalid-argument', 'accept_required');
  const accept: boolean = data.accept;
  const cfg = await loadConfig();
  // Requests made before private time slots may overlap a confirmed booking:
  // the host cannot accept two people for the same time.
  let confirmedBusy: Array<[number, number]> = [];
  if (accept) {
    const pre = (await fdb().collection(BOOKINGS).doc(bookingId).get()).data();
    const ps = msOf(pre?.slotStart);
    const pe = msOf(pre?.slotEnd);
    if (pre && pre.hostId === uid && ps !== null && pe !== null) {
      const snap = await hostBookingsQuery(uid, ps, pe).get();
      confirmedBusy = busyFrom(snap.docs.filter((d) => d.data().status === 'confirmed'), bookingId);
    }
  }
  const r = await transition(bookingId, (b, now) => {
    if (uid !== b.hostId) fail('permission-denied', 'not_host');
    if (accept && b.status === 'confirmed') return { noop: true };
    if (!accept && b.status === 'declined') return { noop: true };
    if (b.status !== 'requested') fail('failed-precondition', 'not_pending', { status: b.status });
    const expires = msOf(b.requestExpiresAt);
    if (expires !== null && now >= expires) fail('failed-precondition', 'request_expired');
    if (!accept) return { to: 'declined', patch: { requestExpiresAt: del(), respondedAt: ts(now) } };
    const start = msOf(b.slotStart) as number;
    const end = msOf(b.slotEnd) as number;
    if (start <= now) fail('failed-precondition', 'slot_started');
    if (overlapsAny(start, end, confirmedBusy)) fail('failed-precondition', 'time_taken');
    return {
      to: 'confirmed',
      patch: {
        requestExpiresAt: del(),
        respondedAt: ts(now),
        confirmedAt: ts(now),
        reminderAt: ts(reminderAtMs(start, cfg)),
        completeAt: ts(completeAtMs(end, cfg)),
      },
    };
  }, cfg);
  if (!r.noop) {
    const actor = await safeActor(uid);
    await safeNotify({
      recipientId: r.after.guestId,
      type: accept ? 'booking_accepted' : 'booking_declined',
      title: accept ? 'accepted your booking request' : 'declined your booking request',
      body: accept ? payHint(r.after) : title(r.after),
      data: notifData(bookingId, r.after),
      actor,
    });
  }
  return bookingView(bookingId, r.after);
}

// ─────────────────────────────────────────────────────────── cancel

export async function cancelBooking(uid: string, data: any): Promise<Record<string, unknown>> {
  const bookingId = requireBookingId(data);
  const reason = cleanText(data?.reason, 500);
  const cfg = await loadConfig();
  const r = await transition(bookingId, (b, now) => {
    const by = roleOf(uid, b);
    if (!by) fail('permission-denied', 'not_a_party');
    if (b.status === `cancelled_by_${by}`) return { noop: true };
    if (b.status !== 'requested' && b.status !== 'confirmed') {
      fail('failed-precondition', 'not_cancellable', { status: b.status });
    }
    const start = msOf(b.slotStart) as number;
    if (now >= start) fail('failed-precondition', 'already_started');
    const wasConfirmed = b.status === 'confirmed';
    const percent = wasConfirmed
      // Every booking is a request: the guest's booking (and its 24 h grace
      // window) starts when the host CONFIRMS it, not when it was requested.
      ? refundFor(b.policy, now, start, msOf(b.confirmedAt) ?? msOf(b.createdAt) ?? now, by)
      : 100;
    const due = wasConfirmed
      ? refundDueFor(b.price, b.payment, percent, by === 'host' ? 'host_cancelled' : 'guest_cancelled')
      : null;
    return {
      to: by === 'host' ? 'cancelled_by_host' : 'cancelled_by_guest',
      patch: {
        cancellation: { by, at: ts(now), reason },
        refundDue: due ? { ...due, decidedAt: ts(now) } : null,
        reminderAt: del(),
        completeAt: del(),
        requestExpiresAt: del(),
      },
      hostPenalty: by === 'host' && wasConfirmed,
    };
  }, cfg);
  if (!r.noop) {
    const by = roleOf(uid, r.before) as CancelledBy;
    const other = by === 'guest' ? r.before.hostId : r.before.guestId;
    const actor = await safeActor(uid);
    await safeNotify({
      recipientId: other,
      type: 'booking_cancelled',
      title: by === 'guest' ? 'cancelled their booking' : 'cancelled your booking',
      body: r.after.refundDue && r.after.refundDue.amount > 0
        ? `${title(r.after)} — refund owed: ${r.after.refundDue.percent}%.`
        : title(r.after),
      data: notifData(bookingId, r.after),
      actor,
    });
    await flaggedHostFollowUp(r, r.before.hostId);
  }
  return bookingView(bookingId, r.after);
}

// ─────────────────────────────────────────────────────────── check-in

export async function getBookingCheckInCode(uid: string, data: any): Promise<Record<string, unknown>> {
  const bookingId = requireBookingId(data);
  const snap = await fdb().collection(BOOKINGS).doc(bookingId).get();
  if (!snap.exists) fail('not-found', 'booking_not_found');
  const b = snap.data() as Record<string, any>;
  if (b.guestId !== uid) fail('permission-denied', 'not_guest');
  if (b.status !== 'confirmed') fail('failed-precondition', 'not_confirmed', { status: b.status });
  // No QR before the money arrived: in-app payments need the provider's
  // confirmation (webhook -> payment.status 'paid'); a link payment needs the
  // host's "received". Cash is paid at the door (the host confirms there).
  const mode = b.payment?.mode;
  if (mode === 'online') {
    if (b.payment?.status !== 'paid' || !b.payment?.orderId) fail('failed-precondition', 'not_paid', { status: b.payment?.status ?? null });
    const ids: string[] = Array.isArray(b.payment.ticketIds) && b.payment.ticketIds.length
      ? b.payment.ticketIds : [`${b.payment.orderId}_1`];
    const snaps = await Promise.all(ids.map((id) => fdb().collection('tickets').doc(id).get()));
    const tickets = snaps.map((s) => s.data()).filter((t) => t && t.status === 'valid') as Array<Record<string, any>>;
    if (!tickets.length) fail('failed-precondition', 'ticket_not_valid');
    return {
      bookingId, code: null, qrPayload: tickets[0].qrPayload, ticketId: tickets[0].ticketId,
      tickets: tickets.map((t) => ({ ticketId: t.ticketId, qrPayload: t.qrPayload, partySize: t.partySize ?? 1, checkedIn: !!t.checkedInAt })),
    };
  }
  if (mode === 'link' && !b.payment?.hostConfirmedPaidAt) fail('failed-precondition', 'not_paid');
  const code = checkInCode(await checkInSecret(), bookingId);
  return { bookingId, code, qrPayload: checkInQrPayload(bookingId, code) };
}

/** Most helpers a host may authorise to scan their experience's guests in. */
export const MAX_EXPERIENCE_SCANNERS = 10;

/**
 * Host, or a helper the host authorised on the experience
 * (`user_experiences/{id}.allowedScannerIds`), may check guests in.
 */
async function canScanExperience(uid: string, experienceId: string, hostId: string): Promise<boolean> {
  if (uid === hostId) return true;
  const exp = await fdb().collection(EXPERIENCES).doc(experienceId).get();
  const ids: unknown = exp.data()?.allowedScannerIds;
  return Array.isArray(ids) && ids.includes(uid);
}

/**
 * Host or helper at the door. data: { bookingId, code, experienceId?, cashReceived? }.
 * `experienceId` (the experience the door scanner has open) rejects a valid
 * code that belongs to another experience. A new check-in also records that
 * host and guest met in person (checkin/meetings.ts).
 */
export async function checkInBooking(uid: string, data: any): Promise<Record<string, unknown>> {
  const bookingId = requireBookingId(data);
  const cashReceived = data?.cashReceived === true;
  const cfg = await loadConfig();
  const secret = await checkInSecret();
  const pre = await fdb().collection(BOOKINGS).doc(bookingId).get();
  if (!pre.exists) fail('not-found', 'booking_not_found');
  const pb = pre.data() as Record<string, any>;
  const openExperienceId = typeof data?.experienceId === 'string' ? data.experienceId : null;
  if (openExperienceId && openExperienceId !== pb.experienceId) fail('failed-precondition', 'wrong_experience');
  const allowed = await canScanExperience(uid, pb.experienceId, pb.hostId);
  const r = await transition(bookingId, (b, now) => {
    if (!allowed || b.hostId !== pb.hostId) fail('permission-denied', 'not_host');
    // Only the host can confirm cash; a helper just opens the door.
    const cashByHost = cashReceived && uid === b.hostId;
    const wantsCash = cashByHost && b.payment?.mode === 'cash' && !b.payment?.hostConfirmedPaidAt;
    // The code first: a forged code learns nothing, not even "already in".
    if (!verifyCheckInCode(secret, bookingId, data?.code)) fail('permission-denied', 'invalid_code');
    if (b.status === 'confirmed' && b.checkIn && !wantsCash) return { noop: true };
    if (b.status !== 'confirmed') fail('failed-precondition', 'not_confirmed', { status: b.status });
    // Re-checked at every scan: a refunded / disputed in-app payment is refused.
    if (b.payment?.mode === 'online' && b.payment?.status !== 'paid') {
      fail('permission-denied', 'ticket_not_valid', { status: b.payment?.status ?? null });
    }
    if (!inCheckInWindow(now, msOf(b.slotStart) as number, msOf(b.slotEnd) as number, cfg)) {
      fail('failed-precondition', 'outside_checkin_window');
    }
    return {
      patch: {
        checkIn: b.checkIn ?? { at: ts(now), byUid: uid },
        ...(wantsCash ? { payment: { ...b.payment, hostConfirmedPaidAt: ts(now) } } : {}),
      },
      extra: b.checkIn ? undefined : (tx, after) => eligibilityWrite(tx, after, bookingId, now, cfg),
    };
  }, cfg);
  if (!r.noop && !r.before.checkIn) {
    await recordMeeting(r.after.hostId, r.after.guestId, {
      type: 'experience', contextId: bookingId, title: title(r.after), verified: true, byUid: uid,
    }, fdb());
    await safeNotify({
      recipientId: r.after.guestId, type: 'booking_checked_in', title: 'You are checked in',
      body: title(r.after), data: notifData(bookingId, r.after),
    });
  }
  let guestName = '';
  let guestPhotoUrl: string | null = null;
  try {
    const gp = (await fdb().collection('profiles').doc(r.after.guestId).get()).data() ?? {};
    guestName = String(gp.displayName ?? gp.nickname ?? '');
    const photos: unknown = gp.photoUrls;
    guestPhotoUrl = Array.isArray(photos) && typeof photos[0] === 'string' ? photos[0] : null;
  } catch {
    // The name is a convenience for the door screen, never a reason to fail.
  }
  return {
    ...bookingView(bookingId, r.after),
    alreadyCheckedIn: !!r.before.checkIn,
    guestName,
    guestPhotoUrl,
  };
}

/**
 * Host removed bookable times (updateExperienceAvailability with confirm):
 * every active booking at those starts is cancelled by the host (100 %
 * refund owed, no host penalty: it was announced through the schedule),
 * the guest is notified, and in-app payments are refunded / marked owed.
 */
export async function cancelBookingsAtRemovedTimes(hostId: string, experienceId: string, startsMs: number[]): Promise<number> {
  const cfg = await loadConfig();
  let n = 0;
  for (const start of startsMs.slice(0, 200)) {
    const q = await fdb().collection(BOOKINGS)
      .where('experienceId', '==', experienceId)
      .where('slotStart', '==', ts(start))
      .limit(100)
      .get();
    for (const d of q.docs) {
      const b0 = d.data();
      if (b0.hostId !== hostId || (b0.status !== 'requested' && b0.status !== 'confirmed')) continue;
      const r = await transition(d.id, (b, now) => {
        if (b.status !== 'requested' && b.status !== 'confirmed') return { noop: true };
        const due = b.status === 'confirmed'
          ? refundDueFor(b.price, b.payment, 100, 'host_removed_time')
          : null;
        return {
          to: 'cancelled_by_host',
          patch: {
            cancellation: { by: 'host', at: ts(now), reason: 'host_removed_time' },
            refundDue: due ? { ...due, decidedAt: ts(now) } : null,
            reminderAt: del(), completeAt: del(), requestExpiresAt: del(),
          },
        };
      }, cfg);
      if (r.noop) continue;
      n++;
      const orderId = r.after.payment?.orderId;
      if (orderId) await requestOrderRefund(String(orderId), 'host_removed_time').catch(() => undefined);
      await safeNotify({
        recipientId: r.after.guestId, type: 'booking_cancelled', title: 'Your booking was cancelled by the host',
        body: `${title(r.after)} — the time is no longer available. Any payment is refunded.`,
        data: notifData(d.id, r.after),
      });
    }
  }
  return n;
}

/** Door: a paid ticket (verified by checkin/eventCheckin.checkInPaidTicket). */
export async function checkInBookingWithTicket(
  uid: string,
  ticket: Record<string, any>,
  experienceId: string | null,
): Promise<Record<string, unknown>> {
  const bookingId = ticket.bookingId;
  if (!isDocId(bookingId)) fail('permission-denied', 'invalid_code');
  const pre = (await fdb().collection(BOOKINGS).doc(bookingId).get()).data();
  if (!pre) fail('not-found', 'booking_not_found');
  if (!(await canScanExperience(uid, pre.experienceId, pre.hostId))) fail('permission-denied', 'not_host');
  if (ticket.status !== 'valid') fail('permission-denied', 'ticket_not_valid', { status: ticket.status });
  const code = checkInCode(await checkInSecret(), bookingId);
  return checkInBooking(uid, { bookingId, code, experienceId: experienceId ?? undefined });
}

// ─────────────────────────────────────────────────────────── no-show

export async function markNoShow(uid: string, data: any): Promise<Record<string, unknown>> {
  const bookingId = requireBookingId(data);
  const cfg = await loadConfig();
  const r = await transition(bookingId, (b, now) => {
    if (uid !== b.hostId) fail('permission-denied', 'not_host');
    if (b.status === 'no_show') return { noop: true };
    if (b.status !== 'confirmed') fail('failed-precondition', 'not_confirmed', { status: b.status });
    if (b.checkIn) fail('failed-precondition', 'guest_checked_in');
    if (!canMarkNoShow(now, msOf(b.slotStart) as number, cfg)) fail('failed-precondition', 'too_early');
    // A guest no-show is a late cancellation: the policy's 0% band.
    const due = refundDueFor(b.price, b.payment, 0, 'guest_no_show');
    return {
      to: 'no_show',
      patch: {
        noShowAt: ts(now),
        refundDue: due ? { ...due, decidedAt: ts(now) } : null,
        reminderAt: del(),
        completeAt: del(),
      },
    };
  }, cfg);
  if (!r.noop) {
    const actor = await safeActor(uid);
    await safeNotify({
      recipientId: r.after.guestId, type: 'booking_no_show', title: 'marked you as a no-show',
      body: `${title(r.after)} — you can contest this within ${cfg.disputeWindowHours} h of the end.`,
      data: notifData(bookingId, r.after), actor,
    });
  }
  return bookingView(bookingId, r.after);
}

// ─────────────────────────────────────────────────────────── paid marks

const PAYABLE_STATUSES = ['confirmed', 'completed', 'no_show', 'disputed', 'resolved'];

/**
 * Off-platform payment confirmations (informational, never money):
 *   guest, mode link  -> payment.guestMarkedPaidAt   ("I paid via the link")
 *   host,  mode link  -> payment.hostConfirmedPaidAt ("I received it")
 *   host,  mode cash  -> payment.hostConfirmedPaidAt, only at / after check-in
 *                        (or once the slot started). Also: checkInBooking
 *                        {cashReceived: true}, confirmCashReceived.
 * A guest cannot mark cash as paid (only the host can confirm receiving it).
 */
export async function markBookingPaid(uid: string, data: any, onlyMode?: 'cash'): Promise<Record<string, unknown>> {
  const bookingId = requireBookingId(data);
  const cfg = await loadConfig();
  const r = await transition(bookingId, (b, now) => {
    const role = roleOf(uid, b);
    if (!role) fail('permission-denied', 'not_a_party');
    const mode = b.payment?.mode;
    if (onlyMode && mode !== onlyMode) fail('failed-precondition', 'not_cash_payment');
    // In-app payments are confirmed ONLY by the provider webhook.
    if (mode === 'online') fail('failed-precondition', 'paid_in_app');
    if (mode !== 'link' && mode !== 'cash') fail('failed-precondition', 'not_paid_booking');
    if (mode === 'cash' && role !== 'host') fail('permission-denied', 'host_confirms_cash');
    if (!PAYABLE_STATUSES.includes(b.status)) fail('failed-precondition', 'not_confirmed', { status: b.status });
    if (mode === 'cash' && !b.checkIn && now < (msOf(b.slotStart) ?? Infinity)) {
      fail('failed-precondition', 'cash_before_meeting');
    }
    const field = role === 'guest' ? 'guestMarkedPaidAt' : 'hostConfirmedPaidAt';
    if (b.payment?.[field]) return { noop: true };
    return { patch: { payment: { ...b.payment, [field]: ts(now) } } };
  }, cfg);
  if (!r.noop) {
    const guestSide = uid === r.before.guestId;
    const actor = await safeActor(uid);
    await safeNotify({
      recipientId: guestSide ? r.before.hostId : r.before.guestId,
      type: guestSide ? 'booking_payment_marked' : 'booking_payment_confirmed',
      title: guestSide ? 'says they paid for their booking' : 'confirmed your payment',
      body: title(r.after), data: notifData(bookingId, r.after), actor,
    });
  }
  return bookingView(bookingId, r.after);
}

/** Host: "I received the cash" (mode cash only). */
export function confirmCashReceived(uid: string, data: any): Promise<Record<string, unknown>> {
  return markBookingPaid(uid, data, 'cash');
}

// ─────────────────────────────────────────────────────────── disputes

async function removeReviewEligibility(b: Record<string, any>, bookingId: string): Promise<void> {
  const expRef = fdb().collection(EXPERIENCES).doc(b.experienceId);
  try {
    const [elig, pending] = await Promise.all([
      expRef.collection(REVIEW_ELIGIBILITY).doc(b.guestId).get(),
      expRef.collection(PENDING_REVIEWS).doc(b.guestId).get(),
    ]);
    if (elig.exists && elig.data()?.bookingId === bookingId) await elig.ref.delete();
    if (pending.exists && pending.data()?.bookingId === bookingId) await pending.ref.delete();
  } catch (e) {
    console.error(`[bookings] eligibility cleanup ${bookingId} failed:`, e);
  }
}

export async function openBookingDispute(uid: string, data: any): Promise<Record<string, unknown>> {
  const bookingId = requireBookingId(data);
  const reason = cleanText(data?.reason, 1000);
  if (!reason || reason.length < 10) fail('invalid-argument', 'reason_required');
  const cfg = await loadConfig();
  const r = await transition(bookingId, (b, now) => {
    if (uid !== b.guestId) fail('permission-denied', 'not_guest');
    if (b.status === 'disputed') return { noop: true };
    if (b.status !== 'confirmed' && b.status !== 'no_show') {
      fail('failed-precondition', 'not_disputable', { status: b.status });
    }
    if (!inDisputeWindow(now, msOf(b.slotStart) as number, msOf(b.slotEnd) as number, cfg)) {
      fail('failed-precondition', 'outside_dispute_window');
    }
    return {
      to: 'disputed',
      patch: {
        dispute: { openedAt: ts(now), byUid: uid, reason, status: 'open', resolution: null, fromStatus: b.status },
        reminderAt: del(),
        completeAt: del(),
      },
    };
  }, cfg);
  if (!r.noop) {
    await removeReviewEligibility(r.after, bookingId);
    const actor = await safeActor(uid);
    await safeNotify({
      recipientId: r.after.hostId, type: 'booking_dispute', title: 'reported a problem with their booking',
      body: title(r.after), data: notifData(bookingId, r.after), actor,
    });
    await notifyAdmins('admin_booking_dispute', 'Booking dispute opened', `${title(r.after)} — booking ${bookingId}`, {
      action: 'admin_booking_dispute', bookingId,
    });
  }
  return bookingView(bookingId, r.after);
}

export async function resolveBookingDispute(uid: string, data: any): Promise<Record<string, unknown>> {
  const bookingId = requireBookingId(data);
  if (!(await isAdminUid(uid))) fail('permission-denied', 'admin_only');
  const refundPercent = data?.refundPercent;
  if (!Number.isInteger(refundPercent) || refundPercent < 0 || refundPercent > 100) {
    fail('invalid-argument', 'invalid_refund_percent');
  }
  const hostAction: HostAction = data?.hostAction ?? 'none';
  if (!(HOST_ACTIONS as readonly string[]).includes(hostAction)) fail('invalid-argument', 'invalid_host_action');
  const note = cleanText(data?.note, 1000);
  const cfg = await loadConfig();
  const r = await transition(bookingId, (b, now) => {
    if (b.status === 'resolved') return { noop: true };
    if (b.status !== 'disputed') fail('failed-precondition', 'not_disputed', { status: b.status });
    const due = refundPercent > 0
      ? refundDueFor(b.price, b.payment, refundPercent, 'dispute_resolution')
      : null;
    return {
      to: 'resolved',
      patch: {
        dispute: {
          ...(b.dispute || {}),
          status: 'resolved',
          resolution: { refundPercent, hostAction, note, byUid: uid, at: ts(now) },
        },
        refundDue: due ? { ...due, decidedAt: ts(now) } : (b.refundDue ?? null),
      },
    };
  }, cfg);
  if (!r.noop) {
    const b = r.after;
    const now = nowMs();
    try {
      if (hostAction === 'hide_listing') {
        const expRef = fdb().collection(EXPERIENCES).doc(b.experienceId);
        const exp = await expRef.get();
        if (exp.exists && exp.data()?.status !== 'hidden') {
          await expRef.update({
            status: 'hidden',
            moderation: {
              auto: false, reason: 'booking_dispute', bookingId,
              previousStatus: exp.data()?.status === 'published' ? 'published' : 'draft',
            },
          });
        }
      } else if (hostAction === 'suspend_hosting') {
        await fdb().collection(HOST_SUSPENSIONS).doc(b.hostId).set({
          hostId: b.hostId, active: true, reason: 'booking_dispute', bookingId, byUid: uid, createdAt: ts(now),
        }, { merge: true });
      }
    } catch (e) {
      console.error(`[bookings] host action ${hostAction} for ${bookingId} failed:`, e);
    }
    const d = notifData(bookingId, b);
    const due = b.refundDue && b.refundDue.amount > 0 ? ` Refund owed: ${b.refundDue.percent}%.` : '';
    await safeNotify({ recipientId: b.guestId, type: 'booking_dispute_resolved', title: 'Your report was reviewed', body: `${title(b)}.${due}`, data: d });
    await safeNotify({
      recipientId: b.hostId,
      type: hostAction === 'warn' ? 'booking_host_warning' : 'booking_dispute_resolved',
      title: hostAction === 'warn' ? 'Warning about one of your bookings' : 'A booking report was reviewed',
      body: `${title(b)}.${due}`, data: d,
    });
  }
  return bookingView(bookingId, r.after);
}

// ─────────────────────────────────────────────────────────── slot cancel

/**
 * Host cancels a whole slot: the slot becomes 'cancelled' and every active
 * booking on it becomes cancelled_by_host (100% owed back). Counts ONE host
 * cancellation when any confirmed booking was affected. Re-callable: a slot
 * already cancelled finishes any booking still active (pages of 400).
 */
export async function cancelSlot(uid: string, data: any): Promise<Record<string, unknown>> {
  const { experienceId, slotId } = data || {};
  if (!isDocId(experienceId)) fail('invalid-argument', 'invalid_experience_id');
  if (!isDocId(slotId)) fail('invalid-argument', 'invalid_slot_id');
  const reason = cleanText(data?.reason, 500);
  const cfg = await loadConfig();
  const db = fdb();
  const expRef = db.collection(EXPERIENCES).doc(experienceId);
  const slotRef = expRef.collection(SLOTS).doc(slotId);
  const PAGE = 400;

  const res = await db.runTransaction(async (tx) => {
    const q = db.collection(BOOKINGS)
      .where('experienceId', '==', experienceId)
      .where('slotId', '==', slotId)
      .where('status', 'in', ACTIVE_STATUSES as unknown as string[])
      .limit(PAGE);
    const [exp, slot, active] = await Promise.all([tx.get(expRef), tx.get(slotRef), tx.get(q)]);
    if (!exp.exists) fail('not-found', 'experience_not_found');
    if (exp.data()?.hostId !== uid) fail('permission-denied', 'not_host');
    if (!slot.exists) fail('not-found', 'slot_not_found');
    const now = nowMs();
    const docs = active.docs;
    const anyConfirmed = docs.some((d) => d.data()?.status === 'confirmed');
    const statsSnap = anyConfirmed ? await tx.get(db.collection(HOST_CANCEL_STATS).doc(uid)) : null;

    let released = 0;
    const cancelled: Array<{ id: string; b: Record<string, any> }> = [];
    for (const d of docs) {
      const b = d.data() as Record<string, any>;
      if (!canTransition(b.status, 'cancelled_by_host')) continue;
      const due = b.status === 'confirmed'
        ? refundDueFor(b.price, b.payment, 100, 'host_cancelled')
        : null;
      released += seatsReleased(b.status, 'cancelled_by_host', Number(b.guests) || 0);
      const patch = {
        status: 'cancelled_by_host',
        cancellation: { by: 'host', at: ts(now), reason: reason ?? 'slot_cancelled' },
        refundDue: due ? { ...due, decidedAt: ts(now) } : null,
        reminderAt: del(), completeAt: del(), requestExpiresAt: del(),
        updatedAt: ts(now),
      };
      tx.update(d.ref, patch);
      cancelled.push({ id: d.id, b: { ...b, status: 'cancelled_by_host' } });
    }
    const booked = Number(slot.data()?.bookedCount) || 0;
    tx.update(slotRef, { status: 'cancelled', bookedCount: Math.max(0, booked - released), updatedAt: ts(now) });
    let hostFlagged = false;
    if (statsSnap) {
      hostFlagged = writeHostPenalty(tx, uid, statsSnap, now, cfg, {
        lastExperienceId: experienceId, lastSlotId: slotId,
      });
    }
    return { cancelled, hostFlagged, more: docs.length >= PAGE };
  });

  const actor = await safeActor(uid);
  await Promise.all(res.cancelled.map(({ id, b }) => safeNotify({
    recipientId: b.guestId, type: 'booking_cancelled', title: 'cancelled your booking',
    body: title(b),
    data: notifData(id, b), actor,
  })));
  await flaggedHostFollowUp(res, uid);
  return { experienceId, slotId, cancelledBookings: res.cancelled.length, more: res.more };
}

// ─────────────────────────────────────────────────────────── experience deleted

/**
 * A deleted experience: future active bookings become cancelled_by_host (one
 * host cancellation counted when any was confirmed); the slots, review
 * eligibility markers and unrevealed pending reviews are deleted.
 */
export async function onExperienceDeleted(experienceId: string, hostId: string | null): Promise<number> {
  const db = fdb();
  const cfg = await loadConfig();
  const now = nowMs();
  let cancelledCount = 0;
  let anyConfirmed = false;
  const toNotify: Array<{ id: string; b: Record<string, any> }> = [];
  for (let guard = 0; guard < 50; guard++) {
    const page = await db.collection(BOOKINGS)
      .where('experienceId', '==', experienceId)
      .where('status', 'in', ACTIVE_STATUSES as unknown as string[])
      .limit(300)
      .get();
    const future = page.docs.filter((d) => (msOf(d.data()?.slotStart) ?? 0) > now);
    if (future.length === 0) break;
    const batch = db.batch();
    for (const d of future) {
      const b = d.data() as Record<string, any>;
      if (b.status === 'confirmed') anyConfirmed = true;
      const due = b.status === 'confirmed' ? refundDueFor(b.price, b.payment, 100, 'experience_deleted') : null;
      batch.update(d.ref, {
        status: 'cancelled_by_host',
        cancellation: { by: 'host', at: ts(now), reason: 'experience_deleted' },
        refundDue: due ? { ...due, decidedAt: ts(now) } : null,
        reminderAt: del(), completeAt: del(), requestExpiresAt: del(),
        updatedAt: ts(now),
      });
      toNotify.push({ id: d.id, b });
    }
    await batch.commit();
    cancelledCount += future.length;
    if (page.docs.length < 300) break;
  }
  if (anyConfirmed && hostId) {
    const r = await db.runTransaction(async (tx) => {
      const stats = await tx.get(db.collection(HOST_CANCEL_STATS).doc(hostId));
      return { hostFlagged: writeHostPenalty(tx, hostId, stats, now, cfg, { lastExperienceId: experienceId }) };
    });
    await flaggedHostFollowUp(r, hostId);
  }
  await Promise.all(toNotify.map(({ id, b }) => safeNotify({
    recipientId: b.guestId, type: 'booking_cancelled', title: 'Your booking was cancelled',
    body: `${title(b)} is no longer available.`, data: notifData(id, b),
  })));
  const expRef = db.collection(EXPERIENCES).doc(experienceId);
  for (const sub of [SLOTS, REVIEW_ELIGIBILITY, PENDING_REVIEWS]) {
    try {
      await db.recursiveDelete(expRef.collection(sub));
    } catch (e) {
      console.error(`[bookings] cleanup ${experienceId}/${sub} failed:`, e);
    }
  }
  return cancelledCount;
}

// ─────────────────────────────────────────────────────────── scheduled sweeps

const SWEEP_PAGE = 200;
const SWEEP_BUDGET_MS = 240_000;

/**
 * Pages a "due" query until it returns nothing new or the time budget ends.
 * Each handled doc must leave the query (status or due field changes), so
 * re-querying from the top is correct; ids that failed are skipped.
 */
async function sweep(
  query: () => FirebaseFirestore.Query,
  handle: (doc: FirebaseFirestore.QueryDocumentSnapshot) => Promise<void>,
  label: string,
): Promise<number> {
  const started = Date.now();
  const seen = new Set<string>();
  let handled = 0;
  while (Date.now() - started < SWEEP_BUDGET_MS) {
    const page = await query().limit(SWEEP_PAGE).get();
    const fresh = page.docs.filter((d) => !seen.has(d.id));
    if (fresh.length === 0) break;
    for (const d of fresh) {
      seen.add(d.id);
      try {
        await handle(d);
        handled++;
      } catch (e) {
        console.error(`[bookings] ${label} ${d.id} failed:`, e);
      }
    }
    if (page.docs.length < SWEEP_PAGE) break;
  }
  if (handled) console.log(`[bookings] ${label}: ${handled}`);
  return handled;
}

/** Confirmed bookings 24 h before the start: remind guest and host (once). */
export async function sendDueReminders(): Promise<number> {
  const db = fdb();
  return sweep(
    () => db.collection(BOOKINGS)
      .where('status', '==', 'confirmed')
      .where('reminderAt', '<=', ts(nowMs()))
      .orderBy('reminderAt'),
    async (d) => {
      const ref = d.ref;
      const out = await db.runTransaction(async (tx) => {
        const s = await tx.get(ref);
        const b = s.data() as Record<string, any> | undefined;
        const at = msOf(b?.reminderAt);
        if (!b || b.status !== 'confirmed' || at === null || at > nowMs()) return null;
        tx.update(ref, { reminderAt: del(), reminderSentAt: ts(nowMs()) });
        return (msOf(b.slotStart) ?? 0) > nowMs() ? b : null;
      });
      if (!out) return;
      const data = notifData(d.id, out);
      await safeNotify({ recipientId: out.guestId, type: 'booking_reminder', title: 'Your experience is coming up', body: title(out), data });
      await safeNotify({ recipientId: out.hostId, type: 'booking_reminder_host', title: 'You are hosting soon', body: title(out), data });
    },
    'reminders',
  );
}

/** Requests the host never answered (48 h or the start): expired, seats freed. */
export async function expireDueRequests(): Promise<number> {
  const db = fdb();
  const cfg = await loadConfig();
  return sweep(
    () => db.collection(BOOKINGS)
      .where('status', '==', 'requested')
      .where('requestExpiresAt', '<=', ts(nowMs()))
      .orderBy('requestExpiresAt'),
    async (d) => {
      const r = await transition(d.id, (b, now) => {
        const at = msOf(b.requestExpiresAt);
        if (b.status !== 'requested' || at === null || at > now) return { noop: true };
        return { to: 'expired', patch: { requestExpiresAt: del(), expiredAt: ts(now) } };
      }, cfg);
      if (r.noop) return;
      await safeNotify({
        recipientId: r.after.guestId, type: 'booking_expired', title: 'Your booking request expired',
        body: `${title(r.after)} — the host did not answer in time.`, data: notifData(d.id, r.after),
      });
    },
    'expire-requests',
  );
}

/** Confirmed bookings past end + dispute window: completed; reviews unlocked. */
export async function completeDueBookings(): Promise<number> {
  const db = fdb();
  const cfg = await loadConfig();
  return sweep(
    () => db.collection(BOOKINGS)
      .where('status', '==', 'confirmed')
      .where('completeAt', '<=', ts(nowMs()))
      .orderBy('completeAt'),
    async (d) => {
      const r = await transition(d.id, (b, now) => {
        const at = msOf(b.completeAt);
        if (b.status !== 'confirmed' || at === null || at > now) return { noop: true };
        return {
          to: 'completed',
          patch: { completeAt: del(), reminderAt: del(), completedAt: ts(now) },
          extra: (tx, after) => eligibilityWrite(tx, after, d.id, now, cfg),
        };
      }, cfg);
      if (r.noop) return;
      const data = notifData(d.id, r.after);
      await safeNotify({ recipientId: r.after.guestId, type: 'booking_review_prompt', title: 'How was your experience?', body: `Review ${title(r.after)}`, data });
      await safeNotify({ recipientId: r.after.hostId, type: 'booking_review_guest_prompt', title: 'Review your guest', body: title(r.after), data });
    },
    'complete',
  );
}
