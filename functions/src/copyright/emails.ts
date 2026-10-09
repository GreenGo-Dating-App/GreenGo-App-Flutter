/**
 * Copyright emails, in the recipient's language (server i18n catalog built
 * from the app ARBs). Complainants who are not users get the language they
 * used to submit (notice.locale); uploaders get their app language.
 *
 * What each party receives (DMCA forwarding):
 *   uploader    a copy of the notice WITHOUT the complainant's phone and
 *               postal address (name + email are kept so a counter-notice
 *               can be addressed; the form warns the complainant)
 *   complainant the FULL counter-notice (§512(g)(2)(B) requires forwarding
 *               it; the counter-notice form warns the uploader)
 *   admins      reference + link only, never personal data
 */
import { t } from '../shared/i18n';
import { detailsTable, emailFrame, intlLocale } from '../emails/emailFormat';
import { escapeHtml, OutgoingEmail } from '../emails/sendEmail';
import { AGENT, noticeRef, panelLink } from './model';

export function formatDate(ms: number, locale: unknown): string {
  try {
    return new Intl.DateTimeFormat(intlLocale(locale), { dateStyle: 'long', timeZone: 'UTC' }).format(new Date(ms));
  } catch {
    return new Date(ms).toISOString().slice(0, 10);
  }
}

const p = (s: string) => `<p>${escapeHtml(s)}</p>`;

/** Copy of a notice for the uploader (no complainant phone / address). */
export function noticeCopyHtml(n: Record<string, any>, locale: unknown, submittedMs: number): string {
  const rel = n.complainant?.relationship === 'agent' ? t(locale, 'copyrightFormRelAgent') : t(locale, 'copyrightFormRelOwner');
  const rows: Array<[string, string | null | undefined]> = [
    [t(locale, 'emailCopyrightRefLabel'), noticeRef(n.noticeId)],
    [t(locale, 'emailCopyrightDateLabel'), formatDate(submittedMs, locale)],
    [t(locale, 'copyrightFormName'), n.complainant?.name],
    [t(locale, 'copyrightFormOrganization'), n.complainant?.organization],
    [t(locale, 'copyrightFormEmail'), n.complainant?.email],
    [t(locale, 'copyrightFormRelationship'), rel],
    [t(locale, 'copyrightFormWorkDescription'), n.work?.description],
    [t(locale, 'copyrightFormWorkUrl'), n.work?.url],
    [t(locale, 'copyrightFormContentLocation'), n.content?.location],
    [t(locale, 'copyrightFormContentDetails'), n.content?.details],
    [t(locale, 'copyrightFormSignature'), n.signature],
  ];
  const statements = ['copyrightFormGoodFaith', 'copyrightFormAccuracy', 'copyrightFormAuthority'] as const;
  return `<h3>${escapeHtml(t(locale, 'emailCopyrightNoticeCopy'))}</h3>${detailsTable(rows)}`
    + `<ul>${statements.map((k) => `<li>${escapeHtml(t(locale, k))}</li>`).join('')}</ul>`;
}

export function uploaderRemovedEmail(to: string, n: Record<string, any>, locale: unknown, submittedMs: number, activeStrikes: number): OutgoingEmail {
  return {
    to: [to],
    subject: t(locale, 'emailCopyrightRemovedSubject'),
    html: emailFrame(
      p(t(locale, 'emailCopyrightRemovedIntro'))
      + p(t(locale, 'emailCopyrightStrikeInfo', { count: activeStrikes }))
      + p(t(locale, 'emailCopyrightCounterInfo'))
      + noticeCopyHtml(n, locale, submittedMs),
    ),
    fromName: 'GreenGo Copyright',
    replyTo: AGENT.email,
  };
}

export function complainantAcceptedEmail(n: Record<string, any>): OutgoingEmail {
  const l = n.locale;
  return {
    to: [n.complainant.email],
    subject: t(l, 'emailCopyrightAcceptedSubject'),
    html: emailFrame(p(t(l, 'emailCopyrightAcceptedBody', { ref: noticeRef(n.noticeId) }))),
    fromName: 'GreenGo Copyright',
    replyTo: AGENT.email,
  };
}

export function complainantRejectedEmail(n: Record<string, any>, reason: string): OutgoingEmail {
  const l = n.locale;
  return {
    to: [n.complainant.email],
    subject: t(l, 'emailCopyrightRejectedSubject'),
    html: emailFrame(p(t(l, 'emailCopyrightRejectedBody', { ref: noticeRef(n.noticeId), reason }))),
    fromName: 'GreenGo Copyright',
    replyTo: AGENT.email,
  };
}

