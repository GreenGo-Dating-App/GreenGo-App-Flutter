/**
 * "AI services" switch (Profile > Account settings). The switch is the
 * AI-processing consent `consents/{uid}.ai_processing`, recorded through the
 * `recordConsent` callable with a timestamped `events` history. These tests
 * prove the SERVER enforces it, not only the app UI:
 *
 *  - OFF: aiAssist, synthesizeSpeech, translatePrivateText, translateMessage
 *    and batchTranslateMessages refuse with AI_CONSENT_REQUIRED and nothing is
 *    sent to Google; the support assistant leaves the chat to a human (no
 *    Anthropic call).
 *  - ON (again): the same calls work.
 *  - Every switch change is an auditable event (accepted + timestamp).
 *  - Rules: the owner can READ their own consent summary (to show the switch
 *    state across devices); nobody else can, and nobody can write it or read
 *    the event history from a client.
 *
 * Runs against the real Firestore + Auth + Storage emulators:
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "npx jest --config jest.security.config.js"
 * Only outbound HTTP (global fetch) is mocked.
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

// --- outbound HTTP mock ------------------------------------------------------
const fetchMock = jest.fn(async (url: any, init: any = {}) => {
  const u = String(url);
  const json = (status: number, body: any) => ({
    ok: status >= 200 && status < 300, status, json: async () => body, text: async () => JSON.stringify(body),
  });
  if (u.includes('generativelanguage.googleapis.com')) {
    return json(200, { candidates: [{ content: { parts: [{ text: JSON.stringify({ level: 'B1' }) }] } }] });
  }
  if (u.includes('texttospeech.googleapis.com')) {
    return json(200, { audioContent: Buffer.from('ID3fake-mp3').toString('base64') });
  }
  if (u.includes('translation.googleapis.com')) {
    const body = JSON.parse(init.body);
    return json(200, { data: { translations: body.q.map((q: string) => ({ translatedText: `[it] ${q}`, detectedSourceLanguage: 'en' })) } });
  }
  if (u.includes('translate.googleapis.com/translate_a')) {
    return json(200, [[['Ciao', 'Hello', null, null, 10]], null, 'en']);
  }
  if (u.includes('api.anthropic.com')) {
    return json(200, { content: [{ type: 'text', text: 'Happy to help!' }] });
  }
  return json(404, {});
});
(global as any).fetch = fetchMock;
const calls = (host: string) => fetchMock.mock.calls.filter((c) => String(c[0]).includes(host));

// --- helpers -----------------------------------------------------------------
const emuHost = () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host || !/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) {
    throw new Error('Refusing to run: FIRESTORE_EMULATOR_HOST is not a local emulator');
  }
  return host;
};

function emulatorRequest(method: string, path: string, headers: Record<string, string> = {}, body?: string) {
  const host = emuHost();
  return new Promise<{ status: number; body: string }>((resolve, reject) => {
    const req = http.request(
      { host: host.split(':')[0], port: Number(host.split(':')[1]), method, path, headers },
      (res) => {
        let data = '';
        res.on('data', (c) => { data += c; });
        res.on('end', () => resolve({ status: res.statusCode || 0, body: data }));
      });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

const clearAll = () => emulatorRequest('DELETE', `/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);

/** Unsigned ID token: the Firestore emulator accepts it and evaluates the rules as this user. */
function userToken(uid: string): string {
  const b64 = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b64({ alg: 'none', typ: 'JWT' })}.${b64({
    iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, sub: uid, user_id: uid,
    iat: now, exp: now + 3600, auth_time: now,
    email: `${uid}@example.com`, email_verified: true,
    firebase: { sign_in_provider: 'password', identities: {} },
  })}.`;
}
const docPath = (p: string) => `/v1/projects/${PROJECT}/databases/(default)/documents/${p}`;
const clientGet = (uid: string, p: string) =>
  emulatorRequest('GET', docPath(p), { Authorization: `Bearer ${userToken(uid)}` });
const clientPatch = (uid: string, p: string, fields: any) =>
  emulatorRequest('PATCH', docPath(p), { Authorization: `Bearer ${userToken(uid)}`, 'Content-Type': 'application/json' },
    JSON.stringify({ fields }));

const gw = () => require('../../src/ai/aiGateway');
const tr = () => require('../../src/messaging/translation');
const support = () => require('../../src/admin/adminPanelFunctions');

const callV2 = (fn: any, data: any, uid?: string) =>
  (fft.wrap(fn) as any)({ data, auth: uid ? { uid, token: { email: `${uid}@example.com` } } : undefined });
const callV1 = (fn: any, data: any, uid?: string) =>
  (fft.wrap(fn) as any)(data, { auth: uid ? { uid, token: { email: `${uid}@example.com` } } : undefined, rawRequest: {} });

/** What the app's "AI services" switch sends (AiConsentService -> recordConsent). */
const setAiServices = (uid: string, on: boolean) =>
  callV2(gw().recordConsent, { type: 'ai_processing', version: 1, accepted: on, locale: 'en', platform: 'web' }, uid);

const AI_OFF = { code: 'permission-denied', details: { code: 'AI_CONSENT_REQUIRED' } };

beforeEach(async () => {
  await clearAll();
  fetchMock.mockClear();
  await db.doc('app_config/api_keys').set({ gemini_api_key: 'AIzaG-test', cloud_tts_api_key: 'AIzaT-test' });
  gw()._resetKeyCache();
  gw()._setAccessTokenProvider(async () => 'ya29.test-token');
});
afterAll(() => fft.cleanup());

// ===========================================================================
describe('AI gateway callables follow the switch', () => {
  const assist = (uid: string) =>
    callV2(gw().aiAssist, { task: 'difficulty', text: 'Hello there', language: 'en' }, uid);
  const speak = (uid: string) =>
    callV2(gw().synthesizeSpeech, { text: 'Bom dia', language: 'pt_BR', isMale: false }, uid);
  const translate = (uid: string) =>
    callV2(gw().translatePrivateText, { texts: ['Hello'], target: 'it' }, uid);

  test('ON -> works; OFF -> refused with no Google call; ON again -> works', async () => {
    await setAiServices('u1', true);
    await expect(assist('u1')).resolves.toMatchObject({ success: true, result: { level: 'B1' } });
    await expect(translate('u1')).resolves.toMatchObject({ success: true });
    expect(calls('generativelanguage')).toHaveLength(1);
    expect(calls('translation.googleapis.com')).toHaveLength(1);

    await setAiServices('u1', false);
    fetchMock.mockClear();
    await expect(assist('u1')).rejects.toMatchObject(AI_OFF);
    await expect(speak('u1')).rejects.toMatchObject(AI_OFF);
    await expect(translate('u1')).rejects.toMatchObject(AI_OFF);
    expect(fetchMock).not.toHaveBeenCalled();

    await setAiServices('u1', true);
    await expect(assist('u1')).resolves.toMatchObject({ success: true });
    await expect(speak('u1')).resolves.toMatchObject({ success: true });
  });

  test('switching OFF for one user does not affect another', async () => {
    await setAiServices('u1', false);
    await setAiServices('u2', true);
    await expect(assist('u1')).rejects.toMatchObject(AI_OFF);
    await expect(assist('u2')).resolves.toMatchObject({ success: true });
  });

  test('every switch change is an auditable, timestamped event', async () => {
    await setAiServices('u1', true);
    await setAiServices('u1', false);
    await setAiServices('u1', true);
    await setAiServices('u1', false);
    const summary = (await db.doc('consents/u1').get()).data()!;
    expect(summary.ai_processing).toMatchObject({ accepted: false, version: 1 });
    expect(summary.ai_processing.at).toBeInstanceOf(admin.firestore.Timestamp);
    const events = await db.collection('consents/u1/events').orderBy('at').get();
    expect(events.docs.map((d) => [d.data().type, d.data().accepted, d.data().platform]))
      .toEqual([['ai_processing', true, 'web'], ['ai_processing', false, 'web'],
        ['ai_processing', true, 'web'], ['ai_processing', false, 'web']]);
    events.docs.forEach((d) => expect(d.data().at).toBeInstanceOf(admin.firestore.Timestamp));
  });
});

// ===========================================================================
describe('message translation callables (private chat text) follow the switch', () => {
  beforeEach(async () => {
    await db.doc('conversations/c1').set({ participants: ['u1', 'u2'], userId1: 'u1', userId2: 'u2' });
    await db.doc('conversations/c1/messages/m1').set({
      type: 'text', content: 'Hello', senderId: 'u2', sentAt: admin.firestore.Timestamp.now(),
    });
  });

  test('OFF (or never accepted): translateMessage and batchTranslateMessages refuse, nothing sent', async () => {
    await expect(callV1(tr().translateMessage, { messageId: 'm1', conversationId: 'c1', targetLanguage: 'it' }, 'u1'))
      .rejects.toMatchObject(AI_OFF);
    await setAiServices('u1', false);
    await expect(callV1(tr().translateMessage, { messageId: 'm1', conversationId: 'c1', targetLanguage: 'it' }, 'u1'))
      .rejects.toMatchObject(AI_OFF);
    await expect(callV1(tr().batchTranslateMessages, { conversationId: 'c1', targetLanguage: 'it' }, 'u1'))
      .rejects.toMatchObject(AI_OFF);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  test('ON: both work', async () => {
    await setAiServices('u1', true);
    await expect(callV1(tr().translateMessage, { messageId: 'm1', conversationId: 'c1', targetLanguage: 'it' }, 'u1'))
      .resolves.toMatchObject({ success: true, translatedContent: 'Ciao' });
    await expect(callV1(tr().batchTranslateMessages, { conversationId: 'c1', targetLanguage: 'it' }, 'u1'))
      .resolves.toMatchObject({ success: true, processed: 1 });
    expect(calls('translate.googleapis.com/translate_a').length).toBeGreaterThanOrEqual(2);
  });

  test('a non-participant is still refused first (no consent leak)', async () => {
    await setAiServices('u3', true);
    await expect(callV1(tr().translateMessage, { messageId: 'm1', conversationId: 'c1', targetLanguage: 'it' }, 'u3'))
      .rejects.toMatchObject({ code: 'permission-denied' });
    expect(fetchMock).not.toHaveBeenCalled();
  });
});

// ===========================================================================
describe('support assistant follows the switch', () => {
  const fire = (id: string, data: any) =>
    (fft.wrap(support().processAISupportMessage) as any)(
      fft.firestore.makeDocumentSnapshot(data, `support_messages/${id}`), { params: { messageId: id } });
  const msg = { conversationId: 's1', senderId: 'u1', senderType: 'user', content: 'How do I change my photo?' };

  beforeEach(async () => {
    await db.doc('environment_config/production').set({
      aiAgent: { enabled: true, claudeApiKey: 'sk-test', escalateAfterMessages: 50 },
    });
    await db.doc('support_chats/s1').set({ userId: 'u1' });
    await db.doc('support_messages/a').set(msg);
  });

  test('OFF: no AI reply (left for a human agent), no Anthropic call', async () => {
    await setAiServices('u1', false);
    await fire('a', msg);
    expect(calls('api.anthropic.com')).toHaveLength(0);
    const replies = await db.collection('support_messages').where('senderId', '==', 'ai-agent').get();
    expect(replies.size).toBe(0);
    const logs = await db.collection('ai_support_logs').get();
    expect(logs.docs.map((d) => d.data().status)).toEqual(['ai_consent_withdrawn']);
  });

  test('ON: the assistant answers', async () => {
    await setAiServices('u1', true);
    await fire('a', msg);
    expect(calls('api.anthropic.com')).toHaveLength(1);
    const replies = await db.collection('support_messages').where('senderId', '==', 'ai-agent').get();
    expect(replies.size).toBe(1);
  });
});

// ===========================================================================
describe('rules: consents/{uid}', () => {
  beforeEach(async () => {
    await setAiServices('u1', false);
  });

  test('LEGIT: the owner can read their own consent summary (switch state on any device)', async () => {
    const r = await clientGet('u1', 'consents/u1');
    expect(r.status).toBe(200);
    expect(JSON.parse(r.body).fields.ai_processing.mapValue.fields.accepted).toEqual({ booleanValue: false });
  });

  test('ATTACK: another user cannot read it', async () => {
    expect((await clientGet('u2', 'consents/u1')).status).toBe(403);
  });

  test('ATTACK: nobody can write it or read the event history from a client', async () => {
    const forged = { ai_processing: { mapValue: { fields: { accepted: { booleanValue: true }, version: { integerValue: '1' } } } } };
    expect((await clientPatch('u1', 'consents/u1', forged)).status).toBe(403);
    expect((await clientPatch('u1', 'consents/u1/events/x', { accepted: { booleanValue: true } })).status).toBe(403);
    const events = await db.collection('consents/u1/events').limit(1).get();
    expect((await clientGet('u1', `consents/u1/events/${events.docs[0].id}`)).status).toBe(403);
    expect((await db.doc('consents/u1').get()).data()!.ai_processing.accepted).toBe(false);
  });
});
