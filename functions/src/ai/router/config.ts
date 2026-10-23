/**
 * `ai_config/main`: providers, routes and context rules (server-only doc, no
 * secrets). Read by every routed call through a 60 s per-instance cache, so
 * an admin change applies within a minute without a redeploy.
 *
 * Without the doc (or for a capability it does not mention) the DEFAULTS
 * below apply. They reproduce the pre-router behaviour exactly:
 *   translate_chat   Cloud Translation v2
 *   translate_public free Google endpoint
 *   text_assist      Gemini
 *   text_buddies     (no provider until an admin configures one)
 *   tts              Google Cloud TTS
 * QWEN_PRESET is what the admin panel's "Load Qwen preset" writes.
 */
import * as admin from 'firebase-admin';
import '../../shared/firebaseAdmin';
import { isMockAllowed } from './mock';
import {
  AiConfig, CAPABILITIES, Capability, CapabilityRules, PROVIDER_TYPES, ProviderConfig, RouteConfig,
  TYPE_KINDS, capabilityKind,
} from './types';

export const AI_CONFIG_DOC = 'ai_config/main';
export const AI_CONFIG_HISTORY = 'ai_config/main/history';
const TTL_MS = 60_000;

/** Current AI-consent notice version that names Alibaba Cloud (Qwen). */
export const QWEN_CONSENT_VERSION = 3;

// ------------------------------------------------------------------ defaults

export const BUILTIN_PROVIDERS: Record<string, ProviderConfig> = {
  google_v2: { id: 'google_v2', label: 'Google Cloud Translation v2', type: 'google_translate_v2', enabled: true },
  google_free: { id: 'google_free', label: 'Google Translate (free endpoint)', type: 'google_free', enabled: true },
  gemini: {
    id: 'gemini', label: 'Google Gemini', type: 'gemini', enabled: true,
    model: process.env.GEMINI_MODEL || 'gemini-2.0-flash',
  },
  google_tts: { id: 'google_tts', label: 'Google Cloud TTS (Chirp 3 HD)', type: 'google_tts', enabled: true },
};

export const DEFAULT_RULES: Record<Capability, CapabilityRules> = {
  translate_chat: { maxInputChars: 2000, timeoutMs: 20_000, retries: 0, glossary: [{ source: 'GreenGo', target: 'GreenGo' }] },
  translate_public: { maxInputChars: 5000, timeoutMs: 8_000, retries: 1, glossary: [{ source: 'GreenGo', target: 'GreenGo' }] },
  text_assist: { maxInputChars: 1000, maxTokens: 1024, temperature: 0.3, timeoutMs: 20_000, retries: 0 },
  text_buddies: {
    maxOutputChars: 200,
    maxInputChars: 500,
    maxTokens: 120,
    temperature: 0.8,
    timeoutMs: 15_000,
    retries: 1,
    styleRules: [
      'Reply like a chat message: one or two short sentences, at most 200 characters.',
      'No lists, no headings, no markdown, no links, no hashtags.',
    ],
    bannedTerms: [],
    stripMarkdown: true,
    stripLinks: true,
    contextMessages: 12,
    contextChars: 2400,
    memoryMaxFacts: 20,
    memoryEvery: 6,
    summaryEvery: 20,
    summaryMaxChars: 600,
    checkInsEnabled: true,
    checkInAfterHours: 24,
    checkInStartHour: 9,
    checkInEndHour: 21,
    checkInMaxUnanswered: 3,
  },
  tts: { maxInputChars: 500, timeoutMs: 30_000, retries: 0 },
};

export const DEFAULT_ROUTES: Record<Capability, RouteConfig> = {
  translate_chat: { enabled: true, chain: ['google_v2'] },
  translate_public: { enabled: true, chain: ['google_free'] },
  text_assist: { enabled: true, chain: ['gemini'] },
  text_buddies: { enabled: true, chain: [] },
  tts: { enabled: true, chain: ['google_tts'] },
};

export function defaultConfig(): AiConfig {
  return {
    version: 0,
    providers: JSON.parse(JSON.stringify(BUILTIN_PROVIDERS)),
    routes: JSON.parse(JSON.stringify(DEFAULT_ROUTES)),
    rules: JSON.parse(JSON.stringify(DEFAULT_RULES)),
    keys: {},
    updatedAt: null,
    updatedBy: null,
  };
}

/** US (Virginia) DashScope endpoint (owner decision 2026-10-23). */
export const DASHSCOPE_US = 'https://dashscope-us.aliyuncs.com';

