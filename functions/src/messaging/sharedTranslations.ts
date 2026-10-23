/**
 * translateTexts — shared, persistent translations for PUBLIC content
 * (event / attraction / experience text). Each (target language, text) pair is
 * translated ONCE and stored in `translations/{id}`; every later viewer reads
 * the stored copy instead of translating again.
 *
 *   id = sha256(`${target}\u0000${text}`) hex — computed identically by the
 *   app (TranslationService.sharedTranslationId), so clients read hits
 *   directly from Firestore and only call this function for misses.
 *
 * Only this function writes translations (rules: get for signed-in users, no
 * list, no client writes), so nobody can plant a fake translation. The doc
 * stores the translated text, never the original. Private chat text never
 * goes through here.
 *
 * Consent: the caller (viewer) must have accepted the AI-processing notice
 * (requireTranslationConsent), else failed-precondition AI_CONSENT_REQUIRED.
 *
 * Guard rails: signed-in only, ≤ 50 texts per call, ≤ 5,000 chars each, and a
 * per-user daily quota of misses (cache hits are free).
 *
 * Misses are translated through the AI router (`translate_public`), at
 * most 4 requests in flight, retried with backoff. If the endpoint rate-limits
 * (429) or fails, the untranslated texts come back as '' (same response shape
 * as always), are not stored, and the app falls back to translating them on
 * the device. No dependency on the paid Cloud Translation API.
 */
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import '../shared/firebaseAdmin';
import { translate } from '../ai/router/router';
import { requireTranslationConsent } from '../shared/aiConsent';

const db = admin.firestore();

const MAX_TEXTS = 50;
export const MAX_CHARS = 5000;
const DAILY_MISS_QUOTA = 1500;

/** Must match TranslationService.normalizeLanguage targets used by the app. */
export const TARGET_RE = /^[a-z]{2}(-[A-Z]{2})?$/;

export function sharedTranslationId(target: string, text: string): string {
  return crypto.createHash('sha256').update(`${target}\u0000${text}`, 'utf8').digest('hex');
}

interface Req {
  texts?: unknown;
  target?: unknown;
}

export const translateTexts = onCall<Req>(
  { memory: '512MiB', timeoutSeconds: 60 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required');

    const target = typeof request.data?.target === 'string' ? request.data.target : '';
    if (!TARGET_RE.test(target)) throw new HttpsError('invalid-argument', 'Bad target');
    const raw = Array.isArray(request.data?.texts) ? request.data.texts : [];
    const texts = raw
      .filter((t): t is string => typeof t === 'string' && t.trim().length > 0)
      .slice(0, MAX_TEXTS)
      .map((t) => t.slice(0, MAX_CHARS));
    if (texts.length === 0) return { translations: [] as string[] };

    // Apple 5.1.2(i): the viewer must have allowed sending text to Google
    // (account-level AI consent; see shared/aiConsent.ts).
    await requireTranslationConsent(uid);

    const unique = [...new Set(texts)];
    const refs = unique.map((t) => db.collection('translations').doc(sharedTranslationId(target, t)));
    const snaps = await db.getAll(...refs);
    const result = new Map<string, string>();
    const misses: string[] = [];
    snaps.forEach((s, i) => {
      const v = s.exists ? (s.data()?.translated as string | undefined) : undefined;
      if (v) result.set(unique[i], v);
      else misses.push(unique[i]);
    });

    if (misses.length > 0) {
      // Per-user daily quota on translated misses.
      const day = new Date().toISOString().slice(0, 10).replace(/-/g, '');
      const quotaRef = db.collection('translation_quota').doc(`${uid}_${day}`);
      const allowed = await db.runTransaction(async (tx) => {
        const q = await tx.get(quotaRef);
        const used = (q.data()?.count as number) || 0;
        if (used + misses.length > DAILY_MISS_QUOTA) return false;
        tx.set(quotaRef, {
          count: used + misses.length,
          uid,
          expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + 3 * 864e5),
        }, { merge: true });
        return true;
      });

      if (allowed) {
        // `translate_public` route (admin panel): Qwen-MT, then the free
        // Google endpoint. Public texts only: no consent gate (version 0).
        const routed = await translate('translate_public', misses, target, { consentVersion: 0 }, {
          // Well inside the app's 30s callable timeout.
          deadlineMs: 20000,
        });
        const out = routed.items;
        const batch = db.batch();
        let writes = 0;
        misses.forEach((text, i) => {
          const translated = out[i]?.text || '';
          if (!translated) return;
          result.set(text, translated);
          batch.set(db.collection('translations').doc(sharedTranslationId(target, text)), {
            target,
            translated,
            source: out[i]?.detectedLanguage || null,
            provider: routed.providers[i] || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          writes++;
        });
        if (writes > 0) await batch.commit();
      }
    }

    // Same order as the request; '' = not translated (caller keeps original).
    return { translations: texts.map((t) => result.get(t) ?? '') };
  },
);
