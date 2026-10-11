/**
 * Marco Civil da Internet access logs (Lei 12.965/2014 art. 15; legal audit
 * BR-09). As an "application provider" GreenGo must keep the records of
 * access to the application - date and time of use from a given IP address -
 * for 6 months, under confidentiality, in a controlled environment, and
 * disclose them only under a court order.
 *
 * Store: `access_logs/{autoId}` (server-only; firestore.rules deny every
 * client, admins included). Each record:
 *   uid, event ('sign_up' | 'sign_in' | 'app_session'), ip, userAgent,
 *   provider (sign-in method, when known), source ('auth_blocking' |
 *   'callable'), port (always null, see below), at (server time), expireAt.
 * Retention: `expireAt` = 6 calendar months + 1 day after the event; a
 * Firestore TTL policy on access_logs.expireAt deletes them (TTL deletes
 * within ~24 h after expiry, so 6 months are always kept). Owner step, once:
 *   gcloud firestore fields ttls update expireAt \
 *     --collection-group=access_logs --enable-ttl --project=greengo-chat
 * (or deploy firestore.indexes.json, whose fieldOverrides declare it).
 * Account deletion does NOT remove them (RETENTION_STORES: legal obligation,
 * LGPD art. 16 I).
 *
 * SOURCE PORT: Marco Civil practice (and Decree 8.771/2016 / STJ case law for
 * CGNAT) expects the source port too, but it is NOT AVAILABLE on Firebase:
 * the TLS connection is terminated by Google's front end (Identity Toolkit /
 * Google Front End for Cloud Run), and neither the auth blocking event nor
 * the callable request exposes the client's source port. `port` is stored as
 * null so the gap is explicit in every record.
 *
 * Writers:
 *   - beforeUserCreated / beforeUserSignedIn blocking functions
 *     (`logAccessOnSignUp`, `logAccessOnSignIn`): event.ipAddress +
 *     event.userAgent from Identity Platform. They REQUIRE the project to be
 *     upgraded to Firebase Authentication with Identity Platform, and they
 *     must never block a sign-in: every failure is caught and logged, the
 *     write is bounded by a short timeout, and nothing is returned.
 *   - `logAccess` callable (fallback that works without Identity Platform,
 *     and also records app sessions): the app calls it at start and after
 *     each sign-in; the IP comes from the request. At most one record per
 *     user, event and minute (deterministic doc id) so a reconnect storm
 *     cannot flood the store.
 *
 * Deploy: logAccess, logAccessOnSignIn, logAccessOnSignUp (the last two only
 * after Identity Platform is enabled; then register them in Firebase console
 * > Authentication > Settings > Blocking functions if the deploy did not).
 */
import * as admin from 'firebase-admin';
import { onCall } from 'firebase-functions/v2/https';
import { beforeUserCreated, beforeUserSignedIn } from 'firebase-functions/v2/identity';
import type { AuthBlockingEvent } from 'firebase-functions/v2/identity';
import '../shared/firebaseAdmin';

export const ACCESS_LOGS = 'access_logs';

export type AccessEvent = 'sign_up' | 'sign_in' | 'app_session';

/** expireAt for an event at [at]: 6 calendar months + 1 day (UTC). */
export function accessLogExpiry(at: Date): Date {
  const d = new Date(at.getTime());
  const day = d.getUTCDate();
  d.setUTCDate(1);
  d.setUTCMonth(d.getUTCMonth() + 6);
  const lastDay = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)).getUTCDate();
  d.setUTCDate(Math.min(day, lastDay));
  return new Date(d.getTime() + 24 * 3600 * 1000);
}

const clip = (v: unknown, max: number): string | null =>
  typeof v === 'string' && v.trim() ? v.trim().slice(0, max) : null;

/** Plausible IPv4 / IPv6 literal (no ports, no garbage from headers). */
export function cleanIp(v: unknown): string | null {
  const s = clip(v, 64);
  if (!s) return null;
  const ip = s.replace(/^::ffff:/i, '');
  if (/^\d{1,3}(\.\d{1,3}){3}$/.test(ip)) return ip;
  if (/^[0-9a-f:]+$/i.test(ip) && ip.includes(':')) return ip.toLowerCase();
  return null;
}

/**
 * Client IP of a callable request. Cloud Run / Cloud Functions put the real
 * client address LAST in X-Forwarded-For (anything before it may have been
 * sent by the client itself), so the last valid entry wins; then the socket
 * address Express reports.
 */
