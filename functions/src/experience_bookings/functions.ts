/**
 * Experience bookings — Cloud Function bindings (thin wrappers; the logic is in
 * ./service.ts and ./reviews.ts, the model in ./model.ts).
 *
 * 512MiB everywhere: the functions bundle needs ~200MB RSS just to load;
 * 256MiB instances are OOM-killed on cold start and trigger events dropped.
 * No secrets: the check-in HMAC key lives in server_secrets/booking_checkin.
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentWritten,
} from 'firebase-functions/v2/firestore';
import * as svc from './service';
import {
  handleGuestReviewWrite,
  handlePendingReviewCreated,
  revealDueReviews,
} from './reviews';

const CALL_OPTS = { memory: '512MiB' as const, timeoutSeconds: 60 };
const JOB_OPTS = { memory: '512MiB' as const, timeoutSeconds: 300, timeZone: 'UTC' };
const TRIGGER_OPTS = { memory: '512MiB' as const, timeoutSeconds: 120 };

type Impl = (uid: string, data: any) => Promise<Record<string, unknown>>;

function callable(impl: Impl) {
  return onCall(CALL_OPTS, async (req: CallableRequest<any>) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.', { code: 'unauthenticated' });
    try {
      return await impl(uid, req.data ?? {});
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      console.error('[bookings] callable failed:', e);
      throw new HttpsError('internal', 'booking_internal_error', { code: 'internal' });
    }
  });
}

// Callables
export const createBooking = callable(svc.createBooking);
export const respondToBookingRequest = callable(svc.respondToBookingRequest);
export const cancelBooking = callable(svc.cancelBooking);
export const cancelExperienceSlot = callable(svc.cancelSlot);
export const getBookingCheckInCode = callable(svc.getBookingCheckInCode);
export const checkInBooking = callable(svc.checkInBooking);
export const markBookingNoShow = callable(svc.markNoShow);
export const markBookingPaid = callable((uid, data) => svc.markBookingPaid(uid, data));
export const confirmCashReceived = callable(svc.confirmCashReceived);
export const openBookingDispute = callable(svc.openBookingDispute);
export const resolveBookingDispute = callable(svc.resolveBookingDispute);

// Schedules
export const sendBookingReminders = onSchedule(
  { schedule: 'every 30 minutes', ...JOB_OPTS },
  async () => {
    await svc.sendDueReminders();
  },
);
export const expireBookingRequests = onSchedule(
  { schedule: 'every 30 minutes', ...JOB_OPTS },
  async () => {
    await svc.expireDueRequests();
  },
);
export const completeBookings = onSchedule(
  { schedule: 'every 60 minutes', ...JOB_OPTS },
  async () => {
    await svc.completeDueBookings();
  },
);
export const revealBlindReviews = onSchedule(
  { schedule: 'every 60 minutes', ...JOB_OPTS },
  async () => {
    await revealDueReviews();
  },
);

// Triggers
export const onGuestReviewWritten = onDocumentWritten(
  { document: 'guest_reviews/{bookingId}', ...TRIGGER_OPTS },
  async (event) => {
    try {
      await handleGuestReviewWrite(
        event.id,
        event.params.bookingId,
        event.data?.before?.data() ?? null,
        event.data?.after?.data() ?? null,
      );
    } catch (e) {
      console.error(`[bookings] guest review ${event.params.bookingId} failed:`, e);
    }
  },
);

export const onPendingExperienceReviewCreated = onDocumentCreated(
  { document: 'user_experiences/{experienceId}/pending_reviews/{reviewerId}', ...TRIGGER_OPTS },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    try {
      await handlePendingReviewCreated(event.params.experienceId, event.params.reviewerId, data);
    } catch (e) {
      console.error(`[bookings] pending review ${event.params.experienceId}/${event.params.reviewerId} failed:`, e);
    }
  },
);

export const onBookableExperienceDeleted = onDocumentDeleted(
  { document: 'user_experiences/{experienceId}', ...TRIGGER_OPTS, timeoutSeconds: 300 },
  async (event) => {
    try {
      const hostId = (event.data?.data()?.hostId as string | undefined) ?? null;
      await svc.onExperienceDeleted(event.params.experienceId, hostId);
    } catch (e) {
      console.error(`[bookings] experience ${event.params.experienceId} delete cleanup failed:`, e);
    }
  },
);
