/**
 * Copyright notice-and-takedown flows (see model.ts for the data model).
 * Everything here is server-side; callables / HTTP / scheduler wrappers live
 * in functions.ts. `copyrightDeps.now` is the clock (overridable in tests).
 */
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { HttpsError } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { t } from '../shared/i18n';
import { normalizeLocale } from '../shared/i18n/locales';
import { resolveLocale } from '../shared/i18n/recipientLocale';
import { authEmailOf, sendEmail, sendEmailOnce } from '../emails/sendEmail';
import { notifyAffectedUserOfDecision, MODERATION_DECISIONS, APPEAL_WINDOW_DAYS } from '../safety/moderationDecisions';
import { syncHostExperiencesForBan } from '../user_experiences/hostBan';
import {
  addBusinessDays, adminRecipients, CONFIRM_TTL_MS, ContentTarget, COUNTER_NOTICES, CounterInput,
  NOTICES, NoticeInput, publicFormUrl, RATE_LIMITS, RESTORE_BUSINESS_DAYS, STRIKE_LIMIT, STRIKE_TTL_MS, STRIKES,
  targetFromLocation, UNVERIFIED_TTL_MS,
} from './model';
import { disableContent, inspectTarget, RemovalRecord, restoreContent } from './content';
import {
  adminAlertEmail, complainantAcceptedEmail, complainantCounterEmail, complainantRejectedEmail,
  complainantRestoredEmail, confirmEmail, uploaderRemovedEmail,
} from './emails';

const db = () => admin.firestore();
const TS = admin.firestore.Timestamp;

export const copyrightDeps = {
  now: (): number => Date.now(),
  token: (): string => crypto.randomBytes(32).toString('hex'),
};

const ts = (ms: number) => TS.fromMillis(ms);
const nowTs = () => ts(copyrightDeps.now());
const ms = (v: unknown): number | null => (v instanceof TS ? v.toMillis() : (v && typeof (v as any).toMillis === 'function') ? (v as any).toMillis() : null);

export const sha256 = (s: string): string => crypto.createHash('sha256').update(s).digest('hex');

function isAlreadyExists(e: unknown): boolean {
  const code = (e as { code?: unknown })?.code;
  return code === 6 || code === 'already-exists' || /ALREADY_EXISTS/i.test(String((e as Error)?.message));
}

// ───────────────────────────────────────────────────────────── audit

export type Actor = { kind: 'admin' | 'user' | 'public' | 'system'; uid?: string | null; role?: string };

export async function audit(noticeId: string, action: string, actor: Actor, details: Record<string, unknown> = {}): Promise<void> {
  try {
    await db().collection(NOTICES).doc(noticeId).collection('audit').add({
      action,
      actorKind: actor.kind,
      actorUid: actor.uid ?? null,
      actorRole: actor.role ?? null,
      details,
      at: nowTs(),
    });
    if (actor.kind === 'admin') {
      await db().collection('admin_audit_log').add({
        adminId: actor.uid ?? null,
        action: `copyright_${action}`,
        targetType: 'copyright_notice',
        targetId: noticeId,
        details,
        timestamp: nowTs(),
      });
    }
  } catch (e) {
    console.error(`[copyright] audit ${action} for ${noticeId} failed:`, (e as Error)?.message);
  }
}

// ───────────────────────────────────────────────────────────── rate limits

/** Fixed-window counter; throws resource-exhausted over [limit]. */
export async function takeRateLimit(key: string, limit: number, windowMs: number): Promise<void> {
  const ref = db().collection(RATE_LIMITS).doc(key.replace(/[^A-Za-z0-9_-]/g, '_').slice(0, 200));
  const now = copyrightDeps.now();
  await db().runTransaction(async (tx) => {
    const d = (await tx.get(ref)).data();
    const start = ms(d?.windowStart);
    if (!d || start === null || now - start >= windowMs) {
      tx.set(ref, { count: 1, windowStart: ts(now), expireAt: ts(now + windowMs * 2) });
      return;
    }
    if ((d.count ?? 0) >= limit) throw new HttpsError('resource-exhausted', 'rate_limited');
    tx.update(ref, { count: (d.count ?? 0) + 1 });
  });
}

