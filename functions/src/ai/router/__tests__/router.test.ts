/**
 * AI router: rules engine (grapheme cutter, markdown/link stripping, banned
 * terms, context budget), config validation (SSRF guard, chains), consent
 * gating per provider, fallback down the chain, partial translation
 * fallback, Secret Manager keys and per-model usage counters.
 */
jest.mock('firebase-admin', () => {
  const firestoreFn: any = () => ({});
  firestoreFn.FieldValue = { increment: (n: number) => ({ inc: n }), serverTimestamp: () => 'TS' };
  firestoreFn.Timestamp = { now: () => 'NOW', fromMillis: (n: number) => n };
  return { apps: [{}], initializeApp: jest.fn(), firestore: firestoreFn, storage: () => ({}), auth: () => ({}), messaging: () => ({}), credential: {} };
});

import { _setConfig, defaultConfig, qwenPreset, validateBaseUrl, validateRoute, validateRules, ConfigError } from '../config';
import { applyReplyRules, cutToLimit, fitContext, graphemeLength, stripMarkdown, findBanned } from '../rules';
import { eligibleChain, generate, translate, speak, NoProviderError } from '../router';
import { _setSecretStore } from '../secrets';
import { _setUsageSink, UsageEvent } from '../usage';
import { _setAccessTokenProvider } from '../http';
import { AiConfig } from '../types';

const fetchMock = jest.fn();
(global as any).fetch = fetchMock;
const usage: UsageEvent[] = [];
const keys = new Map<string, string>();

const json = (body: any, status = 200) => ({ ok: status < 400, status, json: async () => body });
const chat = (content: string) => json({ choices: [{ message: { content } }] });

function qwenConfig(): AiConfig {
  const c = qwenPreset(defaultConfig());
  return c;
}

beforeEach(() => {
  fetchMock.mockReset();
  usage.length = 0;
  keys.clear();
  keys.set('AI_KEY_DASHSCOPE', 'sk-test-1234');
  _setUsageSink((e) => usage.push(e));
  _setSecretStore({
    read: async (n) => keys.get(n) ?? null,
    write: async (n, v) => { keys.set(n, v); },
    remove: async (n) => { keys.delete(n); },
  });
  _setAccessTokenProvider(async () => 'ya29.token');
  _setConfig(qwenConfig());
});

// ------------------------------------------------------------------ rules

describe('cutToLimit', () => {
  it('keeps short text untouched (exactly at the limit too)', () => {
    expect(cutToLimit('Hi there!', 200)).toBe('Hi there!');
    const exact = 'a'.repeat(200);
    expect(cutToLimit(exact, 200)).toBe(exact);
  });

  it('cuts at the last sentence end inside the budget', () => {
    const s = 'First sentence is here. Second one is also fine! Third sentence would go over the limit for sure';
    expect(cutToLimit(s, 60)).toBe('First sentence is here. Second one is also fine!');
  });

  it('falls back to a word boundary with an ellipsis', () => {
    const out = cutToLimit('word '.repeat(60).trim(), 50);
    expect(graphemeLength(out)).toBeLessThanOrEqual(50);
    expect(out.endsWith('…')).toBe(true);
    expect(out).not.toMatch(/wor…$/);
  });

  it('never splits emoji or accented letters (counts graphemes)', () => {
    const family = '👨‍👩‍👧‍👦';
    const s = `${family} ${'é'.repeat(10)} ${family}${family}${family}`;
    const out = cutToLimit(s, 14);
    expect(graphemeLength(out)).toBeLessThanOrEqual(14);
    // No broken ZWJ sequence or lone combining mark.
    expect(out.normalize('NFC')).toBe(out.normalize('NFC'));
    expect(out).not.toMatch(/‍$/);
  });

  it('handles empty text', () => {
    expect(cutToLimit('', 10)).toBe('');
  });
});

