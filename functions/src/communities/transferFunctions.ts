/**
 * Community ownership transfer: Cloud Function bindings (thin wrappers; the
 * logic is in ./transfer.ts). 512MiB everywhere (the bundle needs ~200MB RSS
 * just to load; 256MiB instances are OOM-killed on cold start).
 */
import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as svc from './transfer';

const CALL_OPTS = { memory: '512MiB' as const, timeoutSeconds: 60 };

type Impl = (req: CallableRequest<any>, uid: string) => Promise<Record<string, unknown>>;

function callable(impl: Impl) {
  return onCall(CALL_OPTS, async (req: CallableRequest<any>) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.', { code: 'unauthenticated' });
    try {
      return await impl(req, uid);
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      console.error('[communityTransfer] callable failed:', e);
      throw new HttpsError('internal', 'community_transfer_internal_error', { code: 'internal' });
    }
  });
}

/** Owner offers the community to a member (needs a sign-in < 5 min old). */
export const requestCommunityTransfer = callable((req, uid) =>
  svc.requestCommunityTransfer(uid, (req.auth?.token as any)?.auth_time, req.data ?? {}));

/** The offered member accepts or declines. */
export const respondCommunityTransfer = callable((req, uid) =>
  svc.respondCommunityTransfer(uid, req.data ?? {}));

/** The owner withdraws a pending offer. */
export const cancelCommunityTransfer = callable((req, uid) =>
  svc.cancelCommunityTransfer(uid, req.data ?? {}));

/** Sweeps offers older than 7 days and tells their owners. */
export const expireCommunityTransfers = onSchedule(
  { schedule: 'every 6 hours', memory: '512MiB', timeoutSeconds: 300, timeZone: 'UTC' },
  async () => {
    await svc.expireDueTransfers();
  },
);
