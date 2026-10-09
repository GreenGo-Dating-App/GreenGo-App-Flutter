/**
 * The app's UI languages, mirrored from lib/l10n/app_*.arb and
 * LanguageProvider.supportedLocales on the client.
 */
export const SUPPORTED_LOCALES = ['en', 'de', 'es', 'fr', 'it', 'pt', 'pt_BR'] as const;

export type AppLocale = (typeof SUPPORTED_LOCALES)[number];

export const DEFAULT_LOCALE: AppLocale = 'en';

const SUPPORTED = new Set<string>(SUPPORTED_LOCALES);

/**
 * Map any locale-ish value ("pt_BR", "pt-br", "it_IT", "de", "EN-us", null) to
 * one of [SUPPORTED_LOCALES]. Brazilian Portuguese is the only region kept;
 * every other region collapses to its language; anything unknown is English.
 */
export function normalizeLocale(raw: unknown): AppLocale {
  if (typeof raw !== 'string') return DEFAULT_LOCALE;
  const v = raw.trim().replace(/-/g, '_');
  if (!v) return DEFAULT_LOCALE;
  const [lang, region] = v.split('_');
  const base = (lang || '').toLowerCase();
  if (base === 'pt' && (region || '').toUpperCase() === 'BR') return 'pt_BR';
  return SUPPORTED.has(base) ? (base as AppLocale) : DEFAULT_LOCALE;
}