describe('applyReplyRules', () => {
  it('strips markdown and links, tidies, cuts and flags banned terms', () => {
    const r = applyReplyRules('**Hello** _friend_!\n\n\n- see https://x.y/z now\n# Title', {
      stripMarkdown: true, stripLinks: true, maxOutputChars: 200, bannedTerms: ['TITLE'],
    });
    expect(r.text).toBe('Hello friend!\nsee now\nTitle');
    expect(r.banned).toBe('TITLE');
    expect(r.truncated).toBe(0);
  });

  it('reports how much was cut', () => {
    const r = applyReplyRules('x'.repeat(250), { maxOutputChars: 200 });
    expect(graphemeLength(r.text)).toBeLessThanOrEqual(200);
    expect(r.truncated).toBeGreaterThan(0);
  });

  it('finds banned terms ignoring accents and case', () => {
    expect(findBanned('Vamos num ENCONTRO romântico', ['romantico'])).toBe('romantico');
    expect(findBanned('nothing here', ['x-rated'])).toBeNull();
  });

  it('removes code fences and list markers', () => {
    expect(stripMarkdown('1. one\n2. two\n```js\ncode\n```')).toBe('one\ntwo\n ');
  });
});

describe('fitContext', () => {
  const m = (n: number, len = 10) => ({ role: 'user', content: String(n).padEnd(len, '.') });
  it('keeps the newest messages within count and char budget', () => {
    const msgs = [1, 2, 3, 4, 5].map((n) => m(n));
    expect(fitContext(msgs, 3, 1000).map((x) => x.content[0])).toEqual(['3', '4', '5']);
    expect(fitContext(msgs, 10, 25).map((x) => x.content[0])).toEqual(['4', '5']);
  });
  it('always keeps (a tail of) the last message', () => {
    const out = fitContext([m(1, 50)], 5, 20);
    expect(out).toHaveLength(1);
    expect(out[0].content).toHaveLength(20);
  });
});

// ----------------------------------------------------------------- config

describe('config validation', () => {
  it.each([
    'http://dashscope-us.aliyuncs.com',
    'https://localhost/v1',
    'https://127.0.0.1/v1',
    'https://10.1.2.3/v1',
    'https://169.254.169.254/latest',
    'https://metadata.google.internal/x',
    'https://user:pw@example.com/v1',
    'https://example.com/v1?key=1',
    'not a url',
  ])('rejects base URL %s', (u) => {
    expect(() => validateBaseUrl(u)).toThrow(ConfigError);
  });

  it('accepts the DashScope US endpoint', () => {
    expect(validateBaseUrl('https://dashscope-us.aliyuncs.com/compatible-mode/v1/')).toBe(
      'https://dashscope-us.aliyuncs.com/compatible-mode/v1');
  });

  it('rejects a chain with a provider that cannot serve the capability', () => {
    const c = qwenConfig();
    expect(() => validateRoute('tts', { chain: ['qwen_flash'] }, c.providers)).toThrow(/cannot do tts/);
    expect(() => validateRoute('text_buddies', { chain: ['qwen_flash', 'qwen_flash'] }, c.providers)).toThrow(/twice/);
    expect(validateRoute('tts', { chain: ['qwen_tts', 'google_tts'] }, c.providers).chain).toEqual(['qwen_tts', 'google_tts']);
  });

  it('validates rule ranges', () => {
    expect(() => validateRules({ maxOutputChars: 5 })).toThrow(ConfigError);
    expect(validateRules({ maxOutputChars: '200', styleRules: ['a', ''] })).toEqual({ maxOutputChars: 200, styleRules: ['a'] });
  });

  it('the Qwen preset shares one DashScope key and gates on consent v3', () => {
    const c = qwenConfig();
    for (const id of ['qwen_flash', 'qwen_mt_flash', 'qwen_tts', 'qwen_mt_public']) expect(c.providers[id].keyName).toBe('dashscope');
    expect(c.providers.qwen_flash.minConsentVersion).toBe(3);
    expect(c.providers.qwen_mt_public.minConsentVersion).toBe(0);
    expect(c.providers.qwen_flash.baseUrl).toContain('dashscope-intl.aliyuncs.com');
  });

  it('defaults reproduce the pre-router providers', () => {
    const d = defaultConfig();
    expect(d.routes.translate_chat.chain).toEqual(['google_v2']);
    expect(d.routes.translate_public.chain).toEqual(['google_free']);
    expect(d.routes.text_assist.chain).toEqual(['gemini']);
    expect(d.routes.tts.chain).toEqual(['google_tts']);
    expect(d.rules.text_buddies.maxOutputChars).toBe(200);
  });
});

