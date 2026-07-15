/**
 * Scheduled-event auto-publish (NEW, isolated module) — #17.
 *
 * Scheduled events (`status: 'scheduled'`, `publishAt` set) currently go "live"
 * purely via client-side query filtering (`publishAt <= now`), with NO doc write.
 * Because nothing writes the doc, the `onUpdate → published` transition never
 * fires, so a scheduled BUSINESS event never pushes to followers and a scheduled
 * COMMUNITY event never pushes to members.
 *
 * This scheduled function periodically flips DUE scheduled events
 * (`publishAt <= now`) to `status: 'published'` — a real doc write — which then
 * triggers the existing follower fan-out (business_new_event.ts) and community
 * fan-out (communities/eventFanout.ts) via their onUpdate handlers. Idempotent:
 * only events still in `scheduled` are flipped, and each fan-out has its own
 * one-time claim flag.
 *
 * Needs composite index events(status ASC, publishAt ASC).
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const PAGE = 300;

export const autoPublishScheduledEvents = onSchedule(
  'every 15 minutes',
  monitored('autoPublishScheduledEvents', async () => {
    const now = admin.firestore.Timestamp.now();
    let flipped = 0;

    // Page through due scheduled events.
    // eslint-disable-next-line no-constant-condition
    while (true) {
      const snap = await db
        .collection('events')
        .where('status', '==', 'scheduled')
        .where('publishAt', '<=', now)
        .orderBy('publishAt', 'asc')
        .limit(PAGE)
        .get();
      if (snap.empty) break;

      const batch = db.batch();
      for (const doc of snap.docs) {
        batch.update(doc.ref, {
          status: 'published',
          autoPublishedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      flipped += snap.size;

      if (snap.size < PAGE) break;
    }

    if (flipped > 0) {
      console.log(`autoPublishScheduledEvents: published ${flipped} event(s)`);
    }
  }),
);
