/**
 * DSA art. 17 (statement of reasons) + art. 20 (internal complaint handling),
 * plan P2-8c, Terms sections 18.3 / 18.4.
 *
 * EVERY account / content action and every decision not to act on a report
 * goes through [createModerationDecision]:
 *   - a server-only record  moderation_decisions/{decisionId}
 *       { userId, role ('affected' | 'reporter'), action, reasonCode,
 *         explanation, decidedBy, decidedAt, contentRef {type,id,excerpt},
 *         automated, automatedDetection, automatedDecision, effects[],
 *         appealable, appealDeadline, appealStatus, ... }
 *     `effects` lists what the action changed, so an overturned appeal can
 *     reverse it (moderationEffects.ts / appealResolution.ts);
 *   - one in-app notification (type 'system', so every app version renders
 *     it; push via the parity trigger) carrying the statement of reasons in
 *     `data` and the decisionId the app uses to appeal (submitAppeal);
 *   - an EMAIL with the same statement of reasons and a signed appeal link
 *     (appealPage.ts), because a banned user cannot open the app (Firebase
 *     Auth disabled). Terms 18.4 a: "in the app or by replying to our notice".
 *
 * No notice where the law forbids it: CSAE (safety/takedowns/safetyCases.ts
 * never calls this for csae cases, no tipping-off).
 *
 * Appeals (submitAppealForDecision): the decision's own user (the affected
 * user, or the REPORTER for a decision not to act on their report), once,
 * within APPEAL_WINDOW_DAYS (DSA: at least six months). Creates
 * report_appeals/{id} and a moderation_queue item 'appeal' for a human
 * reviewer who did not take the original decision.
 */
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import * as functions from 'firebase-functions/v1';
import '../shared/firebaseAdmin';
import { ArbKey, t as tr } from '../shared/i18n';
import { resolveLocale } from '../shared/i18n/recipientLocale';
import { authEmailOf, escapeHtml, OutgoingEmail, sendEmailOnce } from '../emails/sendEmail';
import { detailsTable, emailFrame, intlLocale } from '../emails/emailFormat';
import { functionsBaseUrl } from '../ticket_payments/config';
import { ticketKey } from '../ticket_payments/keys';
import { DecisionEffect } from './moderationEffects';

const db = () => admin.firestore();

export const MODERATION_DECISIONS = 'moderation_decisions';
/** DSA art. 20(1): complaints possible for at least six months. */
export const APPEAL_WINDOW_DAYS = 183;
export const APPEAL_MIN_CHARS = 10;
export const APPEAL_MAX_CHARS = 2000;
export const EXCERPT_MAX = 140;

/** Actions that restrict the user or their content (art. 17(1)). */
export const USER_AFFECTING_ACTIONS = new Set([
  'removeContent', 'issueWarning', 'suspendUser', 'banUser', 'shadowBan', 'requireVerification',
  'restrictAccount', 'reporterWarning', 'suspendReporting',
]);
/** Decision on a report made by the user (Terms 18.4 a, last bullet). */
export const REPORTER_ACTIONS = new Set(['noAction']);

export type DecisionRole = 'affected' | 'reporter';
export type ContentType =
  | 'message' | 'photo' | 'profile' | 'event' | 'experience' | 'review' | 'account' | 'report' | 'other';
export type AutomatedDetection = 'keyword' | 'vision' | 'hash';

/** Which Content a decision concerns (Terms 18.3, second bullet). */
export interface ContentReference {
  type: ContentType;
  id: string | null;
  /** Short excerpt of the user's OWN content (never a reporter's words). */
  excerpt: string | null;
}

export interface AutomatedInfo {
  /** Automated tool that detected / flagged the item, or null. */
  detection: AutomatedDetection | null;
  /** True only when the automated tool itself applied the measure (e.g. a held upload). */
  decision: boolean;
}

export function decisionNotificationId(decisionId: string): string {
  return `moderation_decision_${decisionId}`;
}

function isAlreadyExists(e: unknown): boolean {
  const code = (e as { code?: unknown })?.code;
  return code === 6 || code === 'already-exists' || code === 'ALREADY_EXISTS';
}

// ---------------------------------------------------------------------------
// Pure helpers (exported for tests)
// ---------------------------------------------------------------------------

