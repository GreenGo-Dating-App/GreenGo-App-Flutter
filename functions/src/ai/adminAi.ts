/**
 * adminAi: ONE callable for the admin panel's "AI Providers" page.
 * `data.action` selects the operation.
 *
 * Roles (shared/adminAuth.ts):
 *   read actions   superAdmin | analyst
 *   write actions  superAdmin (fresh admin 2FA once requireAdmin2fa is on),
 *                  each one audited in admin_audit_log (never with the key).
 *
 * API keys go to Secret Manager only (./router/secrets.ts). `ai_config/main`
 * holds providers, routes, rules and key METADATA (last 4 chars, who, when).
 * Every saved config is versioned in ai_config/main/history/{version} so an
 * admin can roll back.
 */
import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { AdminRole, requireAdmin } from '../shared/adminAuth';
import {
  AI_CONFIG_DOC, BUILTIN_PROVIDERS, ConfigError, DEFAULT_ROUTES, DEFAULT_RULES, PROVIDER_ID, defaultConfig,
  invalidateConfigCache, keyNameOf, mockPreset, normalizeConfig, qwenPreset, validateBaseUrl, validateProvider, validateRoute, validateRules,
} from './router/config';
import { removeProviderKey, secretNameFor, writeProviderKey } from './router/secrets';
import { testProvider } from './router/router';
import { isMockAllowed } from './router/mock';
import { APP_LANGUAGES, MODEL_LANGUAGES, providerLanguages } from './router/languages';
import { AI_USAGE_STATS, USAGE_SHARDS, dayKey } from './router/usage';
import { AiConfig, CAPABILITIES, Capability, PROVIDER_TYPES, TYPE_KINDS, TYPE_NEEDS_KEY } from './router/types';

const db = () => admin.firestore();
const READ_ROLES: readonly AdminRole[] = ['superAdmin', 'analyst'];
const WRITE_ROLES: readonly AdminRole[] = ['superAdmin'];

const isCap = (v: unknown): v is Capability => typeof v === 'string' && (CAPABILITIES as readonly string[]).includes(v);

async function audit(uid: string, action: string, details: Record<string, unknown>): Promise<void> {
  try {
    await db().collection('admin_audit_log').add({
      adminId: uid, action: `ai.${action}`, details,
      timestamp: admin.firestore.FieldValue.serverTimestamp(), source: 'adminAi',
    });
  } catch (e) {
    console.warn('[adminAi] audit failed', (e as Error)?.message);
  }
}

async function readConfig(): Promise<AiConfig> {
  const snap = await db().doc(AI_CONFIG_DOC).get();
  return normalizeConfig(snap.exists ? snap.data() : null);
}

/** Saves [next] as a new version (transaction on the version number). */
async function saveConfig(next: AiConfig, uid: string, note: string): Promise<AiConfig> {
  const ref = db().doc(AI_CONFIG_DOC);
  const saved = await db().runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    const version = (Number(cur.data()?.version) || 0) + 1;
    const doc = { ...next, version, updatedAt: new Date().toISOString(), updatedBy: uid };
    tx.set(ref, doc);
    tx.set(ref.collection('history').doc(String(version)), { ...doc, note });
    return doc;
  });
  invalidateConfigCache();
  return saved;
}

const bad = (e: unknown): never => {
  if (e instanceof ConfigError) throw new HttpsError('invalid-argument', e.message);
  throw e;
};

function publicView(c: AiConfig) {
  return {
    config: c,
    capabilities: CAPABILITIES,
    providerTypes: PROVIDER_TYPES.map((t) => ({ type: t, kinds: TYPE_KINDS[t], needsKey: TYPE_NEEDS_KEY[t] })),
    builtinProviders: Object.keys(BUILTIN_PROVIDERS),
    defaults: { routes: DEFAULT_ROUTES, rules: DEFAULT_RULES },
    keyStore: 'Google Cloud Secret Manager',
    mockAvailable: isMockAllowed(),
    appLanguages: APP_LANGUAGES,
    providerLanguages: Object.fromEntries(Object.values(c.providers).map((p) => [p.id, providerLanguages(p)])),
    modelLanguages: MODEL_LANGUAGES,
    modelCatalog: MODEL_CATALOG,
  };
}

