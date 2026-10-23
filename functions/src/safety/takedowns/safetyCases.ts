/**
 * NCII + CSAE safety cases (audit BR-11, US-09, US-10, BR-14, AS-08, EU-19).
 *
 * ONE flow for:
 *   - NCII (non-consensual intimate imagery): US TAKE IT DOWN Act (valid
 *     request -> removal within 48 h, remove known copies; FTC-enforced since
 *     19 May 2026) and Brazil Decreto 12.976/2026 (removal within 2 h, block
 *     re-uploads). The 2 h target covers both.
 *   - CSAE (child sexual abuse / exploitation): immediate hide, P0 alert,
 *     1-year legal hold (legalHold.ts), report package for NCMEC / PF.
 *
 * Lifecycle of `safety_cases/{caseId}` (server-only collection):
 *
 *   pending_review --decide(confirm)--> confirmed --markReported--> (reportedTo[])
 *                 \--decide(restore)--> restored
 *
 *   On creation the referenced content is hidden IMMEDIATELY (precautionary
 *   takedown, safety first):
 *     - Storage objects are MOVED to `safety_holds/{caseId}/<path>` (no client
 *       access), so every existing download URL stops working at once;
 *     - references to them are removed from profiles (photoUrls,
 *       privatePhotoUrls) and recorded for a restore;
 *     - chat messages are replaced by the moderator placeholder (original kept
 *       in safety_cases/{id}/evidence);
 *     - image hashes go into blocked_media_hashes (provisional), so the same
 *       image cannot be re-uploaded to a public surface while under review.
 *   Then: P0 email (no personal data in the subject), in-app admin
 *   notifications, an admin_alerts row, and the SLA timers:
 *     NCII: escalate at 1 h, target 2 h, legal maximum 48 h.
 *     CSAE: escalate at 1 h, target 24 h.
 *
 *   confirm: NCII -> held copies deleted, hashes made permanent, uploader
 *            strike/suspend/ban + DSA statement of reasons, requester told.
 *            CSAE -> held copies moved into the legal hold, hashes permanent,
 *            account ALWAYS banned (Terms 19.2 a: closed immediately, without
 *            prior warning), NO notice to the uploader (no tipping-off),
 *            report package next.
 *   restore: everything put back exactly, hashes deactivated, requester told.
 *
 * Every step writes safety_cases/{id}/audit and admin actions also go to
 * admin_audit_log (which emails the security list for sensitive actions).
 *
 * The requester sees only `safety_request_status/{caseId}` (status + dates):
 * in-app by uid (firestore.rules), public-form requesters by a token link.
 */

import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import '../../shared/firebaseAdmin';
import { t as tr } from '../../shared/i18n';
import { resolveLocale } from '../../shared/i18n/recipientLocale';
import { sendSecurityAlert, shortId } from '../../security/securityEventAlerts';
import { sendResendEmail } from '../../shared/resendEmail';
import { notifyAffectedUserOfDecision } from '../moderationDecisions';
import type { DecisionEffect } from '../moderationEffects';
import { computeImageHashes, ImageHashes } from './perceptualHash';
import { addBlockedHash, setCaseHashesActive } from './hashLists';
import { ensureLegalHold, copyIntoHold } from './legalHold';
import { originalFromRendition } from '../mediaLibrary';

const db = () => admin.firestore();
const TS = admin.firestore.Timestamp;
const H = 3600_000;

export const SAFETY_CASES = 'safety_cases';
export const SAFETY_STATUS = 'safety_request_status';
export const SAFETY_HOLD_PREFIX = 'safety_holds/';
/** Always told about P0 safety cases (owner request), on top of SECURITY_ALERT_EMAILS. */
export const SAFETY_ALERT_EMAIL = 'greengochat.com@gmail.com';
const MAX_HASH_BYTES = 25 * 1024 * 1024;

export type SafetyKind = 'ncii' | 'csae';
export type CaseSource = 'public_form' | 'in_app_form' | 'user_report' | 'hash_match' | 'admin';
export type CaseStatus = 'pending_review' | 'confirmed' | 'restored';

export const SLA: Record<SafetyKind, { escalateMs: number; targetMs: number; maxMs: number }> = {
  ncii: { escalateMs: 1 * H, targetMs: 2 * H, maxMs: 48 * H },
  csae: { escalateMs: 1 * H, targetMs: 24 * H, maxMs: 24 * H },
};

export interface ContentRef {
  /** storage: object path; profile: uid; message: Firestore doc path; url: unresolved link. */
  type: 'storage' | 'profile' | 'message' | 'url';
  value: string;
}

export interface Requester {
  name: string | null;
  email: string | null;
  phone: string | null;
  uid: string | null;
  role: 'depicted_person' | 'authorized_representative' | 'reporter' | 'system';
  representedPerson?: string | null;
}

// ---------------------------------------------------------------------------
// Content-location parsing
// ---------------------------------------------------------------------------

