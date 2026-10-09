/**
 * Copyright notice-and-takedown: data model, constants and pure validation.
 *
 * Mechanics implemented (not legal advice):
 *   - US DMCA 17 U.S.C. §512(c)(3) notice elements, §512(g)(2)-(3) counter-
 *     notice + restoration after 10-14 business days unless the complainant
 *     reports a court action, §512(i) repeat-infringer policy.
 *   - EU DSA art. 16 (notice and action), art. 17 statement of reasons and
 *     art. 20 appeal (reuses moderation_decisions + submitAppeal).
 *   - Brazil Lei 9.610/1998: same process for every jurisdiction.
 *
 * Collections (all server-written; see firestore.rules):
 *   copyright_notices/{id}                 the notice + its lifecycle
 *   copyright_notices/{id}/private/contact complainant phone + address, web
 *                                          confirmation token hash (server-only)
 *   copyright_notices/{id}/audit/{autoId}  every step (server-only)
 *   copyright_counter_notices/{noticeId}   one counter-notice per notice
 *   copyright_strikes/{noticeId}           one strike per accepted notice
 *   copyright_rate_limits/{key}            submission throttling (server-only)
 *
 * Status machine of a notice:
 *   unverified (web, email not confirmed) -> pending -> accepted | rejected
 *   accepted -> counter_noticed -> restored | lawsuit_filed
 */
import { HttpsError } from 'firebase-functions/v2/https';
import { isEmail } from '../emails/sendEmail';

export const NOTICES = 'copyright_notices';
export const COUNTER_NOTICES = 'copyright_counter_notices';
export const STRIKES = 'copyright_strikes';
export const RATE_LIMITS = 'copyright_rate_limits';

export const NOTICE_STATUSES = [
  'unverified', 'pending', 'accepted', 'rejected', 'counter_noticed', 'restored', 'lawsuit_filed',
] as const;
export type NoticeStatus = typeof NOTICE_STATUSES[number];

/** Statuses the uploader can see (after an admin acted on the notice). */
export const UPLOADER_VISIBLE: ReadonlySet<string> = new Set(['accepted', 'counter_noticed', 'restored', 'lawsuit_filed']);

export const CONTENT_TYPES = ['message', 'event', 'experience', 'profilePhoto'] as const;
export type ContentType = typeof CONTENT_TYPES[number];

/** Designated agent (owner fills the postal address; see the owner guide). */
export const AGENT = {
  name: 'Universo Kardasha Ltda.',
  email: 'copyright@greengochat.com',
  postalAddress: process.env.COPYRIGHT_AGENT_ADDRESS || '[postal address to be filled by owner]',
};

export const STRIKE_LIMIT = 3;
export const STRIKE_TTL_MS = 365 * 86_400_000;
/** §512(g)(2)(C): restore not less than 10, nor more than 14, business days after the counter-notice. */
export const RESTORE_BUSINESS_DAYS = 10;
export const CONFIRM_TTL_MS = 48 * 3_600_000;
/** Unconfirmed web notices are purged by processCopyrightNotices after `expireAt`. */
export const UNVERIFIED_TTL_MS = 7 * 86_400_000;

export const DEFAULT_ADMIN_RECIPIENT = 'greengochat.com@gmail.com';
export const DEFAULT_PANEL_URL = 'https://greengo-chat-admin.web.app';
export const DEFAULT_PUBLIC_FORM_URL = 'https://greengo-chat.web.app/copyright-notice';

export function adminRecipients(env: string | undefined = process.env.ADMIN_COPYRIGHT_EMAILS): string[] {
  const list = (env && env.trim() ? env : DEFAULT_ADMIN_RECIPIENT)
    .split(/[,;\s]+/).map((s) => s.trim()).filter(isEmail);
  return list.length ? [...new Set(list)] : [DEFAULT_ADMIN_RECIPIENT];
}

