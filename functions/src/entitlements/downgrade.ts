/**
 * Plan changes -> hide / restore listings (owner rule 2026-10-14).
 *
 * When a user's plan drops (paid tier expired / downgraded, Base expired, an
 * admin lowered it), their events and experiences over the new allowance are
 * HIDDEN, never deleted; when the plan rises again they come back, most recent
 * first, up to the new allowance. Allowance and selection are pure
 * (entitlements/listingAllowance.ts):
 *   no plan 0 · Base 1 · Silver 5 · Gold 10 · Platinum / TEST / admin unlimited
 * active events (a series is one) and active experiences, the newest kept.
 *
 * ONE trigger covers every way a plan changes - the hourly expiry jobs
 * (subscription/index.ts handleExpiredMemberships / handleExpiredBaseMemberships
 * write membershipTier / hasBaseMembership), store notifications, purchase
 * verification, Stripe webhooks, coupons and admin edits all end in a write of
 * the allowance fields on profiles/{uid}. Every other profile write exits
 * after one comparison.
 *
 * Tickets and bookings already sold stay valid: a hidden event keeps its
 * document (holders still open it by id), only discovery / share cards drop
 * it. A listing that stays visible after a drop to Base cannot sell new paid
 * tickets / bookings - Base is never an active business
 * (shared/effectiveTier.ts isBusinessActive), so checkout refuses with
 * `seller_not_business`; existing orders are unaffected.
 *
 * Idempotent (planning again on the result is a no-op) and per-user: indexed
 * per-owner queries (events organizerId+endDate, organizerId+hiddenByDowngrade;
 * user_experiences hostId), paginated, written in batches of <= 400.
 */
import * as admin from 'firebase-admin';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import '../shared/firebaseAdmin';
import { monitored } from '../shared/monitoring';
import { WriteQueue } from '../shared/membershipExpiry';
import { logInfo } from '../shared/utils';
import { isBannedState } from '../user_experiences/hostBan';
import { millisOf } from './eventSlots';
import {
  ListingAllowance,
  ListingUnit,
  allowanceFieldsChanged,
  eventUnits,
  eventHidePatch,
  eventRestoreStatus,
  experienceHidePatch,
  experienceHideable,
  experienceRestore,
  listingAllowance,
  planListingReconcile,
} from './listingAllowance';

const db = admin.firestore();
const PAGE = 300;
const FV = admin.firestore.FieldValue;

const EVENT_FIELDS = ['organizerId', 'status', 'endDate', 'seriesId', 'createdAt', 'hiddenByDowngrade', 'preDowngradeStatus'];
const EXPERIENCE_FIELDS = ['hostId', 'status', 'createdAt', 'hiddenByDowngrade', 'moderation'];

type Doc = { id: string; ref: FirebaseFirestore.DocumentReference; data: Record<string, any> };

async function pagedByDocId(base: FirebaseFirestore.Query, fields: string[], into: Map<string, Doc>): Promise<void> {
  let cursor: string | null = null;
  for (;;) {
    let q = base.orderBy(admin.firestore.FieldPath.documentId()).select(...fields).limit(PAGE);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.get();
    for (const d of snap.docs) into.set(d.id, { id: d.id, ref: d.ref, data: d.data() });
    if (snap.size < PAGE) return;
    cursor = snap.docs[snap.docs.length - 1].id;
  }
}

/** The owner's ongoing events plus every event already hidden by a downgrade. */
async function loadEvents(uid: string, nowMs: number): Promise<Map<string, Doc>> {
  const out = new Map<string, Doc>();
  // Ongoing: organizerId + endDate (the index recountEvents already uses).
  let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  for (;;) {
    let q = db.collection('events')
      .where('organizerId', '==', uid)
      .where('endDate', '>', admin.firestore.Timestamp.fromMillis(nowMs))
      .orderBy('endDate')
      .select(...EVENT_FIELDS)
      .limit(PAGE);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    for (const d of snap.docs) out.set(d.id, { id: d.id, ref: d.ref, data: d.data() });
    if (snap.size < PAGE) break;
    last = snap.docs[snap.docs.length - 1];
  }
  await pagedByDocId(
    db.collection('events').where('organizerId', '==', uid).where('hiddenByDowngrade', '==', true),
    EVENT_FIELDS, out);
  return out;
}

export interface ReconcileResult { eventsHidden: number; eventsRestored: number; experiencesHidden: number; experiencesRestored: number }

