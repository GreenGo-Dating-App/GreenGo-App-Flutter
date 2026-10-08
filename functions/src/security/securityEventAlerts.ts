/**
 * P3-5 security-event alerts: emails the security mailbox(es) when something
 * security-relevant happens, so it is noticed in minutes instead of weeks.
 *
 *  - every admin action recorded in `admin_audit_log` (ID-document views,
 *    password changes, deletions, coin adjustments, …)
 *  - any change to `admin_users` (role added / changed / removed)
 *  - every new `fraud_flags` entry (refund clawbacks, forged gifts, sandbox
 *    grants, withheld refunds, …), capped per hour so a burst can't flood
 *  - P0 child-safety moderation alerts (`admin_alerts`)
 *
 * Emails carry NO personal data: short id prefixes, event type, time and a
 * console link only. Recipients come from SECURITY_ALERT_EMAILS (comma list).
 * Sending uses the same Resend settings as the other server emails.
 */
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { db as sharedDb } from '../shared/utils';

const db = () => sharedDb;
const CONSOLE = 'https://console.firebase.google.com/project/greengo-chat/firestore/databases/-default-/data/~2F';
const FRAUD_FLAGS_PER_HOUR = 30;

/** First 6 chars of an id: enough to look it up, not enough to identify. */
export function shortId(id: unknown): string {
  return typeof id === 'string' && id ? `${id.slice(0, 6)}…` : '-';
}

export function recipients(): string[] {
  return (process.env.SECURITY_ALERT_EMAILS || 'info@greengochat.com,greengochat.com@gmail.com')
    .split(',').map((s) => s.trim()).filter((s) => /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(s));
}

/** Per-hour counter; returns true while under [cap] for [kind]. */
async function underHourlyCap(kind: string, cap: number): Promise<boolean> {
  const hour = new Date().toISOString().slice(0, 13); // 2026-10-08T14
  const ref = db().collection('security_alert_quota').doc(`${kind}_${hour}`);
  return db().runTransaction(async (tx) => {
    const n = ((await tx.get(ref)).data()?.count as number) || 0;
    tx.set(ref, {
      count: n + 1, kind, hour,
      expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + 2 * 86400000),
    }, { merge: true });
    return n < cap;
  });
}