// ───────────────────────────────────────────────────────────── submit

export interface SubmitMeta {
  source: 'app' | 'web';
  submitterUid: string | null;
  locale: unknown;
  ipHash?: string | null;
}

/** Creates a notice. App submissions are pending at once; web ones wait for the email confirmation. */
export async function createNotice(input: NoticeInput, meta: SubmitMeta): Promise<{ noticeId: string; status: string }> {
  const ref = db().collection(NOTICES).doc();
  const now = copyrightDeps.now();
  const locale = normalizeLocale(meta.locale);
  const target: ContentTarget | null = input.content.target ?? targetFromLocation(input.content.location);
  const status = meta.source === 'app' ? 'pending' : 'unverified';
  const token = meta.source === 'web' ? copyrightDeps.token() : null;

  const batch = db().batch();
  batch.set(ref, {
    noticeId: ref.id,
    status,
    source: meta.source,
    submitterUid: meta.submitterUid,
    locale,
    complainant: input.complainant,
    work: input.work,
    content: { location: input.content.location, details: input.content.details, label: input.content.label, target },
    statements: input.statements,
    signature: input.signature,
    submittedAt: ts(now),
    confirmedAt: status === 'pending' ? ts(now) : null,
    targetUid: null,
    uploaderVisible: false,
    updatedAt: ts(now),
    ...(status === 'unverified' ? { expireAt: ts(now + UNVERIFIED_TTL_MS) } : {}),
  });
  batch.set(ref.collection('private').doc('contact'), {
    phone: input.contact.phone,
    address: input.contact.address,
    ipHash: meta.ipHash ?? null,
    confirmTokenHash: token ? sha256(token) : null,
    confirmExpiresAt: token ? ts(now + CONFIRM_TTL_MS) : null,
  });
  await batch.commit();
  await audit(ref.id, 'submitted', { kind: meta.submitterUid ? 'user' : 'public', uid: meta.submitterUid }, { source: meta.source, contentType: target?.type ?? null });

  if (token) {
    const link = `${publicFormUrl()}/confirm?id=${encodeURIComponent(ref.id)}&token=${token}`;
    const r = await sendEmail(confirmEmail(input.complainant.email, locale, link));
    await audit(ref.id, 'confirmation_email', { kind: 'system' }, { sent: r.sent, reason: r.reason ?? null });
  } else {
    await alertAdmins(ref.id, 'notice', { source: meta.source, contentType: target?.type ?? null });
  }
  return { noticeId: ref.id, status };
}

async function alertAdmins(noticeId: string, kind: 'notice' | 'counter', meta: { source?: string; contentType?: string | null }) {
  await sendEmailOnce(`copyright_admin_${kind}_${noticeId}`, async () => adminAlertEmail(adminRecipients(), noticeId, kind, meta),
    { type: `copyright_admin_${kind}`, noticeId });
}

/** Web email confirmation link. */
export async function confirmWebNotice(noticeId: unknown, token: unknown): Promise<'confirmed' | 'already' | 'invalid'> {
  if (typeof noticeId !== 'string' || !/^[A-Za-z0-9]{1,64}$/.test(noticeId) || typeof token !== 'string' || !/^[a-f0-9]{64}$/.test(token)) {
    return 'invalid';
  }
  const ref = db().collection(NOTICES).doc(noticeId);
  const now = copyrightDeps.now();
  let meta: { source?: string; contentType?: string | null } = {};
  const res = await db().runTransaction(async (tx) => {
    const [snap, priv] = await Promise.all([tx.get(ref), tx.get(ref.collection('private').doc('contact'))]);
    if (!snap.exists || !priv.exists) return 'invalid' as const;
    const d = snap.data()!;
    const p = priv.data()!;
    const expected = typeof p.confirmTokenHash === 'string' ? Buffer.from(p.confirmTokenHash, 'hex') : null;
    const got = Buffer.from(sha256(token), 'hex');
    if (!expected || expected.length !== got.length || !crypto.timingSafeEqual(expected, got)) return 'invalid' as const;
    if (d.status !== 'unverified') return 'already' as const;
    if ((ms(p.confirmExpiresAt) ?? 0) < now) return 'invalid' as const;
    tx.update(ref, { status: 'pending', confirmedAt: ts(now), expireAt: admin.firestore.FieldValue.delete(), updatedAt: ts(now) });
    meta = { source: d.source, contentType: d.content?.target?.type ?? null };
    return 'confirmed' as const;
  });
  if (res === 'confirmed') {
    await audit(noticeId, 'email_confirmed', { kind: 'public' });
    await alertAdmins(noticeId, 'notice', meta);
  }
  return res;
}

