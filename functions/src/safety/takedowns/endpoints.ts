/**
 * Safety takedown endpoints (see safetyCases.ts for the flow).
 *
 *  nciiTakedownRequest   HTTPS, PUBLIC (non-users): the TAKE IT DOWN / Decreto
 *                        12.976 request form on greengochat.com. Rate-limited
 *                        by IP and email; honeypot; the requester confirms
 *                        their email with a link and can check the status with
 *                        a token link (no account needed).
 *  submitSafetyRequest   callable, signed-in users (Help & Support, report
 *                        sheet on profiles / photos / media).
 *  safetyAdmin           callable for the admin panel Safety queue (requireAdmin).
 *  safetySlaSweep        every 10 minutes: 1 h escalation, 2 h / 48 h breach alerts.
 *  legalHoldExpirySweep  daily: holds past their 1-year date.
 */

import { onCall, onRequest, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import '../../shared/firebaseAdmin';
import { requireAdmin, MODERATION_ROLES, SUPER_ADMIN_ONLY } from '../../shared/adminAuth';
import { sendResendEmail } from '../../shared/resendEmail';
import { sendSecurityAlert } from '../../security/securityEventAlerts';
import {
  SAFETY_CASES, SAFETY_STATUS, createSafetyCase, decideSafetyCase, parseContentLocation, newStatusToken,
  tokenHash, runSafetySlaSweep, auditCase, SANCTIONS, Sanction, ContentRef, SAFETY_ALERT_EMAIL,
} from './safetyCases';
import { LEGAL_HOLDS, AUTHORITIES, Authority, buildReportPackage, runLegalHoldExpirySweep } from './legalHold';
import { importCsamEntries } from './hashLists';

const db = () => admin.firestore();
const TS = admin.firestore.Timestamp;

// ---------------------------------------------------------------------------
// Form validation (shared by the public endpoint and the in-app callable)
// ---------------------------------------------------------------------------

export interface NciiForm {
  fullName: string;
  email: string;
  phone: string | null;
  role: 'depicted_person' | 'authorized_representative';
  representedPerson: string | null;
  contentLocations: string[];
  description: string | null;
  signature: string;
  locale: string | null;
}

const EMAIL_RE = /^[^@\s]{1,64}@[^@\s]{1,190}\.[^@\s]{2,24}$/;
const s = (v: unknown, max: number): string => (typeof v === 'string' ? v.trim().slice(0, max) : '');

/**
 * TAKE IT DOWN Act §3(a)(1)(B) valid request: (i) physical/electronic
 * signature, (ii) identification + location of the depiction, (iii) brief
 * good-faith statement that it is not consensual, (iv) contact information.
 * Returns the cleaned form or the list of problems (field names).
 */
export function validateNciiForm(body: any, opts: { emailOptional?: boolean } = {}): { ok: true; form: NciiForm } | { ok: false; errors: string[] } {
  const errors: string[] = [];
  const fullName = s(body?.fullName, 120);
  if (fullName.length < 2) errors.push('fullName');
  const email = s(body?.email, 254).toLowerCase();
  if (!(opts.emailOptional && !email) && !EMAIL_RE.test(email)) errors.push('email');
  const phone = s(body?.phone, 40) || null;
  const role = body?.role === 'authorized_representative' ? 'authorized_representative' : body?.role === 'depicted_person' ? 'depicted_person' : null;
  if (!role) errors.push('role');
  const representedPerson = s(body?.representedPerson, 120) || null;
  if (role === 'authorized_representative' && (!representedPerson || representedPerson.length < 2)) errors.push('representedPerson');
  const locs = Array.isArray(body?.contentLocations) ? body.contentLocations : [];
  const contentLocations = locs.map((x: unknown) => s(x, 1000)).filter((x: string) => x.length >= 3).slice(0, 10);
  if (contentLocations.length === 0) errors.push('contentLocations');
  const st = body?.statements || {};
  if (st.depictedOrAuthorized !== true) errors.push('statements.depictedOrAuthorized');
  if (st.goodFaith !== true) errors.push('statements.goodFaith');
  if (st.accurate !== true) errors.push('statements.accurate');
  const signature = s(body?.signature, 120);
  if (signature.length < 2) errors.push('signature');
  const description = s(body?.description, 2000) || null;
  const locale = s(body?.locale, 10) || null;
  if (errors.length) return { ok: false, errors };
  return {
    ok: true,
    form: { fullName, email, phone, role: role!, representedPerson, contentLocations, description, signature, locale },
  };
}

function statementsRecord(form: NciiForm, nowMs: number) {
  return {
    depictedOrAuthorized: true,
    goodFaith: true,
    accurate: true,
    text: {
      depictedOrAuthorized: form.role === 'depicted_person'
        ? 'I am the person depicted in the intimate image(s).'
        : `I am authorized to act on behalf of the person depicted (${form.representedPerson}).`,
      goodFaith: 'I have a good-faith belief that the intimate visual depiction was published without consent.',
      accurate: 'The information in this request is accurate.',
    },
    signedAt: TS.fromMillis(nowMs),
  };
}

function refsFrom(form: NciiForm): ContentRef[] {
  return form.contentLocations.map(parseContentLocation).filter((x): x is ContentRef => !!x);
}

// ---------------------------------------------------------------------------
// Rate limiting (fixed windows, transactional counters, TTL via expireAt)
// ---------------------------------------------------------------------------

export const RATE_LIMITS = { ipPerHour: 5, ipPerDay: 20, emailPerDay: 5, uidPerDay: 5, globalPerHour: 300 };
const RATE_SALT = () => process.env.RATE_LIMIT_SALT || process.env.RETENTION_SALT || 'greengo-safety-rate-v1';
const hashKey = (v: string) => crypto.createHash('sha256').update(`${RATE_SALT()}:${v}`).digest('hex').slice(0, 32);

/** Increments every counter; false when any is over its cap (nothing else is written then). */
export async function takeRateLimit(keys: Array<{ key: string; cap: number; windowMs: number }>, nowMs = Date.now()): Promise<boolean> {
  const refs = keys.map((k) => ({
    ...k,
    ref: db().collection('safety_rate_limits').doc(`${k.key}_${Math.floor(nowMs / k.windowMs)}`),
  }));
  return db().runTransaction(async (tx) => {
    const snaps = await Promise.all(refs.map((r) => tx.get(r.ref)));
    for (let i = 0; i < refs.length; i++) {
      if (((snaps[i].data()?.count as number) || 0) >= refs[i].cap) return false;
    }
    refs.forEach((r, i) => tx.set(r.ref, {
      count: ((snaps[i].data()?.count as number) || 0) + 1,
      expireAt: TS.fromMillis(nowMs + 2 * r.windowMs),
    }, { merge: true }));
    return true;
  });
}

function clientIp(req: any): string {
  const xff = String(req.headers?.['x-forwarded-for'] || '').split(',')[0].trim();
  return xff || req.ip || req.socket?.remoteAddress || 'unknown';
}

// ---------------------------------------------------------------------------
// Public HTTPS endpoint
// ---------------------------------------------------------------------------

const escHtml = (x: string) => x.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c] as string));

