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

import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { HttpsError, FunctionsErrorCode } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { tierDateFromValue } from '../shared/effectiveTier';
import { emitNotification, resolveActor, Actor } from '../notifications/notifyHelpers';
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

/** Admin = admin-panel user (admin_users/{uid}) or legacy users.role == 'admin'. */
export async function isAdminUid(uid: string): Promise<boolean> {
  const [a, u] = await Promise.all([
    fdb().collection('admin_users').doc(uid).get(),
    fdb().collection('users').doc(uid).get(),
  ]);
  return a.exists || u.data()?.role === 'admin';
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
    const release = plan.to ? seatsReleased(b.status, plan.to, Number(b.guests) || 0) : 0;
    const slotRef = db.collection(EXPERIENCES).doc(b.experienceId).collection(SLOTS).doc(b.slotId);
    const statsRef = db.collection(HOST_CANCEL_STATS).doc(b.hostId);
    // All reads before any write.
    const slotSnap = release > 0 ? await tx.get(slotRef) : null;
    const statsSnap = plan.hostPenalty ? await tx.get(statsRef) : null;

    const after = { ...b, ...(plan.patch || {}), ...(plan.to ? { status: plan.to } : {}), updatedAt: ts(now) };
    tx.update(ref, { ...(plan.patch || {}), ...(plan.to ? { status: plan.to } : {}), updatedAt: ts(now) });
    if (slotSnap?.exists) {
      const booked = Number(slotSnap.data()?.bookedCount) || 0;
      tx.update(slotRef, { bookedCount: Math.max(0, booked - release), updatedAt: ts(now) });
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

export async function createBooking(uid: string, data: any): Promise<Record<string, unknown>> {
  const { experienceId, slotId, guests, requestId } = data || {};
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
  const slotRef = expRef.collection(SLOTS).doc(slotId);

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
    const [existing, exp, slot, guestP, hostP, susp, dup] = await Promise.all([
      tx.get(bookingRef), tx.get(expRef), tx.get(slotRef),
      tx.get(db.collection('profiles').doc(uid)),
      tx.get(db.collection('profiles').doc(hostId)),
      tx.get(db.collection(HOST_SUSPENSIONS).doc(hostId)),
      tx.get(dupQ),
    ]);
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

    const priced = computeBookingPrice(e, guests);
    if (priced.ok === false) fail('failed-precondition', 'experience_price_invalid', { reason: priced.reason });
    let mode: PaymentMode = 'free';
    let link: { type: string; value: string } | null = null;
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
    }

    const s = slot.data() as Record<string, any> | undefined;
    if (!s) fail('not-found', 'slot_not_found');
    if (s.status !== 'open') fail('failed-precondition', 'slot_closed');
    const start = msOf(s.start);
    const end = msOf(s.end);
    if (start === null || end === null || end <= start) fail('failed-precondition', 'slot_invalid');
    if (start <= now) fail('failed-precondition', 'slot_started');
    if (Number.isInteger(e.maxGroupSize) && guests > e.maxGroupSize) {
      fail('invalid-argument', 'too_many_guests', { max: e.maxGroupSize });
    }
    if (dup.docs.some((d) => d.data()?.experienceId === experienceId)) {
      fail('already-exists', 'already_booked', { bookingId: dup.docs[0].id });
    }
    const capacity = Number(s.capacity) || 0;
    const booked = Number(s.bookedCount) || 0;
    if (capacity - booked < guests) {
      fail('resource-exhausted', 'slot_full', { seatsLeft: Math.max(0, capacity - booked) });
    }

    const requested = e.requestToBook === true;
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
      price: priced.price,
      payment: {
        mode,
        link,
        guestMarkedPaidAt: null,
        hostConfirmedPaidAt: null,
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
    tx.update(slotRef, { bookedCount: booked + guests, updatedAt: ts(now) });
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
      ? refundFor(b.policy, now, start, msOf(b.createdAt) ?? now, by)
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
  const code = checkInCode(await checkInSecret(), bookingId);
  return { bookingId, code, qrPayload: checkInQrPayload(bookingId, code) };
}

export async function checkInBooking(uid: string, data: any): Promise<Record<string, unknown>> {
  const bookingId = requireBookingId(data);
  const cashReceived = data?.cashReceived === true;
  const cfg = await loadConfig();
  const secret = await checkInSecret();
  const r = await transition(bookingId, (b, now) => {
    if (uid !== b.hostId) fail('permission-denied', 'not_host');
    const wantsCash = cashReceived && b.payment?.mode === 'cash' && !b.payment?.hostConfirmedPaidAt;
    if (b.status === 'confirmed' && b.checkIn && !wantsCash) return { noop: true };
    if (b.status !== 'confirmed') fail('failed-precondition', 'not_confirmed', { status: b.status });
    if (!verifyCheckInCode(secret, bookingId, data?.code)) fail('permission-denied', 'invalid_code');
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
    await safeNotify({
      recipientId: r.after.guestId, type: 'booking_checked_in', title: 'You are checked in',
      body: title(r.after), data: notifData(bookingId, r.after),
    });
  }
  return { ...bookingView(bookingId, r.after), alreadyCheckedIn: !!r.before.checkIn };
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
