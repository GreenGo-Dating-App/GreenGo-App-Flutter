/**
 * Private-content warning acknowledgement (proof of acceptance).
 *
 * Terms §16.9(d): the first time a user opens another user's private photo,
 * private-album content or chat media (images / videos received in 1:1 and
 * group chats) the app shows ONE blocking warning (one acceptance covers
 * all three): screenshots / recordings / saving / sharing without
 * consent are forbidden by the Terms and by law, misuse leads to suspension,
 * evidence preservation, reporting and legal action. The
 * content opens only after this callable stored the acceptance.
 *
 * Proof lives in a SERVER-ONLY collection (users/{uid} is owner-writable, so
 * it cannot prove anything):
 *
 *   legal_acknowledgements/{uid}/items/{autoId}
 *     kind            'private_content_warning'
 *     uid
 *     warningVersion  e.g. 'pcw-1' (bumping it re-shows the warning)
 *     termsVersion    Terms of Service version that applies to the account
 *                     (termsVersionForAccount: TERMS_VERSION, or the previous
 *                     one for accounts created before it took effect), §16.9(d)
 *     acceptedAt      server timestamp
 *     locale, platform, appVersion       (as reported by the client)
 *     ip, userAgent                       (from the HTTPS request)
 *     textHash        sha256(`${warningVersion}\n${text}`), hex - the exact
 *                     localized text the user saw (sent by the client)
 *     textLength
 *
 * Firestore rules: the owner may read their own items; no client writes.
 * Records are append-only (never updated or deleted by this code).
 *
 * Deploy: acknowledgePrivateContentWarning
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { createHash } from 'crypto';
import '../shared/firebaseAdmin';
import { AppError, handleError } from '../shared/utils';
import { TERMS_VERSION, termsVersionForAccount } from '../shared/legalVersions';

export const ACK_COLLECTION = 'legal_acknowledgements';
export const ACK_KIND = 'private_content_warning';
/** Versions the server accepts. Add the new one here when the text changes. */
export const PRIVATE_CONTENT_WARNING_VERSIONS: readonly string[] = ['pcw-1'];
/**
 * Current Terms of Service version, recorded with every acceptance (§16.9(d):
 * "the version of these Terms"). One shared constant, kept equal to the
 * app's kTermsVersion by __tests__/unit/legalVersions.test.ts.
 */
export { TERMS_VERSION };
/** Per user and version: more records than this are not written again. */
export const MAX_ACKS_PER_VERSION = 20;

const PLATFORMS = new Set(['android', 'ios', 'web', 'macos', 'windows', 'linux', 'fuchsia', 'unknown']);
const LOCALE_RE = /^[A-Za-z]{2,3}([_-][A-Za-z0-9]{2,8}){0,2}$/;

export function warningTextHash(version: string, text: string): string {
  return createHash('sha256').update(`${version}\n${text}`, 'utf8').digest('hex');
}

function clip(v: unknown, max: number): string | null {
  if (typeof v !== 'string') return null;
  const s = v.trim();
  return s ? s.slice(0, max) : null;
}

function requestMeta(raw: any): { ip: string | null; userAgent: string | null } {
  if (!raw) return { ip: null, userAgent: null };
  const headers = raw.headers || {};
  const fwd = typeof headers['x-forwarded-for'] === 'string'
    ? headers['x-forwarded-for'].split(',')[0].trim()
    : null;
  return {
    ip: clip(raw.ip || fwd, 64),
    userAgent: clip(headers['user-agent'], 512),
  };
}

export async function recordPrivateContentWarningAck(request: Pick<CallableRequest, 'auth' | 'data' | 'rawRequest'>) {
  const uid = request.auth?.uid;
  if (!uid) throw new AppError('unauthenticated', 'Sign in required', 401);
  const data = (request.data ?? {}) as Record<string, unknown>;

  const warningVersion = typeof data.warningVersion === 'string' ? data.warningVersion : '';
  if (!PRIVATE_CONTENT_WARNING_VERSIONS.includes(warningVersion)) {
    throw new AppError('invalid-argument', 'invalid_warning_version', 400);
  }
  const text = typeof data.text === 'string' ? data.text : '';
  if (text.trim().length < 50 || text.length > 20000) {
    throw new AppError('invalid-argument', 'invalid_text', 400);
  }
  const locale = clip(data.locale, 20);
  if (!locale || !LOCALE_RE.test(locale)) {
    throw new AppError('invalid-argument', 'invalid_locale', 400);
  }
  const platformIn = clip(data.platform, 20)?.toLowerCase() ?? 'unknown';
  const platform = PLATFORMS.has(platformIn) ? platformIn : 'unknown';
  const appVersion = clip(data.appVersion, 40);

  const db = admin.firestore();
  const items = db.collection(ACK_COLLECTION).doc(uid).collection('items');

  // Bounded: a client looping on the callable cannot grow the proof
  // collection forever. The existing proof stands.
  const existing = await items.where('warningVersion', '==', warningVersion).count().get();
  if (existing.data().count >= MAX_ACKS_PER_VERSION) {
    return { ok: true, warningVersion, recorded: false };
  }

  const { ip, userAgent } = requestMeta(request.rawRequest);
  // The version that applies to this account (5.3.0 took effect for new
  // accounts first): Auth creation time, one call per acknowledgement.
  let createdMs: number | null = null;
  try {
    createdMs = Date.parse((await admin.auth().getUser(uid)).metadata.creationTime);
  } catch {
    // unknown: the current version
  }
  const ref = items.doc();
  // create(): fails instead of overwriting - the record is append-only.
  await ref.create({
    kind: ACK_KIND,
    uid,
    warningVersion,
    termsVersion: termsVersionForAccount(createdMs, Date.now()),
    acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
    locale,
    platform,
    appVersion,
    ip,
    userAgent,
    textHash: warningTextHash(warningVersion, text),
    textLength: text.length,
  });
  return { ok: true, warningVersion, recorded: true, ackId: ref.id };
}

export const acknowledgePrivateContentWarning = onCall({ memory: '512MiB' }, async (request) => {
  try {
    return await recordPrivateContentWarningAck(request);
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    throw handleError(e);
  }
});