const STORAGE_PREFIXES = [
  'profiles/', 'communities/', 'chat_images/', 'group_media/', 'storefronts/', 'video_profiles/',
  'voice_intros/', 'chat_videos/', 'support_attachments/', 'users/',
  'library_renditions/',
];
const MESSAGE_PATH = /^(conversations|groups|communities|events)\/[^/]+\/messages\/[^/]+$/;
const APP_HOSTS = /(^|\.)greengochat\.com$|^greengo-chat\.web\.app$|^greengo-chat\.firebaseapp\.com$/;
const UID_RE = /^[A-Za-z0-9_-]{6,128}$/;

/** Object path of a Firebase Storage download URL / gs:// URL (null otherwise). */
export function storagePathFromUrl(url: string): string | null {
  try {
    if (url.startsWith('gs://')) {
      const rest = url.slice(5);
      return rest.slice(rest.indexOf('/') + 1) || null;
    }
    const u = new URL(url);
    const m = u.pathname.match(/\/o\/([^/]+)$/);
    if (m) return decodeURIComponent(m[1]);
    if (u.hostname === 'storage.googleapis.com') {
      return u.pathname.split('/').filter(Boolean).slice(1).map(decodeURIComponent).join('/') || null;
    }
  } catch {
    /* not a URL */
  }
  return null;
}

/**
 * What a requester typed/pasted -> a content reference. Unknown links stay
 * `url` (kept on the case for a moderator to act on by hand).
 */
export function parseContentLocation(raw: unknown): ContentRef | null {
  const s = typeof raw === 'string' ? raw.trim().slice(0, 1000) : '';
  if (!s) return null;
  if (/^profile:/.test(s)) {
    const uid = s.slice(8).trim();
    return UID_RE.test(uid) ? { type: 'profile', value: uid } : { type: 'url', value: s };
  }
  if (MESSAGE_PATH.test(s)) return { type: 'message', value: s };
  if (STORAGE_PREFIXES.some((p) => s.startsWith(p)) && !s.includes('..')) return { type: 'storage', value: s };
  const sp = storagePathFromUrl(s);
  if (sp && !sp.includes('..')) return { type: 'storage', value: sp };
  try {
    const u = new URL(s);
    if (APP_HOSTS.test(u.hostname)) {
      const m = u.pathname.match(/^\/(?:u|profile)\/([A-Za-z0-9_-]{6,128})\/?$/);
      if (m) return { type: 'profile', value: m[1] };
    }
  } catch {
    /* free text */
  }
  return { type: 'url', value: s };
}

// ---------------------------------------------------------------------------
// Hiding / restoring content
// ---------------------------------------------------------------------------

export interface HiddenItem {
  type: 'storage' | 'profileRef' | 'message' | 'unresolved';
  path?: string;
  holdPath?: string | null;
  missing?: boolean;
  hashes?: ImageHashes | null;
  contentType?: string | null;
  /** profileRef: the doc and field the URLs were removed from. */
  docPath?: string;
  field?: string;
  urls?: string[];
  /** message: the evidence doc with the original fields. */
  evidenceId?: string;
  value?: string;
  reason?: string;
  /** Uploader / sender when known (object metadata userId, message senderId). */
  ownerUid?: string | null;
}

async function auditCase(caseId: string, action: string, actor: { uid: string; role?: string }, details: Record<string, unknown> = {}) {
  await db().collection(SAFETY_CASES).doc(caseId).collection('audit').add({
    action,
    actorUid: actor.uid,
    actorRole: actor.role ?? null,
    details,
    at: TS.now(),
  });
}

/** Moves one Storage object into the case hold and blocks its hashes (provisionally). */
async function holdStorageObject(caseId: string, kind: SafetyKind, path: string): Promise<HiddenItem> {
  const bucket = admin.storage().bucket();
  const src = bucket.file(path);
  const [exists] = await src.exists();
  if (!exists) return { type: 'storage', path, holdPath: null, missing: true };
  const [meta] = await src.getMetadata();
  const contentType = (meta.contentType as string) || null;
  const ownerUid = typeof (meta.metadata as any)?.userId === 'string' ? String((meta.metadata as any).userId) : null;
  let hashes: ImageHashes | null = null;
  if ((contentType || '').startsWith('image/') || /\.(jpe?g|png|webp|gif|heic|heif|bmp)$/i.test(path)) {
    if (Number(meta.size || 0) <= MAX_HASH_BYTES) {
      try {
        const [buf] = await src.download();
        hashes = await computeImageHashes(buf);
      } catch (e) {
        console.error(`[safetyCases] could not hash ${path}:`, (e as Error)?.message || e);
      }
    }
  }
  const holdPath = `${SAFETY_HOLD_PREFIX}${caseId}/${path}`;
  await src.copy(bucket.file(holdPath));
  await src.delete({ ignoreNotFound: true });
  if (hashes) {
    await addBlockedHash({ hashes, kind, caseId, provisional: true, sourcePath: path });
  }
  return { type: 'storage', path, holdPath, hashes, contentType, ownerUid };
}

/**
 * Holds [path] and, when it is a "My pictures" reduced copy, the original
 * upload too (moving the original also drops its library item and every
 * other copy, mediaLibrary.handleLibraryObjectDeleted).
 */
