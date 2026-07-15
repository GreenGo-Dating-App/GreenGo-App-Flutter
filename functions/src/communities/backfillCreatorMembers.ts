/**
 * ONE-TIME backfill (NEW, isolated module).
 *
 * Older communities were created without adding the creator to the `members`
 * subcollection (fixed going forward in the client's createCommunity). Those
 * communities are missing from the creator's "My Communities" and the creator
 * can't post tips/announcements (rules gate on an existing member doc). This
 * callable-by-URL function walks every community and, when the creator has no
 * member doc, creates one as OWNER. Idempotent — safe to run more than once.
 *
 * Guarded by a shared secret passed as `?token=...` so it can't be triggered
 * anonymously. Invoke once after deploy, then it can be removed.
 */

import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();
// Change this before deploying if you want a different one-time token.
const BACKFILL_TOKEN = 'greengo-backfill-2026';

export const backfillCommunityCreatorMembers = onRequest(
  { memory: '512MiB', timeoutSeconds: 300 },
  monitored('backfillCommunityCreatorMembers', async (req, res) => {
    if (req.query.token !== BACKFILL_TOKEN) {
      res.status(403).send('forbidden');
      return;
    }

    let scanned = 0;
    let created = 0;
    let lastId: string | undefined;

    // eslint-disable-next-line no-constant-condition
    while (true) {
      let q = db
        .collection('communities')
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(300);
      if (lastId) q = q.startAfter(lastId);
      const snap = await q.get();
      if (snap.empty) break;
      lastId = snap.docs[snap.docs.length - 1].id;

      for (const doc of snap.docs) {
        scanned++;
        const c = doc.data();
        const creatorId = (c.createdByUserId as string) || '';
        if (!creatorId) continue;
        const memberRef = doc.ref.collection('members').doc(creatorId);
        const existing = await memberRef.get();
        if (existing.exists) continue;

        // Resolve the creator's display name for the member doc.
        let displayName = (c.createdByName as string) || '';
        if (!displayName) {
          const p = await db.collection('profiles').doc(creatorId).get();
          displayName =
            (p.data()?.displayName as string) ||
            (p.data()?.nickname as string) ||
            'Owner';
        }

        await memberRef.set({
          userId: creatorId,
          displayName,
          photoUrl: null,
          role: 'owner',
          joinedAt: admin.firestore.Timestamp.now(),
          languages: [],
          isLocalGuide: false,
          isMuted: false,
          isBanned: false,
          canWriteTips: false,
          canWriteAnnouncements: false,
        });
        created++;
      }

      if (snap.size < 300) break;
    }

    res.status(200).json({ scanned, created });
  }),
);
