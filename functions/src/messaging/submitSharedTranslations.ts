/**
 * submitSharedTranslations — clients CONTRIBUTE their on-device translations
 * of PUBLIC content (events / attractions / experiences) to the shared
 * `translations/{id}` store, by consensus.
 *
 * Why: translateTexts translates cache misses server-side with the free
 * endpoint, but Cloud Functions IPs are rate-limited (429) quickly, so the app
 * often translates on the device instead — and that work was never shared.
 *
 * Trust model: a contribution becomes a shared translation only once TWO
 * DIFFERENT users independently submitted the SAME (whitespace / Unicode
 * normalised) translation of the same (target, text). One user alone can
 * never plant text. Until then the votes sit in
 * `translation_candidates/{id}` (server only, TTL on `expireAt`).
 *
 *   id = sharedTranslationId(target, text)   (same id as translations/{id})
 *   translation_candidates/{id} = {
 *     target, textHash: sha256(text),
 *     votes: { [sha256(normalised translation)]: { translation, uids[], at } },
 *     updatedAt, expireAt,
 *   }
 *
 * The original text is never stored (only its hash), like translations/{id}.
 *
 * Guard rails: signed-in, existing non-banned profile, valid target, ≤ 20
 * items per call, text/translation ≤ MAX_CHARS, per-user daily quota,
 * translations identical to the source rejected, prohibited language rejected
 * and links / contact info that the source does not contain rejected
 * (user_experiences/moderation.ts). Already-shared texts are a no-op.
 *
 * KNOWN LIMIT: the server cannot cheaply verify that a submitted text really
 * is public content (or even exists anywhere in the app). That is acceptable:
 * a translation is only ever served to someone who asks for EXACTLY that text
 * (the id is a hash of it), two distinct accounts must agree, moderation
 * filters abusive output, and the quota bounds volume. A single person with
 * two accounts can still agree with themselves — the same moderation and
 * quota apply, and `origin: 'consensus'` + `voters` on the stored doc let an
 * admin find and purge such entries.
 *
 * Chat translation is private and never comes here: the app only contributes
 * from TranslationService.translateShared (public content).
 */
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import '../shared/firebaseAdmin';
import { MAX_CHARS, TARGET_RE, sharedTranslationId } from './sharedTranslations';
import { containsLink, findContactInfo, findProhibitedTerms } from '../user_experiences/moderation';

const db = admin.firestore();

export const MAX_ITEMS = 20;
export const DAILY_SUBMIT_QUOTA = 500;
/** Distinct users needed before a translation is shared. */
export const CONSENSUS_USERS = 2;
/** Bounded doc size: at most this many uids per variant ... */
export const MAX_UIDS_PER_VARIANT = 5;
/** ... and this many competing variants per candidate. */
export const MAX_VARIANTS = 5;
const CANDIDATE_TTL_MS = 30 * 864e5;

// ─────────────────────────────────────────────────────────── pure helpers

/** NFC, trimmed, line endings unified, runs of spaces/tabs collapsed (newlines kept). */
export function cleanTranslation(s: string): string {
  return s
    .normalize('NFC')
    .replace(/\r\n?/g, '\n')
    .replace(/[^\S\n]+/g, ' ')
    .replace(/ *\n */g, '\n')
    .trim();
}

/** Comparison form: NFC, trimmed, ALL whitespace collapsed to one space. */
export function normaliseForVote(s: string): string {
  return s.normalize('NFC').replace(/\s+/g, ' ').trim();
}

export function voteKey(translation: string): string {
  return crypto.createHash('sha256').update(normaliseForVote(translation), 'utf8').digest('hex');
}

/** Same text as the source (ignoring whitespace/case) = nothing translated. */
export function sameAsSource(text: string, translation: string): boolean {
  return normaliseForVote(text).toLowerCase() === normaliseForVote(translation).toLowerCase();
}

/**
 * Why [translation] of [text] must be dropped, or null when acceptable.
 * Links / contact info are only allowed when the source already has them.
 */
export function rejectReason(text: string, translation: string): string | null {
  if (normaliseForVote(translation).length === 0) return 'empty';
  if (sameAsSource(text, translation)) return 'same_as_source';
  if (findProhibitedTerms(translation).length > 0) return 'prohibited_terms';
  if (containsLink(translation) && !containsLink(text)) return 'contains_link';
  const srcContact = new Set(findContactInfo(text));
  if (findContactInfo(translation).some((k) => !srcContact.has(k))) return 'contact_info';
  return null;
}

export interface Variant {
  translation: string;
  uids: string[];
  at: number;
}

export interface Candidate {
  target: string;
  textHash: string;
  votes: Record<string, Variant>;
}

export interface VoteOutcome {
  candidate: Candidate;
  /** The agreed translation once CONSENSUS_USERS distinct users agree. */
  consensus: { translation: string; uids: string[] } | null;
}

/**
 * Adds [uid]'s vote for [translation]. A user has ONE vote per candidate: a
 * new, different translation moves their vote. Pure — no Firestore.
 */