// ------------------------------------------------------------------- reads

const READS: Record<string, (d: any, uid: string) => Promise<unknown>> = {
  async getConfig() {
    return publicView(await readConfig());
  },

  /** Live model ids from the provider (+ the built-in catalogue). */
  async listModels(d) {
    const c = await readConfig();
    const p = c.providers[String(d.providerId ?? '')];
    const catalog = MODEL_CATALOG.filter((m) => !p || m.types.includes(p.type));
    if (!p && !d.baseUrl) return { live: [], catalog: MODEL_CATALOG };
    const probe = p ?? {
      id: String(d.keyName ?? ''), keyName: String(d.keyName ?? ''), type: String(d.type ?? 'openai_compatible'),
      baseUrl: (() => { try { return validateBaseUrl(d.baseUrl); } catch (e) { return bad(e); } })(),
    };
    try {
      return { live: await liveModels(probe), catalog };
    } catch (e: any) {
      return { live: [], catalog, error: String(e?.message ?? e).slice(0, 200) };
    }
  },

  async listHistory(d) {
    const limit = Math.min(50, Math.max(1, Number(d.limit) || 20));
    const snap = await db().doc(AI_CONFIG_DOC).collection('history').orderBy('version', 'desc').limit(limit).get();
    return {
      items: snap.docs.map((x) => ({
        version: x.data().version, updatedAt: x.data().updatedAt ?? null, updatedBy: x.data().updatedBy ?? null,
        note: x.data().note ?? '',
      })),
    };
  },

  /** Daily usage per capability / provider, summed over the shards. */
  async getUsage(d) {
    const days = Math.min(62, Math.max(1, Number(d.days) || 14));
    const out: Record<string, any> = {};
    const models: Record<string, string> = {};
    const ids: string[] = [];
    for (let i = 0; i < days; i++) {
      const day = dayKey(new Date(Date.now() - i * 864e5));
      out[day] = {};
      for (let s = 0; s < USAGE_SHARDS; s++) ids.push(`${day}_${s}`);
    }
    for (let i = 0; i < ids.length; i += 200) {
      const snaps = await db().getAll(...ids.slice(i, i + 200).map((id) => db().collection(AI_USAGE_STATS).doc(id)));
      for (const s of snaps) {
        if (!s.exists) continue;
        const data = s.data() ?? {};
        const day = String(data.day ?? s.id.split('_')[0]);
        Object.assign(models, data.models ?? {});
        for (const [cap, provs] of Object.entries<any>(data.c ?? {})) {
          for (const [pid, st] of Object.entries<any>(provs ?? {})) {
            const row = ((out[day][cap] ??= {})[pid] ??= { calls: 0, items: 0, chars: 0, errors: 0, fallbacks: 0, latencyMs: 0, tokensIn: 0, tokensOut: 0 });
            for (const k of Object.keys(row)) row[k] += Number(st?.[k]) || 0;
          }
        }
      }
    }
    return { days: out, models };
  },
};

/**
 * Known model ids (a starting point for the picker; the live list from the
 * provider's /models endpoint is preferred, and any id can be typed in).
 * `kinds` = which capabilities the model suits; prices are not stored here
 * (the admin types the current price into the provider's options).
 */
