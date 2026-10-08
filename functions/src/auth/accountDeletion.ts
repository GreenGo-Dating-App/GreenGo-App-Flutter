/**
 * THE account deletion routine (audit H-15 / P1-10, P2-7 part 1).
 *
 * One implementation, used by:
 *   - deleteMyAccount (callable, app)              -> deletes Auth LAST
 *   - requestAccountDeletion / confirmAccountDeletion (website) -> Auth LAST
 *   - onUserDeletedCleanup (Auth onDelete trigger: old app versions, admin
 *     panel, console) -> Auth is already gone; sweeps the data.
 *
 * Driven by ACCOUNT_DATA_INVENTORY below: every per-user location we know of,
 * and what happens to it. Adding a feature that stores per-user data means
 * adding a line here (the inventory test seeds every line and checks nothing
 * with the uid survives outside the retention stores).
 *
 * Every step is idempotent and re-queries its source (no saved offsets), so a
 * run that dies half-way is finished by simply running it again — which is
 * what the Auth trigger does after an app/web deletion anyway.
 *
 * ---------------------------------------------------------------------------
 * POLICY NOTES FOR COUNSEL (DRAFT)
 *
 * DELETED: every document keyed by / owned by the user, the user's
 *   subcollections (recursive), the user's own Storage prefixes, and the
 *   Storage objects referenced by messages the user sent (chat media).
 *
 * RETAINED - FINANCIAL (GDPR Art. 17(3)(b)/(e), LGPD Art. 16 I; tax/bookkeeping
 *   law, 5-year retention promised in the privacy policy): payment and coin
 *   ledger records are NOT kept as-is. The minimum bookkeeping fields (amount,
 *   currency, product, store/order/transaction ids, dates, status) are copied
 *   to `retention_finance/{collection}__{docId}` with the uid replaced by
 *   `uidHash` = SHA-256(RETENTION_SALT + ':' + uid); no name, email, photo or
 *   free text. The originals are then deleted. `retainUntil` = +5 years
 *   (a purge job for expired rows is follow-up work, P2-7).
 *   RETENTION_SALT: set it as a secret/env var in production. Fallback (if
 *   unset) is the fixed string FALLBACK_RETENTION_SALT below - documented
 *   on purpose so hashes stay stable, but it is public in the source, so it
 *   only pseudonymises against outsiders who do not have the uid list.
 *
 * IDENTITY DOCUMENTS (P2-6): `id_documents/{uid}/` images are DELETED (no
 *   30-day retention any more); only legacy entries under an admin legal hold
 *   stay in `id_document_retention` (safety/idDocumentRetention.ts).
 *
 * ANONYMISED - MESSAGES IN SHARED CONVERSATIONS: messages the user sent to
 *   OTHER people stay in the other person's history (deleting them would edit
 *   someone else's records) as an EMPTY placeholder: `senderId` becomes
 *   'deleted_user', `deletedAuthor: true`, sender name/photo are removed, the
 *   text body is cleared (`content: ''`) together with every stored
 *   translation of it, and media is removed (non-text messages become
 *   type 'text', `mediaRemoved: true`, the Storage object is deleted).
 *   Timestamps stay, so the conversation keeps its order; the app shows a
 *   localized "Message deleted" bubble. (Owner decision 2026-10-08: the other
 *   person no longer sees the deleted user's words.) A conversation's
 *   `lastMessage` preview written by the deleted user is cleared the same way.
 *
 * NOT DONE HERE (enqueued in `deletion_followups/{uid}` for a later worker):
 *   Stripe customer deletion and GA4 / Crashlytics user-data deletion. Those
 *   are external API calls and are out of scope for this change.
 */

import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import '../shared/firebaseAdmin';
import { retainIdDocumentsOnAccountDeletion } from '../safety/idDocumentRetention';
import { enqueueFollowGraphCleanup, removeFollowGraphRound } from '../social/followCleanup';

const db = () => admin.firestore();
const TS = () => admin.firestore.Timestamp.now();

export const TOMBSTONE = 'deleted_user';
export const DELETION_JOBS = 'deletion_jobs';
export const DELETION_RECEIPTS = 'deletion_receipts';
export const DELETION_FOLLOWUPS = 'deletion_followups';
export const RETENTION_FINANCE = 'retention_finance';
export const FALLBACK_RETENTION_SALT = 'greengo-retention-finance-v1';
const PAGE = 300;
const FIVE_YEARS_MS = 5 * 365.25 * 24 * 3600 * 1000;

/**
 * Collections that legitimately keep something about a deleted uid
 * afterwards. Everything else must be empty for the uid (inventory test).
 */
export const RETENTION_STORES = [
  RETENTION_FINANCE, // pseudonymised (uidHash), never the uid itself
  DELETION_RECEIPTS, // keyed by uid, no personal data
  DELETION_FOLLOWUPS, // work queue for Stripe/analytics; deleted by its worker
  DELETION_JOBS, // only kept when a run FAILED (needed to retry)
  'id_document_retention', // legacy entries under an admin legal hold only (P2-6)
  'follow_cleanup_jobs', // queued follow-graph job, deleted when done
];

// ---------------------------------------------------------------------------
// Inventory
// ---------------------------------------------------------------------------

