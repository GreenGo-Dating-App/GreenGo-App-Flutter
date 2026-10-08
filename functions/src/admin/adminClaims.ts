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
 * Other custom claims on the account are preserved. When a role is removed or
 * changed, refresh tokens are revoked so the old claim stops being minted into
 * new ID tokens (an already-issued ID token can live up to 1h; superAdmin-only
 * actions re-read admin_users anyway, see shared/adminAuth.ts).
 */

import * as admin from 'firebase-admin';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { ADMIN_ROLE_CLAIM, adminRoleFromDoc, requireAdmin, SUPER_ADMIN_ONLY } from '../shared/adminAuth';

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

  if (role) current[ADMIN_ROLE_CLAIM] = role;
  else delete current[ADMIN_ROLE_CLAIM];
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