export const MODEL_CATALOG: { id: string; label: string; types: string[]; kinds: string[] }[] = [
  { id: 'qwen-flash', label: 'Qwen Flash', types: ['openai_compatible'], kinds: ['text', 'translate'] },
  { id: 'qwen-plus', label: 'Qwen Plus', types: ['openai_compatible'], kinds: ['text', 'translate'] },
  { id: 'qwen-max', label: 'Qwen Max', types: ['openai_compatible'], kinds: ['text', 'translate'] },
  { id: 'qwen-turbo', label: 'Qwen Turbo', types: ['openai_compatible'], kinds: ['text', 'translate'] },
  { id: 'qwen-mt-flash', label: 'Qwen-MT Flash', types: ['qwen_mt'], kinds: ['translate'] },
  { id: 'qwen-mt-plus', label: 'Qwen-MT Plus', types: ['qwen_mt'], kinds: ['translate'] },
  { id: 'qwen-mt-lite', label: 'Qwen-MT Lite', types: ['qwen_mt'], kinds: ['translate'] },
  { id: 'qwen3-tts-flash', label: 'Qwen3 TTS Flash', types: ['qwen_tts'], kinds: ['tts'] },
  { id: 'qwen-audio-3.1-tts-flash', label: 'Qwen-Audio 3.1 TTS Flash (WebSocket)', types: ['qwen_audio_tts'], kinds: ['tts'] },
  { id: 'qwen-audio-3.1-tts-plus', label: 'Qwen-Audio 3.1 TTS Plus (WebSocket)', types: ['qwen_audio_tts'], kinds: ['tts'] },
  // Small open models for a self-hosted engine (Ollama / vLLM, OpenAI-compatible /v1).
  { id: 'qwen3:0.6b', label: 'Qwen3 0.6B (Ollama)', types: ['openai_compatible'], kinds: ['text', 'translate'] },
  { id: 'qwen3:1.7b', label: 'Qwen3 1.7B (Ollama)', types: ['openai_compatible'], kinds: ['text', 'translate'] },
  { id: 'qwen2.5:0.5b', label: 'Qwen2.5 0.5B (Ollama)', types: ['openai_compatible'], kinds: ['text', 'translate'] },
  { id: 'qwen2.5:1.5b', label: 'Qwen2.5 1.5B (Ollama)', types: ['openai_compatible'], kinds: ['text', 'translate'] },
  { id: 'llama3.2:1b', label: 'Llama 3.2 1B (Ollama)', types: ['openai_compatible'], kinds: ['text', 'translate'] },
  { id: 'gemma3:1b', label: 'Gemma 3 1B (Ollama)', types: ['openai_compatible'], kinds: ['text', 'translate'] },
  { id: 'gemini-2.0-flash', label: 'Gemini 2.0 Flash', types: ['gemini'], kinds: ['text'] },
  { id: 'gemini-flash-latest', label: 'Gemini Flash (latest)', types: ['gemini'], kinds: ['text'] },
];

/** GET {baseUrl}/models with the provider's key (OpenAI-compatible APIs). */
async function liveModels(p: { baseUrl?: string; type: string; id: string; keyName?: string; options?: Record<string, unknown> }): Promise<string[]> {
  const { readProviderKey } = await import('./router/secrets');
  const { fetchJson } = await import('./router/http');
  if (!p.baseUrl) return [];
  const key = await readProviderKey(p.keyName || p.id);
  const open = (p as any).options?.noAuth === true;
  if (!key && !open) throw new HttpsError('failed-precondition', 'Save the API key first');
  // TTS endpoints live under /api/v1: list from the compatible-mode root.
  const base = p.type === 'qwen_tts' ? p.baseUrl.replace(/\/api\/v1$/, '/compatible-mode/v1') : p.baseUrl;
  const r = await fetchJson(`${base.replace(/\/+$/, '')}/models`, { headers: key ? { Authorization: `Bearer ${key}` } : {} }, 15_000);
  if (!r.ok) throw new HttpsError('unavailable', `The provider answered HTTP ${r.status} to /models`);
  const list = Array.isArray(r.body?.data) ? r.body.data : [];
  return list.map((m: any) => String(m?.id ?? '')).filter(Boolean).sort();
}

// ------------------------------------------------------------------ writes