export type InventoryEntry =
  /** Document whose id IS the uid; `recursive` also removes subcollections. */
  | { kind: 'doc'; collection: string; recursive?: boolean }
  /** A fixed path containing `{uid}` (e.g. a subcollection under a fixed parent). */
  | { kind: 'path'; path: string; recursive?: boolean }
  /** Documents found by `field == uid` (or array-contains). */
  | { kind: 'query'; collection: string; field: string; arrayContains?: boolean; recursive?: boolean }
  /** Documents whose id starts with `${uid}_` (compound ids). */
  | { kind: 'idPrefix'; collection: string }
  /** Collection-group docs by field; optional counter on the parent doc. */
  | { kind: 'group'; group: string; field: string; parentCounter?: string }
  /** Financial records: minimal copy to retention_finance, then delete. */
  | { kind: 'finance'; collection: string; field?: string; byDocId?: boolean }
  /** The user's support tickets: chat + its support_messages + attachments. */
  | { kind: 'supportChats' }
  /**
   * Shared docs (conversations, groups, bookings): keep for the other
   * members, replace the uid with the tombstone everywhere (string values,
   * 1:1 array members), drop map keys equal to the uid. `dropFromArrays`
   * (or `isGroup: true` on the doc) removes the uid from arrays instead
   * (= leaving the group); `deleteSub` also deletes `{doc}/{deleteSub}/{uid}`.
   */
  | { kind: 'scrub'; collection: string; field: string; arrayContains?: boolean; dropFromArrays?: boolean; deleteSub?: string }
  /** Other users' docs that list the uid in an array field: arrayRemove only. */
  | { kind: 'arrayRemove'; collection: string; field: string }
  /** Other users' docs that reference the uid in one field: set to tombstone. */
  | { kind: 'replaceField'; collection: string; field: string }
  /** Two-party content: keep, but strip author identity + media. */
  | { kind: 'anonymise'; group: string; field: string; topLevelOnly?: boolean }
  /** Storage prefix `${prefix}/${uid}/` (default bucket unless `buckets`). */
  | { kind: 'storage'; prefix: string; buckets?: 'backup' };

export const BACKUP_BUCKETS = (): string[] =>
  Array.from(new Set([process.env.BACKUP_BUCKET || 'greengo-chat-backups', 'conversation-backups']));

const docs = (recursive: boolean, ...cs: string[]): InventoryEntry[] =>
  cs.map((c) => ({ kind: 'doc', collection: c, recursive }));
const q = (collection: string, ...fields: string[]): InventoryEntry[] =>
  fields.map((field) => ({ kind: 'query', collection, field }));
const fin = (collection: string, ...fields: string[]): InventoryEntry[] =>
  fields.map((field) => ({ kind: 'finance', collection, field }));

/**
 * Every per-user location (sources: the writers in lib/ and functions/src,
 * firestore.rules, storage.rules - inventory of 2026-10-08). Legacy names that
 * only the old client deletion list knew are kept: a get on a missing doc is
 * cheap and old accounts may still hold them.
 */
