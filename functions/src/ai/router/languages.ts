/**
 * Which languages each model supports (admin panel "Languages" column and
 * routing). Two sources, in order:
 *   1. provider.options.languages: explicit list set by an admin (enforced:
 *      the router skips the provider for any other language);
 *   2. MODEL_LANGUAGES below: what the vendor documents (informational).
 * null = not documented / any.
 */
import { ProviderConfig } from './types';

/** The app's 7 languages, shown as a coverage row for every model. */
export const APP_LANGUAGES = ['en', 'de', 'es', 'fr', 'it', 'pt', 'pt-BR'] as const;

const SEVEN = ['en', 'de', 'es', 'fr', 'it', 'pt', 'pt-BR'];

export interface ModelLanguages {
  languages: string[] | null;
  note: string;
}

/** Vendor-documented support (checked 2026-10-23). Keys = model id or provider type. */
export const MODEL_LANGUAGES: Record<string, ModelLanguages> = {
  'qwen-mt-flash': { languages: SEVEN, note: '92 languages; Portuguese only (pt-BR via the Brazilian hint).' },
  'qwen-mt-plus': { languages: SEVEN, note: '92 languages; Portuguese only (pt-BR via the Brazilian hint).' },
  'qwen-mt-lite': { languages: SEVEN, note: '31 languages incl. all 7 app languages.' },
  'qwen-flash': { languages: SEVEN, note: 'General multilingual model (100+ languages).' },
  'qwen-plus': { languages: SEVEN, note: 'General multilingual model (100+ languages).' },
  'qwen-max': { languages: SEVEN, note: 'General multilingual model (100+ languages).' },
  'qwen-flash-character': { languages: SEVEN, note: 'Role-play model; multilingual. Translation: use the Plus model (more reliable).' },
  'qwen-plus-character': { languages: SEVEN, note: 'Role-play model; multilingual; translated DE/FR/ES/ZH correctly in tests.' },
  'qwen3-tts-flash': { languages: ['en', 'de', 'es', 'fr', 'it', 'pt', 'pt-BR'], note: 'Chinese, English, German, Italian, Portuguese, Spanish, Japanese, Korean, French, Russian.' },
  'qwen-audio-3.1-tts-flash': { languages: ['en', 'de', 'es', 'fr', 'it', 'pt', 'pt-BR'], note: 'Multilingual voices (zh, ja, ko, fr, de, pt, it, vi, id); English voices; Spanish works on the multilingual voices (not in the vendor list).' },
  'qwen-audio-3.1-tts-plus': { languages: ['en', 'de', 'fr', 'it', 'pt', 'pt-BR'], note: 'Same voice families as 3.1 Flash; Spanish not tested.' },
  'gemini-2.0-flash': { languages: SEVEN, note: 'Multilingual.' },
  'gemini-flash-latest': { languages: SEVEN, note: 'Multilingual.' },
  google_translate_v2: { languages: SEVEN, note: '100+ languages, incl. pt-BR and pt-PT.' },
  google_free: { languages: SEVEN, note: '100+ languages, incl. pt-BR and pt-PT.' },
  google_tts: { languages: SEVEN, note: 'Chirp 3 HD voices; pt-PT falls back to the default voice / pt-BR.' },
  mock: { languages: SEVEN, note: 'Test only: canned answers in any language.' },
};

const norm = (c: string) => {
  const [a, b] = c.trim().replace(/_/g, '-').split('-');
  return b ? `${a.toLowerCase()}-${b.toUpperCase()}` : a.toLowerCase();
};

/** Explicit admin list (enforced), or null. */
export function explicitLanguages(p: ProviderConfig): string[] | null {
  const l = (p.options as any)?.languages;
  return Array.isArray(l) && l.length ? l.map((x: unknown) => norm(String(x))) : null;
}

/** What to show for a provider: explicit list, else vendor info by model, else by type. */
export function providerLanguages(p: ProviderConfig): ModelLanguages {
  const explicit = explicitLanguages(p);
  if (explicit) return { languages: explicit, note: 'Set by an admin (enforced).' };
  return MODEL_LANGUAGES[p.model ?? ''] ?? MODEL_LANGUAGES[p.type] ?? { languages: null, note: 'Not documented: assume any language; test it.' };
}

/**
 * False only when an admin listed languages for the provider and [language]
 * is not one of them ("pt-BR" matches "pt-BR" or "pt"; "pt" matches "pt").
 */
export function supportsLanguage(p: ProviderConfig, language: string | undefined): boolean {
  if (!language) return true;
  const list = explicitLanguages(p);
  if (!list) return true;
  const l = norm(language);
  return list.includes(l) || list.includes(l.split('-')[0]);
}
