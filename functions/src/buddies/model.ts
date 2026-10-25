/**
 * GreenGo Buddies: data model, plan limits and validation.
 *
 * Owner rules (2026-10-23):
 *  - Buddies per plan (effective tier): Free 1 (Base 1), Silver 3, Gold 5, Platinum 10.
 *  - Free Buddy REPLIES per UTC day, all Buddies together: Free / Base 10,
 *    Silver 30, Gold 50, Platinum 100. After that 1 coin per 3 replies (~0.33 each).
 *  - Messages the Buddy sends on its own (check-ins after inactivity) are
 *    never counted and never charged.
 *  - Replies are at most 200 characters per bubble (1-3 bubbles per turn),
 *    user messages at most 200.
 *
 * Firestore (new, separate collections; never conversations / groups):
 *   ai_buddies/{uid}/buddies/{buddyId}                settings + state
 *   ai_buddies/{uid}/buddies/{buddyId}/messages/{id}  { role, text, kind, charged, createdAt }
 *   ai_buddy_usage/{uid}_{yyyymmdd}                   free replies used today (server-only, TTL)
 *   ai_buddy_requests/{uid}_{requestId}               idempotency of sendBuddyMessage (server-only, TTL)
 */
import { EffectiveTier } from '../shared/effectiveTier';
import { TOPIC_IDS } from './topics';

export const BUDDIES = 'ai_buddies';
export const BUDDY_USAGE = 'ai_buddy_usage';
export const BUDDY_REQUESTS = 'ai_buddy_requests';

export const BUDDY_LIMIT: Record<EffectiveTier, number> = { FREE: 1, SILVER: 3, GOLD: 5, PLATINUM: 10, TEST: 10 };
/**
 * Owner 2026-10-24: no free Buddy replies any more (users get coins all the
 * time, so every reply is paid with coins). Kept as a table so a free
 * allowance can come back per plan without code changes elsewhere.
 */
export const FREE_REPLIES_PER_DAY: Record<EffectiveTier, number> = { FREE: 0, SILVER: 0, GOLD: 0, PLATINUM: 0, TEST: 0 };
/**
 * Owner 2026-10-24 (revised): 1 coin buys 3 paid reply turns (~0.33 coins
 * each; a turn = the Buddy's 1-3 messages). Balances stay integers.
 */
export const REPLIES_PER_COIN = 3;
export const COINS_PER_REPLY = Math.round(100 / REPLIES_PER_COIN) / 100;
/** Owner 2026-10-24: user messages to a Buddy are at most 200 characters (like the replies). */
export const USER_MESSAGE_MAX = 200;

export const ROLES = ['friend', 'expert', 'teacher', 'coach', 'conversation_partner', 'debate_partner'] as const;
export const TONES = ['warm', 'funny', 'calm', 'direct', 'formal', 'playful'] as const;
export const LEVELS = ['beginner', 'intermediate', 'expert'] as const;
export const CEFR = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'] as const;
export const LANGUAGES = ['en', 'de', 'es', 'fr', 'it', 'pt', 'pt_BR'] as const;
/** Legacy code-drawn avatars (still accepted for Buddies created before 2026-10-24). */
export const AVATARS = Array.from({ length: 24 }, (_, i) => `buddy_${String(i + 1).padStart(2, '0')}`);
/**
 * Avatar images people pick from (owner 2026-10-24): `buddy_avatars/{id}`
 * { url, label, order, active } in Firestore, images in our Storage
 * (illustrations, never photos of real people). Buddies have no profile.
 */
export const BUDDY_AVATARS = 'buddy_avatars';
export const AVATAR_ID = /^[A-Za-z0-9_-]{1,64}$/;
/** Defaults now that the builder only asks category, language and tone. */
export const DEFAULT_ROLE: Role = 'friend';
export const DEFAULT_LEVEL: Level = 'intermediate';

export type Role = typeof ROLES[number];
export type Tone = typeof TONES[number];
export type Level = typeof LEVELS[number];
export type Language = typeof LANGUAGES[number];

export interface BuddySettings {
  name: string;
  avatar: string;
  topic: string;
  role: Role;
  tone: Tone;
  language: Language;
  level: Level;
  cefr: string | null;
  checkInsEnabled: boolean;
  /**
   * Owner 2026-10-24: the language this chat is translated into, chosen at
   * creation and fixed. The server translates every message once into it.
   */
  chatLanguage: Language;
  /**
   * Owner 2026-10-25: the language the USER writes in, chosen at creation and
   * fixed. A user message in it is not translated when it already is the
   * chatLanguage, and it is the translation source (no detection).
   */
  userLanguage: Language;
  /**
   * Owner 2026-10-25: where the user wants to go (travel topics, see
   * DESTINATION_TOPICS): a short place name the Buddy builds the chat
   * around. Editable; null when not given.
   */
  destination?: string | null;
}

