/**
 * Free Google translate endpoint (no API key, no billing):
 *
 *   GET  https://translate.googleapis.com/translate_a/single
 *          ?client=gtx&sl=<source|auto>&tl=<target>&dt=t&q=<text>
 *   POST same URL without `q`, body `q=<text>` (form-encoded) for long texts.
 *
 * Response: [[["<translated>","<original>",...], ...one per sentence...],
 *            null, "<detected source>", ...]
 *
 * Used for EVERY translation (chat callables and the shared public-content
 * store) so nothing depends on the paid Cloud Translation API. The endpoint
 * rate-limits bursts (HTTP 429), so calls are retried with backoff and run
 * with limited concurrency; on a persistent 429/5xx callers get what was
 * translated so far and the app falls back to translating on the device.
 */

export const FREE_ENDPOINT = 'https://translate.googleapis.com/translate_a/single';

/** Above this length the text goes in a POST body (long URLs are rejected). */
const POST_THRESHOLD = 1200;

export interface FreeTranslation {
  /** The translation; the original text when it already is in the target language. */
  text: string;
  /** Source language reported by the endpoint, if any. */
  detectedLanguage: string | null;
  /** True when the source already was the target language. */
  sameLanguage: boolean;
}

export class FreeTranslateError extends Error {
  constructor(
    message: string,
    readonly status?: number,
    /** 429 / 5xx / network: the endpoint may answer later. */
    readonly transient = true,
  ) {
    super(message);
    this.name = 'FreeTranslateError';
  }
}

export interface FreeTranslateOptions {
  source?: string;
  fetchImpl?: typeof fetch;
  timeoutMs?: number;
  /** Total attempts including the first (default 3). */
  attempts?: number;
  /** Delay before retry n (0-based). */
  backoffMs?: (retry: number) => number;
}

/** `pt` vs `pt-BR`, `zh-CN` vs `zh` -> same base language. */
export function sameBaseLanguage(a: string, b: string): boolean {
  const base = (s: string) => s.trim().toLowerCase().replace(/_/g, '-').split('-')[0];
  const x = base(a);
  return x.length > 0 && x === base(b);
}

/** `pt_BR` -> `pt-BR`, `EN` -> `en`. The endpoint silently ignores unknown codes. */
export function normalizeTarget(lang: string): string {
  const m = /^([a-zA-Z]{2,3})(?:[-_]([a-zA-Z]{2}))?$/.exec(lang.trim());
  if (!m) return lang.trim();
  return m[2] ? `${m[1].toLowerCase()}-${m[2].toUpperCase()}` : m[1].toLowerCase();
}

/**
 * Parses a free-endpoint body. Sentences are concatenated in order; when the
 * detected language is the target the original is returned unchanged.
 * Returns null when the body is not in the expected shape.
 */
