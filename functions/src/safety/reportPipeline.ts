/**
 * Report pipeline (P1-12, audit C-11): every user report reaches a moderator.
 *
 * Clients write reports straight into Firestore, into three collections:
 *   - user_reports     profile / chat-user / community reports
 *                      (safety_actions_service.dart, chat_remote_datasource.dart reportUser)
 *   - message_reports  chat message reports (chat_remote_datasource.dart reportMessage)
 *   - reports          event reports (events_screen.dart, type 'event') and
 *                      experience / experience-review reports
 *                      (user_experiences_repository_impl.dart, type 'user_experience' /
 *                      'user_experience_review')
 * None of them reached `moderation_queue`, which is what the admin panel and the
 * moderation callables (admin/moderationQueue.ts) read. These triggers create
 * exactly ONE normalized queue item per report (doc id derived from the source
 * path, written with create(), so a re-delivered event cannot duplicate it).
 *
 * Clients are not changed: reasons stay stored as the TRANSLATED UI text the app
 * writes (report_block_sheet.dart); a language-neutral `reasonCode` is derived
 * here from the strings of every locale in lib/l10n/app_*.arb.
 *
 * P0 items (child safety) alert the admins (admin_alerts doc + in-app
 * notification + Resend email when app_config/resend_settings is configured;
 * the email carries ids only, never the reported content).
 *
 * When a queue item reaches a final status, the reporter gets ONE neutral
 * in-app notification ("reviewed: action taken / no violation found").
 */

import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { monitored } from '../shared/monitoring';
import { applyReportAutoActions } from './reportingSystem';

const db = admin.firestore();
const OPTS = { memory: '512MiB' as const, timeoutSeconds: 60 };

// ---------------------------------------------------------------------------
// Reason normalization
// ---------------------------------------------------------------------------

export type ReasonCode =
  | 'csae'
  | 'underage'
  | 'sexual_content'
  | 'inappropriate'
  | 'threats'
  | 'violence'
  | 'harassment'
  | 'hate'
  | 'spam'
  | 'scam'
  | 'impersonation'
  | 'privacy'
  | 'misleading'
  | 'no_show'
  | 'off_platform_payment'
  | 'other';

export type PriorityLevel = 'P0' | 'P1' | 'P2';

/**
 * Exact reason strings -> code. The localized strings are the values of the
 * `chatReportReason*` keys in EVERY lib/l10n/app_*.arb (identical in the web
 * repo). Wire values (experience sheet, submitReport categories, admin-panel
 * categories) are included too.
 */
const REASON_STRINGS: Record<ReasonCode, string[]> = {
  underage: [
    'Minderjähriger Benutzer', 'Underage user', 'Usuario menor de edad', 'Utilisateur mineur',
    'Utente minorenne', 'Utilizador menor de idade', 'Usuário menor de idade',
    'underage', 'minorSafety', 'minor_safety', 'minor',
  ],
  csae: ['csae', 'csam', 'child_sexual_exploitation', 'childSexualExploitation', 'child_safety', 'childSafety'],
  harassment: [
    'Belästigung oder Mobbing', 'Harassment or bullying', 'Acoso o intimidación',
    'Harcèlement ou intimidation', 'Molestie o bullismo', 'Assédio ou bullying',
    'harassment', 'bullying',
  ],
  inappropriate: [
    'Unangemessener Inhalt', 'Inappropriate content', 'Contenido inapropiado', 'Contenu inapproprié',
    'Contenuto inappropriato', 'Conteúdo inapropriado',
    'inappropriate', 'inappropriateContent', 'inappropriate_content',
  ],
  sexual_content: ['sexual_content', 'sexualContent', 'sexual', 'nudity'],
  threats: [
    'Bedrohliches Verhalten', 'Threatening behavior', 'Comportamiento amenazante',
    'Comportement menaçant', 'Comportamento minaccioso', 'Comportamento ameaçador',
    'threats', 'threatening', 'threat',
  ],
  violence: ['violence', 'violent'],
  hate: ['hate', 'hateSpeech', 'hate_speech'],
  spam: [
    'Spam oder Betrug', 'Spam or scam', 'Spam o estafa', 'Spam ou arnaque', 'Spam o truffa',
    'Spam ou burla', 'Spam ou golpe',
    'spam',
  ],
  scam: ['scam', 'fraud'],
  impersonation: [
    'Falsches Profil / Catfishing', 'Fake profile / Catfishing', 'Perfil falso / Catfishing',
    'Faux profil / Catfishing', 'Profilo falso / Catfishing',
    'impersonation', 'fakeProfile', 'fake_profile', 'catfishing',
  ],
  privacy: [
    'Teilen persönlicher Informationen', 'Sharing personal information', 'Compartir información personal',
    "Partage d'informations personnelles", 'Condivisione di informazioni personali',
    'Partilha de informações pessoais', 'Compartilhamento de informações pessoais',
    'privacy', 'personal_info', 'personalInfo',
  ],
  misleading: ['misleading'],
  no_show: ['no_show', 'noShow'],
  off_platform_payment: ['off_platform_payment', 'offPlatformPayment'],
  other: ['Sonstiges', 'Other', 'Otro', 'Autre', 'Altro', 'Outro', 'other'],
};

