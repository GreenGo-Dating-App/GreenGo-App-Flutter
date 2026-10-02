/**
 * Banned / suspended hosts: hide their experiences; restore them on unban.
 *
 *  - ban:   every experience of the host that is NOT already hidden becomes
 *           status 'hidden' with moderation {reason:'host_banned',
 *           previousStatus}. Text-moderation hides (moderation.auto) and admin
 *           hides are left untouched.
 *  - unban: only experiences hidden with reason 'host_banned' go back to their
 *           previousStatus, and the moderation field is removed. (The text
 *           trigger re-checks the text on that write and re-hides if needed.)
 * Paginated (by document id), idempotent: re-running a ban/unban is a no-op.
 *
 * Called from every server ban/unban path (admin callables, moderation
 * queue) AND from `onProfileBanStateChanged`, which covers admin-panel
 * clients that write profiles.isBanned / accountStatus directly.
 */
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';

const EXPERIENCES = 'user_experiences';
const PAGE = 300;

/** Pure: is this profile / users doc in a banned-or-suspended state? */
export function isBannedState(d: Record<string, unknown> | null | undefined): boolean {
  if (!d) return false;
  if (d.isBanned === true || d.banned === true) return true;
  return d.accountStatus === 'banned' || d.accountStatus === 'suspended';
}

/** Pure: the patch for one experience on ban (null = leave as is). */
export function banPatch(exp: Record<string, unknown>): Record<string, unknown> | null {
  if (exp.status === 'hidden') return null;
  return {
    status: 'hidden',
    moderation: {
      reason: 'host_banned',
      previousStatus: exp.status === 'published' ? 'published' : 'draft',
    },
  };
}

/** Pure: the status to restore on unban, or null when not hidden by a ban. */
export function unbanStatus(exp: Record<string, unknown>): 'published' | 'draft' | null {
  const mod = exp.moderation as Record<string, unknown> | undefined;
  if (exp.status !== 'hidden' || !mod || mod.reason !== 'host_banned') return null;
  return mod.previousStatus === 'published' ? 'published' : 'draft';
}

/** Hides (banned=true) or restores (false) all of [hostId]'s experiences. */
export async function setHostExperiencesBanned(hostId: string, banned: boolean): Promise<number> {
  if (!hostId) return 0;
  const db = admin.firestore();
  let changed = 0;
  let cursor: string | null = null;
  for (;;) {
    let q = db.collection(EXPERIENCES)
      .where('hostId', '==', hostId)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(PAGE);
    if (cursor) q = q.startAfter(cursor);
    const page = await q.get();
    const batch = db.batch();
    let ops = 0;
    for (const d of page.docs) {
      const data = d.data();
      if (banned) {
        const p = banPatch(data);
        if (p) { batch.update(d.ref, p); ops++; }
      } else {
        const st = unbanStatus(data);
        if (st) {
          batch.update(d.ref, { status: st, moderation: admin.firestore.FieldValue.delete() });
          ops++;
        }
      }
    }
    if (ops) await batch.commit();
    changed += ops;
    if (page.size < PAGE) break;
    cursor = page.docs[page.docs.length - 1].id;
  }
  console.log(`setHostExperiencesBanned(${hostId}, ${banned}): ${changed} experiences`);
  return changed;
}

/** Best-effort wrapper for the ban callables (never fails the ban itself). */
export async function syncHostExperiencesForBan(hostId: string, banned: boolean): Promise<void> {
  try {
    // Unban from a users-doc callable while the PROFILE is still banned
    // (another ban path): keep them hidden.
    if (!banned) {
      const profile = await admin.firestore().collection('profiles').doc(hostId).get();
      if (isBannedState(profile.data())) return;
    }
    await setHostExperiencesBanned(hostId, banned);
  } catch (e) {
    console.error(`syncHostExperiencesForBan(${hostId}, ${banned}) failed:`, e);
  }
}

/**
 * profiles/{uid} updates: reacts ONLY when the ban state flips (isBanned /
 * accountStatus). Every other profile write exits after one comparison.
 * 512MiB: the bundle needs ~200MB just to load.
 */
export const onProfileBanStateChanged = onDocumentUpdated(
  { document: 'profiles/{uid}', memory: '512MiB', timeoutSeconds: 300 },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    const was = isBannedState(before);
    const now = isBannedState(after);
    if (was === now) return;
    await setHostExperiencesBanned(event.params.uid, now);
  },
);
