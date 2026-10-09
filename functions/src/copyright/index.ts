/**
 * Copyright notice-and-takedown Cloud Functions (see model.ts).
 *
 *   submitCopyrightNotice          callable, signed-in user (app form)
 *   copyrightNoticeWeb             HTTPS, public form for non-users (web.ts)
 *   submitCopyrightCounterNotice   callable, the uploader of the material
 *   adminListCopyrightNotices      callable, superAdmin | moderator
 *   adminGetCopyrightNotice        callable, superAdmin | moderator
 *   adminDecideCopyrightNotice     callable, superAdmin | moderator (accept / reject)
 *   adminMarkCopyrightLawsuit      callable, superAdmin | moderator
 *   adminGetCopyrightStrikes       callable, superAdmin | moderator
 *   processCopyrightNotices        scheduler: restore after 10 business days, expire strikes
 */
import * as admin from 'firebase-admin';
import { CallableRequest, HttpsError, onCall, onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { MODERATION_ROLES, requireAdmin } from '../shared/adminAuth';
import { inspectTarget } from './content';
import {
  COUNTER_NOTICES, NOTICE_STATUSES, NOTICES, noticeRef, parseCounterNotice, parseNotice, parseTarget, STRIKES,
} from './model';
import {
  acceptNotice, activeStrikes, copyrightDeps, createNotice, markLawsuit, rejectNotice,
  runCopyrightMaintenance, submitCounterNotice, takeRateLimit,
} from './service';
import { handleCopyrightWeb } from './web';

const db = () => admin.firestore();
const OPTS = { memory: '512MiB' as const, timeoutSeconds: 120 };

const millis = (v: unknown): number | null => (v && typeof (v as any).toMillis === 'function' ? (v as any).toMillis() : null);

function noticeId(v: unknown): string {
  if (typeof v !== 'string' || !/^[A-Za-z0-9]{1,64}$/.test(v)) throw new HttpsError('invalid-argument', 'invalid_noticeId');
  return v;
}

function requireUser(req: CallableRequest<any>): string {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'sign_in_required');
  return uid;
}

// ───────────────────────────────────────────────────────────── users

export const submitCopyrightNotice = onCall(OPTS, async (req) => {
  const uid = requireUser(req);
  const input = parseNotice(req.data);
  await takeRateLimit(`app_${uid}`, 10, 86_400_000);
  const r = await createNotice(input, { source: 'app', submitterUid: uid, locale: req.data?.locale });
  return { ...r, ref: noticeRef(r.noticeId) };
});

export const submitCopyrightCounterNotice = onCall(OPTS, async (req) => {
  const uid = requireUser(req);
  const input = parseCounterNotice(req.data);
  await takeRateLimit(`counter_${uid}`, 20, 86_400_000);
  return submitCounterNotice(uid, input);
});

export const copyrightNoticeWeb = onRequest({ memory: '512MiB', timeoutSeconds: 60, cors: false }, async (req, res) => {
  try {
    await handleCopyrightWeb(req, res as any);
  } catch (e) {
    console.error('[copyright] web handler failed:', (e as Error)?.message);
    if (!res.headersSent) res.status(500).send('error');
  }
});

// ───────────────────────────────────────────────────────────── admin

function summary(id: string, d: Record<string, any>) {
  return {
    noticeId: id,
    ref: noticeRef(id),
    status: d.status,
    source: d.source ?? null,
    locale: d.locale ?? 'en',
    submittedAt: millis(d.submittedAt),
    confirmedAt: millis(d.confirmedAt),
    complainant: { name: d.complainant?.name ?? null, email: d.complainant?.email ?? null, organization: d.complainant?.organization ?? null, relationship: d.complainant?.relationship ?? null },
    work: d.work ?? null,
    content: { location: d.content?.location ?? null, details: d.content?.details ?? null, label: d.content?.label ?? null, target: d.content?.target ?? null },
    targetUid: d.targetUid ?? null,
    decision: d.decision ? { ...d.decision, decidedAt: millis(d.decision.decidedAt) } : null,
    strike: d.strike ?? null,
    counterNoticedAt: millis(d.counterNoticedAt),
    restoreAfter: millis(d.restoreAfter),
    restoredAt: millis(d.restoredAt),
    lawsuitFiledAt: millis(d.lawsuitFiledAt),
    lawsuitNote: d.lawsuitNote ?? null,
  };
}

export const adminListCopyrightNotices = onCall(OPTS, async (req) => {
  await requireAdmin(req.auth as any, MODERATION_ROLES);
  const status = req.data?.status;
  if (status !== undefined && status !== null && !(NOTICE_STATUSES as readonly string[]).includes(status)) {
    throw new HttpsError('invalid-argument', 'invalid_status');
  }
  const limit = Math.min(Math.max(Number(req.data?.limit) || 50, 1), 100);
  let q: FirebaseFirestore.Query = db().collection(NOTICES);
  if (status) q = q.where('status', '==', status);
  q = q.orderBy('submittedAt', 'desc');
  if (typeof req.data?.startAfter === 'string' && req.data.startAfter) {
    const cursor = await db().collection(NOTICES).doc(noticeId(req.data.startAfter)).get();
    if (cursor.exists) q = q.startAfter(cursor);
  }
  const snap = await q.limit(limit).get();
  return { items: snap.docs.map((d) => summary(d.id, d.data())), hasMore: snap.size === limit };
});