export function applyVote(
  existing: Candidate | null | undefined,
  vote: { uid: string; target: string; textHash: string; translation: string; now: number },
): VoteOutcome {
  const votes: Record<string, Variant> = {};
  for (const [k, v] of Object.entries(existing?.votes ?? {})) {
    if (!v || typeof v.translation !== 'string' || !Array.isArray(v.uids)) continue;
    const uids = v.uids.filter((u) => typeof u === 'string' && u !== vote.uid);
    if (uids.length > 0) votes[k] = { translation: v.translation, uids, at: Number(v.at) || 0 };
  }

  const key = voteKey(vote.translation);
  const current = votes[key];
  if (current) {
    current.uids = [...current.uids, vote.uid].slice(-MAX_UIDS_PER_VARIANT);
    current.at = vote.now;
  } else {
    // Make room: evict the oldest single-voter variant (never one with support).
    if (Object.keys(votes).length >= MAX_VARIANTS) {
      const evict = Object.entries(votes)
        .filter(([, v]) => v.uids.length < CONSENSUS_USERS)
        .sort(([, a], [, b]) => a.at - b.at)[0];
      if (evict) delete votes[evict[0]];
    }
    if (Object.keys(votes).length < MAX_VARIANTS) {
      votes[key] = { translation: cleanTranslation(vote.translation), uids: [vote.uid], at: vote.now };
    }
  }

  const candidate: Candidate = { target: vote.target, textHash: vote.textHash, votes };
  const winner = votes[key];
  const consensus = winner && new Set(winner.uids).size >= CONSENSUS_USERS
    ? { translation: winner.translation, uids: [...new Set(winner.uids)] }
    : null;
  return { candidate, consensus };
}

/** Banned / suspended / deleted accounts cannot contribute. */
function isBlocked(p: Record<string, unknown>): boolean {
  const status = String(p.accountStatus || 'active').toLowerCase();
  return p.isBanned === true || ['banned', 'suspended', 'deleted'].includes(status);
}

// ─────────────────────────────────────────────────────────── callable

interface Req {
  target?: unknown;
  items?: unknown;
}

interface Item {
  text: string;
  translation: string;
  id: string;
}

export const submitSharedTranslations = onCall<Req>(
  { memory: '512MiB', timeoutSeconds: 60 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required');

    const target = typeof request.data?.target === 'string' ? request.data.target : '';
    if (!TARGET_RE.test(target)) throw new HttpsError('invalid-argument', 'Bad target');
    const raw = Array.isArray(request.data?.items) ? request.data.items : [];
    if (raw.length > MAX_ITEMS) throw new HttpsError('invalid-argument', `At most ${MAX_ITEMS} items`);

    const profile = await db.collection('users').doc(uid).get();
    if (!profile.exists || isBlocked(profile.data() ?? {})) {
      throw new HttpsError('permission-denied', 'Not allowed');
    }

    // Validate + moderate; one item per id.
    const byId = new Map<string, Item>();
    let rejected = 0;
    for (const r of raw) {
      const o = (r && typeof r === 'object' ? r : {}) as Record<string, unknown>;
      const text = o.text;
      const translation = o.translation;
      if (
        typeof text !== 'string' || typeof translation !== 'string' ||
        text.trim().length === 0 || text.length > MAX_CHARS || translation.length > MAX_CHARS ||
        rejectReason(text, translation) !== null
      ) {
        rejected++;
        continue;
      }
      const id = sharedTranslationId(target, text);
      if (!byId.has(id)) byId.set(id, { text, translation, id });
    }
    let items = [...byId.values()];
    if (items.length === 0) return { accepted: 0, shared: 0, rejected, existing: 0 };

    // Already shared → nothing to do (and not charged to the quota).
    const snaps = await db.getAll(...items.map((it) => db.collection('translations').doc(it.id)));
    const existingIds = new Set(items.filter((_, i) => snaps[i].exists).map((it) => it.id));
    items = items.filter((it) => !existingIds.has(it.id));
    if (items.length === 0) return { accepted: 0, shared: 0, rejected, existing: existingIds.size };

    // Per-user daily quota (separate counter from translateTexts' misses).
    const day = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const quotaRef = db.collection('translation_quota').doc(`${uid}_${day}_submit`);
    const allowed = await db.runTransaction(async (tx) => {
      const q = await tx.get(quotaRef);
      const used = (q.data()?.count as number) || 0;
      const n = Math.max(0, Math.min(items.length, DAILY_SUBMIT_QUOTA - used));
      if (n > 0) {
        tx.set(quotaRef, {
          count: used + n,
          uid,
          expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + 3 * 864e5),
        }, { merge: true });
      }
      return n;
    });
    items = items.slice(0, allowed);
    if (items.length === 0) {
      return { accepted: 0, shared: 0, rejected, existing: existingIds.size, quotaExceeded: true };
    }

    let shared = 0;
    await Promise.all(items.map(async (it) => {
      const transRef = db.collection('translations').doc(it.id);
      const candRef = db.collection('translation_candidates').doc(it.id);
      const textHash = crypto.createHash('sha256').update(it.text, 'utf8').digest('hex');
      try {
        const didShare = await db.runTransaction(async (tx) => {
          const [t, c] = [await tx.get(transRef), await tx.get(candRef)];
          if (t.exists) {
            if (c.exists) tx.delete(candRef);
            return false;
          }
          const now = Date.now();
          const { candidate, consensus } = applyVote(c.exists ? (c.data() as Candidate) : null, {
            uid, target, textHash, translation: it.translation, now,
          });
          if (consensus) {
            // Same shape translateTexts writes (clients read `translated`);
            // `source` stays the DETECTED-language field, unknown here.
            tx.set(transRef, {
              target,
              translated: consensus.translation,
              source: null,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              origin: 'consensus',
              voters: consensus.uids,
            });
            tx.delete(candRef);
            return true;
          }
          tx.set(candRef, {
            ...candidate,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            expireAt: admin.firestore.Timestamp.fromMillis(now + CANDIDATE_TTL_MS),
          });
          return false;
        });
        if (didShare) shared++;
      } catch (e) {
        console.warn('submitSharedTranslations: vote failed', it.id, e);
      }
    }));

    return { accepted: items.length, shared, rejected, existing: existingIds.size };
  },
);
