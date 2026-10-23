/**
 * AI router types (2026-10, "GreenGo Buddies + switchable AI providers").
 *
 * Features ask the router for a CAPABILITY ("translate_chat", "text_buddies"
 * ...), never for a provider. Which provider serves a capability, with which
 * fallbacks and which context rules, is configured by a superAdmin in the
 * admin panel (`ai_config/main`, server-only). API keys are NEVER in that
 * doc: they live in Secret Manager (see ./secrets.ts).
 */

export const CAPABILITIES = [
  'translate_chat', // private chat text (consent required)
  'translate_public', // shared / public texts, community tips (no personal data)
  'text_assist', // chat helpers: smart replies, grammar, cultural tips ...
  'text_buddies', // GreenGo Buddies replies
  'tts', // text to speech
] as const;
export type Capability = typeof CAPABILITIES[number];

export type CapabilityKind = 'translate' | 'text' | 'tts';
export const capabilityKind = (c: Capability): CapabilityKind =>
  c.startsWith('translate') ? 'translate' : c === 'tts' ? 'tts' : 'text';

export const PROVIDER_TYPES = [
  'openai_compatible', // Qwen (DashScope compatible-mode), OpenAI, DeepSeek, vLLM ...
  'qwen_mt', // Qwen-MT translation (compatible-mode + translation_options)
  'qwen_tts', // Qwen TTS (DashScope multimodal-generation)
  'qwen_audio_tts', // Qwen-Audio TTS 3.x (DashScope WebSocket, CosyVoice protocol)
  'gemini', // Google Gemini generateContent
  'google_translate_v2', // official Cloud Translation v2 (service account, no key)
  'google_free', // unofficial free Google Translate endpoint (no key)
  'google_tts', // Google Cloud Text-to-Speech (Chirp 3 HD)
  'mock', // canned key-free answers for tests (never in production, see mock.ts)
] as const;
export type ProviderType = typeof PROVIDER_TYPES[number];

/** Which capability kinds a provider type can serve. */
export const TYPE_KINDS: Record<ProviderType, CapabilityKind[]> = {
  openai_compatible: ['text', 'translate'],
  qwen_mt: ['translate'],
  qwen_tts: ['tts'],
  qwen_audio_tts: ['tts'],
  gemini: ['text'],
  google_translate_v2: ['translate'],
  google_free: ['translate'],
  google_tts: ['tts'],
  mock: ['text', 'translate', 'tts'],
};

/** Types that need an API key (the Google ones may fall back to legacy keys). */
export const TYPE_NEEDS_KEY: Record<ProviderType, boolean> = {
  openai_compatible: true,
  qwen_mt: true,
  qwen_tts: true,
  qwen_audio_tts: true,
  gemini: true,
  google_translate_v2: false,
  google_free: false,
  google_tts: true,
  mock: false,
};

export interface ProviderConfig {
  /** Slug [a-z0-9_]{2,40}. */
  id: string;
  label: string;
  type: ProviderType;
  enabled: boolean;
  /** https base URL (openai_compatible / qwen_*). */
  baseUrl?: string;
  model?: string;
  /**
   * Lowest `consents/{uid}.ai_processing.version` whose notice names this
   * provider. Users with an older acceptance are routed to the next provider
   * in the chain (0 = no requirement, e.g. public texts / Google).
   */
  minConsentVersion?: number;
  /** Type-specific options (voices, json mode, extra request params). */
  options?: Record<string, unknown>;
  /**
   * Name of the API key this provider uses (Secret Manager secret
   * AI_KEY_<KEYNAME upper>). Several providers can share one key, e.g. every
   * Qwen model uses the same DashScope key "dashscope". Defaults to the id.
   */
  keyName?: string;
}

/** Key metadata only: the key itself is in Secret Manager. */
export interface KeyInfo {
  last4: string;
  setAt: string;
  setBy: string;
}

export interface RouteConfig {
  enabled: boolean;
  /** Provider ids in order: primary first, then fallbacks. */
  chain: string[];
}

export interface Glossary { source: string; target: string }

/** Per-capability context rules (admin-editable; the safety block is not). */
export interface CapabilityRules {
  /** Hard cap on the reply, enforced on the server by grapheme. */
  maxOutputChars?: number;
  maxInputChars?: number;
  maxTokens?: number;
  temperature?: number;
  timeoutMs?: number;
  /** Extra attempts on the SAME provider before moving down the chain. */
  retries?: number;
  /** Lines added to the system prompt (tone, length, format...). */
  styleRules?: string[];
  /** Case-insensitive words/phrases: a reply containing one is rejected. */
  bannedTerms?: string[];
  stripMarkdown?: boolean;
  stripLinks?: boolean;
  /** Translation: terms that must be translated a fixed way (or kept). */
  glossary?: Glossary[];
  /** Translation: English domain/style hint (Qwen-MT `domains`). */
  domainHint?: string;
  // --- conversation memory / context budget (text_buddies) ---
  /** Most recent messages sent with each reply (older ones live in the summary). */
  contextMessages?: number;
  /** Character budget for those recent messages (oldest dropped first). */
  contextChars?: number;
  /** Long-term memory facts kept per Buddy (oldest/least important dropped). */
  memoryMaxFacts?: number;
  /** Re-extract memory facts every N user messages (0 = off). */
  memoryEvery?: number;
  /** Fold older messages into the rolling summary every N messages (0 = off). */
  summaryEvery?: number;
  summaryMaxChars?: number;
  // --- proactive check-ins (text_buddies) ---
  checkInsEnabled?: boolean;
  /** Hours since the user's last message before a check-in. */
  checkInAfterHours?: number;
  /** Local hours [start, end) in which a check-in may be sent. */
  checkInStartHour?: number;
  checkInEndHour?: number;
  /** Stop checking in after this many unanswered check-ins. */
  checkInMaxUnanswered?: number;
}

export interface AiConfig {
  version: number;
  providers: Record<string, ProviderConfig>;
  routes: Record<Capability, RouteConfig>;
  rules: Record<Capability, CapabilityRules>;
  /** keyName -> metadata of the saved key (no secret). */
  keys: Record<string, KeyInfo>;
  updatedAt?: string | null;
  updatedBy?: string | null;
}

// ---------------------------------------------------------------- calls

export interface ChatMessage { role: 'user' | 'assistant'; content: string }

export interface GenerateRequest {
  /** System prompt (the router prepends the fixed safety block for buddies). */
  system?: string;
  messages: ChatMessage[];
  /** The caller parses JSON out of the reply. */
  json?: boolean;
  /** Overrides of the capability rules for this call (e.g. max tokens). */
  maxTokens?: number;
}

export interface GenerateResult {
  text: string;
  providerId: string;
  model: string;
  /** Characters cut by the rules engine (0 = untouched). */
  truncated: number;
}

export interface TranslateItem {
  text: string;
  detectedLanguage: string | null;
  sameLanguage: boolean;
}

export interface TranslateResult {
  items: (TranslateItem | null)[];
  /** Provider that produced each item (null = not translated). */
  providers: (string | null)[];
}

export interface TtsRequest { text: string; language: string; isMale: boolean }
export interface TtsResult {
  audio: Buffer;
  contentType: string;
  extension: string;
  voice: string;
  providerId: string;
}

/** Context passed to every routed call. */
export interface CallContext {
  /** The caller's accepted AI-consent version (0 = none / not needed). */
  consentVersion: number;
}

export class ProviderError extends Error {
  constructor(message: string, readonly status = 0, readonly transient = true) {
    super(message);
    this.name = 'ProviderError';
  }
}
