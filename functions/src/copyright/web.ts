/**
 * Public copyright notice form for rights holders who are NOT GreenGo users
 * (most are not). Served by the `copyrightNoticeWeb` HTTPS function, also
 * behind the hosting rewrite https://greengo-chat.web.app/copyright-notice.
 *
 *   GET  /                      the form (language: ?lang=, else Accept-Language)
 *   POST /                      submit (form-encoded or JSON)
 *   GET  /confirm?id=&token=    email confirmation link
 *
 * Abuse controls without a CAPTCHA (no third-party script, no tracking):
 *   - per-IP (salted SHA-256, raw IP never stored) and per-email rate limits
 *   - honeypot field
 *   - email confirmation: nothing reaches the review queue, and nobody is
 *     notified, until the complainant opens the link sent to the address
 *     they gave (a forged notice cannot be pinned on someone else's address)
 *   - unconfirmed notices are purged after 7 days (processCopyrightNotices)
 * Logged-in app users use the `submitCopyrightNotice` callable instead.
 */
import * as crypto from 'crypto';
import { HttpsError } from 'firebase-functions/v2/https';
import { AppLocale, normalizeLocale, t } from '../shared/i18n';
import { escapeHtml } from '../emails/sendEmail';
import { AGENT, parseNotice } from './model';
import { confirmWebNotice, createNotice, takeRateLimit } from './service';

export const WEB_LIMITS = { perIpPerHour: 5, perEmailPerDay: 3 };

export function localeFromRequest(req: { query?: any; body?: any; headers?: any }): AppLocale {
  const q = req.query?.lang ?? req.body?.lang;
  if (typeof q === 'string' && q) return normalizeLocale(q);
  const al = String(req.headers?.['accept-language'] || '').split(',')[0]?.split(';')[0];
  return normalizeLocale(al);
}

export function clientIp(req: { headers?: any; ip?: string }): string {
  const xf = String(req.headers?.['x-forwarded-for'] || '').split(',')[0].trim();
  return xf || String(req.headers?.['fastly-client-ip'] || '') || req.ip || 'unknown';
}

export function ipHash(ip: string): string {
  const salt = process.env.COPYRIGHT_IP_SALT || 'greengo-copyright-v1';
  return crypto.createHash('sha256').update(`${salt}:${ip}`).digest('hex').slice(0, 32);
}

const SECURITY_HEADERS: Record<string, string> = {
  'Content-Security-Policy': "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; frame-ancestors 'none'; base-uri 'none'",
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'no-referrer',
  'Cache-Control': 'no-store',
};

function page(locale: AppLocale, body: string): string {
  const e = (k: Parameters<typeof t>[1]) => escapeHtml(t(locale, k));
  return '<!doctype html><html lang="' + locale.replace('_', '-') + '"><head><meta charset="utf-8">'
    + '<meta name="viewport" content="width=device-width,initial-scale=1">'
    + `<title>${e('copyrightFormTitle')} · GreenGo</title>`
    + '<style>body{font-family:system-ui,Arial,sans-serif;max-width:680px;margin:0 auto;padding:16px;color:#111;background:#fff;line-height:1.5}'
    + 'h1{color:#0F9D58;font-size:1.5rem}fieldset{border:1px solid #ddd;border-radius:8px;margin:16px 0;padding:12px}'
    + 'label{display:block;margin:10px 0 4px;font-weight:600}input[type=text],input[type=email],input[type=tel],input[type=url],textarea{width:100%;box-sizing:border-box;padding:8px;border:1px solid #bbb;border-radius:6px;font:inherit}'
    + '.chk{display:flex;gap:8px;font-weight:400;align-items:flex-start}.chk input{margin-top:5px}.warn{background:#fff4e5;border-left:4px solid #f59e0b;padding:10px}'
    + 'button{background:#0F9D58;color:#fff;border:0;border-radius:6px;padding:12px 20px;font-size:1rem;cursor:pointer}.hp{position:absolute;left:-5000px}'
    + '@media (prefers-color-scheme:dark){body{background:#111;color:#eee}fieldset{border-color:#444}input,textarea{background:#222;color:#eee}.warn{background:#3a2a10}}</style>'
    + `</head><body><h1>${e('copyrightFormTitle')}</h1>${body}`
    + `<p style="font-size:.85rem;color:#666;white-space:pre-line">${escapeHtml(t(locale, 'copyrightPolicyAgentBody', { address: AGENT.postalAddress }))}</p>`
    + '</body></html>';
}