export const adminGetCopyrightNotice = onCall(OPTS, async (req) => {
  await requireAdmin(req.auth as any, MODERATION_ROLES);
  const id = noticeId(req.data?.noticeId);
  const ref = db().collection(NOTICES).doc(id);
  const [snap, priv, counter, auditSnap] = await Promise.all([
    ref.get(), ref.collection('private').doc('contact').get(), db().collection(COUNTER_NOTICES).doc(id).get(),
    ref.collection('audit').orderBy('at', 'asc').limit(200).get(),
  ]);
  if (!snap.exists) throw new HttpsError('not-found', 'notice_not_found');
  const d = snap.data()!;
  const p = priv.data() || {};
  const target = d.content?.target ?? null;
  const content = target ? await inspectTarget(target).catch(() => null) : null;
  const owner = d.targetUid ?? content?.ownerUid ?? null;
  const strikes = owner ? (await db().collection(STRIKES).where('userId', '==', owner).get()).docs.map((s) => {
    const x = s.data();
    return { strikeId: s.id, noticeId: x.noticeId, status: x.status, createdAt: millis(x.createdAt), expiresAt: millis(x.expiresAt), removedReason: x.removedReason ?? null };
  }) : [];
  const c = counter.data();
  return {
    notice: summary(id, d),
    contact: { phone: p.phone ?? null, address: p.address ?? null },
    contentPreview: content,
    ownerUid: owner,
    strikes,
    activeStrikes: owner ? (await activeStrikes(owner)).length : 0,
    counterNotice: c ? { ...c, submittedAt: millis(c.submittedAt), restoreAfter: millis(c.restoreAfter), restoredAt: millis(c.restoredAt), updatedAt: millis(c.updatedAt) } : null,
    audit: auditSnap.docs.map((a) => ({ ...a.data(), at: millis(a.data().at) })),
  };
});

export const adminDecideCopyrightNotice = onCall(OPTS, async (req) => {
  const caller = await requireAdmin(req.auth as any, MODERATION_ROLES);
  const id = noticeId(req.data?.noticeId);
  const decision = req.data?.decision;
  const reason = typeof req.data?.reason === 'string' ? req.data.reason.trim() : '';
  if (reason.length > 2000) throw new HttpsError('invalid-argument', 'invalid_reason');
  if (decision === 'accept') {
    const target = parseTarget(req.data?.target);
    return acceptNotice(caller, id, { reason, target });
  }
  if (decision === 'reject') {
    if (reason.length < 5) throw new HttpsError('invalid-argument', 'invalid_reason');
    return rejectNotice(caller, id, reason);
  }
  throw new HttpsError('invalid-argument', 'invalid_decision');
});

export const adminMarkCopyrightLawsuit = onCall(OPTS, async (req) => {
  const caller = await requireAdmin(req.auth as any, MODERATION_ROLES);
  const id = noticeId(req.data?.noticeId);
  const note = typeof req.data?.note === 'string' ? req.data.note.trim() : '';
  if (note.length < 5 || note.length > 2000) throw new HttpsError('invalid-argument', 'invalid_note');
  return markLawsuit(caller, id, note);
});

export const adminGetCopyrightStrikes = onCall(OPTS, async (req) => {
  await requireAdmin(req.auth as any, MODERATION_ROLES);
  const uid = req.data?.userId;
  if (typeof uid !== 'string' || !uid || uid.length > 128 || uid.includes('/')) throw new HttpsError('invalid-argument', 'invalid_userId');
  const snap = await db().collection(STRIKES).where('userId', '==', uid).get();
  const now = copyrightDeps.now();
  const strikes = snap.docs.map((s) => {
    const x = s.data();
    return { strikeId: s.id, noticeId: x.noticeId, status: x.status, createdAt: millis(x.createdAt), expiresAt: millis(x.expiresAt), removedReason: x.removedReason ?? null };
  }).sort((a, b) => (b.createdAt ?? 0) - (a.createdAt ?? 0));
  const active = strikes.filter((s) => s.status === 'active' && (s.expiresAt ?? 0) > now).length;
  return { userId: uid, active, strikes };
});

// ───────────────────────────────────────────────────────────── scheduler

export const processCopyrightNotices = onSchedule(
  { schedule: 'every 6 hours', timeZone: 'UTC', memory: '512MiB', timeoutSeconds: 540 },
  async () => {
    const r = await runCopyrightMaintenance();
    if (r.restored || r.failed || r.expired || r.purged) console.log(`[copyright] maintenance: ${r.restored} restored, ${r.failed} failed, ${r.expired} strikes expired, ${r.purged} unconfirmed purged`);
  },
);
