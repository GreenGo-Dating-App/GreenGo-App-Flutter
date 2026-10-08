/**
 * Central admin authorization (security Phase 1, P1-6).
 *
 * There is exactly ONE source of truth for "who is an admin": the
 * `admin_users/{uid}` document (written only by a superAdmin, see
 * firestore.rules) and its mirror in the `adminRole` custom claim, which
 * `admin/adminClaims.ts` keeps in sync.
 *
 * NO LONGER ACCEPTED as admin (each was writable or forgeable somewhere, or
 * simply drifted out of sync with the admin panel):
 *   - users/{uid}.isAdmin, users/{uid}.role == 'admin'
 *   - profiles/{uid}.isAdmin
 *   - the legacy `admins` collection and its `permissions` arrays
 * Firestore RULES still honour some of these for the in-app admin screens;
 * that is a rules concern and is unchanged here.
 *
 * Role matrix (admin panel roles: superAdmin, moderator, support, analyst):
 *   SUPER_ADMIN_ONLY - delete / disable users, change passwords, view ID
 *                      documents, grant entitlements or coins, broadcasts
 *   MODERATION       - superAdmin | moderator
 *   ANY_ADMIN        - any active admin_users member (read-only analytics)
 */

import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';

if (!admin.apps.length) {
  admin.initializeApp();
}

export type AdminRole = 'superAdmin' | 'moderator' | 'support' | 'analyst';

export const SUPER_ADMIN_ONLY: readonly AdminRole[] = ['superAdmin'];
export const MODERATION_ROLES: readonly AdminRole[] = ['superAdmin', 'moderator'];
export const SUPPORT_ROLES: readonly AdminRole[] = ['superAdmin', 'moderator', 'support'];
/** `undefined` = any active admin role. */
export const ANY_ADMIN: readonly AdminRole[] | undefined = undefined;

/**
 * Legacy permission names (userManagement / adminDashboard) mapped onto the
 * role matrix. Unknown permissions default to superAdmin only (fail closed).
 */
const PERMISSION_ROLES: Record<string, readonly AdminRole[] | undefined> = {
  // read-only
  viewDashboard: ANY_ADMIN,
  viewUserProfiles: SUPPORT_ROLES,
  viewAuditLog: SUPER_ADMIN_ONLY,
  // moderation
  suspendUsers: MODERATION_ROLES,
  banUsers: MODERATION_ROLES,
  editUserProfiles: MODERATION_ROLES,
  // dangerous
  deleteUsers: SUPER_ADMIN_ONLY,
  overrideSubscriptions: SUPER_ADMIN_ONLY,
  adjustCoins: SUPER_ADMIN_ONLY,
  sendNotifications: SUPER_ADMIN_ONLY,
  impersonateUsers: SUPER_ADMIN_ONLY,
  massActions: SUPER_ADMIN_ONLY,
};

export function rolesForPermission(permission: string): readonly AdminRole[] | undefined {
  return Object.prototype.hasOwnProperty.call(PERMISSION_ROLES, permission)
    ? PERMISSION_ROLES[permission]
    : SUPER_ADMIN_ONLY;
}

/** Name of the custom claim mirrored from admin_users/{uid}.role. */
export const ADMIN_ROLE_CLAIM = 'adminRole';

export interface AdminIdentity {
  uid: string;
  role: string;
  /** Where the role came from (for audit logs / debugging). */
  source: 'claim' | 'admin_users';
}

type AuthLike = { uid?: string; token?: Record<string, any> } | null | undefined;

/** Role from the admin_users doc, or null when the uid is not an active admin. */
export async function adminRoleFromDoc(uid: string): Promise<string | null> {
  const snap = await admin.firestore().collection('admin_users').doc(uid).get();
  if (!snap.exists) return null;
  const d = snap.data() || {};
  if (d.isActive === false) return null;
  return typeof d.role === 'string' && d.role ? d.role : 'unknown';
}

/**
 * Throws `unauthenticated` / `permission-denied` HttpsError unless the caller
 * is an admin whose role is in `allowedRoles` (any role when omitted).
 *
 * The `adminRole` claim is a fast path for non-superAdmin checks. Actions
 * restricted to superAdmin ALWAYS re-read admin_users, so a demoted or removed
 * superAdmin loses those powers immediately, not when the ID token expires.
 */
export async function requireAdmin(
  auth: AuthLike,
  allowedRoles?: readonly AdminRole[]
): Promise<AdminIdentity> {
  const uid = auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Must be authenticated');

  const superOnly = !!allowedRoles && allowedRoles.length === 1 && allowedRoles[0] === 'superAdmin';
  const claimRole = auth?.token?.[ADMIN_ROLE_CLAIM];

  let role: string | null = null;
  let source: AdminIdentity['source'] = 'admin_users';
  if (!superOnly && typeof claimRole === 'string' && claimRole) {
    role = claimRole;
    source = 'claim';
  } else {
    // Transitional fallback (claims not synced yet) and the superAdmin path.
    role = await adminRoleFromDoc(uid);
  }

  if (!role) throw new HttpsError('permission-denied', 'Must be an admin');
  if (allowedRoles && !allowedRoles.includes(role as AdminRole)) {
    throw new HttpsError('permission-denied', `Requires role: ${allowedRoles.join(' | ')}`);
  }
  return { uid, role, source };
}

/** Boolean form for code paths that branch instead of throwing. */
export async function isAdminCaller(auth: AuthLike, allowedRoles?: readonly AdminRole[]): Promise<boolean> {
  try {
    await requireAdmin(auth, allowedRoles);
    return true;
  } catch {
    return false;
  }
}