/** Full counter-notice, forwarded to the complainant. */
export function complainantCounterEmail(n: Record<string, any>, c: Record<string, any>, restoreAfterMs: number): OutgoingEmail {
  const l = n.locale;
  const rows: Array<[string, string | null | undefined]> = [
    [t(l, 'emailCopyrightRefLabel'), noticeRef(n.noticeId)],
    [t(l, 'copyrightFormContentLocation'), n.content?.location],
    [t(l, 'copyrightFormName'), c.name],
    [t(l, 'copyrightFormAddress'), c.address],
    [t(l, 'copyrightFormPhone'), c.phone],
    [t(l, 'copyrightFormEmail'), c.email],
    [t(l, 'copyrightCounterExplanation'), c.explanation],
    [t(l, 'copyrightFormSignature'), c.signature],
  ];
  return {
    to: [n.complainant.email],
    subject: t(l, 'emailCopyrightCounterSubject'),
    html: emailFrame(
      p(t(l, 'emailCopyrightCounterBody', { ref: noticeRef(n.noticeId), date: formatDate(restoreAfterMs, l), agentEmail: AGENT.email }))
      + `<h3>${escapeHtml(t(l, 'copyrightCounterTitle'))}</h3>${detailsTable(rows)}`
      + `<ul><li>${escapeHtml(t(l, 'copyrightCounterPerjury'))}</li><li>${escapeHtml(t(l, 'copyrightCounterJurisdiction'))}</li></ul>`,
    ),
    fromName: 'GreenGo Copyright',
    replyTo: AGENT.email,
  };
}

export function complainantRestoredEmail(n: Record<string, any>): OutgoingEmail {
  const l = n.locale;
  return {
    to: [n.complainant.email],
    subject: t(l, 'emailCopyrightRestoredSubject'),
    html: emailFrame(p(t(l, 'emailCopyrightRestoredBody', { ref: noticeRef(n.noticeId) }))),
    fromName: 'GreenGo Copyright',
    replyTo: AGENT.email,
  };
}

export function confirmEmail(to: string, locale: unknown, link: string): OutgoingEmail {
  return {
    to: [to],
    subject: t(locale, 'emailCopyrightConfirmSubject'),
    html: emailFrame(
      p(t(locale, 'emailCopyrightConfirmIntro'))
      + `<p><a href="${escapeHtml(link)}" style="display:inline-block;padding:10px 16px;background:#0F9D58;color:#fff;border-radius:6px;text-decoration:none">${escapeHtml(t(locale, 'emailCopyrightConfirmButton'))}</a></p>`
      + `<p style="color:#555;font-size:12px">${escapeHtml(link)}</p>`,
    ),
    text: `${t(locale, 'emailCopyrightConfirmIntro')}\n${link}`,
    fromName: 'GreenGo Copyright',
    replyTo: AGENT.email,
  };
}

/** Admin alert: reference, kind and panel link only (no personal data, also not in the subject). */
export function adminAlertEmail(to: string[], noticeId: string, kind: 'notice' | 'counter', meta: { source?: string; contentType?: string | null }): OutgoingEmail {
  const ref = noticeRef(noticeId);
  const link = panelLink(noticeId);
  const what = kind === 'notice' ? 'New copyright notice' : 'Copyright counter-notice received';
  return {
    to,
    subject: `${what} ${ref}`,
    html: '<div style="font-family:Arial,sans-serif;font-size:14px;color:#111">'
      + `<p>${escapeHtml(what)}: <b>${escapeHtml(ref)}</b></p>`
      + (meta.source ? `<p>Source: ${escapeHtml(meta.source)}${meta.contentType ? `, content type: ${escapeHtml(meta.contentType)}` : ''}</p>` : '')
      + `<p><a href="${escapeHtml(link)}" style="display:inline-block;padding:10px 16px;background:#0F9D58;color:#fff;border-radius:6px;text-decoration:none">Open in the admin panel</a></p>`
      + `<p style="color:#555;font-size:12px">${escapeHtml(link)}</p>`
      + '<p style="color:#888;font-size:12px">Admin login required. This email intentionally contains no personal data.'
      + (kind === 'counter' ? ' The material is restored automatically after 10 business days unless you mark "lawsuit filed".' : '')
      + '</p></div>',
    text: `${what} ${ref}\n${link}`,
    fromName: 'GreenGo Copyright',
    replyTo: AGENT.email,
  };
}
