/**
 * Shared transactional email sender (Resend), same configuration contract as
 * security/securityEventAlerts.ts and shared/resendEmail.ts:
 *   API key   process.env.RESEND_API_KEY, else app_config/resend_settings.apiKey
 *   sender    app_config/resend_settings.senderEmail (+ senderName)
 *
 * Never throws and never crashes a trigger: with no key it logs and returns
 * { sent: false, reason: 'not_configured' }. Never logs a full address.
 *
 * Idempotency: [claimEmailOnce] creates email_dispatch/{key} with create()
 * (fails when it exists), so a retried trigger / scheduler run cannot send the
 * same email twice. A failed send releases the claim so a later run may retry.
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { maskEmail } from '../shared/resendEmail';

export interface EmailAttachment {
  filename: string;
  /** Raw bytes; base64-encoded on send. */
  content: Buffer;
  contentType?: string;
  /** Set to reference the attachment inline as <img src="cid:ID">. */
  contentId?: string;
}

export interface OutgoingEmail {
  to: string[];
  subject: string;
  html: string;
  text?: string;
  attachments?: EmailAttachment[];
  /** Display name of the sender (default: settings senderName or "GreenGo"). */
  fromName?: string;
}

export type SendResult = { sent: boolean; reason?: string };

export const EMAIL_DISPATCH = 'email_dispatch';

/** Overridable in tests. */
export const emailDeps = {
  db: (): FirebaseFirestore.Firestore => admin.firestore(),
  fetch: (url: string, init: any): Promise<{ ok: boolean; status: number }> => (globalThis as any).fetch(url, init),
  now: (): number => Date.now(),
};

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

export function isEmail(v: unknown): v is string {
  return typeof v === 'string' && v.length <= 254 && EMAIL_RE.test(v.trim());
}

/** HTML-escape user content before it goes into an email body. */
export function escapeHtml(s: unknown): string {
  return String(s ?? '').replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', '\'': '&#39;' }[c] as string));
}

export async function sendEmail(msg: OutgoingEmail): Promise<SendResult> {
  const to = msg.to.map((s) => s.trim()).filter(isEmail);
  if (to.length === 0) return { sent: false, reason: 'no_recipient' };
  try {
    let cfg: Record<string, any> = {};
    try {
      cfg = (await emailDeps.db().doc('app_config/resend_settings').get()).data() || {};
    } catch (e) {
      console.warn('[email] could not read resend_settings:', (e as Error)?.message);
    }
    const apiKey = process.env.RESEND_API_KEY || cfg.apiKey;
    if (!apiKey) {
      console.warn(`[email] Resend not configured; "${msg.subject}" not sent to ${to.map(maskEmail).join(', ')}`);
      return { sent: false, reason: 'not_configured' };
    }
    const senderEmail = cfg.senderEmail || 'onboarding@resend.dev';
    const senderName = msg.fromName || cfg.senderName || 'GreenGo';
    const body: Record<string, unknown> = {
      from: `${senderName} <${senderEmail}>`,
      to,
      subject: msg.subject,
      html: msg.html,
      ...(msg.text ? { text: msg.text } : {}),
    };
    if (msg.attachments?.length) {
      body.attachments = msg.attachments.map((a) => ({
        filename: a.filename,
        content: a.content.toString('base64'),
        ...(a.contentType ? { content_type: a.contentType } : {}),
        ...(a.contentId ? { content_id: a.contentId } : {}),
      }));
    }
    const res = await emailDeps.fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` },
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      console.error(`[email] Resend HTTP ${res.status} for "${msg.subject}" to ${to.map(maskEmail).join(', ')}`);
      return { sent: false, reason: `http_${res.status}` };
    }
    return { sent: true };
  } catch (e) {
    console.error(`[email] send failed for "${msg.subject}":`, (e as Error)?.message || e);
    return { sent: false, reason: 'exception' };
  }
}

/** Firestore-safe dispatch id. */
export function dispatchId(key: string): string {
  return key.replace(/[^A-Za-z0-9_.-]/g, '_').slice(0, 1400);
}

/** true when this caller owns [key] (first claim); false when already claimed. */
export async function claimEmailOnce(key: string, meta: Record<string, unknown> = {}): Promise<boolean> {
  try {
    await emailDeps.db().collection(EMAIL_DISPATCH).doc(dispatchId(key)).create({
      ...meta,
      status: 'sending',
      claimedAt: admin.firestore.Timestamp.fromMillis(emailDeps.now()),
      // Firestore TTL (configure on `expireAt`) can drop these after 180 days.
      expireAt: admin.firestore.Timestamp.fromMillis(emailDeps.now() + 180 * 86400000),
    });
    return true;
  } catch (e) {
    const code = (e as { code?: unknown })?.code;
    if (code === 6 || code === 'already-exists' || /ALREADY_EXISTS/i.test(String((e as Error)?.message))) return false;
    throw e;
  }
}

/** Record the outcome; a failed send releases the claim (a later run may retry). */
export async function settleEmailClaim(key: string, result: SendResult): Promise<void> {
  const ref = emailDeps.db().collection(EMAIL_DISPATCH).doc(dispatchId(key));
  try {
    if (result.sent) {
      await ref.set({ status: 'sent', sentAt: admin.firestore.Timestamp.fromMillis(emailDeps.now()) }, { merge: true });
    } else if (result.reason === 'not_configured' || result.reason === 'no_recipient') {
      // Permanent for this item: keep the claim so a misconfiguration does not
      // turn every scheduler pass into another attempt.
      await ref.set({ status: 'skipped', reason: result.reason }, { merge: true });
    } else {
      await ref.delete();
    }
  } catch (e) {
    console.warn('[email] could not settle claim', key, (e as Error)?.message);
  }
}

/** claim -> send -> settle. Returns 'duplicate' when already handled. */
export async function sendEmailOnce(
  key: string,
  build: () => Promise<OutgoingEmail | null>,
  meta: Record<string, unknown> = {},
): Promise<SendResult | 'duplicate'> {
  if (!(await claimEmailOnce(key, meta))) return 'duplicate';
  let result: SendResult;
  try {
    const msg = await build();
    result = msg ? await sendEmail(msg) : { sent: false, reason: 'no_recipient' };
  } catch (e) {
    console.error('[email] building', key, 'failed:', (e as Error)?.message || e);
    result = { sent: false, reason: 'exception' };
  }
  await settleEmailClaim(key, result);
  return result;
}

/** Account email of [uid] (Firebase Auth), or null. */
export async function authEmailOf(uid: string): Promise<string | null> {
  try {
    const u = await admin.auth().getUser(uid);
    return isEmail(u.email) ? u.email!.trim() : null;
  } catch {
    return null;
  }
}

/** uid -> account email, batched 100 per Auth call (scales to big lists). */
export async function authEmailsOf(uids: string[]): Promise<Map<string, string>> {
  const out = new Map<string, string>();
  const unique = [...new Set(uids.filter(Boolean))];
  for (let i = 0; i < unique.length; i += 100) {
    try {
      const res = await admin.auth().getUsers(unique.slice(i, i + 100).map((uid) => ({ uid })));
      for (const u of res.users) if (isEmail(u.email)) out.set(u.uid, u.email!.trim());
    } catch (e) {
      console.warn('[email] getUsers failed:', (e as Error)?.message);
    }
  }
  return out;
}