// ----------------------------------------------------------------- router

describe('consent gating', () => {
  it('skips providers named only in a newer consent notice', () => {
    const c = qwenConfig();
    expect(eligibleChain(c, 'translate_chat', { consentVersion: 2 }).map((p) => p.id)).toEqual(['google_v2']);
    expect(eligibleChain(c, 'translate_chat', { consentVersion: 3 }).map((p) => p.id)).toEqual(['qwen_mt_flash', 'google_v2']);
    expect(eligibleChain(c, 'translate_public', { consentVersion: 0 }).map((p) => p.id)).toEqual(['qwen_mt_public', 'google_free']);
  });

  it('buddies have no provider without the Qwen consent', async () => {
    await expect(generate('text_buddies', { messages: [{ role: 'user', content: 'hi' }] }, { consentVersion: 2 }))
      .rejects.toBeInstanceOf(NoProviderError);
    expect(fetchMock).not.toHaveBeenCalled();
  });
});

describe('generate', () => {
  it('calls Qwen with the key from Secret Manager and applies the 200-char rule', async () => {
    fetchMock.mockResolvedValueOnce(chat(`**Ciao!** ${'parola '.repeat(60)}`));
    const r = await generate('text_buddies', { system: 'sys', messages: [{ role: 'user', content: 'hi' }] }, { consentVersion: 3 });
    expect(graphemeLength(r.text)).toBeLessThanOrEqual(200);
    expect(r.text.startsWith('Ciao!')).toBe(true);
    expect(r.providerId).toBe('qwen_flash');
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe('https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions');
    expect(init.headers.Authorization).toBe('Bearer sk-test-1234');
    const body = JSON.parse(init.body);
    expect(body.model).toBe('qwen-flash');
    expect(body.messages[0]).toEqual({ role: 'system', content: 'sys' });
    expect(usage[0]).toMatchObject({ capability: 'text_buddies', providerId: 'qwen_flash', ok: true, fallback: false });
  });

  it('falls back to Gemini for chat helpers when Qwen fails', async () => {
    process.env.GEMINI_API_KEY = 'gem-key';
    fetchMock
      .mockResolvedValueOnce(json({ error: 'x' }, 401))
      .mockResolvedValueOnce(json({ candidates: [{ content: { parts: [{ text: '{"level":"B1"}' }] } }] }));
    const r = await generate('text_assist', { messages: [{ role: 'user', content: 'p' }], json: true }, { consentVersion: 3 });
    expect(r.providerId).toBe('gemini');
    expect(r.text).toBe('{"level":"B1"}');
    expect(usage.map((u) => [u.providerId, u.ok, u.fallback])).toEqual([['qwen_flash', false, false], ['gemini', true, true]]);
    delete process.env.GEMINI_API_KEY;
  });

  it('fails cleanly without a key (no request sent)', async () => {
    keys.clear();
    _setConfig({ ...qwenConfig(), routes: { ...qwenConfig().routes, text_assist: { enabled: true, chain: ['qwen_flash'] } } });
    await expect(generate('text_assist', { messages: [{ role: 'user', content: 'p' }] }, { consentVersion: 3 }))
      .rejects.toThrow(/no API key/);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('never puts the key in the URL', async () => {
    fetchMock.mockResolvedValueOnce(chat('ok'));
    await generate('text_buddies', { messages: [{ role: 'user', content: 'x' }] }, { consentVersion: 3 });
    expect(String(fetchMock.mock.calls[0][0])).not.toContain('sk-test');
  });
});

describe('translate', () => {
  it('uses Qwen-MT with translation_options, glossary and the pt-BR hint', async () => {
    fetchMock.mockResolvedValueOnce(chat('Olá, tudo bem?'));
    const r = await translate('translate_chat', ['Hi, how are you?'], 'pt-BR', { consentVersion: 3 });
    expect(r.items[0]).toEqual({ text: 'Olá, tudo bem?', detectedLanguage: null, sameLanguage: false });
    expect(r.providers[0]).toBe('qwen_mt_flash');
    const body = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(body.model).toBe('qwen-mt-flash');
    expect(body.messages).toEqual([{ role: 'user', content: 'Hi, how are you?' }]);
    expect(body.translation_options).toMatchObject({ source_lang: 'auto', target_lang: 'Portuguese' });
    expect(body.translation_options.domains).toMatch(/Brazilian Portuguese/);
    expect(body.translation_options.terms).toEqual([{ source: 'GreenGo', target: 'GreenGo' }]);
  });

  it('marks unchanged output as same language', async () => {
    fetchMock.mockResolvedValueOnce(chat('ciao a tutti'));
    const r = await translate('translate_chat', ['Ciao a tutti'], 'it', { consentVersion: 3 });
    expect(r.items[0]).toMatchObject({ text: 'Ciao a tutti', sameLanguage: true });
  });

  it('sends only the texts Qwen could not translate to Google', async () => {
    fetchMock.mockImplementation(async (url: string, init: any) => {
      if (url.includes('dashscope')) {
        const text = JSON.parse(init.body).messages[0].content;
        return text === 'two' ? json({}, 500) : chat(`T:${text}`);
      }
      const q = JSON.parse(init.body).q;
      return json({ data: { translations: q.map((t: string) => ({ translatedText: `G:${t}`, detectedSourceLanguage: 'en' })) } });
    });
    const r = await translate('translate_chat', ['one', 'two', 'three'], 'it', { consentVersion: 3 });
    expect(r.items.map((x) => x?.text)).toEqual(['T:one', 'G:two', 'T:three']);
    expect(r.providers).toEqual(['qwen_mt_flash', 'google_v2', 'qwen_mt_flash']);
    const googleCall = fetchMock.mock.calls.find(([u]) => String(u).includes('translation.googleapis.com'));
    expect(JSON.parse(googleCall![1].body).q).toEqual(['two']);
    expect(usage.find((u) => u.providerId === 'qwen_mt_flash')).toMatchObject({ items: 2, ok: true });
    expect(usage.find((u) => u.providerId === 'google_v2')).toMatchObject({ items: 1, ok: true, fallback: true });
  });

  it('returns nulls when every provider fails', async () => {
    fetchMock.mockResolvedValue(json({}, 503));
    const r = await translate('translate_chat', ['a'], 'it', { consentVersion: 3 });
    expect(r.items).toEqual([null]);
  });
});

describe('speak', () => {
  it('downloads the Qwen TTS audio and reports wav', async () => {
    fetchMock
      .mockResolvedValueOnce(json({ output: { audio: { url: 'https://dashscope-result.example/a.wav?Expires=1' } } }))
      .mockResolvedValueOnce({ ok: true, status: 200, arrayBuffer: async () => new Uint8Array([1, 2, 3]).buffer });
    const r = await speak('tts', { text: 'Ciao', language: 'it', isMale: false }, { consentVersion: 3 });
    expect(r).toMatchObject({ contentType: 'audio/wav', extension: 'wav', voice: 'qwen:Cherry', providerId: 'qwen_tts' });
    expect(r.audio.length).toBe(3);
    const body = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(body).toEqual({ model: 'qwen3-tts-flash', input: { text: 'Ciao', voice: 'Cherry', language_type: 'Italian' } });
    expect(fetchMock.mock.calls[0][0]).toBe('https://dashscope-intl.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation');
  });

  it('lets Google speak a language Qwen TTS does not support', async () => {
    process.env.CLOUD_TTS_API_KEY = 'tts-key';
    fetchMock.mockResolvedValueOnce(json({ audioContent: Buffer.from('mp3').toString('base64') }));
    const r = await speak('tts', { text: 'नमस्ते', language: 'hi', isMale: true }, { consentVersion: 3 });
    expect(r).toMatchObject({ providerId: 'google_tts', contentType: 'audio/mpeg' });
    expect(fetchMock).toHaveBeenCalledTimes(1);
    delete process.env.CLOUD_TTS_API_KEY;
  });
});

// ------------------------------------------------------------------- mock
import { isMockAllowed, mockGenerate, mockSpeak, mockTranslate } from '../mock';
import { mockPreset, validateProvider } from '../config';
import { applyReplyRules as applyRules, graphemeLength as glen } from '../rules';

describe('mock provider (test projects only)', () => {
  const saved = process.env.GCLOUD_PROJECT;
  afterEach(() => { process.env.GCLOUD_PROJECT = saved; });

  it('is refused in production', () => {
    process.env.GCLOUD_PROJECT = 'greengo-chat';
    expect(isMockAllowed()).toBe(false);
    expect(() => mockGenerate({ messages: [{ role: 'user', content: 'hi' }] })).toThrow(/production/);
    expect(() => validateProvider({ id: 'mock', type: 'mock' })).toThrow(/test projects/);
    expect(() => mockPreset(defaultConfig())).toThrow(/test projects/);
  });

  it('answers every capability in a test project, no key and no network', async () => {
    process.env.GCLOUD_PROJECT = 'greengo-chat-test';
    _setConfig(mockPreset(defaultConfig()));
    const g = await generate('text_buddies', { system: 'Always reply in Italian.', messages: [{ role: 'user', content: 'Ciao!' }] }, { consentVersion: 0 });
    expect(g.providerId).toBe('mock');
    expect(g.text).toMatch(/^(Che bello|Fantastico|Ottimo)/);
    expect(glen(g.text)).toBeLessThanOrEqual(200);
    expect(applyRules(g.text, { bannedTerms: [] }).banned).toBeNull();
    const t = await translate('translate_chat', ['Hello'], 'pt-BR', { consentVersion: 0 });
    expect(t.items[0]?.text).toBe('[→pt-BR] Hello');
    const s = await speak('tts', { text: 'Ciao', language: 'it', isMale: false }, { consentVersion: 0 });
    expect(s.audio.subarray(0, 4).toString()).toBe('RIFF');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('returns valid JSON for memory, summary and chat-helper prompts', () => {
    process.env.GCLOUD_PROJECT = 'greengo-chat-test';
    const j = (content: string) => JSON.parse(mockGenerate({ messages: [{ role: 'user', content }], json: true }));
    expect(j('Current memory facts (JSON): ["Likes pizza"]\nReturn {"facts": [...]}').facts[0]).toBe('Likes pizza');
    expect(typeof j('Return {"summary": "..."}').summary).toBe('string');
    expect(j('Suggest exactly 3 short replies').replies).toHaveLength(3);
    expect(j('Assess the CEFR difficulty level').level).toBe('A2');
    expect(mockTranslate(['a'], 'it')[0].text).toBe('[→it] a');
    expect(mockSpeak().contentType).toBe('audio/wav');
  });
});

// ---------------------------------------------------- custom engine (Ollama)
describe('custom OpenAI-compatible engine without a key (e.g. Ollama)', () => {
  const ollama = (baseUrl = 'https://my-ollama.example.com/v1') => {
    const c = defaultConfig();
    c.providers.ollama = { id: 'ollama', label: 'Ollama', type: 'openai_compatible', enabled: true, baseUrl,
      model: 'qwen2.5:0.5b', minConsentVersion: 0, options: { noAuth: true } };
    c.routes.text_buddies = { enabled: true, chain: ['ollama'] };
    return c;
  };

  it('calls the engine with no Authorization header and no saved key', async () => {
    keys.clear();
    _setConfig(ollama());
    fetchMock.mockResolvedValueOnce(chat('Ciao! Come va?'));
    const r = await generate('text_buddies', { messages: [{ role: 'user', content: 'hi' }] }, { consentVersion: 0 });
    expect(r.providerId).toBe('ollama');
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe('https://my-ollama.example.com/v1/chat/completions');
    expect(init.headers.Authorization).toBeUndefined();
    expect(JSON.parse(init.body).model).toBe('qwen2.5:0.5b');
  });

  it('accepts http://localhost only inside the Functions emulator', () => {
    const prev = process.env.FUNCTIONS_EMULATOR;
    try {
      delete process.env.FUNCTIONS_EMULATOR;
      expect(() => validateBaseUrl('http://localhost:11434/v1')).toThrow(ConfigError);
      process.env.FUNCTIONS_EMULATOR = 'true';
      expect(validateBaseUrl('http://localhost:11434/v1/')).toBe('http://localhost:11434/v1');
      expect(() => validateBaseUrl('http://10.0.0.5:11434/v1')).toThrow(ConfigError);
    } finally {
      if (prev === undefined) delete process.env.FUNCTIONS_EMULATOR; else process.env.FUNCTIONS_EMULATOR = prev;
    }
  });
});

// --------------------------------------------- Qwen-Audio TTS over WebSocket
import { _setWsFactory, audioVoice, audioWsUrl } from '../qwenAudioTts';
import { providerLanguages, supportsLanguage } from '../languages';

describe('qwen_audio_tts (WebSocket)', () => {
  const provider = { id: 'qwen_audio_tts', label: 'QA', type: 'qwen_audio_tts' as const, enabled: true,
    baseUrl: 'https://dashscope-intl.aliyuncs.com', model: 'qwen-audio-3.1-tts-flash', keyName: 'dashscope', minConsentVersion: 0 };
  const sent: any[] = [];
  let headersSeen: Record<string, string> = {};
  let urlSeen = '';
  function fakeServer(mode: 'ok' | 'fail') {
    _setWsFactory((url, headers) => {
      urlSeen = url; headersSeen = headers;
      const ws: any = { binaryType: '', close: jest.fn() };
      ws.send = (data: string) => {
        const m = JSON.parse(data); sent.push(m);
        const a = m.header.action;
        setImmediate(() => {
          if (a === 'run-task') ws.onmessage({ data: JSON.stringify({ header: { event: 'task-started' } }) });
          if (a === 'finish-task') {
            if (mode === 'fail') return ws.onmessage({ data: JSON.stringify({ header: { event: 'task-failed', error_code: 'InvalidParameter' } }) });
            ws.onmessage({ data: new Uint8Array([0xff, 0xfb, 1]).buffer });
            ws.onmessage({ data: new Uint8Array([2, 3]).buffer });
            ws.onmessage({ data: JSON.stringify({ header: { event: 'task-finished' } }) });
          }
        });
      };
      setImmediate(() => ws.onopen({}));
      return ws;
    });
  }
  beforeEach(() => { sent.length = 0; });
  afterAll(() => _setWsFactory(null));

  it('runs run-task -> continue-task -> finish-task and joins the binary mp3 frames', async () => {
    fakeServer('ok');
    const c = defaultConfig();
    c.providers.qwen_audio_tts = provider;
    c.routes.tts = { enabled: true, chain: ['qwen_audio_tts', 'google_tts'] };
    _setConfig(c);
    const r = await speak('tts', { text: 'Hola a todos', language: 'es', isMale: false }, { consentVersion: 0 });
    expect(r).toMatchObject({ contentType: 'audio/mpeg', extension: 'mp3', voice: 'qwen:longanhuan_v3.1', providerId: 'qwen_audio_tts' });
    expect([...r.audio]).toEqual([0xff, 0xfb, 1, 2, 3]);
    expect(urlSeen).toBe('wss://dashscope-intl.aliyuncs.com/api-ws/v1/inference');
    expect(headersSeen.Authorization).toBe('bearer sk-test-1234');
    expect(sent.map((m) => m.header.action)).toEqual(['run-task', 'continue-task', 'finish-task']);
    expect(new Set(sent.map((m) => m.header.task_id)).size).toBe(1);
    expect(sent[0].payload).toMatchObject({ task: 'tts', function: 'SpeechSynthesizer', model: 'qwen-audio-3.1-tts-flash' });
    expect(sent[1].payload.input.text).toBe('Hola a todos');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('falls back to the next provider when the model refuses', async () => {
    fakeServer('fail');
    process.env.CLOUD_TTS_API_KEY = 'tts-key';
    fetchMock.mockResolvedValueOnce(json({ audioContent: Buffer.from('mp3').toString('base64') }));
    const c = defaultConfig();
    c.providers.qwen_audio_tts = provider;
    c.routes.tts = { enabled: true, chain: ['qwen_audio_tts', 'google_tts'] };
    _setConfig(c);
    const r = await speak('tts', { text: 'Ciao', language: 'it', isMale: true }, { consentVersion: 0 });
    expect(r.providerId).toBe('google_tts');
    delete process.env.CLOUD_TTS_API_KEY;
  });

  it('picks voices per language (English voices for en, multilingual for es/it, custom override)', () => {
    expect(audioVoice(provider, 'en', false)).toBe('Abby_v3.1');
    expect(audioVoice(provider, 'pt-BR', true)).toBe('xunanchuan_v3.1');
    expect(audioVoice(provider, 'es', false)).toBe('longanhuan_v3.1');
    expect(audioVoice({ ...provider, options: { voices: { it: { female: 'X_v3.1' } } } }, 'it', false)).toBe('X_v3.1');
    expect(audioVoice(provider, 'xx', false)).toBeNull();
    expect(audioWsUrl('https://dashscope-intl.aliyuncs.com/api/v1')).toBe('wss://dashscope-intl.aliyuncs.com/api-ws/v1/inference');
  });
});

describe('supported languages per model', () => {
  const p = (options?: any, model = 'qwen-mt-flash') => ({ id: 'x', label: 'x', type: 'qwen_mt' as const, enabled: true, model, options });
  it('shows vendor info, and an admin list overrides it', () => {
    expect(providerLanguages(p()).languages).toContain('pt-BR');
    expect(providerLanguages(p(undefined, 'unknown-model')).languages).toBeNull();
    expect(providerLanguages(p({ languages: ['it', 'pt_br'] })).languages).toEqual(['it', 'pt-BR']);
  });
  it('the router skips a provider only for languages an admin excluded', async () => {
    expect(supportsLanguage(p(), 'es')).toBe(true);
    expect(supportsLanguage(p({ languages: ['it', 'pt'] }), 'es')).toBe(false);
    expect(supportsLanguage(p({ languages: ['it', 'pt'] }), 'pt-BR')).toBe(true);
    const c = qwenConfig();
    c.providers.qwen_mt_flash = { ...c.providers.qwen_mt_flash, options: { languages: ['it'] } };
    _setConfig(c);
    fetchMock.mockResolvedValueOnce(json({ data: { translations: [{ translatedText: 'Hola', detectedSourceLanguage: 'en' }] } }));
    const r = await translate('translate_chat', ['Hi'], 'es', { consentVersion: 3 });
    expect(r.providers[0]).toBe('google_v2');
    expect(String(fetchMock.mock.calls[0][0])).toContain('translation.googleapis.com');
  });
});

describe('chat-model translation guards', () => {
  const { parseTranslationJson, plausibleTranslation } = require('../adapters');
  it('reads {"translation"} even with text or fences around it', () => {
    expect(parseTranslationJson('{"translation": "Ciao!"}')).toBe('Ciao!');
    expect(parseTranslationJson('```json\n{"translation":"Ciao"}\n```')).toBe('Ciao');
    expect(parseTranslationJson('Ciao!')).toBeNull();
    expect(parseTranslationJson('{"translation": ""}')).toBeNull();
  });
  it('rejects an "answer" that is far longer or shorter than the text', () => {
    const t = 'Naples is the home of pizza margherita! Have you ever tried a real one there?';
    expect(plausibleTranslation(t, 'Napoli è la patria della pizza margherita! Hai mai provato una vera pizza lì?')).toBe(true);
    expect(plausibleTranslation(t, 'Sì!')).toBe(false);
    expect(plausibleTranslation(t, t.repeat(4))).toBe(false);
    expect(plausibleTranslation('Hi!', 'Ciao a te, come stai oggi?')).toBe(true);
  });
});