// ───────────────────────────────────────────────────────────── strikes

export async function activeStrikes(uid: string): Promise<Array<Record<string, any>>> {
  const now = copyrightDeps.now();
  const snap = await db().collection(STRIKES).where('userId', '==', uid).get();
  return snap.docs
    .map((d) => d.data())
    .filter((s) => s.status === 'active' && (ms(s.expiresAt) ?? 0) > now);
}

async function terminateRepeatInfringer(uid: string, noticeId: string, count: number): Promise<boolean> {
  const now = copyrightDeps.now();
  const decisionId = `copyright_term_${noticeId}`;
  const reason = 'copyright_repeat_infringer';
  // Same fields as the moderation suspension (admin/moderationQueue.ts suspendUser), with no end date.
  await db().collection('users').doc(uid).set({
    accountStatus: 'suspended',
    suspensionReason: reason,
    suspendedAt: ts(now),
    suspendedUntil: null,
    copyrightTerminatedAt: ts(now),
  }, { merge: true });
  try {
    await db().collection('profiles').doc(uid).update({ status: 'suspended', suspensionReason: reason, suspendedAt: ts(now), suspendedUntil: null });
  } catch (e: any) {
    if (e?.code !== 5) console.error(`[copyright] could not mirror suspension onto profiles/${uid}:`, e?.message);
  }
  await syncHostExperiencesForBan(uid, true);
  const created = await notifyAffectedUserOfDecision({
    queueId: decisionId,
    userId: uid,
    action: 'suspendUser',
    reasonCode: 'copyright',
    explanation: `Repeat infringer policy: ${count} valid copyright notices within 12 months (limit ${STRIKE_LIMIT}).`,
    moderatorId: 'system',
    nowMs: now,
  });
  await audit(noticeId, 'account_terminated', { kind: 'system' }, { userId: uid, activeStrikes: count, decisionId });
  return created;
}

// ───────────────────────────────────────────────────────────── admin decisions

async function claimPending(noticeId: string, adminUid: string): Promise<Record<string, any>> {
  const ref = db().collection(NOTICES).doc(noticeId);
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'notice_not_found');
    const d = snap.data()!;
    if (d.status !== 'pending') throw new HttpsError('failed-precondition', `notice_is_${d.status}`);
    tx.update(ref, { status: 'accepting', claimedBy: adminUid, updatedAt: nowTs() });
    return d;
  });
}

async function releaseClaim(noticeId: string): Promise<void> {
  await db().collection(NOTICES).doc(noticeId).update({ status: 'pending', claimedBy: admin.firestore.FieldValue.delete(), updatedAt: nowTs() });
}

const DEFAULT_ACCEPT_REASON = 'Material disabled after a copyright notice (17 U.S.C. §512(c); DSA art. 16).';

