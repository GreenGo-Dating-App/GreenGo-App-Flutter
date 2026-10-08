/**
 * Daily backstop for Google Play refunds / chargebacks (security audit H-10).
 *
 * The RTDN `voidedPurchaseNotification` (playStoreNotifications) is the fast
 * path, but Pub/Sub pushes can be lost and RTDN voided notifications must be
 * enabled separately in Play Console. This job lists the Voided Purchases API
 * (last 30 days max) from a cursor stored in Firestore and runs every entry
 * through the same idempotent processPlayVoidedPurchase, so overlap between
 * runs (and with the RTDN) never double-debits.
 *
 * Cursor: play_voided_purchases_state/cursor { lastVoidedTimeMillis, lastRunAt, ... }
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { db, logInfo, logError } from '../shared/utils';
import { listGooglePlayVoidedPurchases } from '../shared/purchase_verification';
import { processPlayVoidedPurchase } from './storeNotifications';

const DAY_MS = 24 * 3600 * 1000;
/** Re-scan this much before the cursor: late-indexed voids are not missed. */
const OVERLAP_MS = 2 * DAY_MS;
const MAX_PAGES = 20;

export async function runPlayVoidedPurchasesPoll(): Promise<{
  scanned: number;
  outcomes: Record<string, number>;
  failed: number;
  apiUnavailable?: boolean;
}> {
  const cursorRef = db.collection('play_voided_purchases_state').doc('cursor');
  const cursor = (await cursorRef.get()).data() || {};
  const now = Date.now();
  const last = typeof cursor.lastVoidedTimeMillis === 'number' ? cursor.lastVoidedTimeMillis : 0;
  const startTimeMs = Math.max(now - 30 * DAY_MS, last - OVERLAP_MS);

  const outcomes: Record<string, number> = {};
  let scanned = 0;
  let failed = 0;
  let maxSeen = last;
  let pageToken: string | undefined;
  for (let page = 0; page < MAX_PAGES; page++) {
    const res = await listGooglePlayVoidedPurchases(startTimeMs, pageToken);
    if (res.apiUnavailable || res.error) {
      logError(`pollPlayVoidedPurchases: Play API ${res.apiUnavailable ? 'not configured' : res.error}`);
      await cursorRef.set({ lastRunAt: admin.firestore.Timestamp.now(), lastError: res.error || 'api_unavailable' }, { merge: true });
      return { scanned, outcomes, failed, apiUnavailable: true };
    }
    for (const v of res.items) {
      scanned++;
      try {
        const o = await processPlayVoidedPurchase(v, 'voided_poll');
        outcomes[o] = (outcomes[o] || 0) + 1;
        if (v.voidedTimeMillis && v.voidedTimeMillis > maxSeen) maxSeen = v.voidedTimeMillis;
      } catch (e) {
        failed++;
        logError('pollPlayVoidedPurchases: entry failed (retried next run)', e);
      }
    }
    pageToken = res.nextPageToken;
    if (!pageToken) break;
  }

  // Only advance past what was fully processed: a failure keeps the cursor so
  // the next run re-scans it (processing is idempotent).
  await cursorRef.set({
    lastVoidedTimeMillis: failed > 0 ? last : maxSeen,
    lastRunAt: admin.firestore.Timestamp.now(),
    lastScanned: scanned,
    lastFailed: failed,
    lastOutcomes: outcomes,
    lastError: admin.firestore.FieldValue.delete(),
  }, { merge: true });
  logInfo(`pollPlayVoidedPurchases: scanned ${scanned}, failed ${failed}, ${JSON.stringify(outcomes)}`);
  return { scanned, outcomes, failed };
}

export const pollPlayVoidedPurchases = onSchedule(
  {
    schedule: '30 4 * * *', // daily 04:30 UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
  },
  async () => {
    try {
      await runPlayVoidedPurchasesPoll();
    } catch (e) {
      logError('pollPlayVoidedPurchases failed', e);
    }
  },
);