export const ACCOUNT_DATA_INVENTORY: InventoryEntry[] = [
  // --- Documents keyed by uid (subcollections included) -------------------
  ...docs(true,
    'user_interactions', 'user_vectors', 'match_preferences', 'interaction_matrix',
    'referrals', 'referral_redemptions', 'signup_grants', 'user_passports',
    'email_preferences', 'user_levels', 'userLevels', 'user_group_tags', 'user_people_tags',
    'user_group_inbox', 'user_favorite_communities', 'userSettings', 'user_settings',
    'notification_preferences', 'notification_settings', 'user_presence', 'age_verification_queue',
    // Owner/admin-only half of the profile (exact location, DOB, ...; P1-4).
    'profiles_private',
    'streaks', 'mission_progress', 'usageLimits', 'dailyUsage', 'user_stats',
    'user_badge_preferences', 'user_vocabulary', 'user_experience_counts',
    'host_cancellation_stats', 'host_flags', 'host_suspensions', 'host_schedules',
    'business_verification_requests', 'business_ratings', 'business_leads',
    'gamification', 'login_streaks', 'trust_scores', 'verification_badges',
    'fake_profile_detections', 'churn_predictions', 'user_segments', 'welcome_email_series',
    'user_encryption_keys', 'saved_searches', 'safety_progress', 'achievement_progress',
    'language_progress', 'learning_progress', 'daily_hints_progress', 'userAchievements',
    'userBadges', 'userChallenges', 'userVibeTags', 'user_achievements', 'user_challenges',
    'game_stats', 'blocked_users',
  ),
  { kind: 'path', path: 'leaderboards/xp/rankings/{uid}' },

  // --- Compound ids `${uid}_...` -------------------------------------------
  ...['translation_quota', 'achievement_progress', 'challenge_progress', 'level_rewards_claimed',
    'coinAllowanceGrants', 'referralMonthlyGrants', 'user_learning_progress',
  ].map((c): InventoryEntry => ({ kind: 'idPrefix', collection: c })),

  // --- Documents owned via a field ----------------------------------------
  ...q('user_interactions', 'userId', 'targetUserId'),
  ...q('swipes', 'userId', 'targetUserId'),
  ...q('matches', 'userId1', 'userId2'),
  ...q('notifications', 'userId'),
  ...q('email_logs', 'userId'),
  ...q('nicknames', 'uid'),
  ...q('identity_verifications', 'userId'),
  ...q('video_profiles', 'userId'),
  ...q('blockedUsers', 'blockerId', 'blockedUserId', 'userId'),
  ...q('user_blocks', 'blockerId', 'blockedUserId'),
  ...q('user_reports', 'reporterId'),
  ...q('reports', 'reporterId'),
  ...q('message_reports', 'reporterId'),
  ...q('account_actions', 'userId'),
  ...q('image_moderation', 'userId'),
  ...q('moderation_queue', 'userId'),
  ...q('photo_likes', 'profileUserId', 'likerId'),
  ...q('album_access', 'ownerId', 'grantedToId'),
  ...q('xp_transactions', 'userId'),
  ...q('achievement_progress', 'userId'),
  ...q('challenge_progress', 'userId'),
  ...q('language_progress', 'userId'),
  ...q('referral_codes', 'ownerId'),
  ...q('conversation_backups', 'userId'),
  ...q('backups', 'userId'),
  ...q('pdf_exports', 'userId'),
  ...q('conversation_exports', 'userId'),
  ...q('user_lesson_access', 'userId'),
  ...q('teacher_applications', 'userId'),
  ...q('user_warnings', 'userId'),
  ...q('appeals', 'userId'),
  ...q('report_appeals', 'userId'),
  ...q('spam_detections', 'userId'),
  ...q('deletion_requests', 'uid'),
  { kind: 'query', collection: 'met_in_person', field: 'users', arrayContains: true, recursive: true },
  { kind: 'query', collection: 'user_experiences', field: 'hostId', recursive: true },
  { kind: 'supportChats' },

  // --- Collection-group memberships (with counters) ----------------------
  { kind: 'group', group: 'members', field: 'userId', parentCounter: 'memberCount' },
  { kind: 'group', group: 'attendees', field: 'userId', parentCounter: 'attendeeCount' },

  // --- Financial records: pseudonymised retention ------------------------
  ...fin('purchaseLedger', 'userId'),
  ...fin('coinTransactions', 'userId'),
  ...fin('coin_transactions', 'userId'),
  ...fin('videoCoinTransactions', 'userId'),
  ...fin('coinGifts', 'senderId', 'receiverId'),
  ...fin('coinOrders', 'userId'),
  ...fin('purchases', 'userId'),
  ...fin('orders', 'userId'),
  ...fin('stripe_orders', 'userId'),
  ...fin('stripe_invoices', 'userId'),
  ...fin('invoices', 'userId'),
  ...fin('transactions', 'userId'),
  ...fin('subscriptions', 'userId'),
  ...fin('memberships', 'userId'),
  ...fin('membership_purchases', 'userId'),
  ...fin('membershipLedger', 'userId'),
  ...['coinBalances', 'coin_balances', 'coin_wallets', 'videoCoinBalances', 'stripe_customers',
    'subscriptions', 'memberships',
  ].map((c): InventoryEntry => ({ kind: 'finance', collection: c, byDocId: true })),

  // --- Shared containers: keep for the others, scrub the uid --------------
  { kind: 'scrub', collection: 'conversations', field: 'userId1' },
  { kind: 'scrub', collection: 'conversations', field: 'userId2' },
  { kind: 'scrub', collection: 'conversations', field: 'participants', arrayContains: true },
  { kind: 'scrub', collection: 'groups', field: 'participants', arrayContains: true, dropFromArrays: true, deleteSub: 'members' },
  { kind: 'scrub', collection: 'bookings', field: 'guestId' },
  { kind: 'scrub', collection: 'bookings', field: 'hostId' },
  { kind: 'scrub', collection: 'guest_reviews', field: 'guestId' },
  { kind: 'scrub', collection: 'guest_reviews', field: 'hostId' },
  { kind: 'arrayRemove', collection: 'users', field: 'blockedUsers' },
  { kind: 'replaceField', collection: 'coinTransactions', field: 'relatedUserId' },

  // --- Two-party content: anonymise ----------------------------------------
  // Collection group 'messages' = conversations/*/messages, groups/*/messages,
  // communities/*/messages, events/*/messages and the legacy top-level one.
  { kind: 'anonymise', group: 'messages', field: 'senderId' },
  { kind: 'anonymise', group: 'support_messages', field: 'senderId', topLevelOnly: true },

  // --- Storage: prefixes keyed by uid --------------------------------------
  ...['profiles', 'users', 'video_profiles', 'voice_intros', 'verifications', 'verification',
    'voice', 'age_verification', 'business_verification', 'communities',
  ].map((p): InventoryEntry => ({ kind: 'storage', prefix: p })),
  // Conversation backups / PDF exports live in the backup bucket(s):
  // backups/{uid}/, exports/{uid}/, {uid}/ and auto/{uid}/.
  ...['backups', 'exports', '', 'auto'].map((p): InventoryEntry => ({ kind: 'storage', prefix: p, buckets: 'backup' })),

  // profiles/{uid} and users/{uid} are deleted LAST (see deleteAccountData):
  // deleting profiles/{uid} fires onProfileDeleted.
];

/**
 * Locations that keep something about a deleted uid ON PURPOSE, or that this
 * change cannot reach yet (P2-7). Documented for counsel.
 */
