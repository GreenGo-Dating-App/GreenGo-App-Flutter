/**
 * translateCommunityTips — community Tips (language tip / cultural fact /
 * city tip / other) shown in the VIEWER's language, translated ONCE for
 * everyone and stored in the shared store `translations/{id}`.
 *
 *   request  { communityId, messageIds: string[] (<= 30), target }
 *   response { translations: Array<{ messageId, hash, text, sameLanguage } | null> }
 *            (same order as messageIds; null = not a tip of this community
 *             or not translated right now; text '' never returned)
 *
 *   id   = sharedTranslationId(target, tipText)  (same key as translateTexts,
 *          so the app reads hits straight from Firestore and only calls this
 *          for misses; identical text in two communities shares one entry)
 *   hash = sha256(tipText) hex — the app keys its device cache on
 *          messageId + hash + target, so an edited tip is translated again.
 *
 * Why not translateTexts: that callable accepts ANY text, so it doubles as a
 * free translation API (bounded only by a daily quota). Here the client sends
 * only message ids; the text is read server-side and must be a tip type of
 * THAT community. The client never supplies a text or a translation, so
 * nobody can plant a fake translation or translate arbitrary text.
 *
 * Consent: the VIEWER (caller) must have accepted the AI-processing notice
 * (requireTranslationConsent), else failed-precondition AI_CONSENT_REQUIRED.
 *
 * Visibility: signed-in only. Private communities (isPublic == false) also
 * require a non-banned member doc (or a platform moderator), which is stricter
 * than the message read rule.
 *
 * Cost: misses use the FREE Google endpoint (./freeTranslate, $0, rate
 * limited); every (text, language) is translated once globally. A per-user
 * daily miss quota bounds bursts. No trigger pre-translates on create (a
 * Firestore trigger cannot filter by type, so it would fire for every chat
 * message), translation happens on first view per language.
 */
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import '../shared/firebaseAdmin';
import { freeTranslateMany } from '../messaging/freeTranslate';
import { MAX_CHARS, TARGET_RE, sharedTranslationId } from '../messaging/sharedTranslations';
import { isAdminCaller, MODERATION_ROLES } from '../shared/adminAuth';
import { requireTranslationConsent } from '../shared/aiConsent';

const db = admin.firestore();

/** One visible page of tips per call. */
export const MAX_TIPS_PER_CALL = 30;
/** Translated misses per user per UTC day (cache hits are free). */
export const DAILY_TIP_MISS_QUOTA = 2000;
export const TIP_TYPES: readonly string[] = ['language_tip', 'cultural_fact', 'city_tip', 'other_tip'];
const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

export function tipTextHash(text: string): string {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

export interface TipTranslation {
  messageId: string;
  hash: string;
  text: string;
  sameLanguage: boolean;
}

interface Req {
  communityId?: unknown;
  messageIds?: unknown;
  target?: unknown;
}

async function assertCanRead(uid: string, auth: unknown, communityId: string): Promise<void> {
  const community = await db.collection('communities').doc(communityId).get();
  if (!community.exists) throw new HttpsError('not-found', 'Community not found');
  if (community.data()?.isPublic !== false) return;
  const member = await db.collection('communities').doc(communityId)
    .collection('members').doc(uid).get();
  if (member.exists && member.data()?.isBanned !== true) return;
  if (await isAdminCaller(auth as any, MODERATION_ROLES)) return;
  throw new HttpsError('permission-denied', 'Members only');
}

async function takeQuota(uid: string, n: number): Promise<boolean> {
  const day = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const quotaRef = db.collection('translation_quota').doc(`tips_${uid}_${day}`);
  return db.runTransaction(async (tx) => {
    const q = await tx.get(quotaRef);
    const used = (q.data()?.count as number) || 0;
    if (used + n > DAILY_TIP_MISS_QUOTA) return false;
    tx.set(quotaRef, {
      count: used + n,
      uid,
      expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + 3 * 864e5),
    }, { merge: true });
    return true;
  });
}

export const translateCommunityTips = onCall<Req>(
  { memory: '512MiB', timeoutSeconds: 60 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required');

    const d = request.data ?? {};
    const target = typeof d.target === 'string' ? d.target : '';
    if (!TARGET_RE.test(target)) throw new HttpsError('invalid-argument', 'Bad target');
    const communityId = typeof d.communityId === 'string' ? d.communityId : '';
    if (!ID_RE.test(communityId)) throw new HttpsError('invalid-argument', 'Bad communityId');
    if (!Array.isArray(d.messageIds)) throw new HttpsError('invalid-argument', 'messageIds required');
    const ids = d.messageIds as unknown[];
    if (ids.length > MAX_TIPS_PER_CALL) {
      throw new HttpsError('invalid-argument', `At most ${MAX_TIPS_PER_CALL} tips per call`);
    }
    if (!ids.every((x) => typeof x === 'string' && ID_RE.test(x))) {
      throw new HttpsError('invalid-argument', 'Bad messageId');
    }
    const messageIds = ids as string[];
    if (messageIds.length === 0) return { translations: [] };

    // Apple 5.1.2(i): the VIEWER asks for the translation, so the viewer's
    // account-level AI consent is required (shared/aiConsent.ts).
    await requireTranslationConsent(uid);

    await assertCanRead(uid, request.auth, communityId);

    // The tip texts come from Firestore, never from the client.
    const unique = [...new Set(messageIds)];
    const msgsRef = db.collection('communities').doc(communityId).collection('messages');
    const msgSnaps = await db.getAll(...unique.map((id) => msgsRef.doc(id)));
    const textOf = new Map<string, string>();
    msgSnaps.forEach((s, i) => {
      if (!s.exists) return;
      const m = s.data() ?? {};
      if (!TIP_TYPES.includes(m.type as string)) return;
      const content = typeof m.content === 'string' ? m.content.slice(0, MAX_CHARS) : '';
      if (content.trim().length === 0) return;
      textOf.set(unique[i], content);
    });

    const texts = [...new Set(textOf.values())];
    const translated = new Map<string, string>();
    if (texts.length > 0) {
      const tRefs = texts.map((t) => db.collection('translations').doc(sharedTranslationId(target, t)));
      const tSnaps = await db.getAll(...tRefs);
      const misses: string[] = [];
      tSnaps.forEach((s, i) => {
        const v = s.exists ? (s.data()?.translated as string | undefined) : undefined;
        if (v) translated.set(texts[i], v);
        else misses.push(texts[i]);
      });

      if (misses.length > 0 && (await takeQuota(uid, misses.length))) {
        const out = await freeTranslateMany(misses, target, {
          concurrency: 4,
          timeoutMs: 6000,
          deadlineMs: 20000,
        });
        const batch = db.batch();
        let writes = 0;
        misses.forEach((text, i) => {
          const t = out[i]?.text || '';
          if (!t) return;
          translated.set(text, t);
          batch.set(db.collection('translations').doc(sharedTranslationId(target, text)), {
            target,
            translated: t,
            source: out[i]?.detectedLanguage || null,
            origin: 'community_tip',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          writes++;
        });
        if (writes > 0) await batch.commit();
      }
    }

    const translations: (TipTranslation | null)[] = messageIds.map((messageId) => {
      const text = textOf.get(messageId);
      const t = text === undefined ? undefined : translated.get(text);
      if (text === undefined || !t) return null;
      return { messageId, hash: tipTextHash(text), text: t, sameLanguage: t === text };
    });
    return { translations };
  },
);
