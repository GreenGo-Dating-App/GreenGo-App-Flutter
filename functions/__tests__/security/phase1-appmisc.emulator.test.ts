/**
 * Phase 1 "app misc": server-side AI gateway (C-08 follow-up, H-17, P2-10),
 * AI-processing consent record, neutral age gate (H-21 interim).
 *
 * Runs against the real Firestore + Auth + Storage emulators:
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "npx jest --config jest.security.config.js"
 *
 * Only the outbound Google / Unsplash calls (global fetch) are mocked. Source
 * modules are required lazily so this file also runs (and fails) against the
 * pre-change code.
 */

import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) {
  admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
}
const fft = functionsTest({ projectId: PROJECT });
const db = admin.firestore();
const auth = admin.auth();

const GEMINI_KEY = 'AIzaGEMINI-test-key-0001';
const TTS_KEY = 'AIzaTTS-test-key-0002';
const UNSPLASH_KEY = 'unsplash-test-key-0003';
const KEYS = [GEMINI_KEY, TTS_KEY, UNSPLASH_KEY];

// --- outbound HTTP mock ------------------------------------------------------
let geminiReply: any = { replies: ['Oi!', 'Tudo bem?', 'Legal'], translations: ['Hi!', 'All good?', 'Cool'] };
let geminiStatus = 200;
const fetchMock = jest.fn(async (url: any, init: any = {}) => {
  const u = String(url);
  const json = (status: number, body: any) => ({ ok: status >= 200 && status < 300, status, json: async () => body, text: async () => JSON.stringify(body) });
  if (u.includes('generativelanguage.googleapis.com')) {
    if (geminiStatus !== 200) {
      return json(geminiStatus, { error: { message: `API key ${GEMINI_KEY} quota exceeded` } });
    }
    return json(200, { candidates: [{ content: { parts: [{ text: JSON.stringify(geminiReply) }] } }] });
  }
  if (u.includes('texttospeech.googleapis.com')) {
    return json(200, { audioContent: Buffer.from('ID3fake-mp3').toString('base64') });
  }
  if (u.includes('translation.googleapis.com')) {
    const body = JSON.parse(init.body);
    return json(200, {
      data: {
        translations: body.q.map((q: string) => (q.startsWith('Hello')
          ? { translatedText: `[${body.target}] ${q}`, detectedSourceLanguage: 'en' }
          : { translatedText: q, detectedSourceLanguage: body.target })),
      },
    });
  }
  if (u.includes('api.unsplash.com')) {
    return json(200, { results: [{ urls: { small: 'https://img/s.jpg', thumb: 'https://img/t.jpg', regular: 'https://img/r.jpg' }, alt_description: 'a red car', user: { name: 'Ann', links: { html: 'https://u/ann' } } }] });
  }
  return json(404, {});
});
(global as any).fetch = fetchMock;
const calls = (host: string) => fetchMock.mock.calls.filter((c) => String(c[0]).includes(host));

