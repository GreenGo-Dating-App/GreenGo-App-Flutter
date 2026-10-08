/**
 * Account deletion cascade.
 *
 * Guideline 5.1.1(v): an app that offers account creation must let the user
 * delete the account — and Apple means the account, not just the ability to
 * sign in. GDPR Article 17 says the same about the data behind it.
 *
 * Until v4.0.0 GreenGo's "delete account" called `user.delete()` on the client
 * and stopped there. That removes the Firebase Auth record and leaves
 * everything else: the profile and its photos, coin balances, community
 * memberships, event attendance, blocked lists, and — since Wave 2 — age
 * verification records. The account was unreachable, not deleted.
 *
 * This runs on the auth deletion trigger rather than as a callable, so it
 * fires however the user is removed: from the app, from the admin panel, or by
 * hand in the Firebase console.
 *
 * WHAT IS DELETED / RETAINED / ANONYMISED: see ACCOUNT_DATA_INVENTORY and
 *   the policy notes in ./accountDeletion.ts (financial records are now
 *   retained pseudonymised in retention_finance instead of being deleted).
 *
 * WHAT IS RETAINED (DRAFT — lawyer review, LGPD legitimate interest /
 * GDPR Art. 6(1)(f))
 *   Identity documents (`id_documents/{uid}/…`): moved to `retention/{uid}/…`
 *   and kept 30 days for fraud prevention, then erased by
 *   purgeRetainedIdDocuments (safety/idDocumentRetention.ts). The
 *   `id_documents/{uid}` prefix is deliberately NOT a storage inventory entry.
 *
 * WHAT IS ANONYMISED INSTEAD
 *   Messages already delivered to another person. Deleting those would edit
 *   somebody else's conversation history, which is neither required nor
 *   desirable; the sender is replaced with a tombstone so nothing traces back.
 *   This is the standard reading of "personal data" for two-party content and
 *   is stated in the privacy policy.
 */

import * as functions from 'firebase-functions/v1';
import { logInfo } from '../shared/utils';
import { sweepDeletedAccount } from './accountDeletion';

/**
 * Since P1-10 the cascade itself lives in ./accountDeletion.ts (one inventory,
 * shared with deleteMyAccount and the website flow). This trigger keeps its
 * job: whenever an Auth user disappears - old app versions that delete
 * client-side, the admin panel, the console - sweep the data and write
 * `deletion_receipts/{uid}` (same shape as before). After a server-initiated
 * deletion it runs again as a cheap idempotent sweep and keeps the original
 * receipt.
 */
export const onUserDeletedCleanup = functions
  .runWith({ memory: '512MB', timeoutSeconds: 540 })
  .auth.user()
  .onDelete(async (user) => {
    const uid = user.uid;
    logInfo(`onUserDeletedCleanup: starting for ${uid}`);
    const report = await sweepDeletedAccount(uid);
    if (report.failures.length === 0) {
      logInfo(
        `onUserDeletedCleanup: done for ${uid} - ${report.documents} docs, ` +
          `${report.anonymised} messages anonymised, ${report.files} files, ` +
          `${report.retained} finance records retained`
      );
    }
  });