/** Providers + routes written by "Load Qwen preset" (keys are added separately). */
export function qwenPreset(base: AiConfig): AiConfig {
  const c: AiConfig = JSON.parse(JSON.stringify(base));
  // One DashScope key for every Qwen model.
  const common = { enabled: true, minConsentVersion: QWEN_CONSENT_VERSION, keyName: 'dashscope' };
  c.providers.qwen_flash = {
    ...(c.providers.qwen_flash ?? {}), ...common, id: 'qwen_flash', label: 'Qwen Flash',
    type: 'openai_compatible', baseUrl: `${DASHSCOPE_US}/compatible-mode/v1`, model: 'qwen-flash',
  };
  c.providers.qwen_mt_flash = {
    ...(c.providers.qwen_mt_flash ?? {}), ...common, id: 'qwen_mt_flash', label: 'Qwen-MT Flash',
    type: 'qwen_mt', baseUrl: `${DASHSCOPE_US}/compatible-mode/v1`, model: 'qwen-mt-flash',
  };
  c.providers.qwen_tts = {
    ...(c.providers.qwen_tts ?? {}), ...common, id: 'qwen_tts', label: 'Qwen TTS',
    type: 'qwen_tts', baseUrl: `${DASHSCOPE_US}/api/v1`, model: 'qwen3-tts-flash',
    options: { voices: { default: { male: 'Ethan', female: 'Cherry' } } },
  };
  // Public texts carry no personal data: no consent gate for that route, so
  // the public chain uses a consent-free copy of the MT provider.
  c.providers.qwen_mt_public = {
    ...(c.providers.qwen_mt_public ?? {}), ...c.providers.qwen_mt_flash,
    id: 'qwen_mt_public', label: 'Qwen-MT Flash (public texts)', minConsentVersion: 0,
  };
  c.routes = {
    translate_chat: { enabled: true, chain: ['qwen_mt_flash', 'google_v2'] },
    translate_public: { enabled: true, chain: ['qwen_mt_public', 'google_free'] },
    text_assist: { enabled: true, chain: ['qwen_flash', 'gemini'] },
    text_buddies: { enabled: true, chain: ['qwen_flash'] },
    tts: { enabled: true, chain: ['qwen_tts', 'google_tts'] },
  };
  return c;
}

/** Test projects only: every capability answered by the key-free mock. */
export function mockPreset(base: AiConfig): AiConfig {
  if (!isMockAllowed()) throw new ConfigError('The mock provider is only allowed in test projects');
  const c: AiConfig = JSON.parse(JSON.stringify(base));
  c.providers.mock = { id: 'mock', label: 'Mock AI (test only)', type: 'mock', enabled: true, minConsentVersion: 0, model: 'mock' };
  for (const cap of CAPABILITIES) {
    c.routes[cap] = { enabled: true, chain: ['mock', ...c.routes[cap].chain.filter((id) => id !== 'mock')].slice(0, 5) };
  }
  return c;
}

// ---------------------------------------------------------------- validation

export class ConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ConfigError';
  }
}

export const PROVIDER_ID = /^[a-z0-9_]{2,40}$/;