/** Travel topics that ask where the user wants to go (owner 2026-10-25). */
export const DESTINATION_TOPICS: ReadonlySet<string> = new Set([
  'city_guides', 'budget_travel', 'backpacking', 'road_trips', 'local_food_travel',
  'packing', 'solo_travel', 'travel_phrases', 'nature_trips',
]);

/**
 * A destination: 1-60 visible characters, letters / digits / space and
 * , . ' - ( ) only (a place name, never instructions); '' / null = none.
 */
export function cleanDestination(v: unknown): string | null {
  if (v === null || v === undefined) return null;
  if (typeof v !== 'string') throw new BuddyInputError('Invalid destination');
  const s = v.normalize('NFC').trim().replace(/\s+/g, ' ');
  if (!s) return null;
  if (Array.from(s).length > 60 || !/^[\p{L}\p{M}\p{N} ,.'()-]+$/u.test(s)) throw new BuddyInputError('Invalid destination');
  return s;
}

export interface MemoryFact { id: string; text: string; at: number; /** The user's exact words the fact is based on. */ evidence?: string }

export class BuddyInputError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'BuddyInputError';
  }
}

const oneOf = <T extends string>(v: unknown, list: readonly T[], field: string): T => {
  if (typeof v !== 'string' || !(list as readonly string[]).includes(v)) throw new BuddyInputError(`Invalid ${field}`);
  return v as T;
};

/** Name: 1-24 visible characters, letters / digits / space / . ' - only. */
export function cleanName(v: unknown): string {
  if (typeof v !== 'string') throw new BuddyInputError('Invalid name');
  const s = v.normalize('NFC').trim().replace(/\s+/g, ' ');
  if (!s || Array.from(s).length > 24 || !/^[\p{L}\p{N} .'-]+$/u.test(s)) throw new BuddyInputError('Invalid name');
  return s;
}

/** Full settings for create; [partial] = only the given keys for update. */
export function validateSettings(raw: any, partial = false): Partial<BuddySettings> {
  const out: Partial<BuddySettings> = {};
  const has = (k: string) => raw && Object.prototype.hasOwnProperty.call(raw, k) && raw[k] !== undefined;
  const need = (k: string) => {
    if (!partial && !has(k)) throw new BuddyInputError(`${k} is required`);
    return has(k);
  };
  if (need('name')) out.name = cleanName(raw.name);
  if (need('avatar')) {
    // An id from buddy_avatars (existence is checked by the callable) or a legacy drawn avatar.
    if (typeof raw.avatar !== 'string' || !AVATAR_ID.test(raw.avatar)) throw new BuddyInputError('Invalid avatar');
    out.avatar = raw.avatar;
  }
  if (need('topic')) out.topic = oneOf(raw.topic, TOPIC_IDS, 'topic');
  // Role and level are optional since 2026-10-24 (builder: category, language, tone).
  if (has('role')) out.role = oneOf(raw.role, ROLES, 'role');
  else if (!partial) out.role = DEFAULT_ROLE;
  if (need('tone')) out.tone = oneOf(raw.tone, TONES, 'tone');
  if (need('language')) out.language = oneOf(raw.language, LANGUAGES, 'language');
  if (has('level')) out.level = oneOf(raw.level, LEVELS, 'level');
  else if (!partial) out.level = DEFAULT_LEVEL;
  if (has('cefr')) out.cefr = raw.cefr === null ? null : oneOf(raw.cefr, CEFR, 'cefr');
  else if (!partial) out.cefr = null;
  if (has('chatLanguage')) out.chatLanguage = oneOf(raw.chatLanguage, LANGUAGES, 'chatLanguage');
  else if (!partial) out.chatLanguage = out.language;
  if (has('userLanguage')) out.userLanguage = oneOf(raw.userLanguage, LANGUAGES, 'userLanguage');
  else if (!partial) out.userLanguage = out.chatLanguage;
  if (has('destination') || (raw && raw.destination === null)) out.destination = cleanDestination(raw.destination);
  if (has('checkInsEnabled')) {
    if (typeof raw.checkInsEnabled !== 'boolean') throw new BuddyInputError('Invalid checkInsEnabled');
    out.checkInsEnabled = raw.checkInsEnabled;
  } else if (!partial) {
    out.checkInsEnabled = true;
  }
  const allowed = new Set(['name', 'avatar', 'topic', 'role', 'tone', 'language', 'chatLanguage', 'userLanguage', 'destination', 'level', 'cefr', 'checkInsEnabled']);
  for (const k of Object.keys(raw ?? {})) if (!allowed.has(k)) throw new BuddyInputError(`Unknown field ${k}`);
  return out;
}

export const utcDay = (ms = Date.now()) => new Date(ms).toISOString().slice(0, 10).replace(/-/g, '');

export const LANGUAGE_NAMES: Record<Language, string> = {
  en: 'English', de: 'German', es: 'Spanish', fr: 'French', it: 'Italian', pt: 'European Portuguese', pt_BR: 'Brazilian Portuguese',
};