export const KNOWN_RESIDUALS = [
  "user_reports / reports / message_reports / moderation_queue where reportedUserId == uid (other people's reports: moderation records)",
  'receiverId / readBy / deliveredTo / reactions keyed by uid on messages OTHER people sent (their copy; no identity once the profile is gone)',
  'subcollection docs keyed by uid under other parents without a userId field: events/*/likes, communities/*/join_requests, coupons/*/redemptions, event_city_subscribers/*/subscribers, attraction_ratings/*/ratings, business_ratings/*/ratings, business_leads/*/leads, user_experiences/*/{reviews,pending_reviews,review_eligibility,booking_consents}',
  'daily_viewers/{day}_{uid} (suffix id, not range-queryable)',
  'translations.voters[] / translation_candidates votes (TTL-expired)',
  'communities created by the user (createdByUserId) and events organised by the user (organizerId): left for their members',
  'Storage objects outside uid-keyed prefixes that carry only customMetadata.userId',
  'admin_users/{uid} (admin roles are removed by an admin, not by self-deletion)',
];

/** Chat media prefixes whose objects are attributed via the sender's messages. */
export const SHARED_MEDIA_PREFIXES = [
  'chat_images/', 'chat_voice/', 'chat_videos/', 'group_media/', 'group_voice/', 'support_attachments/',
];

/** Fields copied to retention_finance (primitives / timestamps only). */
const FINANCE_FIELDS = [
  'amount', 'amountCents', 'amountTotal', 'amount_total', 'amountPaid', 'currency', 'price',
  'priceMicros', 'priceAmountMicros', 'priceCurrencyCode', 'coins', 'coinAmount', 'coinsAdded',
  'quantity', 'type', 'reason', 'status', 'productId', 'sku', 'tier', 'plan', 'platform', 'store',
  'provider', 'source', 'orderId', 'transactionId', 'originalTransactionId', 'paymentIntentId',
  'invoiceId', 'stripeInvoiceId', 'stripeSessionId', 'sessionId', 'subscriptionId', 'refunded',
  'refundedAt', 'tax', 'taxAmount', 'billingCountry', 'createdAt', 'timestamp', 'purchaseDate',
  'purchasedAt', 'paidAt', 'startDate', 'endDate', 'expiresAt', 'periodStart', 'periodEnd',
  'balanceAfter',
];

// ---------------------------------------------------------------------------

export function retentionUidHash(uid: string): string {
  const salt = process.env.RETENTION_SALT || FALLBACK_RETENTION_SALT;
  return crypto.createHash('sha256').update(`${salt}:${uid}`).digest('hex');
}

export interface DeletionReport {
  documents: number;
  anonymised: number;
  files: number;
  retained: number;
  failures: string[];
}

type Ref = FirebaseFirestore.DocumentReference;

async function removeDoc(ref: Ref, recursive: boolean): Promise<number> {
  const snap = await ref.get();
  if (recursive) {
    // recursiveDelete also removes subcollections of a doc that does not exist.
    await db().recursiveDelete(ref);
  } else if (snap.exists) {
    await ref.delete();
  }
  return snap.exists ? 1 : 0;
}

async function pagedQuery(
  q: FirebaseFirestore.Query,
  each: (docs: FirebaseFirestore.QueryDocumentSnapshot[]) => Promise<void>,
): Promise<number> {
  let n = 0;
  // Re-query each round: every page is removed/rewritten, so the next query
  // returns what is left (resumable without offsets).
  for (let guard = 0; guard < 100000; guard++) {
    const snap = await q.limit(PAGE).get();
    if (snap.empty) break;
    await each(snap.docs);
    n += snap.size;
    if (snap.size < PAGE) break;
  }
  return n;
}

async function deleteQuery(q: FirebaseFirestore.Query, recursive: boolean): Promise<number> {
  return pagedQuery(q, async (docs) => {
    if (recursive) {
      for (const d of docs) await db().recursiveDelete(d.ref);
      return;
    }
    const b = db().batch();
    docs.forEach((d) => b.delete(d.ref));
    await b.commit();
  });
}

function pickFinance(data: FirebaseFirestore.DocumentData): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const k of FINANCE_FIELDS) {
    const v = data[k];
    if (v === undefined || v === null) continue;
    if (['string', 'number', 'boolean'].includes(typeof v) || v instanceof admin.firestore.Timestamp) {
      // Never carry something that looks like an email address.
      if (typeof v === 'string' && v.includes('@')) continue;
      out[k] = v;
    }
  }
  return out;
}

async function retainFinanceDocs(collection: string, docs: FirebaseFirestore.DocumentSnapshot[], uid: string) {
  const b = db().batch();
  const now = Date.now();
  const uidHash = retentionUidHash(uid);
  // Doc ids may embed the uid (coinBalances/{uid}, `${uid}_...`): pseudonymise.
  const safe = (id: string) => id.split(uid).join(`u_${uidHash.slice(0, 24)}`);
  for (const d of docs) {
    if (!d.exists) continue;
    b.set(db().collection(RETENTION_FINANCE).doc(`${collection}__${safe(d.id)}`), {
      ...pickFinance(d.data() || {}),
      uidHash,
      saltSource: process.env.RETENTION_SALT ? 'env' : 'fallback',
      sourceCollection: collection,
      sourceDocId: safe(d.id),
      retainedAt: admin.firestore.Timestamp.fromMillis(now),
      retainUntil: admin.firestore.Timestamp.fromMillis(now + FIVE_YEARS_MS),
      legalBasis: 'tax/bookkeeping retention (GDPR 17(3)(b), LGPD 16 I)',
    });
    b.delete(d.ref);
  }
  await b.commit();
}

