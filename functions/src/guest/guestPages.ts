/**
 * Guest pages — pure HTML rendering (no I/O). Every dynamic value goes
 * through escapeHtml (titles, descriptions, names, e-mails, URLs, attribute
 * values); the pages carry no JavaScript at all (CSP script-src 'none', see
 * GUEST_SECURITY_HEADERS), so user content can never execute.
 *
 * Same dark / gold look as the shared-link landing (share/sharePreviewCore).
 */
import { AppLocale } from '../shared/i18n';
import { APPSTORE_URL, BRAND, HOST, PLAY_URL, bcp47, escapeHtml } from '../share/sharePreviewCore';
import { GuestKey, gt } from './guestI18n';
import { GuestInput, GuestKind } from './guestModel';

export const GUEST_SECURITY_HEADERS: Record<string, string> = {
  'Content-Security-Policy':
    "default-src 'none'; img-src https: data:; style-src 'unsafe-inline'; form-action 'self'; "
    + "frame-ancestors 'none'; base-uri 'none'",
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'Referrer-Policy': 'same-origin',
  // Personal pages (form token, live seats, order state): never cached.
  'Cache-Control': 'private, no-store',
  'Vary': 'Accept-Language',
};

// Marketing-site legal pages (greengochat.com). TERMS_URL: confirm the path with the owner.
export const TERMS_URL = 'https://greengochat.com/terms';
export const PRIVACY_URL = 'https://greengochat.com/privacy-policy'; // = shared/marketingConsent.ts

export type FormMode = 'pay' | 'free' | 'request';

export interface FormView {
  mode: FormMode;
  /** Path the form posts to (same origin). */
  action: string;
  token: string;
  /** Events without ticket types: 1..quantityMax tickets. */
  quantityMax?: number;
  /** Events with ticket types: one 0..max select per type. */
  types?: Array<{ id: string; label: string; max: number }>;
  /** Experiences: start times + party size. */
  slots?: Array<{ value: string; label: string }>;
  partyMin?: number;
  partyMax?: number;
  /** "Stripe" | "Mercado Pago" (pay mode). */
  provider?: string;
  /**
   * "Ask for attendee names" (paid events): the most tickets one order can
   * have. Ticket 1 is in the guest's own name; rows 2..N ask the name of
   * every other ticket holder (only the rows up to the chosen quantity count).
   */
  attendeeNames?: number;
}

export interface ListingView {
  kind: GuestKind;
  id: string;
  locale: AppLocale;
  title: string;
  description: string;
  imageUrl: string | null;
  facts: Array<[string, string]>;
  /** null = no capacity shown; 0 = sold out. */
  seatsLeft: number | null;
  /** Localized read-only notice (why guests cannot book). */
  notice: string | null;
  form: FormView | null;
  /** Localized error from the last submit. */
  error: string | null;
  values?: Partial<GuestInput>;
  /** Names typed for tickets 2..N (kept when the form is shown again). */
  attendeeValues?: Array<{ firstName: string; lastName: string }>;
}

const CSS = `
:root{color-scheme:dark}
*{box-sizing:border-box}
html,body{margin:0;min-height:100%}
body{background:#0A0A0A;color:#fff;font:16px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;padding:16px}
main{max-width:560px;margin:0 auto}
.brand{color:#D4AF37;font-weight:800;letter-spacing:.5px;display:flex;justify-content:space-between;align-items:center;margin-bottom:16px}
.badge{font-size:12px;font-weight:600;color:#0A0A0A;background:#D4AF37;border-radius:999px;padding:3px 10px}
.hero{width:100%;border-radius:16px;aspect-ratio:1200/630;object-fit:cover;display:block;background:#1a1a1a}
h1{color:#D4AF37;font-size:24px;line-height:1.25;margin:16px 0 8px;overflow-wrap:anywhere}
h2{font-size:18px;margin:0 0 12px}
p{color:#C8C8C8;margin:0 0 12px;overflow-wrap:anywhere}
.desc{white-space:pre-line}
dl{display:grid;grid-template-columns:auto 1fr;gap:6px 14px;margin:12px 0 16px}
dt{color:#9A9A9A}dd{margin:0;font-weight:600;overflow-wrap:anywhere}
.card{background:#151515;border:1px solid #2a2a2a;border-radius:16px;padding:16px;margin:20px 0}
.seats{display:inline-block;color:#D4AF37;font-weight:700;margin-bottom:8px}
.notice{background:#1d1a10;border-left:4px solid #D4AF37;padding:12px;border-radius:8px;color:#eee}
.error{background:#2a1212;border-left:4px solid #e5484d;padding:12px;border-radius:8px;color:#ffd7d7;margin-bottom:12px}
label{display:block;font-weight:600;margin:12px 0 4px}
input[type=text],input[type=email],select{width:100%;padding:12px;border-radius:10px;border:1px solid #3a3a3a;background:#0f0f0f;color:#fff;font:inherit}
input:focus,select:focus{outline:2px solid #D4AF37;outline-offset:1px}
.row{display:flex;gap:12px}.row>div{flex:1;min-width:0}
fieldset.attendees{border:1px solid #333;border-radius:12px;padding:10px 12px;margin:12px 0}fieldset.attendees legend{color:#D4AF37;font-weight:600;padding:0 6px}
.hint{font-size:13px;color:#9A9A9A;margin:4px 0 0}
.chk{display:flex;gap:10px;align-items:flex-start;font-weight:400;margin-top:16px}
.chk input{margin-top:4px;width:18px;height:18px;flex:none}
a{color:#D4AF37}
.btn{display:block;width:100%;margin-top:18px;padding:14px 20px;border:0;border-radius:30px;background:#D4AF37;color:#0A0A0A;font:inherit;font-weight:700;text-align:center;text-decoration:none;cursor:pointer}
.btn.secondary{background:transparent;color:#D4AF37;border:1px solid #D4AF37}
.hp{position:absolute;left:-9999px;width:1px;height:1px;overflow:hidden}
footer{margin:28px 0 8px;font-size:13px;color:#7a7a7a;text-align:center}
@media (max-width:420px){.row{flex-direction:column;gap:0}h1{font-size:21px}}
`;

