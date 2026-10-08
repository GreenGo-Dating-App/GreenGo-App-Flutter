/**
 * Minimal Resend sender, same contract as `deliverResetEmail` in
 * admin/adminPanelFunctions.ts: the API key and sender identity live in
 * `app_config/resend_settings` ({ apiKey, senderEmail?, senderName? }).
 *
 * Never throws: email is best-effort and callers that must not leak whether
 * an address exists (account deletion) answer the same way either way.
 * Never logs the full address.
 */

import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

/** `jane.doe@example.com` -> `ja***@example.com` (for logs only). */
export function maskEmail(email: string): string {
  const [local, domain] = String(email || '').split('@');
  if (!domain) return '***';
  return `${local.slice(0, 2)}***@${domain}`;
}

export async function sendResendEmail(
  to: string,
  subject: string,
  html: string,
): Promise<{ emailSent: boolean; reason?: string }> {
  try {
    const configDoc = await admin.firestore().doc('app_config/resend_settings').get();
    const cfg = configDoc.data();
    const apiKey = cfg?.apiKey;
    if (!apiKey) {
      console.warn(`sendResendEmail: Resend not configured; "${subject}" not sent to ${maskEmail(to)}`);
      return { emailSent: false, reason: 'not_configured' };
    }
    const senderEmail = cfg?.senderEmail || 'onboarding@resend.dev';
    const senderName = cfg?.senderName || 'GreenGo';

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({ from: `${senderName} <${senderEmail}>`, to: [to], subject, html }),
    });
    if (!res.ok) {
      console.error(`sendResendEmail: Resend HTTP ${res.status} for ${maskEmail(to)}`);
      return { emailSent: false, reason: `http_${res.status}` };
    }
    return { emailSent: true };
  } catch (e: any) {
    console.error(`sendResendEmail: failed for ${maskEmail(to)}`, e?.message || e);
    return { emailSent: false, reason: 'exception' };
  }
}
