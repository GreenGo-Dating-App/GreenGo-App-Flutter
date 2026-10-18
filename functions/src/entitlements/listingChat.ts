/**
 * Buyer <-> organizer chat for events and experiences (owner request
 * 2026-10-17, 5.0.23).
 *
 * The app calls `openListingChat({ type: 'event' | 'experience', id })` from
 * "Message the organizer" / "Message the host". The SERVER decides:
 *
 *   - who the organizer is (events.organizerId / user_experiences.hostId) and
 *     whether the chat is a business inquiry (organizer profile isBusiness
 *     with a businessName) -> the conversation's synthetic matchId, the same
 *     ids the app uses (`search_{a}_{b}` sorted, `bizsearch_{owner}_{customer}`);
 *   - whether the caller is a BUYER: a `going` attendee row of the event
 *     (paid tickets and free RSVPs, events/{id}/attendees/{uid}) or a
 *     confirmed / completed booking of the experience (bookings guestId +
 *     experienceId). A signed-in account whose VERIFIED e-mail bought as a
 *     shared-link guest (guest key of that e-mail) counts too.
 *
 * Buyer: the conversation is found or created HERE (Admin SDK) with
 * `context = { type, id, title, startAt, buyer: true, buyerId }`. That is
 * the buyer exemption: it bypasses the per-tier daily new-connection cap
 * (the rules' connectCapOk only applies to client creates; the
 * onConversationCreatedCountConnect trigger skips buyer conversations) and
 * the Base-to-chat rule (messages rule `buyerChat`). Clients can never write
 * `context.buyer == true` themselves (firestore rules), so the flag is
 * trustworthy for the organizer's "Ticket holder" / "Booked" tag.
 *
 * Not a buyer: nothing is written. The app opens the chat through the normal
 * connect flow (cap applies) and stamps a context without `buyer`.
 *
 * Scale: per call one listing read, one profile read, at most two buyer
 * reads (a doc get or an equality query bounded to 10 rows), a block-index
 * pair read and, for buyers, one transaction on the conversation. No scans,
 * no fan-out; never sends a message.
 */
import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { monitored } from '../shared/monitoring';
import { guestKeyFor } from '../shared/guestIdentity';
import { guestIdentitySecret } from '../guest/guestKeys';
import { BLOCK_INDEX } from '../safety/blockIndex';

const db = () => admin.firestore();

export type ListingType = 'event' | 'experience';

export interface ListingInfo {
  organizerId: string;
  title: string;
  /** Event start (ms), or null for experiences without a booked slot. */
  startMs: number | null;
}

/** Booking statuses that make the caller a "booked" guest. */
export const BUYER_BOOKING_STATUSES: ReadonlySet<string> = new Set(['confirmed', 'completed']);

const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;
const TITLE_MAX = 120;

export function parseListingChatRequest(data: unknown): { type: ListingType; id: string } {
  const d = (data ?? {}) as Record<string, unknown>;
  const type = d.type;
  const id = d.id;
  if ((type !== 'event' && type !== 'experience') || typeof id !== 'string' || !ID_RE.test(id)) {
    throw new HttpsError('invalid-argument', 'type and id are required.');
  }
  return { type, id };
}

export function millisOf(v: any): number | null {
  if (v == null) return null;
  if (typeof v === 'number' && Number.isFinite(v)) return v;
  if (typeof v.toMillis === 'function') return v.toMillis();
  if (v instanceof Date) return v.getTime();
  return null;
}

/** Organizer + title of a listing document (null when unusable). */
export function listingInfoOf(type: ListingType, d: Record<string, any> | undefined): ListingInfo | null {
  if (!d) return null;
  const organizerId = type === 'event' ? d.organizerId : d.hostId;
  if (typeof organizerId !== 'string' || !organizerId || organizerId.includes('/')) return null;
  const title = String(d.title ?? '').trim().slice(0, TITLE_MAX);
  return { organizerId, title, startMs: type === 'event' ? millisOf(d.startDate) : null };
}

