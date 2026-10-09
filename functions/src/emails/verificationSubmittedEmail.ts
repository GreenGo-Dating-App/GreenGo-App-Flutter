/**
 * ID / age-document submitted -> email the verification reviewers.
 *
 * Trigger: age_verification_queue/{uid} written with status 'pending' (what
 * submitAgeDocument writes when a document needs a human decision; a
 * re-submission overwrites the doc with a new submittedAt).
 *
 * The email carries NO personal data and NO image: only the uid (subject
 * exactly "DOCUMENTVERIFICATION FOR USER <uid>") and a deep link to the admin
 * panel, which still requires an admin login (and superAdmin to view the
 * document; every view is audit-logged).
 *
 * One email per submission: idempotency key = uid + submittedAt millis.
 * Recipients: ADMIN_VERIFICATION_EMAILS (comma list), default
 * greengochat.com@gmail.com. Panel base: ADMIN_PANEL_URL (default
 * https://greengo-chat-admin.web.app).
 */
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { escapeHtml, isEmail, sendEmailOnce } from './sendEmail';

export const DEFAULT_VERIFICATION_RECIPIENT = 'greengochat.com@gmail.com';
export const DEFAULT_ADMIN_PANEL_URL = 'https://greengo-chat-admin.web.app';

export function verificationRecipients(env: string | undefined = process.env.ADMIN_VERIFICATION_EMAILS): string[] {
  const list = (env && env.trim() ? env : DEFAULT_VERIFICATION_RECIPIENT)
    .split(/[,;\s]+/).map((s) => s.trim()).filter(isEmail);
  return list.length ? [...new Set(list)] : [DEFAULT_VERIFICATION_RECIPIENT];
}

export function verificationSubject(uid: string): string {
  return `DOCUMENTVERIFICATION FOR USER ${uid}`;
}

export function verificationReviewLink(uid: string, base: string | undefined = process.env.ADMIN_PANEL_URL): string {
  const root = (base && /^https:\/\//.test(base.trim()) ? base.trim() : DEFAULT_ADMIN_PANEL_URL).replace(/\/+$/, '');
  return `${root}/age-verification?user=${encodeURIComponent(uid)}`;
}

export function verificationEmailHtml(uid: string, link: string): string {
  return `<div style="font-family:Arial,sans-serif;font-size:14px;color:#111">`
    + '<p>A user submitted an identity document for age verification. It stays <b>under review</b> until an admin decides.</p>'
    + `<p>User ID: <code>${escapeHtml(uid)}</code></p>`
    + `<p><a href="${escapeHtml(link)}" style="display:inline-block;padding:10px 16px;background:#0F9D58;color:#fff;border-radius:6px;text-decoration:none">Open the verification in the admin panel</a></p>`
    + `<p style="color:#555;font-size:12px">${escapeHtml(link)}</p>`
    + '<p style="color:#888;font-size:12px">Admin login required. This email intentionally contains no personal data and no document image. The document is deleted 7 days after submission if no decision is made.</p>'
    + '</div>';
}

function millisOf(v: unknown): number | null {
  if (v instanceof admin.firestore.Timestamp) return v.toMillis();
  if (v && typeof (v as any).toMillis === 'function') return (v as any).toMillis();
  return null;
}

/** Is this write a NEW pending submission? (pure; exported for tests) */
export function isNewSubmission(
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined,
): boolean {
  if (!after || after.status !== 'pending') return false;
  if (!before || before.status !== 'pending') return true;
  return millisOf(before.submittedAt) !== millisOf(after.submittedAt);
}

export async function handleVerificationQueueWrite(
  uid: string,
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined,
): Promise<'sent' | 'skipped' | 'duplicate' | 'failed'> {
  if (!isNewSubmission(before, after)) return 'skipped';
  const submitted = millisOf(after!.submittedAt) ?? 0;
  const link = verificationReviewLink(uid);
  const r = await sendEmailOnce(`idv_${uid}_${submitted}`, async () => ({
    to: verificationRecipients(),
    subject: verificationSubject(uid),
    html: verificationEmailHtml(uid, link),
    text: `A user submitted an identity document for review.\nUser ID: ${uid}\nReview: ${link}\n(Admin login required. No personal data in this email.)`,
    fromName: 'GreenGo Verification',
  }), { type: 'id_verification_submitted', uid });
  if (r === 'duplicate') return 'duplicate';
  return r.sent ? 'sent' : 'failed';
}

export const emailOnIdVerificationSubmitted = onDocumentWritten(
  { document: 'age_verification_queue/{uid}', memory: '512MiB' },
  async (event) => {
    await handleVerificationQueueWrite(
      event.params.uid,
      event.data?.before?.data(),
      event.data?.after?.data(),
    );
  },
);