const WRITES: Record<string, (d: any, uid: string) => Promise<{ result: unknown; audit: Record<string, unknown> }>> = {
  async saveProvider(d, uid) {
    const c = await readConfig();
    const p = (() => {
      try {
        return validateProvider(d.provider, c.providers[d.provider?.id]);
      } catch (e) {
        return bad(e);
      }
    })();
    if (BUILTIN_PROVIDERS[p.id] && p.type !== BUILTIN_PROVIDERS[p.id].type) {
      throw new HttpsError('invalid-argument', 'The type of a built-in provider cannot change');
    }
    c.providers[p.id] = p;
    // A provider whose type changed must leave routes it can no longer serve.
    for (const cap of CAPABILITIES) {
      try {
        validateRoute(cap, c.routes[cap], c.providers);
      } catch {
        c.routes[cap].chain = c.routes[cap].chain.filter((id) => id !== p.id);
      }
    }
    const saved = await saveConfig(c, uid, `provider ${p.id} saved`);
    return { result: publicView(saved), audit: { providerId: p.id, type: p.type, model: p.model ?? null, baseUrl: p.baseUrl ?? null } };
  },

  async deleteProvider(d, uid) {
    const id = String(d.id ?? '');
    const c = await readConfig();
    if (!c.providers[id]) throw new HttpsError('not-found', 'Unknown provider');
    if (BUILTIN_PROVIDERS[id]) throw new HttpsError('failed-precondition', 'Built-in providers can be disabled, not deleted');
    const used = CAPABILITIES.filter((cap) => c.routes[cap].chain.includes(id));
    if (used.length) throw new HttpsError('failed-precondition', `Remove it from these routes first: ${used.join(', ')}`);
    delete c.providers[id];
    const saved = await saveConfig(c, uid, `provider ${id} deleted`);
    return { result: publicView(saved), audit: { providerId: id } };
  },

  /** Stores an API key in Secret Manager. The key never comes back. */
  async setKey(d, uid) {
    const keyName = String(d.keyName ?? '');
    if (!PROVIDER_ID.test(keyName)) throw new HttpsError('invalid-argument', 'keyName must be 2-40 characters: a-z, 0-9, _');
    const key = typeof d.key === 'string' ? d.key.trim() : '';
    if (key.length < 8 || key.length > 4096 || /\s/.test(key)) throw new HttpsError('invalid-argument', 'That does not look like an API key');
    try {
      await writeProviderKey(keyName, key);
    } catch (e: any) {
      console.error('[adminAi] Secret Manager write failed', e?.code ?? '', e?.details ?? e?.message ?? '');
      throw new HttpsError('failed-precondition',
        'Could not save the key in Secret Manager. Check that the functions service account may manage AI_KEY_* secrets (see docs/ai-providers/SETUP.md).');
    }
    const c = await readConfig();
    c.keys[keyName] = { last4: key.slice(-4), setAt: new Date().toISOString(), setBy: uid };
    const saved = await saveConfig(c, uid, `key ${keyName} set`);
    return { result: publicView(saved), audit: { keyName, secret: secretNameFor(keyName), last4: key.slice(-4) } };
  },

  async deleteKey(d, uid) {
    const keyName = String(d.keyName ?? '');
    if (!PROVIDER_ID.test(keyName)) throw new HttpsError('invalid-argument', 'Invalid keyName');
    await removeProviderKey(keyName);
    const c = await readConfig();
    delete c.keys[keyName];
    const saved = await saveConfig(c, uid, `key ${keyName} deleted`);
    return { result: publicView(saved), audit: { keyName } };
  },

  async saveRoutes(d, uid) {
    const c = await readConfig();
    for (const cap of CAPABILITIES) {
      if (d.routes?.[cap] === undefined) continue;
      try {
        c.routes[cap] = validateRoute(cap, d.routes[cap], c.providers);
      } catch (e) {
        bad(e);
      }
    }
    const saved = await saveConfig(c, uid, 'routes saved');
    return { result: publicView(saved), audit: { routes: saved.routes } };
  },

  async saveRules(d, uid) {
    if (!isCap(d.capability)) throw new HttpsError('invalid-argument', 'Unknown capability');
    const c = await readConfig();
    try {
      c.rules[d.capability] = validateRules(d.rules);
    } catch (e) {
      bad(e);
    }
    const saved = await saveConfig(c, uid, `rules ${d.capability} saved`);
    return { result: publicView(saved), audit: { capability: d.capability, rules: saved.rules[d.capability as Capability] } };
  },

  async resetRules(d, uid) {
    if (!isCap(d.capability)) throw new HttpsError('invalid-argument', 'Unknown capability');
    const c = await readConfig();
    c.rules[d.capability] = JSON.parse(JSON.stringify(DEFAULT_RULES[d.capability as Capability]));
    const saved = await saveConfig(c, uid, `rules ${d.capability} reset`);
    return { result: publicView(saved), audit: { capability: d.capability } };
  },

  async applyQwenPreset(_d, uid) {
    const saved = await saveConfig(qwenPreset(await readConfig()), uid, 'Qwen preset applied');
    return { result: publicView(saved), audit: { preset: 'qwen' } };
  },

  /** Test projects only: route every capability to the key-free mock first. */
  async applyMockPreset(_d, uid) {
    let next: AiConfig;
    try {
      next = mockPreset(await readConfig());
    } catch (e) {
      return bad(e);
    }
    const saved = await saveConfig(next, uid, 'Mock preset applied (test project)');
    return { result: publicView(saved), audit: { preset: 'mock' } };
  },

  async resetToDefaults(_d, uid) {
    const c = defaultConfig();
    c.keys = (await readConfig()).keys; // key metadata stays (the secrets still exist)
    const saved = await saveConfig(c, uid, 'reset to Google defaults');
    return { result: publicView(saved), audit: { preset: 'defaults' } };
  },

  async rollback(d, uid) {
    const version = Number(d.version);
    if (!Number.isInteger(version) || version < 1) throw new HttpsError('invalid-argument', 'Invalid version');
    const snap = await db().doc(AI_CONFIG_DOC).collection('history').doc(String(version)).get();
    if (!snap.exists) throw new HttpsError('not-found', 'Unknown version');
    const c = normalizeConfig(snap.data());
    c.keys = (await readConfig()).keys;
    const saved = await saveConfig(c, uid, `rollback to v${version}`);
    return { result: publicView(saved), audit: { rollbackTo: version } };
  },

  /** One direct call to a provider (no chain / consent / quotas). */
  async testProvider(d) {
    const c = await readConfig();
    const p = c.providers[String(d.providerId ?? '')];
    if (!p) throw new HttpsError('not-found', 'Unknown provider');
    const cap: Capability = isCap(d.capability) ? d.capability
      : (TYPE_KINDS[p.type].includes('translate') ? 'translate_chat' : TYPE_KINDS[p.type].includes('tts') ? 'tts' : 'text_assist');
    const sample = typeof d.sample === 'string' && d.sample.trim() ? d.sample.trim().slice(0, 500) : 'Hello! How are you today?';
    const target = typeof d.target === 'string' && /^[A-Za-z]{2,3}([-_][A-Za-z]{2,4})?$/.test(d.target) ? d.target : 'it';
    const system = typeof d.system === 'string' ? d.system.slice(0, 4000) : undefined;
    try {
      const r = await testProvider(p, cap, sample, target, system);
      return { result: { ok: true, providerId: p.id, keyName: keyNameOf(p), ...r }, audit: { providerId: p.id, capability: cap } };
    } catch (e: any) {
      return {
        result: { ok: false, providerId: p.id, keyName: keyNameOf(p), error: String(e?.message ?? e).slice(0, 300), status: e?.status ?? 0 },
        audit: { providerId: p.id, capability: cap, ok: false },
      };
    }
  },
};

export async function adminAiHandler(request: { data: any; auth?: any }) {
  const data = request.data || {};
  const action = String(data.action || '');
  if (READS[action]) {
    const who = await requireAdmin(request.auth, READ_ROLES, { require2fa: false });
    return READS[action](data, who.uid);
  }
  if (WRITES[action]) {
    const who = await requireAdmin(request.auth, WRITE_ROLES);
    const { result, audit: details } = await WRITES[action](data, who.uid);
    await audit(who.uid, action, details);
    return result;
  }
  throw new HttpsError('invalid-argument', `unknown action: ${action}`);
}

export const adminAi = onCall({ memory: '512MiB', timeoutSeconds: 120 }, adminAiHandler);