function page(title: string, body: string): string {
  return `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">`
    + `<title>${escHtml(title)}</title></head><body style="font-family:Arial,sans-serif;max-width:560px;margin:40px auto;padding:0 16px">`
    + `<h2>${escHtml(title)}</h2>${body}</body></html>`;
}

async function caseByToken(caseId: string, token: string): Promise<FirebaseFirestore.DocumentSnapshot | null> {
  if (!/^[A-Za-z0-9]{10,40}$/.test(caseId) || !/^[0-9a-f]{48}$/.test(token)) return null;
  const snap = await db().collection(SAFETY_CASES).doc(caseId).get();
  const want = snap.data()?.statusTokenHash;
  if (!snap.exists || typeof want !== 'string') return null;
  const got = tokenHash(token);
  return crypto.timingSafeEqual(Buffer.from(want), Buffer.from(got)) ? snap : null;
}

/** Express-style handler (exported for tests). */
export async function handleNciiHttp(req: any, res: any, nowMs = Date.now()): Promise<void> {
  res.set('Cache-Control', 'no-store');
  res.set('X-Content-Type-Options', 'nosniff');
  try {
    if (req.method === 'GET') {
      const action = String(req.query?.action || '');
      const snap = await caseByToken(String(req.query?.case || ''), String(req.query?.token || ''));
      if (!snap) {
        res.status(404).send(page('Request not found', '<p>This link is invalid or has expired.</p>'));
        return;
      }
      const c = snap.data()!;
      if (action === 'confirm') {
        if (c.requester?.emailConfirmed !== true) {
          await snap.ref.update({ 'requester.emailConfirmed': true, 'requester.emailConfirmedAt': TS.fromMillis(nowMs), updatedAt: TS.fromMillis(nowMs) });
          await auditCase(snap.id, 'requester_email_confirmed', { uid: 'requester', role: c.requester?.role });
        }
        res.status(200).send(page('Email confirmed / E-mail confirmado',
          `<p>Thank you. Your request <b>${escHtml(snap.id.slice(0, 8))}</b> is being reviewed.</p>`
          + '<p>Obrigado. Sua solicitação está em análise.</p>'));
        return;
      }
      if (action === 'status') {
        res.status(200).json({
          reference: snap.id.slice(0, 8),
          status: c.status === 'deciding' ? 'pending_review' : c.status,
          createdAt: c.createdAt?.toDate?.().toISOString() ?? null,
          updatedAt: c.updatedAt?.toDate?.().toISOString() ?? null,
          emailConfirmed: c.requester?.emailConfirmed === true,
        });
        return;
      }
      res.status(400).json({ error: 'unknown_action' });
      return;
    }
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'method_not_allowed' });
      return;
    }
    const body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : (req.body || {});
    // Honeypot: real users never fill this hidden field. Answer like a success.
    if (typeof body.website === 'string' && body.website.trim()) {
      res.status(201).json({ ok: true, reference: crypto.randomBytes(4).toString('hex') });
      return;
    }
    const v = validateNciiForm(body);
    if ('errors' in v) {
      res.status(400).json({ error: 'invalid_request', fields: v.errors });
      return;
    }
    const form = v.form;
    const ip = clientIp(req);
    const allowed = await takeRateLimit([
      { key: `ip_h_${hashKey(ip)}`, cap: RATE_LIMITS.ipPerHour, windowMs: 3600_000 },
      { key: `ip_d_${hashKey(ip)}`, cap: RATE_LIMITS.ipPerDay, windowMs: 86_400_000 },
      { key: `em_d_${hashKey(form.email)}`, cap: RATE_LIMITS.emailPerDay, windowMs: 86_400_000 },
      { key: 'global_h', cap: RATE_LIMITS.globalPerHour, windowMs: 3600_000 },
    ], nowMs);
    if (!allowed) {
      res.status(429).json({ error: 'rate_limited', retryAfterSeconds: 3600 });
      return;
    }
    const { token, hash } = newStatusToken();
    const created = await createSafetyCase({
      kind: 'ncii',
      source: 'public_form',
      requester: {
        name: form.fullName, email: form.email, phone: form.phone, uid: null, role: form.role,
        representedPerson: form.representedPerson,
      },
      contentRefs: refsFrom(form),
      description: form.description,
      statements: statementsRecord(form, nowMs),
      signature: form.signature,
      statusTokenHash: hash,
      nowMs,
    });
    const caseId = created!.caseId;
    const host = req.get?.('host') || req.headers?.host || 'localhost';
    const base = process.env.NCII_ENDPOINT_URL || `https://${host}${String(req.path || '/').split('?')[0]}`;
    const link = (action: string) => `${base}?action=${action}&case=${encodeURIComponent(caseId)}&token=${token}`;
    const ref = caseId.slice(0, 8);
    await sendResendEmail(form.email, `GreenGo - confirm your removal request ${ref}`,
      `<p>We received your request to remove intimate content (reference <b>${ref}</b>). `
      + 'The content you identified has been hidden while we review the request (we aim to decide within 2 hours, and never later than 48 hours).</p>'
      + `<p><a href="${link('confirm')}">Confirm your email address</a> - <a href="${link('status')}">Check the status</a></p>`
      + `<p>Recebemos sua solicitação de remoção de conteúdo íntimo (referência <b>${ref}</b>). O conteúdo indicado foi ocultado durante a análise.</p>`
      + `<p><a href="${link('confirm')}">Confirmar e-mail</a> - <a href="${link('status')}">Ver status</a></p>`
      + '<p style="color:#888;font-size:12px">If you did not send this request, ignore this email.</p>');
    res.status(201).json({ ok: true, reference: ref, caseId });
  } catch (e) {
    console.error('[nciiTakedownRequest] failed', e);
    res.status(500).json({ error: 'internal' });
  }
}