export async function sendSecurityAlert(subject: string, lines: string[]): Promise<boolean> {
  const to = recipients();
  if (to.length === 0) return false;
  const cfg = (await db().doc('app_config/resend_settings').get()).data() || {};
  const apiKey = process.env.RESEND_API_KEY || cfg.apiKey;
  if (!apiKey) {
    console.warn('[securityAlerts] Resend not configured; alert not emailed:', subject);
    return false;
  }
  const from = `GreenGo Security <${cfg.senderEmail || 'onboarding@resend.dev'}>`;
  const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c] as string));
  const html = `<div style="font-family:Arial,sans-serif;font-size:14px">${lines.map((l) => `<p>${esc(l)}</p>`).join('')}`
    + '<p style="color:#888;font-size:12px">Automatic GreenGo security alert (P3-5). No personal data is included; open the Firebase console to investigate.</p></div>';
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` },
    body: JSON.stringify({ from, to, subject: `[GreenGo security] ${subject}`, html }),
  });
  if (!res.ok) console.error('[securityAlerts] Resend error', res.status);
  return res.ok;
}

const SENSITIVE_ACTIONS = new Set([
  'view_id_document', 'change_user_password', 'CHANGE_USER_PASSWORD', 'delete_user', 'bulk_delete_users',
  'adjust_coins', 'admin_adjust_coins', 'override_subscription', 'grant_entitlement', 'set_user_status',
  'ban_user', 'impersonate_user', 'send_password_reset', 'set_age_assurance_override',
]);

/** Every admin action is audited; sensitive ones are flagged in the subject. */
export const alertOnAdminAudit = onDocumentCreated(
  { document: 'admin_audit_log/{id}', memory: '512MiB' },
  async (event) => {
    const d = event.data?.data() || {};
    const action = String(d.action || 'unknown');
    if (!(await underHourlyCap('admin_audit', 60))) return;
    const sensitive = SENSITIVE_ACTIONS.has(action);
    await sendSecurityAlert(`${sensitive ? 'SENSITIVE ' : ''}admin action: ${action}`, [
      `Action: ${action}${sensitive ? ' (sensitive)' : ''}`,
      `Admin: ${shortId(d.adminId)} (${String(d.adminRole || 'role n/a')})`,
      `Target: ${String(d.targetType || '-')} ${shortId(d.targetId)}`,
      `Time: ${new Date().toISOString()}`,
      `Record: ${CONSOLE}admin_audit_log~2F${event.params.id}`,
      'If you did not perform this action, change the admin password, revoke sessions and check admin_users now.',
    ]);
  },
);

/** Any admin account added, changed or removed. */
export const alertOnAdminUsersChange = onDocumentWritten(
  { document: 'admin_users/{uid}', memory: '512MiB' },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const kind = !before ? 'ADDED' : !after ? 'REMOVED' : 'CHANGED';
    const roleChange = `${String(before?.role ?? '-')} -> ${String(after?.role ?? '-')}`;
    if (kind === 'CHANGED' && before?.role === after?.role && before?.isActive === after?.isActive) return;
    await sendSecurityAlert(`admin account ${kind}: ${roleChange}`, [
      `Admin account ${kind.toLowerCase()}: ${shortId(event.params.uid)}`,
      `Role: ${roleChange}; active: ${String(before?.isActive ?? '-')} -> ${String(after?.isActive ?? '-')}`,
      `Time: ${new Date().toISOString()}`,
      `Record: ${CONSOLE}admin_users~2F${event.params.uid}`,
      'Admin rights are powerful (ID documents, passwords, coins). If this was not you, act immediately.',
    ]);
  },
);

/** Fraud / abuse flags written by the payment, coin and gift code. */
export const alertOnFraudFlag = onDocumentCreated(
  { document: 'fraud_flags/{id}', memory: '512MiB' },
  async (event) => {
    const d = event.data?.data() || {};
    const type = String(d.type || 'unknown');
    if (!(await underHourlyCap('fraud_flags', FRAUD_FLAGS_PER_HOUR))) {
      if (await underHourlyCap('fraud_flags_overflow_notice', 1)) {
        await sendSecurityAlert('fraud flag BURST - further alerts suppressed this hour', [
          `More than ${FRAUD_FLAGS_PER_HOUR} fraud flags in the last hour. Possible attack or a broken release.`,
          `Collection: ${CONSOLE}fraud_flags`,
        ]);
      }
      return;
    }
    await sendSecurityAlert(`fraud flag: ${type}`, [
      `Type: ${type}${d.reason ? ` (reason: ${String(d.reason)})` : ''}`,
      `User: ${shortId(d.userId ?? d.uid ?? d.senderId)}`,
      `Time: ${new Date().toISOString()}`,
      `Record: ${CONSOLE}fraud_flags~2F${event.params.id}`,
    ]);
  },
);

/** P0 moderation alerts (child safety / underage) also go to the security mailbox. */
export const alertOnModerationP0 = onDocumentCreated(
  { document: 'admin_alerts/{id}', memory: '512MiB' },
  async (event) => {
    const d = event.data?.data() || {};
    if (String(d.type || '') !== 'moderation_p0') return;
    await sendSecurityAlert('P0 child-safety report (24h deadline)', [
      'A report classified as child safety / underage needs action within 24 hours.',
      `Queue item: ${shortId(d.queueId)}`,
      `Time: ${new Date().toISOString()}`,
      `Open the admin panel moderation queue: https://greengo-chat-admin.web.app/moderation`,
      'Do not forward or download any images. Follow the CSAE runbook (NCMEC report, preserve evidence).',
    ]);
  },
);