function e(s: string): string {
  return escapeHtml(s);
}

export function layout(locale: AppLocale, title: string, body: string, extraHead = ''): string {
  return `<!DOCTYPE html>
<html lang="${e(bcp47(locale))}">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<meta name="robots" content="noindex, nofollow" />
<title>${e(title)} · ${BRAND}</title>${extraHead}
<style>${CSS}</style>
</head>
<body>
<main>
<div class="brand"><span>${BRAND}</span><span class="badge">${e(gt(locale, 'guest.page.badge'))}</span></div>
${body}
<footer>
<a href="${e(TERMS_URL)}" rel="noopener">${e(gt(locale, 'guest.form.terms'))}</a> ·
<a href="${e(PRIVACY_URL)}" rel="noopener">${e(gt(locale, 'guest.form.privacy'))}</a>
</footer>
</main>
</body>
</html>`;
}

function select(name: string, label: string, options: Array<{ value: string; label: string }>, selected?: string): string {
  const opts = options
    .map((o) => `<option value="${e(o.value)}"${o.value === selected ? ' selected' : ''}>${e(o.label)}</option>`)
    .join('');
  return `<label for="${e(name)}">${e(label)}</label><select id="${e(name)}" name="${e(name)}" required>${opts}</select>`;
}

function range(from: number, to: number): Array<{ value: string; label: string }> {
  const out: Array<{ value: string; label: string }> = [];
  for (let i = from; i <= to; i++) out.push({ value: String(i), label: String(i) });
  return out;
}