export function parseFreeResponse(
  body: string,
  original: string,
  target: string,
): FreeTranslation | null {
  let decoded: unknown;
  try {
    decoded = JSON.parse(body);
  } catch {
    return null;
  }
  if (!Array.isArray(decoded) || decoded.length === 0) return null;
  const detected = typeof decoded[2] === 'string' ? (decoded[2] as string) : null;
  const sentences = decoded[0];
  if (sentences !== null && !Array.isArray(sentences)) return null;
  let text = '';
  for (const part of (sentences as unknown[]) ?? []) {
    if (Array.isArray(part) && typeof part[0] === 'string') text += part[0];
  }
  const sameLanguage = detected !== null && sameBaseLanguage(detected, target);
  if (sameLanguage || text.trim().length === 0) {
    return { text: original, detectedLanguage: detected, sameLanguage };
  }
  return { text, detectedLanguage: detected, sameLanguage: false };
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
const defaultBackoff = (retry: number) => 400 * 2 ** retry + Math.floor(Math.random() * 200);

/** Translates one text. Throws [FreeTranslateError] after the last attempt. */
export async function freeTranslate(
  text: string,
  target: string,
  opts: FreeTranslateOptions = {},
): Promise<FreeTranslation> {
  const tl = normalizeTarget(target);
  const sl = opts.source ? normalizeTarget(opts.source) : 'auto';
  if (text.trim().length === 0) return { text, detectedLanguage: null, sameLanguage: true };
  if (sl !== 'auto' && sameBaseLanguage(sl, tl)) {
    return { text, detectedLanguage: sl, sameLanguage: true };
  }

  const doFetch = opts.fetchImpl ?? fetch;
  const attempts = Math.max(1, opts.attempts ?? 3);
  const backoff = opts.backoffMs ?? defaultBackoff;
  const query = `client=gtx&sl=${encodeURIComponent(sl)}&tl=${encodeURIComponent(tl)}&dt=t`;
  let last: FreeTranslateError = new FreeTranslateError('not attempted');

  for (let attempt = 0; attempt < attempts; attempt++) {
    if (attempt > 0) await sleep(backoff(attempt - 1));
    try {
      const long = text.length > POST_THRESHOLD;
      const res = await doFetch(
        long ? `${FREE_ENDPOINT}?${query}` : `${FREE_ENDPOINT}?${query}&q=${encodeURIComponent(text)}`,
        {
          method: long ? 'POST' : 'GET',
          headers: long ? { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8' } : undefined,
          body: long ? new URLSearchParams({ q: text }).toString() : undefined,
          signal: AbortSignal.timeout(opts.timeoutMs ?? 8000),
        },
      );
      if (res.ok) {
        const parsed = parseFreeResponse(await res.text(), text, tl);
        if (parsed) return parsed;
        // A malformed 200 will not improve with retries.
        throw new FreeTranslateError('Unreadable translate response', res.status, false);
      }
      const transient = res.status === 429 || res.status >= 500;
      last = new FreeTranslateError(`Translate HTTP ${res.status}`, res.status, transient);
      if (!transient) throw last;
    } catch (e) {
      if (e instanceof FreeTranslateError && !e.transient) throw e;
      last = e instanceof FreeTranslateError
        ? e
        : new FreeTranslateError(`Translate request failed: ${(e as Error)?.message ?? e}`);
    }
  }
  throw last;
}

/**
 * Translates [texts] (same order) with at most [concurrency] requests in
 * flight. A text that could not be translated comes back as null. After a
 * rate limit (429) that survived its retries, or once [deadlineMs] has
 * passed, the remaining texts are not attempted (null) so the caller returns
 * quickly and clients fall back.
 */
export async function freeTranslateMany(
  texts: string[],
  target: string,
  opts: FreeTranslateOptions & { concurrency?: number; deadlineMs?: number } = {},
): Promise<(FreeTranslation | null)[]> {
  const out: (FreeTranslation | null)[] = texts.map(() => null);
  let next = 0;
  let rateLimited = false;
  const stopAt = opts.deadlineMs ? Date.now() + opts.deadlineMs : Infinity;
  const worker = async () => {
    while (!rateLimited && Date.now() < stopAt) {
      const i = next++;
      if (i >= texts.length) return;
      try {
        out[i] = await freeTranslate(texts[i], target, opts);
      } catch (e) {
        if (e instanceof FreeTranslateError && e.status === 429) rateLimited = true;
        console.warn(`freeTranslate failed: ${(e as Error).message}`);
      }
    }
  };
  const n = Math.max(1, Math.min(opts.concurrency ?? 4, texts.length));
  await Promise.all(Array.from({ length: n }, worker));
  return out;
}

/** Languages the app offers (the free endpoint supports these and more). */
export const SUPPORTED_LANGUAGES: { code: string; name: string }[] = [
  { code: 'en', name: 'English' },
  { code: 'it', name: 'Italian' },
  { code: 'es', name: 'Spanish' },
  { code: 'fr', name: 'French' },
  { code: 'de', name: 'German' },
  { code: 'pt', name: 'Portuguese' },
  { code: 'pt-BR', name: 'Portuguese (Brazil)' },
  { code: 'nl', name: 'Dutch' },
  { code: 'ru', name: 'Russian' },
  { code: 'zh-CN', name: 'Chinese (Simplified)' },
  { code: 'ja', name: 'Japanese' },
  { code: 'ko', name: 'Korean' },
  { code: 'ar', name: 'Arabic' },
  { code: 'hi', name: 'Hindi' },
  { code: 'tr', name: 'Turkish' },
  { code: 'pl', name: 'Polish' },
  { code: 'sv', name: 'Swedish' },
  { code: 'el', name: 'Greek' },
  { code: 'he', name: 'Hebrew' },
  { code: 'th', name: 'Thai' },
  { code: 'vi', name: 'Vietnamese' },
  { code: 'id', name: 'Indonesian' },
  { code: 'cs', name: 'Czech' },
  { code: 'ro', name: 'Romanian' },
];

/**
 * Drop-in for the subset of `TranslationServiceClient.translateText` that
 * legacy code used (`contents` + `targetLanguageCode`), backed by the free
 * endpoint. A text that could not be translated yields `translatedText: ''`.
 */
export const freeTranslationClient = {
  async translateText(req: {
    contents: string[];
    targetLanguageCode: string;
    sourceLanguageCode?: string;
    [k: string]: unknown;
  }): Promise<[{ translations: { translatedText: string; detectedLanguageCode: string | null }[] }]> {
    const out = await freeTranslateMany(req.contents, req.targetLanguageCode, {
      source: req.sourceLanguageCode,
    });
    return [{
      translations: out.map((t) => ({
        translatedText: t?.text ?? '',
        detectedLanguageCode: t?.detectedLanguage ?? null,
      })),
    }];
  },
};
