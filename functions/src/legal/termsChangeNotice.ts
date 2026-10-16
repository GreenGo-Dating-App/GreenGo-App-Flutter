/**
 * Terms 24.2 a: tell every user about an important Terms change at least 30
 * days before it takes effect, by email, in their app language.
 *
 * adminSendTermsChangeNotice (superAdmin, admin panel) - ONE BOUNDED PAGE per
 * call, so it scales to millions of users without a long-running job:
 *
 *   request  { version: '5.3.0', dryRun?: boolean (DEFAULT TRUE),
 *              pageSize?: 1..500 (default 200), cursor?: string | null }
 *   response { version, effectiveDate, url, dryRun, processed, withEmail,
 *              sent, alreadySent, skippedNoEmail, skippedNewAccounts, failed,
 *              locales: {en: n, ...},
 *              nextCursor: string | null, done: boolean, noticeDaysLeft,
 *              preview?: { subject, text } (dry run, English) }
 *
 * The panel calls it again with `cursor = nextCursor` until `done`. Pages walk
 * `users` by document id (no index needed); emails come from Firebase Auth in
 * batches of 100 (authEmailsOf); the language from the users doc already
 * loaded (no extra reads). When the notice has accountsCreatedBefore, accounts
 * created on or after that date (Auth creation time, same getUsers call) are
 * skipped: they accepted the version at sign-up (skippedNewAccounts).
 *
 * Idempotent per user + version: every email is claimed in
 * email_dispatch/terms_notice_<version>_<uid> before sending (sendEmailOnce),
 * so re-running a page, a retry or two admins in parallel never send twice; a
 * failed send releases the claim so a later run retries it.
 *
 * Live runs add their counters to legal_notice_runs/terms_<version> (admin
 * read only) with the last cursor, so a run can be resumed and audited.
 */
import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { requireAdmin, SUPER_ADMIN_ONLY } from '../shared/adminAuth';
import {
  EMAIL_DISPATCH, OutgoingEmail, authEmailsOf, dispatchId, emailDeps, escapeHtml, sendEmailOnce,
} from '../emails/sendEmail';
import { emailFrame, intlLocale } from '../emails/emailFormat';
import { localeFromUserData } from '../shared/i18n/recipientLocale';
import type { AppLocale } from '../shared/i18n/locales';
import { NOTICE_COPY, TERMS_NOTICES, TermsNotice } from './termsNoticeCopy';

export const NOTICE_RUNS = 'legal_notice_runs';
const MAX_PAGE = 500;
const DEFAULT_PAGE = 200;
const SEND_PARALLEL = 10;

/** Dispatch key of the notice for [uid] (one email per user and version). */
export const noticeKey = (version: string, uid: string) => `terms_notice_${version}_${uid}`;

function effectiveMs(n: TermsNotice): number {
  return Date.parse(`${n.effectiveDate}T00:00:00Z`);
}

/** "16 November 2026" in [locale]. */
export function formatNoticeDate(n: TermsNotice, locale: AppLocale): string {
  try {
    return new Intl.DateTimeFormat(intlLocale(locale), { dateStyle: 'long', timeZone: 'UTC' })
      .format(new Date(effectiveMs(n)));
  } catch {
    return n.effectiveDate;
  }
}

/** The notice email for [locale] (subject, html, plain text). */
export function buildNoticeEmail(n: TermsNotice, locale: AppLocale, to: string): OutgoingEmail {
  const c = NOTICE_COPY[locale] || NOTICE_COPY.en;
  const bullets = n.bullets[locale] || n.bullets.en;
  const date = formatNoticeDate(n, locale);
  const html = emailFrame(
    `<p>${escapeHtml(c.hello)}</p>`
    + `<p>${escapeHtml(c.intro(n.version, date))}</p>`
    + `<p><strong>${escapeHtml(c.whatChanges)}</strong></p>`
    + `<ul>${bullets.map((b) => `<li>${escapeHtml(b)}</li>`).join('')}</ul>`
    + `<p><a href="${escapeHtml(n.url)}" style="color:#0F9D58;font-weight:bold">${escapeHtml(c.read)}</a></p>`
    + `<p>${escapeHtml(c.rights(date))}</p>`
    + `<p style="color:#777;font-size:12px">${escapeHtml(c.footer)}</p>`,
  );
  const text = [
    c.hello, '', c.intro(n.version, date), '', c.whatChanges,
    ...bullets.map((b) => `- ${b}`), '', `${c.read}: ${n.url}`, '', c.rights(date), '', c.footer,
  ].join('\n');
  return { to: [to], subject: c.subject(n.version, date), html, text };
}

export interface NoticeRunInput {
  version?: unknown;
  dryRun?: unknown;
  pageSize?: unknown;
  cursor?: unknown;
}