export function renderForm(locale: AppLocale): string {
  const e = (k: Parameters<typeof t>[1]) => escapeHtml(t(locale, k));
  const opt = ` (${e('copyrightFormOptional')})`;
  const input = (name: string, label: string, type = 'text', required = true, max = 200) =>
    `<label for="${name}">${label}${required ? ' *' : opt}</label><input id="${name}" name="${name}" type="${type}" maxlength="${max}"${required ? ' required' : ''}>`;
  const area = (name: string, label: string, required = true, max = 2000) =>
    `<label for="${name}">${label}${required ? ' *' : opt}</label><textarea id="${name}" name="${name}" rows="4" maxlength="${max}"${required ? ' required' : ''}></textarea>`;
  const chk = (name: string, label: string) =>
    `<label class="chk"><input type="checkbox" name="${name}" value="on" required><span>${label} *</span></label>`;
  return page(locale, `<p>${e('copyrightPolicyIntro')}</p><p>${e('copyrightFormIntro')}</p>`
    + '<form method="post" action="">'
    + `<input type="hidden" name="lang" value="${locale}">`
    + '<div class="hp" aria-hidden="true"><label for="website">Website</label><input id="website" name="website" tabindex="-1" autocomplete="off"></div>'
    + `<fieldset><legend>${e('copyrightFormSectionYou')}</legend>`
    + input('name', e('copyrightFormName'))
    + input('organization', e('copyrightFormOrganization'), 'text', false)
    + input('email', e('copyrightFormEmail'), 'email', true, 254)
    + input('phone', e('copyrightFormPhone'), 'tel', true, 40)
    + area('address', e('copyrightFormAddress'), true, 500)
    + `<label>${e('copyrightFormRelationship')} *</label>`
    + `<label class="chk"><input type="radio" name="relationship" value="owner" required checked><span>${e('copyrightFormRelOwner')}</span></label>`
    + `<label class="chk"><input type="radio" name="relationship" value="agent"><span>${e('copyrightFormRelAgent')}</span></label>`
    + '</fieldset>'
    + `<fieldset><legend>${e('copyrightFormSectionWork')}</legend>`
    + area('work', e('copyrightFormWorkDescription'))
    + input('workUrl', e('copyrightFormWorkUrl'), 'url', false, 1000)
    + '</fieldset>'
    + `<fieldset><legend>${e('copyrightFormSectionContent')}</legend>`
    + input('location', e('copyrightFormContentLocation'), 'text', true, 1000)
    + area('details', e('copyrightFormContentDetails'), false)
    + '</fieldset>'
    + `<fieldset><legend>${e('copyrightFormSectionStatements')}</legend>`
    + chk('goodFaith', e('copyrightFormGoodFaith'))
    + chk('accuracy', e('copyrightFormAccuracy'))
    + chk('authority', e('copyrightFormAuthority'))
    + `<p class="warn">${e('copyrightFormMisrepWarning')}</p>`
    + input('signature', e('copyrightFormSignature'))
    + '</fieldset>'
    + `<button type="submit">${e('copyrightFormSubmit')}</button></form>`);
}

export function messagePage(locale: AppLocale, key: Parameters<typeof t>[1]): string {
  return page(locale, `<p>${escapeHtml(t(locale, key))}</p>`);
}

/** Form / JSON body -> the callable's notice shape. */
export function bodyToNotice(b: any): any {
  const on = (v: unknown) => v === true || v === 'on' || v === 'true';
  return {
    complainant: { name: b.name, email: b.email, organization: b.organization, phone: b.phone, address: b.address, relationship: b.relationship },
    work: { description: b.work, url: b.workUrl },
    content: { location: b.location, details: b.details },
    statements: { goodFaith: on(b.goodFaith), accuracy: on(b.accuracy), authority: on(b.authority) },
    signature: b.signature,
  };
}

type Res = { status: (n: number) => Res; set: (k: string, v: string) => Res; send: (b: string) => void; json: (b: unknown) => void };

export async function handleCopyrightWeb(req: any, res: Res): Promise<void> {
  for (const [k, v] of Object.entries(SECURITY_HEADERS)) res.set(k, v);
  const locale = localeFromRequest(req);
  const wantsJson = String(req.headers?.['content-type'] || '').includes('application/json')
    || String(req.headers?.accept || '').startsWith('application/json');
  const reply = (code: number, key: Parameters<typeof t>[1], extra: Record<string, unknown> = {}) => {
    if (wantsJson) res.status(code).json({ ok: code < 300, message: t(locale, key), ...extra });
    else res.status(code).set('Content-Type', 'text/html; charset=utf-8').send(messagePage(locale, key));
  };
  const path = String(req.path || '/');

  if (req.method === 'GET' && /\/confirm\/?$/.test(path)) {
    const r = await confirmWebNotice(req.query?.id, req.query?.token);
    if (r === 'invalid') return reply(400, 'copyrightWebInvalidLink');
    return reply(200, 'copyrightWebConfirmed');
  }
  if (req.method === 'GET') {
    res.status(200).set('Content-Type', 'text/html; charset=utf-8').send(renderForm(locale));
    return;
  }
  if (req.method !== 'POST') {
    res.status(405).set('Allow', 'GET, POST').send('');
    return;
  }
  const b = req.body && typeof req.body === 'object' ? req.body : {};
  // Honeypot: pretend success, store nothing.
  if (typeof b.website === 'string' && b.website.trim()) return reply(200, 'copyrightWebCheckEmail');
  let input;
  try {
    input = parseNotice(bodyToNotice(b));
  } catch (e) {
    return reply(400, 'copyrightWebInvalid', { field: ((e as HttpsError)?.details as any)?.field ?? null });
  }
  const ip = ipHash(clientIp(req));
  try {
    await takeRateLimit(`web_ip_${ip}`, WEB_LIMITS.perIpPerHour, 3_600_000);
    await takeRateLimit(`web_email_${crypto.createHash('sha256').update(input.complainant.email).digest('hex').slice(0, 32)}`, WEB_LIMITS.perEmailPerDay, 86_400_000);
  } catch (e) {
    if ((e as HttpsError)?.code === 'resource-exhausted') return reply(429, 'copyrightFormRateLimited');
    throw e;
  }
  try {
    await createNotice(input, { source: 'web', submitterUid: null, locale, ipHash: ip });
  } catch (e) {
    console.error('[copyright] web submit failed:', (e as Error)?.message);
    return reply(500, 'copyrightFormError');
  }
  return reply(200, 'copyrightWebCheckEmail');
}
