/**
 * Two-way, double-blind reviews after a real booking.
 *
 *   guest -> experience: user_experiences/{expId}/pending_reviews/{guestId}
 *     (client create, only with a review_eligibility marker for that booking;
 *     readable by its author only). On reveal it is copied into the PUBLIC
 *     user_experiences/{expId}/reviews/{guestId} — the existing
 *     onExperienceReviewWritten trigger then moderates it, folds it into the
 *     experience + host aggregates and notifies the host, exactly as before —
 *     and the pending doc + marker are deleted.
 *   host -> guest:       guest_reviews/{bookingId}
 *     (client create by the booking's host; status held|visible|rejected set
 *     here). Visible reviews aggregate into profiles/{guestId}.guestRating*
 *     (server-owned), applied once per trigger event (booking_agg_events).
 *
 * Reveal rule (per booking): BOTH sides submitted -> both revealed at once;
 * otherwise each side is revealed REVIEW_REVEAL_DAYS after it was submitted
 * (revealBlindReviews job). A side submitted after the other was already
 * revealed is revealed immediately (nothing left to be blind about).
 */

import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { moderateCommentText } from '../user_experiences/moderation';
import {
  BOOKINGS,
  BOOKING_AGG_EVENTS,
  DAY_MS,
  EXPERIENCES,
  GUEST_REVIEWS,
  PENDING_REVIEWS,
  REVIEW_ELIGIBILITY,
  applyGuestRatingDelta,
  guestRatingDelta,
} from './model';
import { bookingDeps, loadConfig, msOf } from './service';

const fdb = () => bookingDeps.db();
const nowMs = () => bookingDeps.now().getTime();
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const AGG_EVENT_TTL_MS = 7 * DAY_MS;

export interface RevealResult {
  guestSide: boolean;
  hostSide: boolean;
}

/**
 * Reveals what may be revealed for [bookingId], in one transaction.
 * `due` = also reveal a side on its own once its revealAt has passed.
 */
export async function revealForBooking(bookingId: string, due = false): Promise<RevealResult> {
  const db = fdb();
  const bookingSnap = await db.collection(BOOKINGS).doc(bookingId).get();
  const b = bookingSnap.data();
  if (!b) return { guestSide: false, hostSide: false };
  const expRef = db.collection(EXPERIENCES).doc(b.experienceId);
  const pendingRef = expRef.collection(PENDING_REVIEWS).doc(b.guestId);
  const reviewRef = expRef.collection('reviews').doc(b.guestId);
  const eligRef = expRef.collection(REVIEW_ELIGIBILITY).doc(b.guestId);
  const grRef = db.collection(GUEST_REVIEWS).doc(bookingId);

  const out = await db.runTransaction(async (tx) => {
    const [pending, review, gr, elig] = await Promise.all([
      tx.get(pendingRef), tx.get(reviewRef), tx.get(grRef), tx.get(eligRef),
    ]);
    const now = nowMs();
    const p = pending.data();
    const pendingOk = !!p && p.bookingId === bookingId && (p.status ?? 'pending') === 'pending';
    const g = gr.data();
    const guestSubmitted = pendingOk || (review.exists && review.data()?.bookingId === bookingId);
    const hostSubmitted = gr.exists;
    const guestRevealed = review.exists && review.data()?.bookingId === bookingId;
    const hostRevealed = !!g && g.status !== 'held';

    const pendingDue = pendingOk && (msOf(p.revealAt) ?? Infinity) <= now;
    const grDue = !!g && g.status === 'held' && (msOf(g.revealAt) ?? Infinity) <= now;

    const revealGuest = pendingOk && (hostSubmitted || hostRevealed || (due && pendingDue));
    const revealHost = !!g && g.status === 'held' && (guestSubmitted || guestRevealed || (due && grDue));

    if (revealGuest) {
      const base = {
        authorId: b.guestId,
        bookingId,
        rating: p.rating,
        comment: typeof p.comment === 'string' ? p.comment : '',
        updatedAt: ts(now),
      };
      if (review.exists) {
        tx.update(reviewRef, base);
      } else {
        tx.set(reviewRef, { ...base, createdAt: p.createdAt ?? ts(now) });
      }
      tx.delete(pendingRef);
      if (elig.exists && elig.data()?.bookingId === bookingId) tx.delete(eligRef);
    }
    if (revealHost) tx.update(grRef, { status: 'visible', revealedAt: ts(now) });
    return { guestSide: revealGuest, hostSide: revealHost };
  });
  return out;
}

/**
 * guest_reviews/{bookingId} written. New doc (no status yet): moderate ->
 * 'rejected' or 'held' (+ revealAt), then try to reveal the pair. Every event:
 * apply its own visible-rating delta to the guest's profile totals (once per
 * event id). Newly visible -> notify the guest.
 */
