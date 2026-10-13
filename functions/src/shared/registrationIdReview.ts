/**
 * The ID photo sent at REGISTRATION (onboarding: "a photo of yourself holding
 * your ID document"), reviewed by an admin in the admin panel or the in-app
 * admin tools.
 *
 * profiles.verificationStatus is client-writable (the app sets 'pending' when
 * a photo is sent), so on its own it only proves that a photo was sent:
 * 'uploaded'. An APPROVAL is trusted only when an admin's decision is on
 * record in `admin_actions`, which only admins may create (firestore.rules)
 * and which the panel already writes for every approve / reject. The latest
 * decision wins, and the profile must still say approved.
 */
import * as admin from 'firebase-admin';

export const ADMIN_ACTIONS = 'admin_actions';

export type RegistrationReview = 'approved' | 'rejected' | 'other' | null;

/** admin_actions.actionType → decision on the registration ID photo. */
const DECISIONS: Record<string, Exclude<RegistrationReview, null>> = {
  verification_approved: 'approved',
  verification_rejected: 'rejected',
  verification_resubmission_requested: 'other',
  verification_status_set: 'other',
};

/** actionType to record when an admin sets [status] on the profile. */
export function registrationActionType(status: string): string {
  if (status === 'approved' || status === 'verified') return 'verification_approved';
  if (status === 'rejected') return 'verification_rejected';
  if (status === 'needsResubmission') return 'verification_resubmission_requested';
  return 'verification_status_set';
}

function claimsApproved(profile: Record<string, any> | null | undefined): boolean {
  if (!profile || profile.verificationMethod === 'phone') return false;
  return profile.verificationStatus === 'approved' || profile.verificationStatus === 'verified';
}

/** A registration ID photo was sent and is pending or approved (phone sign-ups have none). */
export function registrationIdDocumentSent(profile: Record<string, any> | null | undefined): boolean {
  if (!profile || profile.verificationMethod === 'phone') return false;
  return profile.verificationStatus === 'pending' || claimsApproved(profile);
}

function millis(v: unknown): number {
  if (v instanceof admin.firestore.Timestamp) return v.toMillis();
  if (v instanceof Date) return v.getTime();
  if (typeof v === 'number') return v;
  const t = v as { toMillis?: () => number; seconds?: number; _seconds?: number } | null;
  if (t && typeof t.toMillis === 'function') return t.toMillis();
  if (t && typeof t.seconds === 'number') return t.seconds * 1000;
  if (t && typeof t._seconds === 'number') return t._seconds * 1000;
  return 0;
}

/** Pure: the latest registration-photo decision among [actions]. */
export function latestRegistrationReview(
  actions: Array<Record<string, unknown>>
): RegistrationReview {
  let best: RegistrationReview = null;
  let at = -1;
  for (const a of actions) {
    const d = DECISIONS[String(a.actionType ?? '')];
    if (!d) continue;
    const t = millis(a.timestamp);
    if (t >= at) {
      at = t;
      best = d;
    }
  }
  return best;
}

/** Pure: the profile says approved AND the latest admin decision is an approval. */
export function registrationIdApproved(
  profile: Record<string, any> | null | undefined,
  review: RegistrationReview
): boolean {
  return claimsApproved(profile) && review === 'approved';
}

/**
 * True when an admin approved [uid]'s registration ID photo and it still
 * stands. Reads admin_actions only when the profile claims an approval
 * (equality filter only: no composite index; a user has few admin actions).
 */
export async function registrationIdApprovedByAdmin(
  db: admin.firestore.Firestore,
  uid: string,
  profile: Record<string, any> | null | undefined
): Promise<boolean> {
  if (!claimsApproved(profile)) return false;
  try {
    const snap = await db.collection(ADMIN_ACTIONS)
      .where('targetUserId', '==', uid)
      .limit(100)
      .get();
    return registrationIdApproved(profile, latestRegistrationReview(snap.docs.map((d) => d.data())));
  } catch {
    return false;
  }
}