export async function acceptNotice(
  actor: { uid: string; role: string },
  noticeId: string,
  opts: { reason?: string | null; target?: ContentTarget | null },
): Promise<{ status: 'accepted'; targetUid: string; activeStrikes: number; terminated: boolean }> {
  const n = await claimPending(noticeId, actor.uid);
  let removal: RemovalRecord;
  let owner: string;
  const target = opts.target ?? n.content?.target ?? null;
  try {
    if (!target) throw new HttpsError('failed-precondition', 'target_required');
    const info = await inspectTarget(target);
    if (!info.exists) throw new HttpsError('not-found', 'content_not_found');
    if (!info.ownerUid) throw new HttpsError('failed-precondition', 'owner_unknown');
    owner = info.ownerUid;
    removal = await disableContent(target, noticeId, copyrightDeps.now());
  } catch (e) {
    await releaseClaim(noticeId);
    throw e;
  }

  const now = copyrightDeps.now();
  const reason = (opts.reason || '').trim() || DEFAULT_ACCEPT_REASON;
  // One strike per accepted notice (doc id = notice id -> idempotent).
  try {
    await db().collection(STRIKES).doc(noticeId).create({
      strikeId: noticeId, userId: owner, noticeId, status: 'active',
      createdAt: ts(now), expiresAt: ts(now + STRIKE_TTL_MS), removedAt: null, removedReason: null,
    });
  } catch (e) {
    if (!isAlreadyExists(e)) throw e;
  }
  const strikes = await activeStrikes(owner);
  const decisionId = `copyright_${noticeId}`;

  await db().collection(NOTICES).doc(noticeId).update({
    status: 'accepted',
    claimedBy: admin.firestore.FieldValue.delete(),
    targetUid: owner,
    uploaderVisible: true,
    'content.target': target,
    removal: { ...removal, disabledAt: ts(now) },
    decision: { action: 'accept', reason, decidedBy: actor.uid, decidedAt: ts(now) },
    strike: { strikeId: noticeId, activeCount: strikes.length },
    decisionId,
    updatedAt: ts(now),
  });
  await audit(noticeId, 'accepted', { kind: 'admin', uid: actor.uid, role: actor.role }, {
    target, targetUid: owner, reason, activeStrikes: strikes.length,
  });

  // DSA art. 17 statement of reasons + art. 20 appeal (same record the
  // moderation pipeline writes; submitAppeal accepts it). The uploader is
  // told through the copyright notification below, not a second one.
  try {
    await db().collection(MODERATION_DECISIONS).doc(decisionId).create({
      decisionId, queueId: decisionId, userId: owner, action: 'removeContent', reasonCode: 'copyright',
      explanation: reason.slice(0, 2000), decidedBy: actor.uid, decidedAt: ts(now), automated: false,
      appealable: true, appealDeadline: ts(now + APPEAL_WINDOW_DAYS * 86_400_000), appealStatus: null,
      copyrightNoticeId: noticeId,
    });
  } catch (e) {
    if (!isAlreadyExists(e)) throw e;
  }

  const notice = { ...n, noticeId, status: 'accepted' };
  await notifyUploader(owner, noticeId, 'removed');
  const submittedMs = ms(n.submittedAt) ?? now;
  await sendEmailOnce(`copyright_removed_${noticeId}`, async () => {
    const to = await authEmailOf(owner);
    if (!to) return null;
    return uploaderRemovedEmail(to, notice, await resolveLocale(owner), submittedMs, strikes.length);
  }, { type: 'copyright_removed', noticeId });
  await sendEmailOnce(`copyright_accepted_${noticeId}`, async () => complainantAcceptedEmail(notice), { type: 'copyright_accepted', noticeId });

  let terminated = false;
  if (strikes.length >= STRIKE_LIMIT) terminated = await terminateRepeatInfringer(owner, noticeId, strikes.length);
  return { status: 'accepted', targetUid: owner, activeStrikes: strikes.length, terminated };
}

export async function rejectNotice(actor: { uid: string; role: string }, noticeId: string, reason: string): Promise<{ status: 'rejected' }> {
  const ref = db().collection(NOTICES).doc(noticeId);
  const n = await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'notice_not_found');
    const d = snap.data()!;
    if (d.status !== 'pending' && d.status !== 'unverified') throw new HttpsError('failed-precondition', `notice_is_${d.status}`);
    tx.update(ref, {
      status: 'rejected',
      decision: { action: 'reject', reason, decidedBy: actor.uid, decidedAt: nowTs() },
      expireAt: admin.firestore.FieldValue.delete(),
      updatedAt: nowTs(),
    });
    return d;
  });
  await audit(noticeId, 'rejected', { kind: 'admin', uid: actor.uid, role: actor.role }, { reason });
  if (n.status === 'pending') {
    await sendEmailOnce(`copyright_rejected_${noticeId}`, async () => complainantRejectedEmail({ ...n, noticeId }, reason), { type: 'copyright_rejected', noticeId });
  }
  return { status: 'rejected' };
}