export async function handleGuestReviewWrite(
  eventId: string,
  bookingId: string,
  before: Record<string, any> | null,
  after: Record<string, any> | null,
): Promise<void> {
  const db = fdb();
  const ref = db.collection(GUEST_REVIEWS).doc(bookingId);
  if (after && !after.status) {
    const cfg = await loadConfig();
    const decision = moderateCommentText(after.comment);
    const created = msOf(after.createdAt) ?? nowMs();
    await ref.update(decision.ok
      ? { status: 'held', revealAt: ts(created + cfg.reviewRevealDays * DAY_MS) }
      : { status: 'rejected', moderation: { reason: decision.reason, terms: decision.terms ?? [] } });
    // A rejected host review still counts as "submitted" for the guest side.
    await revealForBooking(bookingId);
    if (decision.ok) {
      const fresh = (await ref.get()).data();
      if (fresh?.status === 'held') {
        await notifySafe({
          recipientId: after.guestId, type: 'guest_review_waiting',
          title: 'Your host reviewed you', body: 'Review your experience to see what they said.',
          data: { action: 'booking', bookingId, experienceId: String(after.experienceId || '') },
        });
      }
    }
    return; // the status write re-fires this trigger with its own delta
  }

  const delta = guestRatingDelta(before, after);
  const guestId = (after?.guestId ?? before?.guestId) as string | undefined;
  if (guestId && (delta.sum !== 0 || delta.count !== 0)) {
    const markerRef = db.collection(BOOKING_AGG_EVENTS).doc(`gr_${eventId}`);
    const profileRef = db.collection('profiles').doc(guestId);
    await db.runTransaction(async (tx) => {
      const [marker, profile] = await Promise.all([tx.get(markerRef), tx.get(profileRef)]);
      if (marker.exists) return; // duplicate delivery
      tx.set(markerRef, { bookingId, guestId, expireAt: ts(nowMs() + AGG_EVENT_TTL_MS) });
      if (!profile.exists) return;
      tx.update(profileRef, { ...applyGuestRatingDelta(profile.data(), delta) });
    });
  }
  if (after?.status === 'visible' && before?.status !== 'visible') {
    await notifySafe({
      recipientId: after.guestId, type: 'guest_review_published',
      title: 'You have a new review from a host', body: typeof after.comment === 'string' ? after.comment.slice(0, 120) : '',
      data: { action: 'guest_review', bookingId },
    });
  }
}

/**
 * pending_reviews/{guestId} created: stamp status + revealAt (server fields),
 * then reveal if the host already reviewed; otherwise nudge the host.
 */
export async function handlePendingReviewCreated(
  experienceId: string,
  guestId: string,
  data: Record<string, any>,
): Promise<void> {
  const db = fdb();
  const ref = db.collection(EXPERIENCES).doc(experienceId).collection(PENDING_REVIEWS).doc(guestId);
  const bookingId = typeof data.bookingId === 'string' ? data.bookingId : '';
  if (!bookingId) return;
  const cfg = await loadConfig();
  const created = msOf(data.createdAt) ?? nowMs();
  try {
    await ref.update({ status: 'pending', revealAt: ts(created + cfg.reviewRevealDays * DAY_MS) });
  } catch {
    return; // withdrawn / already revealed
  }
  const r = await revealForBooking(bookingId);
  if (!r.guestSide) {
    const b = (await db.collection(BOOKINGS).doc(bookingId).get()).data();
    if (b?.hostId) {
      await notifySafe({
        recipientId: b.hostId, type: 'booking_review_waiting',
        title: 'Your guest left a review', body: 'Review your guest to reveal both reviews.',
        data: { action: 'booking', bookingId, experienceId },
      });
    }
  }
}

/** Hourly: reveal every side whose blind period has ended. */
export async function revealDueReviews(): Promise<number> {
  const db = fdb();
  const now = ts(nowMs());
  let n = 0;
  const ids = new Set<string>();
  const [held, pending] = await Promise.all([
    db.collection(GUEST_REVIEWS).where('status', '==', 'held').where('revealAt', '<=', now)
      .orderBy('revealAt').limit(300).get(),
    db.collectionGroup(PENDING_REVIEWS).where('status', '==', 'pending').where('revealAt', '<=', now)
      .orderBy('revealAt').limit(300).get(),
  ]);
  held.docs.forEach((d) => ids.add(d.id));
  pending.docs.forEach((d) => {
    const id = d.data()?.bookingId;
    if (typeof id === 'string' && id) ids.add(id);
  });
  for (const id of ids) {
    try {
      const r = await revealForBooking(id, true);
      if (r.guestSide || r.hostSide) n++;
    } catch (e) {
      console.error(`[bookings] reveal ${id} failed:`, e);
    }
  }
  if (n) console.log(`[bookings] revealed reviews for ${n} booking(s)`);
  return n;
}

async function notifySafe(p: Parameters<typeof bookingDeps.notify>[0]): Promise<void> {
  try {
    await bookingDeps.notify(p);
  } catch (e) {
    console.error(`[bookings] notify ${p.type} failed:`, e);
  }
}
