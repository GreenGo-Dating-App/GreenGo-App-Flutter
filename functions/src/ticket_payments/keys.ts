/**
 * The ticket signing key: TICKET_QR_SIGNING_KEY from the environment, else a
 * random key generated ONCE in server_secrets/ticket_payments (default-deny in
 * firestore.rules), so link-mode tickets work with zero configuration.
 */
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import '../shared/firebaseAdmin';
import { qrSigningKey } from './config';

let cached: string | null = null;

export async function ticketKey(): Promise<string> {
  const env = qrSigningKey();
  if (env.length >= 32) return env;
  if (cached) return cached;
  const db = admin.firestore();
  const ref = db.collection('server_secrets').doc('ticket_payments');
  cached = await db.runTransaction(async (tx) => {
    const k = (await tx.get(ref)).data()?.key;
    if (typeof k === 'string' && k.length >= 32) return k;
    const fresh = crypto.randomBytes(32).toString('hex');
    tx.set(ref, { key: fresh, createdAt: admin.firestore.Timestamp.now() });
    return fresh;
  });
  return cached;
}

/** Test hook. */
export function resetTicketKey(): void { cached = null; }