function formHtml(v: ListingView, f: FormView): string {
  const L = v.locale;
  const vals = v.values ?? {};
  const titleKey: GuestKey = f.mode === 'pay' ? 'guest.form.titlePay' : f.mode === 'free' ? 'guest.form.titleFree' : 'guest.form.titleRequest';
  const submitKey: GuestKey = f.mode === 'pay' ? 'guest.form.submitPay' : f.mode === 'free' ? 'guest.form.submitFree' : 'guest.form.submitRequest';
  const terms = `<a href="${e(TERMS_URL)}" target="_blank" rel="noopener">${e(gt(L, 'guest.form.terms'))}</a>`;
  const privacy = `<a href="${e(PRIVACY_URL)}" target="_blank" rel="noopener">${e(gt(L, 'guest.form.privacy'))}</a>`;
  // Escape the sentence first, then put the (already escaped) links in.
  const consent = e(gt(L, 'guest.form.consent', { terms: '\u0001T\u0001', privacy: '\u0001P\u0001' }))
    .replace('\u0001T\u0001', terms)
    .replace('\u0001P\u0001', privacy);

  let choice = '';
  if (f.types && f.types.length) {
    choice = f.types.map((t, i) => select(`qty_${t.id}`, t.label, range(0, t.max), i === 0 ? '1' : '0')).join('');
  } else if (f.quantityMax) {
    choice = select('quantity', gt(L, 'guest.form.quantity'), range(1, f.quantityMax), '1');
  }
  if (f.slots) {
    choice += select('slot', gt(L, 'guest.form.time'), f.slots);
    choice += select('partySize', gt(L, 'guest.form.partySize'), range(Math.max(1, f.partyMin ?? 1), Math.max(1, f.partyMin ?? 1, f.partyMax ?? 1)), String(Math.max(1, f.partyMin ?? 1)));
  }
  if (f.attendeeNames && f.attendeeNames > 1) {
    const av = v.attendeeValues ?? [];
    let rows = '';
    for (let i = 2; i <= f.attendeeNames; i++) {
      const x = av[i - 2] ?? { firstName: '', lastName: '' };
      rows += `<p class="hint" style="margin:10px 0 4px">${e(gt(L, 'guest.form.attendeeN', { index: i }))}</p>
<div class="row">
<div><label for="att_${i}_first">${e(gt(L, 'guest.form.firstName'))}</label><input type="text" id="att_${i}_first" name="att_${i}_first" maxlength="50" autocomplete="off" value="${e(x.firstName)}" /></div>
<div><label for="att_${i}_last">${e(gt(L, 'guest.form.lastName'))}</label><input type="text" id="att_${i}_last" name="att_${i}_last" maxlength="50" autocomplete="off" value="${e(x.lastName)}" /></div>
</div>`;
    }
    choice += `<fieldset class="attendees"><legend>${e(gt(L, 'guest.form.attendeesTitle'))}</legend>
<p class="hint">${e(gt(L, 'guest.form.attendeesHint'))}</p>${rows}</fieldset>`;
  }
  const note = f.mode === 'pay' && f.provider
    ? `<p class="hint">${e(gt(L, 'guest.form.secureNote', { provider: f.provider }))}</p>`
    : f.mode === 'request'
      ? `<p class="hint">${e(gt(L, 'guest.form.requestNote'))}</p>`
      : '';
  return `<section class="card" aria-labelledby="book">
<h2 id="book">${e(gt(L, titleKey))}</h2>
${v.error ? `<div class="error" role="alert">${e(v.error)}</div>` : ''}
<form method="post" action="${e(f.action)}" autocomplete="on" novalidate>
<input type="hidden" name="token" value="${e(f.token)}" />
<input type="hidden" name="hl" value="${e(L)}" />
<div class="hp" aria-hidden="true"><label for="website">Website</label><input type="text" id="website" name="website" tabindex="-1" autocomplete="off" /></div>
<div class="row">
<div><label for="firstName">${e(gt(L, 'guest.form.firstName'))}</label><input type="text" id="firstName" name="firstName" maxlength="60" autocomplete="given-name" required value="${e(vals.firstName ?? '')}" /></div>
<div><label for="lastName">${e(gt(L, 'guest.form.lastName'))}</label><input type="text" id="lastName" name="lastName" maxlength="60" autocomplete="family-name" required value="${e(vals.lastName ?? '')}" /></div>
</div>
<label for="email">${e(gt(L, 'guest.form.email'))}</label>
<input type="email" id="email" name="email" maxlength="254" autocomplete="email" inputmode="email" required value="${e(vals.email ?? '')}" />
<p class="hint">${e(gt(L, 'guest.form.emailHint'))}</p>
${choice}
<label class="chk"><input type="checkbox" name="consent" value="on" required /> <span>${consent}</span></label>
<p class="hint">${e(gt(L, 'guest.form.privacyNote'))}</p>
<button class="btn" type="submit">${e(gt(L, submitKey))}</button>
${note}
</form>
</section>`;
}

function appButtons(locale: AppLocale, kind: GuestKind, id: string): string {
  const web = `${HOST}/?link=${encodeURIComponent(`/${kind}/${id}`)}`;
  return `<a class="btn secondary" href="${e(web)}">${e(gt(locale, 'guest.landing.openApp'))}</a>
<p class="hint" style="text-align:center;margin-top:10px"><a href="${e(PLAY_URL)}" rel="noopener">Google Play</a> · <a href="${e(APPSTORE_URL)}" rel="noopener">App Store</a></p>`;
}

/** The read-only guest view of ONE listing, with the booking form when allowed. */
export function renderListingPage(v: ListingView): string {
  const L = v.locale;
  const facts = v.facts.length
    ? `<dl>${v.facts.map(([k, val]) => `<dt>${e(k)}</dt><dd>${e(val)}</dd>`).join('')}</dl>`
    : '';
  const seats = v.seatsLeft === null
    ? ''
    : `<span class="seats">${e(v.seatsLeft > 0 ? gt(L, 'guest.page.placesLeft', { count: v.seatsLeft }) : gt(L, 'guest.page.soldOut'))}</span>`;
  const cta = v.kind === 'a' ? `<p>${e(gt(L, 'guest.page.attractionCta'))}</p>` : '';
  const body = `${v.imageUrl ? `<img class="hero" src="${e(v.imageUrl)}" alt="" />` : ''}
<h1>${e(v.title)}</h1>
${facts}
${seats}
${v.description ? `<p class="desc">${e(v.description)}</p>` : ''}
${cta}
${v.notice ? `<div class="card"><div class="notice">${e(v.notice)}</div>${appButtons(L, v.kind, v.id)}</div>` : ''}
${v.form ? formHtml(v, v.form) : ''}
${!v.notice ? appButtons(L, v.kind, v.id) : ''}`;
  return layout(L, v.title, body);
}