export function requestIp(rawRequest: any): string | null {
  const xff = rawRequest?.headers?.['x-forwarded-for'];
  const header = Array.isArray(xff) ? xff.join(',') : xff;
  if (typeof header === 'string') {
    const parts = header.split(',').map((p) => p.trim()).filter(Boolean);
    for (let i = parts.length - 1; i >= 0; i--) {
      const ip = cleanIp(parts[i]);
      if (ip) return ip;
    }
  }
  return cleanIp(rawRequest?.ip) ?? cleanIp(rawRequest?.socket?.remoteAddress);
}

export interface AccessRecord {
  uid: string;
  event: AccessEvent;
  ip: string | null;
  userAgent: string | null;
  provider: string | null;
  source: 'auth_blocking' | 'callable';
  platform?: string | null;
}

/** Writes one record. [docId] makes it idempotent (callable de-dup). */
export async function writeAccessLog(rec: AccessRecord, now = new Date(), docId?: string): Promise<void> {
  const col = admin.firestore().collection(ACCESS_LOGS);
  const ref = docId ? col.doc(docId) : col.doc();
  await ref.set({
    uid: rec.uid,
    event: rec.event,
    ip: rec.ip,
    port: null, // not exposed by Firebase (see header)
    userAgent: rec.userAgent,
    provider: rec.provider,
    source: rec.source,
    ...(rec.platform !== undefined ? { platform: rec.platform } : {}),
    at: admin.firestore.Timestamp.fromDate(now),
    expireAt: admin.firestore.Timestamp.fromDate(accessLogExpiry(now)),
  });
}

/** Resolves after [ms] (never rejects). */
const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

/** The blocking budget is 7 s; never spend more than this on logging. */
export const BLOCKING_WRITE_TIMEOUT_MS = 3000;

/**
 * Body of both blocking functions. NEVER throws and NEVER returns a response
 * that changes the sign-in: logging is best effort.
 */
export async function handleBlockingAccessEvent(event: AuthBlockingEvent, kind: 'sign_up' | 'sign_in'): Promise<void> {
  try {
    const uid = event?.data?.uid;
    if (!uid) return;
    const write = writeAccessLog({
      uid,
      event: kind,
      ip: cleanIp(event.ipAddress),
      userAgent: clip(event.userAgent, 512),
      provider: clip(event.credential?.providerId ?? event.additionalUserInfo?.providerId, 64),
      source: 'auth_blocking',
    }).catch((e) => {
      console.error(`access log (${kind}) write failed: ${e?.message ?? e}`);
    });
    await Promise.race([write, sleep(BLOCKING_WRITE_TIMEOUT_MS)]);
  } catch (e: any) {
    console.error(`access log (${kind}) failed: ${e?.message ?? e}`);
  }
}

export const logAccessOnSignUp = beforeUserCreated(
  { memory: '512MiB', timeoutSeconds: 7 },
  async (event) => {
    await handleBlockingAccessEvent(event, 'sign_up');
  },
);

export const logAccessOnSignIn = beforeUserSignedIn(
  { memory: '512MiB', timeoutSeconds: 7 },
  async (event) => {
    await handleBlockingAccessEvent(event, 'sign_in');
  },
);

/**
 * `logAccess` callable: { event?: 'sign_in' | 'app_session', platform? }.
 * Signed-in callers only. Never fails the app: errors come back as
 * { success: false } (the app ignores the result).
 */
export async function handleLogAccess(request: any, now = new Date()): Promise<{ success: boolean }> {
  const uid = request?.auth?.uid;
  if (!uid) return { success: false };
  const data = request?.data ?? {};
  const event: AccessEvent = data.event === 'sign_in' ? 'sign_in' : 'app_session';
  const raw = request?.rawRequest;
  const minute = Math.floor(now.getTime() / 60_000);
  try {
    await writeAccessLog({
      uid,
      event,
      ip: requestIp(raw),
      userAgent: clip(raw?.headers?.['user-agent'], 512),
      provider: clip(request?.auth?.token?.firebase?.sign_in_provider, 64),
      source: 'callable',
      platform: clip(data.platform, 20),
    }, now, `${uid}_${event}_${minute}`);
    return { success: true };
  } catch (e: any) {
    console.error(`logAccess failed for ${uid}: ${e?.message ?? e}`);
    return { success: false };
  }
}

export const logAccess = onCall(
  { memory: '512MiB', timeoutSeconds: 15 },
  (request) => handleLogAccess(request),
);
