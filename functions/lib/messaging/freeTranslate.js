"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.freeTranslationClient = exports.SUPPORTED_LANGUAGES = exports.FreeTranslateError = exports.FREE_ENDPOINT = void 0;
exports.sameBaseLanguage = sameBaseLanguage;
exports.normalizeTarget = normalizeTarget;
exports.parseFreeResponse = parseFreeResponse;
exports.freeTranslate = freeTranslate;
exports.freeTranslateMany = freeTranslateMany;
exports.FREE_ENDPOINT = 'https://translate.googleapis.com/translate_a/single';
/** Above this length the text goes in a POST body (long URLs are rejected). */
const POST_THRESHOLD = 1200;
class FreeTranslateError extends Error {
    constructor(message, status, 
    /** 429 / 5xx / network: the endpoint may answer later. */
    transient = true) {
        super(message);
        this.status = status;
        this.transient = transient;
        this.name = 'FreeTranslateError';
    }
}
exports.FreeTranslateError = FreeTranslateError;
/** `pt` vs `pt-BR`, `zh-CN` vs `zh` -> same base language. */
function sameBaseLanguage(a, b) {
    const base = (s) => s.trim().toLowerCase().replace(/_/g, '-').split('-')[0];
    const x = base(a);
    return x.length > 0 && x === base(b);
}
/** `pt_BR` -> `pt-BR`, `EN` -> `en`. The endpoint silently ignores unknown codes. */
function normalizeTarget(lang) {
    const m = /^([a-zA-Z]{2,3})(?:[-_]([a-zA-Z]{2}))?$/.exec(lang.trim());
    if (!m)
        return lang.trim();
    return m[2] ? `${m[1].toLowerCase()}-${m[2].toUpperCase()}` : m[1].toLowerCase();
}
/**
 * Parses a free-endpoint body. Sentences are concatenated in order; when the
 * detected language is the target the original is returned unchanged.
 * Returns null when the body is not in the expected shape.
 */
function parseFreeResponse(body, original, target) {
    var _a;
    let decoded;
    try {
        decoded = JSON.parse(body);
    }
    catch (_b) {
        return null;
    }
    if (!Array.isArray(decoded) || decoded.length === 0)
        return null;
    const detected = typeof decoded[2] === 'string' ? decoded[2] : null;
    const sentences = decoded[0];
    if (sentences !== null && !Array.isArray(sentences))
        return null;
    let text = '';
    for (const part of (_a = sentences) !== null && _a !== void 0 ? _a : []) {
        if (Array.isArray(part) && typeof part[0] === 'string')
            text += part[0];
    }
    const sameLanguage = detected !== null && sameBaseLanguage(detected, target);
    if (sameLanguage || text.trim().length === 0) {
        return { text: original, detectedLanguage: detected, sameLanguage };
    }
    return { text, detectedLanguage: detected, sameLanguage: false };
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const defaultBackoff = (retry) => 400 * 2 ** retry + Math.floor(Math.random() * 200);
/** Translates one text. Throws [FreeTranslateError] after the last attempt. */
async function freeTranslate(text, target, opts = {}) {
    var _a, _b, _c, _d, _e;
    const tl = normalizeTarget(target);
    const sl = opts.source ? normalizeTarget(opts.source) : 'auto';
    if (text.trim().length === 0)
        return { text, detectedLanguage: null, sameLanguage: true };
    if (sl !== 'auto' && sameBaseLanguage(sl, tl)) {
        return { text, detectedLanguage: sl, sameLanguage: true };
    }
    const doFetch = (_a = opts.fetchImpl) !== null && _a !== void 0 ? _a : fetch;
    const attempts = Math.max(1, (_b = opts.attempts) !== null && _b !== void 0 ? _b : 3);
    const backoff = (_c = opts.backoffMs) !== null && _c !== void 0 ? _c : defaultBackoff;
    const query = `client=gtx&sl=${encodeURIComponent(sl)}&tl=${encodeURIComponent(tl)}&dt=t`;
    let last = new FreeTranslateError('not attempted');
    for (let attempt = 0; attempt < attempts; attempt++) {
        if (attempt > 0)
            await sleep(backoff(attempt - 1));
        try {
            const long = text.length > POST_THRESHOLD;
            const res = await doFetch(long ? `${exports.FREE_ENDPOINT}?${query}` : `${exports.FREE_ENDPOINT}?${query}&q=${encodeURIComponent(text)}`, {
                method: long ? 'POST' : 'GET',
                headers: long ? { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8' } : undefined,
                body: long ? new URLSearchParams({ q: text }).toString() : undefined,
                signal: AbortSignal.timeout((_d = opts.timeoutMs) !== null && _d !== void 0 ? _d : 8000),
            });
            if (res.ok) {
                const parsed = parseFreeResponse(await res.text(), text, tl);
                if (parsed)
                    return parsed;
                // A malformed 200 will not improve with retries.
                throw new FreeTranslateError('Unreadable translate response', res.status, false);
            }
            const transient = res.status === 429 || res.status >= 500;
            last = new FreeTranslateError(`Translate HTTP ${res.status}`, res.status, transient);
            if (!transient)
                throw last;
        }
        catch (e) {
            if (e instanceof FreeTranslateError && !e.transient)
                throw e;
            last = e instanceof FreeTranslateError
                ? e
                : new FreeTranslateError(`Translate request failed: ${(_e = e === null || e === void 0 ? void 0 : e.message) !== null && _e !== void 0 ? _e : e}`);
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
async function freeTranslateMany(texts, target, opts = {}) {
    var _a;
    const out = texts.map(() => null);
    let next = 0;
    let rateLimited = false;
    const stopAt = opts.deadlineMs ? Date.now() + opts.deadlineMs : Infinity;
    const worker = async () => {
        while (!rateLimited && Date.now() < stopAt) {
            const i = next++;
            if (i >= texts.length)
                return;
            try {
                out[i] = await freeTranslate(texts[i], target, opts);
            }
            catch (e) {
                if (e instanceof FreeTranslateError && e.status === 429)
                    rateLimited = true;
                console.warn(`freeTranslate failed: ${e.message}`);
            }
        }
    };
    const n = Math.max(1, Math.min((_a = opts.concurrency) !== null && _a !== void 0 ? _a : 4, texts.length));
    await Promise.all(Array.from({ length: n }, worker));
    return out;
}
/** Languages the app offers (the free endpoint supports these and more). */
exports.SUPPORTED_LANGUAGES = [
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
exports.freeTranslationClient = {
    async translateText(req) {
        const out = await freeTranslateMany(req.contents, req.targetLanguageCode, {
            source: req.sourceLanguageCode,
        });
        return [{
                translations: out.map((t) => {
                    var _a, _b;
                    return ({
                        translatedText: (_a = t === null || t === void 0 ? void 0 : t.text) !== null && _a !== void 0 ? _a : '',
                        detectedLanguageCode: (_b = t === null || t === void 0 ? void 0 : t.detectedLanguage) !== null && _b !== void 0 ? _b : null,
                    });
                }),
            }];
    },
};
//# sourceMappingURL=freeTranslate.js.map