/** Parse a Firebase Storage download URL / gs:// URL into an object path. */
export function storagePathFromUrl(url: unknown): string | null {
  if (typeof url !== 'string' || !url) return null;
  try {
    if (url.startsWith('gs://')) {
      const rest = url.slice(5);
      return rest.slice(rest.indexOf('/') + 1) || null;
    }
    const u = new URL(url);
    const m = u.pathname.match(/\/o\/([^/]+)$/);
    if (m) return decodeURIComponent(m[1]);
    // storage.googleapis.com/<bucket>/<path>
    if (u.hostname === 'storage.googleapis.com') {
      const parts = u.pathname.split('/').filter(Boolean);
      return parts.slice(1).map(decodeURIComponent).join('/') || null;
    }
  } catch {
    /* not a URL */
  }
  return null;
}

/**
 * Message fields that carry (a copy of) the author's words: the body, its
 * stored translations, captions and previews. Cleared when the author deletes
 * their account.
 */
export const MESSAGE_TEXT_FIELDS = [
  'text', 'caption', 'originalContent', 'translatedContent', 'translatedText',
  'translation', 'translations', 'detectedLanguage', 'preview',
];

const MEDIA_FIELDS = ['imageUrl', 'mediaUrl', 'voiceUrl', 'audioUrl', 'videoUrl', 'thumbnailUrl', 'fileUrl', 'gifUrl', 'stickerUrl'];

async function anonymiseGroup(group: string, field: string, uid: string, report: DeletionReport, topLevelOnly = false) {
  const bucket = admin.storage().bucket();
  // Collection-group scope needs the fieldOverride in firestore.indexes.json
  // (messages.senderId, COLLECTION_GROUP) in production.
  const base = topLevelOnly ? db().collection(group) : db().collectionGroup(group);
  report.anonymised += await pagedQuery(
    base.where(field, '==', uid),
    async (docs) => {
      const b = db().batch();
      const toDelete: string[] = [];
      for (const d of docs) {
        const data = d.data();
        const upd: Record<string, unknown> = {
          [field]: TOMBSTONE,
          senderName: admin.firestore.FieldValue.delete(),
          senderPhotoUrl: admin.firestore.FieldValue.delete(),
          senderPhoto: admin.firestore.FieldValue.delete(),
          senderNickname: admin.firestore.FieldValue.delete(),
          anonymisedAt: TS(),
          deletedAuthor: true,
          // The words go too (owner decision): body + every stored translation.
          content: '',
        };
        for (const f of MESSAGE_TEXT_FIELDS) {
          if (data[f] !== undefined) upd[f] = admin.firestore.FieldValue.delete();
        }
        const urls: unknown[] = [];
        for (const f of MEDIA_FIELDS) {
          if (data[f] !== undefined) {
            urls.push(data[f]);
            upd[f] = admin.firestore.FieldValue.delete();
          }
        }
        if (data.metadata && typeof data.metadata === 'object') {
          for (const f of MEDIA_FIELDS) urls.push(data.metadata[f]);
          upd.metadata = admin.firestore.FieldValue.delete();
        }
        const type = typeof data.type === 'string' ? data.type : 'text';
        if (type !== 'text' && type !== 'system') {
          // Media / location / album share: the content IS the payload.
          urls.push(data.content);
          upd.type = 'text';
          upd.mediaRemoved = true;
        } else if (urls.some(Boolean)) {
          upd.mediaRemoved = true;
        }
        for (const u of urls) {
          const p = storagePathFromUrl(u);
          if (p && SHARED_MEDIA_PREFIXES.some((pre) => p.startsWith(pre))) toDelete.push(p);
        }
        b.update(d.ref, upd);
      }
      await b.commit();
      for (const p of toDelete) {
        try {
          await bucket.file(p).delete({ ignoreNotFound: true });
          report.files += 1;
        } catch (e) {
          report.failures.push(`storage:${p}`);
        }
      }
    },
  );
}

/** Deep-replace the uid (see the 'scrub' inventory kind). */
export function scrubValue(v: any, uid: string, dropFromArrays: boolean): any {
  if (v === uid) return TOMBSTONE;
  if (Array.isArray(v)) {
    const arr = dropFromArrays ? v.filter((x) => x !== uid) : v;
    return arr.map((x) => scrubValue(x, uid, dropFromArrays));
  }
  if (v && typeof v === 'object' && v.constructor === Object) {
    const out: Record<string, any> = {};
    for (const [k, x] of Object.entries(v)) {
      if (k === uid) continue;
      out[k] = scrubValue(x, uid, dropFromArrays);
    }
    return out;
  }
  return v; // Timestamps, GeoPoints, refs, primitives
}

/**
 * A `lastMessage` preview (conversations / groups) written by the deleted user
 * keeps its timestamps but loses the words, like the message itself.
 */
