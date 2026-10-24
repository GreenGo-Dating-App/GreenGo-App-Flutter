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
  AVATARS, BUDDY_LIMIT, BuddyInputError, BuddySettings, COINS_PER_REPLY, FREE_REPLIES_PER_DAY, LANGUAGES, REPLIES_PER_COIN, validateSettings,
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
  it('1 coin buys 3 paid replies (~0.33 coins each)', () => {
    expect(REPLIES_PER_COIN).toBe(3);
    expect(COINS_PER_REPLY).toBeCloseTo(0.33);
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

// ------------------------------------------------- 1-3 messages per turn
import { parseBuddyReply } from '../buddies';
import { conversationBlock, replyFormatBlock } from '../prompt';

describe('multi-message replies', () => {
  const rules = DEFAULT_RULES.text_buddies;
  it('keeps at most 2 cleaned messages', () => {
    const r = parseBuddyReply(JSON.stringify({ messages: ['**Ciao!**', 'Come stai?', 'E Roma?'], keywords: [] }), rules, 'FB');
    expect(r.messages).toEqual(['Ciao!', 'Come stai?']);
  });
  it('plain text (no JSON) is one message, cut to 200 chars', () => {
    const r = parseBuddyReply('x '.repeat(200), rules, 'FB');
    expect(r.messages).toHaveLength(1);
    expect(r.messages[0].length).toBeLessThanOrEqual(200);
  });
  it('replaces an unsafe message and keeps only keywords that appear in the text', () => {
    const r = parseBuddyReply(JSON.stringify({
      messages: ['Il Colosseo a Roma è stupendo!', 'Parliamo di sesso'],
      keywords: [{ type: 'attraction', name: 'Colosseo' }, { type: 'city', name: 'Roma' }, { type: 'city', name: 'Paris' }, { type: 'bad', name: 'x' }],
    }), rules, 'FB');
    expect(r.messages).toEqual(['Il Colosseo a Roma è stupendo!', 'FB']);
    expect(r.keywords).toEqual([{ type: 'attraction', name: 'Colosseo' }, { type: 'city', name: 'Roma' }]);
  });
  it('the prompt asks for curiosity, teaching on learning topics and the JSON format', () => {
    expect(conversationBlock(settings({ topic: 'practice_italian' }))).toMatch(/teacher/);
    expect(conversationBlock(settings({ topic: 'movies', role: 'friend' }))).not.toMatch(/teacher/);
    expect(conversationBlock(settings({ topic: 'movies', role: 'friend' }))).toMatch(/genuinely interested/);
    expect(replyFormatBlock(200)).toMatch(/"messages"/);
  });
});

// ------------------------------------------- never truncated + accurate memory
import { splitIntoBubbles, verifyMemoryFacts } from '../buddies';

describe('never truncated bubbles', () => {
  it('splits a long message at sentence ends without losing words', () => {
    const long = 'Lisbon is wonderful in spring. ' .repeat(12).trim();
    const b = splitIntoBubbles(long, 200);
    expect(b.length).toBeGreaterThan(1);
    b.forEach((x) => expect(x.length).toBeLessThanOrEqual(200));
    expect(b.join(' ')).toBe(long);
    expect(b.join(' ')).not.toMatch(/…/);
  });
  it('continues a very long sentence in the next bubble at a word boundary', () => {
    const s = Array.from({ length: 70 }, (_, i) => `word${i}`).join(' ');
    const b = splitIntoBubbles(s, 200);
    expect(b.join(' ')).toBe(s);
    b.forEach((x) => expect(x.length).toBeLessThanOrEqual(200));
  });
  it('salvages complete messages from a reply cut off mid-JSON and never shows raw JSON', () => {
    const cut = '{"messages": ["Ciao! Va bene, grazie. Sono felice di sentirti, come stai oggi?", "Come sono andate le tue giornate ultimamente?';
    const r = parseBuddyReply(cut, DEFAULT_RULES.text_buddies, 'FB');
    expect(r.messages).toEqual(['Ciao! Va bene, grazie. Sono felice di sentirti, come stai oggi?']);
    expect(parseBuddyReply('{"messages": [', DEFAULT_RULES.text_buddies, 'FB').messages).toEqual(['FB']);
  });
  it('at most 2 bubbles per turn', () => {
    const r = parseBuddyReply(JSON.stringify({ messages: ['A. '.repeat(90), 'B', 'C', 'D'] }), DEFAULT_RULES.text_buddies, 'FB');
    expect(r.messages.length).toBeLessThanOrEqual(2);
  });
});

describe('memory is 100% accurate', () => {
  const user = ['Ciao! Io corro una maratona a maggio', 'Lavoro come architetto a Lisbona'];
  it('keeps facts whose evidence is the user\'s exact words and drops invented ones', () => {
    const facts = verifyMemoryFacts([
      { fact: 'Running a marathon in May', evidence: 'corro una maratona a maggio' },
      { fact: 'Works as an architect in Lisbon', evidence: 'Lavoro come architetto a Lisbona' },
      { fact: 'Loves pizza', evidence: 'adoro la pizza' },
      { fact: 'Has two kids', evidence: '' },
      'plain string fact',
    ], user, [], 20);
    expect(facts.map((f) => f.text)).toEqual(['Running a marathon in May', 'Works as an architect in Lisbon']);
    expect(facts[0].evidence).toBe('corro una maratona a maggio');
  });
  it('keeps an already verified fact when its evidence is unchanged', () => {
    const prev = [{ id: 'x', text: 'Running a marathon in May', evidence: 'corro una maratona a maggio', at: 1 }];
    const facts = verifyMemoryFacts([{ fact: 'Running a marathon in May', evidence: 'corro una maratona a maggio' }], ['other text'], prev, 20);
    expect(facts).toHaveLength(1);
    expect(facts[0].at).toBe(1);
  });
});

describe('stray JSON / tags in a message', () => {
  it('drops a message that is JSON and keeps its keywords; strips tag fragments', () => {
    const r = parseBuddyReply(JSON.stringify({
      messages: ['</> Il Colosseo è a Roma.', '{"keywords": [{"type": "city", "name": "Roma"}]}'],
    }), DEFAULT_RULES.text_buddies, 'FB');
    expect(r.messages).toEqual(['Il Colosseo è a Roma.']);
    expect(r.keywords).toEqual([{ type: 'city', name: 'Roma' }]);
  });
  it('user messages and replies are at most 200 characters', () => {
    expect(DEFAULT_RULES.text_buddies.maxInputChars).toBe(200);
  });
});