async function holdWithOriginal(caseId: string, kind: SafetyKind, path: string): Promise<HiddenItem[]> {
  const out = [await holdStorageObject(caseId, kind, path)];
  const original = originalFromRendition(path);
  if (original && !original.includes('..')) out.push(await holdStorageObject(caseId, kind, original));
  return out;
}

/** Removes every URL that points at [path] from the uid's profile photo arrays. */
async function unlinkFromProfile(uid: string, paths: Set<string>): Promise<HiddenItem[]> {
  const out: HiddenItem[] = [];
  for (const [col, fields] of [['profiles', ['photoUrls', 'privatePhotoUrls']], ['profiles_private', ['privatePhotoUrls']]] as const) {
    const ref = db().collection(col).doc(uid);
    const d = (await ref.get()).data();
    if (!d) continue;
    for (const field of fields) {
      const arr = Array.isArray(d[field]) ? (d[field] as unknown[]).filter((x): x is string => typeof x === 'string') : [];
      const hit = arr.filter((u) => {
        const p = storagePathFromUrl(u);
        return !!p && paths.has(p);
      });
      if (hit.length) {
        await ref.update({ [field]: admin.firestore.FieldValue.arrayRemove(...hit) });
        out.push({ type: 'profileRef', docPath: ref.path, field, urls: hit });
      }
    }
  }
  return out;
}

const MESSAGE_URL_FIELDS = ['content', 'mediaUrl', 'imageUrl', 'videoUrl', 'fileUrl', 'thumbnailUrl', 'url', 'photoUrl', 'audioUrl'];
const MESSAGE_TEXT_FIELDS = ['content', 'text', 'caption', 'translatedContent', 'translatedText', 'originalContent'];

async function hideMessage(caseId: string, kind: SafetyKind, path: string): Promise<HiddenItem[]> {
  const ref = db().doc(path);
  const snap = await ref.get();
  if (!snap.exists) return [{ type: 'unresolved', value: path, reason: 'message_not_found' }];
  const d = snap.data() || {};
  const out: HiddenItem[] = [];
  // Media referenced by the message (image messages keep the URL in `content`).
  const urls = new Set<string>();
  for (const f of MESSAGE_URL_FIELDS) if (typeof d[f] === 'string') urls.add(d[f]);
  if (d.metadata && typeof d.metadata === 'object') {
    for (const v of Object.values(d.metadata)) if (typeof v === 'string') urls.add(v);
  }
  for (const u of urls) {
    const p = storagePathFromUrl(u);
    if (p && !p.includes('..')) out.push(...await holdWithOriginal(caseId, kind, p));
  }
  const evidenceRef = db().collection(SAFETY_CASES).doc(caseId).collection('evidence').doc();
  const original: Record<string, unknown> = {};
  for (const f of [...MESSAGE_TEXT_FIELDS, 'type', 'isDeletedForEveryone', 'isDeleted', 'metadata']) {
    if (f in d) original[f] = d[f];
  }
  await evidenceRef.set({ path, kind: 'message', original, presentFields: Object.keys(d), capturedAt: TS.now() });
  const placeholder = tr('en', 'srvMessageRemovedByModerator');
  const patch: Record<string, unknown> = {
    isDeletedForEveryone: true,
    isDeleted: true,
    'metadata.systemKey': 'srvMessageRemovedByModerator',
    safetyHidden: { caseId, at: TS.now() },
  };
  for (const f of MESSAGE_TEXT_FIELDS) if (typeof d[f] === 'string') patch[f] = f === 'content' || f === 'text' ? placeholder : '';
  if (d.type && d.type !== 'text') patch.type = 'text';
  await ref.update(patch);
  out.push({ type: 'message', path, evidenceId: evidenceRef.id, ownerUid: typeof d.senderId === 'string' ? d.senderId : null });
  return out;
}

/**
 * Hides everything [refs] points at. Never throws: per-item failures are
 * recorded so the moderator sees what still needs a manual action.
 */