export async function markLawsuit(actor: { uid: string; role: string }, noticeId: string, note: string): Promise<{ status: 'lawsuit_filed' }> {
  const ref = db().collection(NOTICES).doc(noticeId);
  await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'notice_not_found');
    const d = snap.data()!;
    if (d.status !== 'counter_noticed') throw new HttpsError('failed-precondition', `notice_is_${d.status}`);
    tx.update(ref, { status: 'lawsuit_filed', lawsuitFiledAt: nowTs(), lawsuitNote: note, lawsuitMarkedBy: actor.uid, updatedAt: nowTs() });
    tx.set(db().collection(COUNTER_NOTICES).doc(noticeId), { status: 'lawsuit', updatedAt: nowTs() }, { merge: true });
  });
  await audit(noticeId, 'lawsuit_filed', { kind: 'admin', uid: actor.uid, role: actor.role }, { note });
  return { status: 'lawsuit_filed' };
}

// ───────────────────────────────────────────────────────────── counter-notice

export async function submitCounterNotice(uid: string, c: CounterInput): Promise<{ status: 'counter_noticed'; restoreAfter: number }> {
  const ref = db().collection(NOTICES).doc(c.noticeId);
  const counterRef = db().collection(COUNTER_NOTICES).doc(c.noticeId);
  const now = copyrightDeps.now();
  const restoreAfter = addBusinessDays(now, RESTORE_BUSINESS_DAYS);
  const n = await db().runTransaction(async (tx) => {
    const [snap, existing] = await Promise.all([tx.get(ref), tx.get(counterRef)]);
    if (!snap.exists) throw new HttpsError('not-found', 'notice_not_found');
    const d = snap.data()!;
    if (d.targetUid !== uid) throw new HttpsError('permission-denied', 'not_your_content');
    if (existing.exists || d.status === 'counter_noticed') throw new HttpsError('already-exists', 'counter_notice_exists');
    if (d.status !== 'accepted') throw new HttpsError('failed-precondition', `notice_is_${d.status}`);
    tx.create(counterRef, {
      noticeId: c.noticeId,
      uploaderUid: uid,
      name: c.name,
      email: c.email,
      phone: c.phone,
      address: c.address,
      explanation: c.explanation,
      statements: c.statements,
      signature: c.signature,
      submittedAt: ts(now),
      restoreAfter: ts(restoreAfter),
      status: 'pending',
    });
    tx.update(ref, { status: 'counter_noticed', counterNoticeId: c.noticeId, counterNoticedAt: ts(now), restoreAfter: ts(restoreAfter), updatedAt: ts(now) });
    return d;
  });
  await audit(c.noticeId, 'counter_notice', { kind: 'user', uid }, { restoreAfter: new Date(restoreAfter).toISOString() });
  // §512(g)(2)(B): promptly forward a copy of the counter-notice to the complainant.
  const r = await sendEmailOnce(`copyright_counter_${c.noticeId}`,
    async () => complainantCounterEmail({ ...n, noticeId: c.noticeId }, c, restoreAfter), { type: 'copyright_counter', noticeId: c.noticeId });
  await audit(c.noticeId, 'counter_notice_forwarded', { kind: 'system' }, { result: typeof r === 'string' ? r : (r.sent ? 'sent' : r.reason ?? 'failed') });
  await alertAdmins(c.noticeId, 'counter', { source: n.source, contentType: n.content?.target?.type ?? null });
  return { status: 'counter_noticed', restoreAfter };
}

// ───────────────────────────────────────────────────────────── scheduler

