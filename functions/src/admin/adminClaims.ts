/**
 * Admin custom claims (security Phase 1, P1-6).
 *
 * `admin_users/{uid}.role` is the source of truth for admin access. This file
 * mirrors it into the `adminRole` custom claim so server checks (and, later,
 * Firestore rules) can authorize without a document read:
 *
 *   - syncAdminClaims(uid)    set / remove the claim from the admin_users doc
 *   - onAdminUserWritten      trigger keeping the claim in sync on every write
 *   - resyncAllAdminClaims    superAdmin-only callable to (re)sync every admin
 *
 * Other custom claims on the account are preserved (in particular the
 * `admin2faUntil` / `admin2faAuthTime` 2FA claims set by setAdmin2faClaim, which
 * in turn preserves `adminRole`). Removing the admin role drops the 2FA claims. When a role is removed or
 * changed, refresh tokens are revoked so the old claim stops being minted into
 * new ID tokens (an already-issued ID token can live up to 1h; superAdmin-only
 * actions re-read admin_users anyway, see shared/adminAuth.ts).
 */

import * as admin from 'firebase-admin';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onCall } from 'firebase-functions/v2/https';
import {
  ADMIN_2FA_CLAIM,
  ADMIN_2FA_SESSION_CLAIM,
  ADMIN_2FA_TTL_SECONDS,
  ADMIN_ROLE_CLAIM,
  adminRoleFromDoc,
  requireAdmin,
  SUPER_ADMIN_ONLY,
} from '../shared/adminAuth';

if (!admin.apps.length) {
  admin.initializeApp();
}

export interface SyncResult {
  uid: string;
  role: string | null;
  changed: boolean;
  revoked: boolean;
}

export async function syncAdminClaims(uid: string): Promise<SyncResult> {
  const role = await adminRoleFromDoc(uid);
  let user: admin.auth.UserRecord;
  try {
    user = await admin.auth().getUser(uid);
  } catch (e: any) {
    if (e?.code === 'auth/user-not-found') return { uid, role, changed: false, revoked: false };
    throw e;
  }

  const current: Record<string, any> = { ...(user.customClaims || {}) };
  const previous = typeof current[ADMIN_ROLE_CLAIM] === 'string' ? current[ADMIN_ROLE_CLAIM] : null;
  if (previous === role) return { uid, role, changed: false, revoked: false };

  if (role) {
    current[ADMIN_ROLE_CLAIM] = role;
  } else {
    delete current[ADMIN_ROLE_CLAIM];
    // No longer an admin: a leftover 2FA claim must not survive a re-promotion.
    delete current[ADMIN_2FA_CLAIM];
    delete current[ADMIN_2FA_SESSION_CLAIM];
  }
  await admin.auth().setCustomUserClaims(uid, current);

  // Demotion / removal / role change: stop the old claim being refreshed.
  let revoked = false;
  if (previous) {
    await admin.auth().revokeRefreshTokens(uid);
    revoked = true;
  }
  console.log(`[adminClaims] ${uid}: ${previous ?? '(none)'} -> ${role ?? '(none)'}${revoked ? ' (tokens revoked)' : ''}`);
  return { uid, role, changed: true, revoked };
}

/**
 * Mark the admin's CURRENT session as 2FA-verified for 8h (H-07). Every other
 * claim (adminRole included) is preserved. `authTime` is the verifying ID
 * token's auth_time; requireAdmin only honours the claim in that session.
 * Returns the new `admin2faUntil` (epoch seconds).
 */
export async function setAdmin2faClaim(uid: string, authTime: unknown, nowMs: number = Date.now()): Promise<number> {
  const user = await admin.auth().getUser(uid);
  const claims: Record<string, any> = { ...(user.customClaims || {}) };
  const until = Math.floor(nowMs / 1000) + ADMIN_2FA_TTL_SECONDS;
  claims[ADMIN_2FA_CLAIM] = until;
  if (typeof authTime === 'number') claims[ADMIN_2FA_SESSION_CLAIM] = authTime;
  else delete claims[ADMIN_2FA_SESSION_CLAIM];
  await admin.auth().setCustomUserClaims(uid, claims);
  return until;
}

export const onAdminUserWritten = onDocumentWritten(
  { document: 'admin_users/{uid}', memory: '512MiB' },
  async (event) => {
    await syncAdminClaims(event.params.uid);
  }
);

export const resyncAllAdminClaims = onCall({ memory: '512MiB', timeoutSeconds: 300 }, async (request) => {
  await requireAdmin(request.auth, SUPER_ADMIN_ONLY);
  const snap = await admin.firestore().collection('admin_users').get();
  const results: SyncResult[] = [];
  for (const doc of snap.docs) {
    results.push(await syncAdminClaims(doc.id));
  }
  return {
    total: results.length,
    changed: results.filter((r) => r.changed).length,
    results: results.map((r) => ({ uid: r.uid, role: r.role, changed: r.changed })),
  };
});