/** Lowercase, strip accents, collapse whitespace. */
export function normalizeReasonText(s: string): string {
  return s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

const REASON_LOOKUP: Map<string, ReasonCode> = (() => {
  const m = new Map<string, ReasonCode>();
  for (const [code, strings] of Object.entries(REASON_STRINGS) as [ReasonCode, string[]][]) {
    for (const s of strings) m.set(normalizeReasonText(s), code);
  }
  return m;
})();

// Keyword fallbacks, matched on accent-stripped lowercase text. Ordered by
// severity: the first hit wins.
export const CSAE_PATTERN =
  /\b(csam|csae|child ?(porn\w*|sexual\w*|abuse\w*|exploit\w*)|p(a)?edophil\w*|pedofil\w*|padophil\w*|(child|minor) grooming|pornografia infantil|pornografia minorile|pedopornogra\w*|abuso (sexual )?infantil|abuso (sessuale )?su minori|kinderporn\w*|kindesmissbrauch|pornographie infantile|explotacion sexual infantil|exploracao sexual infantil)\b/;
const KEYWORD_RULES: [ReasonCode, RegExp][] = [
  ['csae', CSAE_PATTERN],
  ['underage', /\b(under ?age|minor|minors|minorenne|minorenni|menor|menores|mineur|mineure|minderjahrig\w*|child|children|kid|kids|crianca|bambin\w*|nin[oa]s?|enfant)\b/],
  ['sexual_content', /\b(sexual\w*|sessual\w*|sexuel\w*|nud\w*|naked|nackt|porn\w*|explicit)\b/],
  ['threats', /\b(threat\w*|minacc\w*|amenaz\w*|menac\w*|amea\w*|bedroh\w*)\b/],
  ['violence', /\b(violen\w*|gewalt)\b/],
  ['hate', /\b(hate|racis\w*|odio|haine|hass)\b/],
  ['harassment', /\b(harass\w*|bully\w*|molest\w*|acoso|assedio|harcelement|belastigung)\b/],
  ['scam', /\b(scam\w*|fraud\w*|truff\w*|estafa|golpe|arnaque|burla|betrug)\b/],
  ['spam', /\bspam\w*\b/],
  ['impersonation', /\b(fake|catfish\w*|impersonat\w*|falso|falsch\w*|faux)\b/],
];

const PRIORITY_BY_CODE: Record<ReasonCode, PriorityLevel> = {
  csae: 'P0',
  underage: 'P0',
  sexual_content: 'P1',
  // "Inappropriate content" is the app's catch-all for sexual/nudity reports.
  inappropriate: 'P1',
  threats: 'P1',
  violence: 'P1',
  harassment: 'P2',
  hate: 'P2',
  spam: 'P2',
  scam: 'P2',
  impersonation: 'P2',
  privacy: 'P2',
  misleading: 'P2',
  no_show: 'P2',
  off_platform_payment: 'P2',
  other: 'P2',
};

export const SLA_HOURS: Record<PriorityLevel, number> = { P0: 24, P1: 48, P2: 168 };

/** Legacy `priority` vocabulary read by the admin panel + moderationQueue.ts. */
const LEGACY_PRIORITY: Record<PriorityLevel, 'critical' | 'high' | 'medium'> = {
  P0: 'critical',
  P1: 'high',
  P2: 'medium',
};

/** Admin-panel ReportCategory vocabulary (filter on `category`). */
const PANEL_CATEGORY: Record<ReasonCode, string> = {
  csae: 'underage',
  underage: 'underage',
  sexual_content: 'inappropriateContent',
  inappropriate: 'inappropriateContent',
  threats: 'violence',
  violence: 'violence',
  harassment: 'harassment',
  hate: 'hateSpeech',
  spam: 'spam',
  scam: 'scam',
  impersonation: 'fakeProfile',
  privacy: 'other',
  misleading: 'scam',
  no_show: 'other',
  off_platform_payment: 'scam',
  other: 'other',
};

/**
 * Map a raw (possibly translated) reason to a language-neutral code.
 * [extraText] (free-text details) can only ESCALATE to csae: a CSAE keyword
 * anywhere in the report must never be triaged as P2.
 */
export function classifyReason(rawReason: unknown, extraText?: unknown): ReasonCode {
  const reason = typeof rawReason === 'string' ? normalizeReasonText(rawReason) : '';
  const extra = typeof extraText === 'string' ? normalizeReasonText(extraText) : '';
  let code: ReasonCode | undefined = reason ? REASON_LOOKUP.get(reason) : undefined;
  if (!code && reason) {
    for (const [c, re] of KEYWORD_RULES) {
      if (re.test(reason)) { code = c; break; }
    }
  }
  if (!code) code = 'other';
  if (code !== 'csae' && extra && CSAE_PATTERN.test(extra)) code = 'csae';
  return code;
}

export function priorityFor(code: ReasonCode): PriorityLevel {
  return PRIORITY_BY_CODE[code];
}

// ---------------------------------------------------------------------------
// Queue item construction
// ---------------------------------------------------------------------------

export type ReportSource = 'user_reports' | 'message_reports' | 'reports';

/** Deterministic queue doc id: one queue item per source report. */
export function queueIdFor(source: ReportSource, reportId: string): string {
  return `${source}__${reportId}`;
}

const str = (v: unknown, max = 500): string | null =>
  typeof v === 'string' && v.length > 0 ? v.slice(0, max) : null;

interface Normalized {
  itemType: string;
  reportType: string;
  reporterId: string | null;
  reportedUserId: string | null;
  contentRef: { type: string; id: string | null; path: string | null };
  reason: string | null;
  details: string | null;
  /** Shown to moderators in the review screen (admin-only collection). */
  content: Record<string, unknown>;
}

function normalize(source: ReportSource, reportId: string, r: admin.firestore.DocumentData): Normalized {
  const reporterId = str(r.reporterId, 128);
  if (source === 'user_reports') {
    const conv = str(r.conversationId, 256);
    const msg = str(r.messageId, 256);
    return {
      itemType: 'userReport', // moderationQueue.ts reads user_reports/{itemId} for this type
      reportType: str(r.source, 64) || (conv ? 'chat_user' : 'user'),
      reporterId,
      reportedUserId: str(r.reportedUserId, 128),
      contentRef: conv && msg
        ? { type: 'message', id: msg, path: `conversations/${conv}/messages/${msg}` }
        : { type: 'user', id: str(r.reportedUserId, 128), path: r.reportedUserId ? `users/${r.reportedUserId}` : null },
      reason: str(r.reason) || str(r.category),
      details: str(r.additionalDetails, 1000) || str(r.description, 1000),
      content: {
        text: str(r.additionalDetails, 1000) || str(r.description, 1000),
        conversationId: conv,
        messageId: msg,
        surface: str(r.source, 64) || str(r.additionalDetails, 200),
        screenshotUrls: Array.isArray(r.screenshotUrls) ? r.screenshotUrls.slice(0, 10) : [],
      },
    };
  }
  if (source === 'message_reports') {
    const conv = str(r.conversationId, 256);
    const msg = str(r.messageId, 256);
    return {
      itemType: 'messageReport',
      reportType: 'message',
      reporterId,
      reportedUserId: str(r.reportedUserId, 128),
      contentRef: { type: 'message', id: msg, path: conv && msg ? `conversations/${conv}/messages/${msg}` : null },
      reason: str(r.reason),
      details: null,
      content: {
        text: str(r.messageContent, 2000),
        conversationId: conv,
        messageId: msg,
      },
    };
  }
  // `reports`: events and user experiences (+ reviews), discriminated by `type`.
  const type = str(r.type, 64) || 'report';
  if (type === 'event') {
    const eventId = str(r.eventId, 256);
    return {
      itemType: 'eventReport',
      reportType: 'event',
      reporterId,
      reportedUserId: str(r.organizerId, 128) || str(r.reportedUserId, 128),
      contentRef: { type: 'event', id: eventId, path: eventId ? `events/${eventId}` : null },
      reason: str(r.reason),
      details: str(r.description, 1000),
      content: { text: str(r.eventTitle, 300), eventId },
    };
  }
  if (type === 'user_experience' || type === 'user_experience_review') {
    const experienceId = str(r.experienceId, 256);
    const isReview = type === 'user_experience_review';
    return {
      itemType: isReview ? 'experienceReviewReport' : 'experienceReport',
      reportType: type,
      reporterId,
      reportedUserId: isReview ? str(r.reviewAuthorId, 128) : str(r.hostId, 128),
      contentRef: {
        type: isReview ? 'experience_review' : 'experience',
        id: experienceId,
        path: experienceId ? `user_experiences/${experienceId}` : null,
      },
      reason: str(r.reason),
      details: str(r.details, 1000),
      content: {
        text: isReview ? str(r.comment, 300) : str(r.experienceTitle, 300),
        details: str(r.details, 1000),
        experienceId,
      },
    };
  }
  // Generic `reports` doc (e.g. a future surface, or handlers.ts-shaped).
  return {
    itemType: 'report',
    reportType: type,
    reporterId,
    reportedUserId: str(r.reportedUserId, 128),
    contentRef: { type: 'content', id: str(r.reportedContentId, 256), path: null },
    reason: str(r.reason) || str(r.category),
    details: str(r.description, 1000),
    content: { text: str(r.description, 1000) },
  };
}

export function buildQueueItem(
  source: ReportSource,
  reportId: string,
  r: admin.firestore.DocumentData,
  nowMs: number = Date.now(),
): Record<string, unknown> {
  const n = normalize(source, reportId, r);
  const reasonCode = classifyReason(n.reason, n.details);
  const level = priorityFor(reasonCode);
  const queueId = queueIdFor(source, reportId);
  const category = PANEL_CATEGORY[reasonCode];
  return {
    // --- shape read by the admin panel + admin/moderationQueue.ts ---
    queueId,
    itemType: n.itemType,
    itemId: reportId,
    userId: n.reportedUserId || '',
    priority: LEGACY_PRIORITY[level],
    category,
    addedAt: admin.firestore.FieldValue.serverTimestamp(),
    assignedTo: null,
    relatedReportIds: [reportId],
    metadata: {
      category,
      reasonCode,
      reporterId: n.reporterId,
      sourceCollection: source,
      reportType: n.reportType,
    },
    status: 'pending',
    content: { ...n.content, reason: n.reason, sourcePath: `${source}/${reportId}` },
    // --- normalized report fields (P1-12) ---
    source: { collection: source, docId: reportId, path: `${source}/${reportId}` },
    reportType: n.reportType,
    reporterId: n.reporterId,
    reportedUserId: n.reportedUserId,
    contentRef: n.contentRef,
    reason: n.reason,
    reasonCode,
    priorityLevel: level,
    slaHours: SLA_HOURS[level],
    slaDueAt: admin.firestore.Timestamp.fromMillis(nowMs + SLA_HOURS[level] * 3600_000),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

function isAlreadyExists(e: unknown): boolean {
  const code = (e as { code?: unknown })?.code;
  return code === 6 || code === 'already-exists' || code === 'ALREADY_EXISTS';
}

/**
 * Create the queue item for one report. Returns false when it already existed
 * (re-delivered event, or skipped source).
 */
export async function enqueueReport(
  source: ReportSource,
  reportId: string,
  r: admin.firestore.DocumentData | undefined,
): Promise<boolean> {
  if (!r) return false;
  // The admin panel's createReport() writes `reports` with reporterId 'admin'
  // AND its own queue item; don't enqueue that one twice.
  if (source === 'reports' && r.reporterId === 'admin') return false;

  const item = buildQueueItem(source, reportId, r);
  const ref = db.collection('moderation_queue').doc(item.queueId as string);
  try {
    await ref.create(item);
  } catch (e) {
    if (isAlreadyExists(e)) return false;
    throw e;
  }

  // Side effects run once, after the item exists: the create() above is the
  // idempotency gate (a crash after it leaves the item; at-most-once actions).
  if (item.priorityLevel === 'P0') {
    try {
      await alertAdminsP0(item);
    } catch (e) {
      console.error(`[reportPipeline] P0 alert failed for ${item.queueId}:`, e);
    }
  }

  if (source === 'user_reports' && item.reportedUserId) {
    try {
      const settings = (await db.doc('app_config/moderation_settings').get()).data() || {};
      // OFF unless explicitly enabled (app_config/moderation_settings
      // .reportAutoActionsEnabled = true): with a small user base a few
      // coordinated fake accounts could otherwise auto-restrict an innocent
      // user. Turn on once moderation is staffed.
      if (settings.reportAutoActionsEnabled === true) {
        const code = item.reasonCode as ReasonCode;
        await applyReportAutoActions({
          reportedUserId: item.reportedUserId as string,
          minorSafety: code === 'underage' || code === 'csae',
          description: (r.description as string) || (r.additionalDetails as string) || (item.reason as string) || '',
        });
      }
    } catch (e) {
      console.error(`[reportPipeline] auto-actions failed for ${item.queueId}:`, e);
    }
  }
  return true;
}

// ---------------------------------------------------------------------------
// Automatic text flags (P2-8b): flag-for-review ONLY, never an automatic action

export interface AutoTextFlag {
  /** Firestore path of the message, e.g. communities/c1/messages/m1. */
  path: string;
  chatType: 'community' | 'group' | 'event';
  chatId: string;
  messageId: string;
  senderId: string;
  text: string;
  reasonCode: ReasonCode;
  matched: string[];
}

/** Deterministic queue id: one item per flagged message, ever. */
export function autoTextQueueId(path: string): string {
  return `auto_text__${path.replace(/\//g, '~')}`.slice(0, 1400);
}

/**
 * Creates ONE moderation_queue item (source 'auto_text') for a message the
 * keyword screen flagged. Same shape as a report item so the admin panel and
 * takeModerationAction handle it; reporterId 'system' (no reporter feedback).
 * P0 (child safety) alerts the admins like a P0 report. Returns false when the
 * item already existed.
 */
export async function enqueueAutoTextFlag(f: AutoTextFlag, nowMs: number = Date.now()): Promise<boolean> {
  const level = priorityFor(f.reasonCode);
  const queueId = autoTextQueueId(f.path);
  const category = PANEL_CATEGORY[f.reasonCode];
  const item: Record<string, unknown> = {
    queueId,
    itemType: 'autoTextFlag',
    itemId: f.messageId,
    userId: f.senderId,
    priority: LEGACY_PRIORITY[level],
    category,
    addedAt: admin.firestore.FieldValue.serverTimestamp(),
    assignedTo: null,
    relatedReportIds: [],
    metadata: {
      category,
      reasonCode: f.reasonCode,
      reporterId: 'system',
      sourceCollection: 'auto_text',
      reportType: `${f.chatType}_message`,
    },
    status: 'pending',
    content: {
      text: f.text.slice(0, 2000),
      chatType: f.chatType,
      chatId: f.chatId,
      messageId: f.messageId,
      reason: `auto_text:${f.reasonCode}`,
      sourcePath: f.path,
    },
    source: { collection: 'auto_text', docId: f.messageId, path: f.path },
    reportType: `${f.chatType}_message`,
    reporterId: 'system',
    reportedUserId: f.senderId,
    contentRef: { type: 'message', id: f.messageId, path: f.path },
    reason: `auto_text:${f.reasonCode}`,
    reasonCode: f.reasonCode,
    priorityLevel: level,
    slaHours: SLA_HOURS[level],
    slaDueAt: admin.firestore.Timestamp.fromMillis(nowMs + SLA_HOURS[level] * 3600_000),
    autoFlag: { engine: 'keyword-v1', matched: f.matched.slice(0, 10), automatedActions: 'none' },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  try {
    await db.collection('moderation_queue').doc(queueId).create(item);
  } catch (e) {
    if (isAlreadyExists(e)) return false;
    throw e;
  }
  if (level === 'P0') {
    try {
      await alertAdminsP0(item);
    } catch (e) {
      console.error(`[reportPipeline] P0 alert failed for ${queueId}:`, e);
    }
  }
  return true;
}

// ---------------------------------------------------------------------------
// P0 admin alert
// ---------------------------------------------------------------------------

const ADMIN_ROLES = ['super_admin', 'superAdmin', 'admin', 'moderator'];

async function alertAdminsP0(item: Record<string, unknown>): Promise<void> {
  const queueId = item.queueId as string;
  const alertRef = db.collection('admin_alerts').doc(`moderation_p0_${queueId}`);
  const slaDueAt = item.slaDueAt as admin.firestore.Timestamp;
  try {
    await alertRef.create({
      type: 'moderation_p0',
      queueId,
      reasonCode: item.reasonCode,
      priorityLevel: item.priorityLevel,
      sourceCollection: (item.source as { collection: string }).collection,
      slaDueAt,
      status: 'open',
      emailStatus: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    if (isAlreadyExists(e)) return; // already alerted
    throw e;
  }

  const settings = (await db.doc('app_config/moderation_settings').get()).data() || {};
  const admins = await db.collection('admin_users').where('role', 'in', ADMIN_ROLES).limit(50).get();
  const title = 'Urgent report: child-safety review needed';
  const body = `A P0 report (${item.reasonCode}) is waiting in the moderation queue. ` +
    `Queue item ${queueId}, review within 24h.`;
  const emails = new Set<string>();
  for (const a of admins.docs) {
    const email = a.data()?.email;
    if (typeof email === 'string' && email.includes('@')) emails.add(email);
    await db.collection('notifications').doc(`moderation_p0_${queueId}_${a.id}`).set({
      userId: a.id,
      type: 'system',
      title,
      message: body,
      body,
      data: { action: 'moderation_p0', queueId },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  if (Array.isArray(settings.alertEmails)) {
    for (const e of settings.alertEmails) if (typeof e === 'string' && e.includes('@')) emails.add(e);
  }

  const cfg = (await db.doc('app_config/resend_settings').get()).data();
  if (!cfg?.apiKey || emails.size === 0) {
    await alertRef.update({ emailStatus: cfg?.apiKey ? 'no_recipients' : 'not_configured' });
    return;
  }
  // Ids and codes ONLY: never the reported content, names or message text.
  const link = typeof settings.adminPanelUrl === 'string' && settings.adminPanelUrl
    ? `${settings.adminPanelUrl.replace(/\/+$/, '')}/moderation?queueId=${encodeURIComponent(queueId)}`
    : null;
  const due = slaDueAt.toDate().toISOString();
  const html =
    `<p>A <b>P0</b> report is waiting in the GreenGo moderation queue.</p>` +
    `<ul><li>Queue item: <code>${queueId}</code></li><li>Reason code: ${item.reasonCode}</li>` +
    `<li>Review due by: ${due}</li></ul>` +
    (link ? `<p><a href="${link}">Open in the admin panel</a></p>` : '<p>Open it in the admin panel (Moderation).</p>');
  try {
    const resp = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${cfg.apiKey}` },
      body: JSON.stringify({
        from: `${cfg.senderName || 'GreenGo Admin'} <${cfg.senderEmail || 'onboarding@resend.dev'}>`,
        to: [...emails],
        subject: `GreenGo - P0 report needs review within 24h (${queueId})`,
        html,
      }),
    });
    await alertRef.update({ emailStatus: resp.ok ? 'sent' : `failed_${resp.status}` });
  } catch (e) {
    console.error('[reportPipeline] P0 email failed:', e);
    await alertRef.update({ emailStatus: 'failed' });
  }
}

// ---------------------------------------------------------------------------
// Reporter feedback
// ---------------------------------------------------------------------------

/** Final statuses: 'resolved' (moderationQueue.ts callables), 'completed' (admin panel). */
const FINAL_STATUSES = new Set(['resolved', 'completed', 'dismissed', 'closed', 'actioned']);
const NO_VIOLATION_ACTIONS = new Set(['approve', 'dismiss', 'dismissed', 'no_action', 'noAction', 'noViolation', 'no_violation']);

export type ReviewOutcome = 'action_taken' | 'no_violation';

export function outcomeFor(after: admin.firestore.DocumentData): ReviewOutcome {
  if (after.status === 'dismissed') return 'no_violation';
  const action = (after.action ?? after.resolvedAction ?? after.actionTaken) as unknown;
  if (typeof action === 'string' && action && !NO_VIOLATION_ACTIONS.has(action)) return 'action_taken';
  return 'no_violation';
}

const FEEDBACK_TEXT: Record<string, { title: string; action_taken: string; no_violation: string }> = {
  en: {
    title: 'Your report was reviewed',
    action_taken: 'Thank you for your report. Our team reviewed it and took action under our Community Guidelines.',
    no_violation: 'Thank you for your report. Our team reviewed it and found no violation of our Community Guidelines.',
  },
  it: {
    title: 'La tua segnalazione è stata esaminata',
    action_taken: 'Grazie per la segnalazione. Il nostro team l\'ha esaminata e ha preso provvedimenti secondo le Linee guida della community.',
    no_violation: 'Grazie per la segnalazione. Il nostro team l\'ha esaminata e non ha riscontrato violazioni delle Linee guida della community.',
  },
  pt: {
    title: 'A sua denúncia foi analisada',
    action_taken: 'Obrigado pela sua denúncia. A nossa equipa analisou-a e tomou medidas de acordo com as Diretrizes da Comunidade.',
    no_violation: 'Obrigado pela sua denúncia. A nossa equipa analisou-a e não encontrou violação das Diretrizes da Comunidade.',
  },
  pt_BR: {
    title: 'Sua denúncia foi analisada',
    action_taken: 'Obrigado pela sua denúncia. Nossa equipe a analisou e tomou medidas de acordo com as Diretrizes da Comunidade.',
    no_violation: 'Obrigado pela sua denúncia. Nossa equipe a analisou e não encontrou violação das Diretrizes da Comunidade.',
  },
  es: {
    title: 'Tu denuncia ha sido revisada',
    action_taken: 'Gracias por tu denuncia. Nuestro equipo la revisó y tomó medidas según las Normas de la comunidad.',
    no_violation: 'Gracias por tu denuncia. Nuestro equipo la revisó y no encontró ninguna infracción de las Normas de la comunidad.',
  },
  fr: {
    title: 'Votre signalement a été examiné',
    action_taken: 'Merci pour votre signalement. Notre équipe l\'a examiné et a pris des mesures conformément aux Règles de la communauté.',
    no_violation: 'Merci pour votre signalement. Notre équipe l\'a examiné et n\'a constaté aucune infraction aux Règles de la communauté.',
  },
  de: {
    title: 'Deine Meldung wurde geprüft',
    action_taken: 'Danke für deine Meldung. Unser Team hat sie geprüft und gemäß den Community-Richtlinien Maßnahmen ergriffen.',
    no_violation: 'Danke für deine Meldung. Unser Team hat sie geprüft und keinen Verstoß gegen die Community-Richtlinien festgestellt.',
  },
};

function feedbackLocale(lang: unknown): string {
  if (typeof lang !== 'string' || !lang) return 'en';
  const l = lang.replace('-', '_');
  if (/^pt_br$/i.test(l)) return 'pt_BR';
  const base = l.split('_')[0].toLowerCase();
  return FEEDBACK_TEXT[base] ? base : 'en';
}

/** Notification doc id: one per queue item, ever. */
export function feedbackNotificationId(queueId: string): string {
  return `report_reviewed_${queueId}`;
}

export async function notifyReporterOnResolution(
  queueId: string,
  before: admin.firestore.DocumentData | undefined,
  after: admin.firestore.DocumentData | undefined,
): Promise<boolean> {
  if (!before || !after) return false;
  if (!after.source) return false; // only pipeline items carry a real reporter
  if (FINAL_STATUSES.has(before.status) || !FINAL_STATUSES.has(after.status)) return false;
  const reporterId = after.reporterId;
  if (typeof reporterId !== 'string' || !reporterId || ['anonymous', 'admin', 'system'].includes(reporterId)) {
    return false;
  }

  const outcome = outcomeFor(after);
  let lang: unknown = 'en';
  try {
    lang = (await db.collection('users').doc(reporterId).get()).data()?.preferredLanguage;
  } catch {
    /* default to English */
  }
  const t = FEEDBACK_TEXT[feedbackLocale(lang)];
  try {
    await db.collection('notifications').doc(feedbackNotificationId(queueId)).create({
      userId: reporterId,
      // 'system' is a type every app version renders.
      type: 'system',
      title: t.title,
      message: t[outcome],
      body: t[outcome],
      // Neutral (DSA art. 16(5)/17): no identity of the reported user, no sanction detail.
      data: {
        action: 'report_reviewed',
        outcome,
        reportId: String(after.source.docId ?? ''),
      },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      actionUrl: null,
      imageUrl: null,
    });
  } catch (e) {
    if (isAlreadyExists(e)) return false;
    throw e;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Triggers
// ---------------------------------------------------------------------------

export const onUserReportQueued = onDocumentCreated(
  { document: 'user_reports/{reportId}', ...OPTS },
  monitored('onUserReportQueued', async (event) => {
    await enqueueReport('user_reports', event.params.reportId, event.data?.data());
  }),
);

export const onMessageReportQueued = onDocumentCreated(
  { document: 'message_reports/{reportId}', ...OPTS },
  monitored('onMessageReportQueued', async (event) => {
    await enqueueReport('message_reports', event.params.reportId, event.data?.data());
  }),
);

export const onContentReportQueued = onDocumentCreated(
  { document: 'reports/{reportId}', ...OPTS },
  monitored('onContentReportQueued', async (event) => {
    await enqueueReport('reports', event.params.reportId, event.data?.data());
  }),
);

export const onModerationQueueResolved = onDocumentUpdated(
  { document: 'moderation_queue/{queueId}', ...OPTS },
  monitored('onModerationQueueResolved', async (event) => {
    await notifyReporterOnResolution(
      event.params.queueId,
      event.data?.before.data(),
      event.data?.after.data(),
    );
  }),
);