export function excerptOf(v: unknown, max = EXCERPT_MAX): string | null {
  if (typeof v !== 'string') return null;
  const s = v.replace(/\s+/g, ' ').trim();
  if (!s) return null;
  // Media messages keep a URL in `content`: not an excerpt.
  if (/^https?:\/\//i.test(s)) return null;
  return s.length > max ? `${s.slice(0, max - 1)}…` : s;
}

/**
 * Content reference of a moderation_queue item. The excerpt is taken only
 * from fields that hold the reported user's own content (message text,
 * listing title, review text); a user_reports item's text is the REPORTER's
 * description and is never shown.
 */
export function contentReferenceFor(q: Record<string, any> | undefined | null): ContentReference {
  if (!q) return { type: 'account', id: null, excerpt: null };
  if (q.itemType === 'quarantinedImage' || q.type === 'image') {
    const p = typeof q.objectPath === 'string' ? q.objectPath : '';
    return { type: 'photo', id: p ? p.split('/').pop() || p : null, excerpt: null };
  }
  if (q.itemType === 'flaggedPhoto') return { type: 'photo', id: q.itemId ?? null, excerpt: null };
  if (q.itemType === 'flaggedMessage') return { type: 'message', id: q.itemId ?? null, excerpt: excerptOf(q.content?.text) };
  const ref = q.contentRef || {};
  const src = q.source?.collection;
  const ownText = src === 'message_reports' || src === 'auto_text' || src === 'reports';
  const excerpt = ownText ? excerptOf(q.content?.text) : null;
  switch (ref.type) {
    case 'message': return { type: 'message', id: ref.id ?? null, excerpt };
    case 'event': return { type: 'event', id: ref.id ?? null, excerpt };
    case 'experience': return { type: 'experience', id: ref.id ?? null, excerpt };
    case 'experience_review': return { type: 'review', id: ref.id ?? null, excerpt };
    case 'user': return { type: 'profile', id: null, excerpt: null };
    default: return { type: ref.type ? 'other' : 'account', id: ref.id ?? null, excerpt };
  }
}

/** Whether automated tools detected the item (Terms 17.1 b / 18.3). */
export function automationFor(q: Record<string, any> | undefined | null): AutomatedInfo {
  if (!q) return { detection: null, decision: false };
  if (q.itemType === 'quarantinedImage' || q.type === 'image') return { detection: 'vision', decision: false };
  if (q.itemType === 'autoTextFlag' || q.source?.collection === 'auto_text' || q.autoFlag) {
    return { detection: 'keyword', decision: false };
  }
  if (q.source?.collection === 'hash_match') return { detection: 'hash', decision: false };
  return { detection: null, decision: false };
}

const ACTION_KEYS: Record<string, ArbKey> = {
  removeContent: 'moderationActionRemoveContent',
  issueWarning: 'moderationActionWarning',
  suspendUser: 'moderationActionSuspend',
  banUser: 'moderationActionBan',
  shadowBan: 'moderationActionShadowBan',
  requireVerification: 'moderationActionRequireVerification',
  restrictAccount: 'moderationActionRestrict',
  noAction: 'moderationActionNoAction',
  reporterWarning: 'moderationActionReporterWarning',
  suspendReporting: 'moderationActionSuspendReporting',
};
const REASON_KEYS: Record<string, ArbKey> = {
  csae: 'moderationReasonCsae',
  ncii: 'safetyReportReasonNcii',
  underage: 'moderationReasonUnderage',
  sexual_content: 'moderationReasonSexualContent',
  inappropriate: 'moderationReasonInappropriate',
  threats: 'moderationReasonThreats',
  violence: 'moderationReasonViolence',
  harassment: 'moderationReasonHarassment',
  hate: 'moderationReasonHate',
  spam: 'moderationReasonSpam',
  scam: 'moderationReasonScam',
  impersonation: 'moderationReasonImpersonation',
  privacy: 'moderationReasonPrivacy',
  misleading: 'moderationReasonMisleading',
  no_show: 'moderationReasonNoShow',
  off_platform_payment: 'moderationReasonOffPlatformPayment',
  no_violation: 'moderationReasonNoViolation',
  unfounded_reports: 'moderationReasonUnfoundedReports',
  repeat_violations: 'moderationReasonRepeatViolations',
};
const CONTENT_KEYS: Record<ContentType, ArbKey> = {
  message: 'moderationContentTypeMessage',
  photo: 'moderationContentTypePhoto',
  profile: 'moderationContentTypeProfile',
  event: 'moderationContentTypeEvent',
  experience: 'moderationContentTypeExperience',
  review: 'moderationContentTypeReview',
  account: 'moderationContentTypeAccount',
  report: 'moderationContentTypeReport',
  other: 'moderationContentTypeOther',
};

export function actionText(locale: string, action: string): string {
  return tr(locale, ACTION_KEYS[action] ?? 'moderationActionOther');
}
export function reasonText(locale: string, code: string | null): string {
  return tr(locale, REASON_KEYS[code || 'other'] ?? 'moderationReasonOther');
}
export function contentText(locale: string, c: ContentReference | null | undefined): string {
  const ref = c ?? { type: 'account' as const, id: null, excerpt: null };
  const label = tr(locale, CONTENT_KEYS[ref.type] ?? 'moderationContentTypeOther');
  if (ref.excerpt) return `${label}: "${ref.excerpt}"`;
  if (ref.id && ref.type !== 'account' && ref.type !== 'profile') return `${label} (${ref.id.slice(0, 40)})`;
  return label;
}
export function automatedText(locale: string, a: AutomatedInfo): string {
  if (a.decision) return tr(locale, 'moderationDecisionAutomatedHeld');
  if (a.detection) return tr(locale, 'moderationDecisionAutomatedFlagged');
  return tr(locale, 'moderationDecisionAutomatedNone');
}

// ---------------------------------------------------------------------------
// Signed appeal link (web path for users who cannot open the app)
// ---------------------------------------------------------------------------

let appealKey: string | null = null;
async function appealSigningKey(): Promise<string> {
  // HKDF from the ticket signing key (env or self-provisioned server secret):
  // nothing new to configure, and it cannot stand in for any other key.
  return (appealKey ??= Buffer.from(
    crypto.hkdfSync('sha256', await ticketKey(), 'greengo-moderation', 'appeal-link-v1', 32)).toString('hex'));
}
/** Test hook. */
export function resetAppealKey(): void {
  appealKey = null;
}

export async function appealSignature(decisionId: string, userId: string): Promise<string> {
  return crypto.createHmac('sha256', await appealSigningKey())
    .update(`appeal-v1\n${decisionId}\n${userId}`).digest('base64url').slice(0, 43);
}

export async function verifyAppealSignature(decisionId: string, userId: string, sig: unknown): Promise<boolean> {
  if (typeof sig !== 'string' || sig.length !== 43) return false;
  const want = Buffer.from(await appealSignature(decisionId, userId));
  const got = Buffer.from(sig);
  return want.length === got.length && crypto.timingSafeEqual(want, got);
}

export const APPEAL_FUNCTION = 'moderationAppeal';

export async function appealLinkFor(decisionId: string, userId: string, locale: string): Promise<string> {
  const s = await appealSignature(decisionId, userId);
  return `${functionsBaseUrl()}/${APPEAL_FUNCTION}?d=${encodeURIComponent(decisionId)}&s=${s}&hl=${encodeURIComponent(locale)}`;
}

// ---------------------------------------------------------------------------
// Email
// ---------------------------------------------------------------------------

export interface DecisionEmailModel {
  locale: string;
  to: string;
  action: string;
  reasonCode: string | null;
  explanation: string;
  contentRef: ContentReference | null;
  automated: AutomatedInfo;
  appealable: boolean;
  appealDeadlineMs: number;
  appealUrl: string | null;
  role: DecisionRole;
}

/** Pure (exported for tests): every value escaped; the link only on our functions host. */
export function buildDecisionEmail(m: DecisionEmailModel): OutgoingEmail {
  const L = m.locale;
  const date = new Intl.DateTimeFormat(intlLocale(L), { dateStyle: 'long', timeZone: 'UTC' }).format(new Date(m.appealDeadlineMs));
  const rows: Array<[string, string | null]> = [
    [tr(L, 'moderationDecisionActionLabel'), actionText(L, m.action)],
    [tr(L, 'moderationDecisionContentLabel'), contentText(L, m.contentRef)],
    [tr(L, 'moderationDecisionReasonLabel'), reasonText(L, m.reasonCode)],
    [tr(L, 'moderationDecisionExplanationLabel'), m.explanation || null],
    [tr(L, 'moderationDecisionAutomatedLabel'), automatedText(L, m.automated)],
  ];
  const safeUrl = m.appealUrl && m.appealUrl.startsWith(`${functionsBaseUrl()}/`) ? m.appealUrl : null;
  const appeal = m.appealable
    ? `<p>${escapeHtml(tr(L, 'srvDecisionEmailAppeal', { date }))}</p>`
      + (safeUrl
        ? `<p><a href="${escapeHtml(safeUrl)}" style="display:inline-block;background:#0F9D58;color:#fff;padding:10px 18px;border-radius:6px;text-decoration:none;font-weight:bold">${escapeHtml(tr(L, 'moderationDecisionAppealButton'))}</a></p>`
        : '')
    : `<p>${escapeHtml(tr(L, 'moderationDecisionAppealClosed'))}</p>`;
  const inner = `<p><b>${escapeHtml(tr(L, 'moderationDecisionTitle'))}</b></p>`
    + `<p>${escapeHtml(tr(L, 'srvDecisionEmailIntro'))}</p>`
    + `<p>${escapeHtml(tr(L, m.role === 'reporter' ? 'moderationDecisionReporterIntro' : 'moderationDecisionIntro'))}</p>`
    + detailsTable(rows)
    + appeal
    + `<p style="color:#555;font-size:13px">${escapeHtml(tr(L, 'moderationDecisionOtherOptions'))}</p>`;
  return {
    to: [m.to],
    subject: tr(L, 'srvDecisionEmailSubject'),
    html: emailFrame(inner),
    replyTo: 'safety@greengochat.com',
  };
}

// ---------------------------------------------------------------------------
// Create + notify
// ---------------------------------------------------------------------------

export interface DecisionInput {
  decisionId: string;
  userId: string | null | undefined;
  action: string;
  reasonCode: string | null;
  explanation: string | null;
  /** Moderator uid, or 'system' for automatic measures. */
  decidedBy: string;
  role?: DecisionRole;
  queueId?: string | null;
  contentRef?: ContentReference | null;
  automated?: AutomatedInfo | null;
  effects?: DecisionEffect[];
  appealable?: boolean;
  /** In-app notification (default true). The reporter path writes its own. */
  inApp?: boolean;
  /** Statement of reasons by email (default true). */
  email?: boolean;
  /** Extra non-user-facing fields stored on the decision (e.g. caseId, reportId). */
  extra?: Record<string, unknown>;
  nowMs?: number;
}

/** Notification `data` (all strings: FCM payload compatible). */
export function decisionNotificationData(d: Record<string, any>): Record<string, string> {
  const deadline = d.appealDeadline instanceof admin.firestore.Timestamp
    ? d.appealDeadline.toDate().toISOString() : '';
  const c = (d.contentRef || {}) as Partial<ContentReference>;
  return {
    action: 'moderation_decision',
    decisionId: String(d.decisionId),
    moderationAction: String(d.action ?? ''),
    reasonCode: String(d.reasonCode ?? 'other'),
    explanation: String(d.explanation ?? ''),
    appealable: d.appealable === true ? 'true' : 'false',
    appealDeadline: deadline,
    role: String(d.role ?? 'affected'),
    contentType: String(c.type ?? ''),
    contentId: String(c.id ?? ''),
    contentExcerpt: String(c.excerpt ?? ''),
    automated: d.automated === true ? 'true' : 'false',
    automatedDecision: d.automatedDecision === true ? 'true' : 'false',
    automatedDetection: String(d.automatedDetection ?? ''),
  };
}

/**
 * Records the decision and notifies the user (in-app + email). Idempotent
 * (decision id is deterministic per action). Returns false when the decision
 * already existed or nobody is affected. Never throws for a missing user.
 */
export async function createModerationDecision(p: DecisionInput): Promise<boolean> {
  const role: DecisionRole = p.role ?? 'affected';
  const allowed = role === 'reporter' ? REPORTER_ACTIONS : USER_AFFECTING_ACTIONS;
  if (!allowed.has(p.action)) return false;
  const userId = typeof p.userId === 'string' ? p.userId : '';
  if (!userId || ['anonymous', 'admin', 'system'].includes(userId)) return false;
  const nowMs = p.nowMs ?? Date.now();
  const deadline = admin.firestore.Timestamp.fromMillis(nowMs + APPEAL_WINDOW_DAYS * 86_400_000);
  const reasonCode = p.reasonCode || (role === 'reporter' ? 'no_violation' : 'other');
  const explanation = (p.explanation || '').slice(0, 2000);
  const automated = p.automated ?? { detection: null, decision: false };
  // Terms 18.3 last paragraph: no notice where the law forbids it. A CSAE
  // suspect is never told (no tipping-off before law enforcement acts); the
  // decision is still recorded for the audit trail.
  const withheld = role === 'affected' && reasonCode === 'csae';
  const appealable = p.appealable !== false && !withheld;
  if (withheld) {
    p = { ...p, inApp: false, email: false, extra: { ...(p.extra || {}), noticeWithheld: 'csae_law_enforcement' } };
  }

  const doc: Record<string, unknown> = {
    decisionId: p.decisionId,
    queueId: p.queueId ?? p.decisionId,
    userId,
    role,
    action: p.action,
    reasonCode,
    explanation,
    decidedBy: p.decidedBy,
    decidedAt: admin.firestore.Timestamp.fromMillis(nowMs),
    contentRef: p.contentRef ?? (role === 'reporter' ? { type: 'report', id: null, excerpt: null } : { type: 'account', id: null, excerpt: null }),
    automated: automated.detection !== null || automated.decision,
    automatedDetection: automated.detection,
    automatedDecision: automated.decision,
    effects: p.effects ?? [],
    appealable,
    appealDeadline: deadline,
    appealStatus: null,
    ...(p.extra || {}),
  };
  const decisionRef = db().collection(MODERATION_DECISIONS).doc(p.decisionId);
  try {
    await decisionRef.create(doc);
  } catch (e) {
    if (isAlreadyExists(e)) return false;
    throw e;
  }

  // Stored in the user's language (as before) for app versions without key
  // support, plus titleKey/bodyKey so newer apps follow the UI language.
  const locale = await resolveLocale(userId);
  if (p.inApp !== false) {
    const title = tr(locale, 'srvModerationDecisionTitle');
    const body = tr(locale, 'srvModerationDecisionBody');
    try {
      await db().collection('notifications').doc(decisionNotificationId(p.decisionId)).create({
        userId,
        type: 'system',
        title,
        message: body,
        body,
        titleKey: 'srvModerationDecisionTitle',
        bodyKey: 'srvModerationDecisionBody',
        data: decisionNotificationData(doc),
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        actionUrl: null,
        imageUrl: null,
      });
    } catch (e) {
      if (!isAlreadyExists(e)) console.error(`[decisions] in-app notice for ${p.decisionId} failed:`, e);
    }
  }
  if (p.email !== false) {
    try {
      await sendDecisionEmail(doc, locale);
    } catch (e) {
      console.error(`[decisions] email for ${p.decisionId} failed:`, (e as Error)?.message || e);
    }
  }
  return true;
}

async function sendDecisionEmail(d: Record<string, any>, locale: string): Promise<void> {
  const userId = d.userId as string;
  const deadlineMs = (d.appealDeadline as admin.firestore.Timestamp).toMillis();
  await sendEmailOnce(`moderation_decision_${d.decisionId}`, async () => {
    const to = await authEmailOf(userId); // works for disabled (banned) accounts too
    if (!to) return null;
    return buildDecisionEmail({
      locale,
      to,
      action: d.action,
      reasonCode: d.reasonCode ?? null,
      explanation: d.explanation ?? '',
      contentRef: d.contentRef ?? null,
      automated: { detection: d.automatedDetection ?? null, decision: d.automatedDecision === true },
      appealable: d.appealable === true,
      appealDeadlineMs: deadlineMs,
      appealUrl: d.appealable === true ? await appealLinkFor(d.decisionId, userId, locale) : null,
      role: d.role === 'reporter' ? 'reporter' : 'affected',
    });
  }, { kind: 'moderation_decision', decisionId: d.decisionId });
}

/**
 * Backward-compatible entry point (takeModerationAction, safety cases,
 * copyright repeat-infringer): a moderator / system action on the affected
 * user. Decision id = [queueId].
 */
export async function notifyAffectedUserOfDecision(p: {
  queueId: string;
  userId: string | null | undefined;
  action: string;
  reasonCode: string | null;
  explanation: string | null;
  moderatorId: string;
  nowMs?: number;
  contentRef?: ContentReference | null;
  automated?: AutomatedInfo | null;
  effects?: DecisionEffect[];
  extra?: Record<string, unknown>;
}): Promise<boolean> {
  return createModerationDecision({
    decisionId: p.queueId,
    queueId: p.queueId,
    userId: p.userId,
    action: p.action,
    reasonCode: p.reasonCode,
    explanation: p.explanation,
    decidedBy: p.moderatorId,
    contentRef: p.contentRef,
    automated: p.automated,
    effects: p.effects,
    extra: p.extra,
    nowMs: p.nowMs,
  });
}

/** Appends effects recorded after the decision was created (e.g. an escalation). */
export async function addDecisionEffects(decisionId: string, effects: DecisionEffect[]): Promise<void> {
  if (!effects.length) return;
  await db().collection(MODERATION_DECISIONS).doc(decisionId)
    .update({ effects: admin.firestore.FieldValue.arrayUnion(...effects) })
    .catch((e) => console.error(`[decisions] could not add effects to ${decisionId}:`, e?.message || e));
}

// ---------------------------------------------------------------------------
// Appeals
// ---------------------------------------------------------------------------

export type AppealChannel = 'app' | 'web';

/**
 * submitAppeal({ decisionId, appealReason }) — the DSA art. 20 path. Throws
 * HttpsError (v1) with stable codes the app / web page map to messages.
 */
export async function submitAppealForDecision(
  uid: string,
  data: { decisionId?: unknown; appealReason?: unknown },
  nowMs: number = Date.now(),
  channel: AppealChannel = 'app',
): Promise<{ appealId: string; status: 'submitted' }> {
  const HttpsError = functions.https.HttpsError;
  const decisionId = typeof data.decisionId === 'string' ? data.decisionId.trim() : '';
  if (!decisionId || decisionId.length > 1500 || decisionId.includes('/')) {
    throw new HttpsError('invalid-argument', 'decisionId is required');
  }
  const reason = typeof data.appealReason === 'string' ? data.appealReason.trim() : '';
  if (reason.length < APPEAL_MIN_CHARS || reason.length > APPEAL_MAX_CHARS) {
    throw new HttpsError('invalid-argument', `appealReason must be ${APPEAL_MIN_CHARS}-${APPEAL_MAX_CHARS} characters`);
  }

  const decisionRef = db().collection(MODERATION_DECISIONS).doc(decisionId);
  const appealRef = db().collection('report_appeals').doc();
  const queueRef = db().collection('moderation_queue').doc(`appeal__${decisionId}`);

  await db().runTransaction(async (tx) => {
    const snap = await tx.get(decisionRef);
    const d = snap.data();
    if (!snap.exists || !d) throw new HttpsError('not-found', 'Decision not found');
    if (d.userId !== uid) throw new HttpsError('permission-denied', 'You can only appeal decisions about you or your own reports');
    if (d.appealStatus) throw new HttpsError('already-exists', 'This decision was already appealed');
    const deadline = d.appealDeadline instanceof admin.firestore.Timestamp ? d.appealDeadline.toMillis() : 0;
    if (d.appealable !== true || nowMs > deadline) {
      throw new HttpsError('failed-precondition', 'The appeal window for this decision has closed');
    }
    const role: DecisionRole = d.role === 'reporter' ? 'reporter' : 'affected';
    const now = admin.firestore.Timestamp.fromMillis(nowMs);
    tx.set(appealRef, {
      appealId: appealRef.id,
      decisionId,
      queueId: d.queueId ?? decisionId,
      reportId: d.reportId ?? null,
      userId: uid,
      role,
      channel,
      appealReason: reason,
      evidenceUrls: [],
      action: d.action ?? null,
      reasonCode: d.reasonCode ?? null,
      originalDecidedBy: d.decidedBy ?? null,
      createdAt: now,
      status: 'pending',
      reviewerNotes: null,
      reviewedAt: null,
      reviewedBy: null,
      decision: null,
    });
    tx.set(queueRef, {
      queueId: queueRef.id,
      itemType: 'appeal',
      itemId: appealRef.id,
      userId: uid,
      // A banned user can do nothing until this is decided.
      priority: d.action === 'banUser' ? 'high' : 'medium',
      category: role === 'reporter' ? 'reporterAppeal' : 'appeal',
      status: 'pending',
      addedAt: now,
      createdAt: now,
      assignedTo: null,
      relatedReportIds: [],
      metadata: {
        decisionId,
        appealId: appealRef.id,
        role,
        channel,
        originalQueueId: d.queueId ?? decisionId,
        action: d.action ?? null,
        reasonCode: d.reasonCode ?? null,
        // Terms 18.4 b: this person may NOT resolve the appeal.
        originalDecidedBy: d.decidedBy ?? null,
      },
      content: { text: reason.slice(0, 2000), explanation: d.explanation ?? null },
      reporterId: 'system',
    });
    tx.update(decisionRef, { appealStatus: 'pending', appealId: appealRef.id, appealedAt: now, appealChannel: channel });
  });
  return { appealId: appealRef.id, status: 'submitted' };
}
