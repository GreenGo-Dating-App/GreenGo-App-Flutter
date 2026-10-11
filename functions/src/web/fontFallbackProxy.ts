/**
 * fontFallbackProxy - serves the Flutter web engine's fallback fonts
 * (Roboto + Noto emoji/CJK/scripts) from our own origin at /gfonts/s/**,
 * so visitors' browsers never contact fonts.gstatic.com.
 * See fontFallbackProxyCore.ts for the rationale and the allow-list.
 *
 * Firebase Hosting: { "source": "/gfonts/**", "function": { "functionId": "fontFallbackProxy" } }
 */

import { onRequest } from 'firebase-functions/v2/https';
import axios from 'axios';
import { monitored } from '../shared/monitoring';
import { FontFetcher, MAX_FONT_BYTES, handleFontRequest } from './fontFallbackProxyCore';

const fetchFromGstatic: FontFetcher = async (url) => {
  const resp = await axios.get<ArrayBuffer>(url, {
    responseType: 'arraybuffer',
    timeout: 10000,
    maxContentLength: MAX_FONT_BYTES,
    maxBodyLength: MAX_FONT_BYTES,
    maxRedirects: 0,
    // Never forward anything about the visitor upstream.
    headers: { 'User-Agent': 'GreenGo-font-proxy/1.0', Accept: 'font/*' },
    validateStatus: () => true,
  });
  return { status: resp.status, data: Buffer.from(resp.data) };
};

export const fontFallbackProxy = onRequest(
  // 512MiB: the shared index.js alone needs ~200MB RSS on cold start.
  { memory: '512MiB', timeoutSeconds: 30, maxInstances: 20, invoker: 'public' },
  monitored('fontFallbackProxy', async (req, res) => {
    await handleFontRequest(req, res, fetchFromGstatic);
  }),
);