export function clearDeletedAuthorPreview(doc: Record<string, any>): void {
  // Group / community docs keep a flat preview string + its sender id.
  if ((doc.lastSenderId === TOMBSTONE || doc.lastMessageSenderId === TOMBSTONE) &&
      typeof doc.lastMessagePreview === 'string') {
    doc.lastMessagePreview = '';
  }
  const lm = doc.lastMessage;
  if (!lm || typeof lm !== 'object' || Array.isArray(lm) || lm.senderId !== TOMBSTONE) return;
  for (const f of MESSAGE_TEXT_FIELDS) delete lm[f];
  for (const f of MEDIA_FIELDS) delete lm[f];
  if (typeof lm.content === 'string') lm.content = '';
  if (lm.type !== undefined && lm.type !== 'system') lm.type = 'text';
  lm.deletedAuthor = true;
}

async function scrubQuery(
  q: FirebaseFirestore.Query,
  uid: string,
  dropFromArrays: boolean,
  deleteSub?: string,
): Promise<number> {
  let n = 0;
  // A scrubbed doc no longer matches, so re-querying is the resume mechanism.
  for (let guard = 0; guard < 100000; guard++) {
    const snap = await q.limit(PAGE).get();
    if (snap.empty) break;
    for (const d of snap.docs) {
      await db().runTransaction(async (tx) => {
        const cur = await tx.get(d.ref);
        if (!cur.exists) return;
        const data = cur.data()!;
        const scrubbed = scrubValue(data, uid, dropFromArrays || data.isGroup === true);
        clearDeletedAuthorPreview(scrubbed);
        scrubbed.participantDeletedAt = TS();
        tx.set(d.ref, scrubbed);
        if (deleteSub) tx.delete(d.ref.collection(deleteSub).doc(uid));
      });
    }
    n += snap.size;
    if (snap.size < PAGE) break;
  }
  return n;
}

async function removeGroupMembership(group: string, field: string, counter: string | undefined, uid: string) {
  return pagedQuery(db().collectionGroup(group).where(field, '==', uid), async (docs) => {
    for (const d of docs) {
      const parent = d.ref.parent.parent;
      // Transaction: delete + decrement exactly once even if two runs race.
      await db().runTransaction(async (tx) => {
        const cur = await tx.get(d.ref);
        if (!cur.exists) return;
        const p = counter && parent ? await tx.get(parent) : null;
        tx.delete(d.ref);
        if (p?.exists) tx.update(parent!, { [counter!]: admin.firestore.FieldValue.increment(-1) });
      });
    }
  });
}

/** Deletes every object under [prefix] in [bucketName] (missing bucket = nothing). */
async function deletePrefix(bucketName: string | undefined, prefix: string): Promise<number> {
  const bucket = bucketName ? admin.storage().bucket(bucketName) : admin.storage().bucket();
  let files: any[] = [];
  try {
    [files] = await bucket.getFiles({ prefix });
  } catch (e: any) {
    // A backup bucket that was never created holds nothing to delete.
    if (bucketName && (e?.code === 404 || /not ?found|does not exist/i.test(String(e?.message)))) return 0;
    throw e;
  }
  for (const f of files) await f.delete({ ignoreNotFound: true });
  return files.length;
}

/** The user's own support tickets: messages (both sides), attachments, chat. */
async function removeSupportChats(uid: string, report: DeletionReport) {
  report.documents += await pagedQuery(db().collection('support_chats').where('userId', '==', uid), async (chats) => {
    for (const c of chats) {
      report.documents += await deleteQuery(
        db().collection('support_messages').where('conversationId', '==', c.id),
        false,
      );
      report.files += await deletePrefix(undefined, `support_attachments/${c.id}/`);
      await db().recursiveDelete(c.ref);
    }
  });
}