/** Business inquiry when the organizer is a business storefront (same test as the app). */
export function isBusinessOrganizer(p: Record<string, any> | undefined): boolean {
  return p?.isBusiness === true && typeof p.businessName === 'string' && p.businessName.trim().length > 0;
}

/** Synthetic matchId - must mirror ChatRemoteDataSource.getOrCreateSearchConversation. */
export function listingChatMatchId(buyerUid: string, organizerId: string, businessInquiry: boolean): string {
  if (businessInquiry) return `bizsearch_${organizerId}_${buyerUid}`;
  const [a, b] = [buyerUid, organizerId].sort();
  return `search_${a}_${b}`;
}

/** A `going` attendee row (paid ticket or free RSVP) of an event. */
export function isGoingAttendee(a: Record<string, any> | undefined): boolean {
  if (!a || a.status !== 'going') return false;
  if (a.ticketStatus && a.ticketStatus !== 'valid') return false;
  return a.isApproved !== false;
}

/** Earliest relevant slot of the buyer's bookings (upcoming first, else latest past). */
export function bookingBuyerSlot(bookings: Array<Record<string, any>>, nowMs: number): { buyer: boolean; startMs: number | null } {
  const ok = bookings.filter((b) => BUYER_BOOKING_STATUSES.has(String(b.status)));
  if (!ok.length) return { buyer: false, startMs: null };
  const starts = ok.map((b) => millisOf(b.slotStart)).filter((x): x is number => x !== null);
  const upcoming = starts.filter((s) => s >= nowMs).sort((x, y) => x - y);
  const past = starts.filter((s) => s < nowMs).sort((x, y) => y - x);
  return { buyer: true, startMs: upcoming[0] ?? past[0] ?? null };
}

/** The conversation context stored on the conversation (pure). */
export function buildListingContext(
  type: ListingType, id: string, info: ListingInfo, startMs: number | null, buyerId: string | null,
): Record<string, any> {
  const s = startMs ?? info.startMs;
  return {
    type,
    id,
    title: info.title,
    startAt: s !== null ? admin.firestore.Timestamp.fromMillis(s) : null,
    ...(buyerId ? { buyer: true, buyerId } : {}),
  };
}

/** A 1:1 conversation between exactly these two users. */
export function isPairConversation(c: Record<string, any> | undefined, a: string, b: string): boolean {
  if (!c || c.isGroup === true) return false;
  return (c.userId1 === a && c.userId2 === b) || (c.userId1 === b && c.userId2 === a);
}

/** Who may count as the caller when checking purchases: the uid, plus the guest key of a verified e-mail. */
async function buyerIdsOf(uid: string, token: Record<string, any> | undefined): Promise<string[]> {
  const ids = [uid];
  const email = typeof token?.email === 'string' ? token.email : '';
  if (email && token?.email_verified === true) {
    try {
      ids.push(guestKeyFor(await guestIdentitySecret(), email));
    } catch {
      // No signing key (emulator / misconfigured): the uid alone.
    }
  }
  return ids;
}

/** Is any of `ids` a buyer of the listing? Returns the slot start for experiences. */
export async function checkBuyer(
  type: ListingType, listingId: string, ids: string[], nowMs: number,
): Promise<{ buyer: boolean; startMs: number | null }> {
  if (type === 'event') {
    const snaps = await Promise.all(ids.map((k) =>
      db().collection('events').doc(listingId).collection('attendees').doc(k).get()));
    return { buyer: snaps.some((s) => isGoingAttendee(s.data())), startMs: null };
  }
  const pages = await Promise.all(ids.map((k) => db().collection('bookings')
    .where('guestId', '==', k).where('experienceId', '==', listingId).limit(10).get()));
  return bookingBuyerSlot(pages.flatMap((p) => p.docs.map((d) => d.data())), nowMs);
}

async function blockedBetween(a: string, b: string): Promise<boolean> {
  const [x, y] = await Promise.all([
    db().collection(BLOCK_INDEX).doc(`${a}_${b}`).get(),
    db().collection(BLOCK_INDEX).doc(`${b}_${a}`).get(),
  ]);
  return x.exists || y.exists;
}

