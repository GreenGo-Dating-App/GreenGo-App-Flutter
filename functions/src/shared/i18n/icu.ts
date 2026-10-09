/**
 * Minimal ICU MessageFormat subset - the same subset Flutter's gen-l10n
 * accepts in the ARB files, so one string works on both sides:
 *
 *   {name}                                   plain substitution
 *   {count, plural, =0{..} one{..} other{..}} plural (=N exact, CLDR categories)
 *   {kind, select, a{..} b{..} other{..}}     select
 *
 * Branches may nest and reference any param ({count} inside a plural branch).
 * Apostrophes are literal (gen-l10n's default, `use-escaping: false`).
 * A missing param renders as an empty string; malformed patterns render as-is
 * rather than throwing, so a bad translation can never break a send.
 */
import type { AppLocale } from './locales';

export type I18nParamValue = string | number;
export type I18nParams = Record<string, I18nParamValue>;

const pluralRulesCache = new Map<string, Intl.PluralRules>();

function pluralCategory(locale: AppLocale, n: number): string {
  const tag = locale.replace('_', '-');
  let rules = pluralRulesCache.get(tag);
  if (!rules) {
    try {
      rules = new Intl.PluralRules(tag);
    } catch {
      rules = new Intl.PluralRules('en');
    }
    pluralRulesCache.set(tag, rules);
  }
  return rules.select(n);
}

/** Index of the `}` matching the `{` at [open], or -1. */
function matchBrace(s: string, open: number): number {
  let depth = 0;
  for (let i = open; i < s.length; i++) {
    const c = s[i];
    if (c === '{') depth++;
    else if (c === '}') {
      depth--;
      if (depth === 0) return i;
    }
  }
  return -1;
}

/** Parse `key{...} key{...}` branch lists of plural/select. */
function parseBranches(s: string): Map<string, string> | null {
  const out = new Map<string, string>();
  let i = 0;
  while (i < s.length) {
    while (i < s.length && /\s/.test(s[i])) i++;
    if (i >= s.length) break;
    const start = i;
    while (i < s.length && s[i] !== '{' && !/\s/.test(s[i])) i++;
    const key = s.slice(start, i);
    while (i < s.length && /\s/.test(s[i])) i++;
    if (s[i] !== '{' || !key) return null;
    const close = matchBrace(s, i);
    if (close < 0) return null;
    out.set(key, s.slice(i + 1, close));
    i = close + 1;
  }
  return out;
}

function renderArgument(
  inner: string,
  params: I18nParams,
  locale: AppLocale,
): string | null {
  const firstComma = inner.indexOf(',');
  if (firstComma < 0) {
    const name = inner.trim();
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(name)) return null;
    const v = params[name];
    return v === undefined || v === null ? '' : String(v);
  }
  const name = inner.slice(0, firstComma).trim();
  const rest = inner.slice(firstComma + 1);
  const secondComma = rest.indexOf(',');
  if (secondComma < 0) return null;
  const kind = rest.slice(0, secondComma).trim();
  const branches = parseBranches(rest.slice(secondComma + 1));
  if (!branches) return null;
  const value = params[name];

  let chosen: string | undefined;
  if (kind === 'plural') {
    const n = typeof value === 'number' ? value : Number(value);
    if (Number.isFinite(n)) {
      chosen = branches.get(`=${n}`) ?? branches.get(pluralCategory(locale, n));
    }
  } else if (kind === 'select') {
    chosen = branches.get(String(value ?? ''));
  } else {
    return null;
  }
  if (chosen === undefined) chosen = branches.get('other') ?? '';
  return formatMessage(chosen, params, locale);
}

/** Render [pattern] with [params] for [locale]. Never throws. */
export function formatMessage(
  pattern: string,
  params: I18nParams = {},
  locale: AppLocale = 'en',
): string {
  if (!pattern || pattern.indexOf('{') < 0) return pattern || '';
  let out = '';
  let i = 0;
  while (i < pattern.length) {
    const open = pattern.indexOf('{', i);
    if (open < 0) {
      out += pattern.slice(i);
      break;
    }
    out += pattern.slice(i, open);
    const close = matchBrace(pattern, open);
    if (close < 0) {
      out += pattern.slice(open);
      break;
    }
    const rendered = renderArgument(pattern.slice(open + 1, close), params, locale);
    out += rendered === null ? pattern.slice(open, close + 1) : rendered;
    i = close + 1;
  }
  return out;
}
