/**
 * Report-count maintenance (NEW, isolated module) — #22.
 *
 * The client can create a `user_reports/{id}` doc but CANNOT increment
 * `users/{reportedUserId}.reportCount` (security rules deny writing another
 * user's doc), so that best-effort client write was silently denied and the
 * moderation triage counter never moved.
 *
 * This Admin-SDK trigger bumps the counter authoritatively when a report doc is
 * created. Idempotent per report via a marker on the report doc.
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();

export const onUserReportCreated = onDocumentCreated(
  'user_reports/{reportId}',
  monitored('onUserReportCreated', async (event) => {
    const snap = event.data;
    if (!snap) return;
    const r = snap.data();
    const reportedUserId = (r?.reportedUserId as string) || '';
    if (!reportedUserId) return;
    if (r?.countApplied === true) return; // already counted

    // Mark the report as counted first (idempotency guard against retries).
    await snap.ref.update({ countApplied: true });

    await db.collection('users').doc(reportedUserId).set(
      {
        reportCount: admin.firestore.FieldValue.increment(1),
        lastReportedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }),
);