/** Find (or create) the buyer conversation and stamp the context. Returns its id. */
export async function upsertBuyerConversation(
  uid: string, organizerId: string, matchId: string, businessInquiry: boolean, context: Record<string, any>,
): Promise<string> {
  const col = db().collection('conversations');
  const ts = admin.firestore.FieldValue.serverTimestamp();
  return db().runTransaction(async (tx) => {
    const found = await tx.get(col.where('matchId', '==', matchId).limit(5));
    const doc = found.docs.find((d) => isPairConversation(d.data(), uid, organizerId));
    const ctx = { ...context, updatedAt: ts };
    if (doc) {
      const cur = doc.data();
      tx.update(doc.ref, {
        context: ctx,
        ...(businessInquiry && cur.businessInquiry !== true ? { businessInquiry: true } : {}),
        // A buyer who had deleted the chat sees it again.
        ...(cur.deletedFor && typeof cur.deletedFor === 'object' && uid in cur.deletedFor
          ? { [`deletedFor.${uid}`]: admin.firestore.FieldValue.delete() } : {}),
      });
      return doc.id;
    }
    const ref = col.doc();
    const now = admin.firestore.Timestamp.now();
    // Same shape as ConversationModel.toFirestore (the app's search conversation).
    tx.set(ref, {
      matchId,
      userId1: uid,
      userId2: organizerId,
      lastMessage: null,
      lastMessageAt: now,
      unreadCount: 0,
      isTyping: false,
      typingUserId: null,
      createdAt: now,
      isPinned: false,
      pinnedAt: null,
      isMuted: false,
      mutedUntil: null,
      isArchived: false,
      archivedAt: null,
      theme: 'gold',
      settings: null,
      conversationType: 'search',
      businessInquiry,
      supportAgentId: null,
      supportPriority: null,
      supportTicketStatus: null,
      supportCategory: null,
      supportSubject: null,
      supportResolvedAt: null,
      visibleTo: null,
      superLikeSenderId: null,
      favorites: null,
      context: ctx,
    });
    return ref.id;
  });
}

function wireContext(c: Record<string, any>): Record<string, any> {
  const s = c.startAt;
  return { ...c, startAt: s && typeof s.toMillis === 'function' ? s.toMillis() : null };
}

export async function handleOpenListingChat(uid: string, token: Record<string, any> | undefined, data: unknown) {
  const { type, id } = parseListingChatRequest(data);
  const listingSnap = await db().collection(type === 'event' ? 'events' : 'user_experiences').doc(id).get();
  const info = listingInfoOf(type, listingSnap.data());
  if (!info) throw new HttpsError('not-found', 'listing_not_found');
  if (info.organizerId === uid) throw new HttpsError('failed-precondition', 'own_listing');

  const [organizerSnap, blocked, ids] = await Promise.all([
    db().collection('profiles').doc(info.organizerId).get(),
    blockedBetween(uid, info.organizerId),
    buyerIdsOf(uid, token),
  ]);
  if (blocked) throw new HttpsError('permission-denied', 'blocked');
  const businessInquiry = isBusinessOrganizer(organizerSnap.data());
  const matchId = listingChatMatchId(uid, info.organizerId, businessInquiry);
  const purchase = await checkBuyer(type, id, ids, Date.now());

  const base = { organizerId: info.organizerId, businessInquiry, matchId };
  if (!purchase.buyer) {
    return { ...base, buyer: false, context: wireContext(buildListingContext(type, id, info, purchase.startMs, null)) };
  }
  const context = buildListingContext(type, id, info, purchase.startMs, uid);
  const conversationId = await upsertBuyerConversation(uid, info.organizerId, matchId, businessInquiry, context);
  return { ...base, buyer: true, conversationId, context: wireContext(context) };
}

export const openListingChat = onCall(
  { memory: '512MiB', timeoutSeconds: 30 },
  monitored('openListingChat', async (request: any) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
    return handleOpenListingChat(uid, request.auth?.token, request.data);
  }),
);