/** Generic page: missing / hidden / private listing (never says which). */
export function renderUnavailablePage(locale: AppLocale): string {
  const body = `<h1>${e(gt(locale, 'guest.page.unavailableTitle'))}</h1>
<p>${e(gt(locale, 'guest.page.unavailableBody'))}</p>
<a class="btn" href="${e(HOST)}">${e(gt(locale, 'guest.page.getApp'))}</a>`;
  return layout(locale, gt(locale, 'guest.page.unavailableTitle'), body);
}

/** A result / message page (registered, paid, pending, error ...). */
export function renderMessagePage(
  locale: AppLocale,
  title: string,
  message: string,
  opts: { backHref?: string | null; refreshSeconds?: number; error?: boolean } = {},
): string {
  const refresh = opts.refreshSeconds ? `\n<meta http-equiv="refresh" content="${Math.max(1, Math.floor(opts.refreshSeconds))}" />` : '';
  const body = `<h1>${e(title)}</h1>
${opts.error ? `<div class="error" role="alert">${e(message)}</div>` : `<p>${e(message)}</p>`}
${opts.backHref ? `<a class="btn secondary" href="${e(opts.backHref)}">${e(gt(locale, 'guest.done.back'))}</a>` : ''}
<a class="btn" href="${e(HOST)}">${e(gt(locale, 'guest.page.getApp'))}</a>`;
  return layout(locale, title, body, refresh);
}

/**
 * After a guest order was created: send the browser to the provider's hosted
 * checkout. A meta refresh (not a 303 from the POST) so a strict form-action
 * CSP never blocks the cross-origin hop, plus a button if refresh is off.
 * Only https URLs of the providers are ever passed in (see guestService).
 */
export function renderRedirectPage(locale: AppLocale, url: string): string {
  const head = `\n<meta http-equiv="refresh" content="0;url=${e(url)}" />`;
  const body = `<h1>${e(gt(locale, 'guest.done.redirectTitle'))}</h1>
<a class="btn" href="${e(url)}" rel="noreferrer">${e(gt(locale, 'guest.done.redirectButton'))}</a>`;
  return layout(locale, gt(locale, 'guest.done.redirectTitle'), body, head);
}

/** "Pay now" page of an accepted guest experience booking. */
export function renderPayPage(
  locale: AppLocale,
  v: { title: string; facts: Array<[string, string]>; action: string; sig: string; provider: string | null },
): string {
  const facts = v.facts.length ? `<dl>${v.facts.map(([k, val]) => `<dt>${e(k)}</dt><dd>${e(val)}</dd>`).join('')}</dl>` : '';
  const body = `<h1>${e(v.title)}</h1>
${facts}
<section class="card">
<h2>${e(gt(locale, 'guest.pay.title'))}</h2>
<p>${e(gt(locale, 'guest.pay.body'))}</p>
<form method="post" action="${e(v.action)}">
<input type="hidden" name="t" value="${e(v.sig)}" />
<input type="hidden" name="hl" value="${e(locale)}" />
<button class="btn" type="submit">${e(gt(locale, 'guest.form.submitPay'))}</button>
</form>
${v.provider ? `<p class="hint">${e(gt(locale, 'guest.form.secureNote', { provider: v.provider }))}</p>` : ''}
</section>`;
  return layout(locale, v.title, body);
}

/** The two choices on the shared-link landing (inserted by sharePreviewCore.renderHtml). */
export function landingChoicesHtml(locale: AppLocale, kind: GuestKind, id: string): string {
  const guestUrl = `${HOST}/guest/${kind}/${encodeURIComponent(id)}?hl=${encodeURIComponent(locale)}`;
  return `<a class="btn" id="store" href="${e(PLAY_URL)}">${e(gt(locale, 'guest.landing.openApp'))}</a>
  <a class="btn guest" id="guest" href="${e(guestUrl)}">${e(gt(locale, 'guest.landing.continueGuest'))}</a>
  <p class="hint">${e(gt(locale, 'guest.landing.guestHint'))}</p>`;
}