export function panelLink(noticeId: string, base: string | undefined = process.env.ADMIN_PANEL_URL): string {
  const root = (base && /^https:\/\//.test(base.trim()) ? base.trim() : DEFAULT_PANEL_URL).replace(/\/+$/, '');
  return `${root}/copyright?notice=${encodeURIComponent(noticeId)}`;
}

export function publicFormUrl(base: string | undefined = process.env.COPYRIGHT_PUBLIC_FORM_URL): string {
  return (base && /^https:\/\//.test(base.trim()) ? base.trim() : DEFAULT_PUBLIC_FORM_URL).replace(/\/+$/, '');
}

/** Short human reference shown in emails ("CN-1A2B3C4D"). */
export function noticeRef(noticeId: string): string {
  return `CN-${noticeId.replace(/[^A-Za-z0-9]/g, '').slice(0, 8).toUpperCase()}`;
}

// ───────────────────────────────────────────────────────────── business days

/**
 * [ms] plus [days] business days (Mon-Fri, UTC). Weekend start counts from
 * the next Monday. Federal holidays are not excluded: the scheduler runs
 * every few hours, so restoration lands inside the 10-14 day window anyway.
 */
export function addBusinessDays(ms: number, days: number): number {
  const d = new Date(ms);
  let left = days;
  while (left > 0) {
    d.setUTCDate(d.getUTCDate() + 1);
    const wd = d.getUTCDay();
    if (wd !== 0 && wd !== 6) left--;
  }
  return d.getTime();
}

// ───────────────────────────────────────────────────────────── validation

export type Fail = (field: string) => never;

const failInvalid: Fail = (field: string) => {
  throw new HttpsError('invalid-argument', `invalid_${field}`, { field });
};

function text(v: unknown, field: string, min: number, max: number, fail: Fail, optional = false): string | null {
  if (v === undefined || v === null || (optional && typeof v === 'string' && v.trim() === '')) {
    if (optional) return null;
    fail(field);
  }
  if (typeof v !== 'string') fail(field);
  // Strip control characters except newlines/tabs.
  // eslint-disable-next-line no-control-regex
  const s = (v as string).replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, '').trim();
  if (s.length < min || s.length > max) fail(field);
  return s;
}

function httpUrl(v: unknown, field: string, fail: Fail): string | null {
  const s = text(v, field, 1, 1000, fail, true);
  if (s === null) return null;
  if (!/^https?:\/\/[^\s]+$/i.test(s)) fail(field);
  return s;
}

/** "/s/ Jane Doe" -> "jane doe" (typed electronic signature compare). */
export function normalizeSignature(s: string): string {
  return s.replace(/^\s*\/s\/\s*/i, '').normalize('NFKC').toLowerCase().replace(/\s+/g, ' ').trim();
}

const MESSAGE_PATH = /^(conversations|groups|communities|events)\/[A-Za-z0-9_-]{1,128}\/messages\/[A-Za-z0-9_-]{1,128}$/;
const PATHS: Record<ContentType, RegExp> = {
  message: MESSAGE_PATH,
  event: /^events\/[A-Za-z0-9_-]{1,128}$/,
  experience: /^user_experiences\/[A-Za-z0-9_-]{1,128}$/,
  profilePhoto: /^profiles\/[A-Za-z0-9_-]{1,128}$/,
};

export interface ContentTarget {
  type: ContentType;
  path: string;
  photoUrl: string | null;
}

/** Validates a structured content target (app prefill or admin override). */
export function parseTarget(v: unknown, fail: Fail = failInvalid): ContentTarget | null {
  if (v === undefined || v === null) return null;
  if (typeof v !== 'object') fail('content');
  const o = v as Record<string, unknown>;
  if (o.type === undefined && o.path === undefined) return null;
  if (typeof o.type !== 'string' || !(CONTENT_TYPES as readonly string[]).includes(o.type)) fail('content_type');
  const type = o.type as ContentType;
  if (typeof o.path !== 'string' || !PATHS[type].test(o.path)) fail('content_path');
  let photoUrl: string | null = null;
  if (type === 'profilePhoto') {
    if (typeof o.photoUrl !== 'string' || !/^https:\/\/[^\s]{1,1500}$/.test(o.photoUrl)) fail('content_photoUrl');
    photoUrl = o.photoUrl as string;
  }
  return { type, path: o.path as string, photoUrl };
}

export interface NoticeInput {
  complainant: { name: string; email: string; organization: string | null; relationship: 'owner' | 'agent' };
  contact: { phone: string; address: string };
  work: { description: string; url: string | null };
  content: { location: string; details: string | null; target: ContentTarget | null; label: string | null };
  statements: { goodFaith: true; accuracy: true; authority: true };
  signature: string;
}

/**
 * §512(c)(3)(A) elements: (i) signature, (ii) the work, (iii) the material +
 * where it is, (iv) contact (address, phone, email), (v) good faith, (vi)
 * accuracy + authority under penalty of perjury.
 */
export function parseNotice(data: any, fail: Fail = failInvalid): NoticeInput {
  const c = data?.complainant ?? {};
  const name = text(c.name, 'name', 2, 200, fail)!;
  const email = text(c.email, 'email', 3, 254, fail)!;
  if (!isEmail(email)) fail('email');
  const organization = text(c.organization, 'organization', 1, 200, fail, true);
  const relationship = c.relationship === 'agent' ? 'agent' : c.relationship === 'owner' ? 'owner' : fail('relationship');
  const phone = text(c.phone, 'phone', 5, 40, fail)!;
  if (!/^[0-9+().\-\s/x]+$/i.test(phone)) fail('phone');
  const address = text(c.address, 'address', 5, 500, fail)!;

  const w = data?.work ?? {};
  const description = text(w.description, 'work', 10, 2000, fail)!;
  const url = httpUrl(w.url, 'work_url', fail);

  const ct = data?.content ?? {};
  const target = parseTarget(ct.target, fail);
  const location = text(ct.location ?? target?.path, 'location', 1, 1000, fail)!;
  const details = text(ct.details, 'details', 3, 2000, fail, true);
  const label = text(ct.label, 'label', 1, 100, fail, true);

  const st = data?.statements ?? {};
  if (st.goodFaith !== true) fail('goodFaith');
  if (st.accuracy !== true) fail('accuracy');
  if (st.authority !== true) fail('authority');

  const signature = text(data?.signature, 'signature', 2, 200, fail)!;
  if (normalizeSignature(signature) !== normalizeSignature(name)) fail('signature');

  return {
    complainant: { name, email: email.toLowerCase(), organization, relationship },
    contact: { phone, address },
    work: { description, url },
    content: { location, details, target, label },
    statements: { goodFaith: true, accuracy: true, authority: true },
    signature,
  };
}

export interface CounterInput {
  noticeId: string;
  name: string;
  email: string;
  phone: string;
  address: string;
  explanation: string;
  statements: { perjury: true; jurisdiction: true };
  signature: string;
}

/** §512(g)(3): signature, material + location, perjury statement, name/address/phone + jurisdiction consent. */
export function parseCounterNotice(data: any, fail: Fail = failInvalid): CounterInput {
  const noticeId = text(data?.noticeId, 'noticeId', 1, 128, fail)!;
  if (noticeId.includes('/')) fail('noticeId');
  const name = text(data?.name, 'name', 2, 200, fail)!;
  const email = text(data?.email, 'email', 3, 254, fail)!;
  if (!isEmail(email)) fail('email');
  const phone = text(data?.phone, 'phone', 5, 40, fail)!;
  if (!/^[0-9+().\-\s/x]+$/i.test(phone)) fail('phone');
  const address = text(data?.address, 'address', 5, 500, fail)!;
  const explanation = text(data?.explanation, 'explanation', 10, 2000, fail)!;
  const st = data?.statements ?? {};
  if (st.perjury !== true) fail('perjury');
  if (st.jurisdiction !== true) fail('jurisdiction');
  const signature = text(data?.signature, 'signature', 2, 200, fail)!;
  if (normalizeSignature(signature) !== normalizeSignature(name)) fail('signature');
  return {
    noticeId, name, email: email.toLowerCase(), phone, address, explanation,
    statements: { perjury: true, jurisdiction: true }, signature,
  };
}

/**
 * Best-effort content target from a GreenGo link the complainant pasted
 * (web form): /e/{eventId} -> event. Anything else is resolved by the admin.
 */
export function targetFromLocation(location: string): ContentTarget | null {
  const m = /^https?:\/\/(?:[a-z0-9-]+\.)*(?:greengo-chat\.web\.app|greengochat\.com|greengo-chat\.firebaseapp\.com)\/e\/([A-Za-z0-9_-]{1,128})(?:[/?#].*)?$/i.exec(location.trim());
  if (m) return { type: 'event', path: `events/${m[1]}`, photoUrl: null };
  return null;
}
