/**
 * Same-origin proxy for the Flutter web engine's fallback fonts.
 *
 * Why: Flutter web (CanvasKit) downloads Roboto and the Noto fallback fonts
 * (emoji, CJK, Arabic, Devanagari, ...) from `https://fonts.gstatic.com/s/`
 * by default. That sends every visitor's IP address to Google without
 * consent, which a German court held unlawful under the GDPR
 * (LG Muenchen I, 3 O 17493/20, 20.01.2022). The web app now sets the engine
 * config `fontFallbackBaseUrl: '/gfonts/s/'`, Firebase Hosting rewrites
 * `/gfonts/**` to this function, and the function fetches the file from
 * Google server-side. Google only ever sees our server; the response is
 * immutable and cached by the Hosting CDN for a year, so each font file costs
 * roughly one function invocation per CDN edge, ever.
 *
 * Why a proxy instead of vendoring the files: the engine references ~720
 * versioned font files (CJK alone is ~560 slices, tens of MB) and the exact
 * paths change with every Flutter upgrade. A proxy only fetches what users
 * actually need and keeps working across upgrades without a re-vendoring step.
 *
 * It is NOT an open proxy: only `fonts.gstatic.com/s/<noto*|roboto>/v<N>/<file>`
 * font files are accepted (strict regex, no query, no encoded characters),
 * redirects are not followed, responses are size-capped and must start with a
 * real font signature.
 *
 * Pure module (no Firebase imports) so it can be unit tested directly.
 */

export const UPSTREAM_ORIGIN = 'https://fonts.gstatic.com';
/** Hosting path the rewrite is mounted on (see firebase.json). */
export const MOUNT_PREFIX = '/gfonts';
/** Largest single file the engine requests is well under 3 MB. */
export const MAX_FONT_BYTES = 8 * 1024 * 1024;

/** Successful font: immutable, versioned URL -> cache for a year everywhere. */
export const FONT_CACHE = 'public, max-age=31536000, s-maxage=31536000, immutable';
/** Upstream 404: cache briefly so a bad path cannot hammer the function. */
export const NOT_FOUND_CACHE = 'public, max-age=300, s-maxage=3600';

const CONTENT_TYPES: Record<string, string> = {
  woff2: 'font/woff2',
  woff: 'font/woff',
  ttf: 'font/ttf',
  otf: 'font/otf',
};

/**
 * /s/<family>/v<version>/<file>[.<slice>].<ext>
 *  - family: Roboto or any Noto family (lower-case, as used by the engine)
 *  - file:   gstatic's opaque id, e.g. `KFOmCnqEu92Fr1Me4GZLCzYlKw` or
 *            `Yq6P-KqIXTD0t4D9z1ESnKM3-HpFabsE4tq3luCC7p-aXxcn.3`
 */
const FONT_PATH_RE =
  /^\/s\/(noto[a-z0-9]{0,60}|roboto)\/v(\d{1,4})\/([A-Za-z0-9_-]{8,128}(?:\.\d{1,3})?)\.(woff2|woff|ttf|otf)$/;

export interface FontTarget {
  /** Absolute upstream URL on fonts.gstatic.com. */
  url: string;
  contentType: string;
}

/**
 * Maps an incoming request path (with or without the `/gfonts` mount prefix)
 * to the upstream font URL, or null when the path is not an allowed font.
 */
export function fontTargetForPath(reqPath: unknown): FontTarget | null {
  if (typeof reqPath !== 'string' || reqPath.length > 300) return null;
  let p = reqPath;
  if (p.startsWith(MOUNT_PREFIX + '/')) p = p.slice(MOUNT_PREFIX.length);
  const m = FONT_PATH_RE.exec(p);
  if (!m) return null;
  return { url: UPSTREAM_ORIGIN + p, contentType: CONTENT_TYPES[m[4]] };
}

/** True when the bytes start with a WOFF2 / WOFF / TrueType / OpenType signature. */
export function looksLikeFont(buf: Buffer): boolean {
  if (!buf || buf.length < 4) return false;
  const tag = buf.subarray(0, 4).toString('latin1');
  if (tag === 'wOF2' || tag === 'wOFF' || tag === 'OTTO' || tag === 'true') return true;
  return buf.readUInt32BE(0) === 0x00010000; // TrueType 1.0
}

export interface UpstreamResponse {
  status: number;
  data: Buffer;
}

/** Fetches a URL. Implementations must not follow redirects and must cap size. */
export type FontFetcher = (url: string) => Promise<UpstreamResponse>;

/** Minimal request/response surface (Express-compatible) used by the handler. */
export interface ProxyRequest {
  method: string;
  path: string;
}
export interface ProxyResponse {
  status(code: number): ProxyResponse;
  set(field: string, value: string): ProxyResponse;
  send(body?: unknown): unknown;
  end(): unknown;
}

export async function handleFontRequest(
  req: ProxyRequest,
  res: ProxyResponse,
  fetchFont: FontFetcher,
): Promise<void> {
  res.set('X-Content-Type-Options', 'nosniff');
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.set('Allow', 'GET, HEAD');
    res.status(405).send('method not allowed');
    return;
  }
  const target = fontTargetForPath(req.path);
  if (!target) {
    res.set('Cache-Control', NOT_FOUND_CACHE);
    res.status(404).send('not found');
    return;
  }

  let upstream: UpstreamResponse;
  try {
    upstream = await fetchFont(target.url);
  } catch {
    res.set('Cache-Control', 'no-store');
    res.status(502).send('upstream unavailable');
    return;
  }

  if (upstream.status === 404 || upstream.status === 410) {
    res.set('Cache-Control', NOT_FOUND_CACHE);
    res.status(404).send('not found');
    return;
  }
  const data = upstream.data;
  if (
    upstream.status !== 200 ||
    !Buffer.isBuffer(data) ||
    data.length > MAX_FONT_BYTES ||
    !looksLikeFont(data)
  ) {
    res.set('Cache-Control', 'no-store');
    res.status(502).send('bad upstream response');
    return;
  }

  res.set('Content-Type', target.contentType);
  res.set('Cache-Control', FONT_CACHE);
  res.set('Content-Length', String(data.length));
  res.status(200);
  if (req.method === 'HEAD') {
    res.end();
    return;
  }
  res.send(data);
}