/** Removes everything in the inventory except profiles/{uid} and users/{uid}. */
async function runInventory(uid: string, report: DeletionReport) {
  const step = async (label: string, fn: () => Promise<void>) => {
    try {
      await fn();
    } catch (e: any) {
      report.failures.push(label);
      console.error(`accountDeletion: ${label} failed for ${uid}`, e?.message || e);
    }
  };

  // Stripe customer id, for the follow-up worker, BEFORE the docs disappear.
  let stripeCustomerId: string | null = null;
  let stripeTestCustomerId: string | null = null;
  await step('followup:read', async () => {
    for (const path of [`stripe_customers/${uid}`, `profiles/${uid}`, `users/${uid}`]) {
      const d = (await db().doc(path).get()).data();
      stripeCustomerId = stripeCustomerId || d?.customerId || d?.stripeCustomerId || null;
      stripeTestCustomerId = stripeTestCustomerId || d?.testCustomerId || d?.stripeTestCustomerId || null;
    }
  });

  // Identity documents: 30-day fraud retention (existing policy).
  await step(`id_documents/${uid}`, async () => {
    report.files += await retainIdDocumentsOnAccountDeletion(uid);
  });

  // Follow graph: one bounded round inline; a queued job finishes the rest.
  // Runs before the doc deletions so edges are removed WITH their mirrors
  // (business_followers/{uid}/followers/* and user_business_following/{uid}).
  await step('follow_graph', async () => {
    const r = await removeFollowGraphRound(
      { db: db(), increment: (n: number) => admin.firestore.FieldValue.increment(n) },
      uid,
      { deadlineMs: Date.now() + 60_000 },
    );
    if (!r.done) await enqueueFollowGraphCleanup(db(), uid);
  });

  // Money first (copy, then delete), then owned docs, then shared containers,
  // then message anonymisation (after the user's own support threads are
  // gone), then Storage.
  const order: InventoryEntry['kind'][] = [
    'finance', 'doc', 'path', 'idPrefix', 'query', 'supportChats', 'group',
    'scrub', 'arrayRemove', 'replaceField', 'anonymise', 'storage',
  ];
  for (const kind of order) {
    for (const e of ACCOUNT_DATA_INVENTORY.filter((x) => x.kind === kind)) {
      switch (e.kind) {
        case 'doc':
          await step(`${e.collection}/${uid}`, async () => {
            report.documents += await removeDoc(db().collection(e.collection).doc(uid), !!e.recursive);
          });
          break;
        case 'path':
          await step(e.path, async () => {
            report.documents += await removeDoc(db().doc(e.path.replace('{uid}', uid)), !!e.recursive);
          });
          break;
        case 'query':
          await step(`${e.collection}.${e.field}`, async () => {
            const qq = db().collection(e.collection).where(e.field, e.arrayContains ? 'array-contains' : '==', uid);
            report.documents += await deleteQuery(qq, !!e.recursive);
          });
          break;
        case 'idPrefix':
          await step(`${e.collection}/${uid}_*`, async () => {
            const qq = db()
              .collection(e.collection)
              .orderBy(admin.firestore.FieldPath.documentId())
              .startAt(`${uid}_`)
              .endAt(`${uid}_`);
            report.documents += await deleteQuery(qq, false);
          });
          break;
        case 'supportChats':
          await step('support_chats', () => removeSupportChats(uid, report));
          break;
        case 'group':
          await step(`group:${e.group}.${e.field}`, async () => {
            report.documents += await removeGroupMembership(e.group, e.field, e.parentCounter, uid);
          });
          break;
        case 'finance':
          await step(`finance:${e.collection}${e.byDocId ? '/{uid}' : '.' + e.field}`, async () => {
            if (e.byDocId) {
              const s = await db().collection(e.collection).doc(uid).get();
              if (s.exists) {
                await retainFinanceDocs(e.collection, [s], uid);
                // Its subcollections (if any) carry no bookkeeping data we keep.
                await db().recursiveDelete(s.ref);
                report.retained += 1;
              }
              return;
            }
            report.retained += await pagedQuery(
              db().collection(e.collection).where(e.field!, '==', uid),
              (ds) => retainFinanceDocs(e.collection, ds, uid),
            );
          });
          break;
        case 'scrub':
          await step(`scrub:${e.collection}.${e.field}`, async () => {
            const qq = db().collection(e.collection).where(e.field, e.arrayContains ? 'array-contains' : '==', uid);
            report.anonymised += await scrubQuery(qq, uid, !!e.dropFromArrays, e.deleteSub);
          });
          break;
        case 'arrayRemove':
          await step(`arrayRemove:${e.collection}.${e.field}`, async () => {
            report.anonymised += await pagedQuery(
              db().collection(e.collection).where(e.field, 'array-contains', uid),
              async (ds) => {
                const b = db().batch();
                ds.forEach((d) => b.update(d.ref, { [e.field]: admin.firestore.FieldValue.arrayRemove(uid) }));
                await b.commit();
              },
            );
          });
          break;
        case 'replaceField':
          await step(`replaceField:${e.collection}.${e.field}`, async () => {
            report.anonymised += await pagedQuery(
              db().collection(e.collection).where(e.field, '==', uid),
              async (ds) => {
                const b = db().batch();
                ds.forEach((d) => b.update(d.ref, { [e.field]: TOMBSTONE }));
                await b.commit();
              },
            );
          });
          break;
        case 'anonymise':
          await step(`anonymise:${e.group}.${e.field}`, () => anonymiseGroup(e.group, e.field, uid, report, !!e.topLevelOnly));
          break;
        case 'storage': {
          const prefix = e.prefix ? `${e.prefix}/${uid}/` : `${uid}/`;
          const buckets: Array<string | undefined> = e.buckets === 'backup' ? BACKUP_BUCKETS() : [undefined];
          for (const bn of buckets) {
            await step(`storage:${bn ?? 'default'}:${prefix}`, async () => {
              report.files += await deletePrefix(bn, prefix);
            });
          }
          break;
        }
      }
    }
  }

  // External processors: queued, never called from here.
  await step('followup:enqueue', async () => {
    await db().collection(DELETION_FOLLOWUPS).doc(uid).set(
      {
        // TODO(P2-7): a worker deletes the Stripe customer(s) and requests
        // GA4 / Crashlytics user deletion, then deletes this doc.
        ...(stripeCustomerId ? { stripeCustomerId } : {}),
        ...(stripeTestCustomerId ? { stripeTestCustomerId } : {}),
        stripe: !!(stripeCustomerId || stripeTestCustomerId),
        analytics: true,
        crashlytics: true,
        status: 'pending',
        createdAt: TS(),
      },
      { merge: true },
    );
  });
}

/** Legacy ledger subcollection coinBalances/{uid}/coinTransactions. */
async function retainSubcollectionLedgers(uid: string, report: DeletionReport) {
  const col = db().collection('coinBalances').doc(uid).collection('coinTransactions');
  report.retained += await pagedQuery(col, (ds) => retainFinanceDocs('coinBalances.coinTransactions', ds, uid));
}

