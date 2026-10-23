/**
 * GreenGo Buddies: data model, plan limits and validation.
 *
 * Owner rules (2026-10-23):
 *  - Buddies per plan (effective tier): Free 1 (Base 1), Silver 3, Gold 5, Platinum 10.
 *  - Free Buddy REPLIES per UTC day, all Buddies together: Free / Base 10,
 *    Silver 30, Gold 50, Platinum 100. After that 1 coin per reply.
 *  - Messages the Buddy sends on its own (check-ins after inactivity) are
 *    never counted and never charged.
 *  - Replies are at most 200 characters (admin rule `text_buddies`), user
 *    messages at most 500.
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
export const FREE_REPLIES_PER_DAY: Record<EffectiveTier, number> = { FREE: 10, SILVER: 30, GOLD: 50, PLATINUM: 100, TEST: 100 };
export const COINS_PER_REPLY = 1;
export const USER_MESSAGE_MAX = 500;

export const ROLES = ['friend', 'expert', 'teacher', 'coach', 'conversation_partner', 'debate_partner'] as const;
export const TONES = ['warm', 'funny', 'calm', 'direct', 'formal', 'playful'] as const;
export const LEVELS = ['beginner', 'intermediate', 'expert'] as const;
export const CEFR = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'] as const;
export const LANGUAGES = ['en', 'de', 'es', 'fr', 'it', 'pt', 'pt_BR'] as const;
/** Drawn avatars shipped in the app (never photos, never real people). */
export const AVATARS = Array.from({ length: 24 }, (_, i) => `buddy_${String(i + 1).padStart(2, '0')}`);

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
}

export interface MemoryFact { id: string; text: string; at: number }

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
  if (need('avatar')) out.avatar = oneOf(raw.avatar, AVATARS, 'avatar');
  if (need('topic')) out.topic = oneOf(raw.topic, TOPIC_IDS, 'topic');
  if (need('role')) out.role = oneOf(raw.role, ROLES, 'role');
  if (need('tone')) out.tone = oneOf(raw.tone, TONES, 'tone');
  if (need('language')) out.language = oneOf(raw.language, LANGUAGES, 'language');
  if (need('level')) out.level = oneOf(raw.level, LEVELS, 'level');
  if (has('cefr')) out.cefr = raw.cefr === null ? null : oneOf(raw.cefr, CEFR, 'cefr');
  else if (!partial) out.cefr = null;
  if (has('checkInsEnabled')) {
    if (typeof raw.checkInsEnabled !== 'boolean') throw new BuddyInputError('Invalid checkInsEnabled');
    out.checkInsEnabled = raw.checkInsEnabled;
  } else if (!partial) {
    out.checkInsEnabled = true;
  }
  const allowed = new Set(['name', 'avatar', 'topic', 'role', 'tone', 'language', 'level', 'cefr', 'checkInsEnabled']);
  for (const k of Object.keys(raw ?? {})) if (!allowed.has(k)) throw new BuddyInputError(`Unknown field ${k}`);
  return out;
}

export const utcDay = (ms = Date.now()) => new Date(ms).toISOString().slice(0, 10).replace(/-/g, '');

export const LANGUAGE_NAMES: Record<Language, string> = {
  en: 'English', de: 'German', es: 'Spanish', fr: 'French', it: 'Italian', pt: 'European Portuguese', pt_BR: 'Brazilian Portuguese',
};