// --- helpers -----------------------------------------------------------------
function emulatorDelete(path: string) {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  return new Promise<void>((resolve, reject) => {
    const req = http.request(
      { host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE', path },
      (res) => { res.resume(); res.on('end', resolve); });
    req.on('error', reject);
    req.end();
  });
}
async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host || !/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) {
    throw new Error('Refusing to run: FIRESTORE_EMULATOR_HOST is not a local emulator');
  }
  await emulatorDelete(`/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);
  const users = await auth.listUsers(1000);
  if (users.users.length) await auth.deleteUsers(users.users.map((u) => u.uid));
  await admin.storage().bucket().deleteFiles({ prefix: 'pronunciation_audio/', force: true }).catch(() => undefined);
}

const gw = () => require('../../src/ai/aiGateway');
const ag = () => require('../../src/auth/ageGate');
const call = (fn: any, data: any, uid?: string, token: any = {}) =>
  (fft.wrap(fn) as any)({ data, auth: uid ? { uid, token: { email: `${uid}@example.com`, ...token } } : undefined });
const consent = (uid: string, accepted = true, version = 1) =>
  call(gw().recordConsent, { type: 'ai_processing', version, accepted, locale: 'en', platform: 'android' }, uid);
const noKeys = (v: unknown) => KEYS.forEach((k) => expect(JSON.stringify(v ?? null)).not.toContain(k));

beforeEach(async () => {
  await clearAll();
  fetchMock.mockClear();
  geminiReply = { replies: ['Oi!', 'Tudo bem?', 'Legal'], translations: ['Hi!', 'All good?', 'Cool'] };
  geminiStatus = 200;
  delete process.env.AI_ASSIST_DAILY_LIMIT;
  delete process.env.AI_TTS_SYNTH_DAILY_LIMIT;
  delete process.env.AI_TRANSLATE_CHARS_DAILY_LIMIT;
  await db.doc('app_config/api_keys').set({ gemini_api_key: GEMINI_KEY, cloud_tts_api_key: TTS_KEY, unsplash_api_key: UNSPLASH_KEY });
  gw()._resetKeyCache();
});
afterAll(() => fft.cleanup());

// ===========================================================================
describe('recordConsent', () => {
  test('requires auth and a valid payload', async () => {
    await expect(call(gw().recordConsent, { type: 'ai_processing', version: 1, accepted: true })).rejects.toMatchObject({ code: 'unauthenticated' });
    await expect(call(gw().recordConsent, { type: 'marketing', version: 1, accepted: true }, 'u1')).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(call(gw().recordConsent, { type: 'ai_processing', version: 0, accepted: true }, 'u1')).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(call(gw().recordConsent, { type: 'ai_processing', version: 1, accepted: 'yes' }, 'u1')).rejects.toMatchObject({ code: 'invalid-argument' });
    expect((await db.collection('consents').get()).size).toBe(0);
  });

  test('stores the decision + an append-only event history', async () => {
    expect(await consent('u1', true)).toEqual({ success: true, type: 'ai_processing', version: 1, accepted: true });
    await consent('u1', false);
    const summary = (await db.doc('consents/u1').get()).data()!;
    expect(summary.ai_processing).toMatchObject({ accepted: false, version: 1, locale: 'en' });
    const events = await db.collection('consents/u1/events').orderBy('at').get();
    expect(events.docs.map((d) => d.data().accepted)).toEqual([true, false]);
  });
});

// ===========================================================================
describe('aiAssist (Gemini)', () => {
  const ask = (uid: string | undefined, data: any = {}) =>
    call(gw().aiAssist, { task: 'smartReplies', text: 'Bom dia, tudo bem?', language: 'pt', targetLanguage: 'pt', userLanguage: 'en', ...data }, uid);

  test('auth required; no Google call', async () => {
    await expect(ask(undefined)).rejects.toMatchObject({ code: 'unauthenticated' });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  test('consent required (none, or declined); no Google call', async () => {
    await expect(ask('u1')).rejects.toMatchObject({ code: 'permission-denied', details: { code: 'AI_CONSENT_REQUIRED' } });
    await consent('u1', false);
    await expect(ask('u1')).rejects.toMatchObject({ details: { code: 'AI_CONSENT_REQUIRED' } });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  test('works after consent; key only in a header, never in the URL or the response', async () => {
    await consent('u1');
    const r = await ask('u1');
    expect(r).toEqual({ success: true, task: 'smartReplies', result: { replies: ['Oi!', 'Tudo bem?', 'Legal'], translations: ['Hi!', 'All good?', 'Cool'] } });
    noKeys(r);
    const [url, init] = calls('generativelanguage')[0] as any[];
    expect(String(url)).not.toContain(GEMINI_KEY);
    expect(init.headers['x-goog-api-key']).toBe(GEMINI_KEY);
    // Only the message text + languages go out: no uid / email.
    expect(init.body).toContain('Bom dia, tudo bem?');
    expect(init.body).not.toMatch(/u1|example\.com/);
  });

  test('input caps and unknown task are rejected before any Google call', async () => {
    await consent('u1');
    await expect(ask('u1', { text: 'x'.repeat(1001) })).rejects.toMatchObject({ code: 'invalid-argument', details: { code: 'TEXT_TOO_LONG' } });
    await expect(ask('u1', { text: '   ' })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(ask('u1', { task: 'writeMyEssay' })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(ask('u1', { language: 'x'.repeat(41) })).rejects.toMatchObject({ code: 'invalid-argument' });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  test('per-user daily quota', async () => {
    process.env.AI_ASSIST_DAILY_LIMIT = '2';
    await consent('u1');
    await consent('u2');
    await ask('u1');
    await ask('u1');
    await expect(ask('u1')).rejects.toMatchObject({ code: 'resource-exhausted', details: { code: 'QUOTA_EXCEEDED' } });
    await expect(ask('u2')).resolves.toMatchObject({ success: true }); // per user
    expect(calls('generativelanguage')).toHaveLength(3);
  });

  test('provider error: generic "unavailable", provider body (with the key) not echoed', async () => {
    await consent('u1');
    geminiStatus = 429;
    let err: any;
    try { await ask('u1'); } catch (e) { err = e; }
    expect(err).toMatchObject({ code: 'unavailable' });
    noKeys({ m: err.message, d: err.details });
  });

  test('model output is validated per task', async () => {
    await consent('u1');
    geminiReply = { level: 'Z9' };
    expect((await ask('u1', { task: 'difficulty' })).result).toEqual({ level: 'A1' });
    geminiReply = { hasErrors: false, corrected: 'ok', explanation: '', extra: 'dropped' };
    expect((await ask('u1', { task: 'grammar' })).result).toEqual({ hasErrors: false, corrected: 'ok', explanation: '' });
    geminiReply = { nonsense: true };
    await expect(ask('u1', { task: 'romanize' })).rejects.toMatchObject({ code: 'unavailable' });
  });
});

// ===========================================================================
describe('synthesizeSpeech (Cloud TTS)', () => {
  const speak = (uid: string | undefined, data: any = {}) =>
    call(gw().synthesizeSpeech, { text: 'Bom dia', language: 'pt_BR', isMale: false, ...data }, uid);

  test('auth + consent + input cap', async () => {
    await expect(speak(undefined)).rejects.toMatchObject({ code: 'unauthenticated' });
    await expect(speak('u1')).rejects.toMatchObject({ details: { code: 'AI_CONSENT_REQUIRED' } });
    await consent('u1');
    await expect(speak('u1', { text: 'x'.repeat(501) })).rejects.toMatchObject({ details: { code: 'TEXT_TOO_LONG' } });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  test('miss: synthesizes once, fills the shared cache without the text; hit: no Google call', async () => {
    await consent('u1');
    await consent('u2');
    const r1 = await speak('u1');
    expect(r1).toMatchObject({ success: true, cached: false });
    expect(Buffer.from(r1.audioContent, 'base64').toString()).toBe('ID3fake-mp3');
    noKeys(r1);
    const [url, init] = calls('texttospeech')[0] as any[];
    expect(String(url)).not.toContain(TTS_KEY);
    expect(init.headers['x-goog-api-key']).toBe(TTS_KEY);
    expect(JSON.parse(init.body).voice).toEqual({ languageCode: 'pt-BR', name: 'pt-BR-Chirp3-HD-Kore' });

    const key = gw().ttsCacheKey('Bom dia', 'pt_BR', false);
    expect(key).toMatch(/^v6_pt-br_[0-9a-f]{40}_f$/);
    const doc = (await db.doc(`pronunciation_cache/${key}`).get()).data()!;
    expect(doc).toMatchObject({ generatedBy: 'server', storagePath: `pronunciation_audio/pt-br/${key}.mp3` });
    expect(JSON.stringify(doc)).not.toMatch(/Bom dia/i);
    const [exists] = await admin.storage().bucket().file(doc.storagePath).exists();
    expect(exists).toBe(true);

    // Same phrase (different spacing/case), another user: served from cache.
    const r2 = await speak('u2', { text: '  bom   DIA ' });
    expect(r2).toEqual({ success: true, cached: true, audioUrl: doc.audioUrl });
    expect(calls('texttospeech')).toHaveLength(1);
  });

  test('daily synthesis quota (cache hits are not synthesis)', async () => {
    process.env.AI_TTS_SYNTH_DAILY_LIMIT = '1';
    await consent('u1');
    await speak('u1', { text: 'one' });
    await expect(speak('u1', { text: 'two' })).rejects.toMatchObject({ code: 'resource-exhausted' });
    await expect(speak('u1', { text: 'one' })).resolves.toMatchObject({ cached: true });
  });
});

// ===========================================================================
describe('translatePrivateText (Cloud Translation)', () => {
  beforeEach(() => gw()._setAccessTokenProvider(async () => 'ya29.test-token'));
  const tr = (uid: string | undefined, data: any = {}) =>
    call(gw().translatePrivateText, { texts: ['Hello friend', 'Olá'], target: 'pt_BR', ...data }, uid);

  test('auth + consent + caps', async () => {
    await expect(tr(undefined)).rejects.toMatchObject({ code: 'unauthenticated' });
    await expect(tr('u1')).rejects.toMatchObject({ details: { code: 'AI_CONSENT_REQUIRED' } });
    await consent('u1');
    await expect(tr('u1', { texts: Array(26).fill('a') })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(tr('u1', { texts: ['x'.repeat(2001)] })).rejects.toMatchObject({ details: { code: 'TEXT_TOO_LONG' } });
    await expect(tr('u1', { target: 'klingon!!' })).rejects.toMatchObject({ code: 'invalid-argument' });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  test('translates through the official API; same-language text comes back as is', async () => {
    await consent('u1');
    const r = await tr('u1');
    expect(r).toEqual({
      success: true,
      target: 'pt-BR',
      translations: [
        { text: '[pt-BR] Hello friend', detectedLanguage: 'en', sameLanguage: false },
        { text: 'Olá', detectedLanguage: 'pt-BR', sameLanguage: true },
      ],
    });
    const [url, init] = calls('translation.googleapis.com')[0] as any[];
    expect(String(url)).toBe('https://translation.googleapis.com/language/translate/v2');
    expect(init.headers.Authorization).toBe('Bearer ya29.test-token');
  });

  test('daily character quota', async () => {
    process.env.AI_TRANSLATE_CHARS_DAILY_LIMIT = '20';
    await consent('u1');
    await tr('u1', { texts: ['Hello friend'] }); // 12
    await expect(tr('u1', { texts: ['Hello friend'] })).rejects.toMatchObject({ code: 'resource-exhausted' });
  });
});

// ===========================================================================
describe('getVocabularyImages', () => {
  test('auth required; key stays server-side; result cached', async () => {
    await expect(call(gw().getVocabularyImages, { word: 'car' })).rejects.toMatchObject({ code: 'unauthenticated' });
    const r = await call(gw().getVocabularyImages, { word: 'Car', language: 'en' }, 'u1');
    expect(r.images[0]).toMatchObject({ imageUrl: 'https://img/s.jpg', source: 'unsplash', attribution: 'Photo by Ann on Unsplash' });
    noKeys(r);
    const r2 = await call(gw().getVocabularyImages, { word: 'car', language: 'en' }, 'u2');
    expect(r2.cached).toBe(true);
    expect(calls('unsplash')).toHaveLength(1);
    await expect(call(gw().getVocabularyImages, { word: 'x'.repeat(61) }, 'u1')).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});

// ===========================================================================
describe('declareAge (neutral age gate)', () => {
  const ymd = (yearsAgo: number, dayShift = 0) => {
    const d = new Date();
    d.setUTCFullYear(d.getUTCFullYear() - yearsAgo);
    d.setUTCDate(d.getUTCDate() + dayShift);
    return d.toISOString().slice(0, 10);
  };
  const declare = (uid: string | undefined, dob: string, email?: string) =>
    call(ag().declareAge, { dob }, uid, email ? { email } : {});

  test('auth required; invalid / future dates rejected', async () => {
    await expect(declare(undefined, '2000-01-01')).rejects.toMatchObject({ code: 'unauthenticated' });
    await expect(declare('u1', '2000-02-30')).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(declare('u1', 'yesterday')).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(declare('u1', ymd(-1))).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  test('adult allowed (18th birthday today counts); nothing stored', async () => {
    expect(await declare('adult', ymd(18))).toEqual({ success: true, allowed: true });
    expect(await declare('adult2', '1980-05-01')).toEqual({ success: true, allowed: true });
    expect((await db.collection('age_gate').get()).size).toBe(0);
  });

  test('under 18 blocked; retrying with another date stays blocked; no DOB stored', async () => {
    expect(await declare('kid', ymd(18, 1))).toEqual({ success: true, allowed: false, reason: 'UNDER_18' });
    const gate = (await db.doc('age_gate/kid').get()).data()!;
    expect(gate).toMatchObject({ blocked: true, ageAtBlock: 17 });
    expect(JSON.stringify(gate)).not.toContain(ymd(18, 1));
    expect(await declare('kid', '1990-01-01')).toEqual({ success: true, allowed: false, reason: 'AGE_BLOCKED' });
  });

  test('a new account with the same email is blocked too', async () => {
    await declare('kid', ymd(15), 'Kid@Example.com');
    expect(await declare('kid-new-account', '1990-01-01', 'kid@example.com'))
      .toMatchObject({ allowed: false, reason: 'AGE_BLOCKED' });
  });

  test('an existing profile is hidden (accountStatus age_blocked)', async () => {
    await db.doc('profiles/kid').set({ displayName: 'K', accountStatus: 'active' });
    await declare('kid', ymd(14));
    expect((await db.doc('profiles/kid').get()).data()!.accountStatus).toBe('age_blocked');
  });
});

// ===========================================================================
describe('profile trigger backstop (reverseGeocodeProfileLocation)', () => {
  const trigger = () => require('../../src/admin/adminPanelFunctions').reverseGeocodeProfileLocation;
  const dobYearsAgo = (y: number) => admin.firestore.Timestamp.fromDate(new Date(Date.now() - y * 365.25 * 864e5));
  async function write(uid: string, before: any, after: any) {
    const ref = db.doc(`profiles/${uid}`);
    await ref.set(after);
    const b = before ? fft.firestore.makeDocumentSnapshot(before, `profiles/${uid}`) : fft.firestore.makeDocumentSnapshot({}, '');
    const a = fft.firestore.makeDocumentSnapshot(after, `profiles/${uid}`);
    await (fft.wrap(trigger()) as any)(fft.makeChange(b, a), { params: { userId: uid } });
    return (await ref.get()).data()!;
  }
  const loc = { location: { country: 'Italy', latitude: 1, longitude: 1 } };

  test('profile created with an under-18 DOB is blocked', async () => {
    const p = await write('kid', null, { ...loc, accountStatus: 'active', dateOfBirth: dobYearsAgo(16) });
    expect(p.accountStatus).toBe('age_blocked');
    expect((await db.doc('age_gate/kid').get()).data()).toMatchObject({ blocked: true, source: 'profile_trigger' });
  });

  test('adults, profiles without a DOB and unrelated updates are untouched', async () => {
    expect((await write('a1', null, { ...loc, accountStatus: 'active', dateOfBirth: dobYearsAgo(30) })).accountStatus).toBe('active');
    expect((await write('a2', null, { ...loc, accountStatus: 'active' })).accountStatus).toBe('active');
    // Legacy profile (even with a bad DOB) is not re-evaluated on an unrelated write.
    const legacy = { ...loc, accountStatus: 'active', dateOfBirth: dobYearsAgo(16), bio: 'a' };
    expect((await write('legacy', legacy, { ...legacy, bio: 'b' })).accountStatus).toBe('active');
    expect((await db.collection('age_gate').get()).size).toBe(0);
  });

  test('a DOB edited to under 18 is blocked; a gated account re-creating its profile is blocked', async () => {
    const adult = { ...loc, accountStatus: 'active', dateOfBirth: dobYearsAgo(30) };
    expect((await write('ed', adult, { ...adult, dateOfBirth: dobYearsAgo(12) })).accountStatus).toBe('age_blocked');
    await db.doc('age_gate/gated').set({ blocked: true });
    expect((await write('gated', null, { ...loc, accountStatus: 'active', dateOfBirth: dobYearsAgo(40) })).accountStatus).toBe('age_blocked');
  });
});