async function reconcileEvents(uid: string, limit: number | null, allowRestore: boolean, nowMs: number, queue: WriteQueue, r: ReconcileResult) {
  const docs = [...(await loadEvents(uid, nowMs)).values()];
  const { units, groups } = eventUnits<Doc>(docs, nowMs);
  const plan = planListingReconcile(units, limit, { allowRestore });
  const hideSet = new Set(plan.hide);
  const restoreSet = new Set(plan.restore);
  for (const [key, g] of groups) {
    if (hideSet.has(key)) {
      for (const doc of g.visible) {
        const p = eventHidePatch(doc.data);
        if (!p) continue;
        await queue.update(doc.ref, { ...p, hiddenByDowngradeAt: FV.serverTimestamp() });
        r.eventsHidden++;
      }
    }
    // A restored slot comes back whole; a KEPT visible series also gets its
    // hidden occurrences back so a series is never half visible.
    const restoreHidden = restoreSet.has(key) || (allowRestore && !hideSet.has(key) && g.visible.length > 0);
    if (restoreHidden) {
      for (const doc of g.hidden) {
        const status = eventRestoreStatus(doc.data);
        if (!status) continue;
        await queue.update(doc.ref, {
          status,
          hiddenByDowngrade: FV.delete(),
          preDowngradeStatus: FV.delete(),
          hiddenByDowngradeAt: FV.delete(),
        });
        r.eventsRestored++;
      }
    }
  }
}

async function reconcileExperiences(uid: string, limit: number | null, allowRestore: boolean, queue: WriteQueue, r: ReconcileResult) {
  const docs = new Map<string, Doc>();
  await pagedByDocId(db.collection('user_experiences').where('hostId', '==', uid), EXPERIENCE_FIELDS, docs);
  const units: ListingUnit[] = [];
  for (const [id, doc] of docs) {
    const d = doc.data;
    if (d.hiddenByDowngrade === true) {
      units.push({ key: id, createdMs: millisOf(d.createdAt) ?? 0, hidden: true, active: true });
    } else if (experienceHideable(d)) {
      units.push({ key: id, createdMs: millisOf(d.createdAt) ?? 0, hidden: false, active: true });
    }
  }
  const plan = planListingReconcile(units, limit, { allowRestore });
  for (const id of plan.hide) {
    const doc = docs.get(id)!;
    const p = experienceHidePatch(doc.data);
    if (!p) continue;
    await queue.update(doc.ref, { ...p, hiddenByDowngradeAt: FV.serverTimestamp() });
    r.experiencesHidden++;
  }
  for (const id of plan.restore) {
    const doc = docs.get(id)!;
    const how = experienceRestore(doc.data);
    if (!how) continue;
    await queue.update(doc.ref, how.kind === 'status'
      ? { status: how.status, moderation: FV.delete(), hiddenByDowngrade: FV.delete(), hiddenByDowngradeAt: FV.delete() }
      : { hiddenByDowngrade: FV.delete(), hiddenByDowngradeAt: FV.delete() });
    r.experiencesRestored++;
  }
}

const sameAllowance = (a: ListingAllowance, b: ListingAllowance) => a.events === b.events && a.experiences === b.experiences;

/**
 * Brings `uid`'s visible events / experiences in line with the CURRENT
 * allowance (fresh profile read). Restores are skipped while the account is
 * banned / suspended (hostBan.ts owns those listings then). If the profile
 * changed allowance while this ran, it runs once more.
 */
export async function reconcileListings(uid: string): Promise<ReconcileResult> {
  const r: ReconcileResult = { eventsHidden: 0, eventsRestored: 0, experiencesHidden: 0, experiencesRestored: 0 };
  if (!uid || uid.includes('/')) return r;
  const profileRef = db.collection('profiles').doc(uid);
  for (let pass = 0; pass < 2; pass++) {
    const profile = (await profileRef.get()).data();
    if (!profile) return r;
    const now = new Date();
    const allowance = listingAllowance(profile, now);
    const allowRestore = !isBannedState(profile);
    const queue = new WriteQueue(db);
    await reconcileEvents(uid, allowance.events, allowRestore, now.getTime(), queue, r);
    await reconcileExperiences(uid, allowance.experiences, allowRestore, queue, r);
    await queue.flush();
    const again = (await profileRef.get()).data();
    if (!again || sameAllowance(listingAllowance(again, new Date()), allowance)) break;
  }
  if (r.eventsHidden || r.eventsRestored || r.experiencesHidden || r.experiencesRestored) {
    logInfo(`reconcileListings(${uid}): ${JSON.stringify(r)}`);
  }
  return r;
}

/**
 * profiles/{uid} updates: reacts ONLY when an allowance field changes
 * (membershipTier, membershipEndDate, hasBaseMembership, baseMembershipEndDate,
 * isAdmin). 512MiB: the bundle needs ~200MB just to load.
 */
export const onProfileListingAllowanceChanged = onDocumentUpdated(
  { document: 'profiles/{uid}', memory: '512MiB', timeoutSeconds: 300, retry: false },
  monitored('onProfileListingAllowanceChanged', async (event: any) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;
    if (!allowanceFieldsChanged(before, after)) return;
    await reconcileListings(event.params.uid as string);
  }),
);