const PRIVATE_HOST = [
  /^localhost$/i, /\.local$/i, /\.internal$/i, /^metadata(\.|$)/i,
  /^127\./, /^10\./, /^192\.168\./, /^172\.(1[6-9]|2\d|3[01])\./, /^169\.254\./, /^0\./,
  /^\[?::1\]?$/, /^\[?f[cd][0-9a-f]{2}:/i, /^\[?fe80:/i,
];

/** https only, no credentials, no private / link-local / metadata hosts (SSRF). */
export function validateBaseUrl(v: unknown): string {
  if (typeof v !== 'string' || !v.trim()) throw new ConfigError('baseUrl is required');
  let u: URL;
  try {
    u = new URL(v.trim());
  } catch {
    throw new ConfigError('baseUrl is not a valid URL');
  }
  if (u.username || u.password) throw new ConfigError('baseUrl must not contain credentials');
  if (u.search || u.hash) throw new ConfigError('baseUrl must not contain a query or fragment');
  // Local Functions emulator only: a local engine such as Ollama on http://localhost:11434.
  const localDev = process.env.FUNCTIONS_EMULATOR === 'true' && /^(localhost|127\.0\.0\.1)$/.test(u.hostname);
  if (localDev) return u.toString().replace(/\/+$/, '');
  if (u.protocol !== 'https:') throw new ConfigError('baseUrl must use https (expose a local engine through an https tunnel)');
  if (PRIVATE_HOST.some((re) => re.test(u.hostname))) throw new ConfigError('baseUrl host is not allowed');
  return u.toString().replace(/\/+$/, '');
}

const num = (v: unknown, min: number, max: number, field: string): number | undefined => {
  if (v === undefined || v === null || v === '') return undefined;
  const n = Number(v);
  if (!Number.isFinite(n) || n < min || n > max) throw new ConfigError(`${field} must be between ${min} and ${max}`);
  return n;
};
const text = (v: unknown, max: number, field: string): string | undefined => {
  if (v === undefined || v === null || v === '') return undefined;
  if (typeof v !== 'string') throw new ConfigError(`${field} must be text`);
  const t = v.trim();
  if (t.length > max) throw new ConfigError(`${field} is too long (max ${max})`);
  return t || undefined;
};
const lines = (v: unknown, maxItems: number, maxLen: number, field: string): string[] | undefined => {
  if (v === undefined || v === null) return undefined;
  if (!Array.isArray(v) || v.length > maxItems) throw new ConfigError(`${field}: at most ${maxItems} items`);
  return v.map((x, i) => text(x, maxLen, `${field}[${i}]`)).filter((x): x is string => !!x);
};

/** Secret key name of a provider (several providers may share one). */
export const keyNameOf = (p: ProviderConfig) => p.keyName || p.id;

export function validateProvider(raw: any, existing?: ProviderConfig): ProviderConfig {
  const id = String(raw?.id ?? '');
  if (!PROVIDER_ID.test(id)) throw new ConfigError('id must be 2-40 characters: a-z, 0-9, _');
  if (!PROVIDER_TYPES.includes(raw?.type)) throw new ConfigError('Unknown provider type');
  if (raw.type === 'mock' && !isMockAllowed()) throw new ConfigError('The mock provider is only allowed in test projects');
  const type = raw.type as ProviderConfig['type'];
  const needsUrl = type === 'openai_compatible' || type === 'qwen_mt' || type === 'qwen_tts';
  const p: ProviderConfig = {
    id,
    type,
    label: text(raw.label, 80, 'label') ?? id,
    enabled: raw.enabled !== false,
    ...(needsUrl ? { baseUrl: validateBaseUrl(raw.baseUrl) } : {}),
    ...(text(raw.model, 100, 'model') ? { model: text(raw.model, 100, 'model') } : {}),
    minConsentVersion: num(raw.minConsentVersion, 0, 100, 'minConsentVersion') ?? 0,
  };
  if (needsUrl && !p.model) throw new ConfigError('model is required');
  if (raw.options !== undefined && raw.options !== null) {
    if (typeof raw.options !== 'object' || Array.isArray(raw.options)) throw new ConfigError('options must be an object');
    if (JSON.stringify(raw.options).length > 8000) throw new ConfigError('options too large');
    p.options = raw.options;
  }
  const keyName = text(raw.keyName, 40, 'keyName') ?? existing?.keyName;
  if (keyName) {
    if (!PROVIDER_ID.test(keyName)) throw new ConfigError('keyName must be 2-40 characters: a-z, 0-9, _');
    p.keyName = keyName;
  }
  return p;
}

export function validateRules(raw: any): CapabilityRules {
  if (!raw || typeof raw !== 'object') return {};
  const r: CapabilityRules = {
    maxOutputChars: num(raw.maxOutputChars, 20, 4000, 'maxOutputChars'),
    maxInputChars: num(raw.maxInputChars, 20, 8000, 'maxInputChars'),
    maxTokens: num(raw.maxTokens, 16, 4096, 'maxTokens'),
    temperature: num(raw.temperature, 0, 2, 'temperature'),
    timeoutMs: num(raw.timeoutMs, 1000, 60_000, 'timeoutMs'),
    retries: num(raw.retries, 0, 3, 'retries'),
    styleRules: lines(raw.styleRules, 20, 300, 'styleRules'),
    bannedTerms: lines(raw.bannedTerms, 200, 60, 'bannedTerms'),
    stripMarkdown: raw.stripMarkdown === undefined ? undefined : raw.stripMarkdown === true,
    stripLinks: raw.stripLinks === undefined ? undefined : raw.stripLinks === true,
    domainHint: text(raw.domainHint, 500, 'domainHint'),
    contextMessages: num(raw.contextMessages, 2, 40, 'contextMessages'),
    contextChars: num(raw.contextChars, 300, 12_000, 'contextChars'),
    memoryMaxFacts: num(raw.memoryMaxFacts, 0, 50, 'memoryMaxFacts'),
    memoryEvery: num(raw.memoryEvery, 0, 50, 'memoryEvery'),
    summaryEvery: num(raw.summaryEvery, 0, 100, 'summaryEvery'),
    summaryMaxChars: num(raw.summaryMaxChars, 100, 2000, 'summaryMaxChars'),
    checkInsEnabled: raw.checkInsEnabled === undefined ? undefined : raw.checkInsEnabled === true,
    checkInAfterHours: num(raw.checkInAfterHours, 1, 24 * 14, 'checkInAfterHours'),
    checkInStartHour: num(raw.checkInStartHour, 0, 23, 'checkInStartHour'),
    checkInEndHour: num(raw.checkInEndHour, 1, 24, 'checkInEndHour'),
    checkInMaxUnanswered: num(raw.checkInMaxUnanswered, 0, 10, 'checkInMaxUnanswered'),
  };
  if (raw.glossary !== undefined && raw.glossary !== null) {
    if (!Array.isArray(raw.glossary) || raw.glossary.length > 200) throw new ConfigError('glossary: at most 200 terms');
    r.glossary = raw.glossary.map((g: any, i: number) => {
      const source = text(g?.source, 100, `glossary[${i}].source`);
      const target = text(g?.target, 100, `glossary[${i}].target`);
      if (!source || !target) throw new ConfigError(`glossary[${i}] needs source and target`);
      return { source, target };
    });
  }
  for (const k of Object.keys(r) as (keyof CapabilityRules)[]) if (r[k] === undefined) delete r[k];
  return r;
}

export function validateRoute(cap: Capability, raw: any, providers: Record<string, ProviderConfig>): RouteConfig {
  const chain = Array.isArray(raw?.chain) ? raw.chain.map(String) : [];
  if (chain.length > 5) throw new ConfigError(`${cap}: at most 5 providers in a chain`);
  if (new Set(chain).size !== chain.length) throw new ConfigError(`${cap}: a provider appears twice`);
  for (const id of chain) {
    const p = providers[id];
    if (!p) throw new ConfigError(`${cap}: unknown provider ${id}`);
    if (!TYPE_KINDS[p.type].includes(capabilityKind(cap))) {
      throw new ConfigError(`${cap}: provider ${id} (${p.type}) cannot do ${capabilityKind(cap)}`);
    }
  }
  return { enabled: raw?.enabled !== false, chain };
}

/** Fills missing capabilities / built-in providers so callers never see holes. */
export function normalizeConfig(raw: any): AiConfig {
  const d = defaultConfig();
  if (!raw || typeof raw !== 'object') return d;
  const providers: Record<string, ProviderConfig> = { ...d.providers };
  for (const [id, p] of Object.entries<any>(raw.providers ?? {})) {
    if (PROVIDER_ID.test(id) && p && PROVIDER_TYPES.includes(p.type) && (p.type !== 'mock' || isMockAllowed())) {
      providers[id] = { ...p, id };
    }
  }
  const routes = { ...d.routes };
  const rules = { ...d.rules };
  for (const cap of CAPABILITIES) {
    const r = raw.routes?.[cap];
    if (r && Array.isArray(r.chain)) {
      routes[cap] = { enabled: r.enabled !== false, chain: r.chain.filter((id: string) => providers[id]) };
    }
    if (raw.rules?.[cap] && typeof raw.rules[cap] === 'object') rules[cap] = { ...d.rules[cap], ...raw.rules[cap] };
  }
  return {
    version: Number(raw.version) || 0,
    providers,
    routes,
    rules,
    keys: raw.keys && typeof raw.keys === 'object' ? raw.keys : {},
    updatedAt: raw.updatedAt ?? null,
    updatedBy: raw.updatedBy ?? null,
  };
}

// --------------------------------------------------------------- load / cache

let cached: { at: number; config: AiConfig } | null = null;
let override: AiConfig | null = null;

/** Test hook: a fixed config (null = read Firestore again). */
export function _setConfig(c: AiConfig | null) {
  override = c;
  cached = null;
}
export function invalidateConfigCache() {
  cached = null;
}

export async function loadConfig(): Promise<AiConfig> {
  if (override) return override;
  if (cached && Date.now() - cached.at < TTL_MS) return cached.config;
  let config: AiConfig;
  try {
    const snap = await admin.firestore().doc(AI_CONFIG_DOC).get();
    config = normalizeConfig(snap.exists ? snap.data() : null);
  } catch (e: any) {
    // Never take the AI features down because the config read failed.
    console.warn('ai router: config read failed, using defaults', e?.code || e?.message || e);
    config = cached?.config ?? defaultConfig();
  }
  cached = { at: Date.now(), config };
  return config;
}