export const nciiTakedownRequest = onRequest(
  {
    memory: '512MiB',
    timeoutSeconds: 120,
    cors: [/greengochat\.com$/, /greengo-chat\.web\.app$/, /greengo-chat\.firebaseapp\.com$/],
  },
  (req, res) => handleNciiHttp(req, res),
);

// ---------------------------------------------------------------------------
// In-app request (signed in)
// ---------------------------------------------------------------------------

export async function handleSubmitSafetyRequest(auth: { uid?: string; token?: Record<string, any> } | undefined, data: any, nowMs = Date.now()) {
  const uid = auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required');
  const email = s(data?.email, 254) || (typeof auth?.token?.email === 'string' ? auth!.token!.email : '');
  const v = validateNciiForm({ ...data, email }, { emailOptional: true });
  if ('errors' in v) throw new HttpsError('invalid-argument', `Missing or invalid: ${v.errors.join(', ')}`, { fields: v.errors });
  const ok = await takeRateLimit([{ key: `uid_d_${hashKey(uid)}`, cap: RATE_LIMITS.uidPerDay, windowMs: 86_400_000 }], nowMs);
  if (!ok) throw new HttpsError('resource-exhausted', 'Too many requests today. Contact support if this is urgent.');
  const form = v.form;
  const created = await createSafetyCase({
    kind: 'ncii',
    source: 'in_app_form',
    requester: {
      name: form.fullName, email: form.email || null, phone: form.phone, uid, role: form.role,
      representedPerson: form.representedPerson,
    },
    contentRefs: refsFrom(form),
    description: form.description,
    statements: statementsRecord(form, nowMs),
    signature: form.signature,
    nowMs,
  });
  return { ok: true, caseId: created!.caseId, reference: created!.caseId.slice(0, 8) };
}

