/**
 * GreenGo Buddies: catalogue, settings validation, plan limits, crisis and
 * output safety screens, prompts and the check-in eligibility rule.
 */
jest.mock('firebase-admin', () => {
  const firestoreFn: any = () => ({});
  firestoreFn.FieldValue = { increment: (n: number) => ({ inc: n }), serverTimestamp: () => 'TS' };
  firestoreFn.Timestamp = { now: () => 'NOW', fromMillis: (n: number) => n };
  return { apps: [{}], initializeApp: jest.fn(), firestore: firestoreFn, storage: () => ({}), auth: () => ({}), messaging: () => ({}) };
});

import { TOPICS, TOPIC_IDS, TOPIC_GROUPS } from '../topics';
import {
  AVATARS, BUDDY_LIMIT, BuddyInputError, BuddySettings, FREE_REPLIES_PER_DAY, LANGUAGES, validateSettings,
} from '../model';
import { CRISIS_REPLY, FALLBACK_REPLY, isCrisis, isUnsafeReply } from '../crisis';
import { checkInPrompt, memoryPrompt, parseJsonObject, systemPrompt } from '../prompt';
import { checkInDecision, msUntilWindow } from '../buddies';
import { DEFAULT_RULES } from '../../ai/router/config';

const settings = (o: Partial<BuddySettings> = {}): BuddySettings => ({
  name: 'Luna', avatar: AVATARS[0], topic: 'practice_italian', role: 'teacher', tone: 'warm', language: 'it',
  level: 'beginner', cefr: 'A2', checkInsEnabled: true, ...o,
});

describe('topic catalogue', () => {
  it('has about 120 unique topics in 12 groups', () => {
    expect(TOPICS.length).toBeGreaterThanOrEqual(115);
    expect(new Set(TOPIC_IDS).size).toBe(TOPIC_IDS.length);
    expect(new Set(TOPICS.map((t) => t.group))).toEqual(new Set(TOPIC_GROUPS));
    for (const t of TOPICS) {
      expect(t.id).toMatch(/^[a-z0-9_]+$/);
      expect(t.brief.length).toBeGreaterThan(10);
    }
  });

  it('contains nothing romantic, sexual, about real people or professional advice', () => {
    const forbidden = /romance|romantic|dating|date\b|girlfriend|boyfriend|flirt|sex|adult (content|role)|erotic|celebrit|famous person|diagnos|treatment|prescri|investment advice|legal advice/i;
    for (const t of TOPICS) {
      const text = `${t.id} ${t.brief}`.replace(/no investment advice|never investment|no medical advice|no therapy or medical advice|no diets or medical advice/gi, '');
      expect(`${t.id}: ${forbidden.test(text)}`).toBe(`${t.id}: false`);
    }
  });

  it('flags money / health / legal adjacent topics with a disclaimer', () => {
    const byId = new Map(TOPICS.map((t) => [t.id, t]));
    expect(byId.get('economics_basics')?.disclaimer).toBe('money');
    expect(byId.get('sleep_habits')?.disclaimer).toBe('health');
    expect(byId.get('moving_abroad')?.disclaimer).toBe('legal');
  });
});

describe('plan limits (owner rules 2026-10-23)', () => {
  it('Buddies per plan', () => {
    expect(BUDDY_LIMIT).toMatchObject({ FREE: 1, SILVER: 3, GOLD: 5, PLATINUM: 10 });
  });
  it('free replies per day: Free/Base 10, Silver 30, Gold 50, Platinum 100', () => {
    expect(FREE_REPLIES_PER_DAY).toMatchObject({ FREE: 10, SILVER: 30, GOLD: 50, PLATINUM: 100 });
  });
  it('replies are capped at 200 characters by default', () => {
    expect(DEFAULT_RULES.text_buddies.maxOutputChars).toBe(200);
  });
});

describe('validateSettings', () => {
  it('accepts a full valid Buddy and defaults check-ins on', () => {
    const { checkInsEnabled, ...rest } = settings();
    void checkInsEnabled;
    expect(validateSettings(rest)).toMatchObject({ ...rest, checkInsEnabled: true });
  });
  it.each([
    [{ name: '' }], [{ name: 'x'.repeat(25) }], [{ name: 'Luna<script>' }], [{ avatar: '../photo.jpg' }],
    [{ topic: 'romance' }], [{ role: 'girlfriend' }], [{ tone: 'flirty' }], [{ language: 'ru' }], [{ level: 'god' }],
    [{ cefr: 'D1' }], [{ isAdmin: true }],
  ])('rejects %j', (bad) => {
    expect(() => validateSettings({ ...settings(), ...bad })).toThrow(BuddyInputError);
  });
  it('role and level are optional (builder asks category, language, tone)', () => {
    const { role, level, cefr, checkInsEnabled, ...rest } = settings();
    void role; void level; void cefr; void checkInsEnabled;
    expect(validateSettings({ ...rest, avatar: 'avatar_fox' })).toMatchObject({ role: 'friend', level: 'intermediate', avatar: 'avatar_fox' });
  });
  it('partial updates only validate the given keys', () => {
    expect(validateSettings({ tone: 'funny' }, true)).toEqual({ tone: 'funny' });
    expect(() => validateSettings({ memory: [] }, true)).toThrow(BuddyInputError);
  });
});