export type DeletionSource = 'app_callable' | 'web_email_link' | 'web_id_token' | 'auth_trigger';

/**
 * Deletes (or retains/anonymises, per the policy above) all data of [uid].
 * Returns the report; never throws. Does NOT touch the Auth user.
 */
export async function deleteAccountData(uid: string, source: DeletionSource): Promise<DeletionReport> {
  const report: DeletionReport = { documents: 0, anonymised: 0, files: 0, retained: 0, failures: [] };
  if (!uid || typeof uid !== 'string' || uid.includes('/')) {
    report.failures.push('invalid_uid');
    return report;
  }

  try {
    await retainSubcollectionLedgers(uid, report);
  } catch (e) {
    report.failures.push('finance:coinBalances.subcollections');
  }
  await runInventory(uid, report);

  // Last: users/{uid}, then profiles/{uid}. Deleting the profile fires
  // onProfileDeleted, which (for old app versions) also deletes the Auth user;
  // while a server deletion is running it leaves Auth alone (deletion_jobs).
  for (const c of ['users', 'profiles']) {
    if (report.failures.length > 0 && source !== 'auth_trigger') break; // keep the account usable
    try {
      report.documents += await removeDoc(db().collection(c).doc(uid), true);
    } catch (e) {
      report.failures.push(`${c}/${uid}`);
    }
  }
  return report;
}

async function writeReceipt(uid: string, report: DeletionReport, source: DeletionSource) {
  const ref = db().collection(DELETION_RECEIPTS).doc(uid);
  const existing = (await ref.get()).data();
  if (existing && source === 'auth_trigger' && existing.source && existing.source !== 'auth_trigger') {
    // The Auth trigger re-sweeping after a server deletion: keep the original
    // receipt, record the sweep.
    await ref.set(
      { sweptAt: TS(), sweepFailures: report.failures, sweepDocumentsDeleted: report.documents },
      { merge: true },
    );
    return;
  }
  // Same shape as before (+ source, retained).
  await ref.set({
    deletedAt: TS(),
    documentsDeleted: report.documents,
    messagesAnonymised: report.anonymised,
    filesDeleted: report.files,
    financeRecordsRetained: report.retained,
    failures: report.failures,
    source,
  });
}

export class AccountDeletionIncompleteError extends Error {
  constructor(public report: DeletionReport) {
    super(`account deletion incomplete: ${report.failures.join(', ')}`);
  }
}

/**
 * Full deletion for the server-initiated paths (app callable, website):
 * data first, Auth user LAST, and only if every data step succeeded.
 * Throws AccountDeletionIncompleteError otherwise (account left signed-in-able,
 * profile/users docs left in place, deletion_jobs/{uid} records the failures).
 */
export async function deleteAccountCompletely(
  uid: string,
  opts: { source: Exclude<DeletionSource, 'auth_trigger'> },
): Promise<DeletionReport> {
  const jobRef = db().collection(DELETION_JOBS).doc(uid);
  await jobRef.set({ status: 'running', source: opts.source, startedAt: TS(), failures: [] }, { merge: true });

  const report = await deleteAccountData(uid, opts.source);
  if (report.failures.length > 0) {
    await jobRef.set({ status: 'failed', failures: report.failures, failedAt: TS() }, { merge: true });
    console.error(`accountDeletion: INCOMPLETE for ${uid}`, report.failures);
    throw new AccountDeletionIncompleteError(report);
  }

  // Receipt BEFORE the Auth delete, so the Auth trigger sees it and only sweeps.
  await writeReceipt(uid, report, opts.source);
  try {
    await admin.auth().deleteUser(uid);
  } catch (e: any) {
    if (e?.code !== 'auth/user-not-found') {
      await db().collection(DELETION_RECEIPTS).doc(uid).delete().catch(() => undefined);
      await jobRef.set({ status: 'failed', failures: ['auth'], failedAt: TS() }, { merge: true });
      throw new AccountDeletionIncompleteError({ ...report, failures: ['auth'] });
    }
  }
  await jobRef.delete();
  console.log(
    `accountDeletion: done for ${uid} via ${opts.source} - ${report.documents} docs, ` +
      `${report.anonymised} anonymised, ${report.files} files, ${report.retained} finance rows retained`,
  );
  return report;
}

/** Auth onDelete path (account already gone from Auth). Never throws. */
export async function sweepDeletedAccount(uid: string): Promise<DeletionReport> {
  const report = await deleteAccountData(uid, 'auth_trigger');
  try {
    await writeReceipt(uid, report, 'auth_trigger');
  } catch (e) {
    console.error('accountDeletion: could not write receipt', e);
  }
  if (report.failures.length > 0) {
    console.error(`onUserDeletedCleanup: INCOMPLETE for ${uid} - ${report.failures.length} failures`, report.failures);
  }
  return report;
}

/** True while a server deletion owns the Auth deletion for [uid]. */
export async function serverDeletionRunning(uid: string): Promise<boolean> {
  const d = (await db().collection(DELETION_JOBS).doc(uid).get()).data();
  if (d?.status !== 'running') return false;
  // A run that crashed/timed out (540 s max) must not block the old path forever.
  const started = d.startedAt?.toMillis?.() ?? 0;
  return Date.now() - started < 15 * 60 * 1000;
}