async function notifyUploader(uid: string, noticeId: string, kind: 'removed' | 'restored'): Promise<void> {
  const locale = await resolveLocale(uid);
  const titleKey = kind === 'removed' ? 'srvCopyrightRemovedTitle' : 'srvCopyrightRestoredTitle';
  const bodyKey = kind === 'removed' ? 'srvCopyrightRemovedBody' : 'srvCopyrightRestoredBody';
  try {
    await db().collection('notifications').doc(`copyright_${kind}_${noticeId}`).create({
      userId: uid,
      type: 'system',
      title: t(locale, titleKey),
      message: t(locale, bodyKey),
      body: t(locale, bodyKey),
      titleKey,
      bodyKey,
      data: { action: 'copyright_notice', noticeId },
      isRead: false,
      createdAt: nowTs(),
      actionUrl: null,
      imageUrl: null,
    });
  } catch (e) {
    if (!isAlreadyExists(e)) console.error(`[copyright] notify ${uid} (${kind}) failed:`, (e as Error)?.message);
  }
}

async function restoreOne(noticeId: string): Promise<'restored' | 'skipped' | 'failed'> {
  const ref = db().collection(NOTICES).doc(noticeId);
  const now = copyrightDeps.now();
  const n = await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const d = snap.data();
    if (!d || d.status !== 'counter_noticed' || (ms(d.restoreAfter) ?? Infinity) > now) return null;
    tx.update(ref, { status: 'restored', restoredAt: ts(now), updatedAt: ts(now) });
    return d;
  });
  if (!n) return 'skipped';
  try {
    if (n.removal) await restoreContent(n.removal as RemovalRecord, noticeId);
  } catch (e) {
    console.error(`[copyright] restore ${noticeId} failed:`, (e as Error)?.message);
    await ref.update({ status: 'counter_noticed', restoredAt: null, restoreError: String((e as Error)?.message || e).slice(0, 300) });
    return 'failed';
  }
  await db().collection(STRIKES).doc(noticeId).set({ status: 'removed', removedAt: ts(now), removedReason: 'counter_notice_restored' }, { merge: true });
  await db().collection(COUNTER_NOTICES).doc(noticeId).set({ status: 'restored', restoredAt: ts(now) }, { merge: true });
  await audit(noticeId, 'restored', { kind: 'system' }, { strikeRemoved: true });
  if (n.targetUid) await notifyUploader(n.targetUid, noticeId, 'restored');
  await sendEmailOnce(`copyright_restored_${noticeId}`, async () => complainantRestoredEmail({ ...n, noticeId }), { type: 'copyright_restored', noticeId });
  return 'restored';
}

/** Restores counter-noticed material whose waiting period ended, expires old strikes, purges unconfirmed web notices. */
export async function runCopyrightMaintenance(): Promise<{ restored: number; failed: number; expired: number; purged: number }> {
  const now = ts(copyrightDeps.now());
  let restored = 0;
  let failed = 0;
  const due = await db().collection(NOTICES)
    .where('status', '==', 'counter_noticed').where('restoreAfter', '<=', now).limit(200).get();
  for (const d of due.docs) {
    const r = await restoreOne(d.id);
    if (r === 'restored') restored++;
    if (r === 'failed') failed++;
  }
  const old = await db().collection(STRIKES).where('status', '==', 'active').where('expiresAt', '<=', now).limit(500).get();
  if (!old.empty) {
    const batch = db().batch();
    for (const s of old.docs) batch.update(s.ref, { status: 'expired' });
    await batch.commit();
  }
  // Never-confirmed web notices: delete them WITH their private contact and
  // audit subcollections (a TTL policy would orphan the subcollections).
  const stale = await db().collection(NOTICES).where('status', '==', 'unverified').where('expireAt', '<=', now).limit(200).get();
  for (const d of stale.docs) {
    const batch = db().batch();
    batch.delete(d.ref.collection('private').doc('contact'));
    for (const a of (await d.ref.collection('audit').get()).docs) batch.delete(a.ref);
    batch.delete(d.ref);
    await batch.commit();
  }
  return { restored, failed, expired: old.size, purged: stale.size };
}