describe('crisis detection', () => {
  it.each([
    'I want to kill myself', 'sometimes I want to die', 'voglio morire', 'quiero morirme', 'je veux mourir',
    'ich will sterben', 'quero morrer', 'pensei em suicídio',
  ])('detects %s', (t) => expect(isCrisis(t)).toBe(true));
  it.each(['I died laughing at that joke', 'this pizza is killer', 'quero morar em Lisboa', 'Ciao, come stai?'])(
    'ignores %s', (t) => expect(isCrisis(t)).toBe(false));
  it('has a caring reply with a helpline in every language', () => {
    for (const l of LANGUAGES) {
      expect(CRISIS_REPLY[l]).toMatch(/\d{3}/);
      expect(FALLBACK_REPLY[l].length).toBeLessThanOrEqual(200);
    }
  });
});

describe('output safety screen (always positive, nothing sexual / dark)', () => {
  it.each(['Let us talk about sex', 'una foto nuda', 'conteúdo erótico', 'Ich bin nackt', 'that was pure gore', 'self-harm tips'])(
    'blocks %s', (t) => expect(isUnsafeReply(t, null)).toBe(true));
  it.each(['Até sexta-feira! Bom fim de semana 😊', 'I visited Essex last year', 'Un nuevo día', 'Numero uno!', 'Che bella giornata!'])(
    'lets %s through', (t) => expect(isUnsafeReply(t, null)).toBe(false));
  it('blocks a reply flagged by the admin banned terms', () => {
    expect(isUnsafeReply('anything', 'term')).toBe(true);
  });
});

describe('prompts', () => {
  const rules = DEFAULT_RULES.text_buddies;
  it('system prompt: safety, positivity, identity, language, length, memory', () => {
    const s = systemPrompt(settings(), rules, [{ id: 'a', text: 'Training for a marathon in May', at: 1 }], 'They talked about Rome.');
    expect(s).toMatch(/NOT a dating app/);
    expect(s).toMatch(/positive, warm, kind/);
    expect(s).toMatch(/never claim or pretend to be human/i);
    expect(s).toMatch(/"Luna", a patient teacher/);
    expect(s).toMatch(/You speak ONLY Italian/);
    expect(s).toMatch(/Never switch to another language/);
    expect(s).toMatch(/CEFR A2/);
    expect(s).toMatch(/at most 200 characters/);
    expect(s).toMatch(/Training for a marathon in May/);
    expect(s).toMatch(/They talked about Rome/);
  });
  it('pt_BR Buddies speak Brazilian Portuguese', () => {
    expect(systemPrompt(settings({ language: 'pt_BR' }), rules, [], '')).toMatch(/You speak ONLY Brazilian Portuguese/);
  });
  it('health topics carry the disclaimer', () => {
    expect(systemPrompt(settings({ topic: 'sleep_habits' }), rules, [], '')).toMatch(/general information only/);
  });
  it('check-in asks ONE specific question from memory, no guilt after silence', () => {
    const p = checkInPrompt(settings(), rules, [{ id: 'a', text: 'Has a job interview on Friday', at: 1 }], '',
      [{ role: 'user', content: 'wish me luck!' }], 30, 1);
    expect(p.user).toMatch(/ONE specific open question/);
    expect(p.user).toMatch(/no guilt/);
    expect(p.user).toMatch(/wish me luck/);
    expect(p.system).toMatch(/Has a job interview on Friday/);
  });
  it('memory prompt never stores sensitive data', () => {
    expect(memoryPrompt([], [{ role: 'user', content: 'hi' }], 20)).toMatch(/NEVER store: health/);
  });
  it('parses JSON with fences or chatter', () => {
    expect(parseJsonObject('```json\n{"facts":["a"]}\n```')).toEqual({ facts: ['a'] });
    expect(parseJsonObject('Sure! {"summary":"x"} done')).toEqual({ summary: 'x' });
    expect(parseJsonObject('nope')).toBeNull();
  });
});

describe('check-in eligibility', () => {
  const base = {
    nowMs: Date.UTC(2026, 9, 23, 12, 0), unanswered: 0, maxUnanswered: 3, userCheckInDay: null,
    tzOffsetMinutes: 0, startHour: 9, endHour: 21,
  };
  it('sends in local daytime', () => expect(checkInDecision(base)).toEqual({ action: 'send' }));
  it('stops after 3 unanswered check-ins', () => expect(checkInDecision({ ...base, unanswered: 3 })).toEqual({ action: 'stop' }));
  it('at most one check-in per user per day', () => {
    expect(checkInDecision({ ...base, userCheckInDay: '20261023' }).action).toBe('later');
  });
  it('waits for the local morning (UTC-5 at 12:00 UTC = 07:00 local)', () => {
    const d = checkInDecision({ ...base, tzOffsetMinutes: -300 });
    expect(d.action).toBe('later');
    expect(msUntilWindow(base.nowMs, -300, 9, 21)).toBe(2 * 3600_000);
  });
  it('late evening waits for tomorrow morning', () => {
    expect(msUntilWindow(Date.UTC(2026, 9, 23, 22, 30), 0, 9, 21)).toBe(10.5 * 3600_000);
  });
});
