/**
 * User experiences — Phase 1 safety callables + report trigger.
 *
 *  publishUserExperience  {experienceId, asFree?}
 *    The ONLY way to publish a listing that takes money (firestore.rules deny
 *    a direct client transition into "published + paid / with link", because
 *    the new-host limit needs a count rules cannot do). Also used for free
 *    publishes so the client has one path. In one transaction: host owns it,
 *    not hidden, ID document + host agreement + approved document for paid,
 *    new-host paid limit; `asFree` turns it into a free listing first.
 *
 *  acceptHostAgreement    {version}
 *    Records profiles/{uid}.hostAgreementAcceptedAt / hostAgreementVersion
 *    (server-owned: clients cannot write them).
 *
 *  onExperienceReportCreated  reports/{reportId}
 *    Counts DISTINCT reporters per experience (marker per reporter under
 *    user_experiences/{id}/reporters, no client access). At 3 the listing is
 *    hidden (status 'hidden', moderation.reason 'reports') pending admin
 *    review, and the host is notified. Host self-reports never count.
 */
import { AvailabilityRules, generateSlots, rulesError } from '../experience_bookings/availability';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { emitNotification } from '../notifications/notifyHelpers';
import { EXPERIENCES, countPublishedPaid, safetyError } from './createUserExperience';
import {
  AS_FREE_PATCH,
  EXPERIENCE_REPORT_TYPES,
  HOST_AGREEMENT_VERSION,
  isNewHost,
  publishBlockReason,
  shouldHideForReports,
} from './safety';

const db = admin.firestore();
const OPTS = { memory: '512MiB' as const, timeoutSeconds: 60 };


export const publishUserExperience = onCall<{ experienceId?: string; asFree?: boolean }>(
  OPTS,
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
    const id = typeof request.data?.experienceId === 'string' ? request.data.experienceId : '';
    if (!id) throw new HttpsError('invalid-argument', 'experienceId is required.');
    const asFree = request.data?.asFree === true;

    const expRef = db.collection(EXPERIENCES).doc(id);
    const profileRef = db.collection('profiles').doc(uid);
    return db.runTransaction(async (tx) => {
      const [exp, profileSnap] = await Promise.all([tx.get(expRef), tx.get(profileRef)]);
      if (!exp.exists) throw new HttpsError('not-found', 'not_found', { code: 'not_found' });
      const data = exp.data() ?? {};
      if (data.hostId !== uid) throw new HttpsError('permission-denied', 'Not your experience.');
      if (data.status === 'hidden') {
        throw new HttpsError('failed-precondition', 'hidden', { code: 'hidden' });
      }
      const profile = profileSnap.data() ?? null;
      const next: Record<string, unknown> = { ...data, ...(asFree ? AS_FREE_PATCH : {}) };

      let otherPublishedPaid = 0;
      if (next.isFree !== true && profile?.isAdmin !== true && isNewHost(profile)) {
        otherPublishedPaid = await countPublishedPaid(tx, uid, id);
      }
      const why = publishBlockReason({ profile, experience: next, otherPublishedPaid });
      if (why) throw safetyError(why);
      // Availability must be defined: at least one upcoming open date.
      // Recurring schedule (Manage times) counts when it generates a future time.
      if (!hasRecurringTimes(next) && !(await hasUpcomingDate(tx, expRef))) throw safetyError('dates_required');

      tx.update(expRef, {
        ...(asFree ? AS_FREE_PATCH : {}),
        status: 'published',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return { status: 'published', asFree };
    });
  },
);

/** A valid recurring schedule that offers at least one time in its horizon. */
function hasRecurringTimes(e: Record<string, any>): boolean {
  const rules = e.availabilityRules as AvailabilityRules | undefined;
  if (!rules || rulesError(rules)) return false;
  const now = Date.now();
  const horizon = now + ((rules.maxAdvanceDays ?? 60) + 1) * 86400000;
  return generateSlots(rules, e.availabilityOverrides, now, horizon, now).length > 0;
}

/** Whether the listing has at least one OPEN date starting in the future. */
async function hasUpcomingDate(
  tx: admin.firestore.Transaction,
  expRef: admin.firestore.DocumentReference,
): Promise<boolean> {
  const snap = await tx.get(
    expRef.collection('slots')
      .where('start', '>', admin.firestore.Timestamp.now())
      .orderBy('start')
      .limit(25),
  );
  return snap.docs.some((d) => d.get('status') === 'open');
}

export const acceptHostAgreement = onCall<{ version?: number }>(OPTS, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
  const version = Number(request.data?.version);
  if (version !== HOST_AGREEMENT_VERSION) {
    // An old client accepting an outdated text must not count as consent.
    throw new HttpsError('failed-precondition', 'agreement_outdated', {
      code: 'agreement_outdated',
      current: HOST_AGREEMENT_VERSION,
    });
  }
  const ref = db.collection('profiles').doc(uid);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('failed-precondition', 'Complete your profile first.');
  await ref.update({
    hostAgreementAcceptedAt: admin.firestore.FieldValue.serverTimestamp(),
    hostAgreementVersion: HOST_AGREEMENT_VERSION,
  });
  return { version: HOST_AGREEMENT_VERSION };
});

export const onExperienceReportCreated = onDocumentCreated(
  { document: 'reports/{reportId}', ...OPTS },
  async (event) => {
    const r = event.data?.data();
    if (!r || !EXPERIENCE_REPORT_TYPES.includes(String(r.type))) return;
    const experienceId = typeof r.experienceId === 'string' ? r.experienceId : '';
    const reporterId = typeof r.reporterId === 'string' ? r.reporterId : '';
    if (!experienceId || !reporterId) return;

    const expRef = db.collection(EXPERIENCES).doc(experienceId);
    const markerRef = expRef.collection('reporters').doc(reporterId);
    let hidden: { hostId: string; title: string } | null = null;
    try {
      await db.runTransaction(async (tx) => {
        const [exp, marker] = await Promise.all([tx.get(expRef), tx.get(markerRef)]);
        if (!exp.exists || marker.exists) return; // gone, or this reporter already counted
        const data = exp.data() ?? {};
        if (data.hostId === reporterId) return;
        const distinct = (Number(data.reportCount) || 0) + 1;
        tx.set(markerRef, {
          reportId: event.params.reportId,
          reason: typeof r.reason === 'string' ? r.reason.slice(0, 40) : null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        const patch: Record<string, unknown> = { reportCount: distinct };
        if (shouldHideForReports(distinct, data.status)) {
          patch.status = 'hidden';
          // `auto` absent: the text-moderation trigger never auto-restores it;
          // only an admin decision does.
          patch.moderation = {
            reason: 'reports',
            reportCount: distinct,
            previousStatus: data.status === 'published' ? 'published' : 'draft',
            hiddenAt: admin.firestore.FieldValue.serverTimestamp(),
          };
          hidden = { hostId: String(data.hostId ?? ''), title: String(data.title ?? '') };
        }
        tx.update(expRef, patch);
      });
    } catch (e) {
      console.error(`experience report count failed (${experienceId}):`, e);
      return;
    }
    const h = hidden as { hostId: string; title: string } | null;
    if (h && h.hostId) {
      try {
        await emitNotification({
          recipientId: h.hostId,
          type: 'experience_hidden',
          title: 'Your experience was hidden after several reports',
          body: h.title.slice(0, 120) || 'Pending review by GreenGo',
          data: { action: 'experience', experienceId },
        });
      } catch (e) {
        console.error(`experience hidden notify failed (${experienceId}):`, e);
      }
    }
  },
);