export const submitSafetyRequest = onCall(
  { memory: '512MiB', timeoutSeconds: 120 },
  async (request) => handleSubmitSafetyRequest(request.auth as any, request.data),
);

// ---------------------------------------------------------------------------
// Admin panel: one callable, op-routed (fewer deployed functions)
// ---------------------------------------------------------------------------

const OPEN = ['pending_review', 'deciding'];
const iso = (v: any) => (v?.toDate ? v.toDate().toISOString() : null);

function summary(id: string, c: Record<string, any>, superAdmin: boolean) {
  const hidden = Array.isArray(c.hidden) ? c.hidden : [];
  return {
    caseId: id,
    kind: c.kind,
    status: c.status,
    source: c.source,
    createdAt: iso(c.createdAt),
    escalateAt: iso(c.escalateAt),
    slaTargetAt: iso(c.slaTargetAt),
    slaMaxAt: iso(c.slaMaxAt),
    decidedAt: iso(c.decidedAt),
    escalationLevel: c.escalationLevel ?? 0,
    reportedUserId: c.reportedUserId ?? null,
    hiddenCount: hidden.filter((h: any) => h.type !== 'unresolved').length,
    unresolvedCount: hidden.filter((h: any) => h.type === 'unresolved').length,
    hideErrors: (c.hideErrors || []).length,
    requesterRole: c.requester?.role ?? null,
    emailConfirmed: c.requester?.emailConfirmed === true,
    hashMatch: c.hashMatch ? { list: c.hashMatch.list, how: c.hashMatch.how } : null,
    legalHoldId: superAdmin ? c.legalHoldId ?? null : (c.legalHoldId ? 'active' : null),
    reportedTo: (c.reportedTo || []).map((r: any) => ({ authority: r.authority, at: iso(r.at) })),
  };
}