export async function hideContent(caseId: string, kind: SafetyKind, refs: ContentRef[]): Promise<{ hidden: HiddenItem[]; errors: string[] }> {
  const hidden: HiddenItem[] = [];
  const errors: string[] = [];
  for (const r of refs) {
    try {
      if (r.type === 'storage') {
        hidden.push(...await holdWithOriginal(caseId, kind, r.value));
        const m = r.value.match(/^profiles\/([^/]+)\//);
        if (m) hidden.push(...await unlinkFromProfile(m[1], new Set([r.value])));
      } else if (r.type === 'profile') {
        const d = (await db().collection('profiles').doc(r.value).get()).data() || {};
        const priv = (await db().collection('profiles_private').doc(r.value).get()).data() || {};
        const paths = new Set<string>();
        for (const u of [...(d.photoUrls || []), ...(d.privatePhotoUrls || []), ...(priv.privatePhotoUrls || [])]) {
          const p = typeof u === 'string' ? storagePathFromUrl(u) : null;
          if (p && !p.includes('..')) paths.add(p);
        }
        for (const p of paths) hidden.push(...await holdWithOriginal(caseId, kind, p));
        hidden.push(...await unlinkFromProfile(r.value, paths));
        if (paths.size === 0) hidden.push({ type: 'unresolved', value: `profile:${r.value}`, reason: 'no_photos' });
      } else if (r.type === 'message') {
        hidden.push(...await hideMessage(caseId, kind, r.value));
      } else {
        hidden.push({ type: 'unresolved', value: r.value, reason: 'manual_review' });
      }
    } catch (e: any) {
      console.error(`[safetyCases] hide failed for ${caseId} ${r.type}:`, e?.message || e);
      errors.push(`${r.type}:${String(e?.message || e).slice(0, 200)}`);
    }
  }
  return { hidden, errors };
}

/** Puts back everything hideContent removed. */
export async function restoreContent(caseId: string, hidden: HiddenItem[]): Promise<string[]> {
  const bucket = admin.storage().bucket();
  const errors: string[] = [];
  // Unblock first: copying an image back fires moderateUploadedImage, which
  // must not find its own provisional hash and hide it again.
  await setCaseHashesActive(caseId, false);
  for (const h of hidden) {
    try {
      if (h.type === 'storage' && h.holdPath && h.path) {
        const held = bucket.file(h.holdPath);
        if ((await held.exists())[0]) {
          await held.copy(bucket.file(h.path));
          await held.delete({ ignoreNotFound: true });
        }
      } else if (h.type === 'profileRef' && h.docPath && h.field && h.urls?.length) {
        await db().doc(h.docPath).update({ [h.field]: admin.firestore.FieldValue.arrayUnion(...h.urls) });
      } else if (h.type === 'message' && h.path && h.evidenceId) {
        const ev = (await db().collection(SAFETY_CASES).doc(caseId).collection('evidence').doc(h.evidenceId).get()).data();
        if (ev) {
          const present = new Set<string>(ev.presentFields || []);
          // update() replaces whole top-level values (metadata map included).
          const patch: Record<string, unknown> = { ...(ev.original || {}), safetyHidden: admin.firestore.FieldValue.delete() };
          for (const f of ['isDeletedForEveryone', 'isDeleted', 'metadata', 'type', ...MESSAGE_TEXT_FIELDS]) {
            if (!present.has(f)) patch[f] = admin.firestore.FieldValue.delete();
          }
          await db().doc(h.path).update(patch);
        }
      }
    } catch (e: any) {
      errors.push(`${h.type}:${h.path || h.docPath || ''}:${String(e?.message || e).slice(0, 120)}`);
    }
  }
  return errors;
}

// ---------------------------------------------------------------------------
// Alerts
// ---------------------------------------------------------------------------

async function safetySettings(): Promise<Record<string, any>> {
  return (await db().doc('app_config/safety_settings').get()).data() || {};
}

function panelLink(settings: Record<string, any>, caseId: string): string {
  const base = typeof settings.adminPanelUrl === 'string' && settings.adminPanelUrl
    ? settings.adminPanelUrl.replace(/\/+$/, '')
    : 'https://greengo-chat-admin.web.app';
  return `${base}/safety/${encodeURIComponent(caseId)}`;
}

const KIND_LABEL: Record<SafetyKind, string> = {
  ncii: 'NCII takedown (intimate image without consent)',
  csae: 'CSAE (child sexual abuse / exploitation)',
};

/**
 * P0 email + in-app admin notifications + admin_alerts row. Ids only: no
 * names, emails, URLs of the content or descriptions. Best effort.
 */
export async function alertSafetyCase(caseId: string, kind: SafetyKind, stage: 'opened' | 'escalation' | 'sla_breach' | 'legal_max_breach' | 'hash_match', due: Date | null): Promise<void> {
  const settings = await safetySettings();
  const extra = [SAFETY_ALERT_EMAIL, ...(Array.isArray(settings.onCallEmails) ? settings.onCallEmails : [])];
  const subjects: Record<typeof stage, string> = {
    opened: `P0 ${kind.toUpperCase()} case opened - content hidden, decide by ${due ? due.toISOString().slice(11, 16) + ' UTC' : 'SLA'}`,
    hash_match: `P0 ${kind.toUpperCase()} re-upload blocked by hash match - review`,
    escalation: `ESCALATION: ${kind.toUpperCase()} case not handled within 1h`,
    sla_breach: `SLA BREACHED: ${kind.toUpperCase()} case past its ${kind === 'ncii' ? '2h' : '24h'} target`,
    legal_max_breach: `LEGAL DEADLINE BREACHED: ${kind.toUpperCase()} case past 48h`,
  };
  const subject = `${subjects[stage]} (case ${shortId(caseId)})`;
  try {
    await sendSecurityAlert(subject, [
      `${KIND_LABEL[kind]} - ${stage.replace(/_/g, ' ')}.`,
      `Case: ${shortId(caseId)}`,
      due ? `Decision due: ${due.toISOString()}` : '',
      `Open the Safety queue: ${panelLink(settings, caseId)}`,
      kind === 'csae'
        ? 'Do not download, forward or screenshot any image. Follow docs/safety/csae-ncii-runbook.md (legal hold is active; NCMEC / PF report from the panel).'
        : 'The content is already hidden. Confirm the removal or restore it in the panel; the requester is notified automatically.',
    ].filter(Boolean), extra);
  } catch (e) {
    console.error('[safetyCases] alert email failed', e);
  }
  try {
    await db().collection('admin_alerts').doc(`safety_${stage}_${caseId}`).set({
      type: 'safety_p0',
      stage,
      kind,
      caseId,
      dueAt: due ? TS.fromDate(due) : null,
      status: 'open',
      createdAt: TS.now(),
    });
    const admins = await db().collection('admin_users').where('role', 'in', ['superAdmin', 'super_admin', 'moderator', 'admin']).limit(50).get();
    const batch = db().batch();
    for (const a of admins.docs) {
      batch.set(db().collection('notifications').doc(`safety_${stage}_${caseId}_${a.id}`), {
        userId: a.id,
        type: 'system',
        title: subjects[stage],
        message: `Safety case ${shortId(caseId)} needs action.`,
        body: `Safety case ${shortId(caseId)} needs action.`,
        data: { action: 'safety_case', caseId, stage },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  } catch (e) {
    console.error('[safetyCases] in-app alert failed', e);
  }
}

// ---------------------------------------------------------------------------
// Case creation
// ---------------------------------------------------------------------------

export interface CreateCaseInput {
  kind: SafetyKind;
  source: CaseSource;
  requester: Requester;
  contentRefs: ContentRef[];
  reportedUserId?: string | null;
  description?: string | null;
  statements?: Record<string, unknown> | null;
  signature?: string | null;
  sourceReport?: { collection: string; id: string; queueId: string } | null;
  hashMatch?: Record<string, unknown> | null;
  /** Content already moved by the caller (upload screening). */
  preHidden?: HiddenItem[];
  /** sha256 of the public status token (public form only). */
  statusTokenHash?: string | null;
  /** Deterministic id (report-driven cases: one case per queue item). */
  caseId?: string;
  nowMs?: number;
}

export function escalationStages(kind: SafetyKind, createdMs: number): Array<{ level: number; stage: 'escalation' | 'sla_breach' | 'legal_max_breach'; at: number }> {
  const s = SLA[kind];
  const stages: Array<{ level: number; stage: 'escalation' | 'sla_breach' | 'legal_max_breach'; at: number }> = [
    { level: 1, stage: 'escalation', at: createdMs + s.escalateMs },
    { level: 2, stage: 'sla_breach', at: createdMs + s.targetMs },
  ];
  if (s.maxMs > s.targetMs) stages.push({ level: 3, stage: 'legal_max_breach', at: createdMs + s.maxMs });
  return stages;
}

/** Infers the uploader from a held object path (profiles/{uid}/..., communities/{uid}/...). */
export function uploaderFromPath(path: string | undefined): string | null {
  const m = (path || '').match(/^(profiles|users|video_profiles|voice_intros|communities|storefronts)\/([^/]+)\//);
  return m ? m[2] : null;
}

function isAlreadyExists(e: unknown): boolean {
  const code = (e as { code?: unknown })?.code;
  return code === 6 || code === 'already-exists' || code === 'ALREADY_EXISTS';
}

/**
 * Creates the case, hides the content, opens the legal hold (CSAE), alerts.
 * Returns null when a deterministic caseId already existed.
 */
export async function createSafetyCase(input: CreateCaseInput): Promise<{ caseId: string; hidden: HiddenItem[]; errors: string[]; legalHoldId: string | null } | null> {
  const nowMs = input.nowMs ?? Date.now();
  const ref = input.caseId ? db().collection(SAFETY_CASES).doc(input.caseId) : db().collection(SAFETY_CASES).doc();
  const caseId = ref.id;
  const s = SLA[input.kind];
  const stages = escalationStages(input.kind, nowMs);
  try {
    await ref.create({
      caseId,
      kind: input.kind,
      source: input.source,
      status: 'pending_review' as CaseStatus,
      requester: {
        name: input.requester.name, email: input.requester.email, phone: input.requester.phone,
        uid: input.requester.uid, role: input.requester.role,
        representedPerson: input.requester.representedPerson ?? null,
        emailConfirmed: input.source !== 'public_form',
      },
      requesterUid: input.requester.uid,
      contentRefs: input.contentRefs,
      reportedUserId: input.reportedUserId ?? null,
      description: (input.description || '').slice(0, 2000) || null,
      statements: input.statements ?? null,
      signature: input.signature ?? null,
      sourceReport: input.sourceReport ?? null,
      hashMatch: input.hashMatch ?? null,
      statusTokenHash: input.statusTokenHash ?? null,
      reasonCode: input.kind,
      priorityLevel: 'P0',
      hidden: input.preHidden ?? [],
      hideErrors: [],
      createdAt: TS.fromMillis(nowMs),
      updatedAt: TS.fromMillis(nowMs),
      escalateAt: TS.fromMillis(nowMs + s.escalateMs),
      slaTargetAt: TS.fromMillis(nowMs + s.targetMs),
      slaMaxAt: TS.fromMillis(nowMs + s.maxMs),
      escalationLevel: 0,
      nextEscalationAt: TS.fromMillis(stages[0].at),
      legalHoldId: null,
      reportedTo: [],
    });
  } catch (e) {
    if (isAlreadyExists(e)) return null;
    throw e;
  }
  await db().collection(SAFETY_STATUS).doc(caseId).set({
    caseId,
    kind: input.kind,
    requesterUid: input.requester.uid ?? null,
    status: 'pending_review',
    createdAt: TS.fromMillis(nowMs),
    updatedAt: TS.fromMillis(nowMs),
  });
  await auditCase(caseId, 'created', { uid: input.requester.uid || input.source, role: input.requester.role }, {
    source: input.source, refs: input.contentRefs.length,
  });

  const { hidden, errors } = await hideContent(caseId, input.kind, input.contentRefs);
  const allHidden = [...(input.preHidden ?? []), ...hidden];
  const reportedUserId = input.reportedUserId
    ?? allHidden.map((h) => uploaderFromPath(h.path) || h.ownerUid).find((x) => !!x)
    ?? null;
  await ref.update({ hidden: allHidden, hideErrors: errors, hiddenAt: TS.now(), reportedUserId, updatedAt: TS.now() });
  await auditCase(caseId, 'content_hidden', { uid: 'system' }, {
    items: allHidden.filter((h) => h.type !== 'unresolved').length,
    unresolved: allHidden.filter((h) => h.type === 'unresolved').length,
    errors: errors.length,
  });

  let legalHoldId: string | null = null;
  if (input.kind === 'csae') {
    try {
      legalHoldId = await ensureLegalHold({
        subjectUid: reportedUserId,
        caseId,
        reason: `CSAE case ${caseId} (${input.source})`,
        createdBy: 'system',
        extraFiles: allHidden.filter((h) => h.type === 'storage' && h.holdPath).map((h) => h.holdPath as string),
        nowMs,
      });
      await ref.update({ legalHoldId });
      await auditCase(caseId, 'legal_hold_applied', { uid: 'system' }, { holdId: legalHoldId });
    } catch (e) {
      console.error(`[safetyCases] legal hold failed for ${caseId}:`, e);
      await ref.update({ hideErrors: admin.firestore.FieldValue.arrayUnion('legal_hold_failed') });
    }
  }

  await alertSafetyCase(caseId, input.kind, input.source === 'hash_match' ? 'hash_match' : 'opened', new Date(nowMs + s.targetMs));
  return { caseId, hidden: allHidden, errors, legalHoldId };
}

// ---------------------------------------------------------------------------
// SLA escalation (scheduled every 10 minutes)
// ---------------------------------------------------------------------------

export async function runSafetySlaSweep(nowMs = Date.now()): Promise<Array<{ caseId: string; stage: string }>> {
  const due = await db().collection(SAFETY_CASES)
    .where('status', '==', 'pending_review')
    .where('nextEscalationAt', '<=', TS.fromMillis(nowMs))
    .limit(100)
    .get();
  const fired: Array<{ caseId: string; stage: string }> = [];
  for (const d of due.docs) {
    const res = await db().runTransaction(async (tx) => {
      const cur = (await tx.get(d.ref)).data();
      if (!cur || cur.status !== 'pending_review') return null;
      const next = cur.nextEscalationAt?.toMillis?.();
      if (typeof next !== 'number' || next > nowMs) return null;
      const created = cur.createdAt.toMillis();
      const stages = escalationStages(cur.kind as SafetyKind, created);
      const passed = stages.filter((x) => x.at <= nowMs && x.level > (cur.escalationLevel || 0));
      if (!passed.length) return null;
      const top = passed[passed.length - 1];
      const after = stages.find((x) => x.level > top.level);
      tx.update(d.ref, {
        escalationLevel: top.level,
        nextEscalationAt: after ? TS.fromMillis(after.at) : null,
        lastEscalatedAt: TS.fromMillis(nowMs),
        updatedAt: TS.fromMillis(nowMs),
      });
      return { stage: top.stage, kind: cur.kind as SafetyKind, due: new Date(created + SLA[cur.kind as SafetyKind].targetMs) };
    });
    if (!res) continue;
    await auditCase(d.id, `sla_${res.stage}`, { uid: 'system' }, { at: new Date(nowMs).toISOString() });
    await alertSafetyCase(d.id, res.kind, res.stage, res.due);
    fired.push({ caseId: d.id, stage: res.stage });
  }
  return fired;
}

// ---------------------------------------------------------------------------
// Decisions
// ---------------------------------------------------------------------------

export type Sanction = 'none' | 'strike' | 'suspend' | 'ban';
export const SANCTIONS: Sanction[] = ['none', 'strike', 'suspend', 'ban'];
const SUSPEND_DAYS = 30;

/**
 * The sanction actually applied when a case is confirmed. Terms 19.2 a: for
 * child sexual abuse or exploitation we "close the accounts involved,
 * immediately and without prior warning" - a confirmed CSAE case ALWAYS bans
 * (whatever the moderator picked); NCII keeps the moderator's choice.
 */
export function effectiveSanction(kind: SafetyKind, requested: Sanction): Sanction {
  return kind === 'csae' ? 'ban' : requested;
}

/**
 * Returns the effects (DSA art. 20 reversal on appeal, moderationEffects.ts).
 * The suspension / ban is tagged with the decision id `safety_<caseId>`, so
 * an appeal only lifts THIS sanction, never a newer one.
 */
async function applySanction(uid: string, sanction: Sanction, kind: SafetyKind, caseId: string, reason: string): Promise<DecisionEffect[]> {
  if (sanction === 'none') return [];
  const now = TS.now();
  const decisionId = `safety_${caseId}`;
  const strikeId = `${caseId}_${uid}`;
  const effects: DecisionEffect[] = [{ type: 'strike', userId: uid, strikeId }];
  // Every sanction is also a strike (repeat-offender record).
  await db().collection('user_strikes').doc(strikeId).set({ userId: uid, caseId, decisionId, kind, sanction, at: now, revoked: false });
  const userPatch: Record<string, unknown> = {
    safetyStrikes: admin.firestore.FieldValue.increment(1),
    lastSafetyStrikeAt: now,
  };
  const profilePatch: Record<string, unknown> = {};
  if (sanction === 'suspend') {
    const until = TS.fromMillis(Date.now() + SUSPEND_DAYS * 86_400_000);
    Object.assign(userPatch, { accountStatus: 'suspended', suspensionReason: reason, suspendedUntil: until, suspendedAt: now, suspensionDecisionId: decisionId });
    effects.push({ type: 'suspension', userId: uid });
    Object.assign(profilePatch, { accountStatus: 'suspended', status: 'suspended', suspensionReason: reason, suspendedAt: now, suspendedUntil: until });
  }
  if (sanction === 'ban') {
    Object.assign(userPatch, { accountStatus: 'banned', banReason: reason, bannedAt: now, banDecisionId: decisionId });
    effects.push({ type: 'ban', userId: uid });
    Object.assign(profilePatch, { accountStatus: 'banned', status: 'banned', banReason: reason, bannedAt: now });
    try {
      await admin.auth().updateUser(uid, { disabled: true });
    } catch (e: any) {
      if (e?.code !== 'auth/user-not-found') throw e;
    }
  }
  await db().collection('users').doc(uid).set(userPatch, { merge: true });
  if (Object.keys(profilePatch).length) {
    try {
      await db().collection('profiles').doc(uid).update(profilePatch);
    } catch (e: any) {
      if (e?.code !== 5) throw e;
    }
  }
  return effects;
}

/** Neutral outcome message to the requester (in-app when a uid, email when an address). */
async function notifyRequester(caseId: string, c: Record<string, any>, outcome: 'removed' | 'restored'): Promise<void> {
  const uid = c.requester?.uid;
  if (uid && c.source !== 'hash_match') {
    try {
      const locale = await resolveLocale(uid);
      const bodyKey = outcome === 'removed' ? 'srvReportReviewedActionTaken' as const : 'srvReportReviewedNoViolation' as const;
      await db().collection('notifications').doc(`safety_reviewed_${caseId}`).set({
        userId: uid,
        type: 'system',
        title: tr(locale, 'srvReportReviewedTitle'),
        message: tr(locale, bodyKey),
        body: tr(locale, bodyKey),
        titleKey: 'srvReportReviewedTitle',
        bodyKey,
        data: { action: 'safety_request_reviewed', caseId, outcome },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e) {
      console.error('[safetyCases] requester notification failed', e);
    }
  }
  const email = c.requester?.email;
  if (email && (c.source === 'public_form' || c.source === 'in_app_form')) {
    const ref = caseId.slice(0, 8);
    const html = outcome === 'removed'
      ? `<p>Your removal request <b>${ref}</b> has been reviewed. The content has been removed and copies of it are blocked from being uploaded again.</p>`
        + `<p>Sua solicitação de remoção <b>${ref}</b> foi analisada. O conteúdo foi removido e novas cópias estão bloqueadas.</p>`
      : `<p>Your removal request <b>${ref}</b> has been reviewed. We could not confirm it as non-consensual intimate imagery, so the content was restored. Reply to this email with more information if you believe this is wrong.</p>`
        + `<p>Sua solicitação <b>${ref}</b> foi analisada. Não foi possível confirmá-la como imagem íntima não consentida, e o conteúdo foi restabelecido. Responda a este e-mail com mais informações se considerar que houve um erro.</p>`;
    await sendResendEmail(email, `GreenGo - removal request ${ref} reviewed`, html);
  }
}

export interface DecideInput {
  caseId: string;
  decision: 'confirm' | 'restore';
  sanction: Sanction;
  notes: string | null;
  admin: { uid: string; role: string };
}

export async function decideSafetyCase(p: DecideInput): Promise<{ status: CaseStatus; hashesActivated: number }> {
  const ref = db().collection(SAFETY_CASES).doc(p.caseId);
  // Claim the decision atomically: a second moderator gets failed-precondition.
  const c = await db().runTransaction(async (tx) => {
    const cur = (await tx.get(ref)).data();
    if (!cur) throw Object.assign(new Error('Case not found'), { httpsCode: 'not-found' });
    if (cur.status !== 'pending_review') throw Object.assign(new Error(`Case is already ${cur.status}`), { httpsCode: 'failed-precondition' });
    tx.update(ref, { status: 'deciding', decidingBy: p.admin.uid, updatedAt: TS.now() });
    return cur;
  });
  const kind = c.kind as SafetyKind;
  const hidden = (c.hidden || []) as HiddenItem[];
  let status: CaseStatus;
  let hashesActivated = 0;
  let sanction: Sanction = 'none';
  try {
    if (p.decision === 'restore') {
      const errors = await restoreContent(p.caseId, hidden);
      status = 'restored';
      await ref.update({
        status, decidedAt: TS.now(), decidedBy: p.admin.uid, nextEscalationAt: null,
        decision: { action: 'restore', sanction: 'none', notes: p.notes, errors },
        updatedAt: TS.now(),
      });
      await notifyRequester(p.caseId, c, 'restored');
    } else {
      // Permanent removal. Hashes become permanent blocks.
      hashesActivated = await setCaseHashesActive(p.caseId, true);
      const bucket = admin.storage().bucket();
      for (const h of hidden) {
        if (h.type !== 'storage' || !h.holdPath) continue;
        if (kind === 'csae' && c.legalHoldId) await copyIntoHold(c.legalHoldId, h.holdPath);
        await bucket.file(h.holdPath).delete({ ignoreNotFound: true });
      }
      const uploader = c.reportedUserId as string | null;
      const reason = kind === 'ncii'
        ? 'Intimate image shared without consent (TAKE IT DOWN Act / Decreto 12.976/2026)'
        : 'Child sexual abuse or exploitation material';
      sanction = effectiveSanction(kind, p.sanction);
      const sanctionEffects = uploader ? await applySanction(uploader, sanction, kind, p.caseId, reason) : [];
      status = 'confirmed';
      await ref.update({
        status, decidedAt: TS.now(), decidedBy: p.admin.uid, nextEscalationAt: null,
        decision: { action: 'confirm', sanction, requestedSanction: p.sanction, notes: p.notes },
        updatedAt: TS.now(),
      });
      // DSA art. 17 statement of reasons to the uploader - NCII only. A CSAE
      // suspect is never told (no tipping-off before law enforcement acts).
      if (kind === 'ncii' && uploader) {
        try {
          // Content concerned: the hidden message, else the photo(s).
          const msg = hidden.find((h) => h.type === 'message');
          const photo = hidden.find((h) => h.type === 'storage');
          await notifyAffectedUserOfDecision({
            queueId: `safety_${p.caseId}`,
            userId: uploader,
            action: sanction === 'ban' ? 'banUser' : sanction === 'suspend' ? 'suspendUser' : 'removeContent',
            reasonCode: 'ncii',
            explanation: reason,
            moderatorId: p.admin.uid,
            contentRef: msg
              ? { type: 'message', id: (msg.path || '').split('/').pop() || null, excerpt: null }
              : { type: photo ? 'photo' : 'account', id: photo?.path ? photo.path.split('/').pop() || null : null, excerpt: null },
            // A hash-list match is automated detection; the removal itself was
            // confirmed by this moderator.
            automated: { detection: c.source === 'hash_match' ? 'hash' : null, decision: false },
            effects: [{ type: 'safetyCase', caseId: p.caseId }, ...sanctionEffects],
            extra: { caseId: p.caseId },
          });
        } catch (e) {
          console.error('[safetyCases] uploader notice failed', e);
        }
      }
      await notifyRequester(p.caseId, c, 'removed');
    }
  } catch (e) {
    // Release the claim so the case stays in the queue (and keeps escalating).
    await ref.update({ status: 'pending_review', decidingBy: null, updatedAt: TS.now() });
    throw e;
  }
  await db().collection(SAFETY_STATUS).doc(p.caseId).set({ status, updatedAt: TS.now() }, { merge: true });
  await auditCase(p.caseId, `decision_${p.decision}`, p.admin, { sanction, requestedSanction: p.sanction, notes: p.notes });
  await db().collection('admin_audit_log').add({
    adminId: p.admin.uid,
    adminRole: p.admin.role,
    action: p.decision === 'restore' ? 'safety_restore_content' : 'safety_confirm_removal',
    targetType: 'safety_case',
    targetId: p.caseId,
    details: { kind, sanction },
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { status, hashesActivated };
}

// ---------------------------------------------------------------------------
// Public-form tokens
// ---------------------------------------------------------------------------

export function newStatusToken(): { token: string; hash: string } {
  const token = crypto.randomBytes(24).toString('hex');
  return { token, hash: tokenHash(token) };
}

export function tokenHash(token: string): string {
  return crypto.createHash('sha256').update(`safety-status:${token}`).digest('hex');
}

export { auditCase };
