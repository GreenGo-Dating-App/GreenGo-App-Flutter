/**
 * Server-side i18n for every text a Cloud Function writes for a user to read
 * (notification docs, FCM pushes, system messages, email subjects).
 *
 * - Catalog: ARB-backed keys (catalog.generated.ts, generated from
 *   lib/l10n/app_*.arb by scripts/gen-i18n-catalog.cjs, so the server and the
 *   app use the same words) + server-only email subjects (emailSubjects.ts).
 * - t(locale, key, params): ICU-like {param} / plural / select formatting,
 *   falling back to English for an unknown locale or a missing translation.
 * - Notification docs store `titleKey` / `bodyKey` + `params` so the app
 *   renders them in the VIEWER's language, plus English `title` / `message` /
 *   `body` for app versions that predate the keys. Pushes are rendered
 *   server-side in the RECIPIENT's language (see recipientLocale.ts).
 */
import { ARB_CATALOG, ArbKey } from './catalog.generated';
import { EMAIL_SUBJECTS, EmailSubjectKey } from './emailSubjects';
import { formatMessage, I18nParams, I18nParamValue } from './icu';
import { AppLocale, DEFAULT_LOCALE, normalizeLocale } from './locales';

export { AppLocale, SUPPORTED_LOCALES, DEFAULT_LOCALE, normalizeLocale } from './locales';
export { I18nParams, I18nParamValue, formatMessage } from './icu';
export type { ArbKey } from './catalog.generated';
export type { EmailSubjectKey } from './emailSubjects';

export type I18nKey = ArbKey | EmailSubjectKey;

function lookup(locale: AppLocale, key: string): string | undefined {
  const arb = (ARB_CATALOG[locale] as Record<string, string>)[key];
  if (arb !== undefined) return arb;
  return (EMAIL_SUBJECTS[locale] as Record<string, string>)[key];
}

/** True when [key] exists in the server catalog. */
export function hasKey(key: string): key is I18nKey {
  return lookup(DEFAULT_LOCALE, key) !== undefined;
}

/**
 * Translate [key] into [locale] (any locale-ish string; normalized). Falls
 * back to English when the locale or the translation is missing, and to the
 * key itself when the key is unknown (never throws, never returns empty for a
 * real key).
 */
export function t(locale: unknown, key: I18nKey, params: I18nParams = {}): string {
  const loc = normalizeLocale(locale);
  const own = lookup(loc, key);
  if (own !== undefined && own !== '') return formatMessage(own, params, loc);
  const en = lookup(DEFAULT_LOCALE, key);
  if (en !== undefined) return formatMessage(en, params, DEFAULT_LOCALE);
  return key;
}

// ---------------------------------------------------------------------------
// Localizable text values
// ---------------------------------------------------------------------------

/** A catalog text (key + params) or verbatim user content (an event title). */
export type LText =
  | { key: I18nKey; params?: I18nParams }
  | { raw: string };

/** Catalog text. */
export function lt(key: I18nKey, params?: I18nParams): LText {
  return params ? { key, params } : { key };
}

/** Verbatim text (user-generated content: names, titles, messages). */
export function rawText(text: string): LText {
  return { raw: text };
}

export function isKeyed(v: LText | undefined): v is { key: I18nKey; params?: I18nParams } {
  return !!v && typeof (v as { key?: unknown }).key === 'string';
}

/** Render [text] for [locale]. Plain strings pass through unchanged. */
export function render(locale: unknown, text: LText | string | undefined | null): string {
  if (text === undefined || text === null) return '';
  if (typeof text === 'string') return text;
  if (isKeyed(text)) return t(locale, text.key, text.params);
  return (text as { raw: string }).raw ?? '';
}

/** Merge the params of several texts into the single map stored on a doc. */
export function mergeParams(...texts: Array<LText | string | undefined | null>): I18nParams {
  const out: I18nParams = {};
  for (const x of texts) {
    if (x && typeof x !== 'string' && isKeyed(x) && x.params) {
      for (const [k, v] of Object.entries(x.params)) {
        if (v !== undefined && v !== null) out[k] = v as I18nParamValue;
      }
    }
  }
  return out;
}

/**
 * The text fields of a `notifications` doc: English `title` / `message` /
 * `body` (what app versions without key support show) plus `titleKey` /
 * `bodyKey` / `params` for the localized rendering. Raw (user-content) parts
 * get no key, so the app shows them verbatim.
 */
export function notifTextFields(
  title: LText | string,
  body: LText | string,
): Record<string, unknown> {
  const enTitle = render(DEFAULT_LOCALE, title);
  const enBody = render(DEFAULT_LOCALE, body);
  const out: Record<string, unknown> = { title: enTitle, message: enBody, body: enBody };
  if (typeof title !== 'string' && isKeyed(title)) out.titleKey = title.key;
  if (typeof body !== 'string' && isKeyed(body)) out.bodyKey = body.key;
  const params = mergeParams(title, body);
  if (out.titleKey || out.bodyKey) {
    if (Object.keys(params).length > 0) out.params = params;
  }
  return out;
}

/**
 * Re-render a STORED notification doc's text in [locale] (used by the push
 * parity trigger). Falls back to the stored strings for parts without a key
 * or with a key this server version doesn't know.
 */
export function renderStoredText(
  locale: unknown,
  doc: Record<string, unknown>,
): { title: string; body: string } {
  const params = (doc.params && typeof doc.params === 'object'
    ? (doc.params as I18nParams)
    : {});
  const storedTitle = typeof doc.title === 'string' ? doc.title : '';
  const storedBody =
    (typeof doc.message === 'string' && doc.message) ||
    (typeof doc.body === 'string' ? doc.body : '');
  const titleKey = typeof doc.titleKey === 'string' ? doc.titleKey : '';
  const bodyKey = typeof doc.bodyKey === 'string' ? doc.bodyKey : '';
  return {
    title: titleKey && hasKey(titleKey) ? t(locale, titleKey, params) : storedTitle,
    body: bodyKey && hasKey(bodyKey) ? t(locale, bodyKey, params) : storedBody,
  };
}