export async function runTermsNoticePage(input: NoticeRunInput, by: string) {
  const version = typeof input?.version === 'string' ? input.version.trim() : '';
  const notice = TERMS_NOTICES[version];
  if (!notice) throw new HttpsError('invalid-argument', 'unknown_version', { known: Object.keys(TERMS_NOTICES) });
  const now = emailDeps.now();
  if (now >= effectiveMs(notice)) {
    throw new HttpsError('failed-precondition', 'notice_period_over');
  }
  const dryRun = input?.dryRun !== false;
  const size = Math.min(MAX_PAGE, Math.max(1, Math.floor(Number(input?.pageSize) || DEFAULT_PAGE)));
  const cursor = typeof input?.cursor === 'string' && input.cursor && !input.cursor.includes('/') ? input.cursor : null;

  const db = emailDeps.db();
  let q = db.collection('users')
    .select('appLanguage', 'preferredLanguage', 'isDeleted', 'accountDeleted')
    .orderBy(admin.firestore.FieldPath.documentId())
    .limit(size);
  if (cursor) q = q.startAfter(cursor);
  const snap = await q.get();

  const users = snap.docs
    .filter((d) => d.get('isDeleted') !== true && d.get('accountDeleted') !== true)
    .map((d) => ({ uid: d.id, locale: localeFromUserData(d.data()) }));
  const tooNew = new Set<string>();
  const createdBeforeMs = notice.accountsCreatedBefore
    ? Date.parse(`${notice.accountsCreatedBefore}T00:00:00Z`) : undefined;
  const emails = await authEmailsOf(users.map((u) => u.uid), { createdBeforeMs, tooNew });
  const withEmail = users.filter((u) => emails.has(u.uid));

  const locales: Record<string, number> = {};
  for (const u of withEmail) locales[u.locale] = (locales[u.locale] || 0) + 1;

  let sent = 0;
  let alreadySent = 0;
  let failed = 0;
  if (dryRun) {
    // How many of this page already got it (getAll in chunks, no writes).
    for (let i = 0; i < withEmail.length; i += 300) {
      const refs = withEmail.slice(i, i + 300)
        .map((u) => db.collection(EMAIL_DISPATCH).doc(dispatchId(noticeKey(version, u.uid))));
      if (!refs.length) continue;
      const docs = await db.getAll(...refs);
      alreadySent += docs.filter((d) => d.exists && d.get('status') !== 'sending').length;
    }
  } else {
    for (let i = 0; i < withEmail.length; i += SEND_PARALLEL) {
      const results = await Promise.all(withEmail.slice(i, i + SEND_PARALLEL).map((u) =>
        sendEmailOnce(
          noticeKey(version, u.uid),
          async () => buildNoticeEmail(notice, u.locale, emails.get(u.uid)!),
          { kind: 'terms_notice', version, uid: u.uid },
        )));
      for (const r of results) {
        if (r === 'duplicate') alreadySent++;
        else if (r.sent) sent++;
        else failed++;
      }
    }
  }

  const last = snap.docs.length ? snap.docs[snap.docs.length - 1].id : null;
  const done = snap.docs.length < size;
  const nextCursor = done ? null : last;
  const result = {
    version,
    effectiveDate: notice.effectiveDate,
    url: notice.url,
    dryRun,
    processed: snap.docs.length,
    withEmail: withEmail.length,
    sent,
    alreadySent,
    skippedNoEmail: users.length - withEmail.length - tooNew.size,
    skippedNewAccounts: tooNew.size,
    failed,
    locales,
    nextCursor,
    done,
    noticeDaysLeft: Math.floor((effectiveMs(notice) - now) / 86400000),
    ...(dryRun ? { preview: (() => {
      const m = buildNoticeEmail(notice, 'en', 'preview@example.com');
      return { subject: m.subject, text: m.text };
    })() } : {}),
  };

  if (!dryRun) {
    const inc = admin.firestore.FieldValue.increment;
    await db.collection(NOTICE_RUNS).doc(`terms_${version}`).set({
      doc: 'terms',
      version,
      effectiveDate: notice.effectiveDate,
      processed: inc(result.processed),
      sent: inc(sent),
      alreadySent: inc(alreadySent),
      skippedNoEmail: inc(result.skippedNoEmail),
      skippedNewAccounts: inc(result.skippedNewAccounts),
      failed: inc(failed),
      lastCursor: last,
      done,
      updatedAt: admin.firestore.Timestamp.fromMillis(now),
      updatedBy: by,
    }, { merge: true });
  }
  return result;
}

export const adminSendTermsChangeNotice = onCall({ memory: '512MiB', timeoutSeconds: 540 }, async (request) => {
  const who = await requireAdmin(request.auth as any, SUPER_ADMIN_ONLY);
  return runTermsNoticePage((request.data || {}) as NoticeRunInput, who.uid);
});
