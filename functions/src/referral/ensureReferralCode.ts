/**
 * Returns the caller's invite code, creating it server-side when missing, so
 * every user has an invite link (https://greengo-chat.web.app/r/{CODE}).
 *
 * Idempotent: an existing code (referrals/{uid}.code whose
 * referral_codes/{CODE}.ownerId is the caller) is returned as is. A new code
 * is claimed in a transaction (create-if-absent on referral_codes/{CODE}).
 * Same charset/length as the client generator (ReferralService).
 */
import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { randomInt } from 'crypto';
import { db, logError } from '../shared/utils';
import { monitored } from '../shared/monitoring';

const CHARSET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const CODE_LENGTH = 6;
const MAX_ATTEMPTS = 8;

export function randomReferralCode(rand: (max: number) => number = randomInt): string {
  let out = '';
  for (let i = 0; i < CODE_LENGTH; i++) out += CHARSET[rand(CHARSET.length)];
  return out;
}

export async function ensureReferralCodeFor(uid: string): Promise<string> {
  const myRef = db.collection('referrals').doc(uid);
  const existing = (await myRef.get()).get('code');
  if (typeof existing === 'string' && existing) {
    const owner = (await db.collection('referral_codes').doc(existing).get()).get('ownerId');
    if (owner === uid) return existing;
  }
  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    const code = randomReferralCode();
    const created = await db.runTransaction(async (tx) => {
      const codeRef = db.collection('referral_codes').doc(code);
      const [codeSnap, mySnap] = await Promise.all([tx.get(codeRef), tx.get(myRef)]);
      const current = mySnap.get('code');
      if (typeof current === 'string' && current && current !== existing) return current as string;
      if (codeSnap.exists) return null; // collision: try another
      tx.create(codeRef, { ownerId: uid, createdAt: admin.firestore.FieldValue.serverTimestamp() });
      tx.set(myRef, mySnap.exists ? { code } : { code, invitedCount: 0, coinsEarned: 0 }, { merge: true });
      return code;
    });
    if (created) return created;
  }
  throw new Error('could not allocate a unique referral code');
}

export const ensureReferralCode = onCall(
  { memory: '512MiB', timeoutSeconds: 30 },
  monitored('ensureReferralCode', async (request: CallableRequest<unknown>): Promise<{ code: string }> => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
    try {
      return { code: await ensureReferralCodeFor(request.auth.uid) };
    } catch (e) {
      logError('ensureReferralCode failed', e as any);
      throw new HttpsError('internal', 'Could not create an invite code');
    }
  }),
);