async function adminAudit(adminId: string, role: string, action: string, targetType: string, targetId: string, details: Record<string, unknown> = {}) {
  await db().collection('admin_audit_log').add({
    adminId, adminRole: role, action, targetType, targetId, details,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function toHttps(e: any): never {
  if (e instanceof HttpsError) throw e;
  if (e?.httpsCode) throw new HttpsError(e.httpsCode, e.message);
  console.error('[safetyAdmin] failed', e);
  throw new HttpsError('internal', 'Safety admin action failed');
}

export async function handleSafetyAdmin(auth: any, data: any): Promise<any> {
  const op = String(data?.op || '');
  // Every op needs at least a moderator; some are superAdmin only (below).
  const who = await requireAdmin(auth, MODERATION_ROLES);
  const isSuper = who.role === 'superAdmin';
  const needSuper = async () => { await requireAdmin(auth, SUPER_ADMIN_ONLY); };
  const caseRef = (id: unknown) => {
    if (typeof id !== 'string' || !/^[A-Za-z0-9_-]{6,200}$/.test(id)) throw new HttpsError('invalid-argument', 'caseId required');
    return db().collection(SAFETY_CASES).doc(id);
  };
  try {
    switch (op) {
      case 'list': {
        const limit = Math.min(Math.max(Number(data.limit) || 25, 1), 50);
        const status = typeof data.status === 'string' ? data.status : 'open';
        let q: FirebaseFirestore.Query = db().collection(SAFETY_CASES);
        if (data.kind === 'ncii' || data.kind === 'csae') q = q.where('kind', '==', data.kind);
        if (status === 'open') q = q.where('status', 'in', OPEN).orderBy('slaTargetAt', 'asc');
        else if (['confirmed', 'restored'].includes(status)) q = q.where('status', '==', status).orderBy('createdAt', 'desc');
        else q = q.orderBy('createdAt', 'desc');
        if (typeof data.startAfter === 'string' && data.startAfter) {
          const cur = await caseRef(data.startAfter).get();
          if (cur.exists) q = q.startAfter(cur);
        }
        const snap = await q.limit(limit).get();
        return { cases: snap.docs.map((d) => summary(d.id, d.data(), isSuper)), nextCursor: snap.size === limit ? snap.docs[snap.size - 1].id : null };
      }
      case 'get': {
        const ref = caseRef(data.caseId);
        const snap = await ref.get();
        if (!snap.exists) throw new HttpsError('not-found', 'Case not found');
        const c = snap.data()!;
        const audit = (await ref.collection('audit').orderBy('at', 'asc').limit(200).get()).docs.map((d) => ({
          id: d.id, action: d.data().action, actorUid: d.data().actorUid, actorRole: d.data().actorRole,
          at: iso(d.data().at), details: d.data().details ?? {},
        }));
        await adminAudit(who.uid, who.role, 'safety_view_case', 'safety_case', snap.id, { kind: c.kind });
        return {
          ...summary(snap.id, c, isSuper),
          // NCII: the moderator must be able to contact / verify the requester.
          requester: c.kind === 'ncii' || isSuper ? {
            name: c.requester?.name ?? null, email: c.requester?.email ?? null, phone: c.requester?.phone ?? null,
            uid: c.requester?.uid ?? null, role: c.requester?.role ?? null, representedPerson: c.requester?.representedPerson ?? null,
            emailConfirmed: c.requester?.emailConfirmed === true,
          } : { role: c.requester?.role ?? null, uid: c.requester?.uid ? 'present' : null },
          description: c.description ?? null,
          statements: c.statements?.text ?? null,
          signature: c.signature ?? null,
          contentRefs: c.contentRefs ?? [],
          hidden: (c.hidden || []).map((h: any) => ({
            type: h.type, path: h.path ?? h.docPath ?? h.value ?? null, missing: !!h.missing,
            reason: h.reason ?? null, field: h.field ?? null, urls: h.urls?.length ?? 0,
            hashed: !!h.hashes,
          })),
          hideErrorsList: c.hideErrors ?? [],
          sourceReport: c.sourceReport ?? null,
          decision: c.decision ?? null,
          audit,
        };
      }
      case 'viewContent': {
        // NCII only: short-lived links to the HELD copies so the moderator can
        // verify. Never for CSAE (no viewing / downloading of CSAM).
        const snap = await caseRef(data.caseId).get();
        const c = snap.data();
        if (!c) throw new HttpsError('not-found', 'Case not found');
        if (c.kind !== 'ncii') throw new HttpsError('permission-denied', 'CSAE content is never shown in the panel');
        const bucket = admin.storage().bucket();
        const urls: Array<{ path: string; url: string }> = [];
        for (const h of (c.hidden || []) as any[]) {
          if (h.type === 'storage' && h.holdPath && (await bucket.file(h.holdPath).exists())[0]) {
            const [url] = await bucket.file(h.holdPath).getSignedUrl({ action: 'read', expires: Date.now() + 5 * 60_000, version: 'v4' });
            urls.push({ path: h.path, url });
          }
        }
        await auditCase(snap.id, 'content_viewed', who, { items: urls.length });
        await adminAudit(who.uid, who.role, 'safety_view_content', 'safety_case', snap.id);
        return { urls, expiresInSeconds: 300 };
      }
      case 'decide': {
        const decision = data.decision === 'restore' ? 'restore' : data.decision === 'confirm' ? 'confirm' : null;
        if (!decision) throw new HttpsError('invalid-argument', 'decision must be confirm or restore');
        const sanction: Sanction = SANCTIONS.includes(data.sanction) ? data.sanction : 'none';
        const ref = caseRef(data.caseId);
        const c = (await ref.get()).data();
        if (!c) throw new HttpsError('not-found', 'Case not found');
        // Restoring CSAE-flagged content is a superAdmin decision.
        if (c.kind === 'csae' && decision === 'restore') await needSuper();
        const notes = s(data.notes, 2000) || null;
        return await decideSafetyCase({ caseId: ref.id, decision, sanction: decision === 'restore' ? 'none' : sanction, notes, admin: { uid: who.uid, role: who.role } });
      }
      case 'reportPackage': {
        await needSuper();
        const authority = AUTHORITIES.includes(data.authority) ? data.authority as Authority : null;
        if (!authority) throw new HttpsError('invalid-argument', `authority must be one of ${AUTHORITIES.join(', ')}`);
        const ref = caseRef(data.caseId);
        const c = (await ref.get()).data();
        if (!c) throw new HttpsError('not-found', 'Case not found');
        if (c.kind !== 'csae') throw new HttpsError('failed-precondition', 'Report packages are for CSAE cases');
        const out = await buildReportPackage({ caseId: ref.id, caseData: c, authority, generatedBy: who.uid });
        await auditCase(ref.id, 'report_package_generated', who, { authority, packageId: out.packageId });
        await adminAudit(who.uid, who.role, 'safety_report_package', 'safety_case', ref.id, { authority });
        return out;
      }
      case 'markReported': {
        await needSuper();
        const authority = AUTHORITIES.includes(data.authority) ? data.authority as Authority : null;
        const reference = s(data.reference, 120);
        if (!authority || reference.length < 3) throw new HttpsError('invalid-argument', 'authority and reference required');
        const ref = caseRef(data.caseId);
        const c = (await ref.get()).data();
        if (!c) throw new HttpsError('not-found', 'Case not found');
        await ref.update({
          reportedTo: admin.firestore.FieldValue.arrayUnion({ authority, reference, at: TS.now(), by: who.uid }),
          updatedAt: TS.now(),
        });
        await auditCase(ref.id, 'marked_reported', who, { authority, reference });
        await adminAudit(who.uid, who.role, 'safety_mark_reported', 'safety_case', ref.id, { authority });
        return { ok: true };
      }
      case 'listHolds': {
        await needSuper();
        const snap = await db().collection(LEGAL_HOLDS).orderBy('createdAt', 'desc').limit(Math.min(Number(data.limit) || 50, 100)).get();
        await adminAudit(who.uid, who.role, 'safety_view_legal_hold', 'legal_holds', 'list');
        return {
          holds: snap.docs.map((d) => {
            const h = d.data();
            return {
              holdId: d.id, subjectUid: h.subjectUid ?? null, status: h.status, caseIds: h.caseIds ?? [],
              createdAt: iso(h.createdAt), holdUntil: iso(h.holdUntil), preservedAt: iso(h.preservedAt),
              preservedDocs: h.preservedDocs ?? 0, preservedFiles: h.preservedFiles ?? 0,
              subjectDeletionRequestedAt: iso(h.subjectDeletionRequestedAt), reason: h.reason ?? null,
            };
          }),
        };
      }
      case 'getHold': {
        await needSuper();
        if (typeof data.holdId !== 'string' || !/^[A-Za-z0-9_-]{3,200}$/.test(data.holdId)) throw new HttpsError('invalid-argument', 'holdId required');
        const ref = db().collection(LEGAL_HOLDS).doc(data.holdId);
        const h = (await ref.get()).data();
        if (!h) throw new HttpsError('not-found', 'Hold not found');
        const preserved = (await ref.collection('preserved').limit(300).get()).docs.map((d) => ({
          id: d.id, path: d.data().path, capturedAt: iso(d.data().capturedAt),
        }));
        const packages = (await ref.collection('report_packages').orderBy('createdAt', 'desc').limit(20).get()).docs.map((d) => ({
          id: d.id, authority: d.data().authority?.code ?? null, caseId: d.data().caseId, createdAt: iso(d.data().createdAt),
        }));
        const [files] = await admin.storage().bucket().getFiles({ prefix: `legal_holds/${data.holdId}/files/`, maxResults: 300 });
        await adminAudit(who.uid, who.role, 'safety_view_legal_hold', 'legal_hold', data.holdId);
        return {
          holdId: data.holdId, subjectUid: h.subjectUid ?? null, status: h.status, caseIds: h.caseIds ?? [],
          createdAt: iso(h.createdAt), holdUntil: iso(h.holdUntil), reason: h.reason ?? null,
          preserved, packages, files: files.map((f) => ({ path: f.name, size: Number(f.metadata?.size ?? 0) })),
        };
      }
      case 'extendHold': {
        await needSuper();
        const days = Math.min(Math.max(Number(data.days) || 0, 1), 3650);
        if (typeof data.holdId !== 'string' || !data.holdId) throw new HttpsError('invalid-argument', 'holdId required');
        const ref = db().collection(LEGAL_HOLDS).doc(data.holdId);
        const h = (await ref.get()).data();
        if (!h) throw new HttpsError('not-found', 'Hold not found');
        const from = Math.max(h.holdUntil?.toMillis?.() ?? Date.now(), Date.now());
        await ref.update({ holdUntil: TS.fromMillis(from + days * 86_400_000), status: 'active', extendedBy: who.uid, extendedAt: TS.now() });
        await adminAudit(who.uid, who.role, 'safety_extend_legal_hold', 'legal_hold', data.holdId, { days });
        return { ok: true };
      }
      case 'importCsamHashes': {
        await needSuper();
        const entries = Array.isArray(data.entries) ? data.entries.slice(0, 5000) : [];
        if (!entries.length) throw new HttpsError('invalid-argument', 'entries required');
        const r = await importCsamEntries(entries, who.uid);
        await adminAudit(who.uid, who.role, 'safety_import_csam_hashes', 'csam_hash_list', 'import', r);
        return r;
      }
      default:
        throw new HttpsError('invalid-argument', `Unknown op: ${op}`);
    }
  } catch (e) {
    toHttps(e);
  }
}

export const safetyAdmin = onCall(
  { memory: '512MiB', timeoutSeconds: 300 },
  async (request) => handleSafetyAdmin(request.auth, request.data),
);

// ---------------------------------------------------------------------------
// Schedules
// ---------------------------------------------------------------------------

export const safetySlaSweep = onSchedule(
  { schedule: 'every 10 minutes', timeZone: 'UTC', memory: '512MiB', timeoutSeconds: 300 },
  async () => {
    const fired = await runSafetySlaSweep();
    if (fired.length) console.log(`safetySlaSweep: ${fired.length} escalation(s)`, fired.map((f) => f.stage));
  },
);

export const legalHoldExpirySweep = onSchedule(
  { schedule: 'every day 04:10', timeZone: 'UTC', memory: '512MiB', timeoutSeconds: 540 },
  async () => {
    const settings = (await db().doc('app_config/safety_settings').get()).data() || {};
    const r = await runLegalHoldExpirySweep(Date.now(), settings.autoPurgeExpiredHolds === true);
    if (r.expired.length || r.purged.length) {
      await sendSecurityAlert(`legal holds expired: ${r.expired.length} pending purge, ${r.purged.length} purged`, [
        'One or more CSAE legal holds passed their 1-year preservation date.',
        r.expired.length ? 'Expired holds are kept until a superAdmin extends them or autoPurgeExpiredHolds is enabled (counsel decision).' : '',
        'Open the admin panel Safety > Legal holds.',
      ].filter(Boolean), [SAFETY_ALERT_EMAIL]);
    }
  },
);

export { SAFETY_STATUS };
