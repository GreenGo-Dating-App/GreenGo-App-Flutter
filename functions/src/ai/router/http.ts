/**
 * Small shared HTTP + legacy-key helpers for the AI router and aiGateway.
 */
import * as admin from 'firebase-admin';
import '../../shared/firebaseAdmin';

export interface JsonResponse { ok: boolean; status: number; body: any }

export async function fetchJson(url: string, init: any, timeoutMs: number): Promise<JsonResponse> {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res: any = await fetch(url, { ...init, signal: ctrl.signal });
    let body: any = null;
    try {
      body = await res.json();
    } catch {
      body = null;
    }
    return { ok: !!res.ok, status: Number(res.status) || 0, body };
  } finally {
    clearTimeout(t);
  }
}

export async function fetchBytes(url: string, timeoutMs: number): Promise<{ ok: boolean; status: number; bytes: Buffer | null }> {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res: any = await fetch(url, { signal: ctrl.signal });
    if (!res.ok) return { ok: false, status: Number(res.status) || 0, bytes: null };
    return { ok: true, status: Number(res.status) || 200, bytes: Buffer.from(await res.arrayBuffer()) };
  } finally {
    clearTimeout(t);
  }
}

// ------------------------------------------------------------ legacy keys

let keyCache: { at: number; data: Record<string, unknown> } | null = null;
/** Test hook. */
export function _resetKeyCache() { keyCache = null; }

/**
 * Pre-router key lookup: env first, then `app_config/api_keys` (Admin SDK).
 * Only the Google providers still use it (until their keys move to Secret
 * Manager); new providers read Secret Manager only.
 */
export async function getServerKey(envName: string, ...fields: string[]): Promise<string | null> {
  const env = process.env[envName];
  if (env) return env;
  if (!keyCache || Date.now() - keyCache.at > 5 * 60_000) {
    const snap = await admin.firestore().collection('app_config').doc('api_keys').get();
    keyCache = { at: Date.now(), data: snap.data() ?? {} };
  }
  for (const f of fields) {
    const v = keyCache.data[f];
    if (typeof v === 'string' && v.trim()) return v.trim();
  }
  return null;
}

// --------------------------------------------- Google service-account token

type TokenProvider = () => Promise<string>;
let tokenProvider: TokenProvider = async () => {
  const cred = (admin.app().options.credential as any) ?? admin.credential.applicationDefault();
  const t = await cred.getAccessToken();
  return t.access_token as string;
};
/** Test hook (the emulator has no service account). */
export function _setAccessTokenProvider(p: TokenProvider) { tokenProvider = p; }
export const accessToken = () => tokenProvider();
