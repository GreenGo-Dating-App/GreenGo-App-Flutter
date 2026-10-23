/**
 * "Mock AI" provider (owner request 2026-10-23): canned, key-free answers so
 * every AI screen can be tested end to end without a real model.
 *
 *  - text: a short, positive reply in the language the system prompt asks
 *    for (Buddies), or valid JSON for the JSON tasks (chat helpers, Buddy
 *    memory / summary), always under the 200-character rule.
 *  - translate: "[→it] original text".
 *  - tts: a 0.4 s soft test tone (WAV).
 *
 * NEVER in production: refused when the project is greengo-chat (config
 * validation, the preset and this adapter all check isMockAllowed()).
 */
import { GenerateRequest, ProviderError, TranslateItem, TtsResult } from './types';

export const PRODUCTION_PROJECTS = ['greengo-chat'];

export function currentProject(): string {
  return process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT ||
    (process.env.FIREBASE_CONFIG ? JSON.parse(process.env.FIREBASE_CONFIG).projectId : '') || '';
}

export function isMockAllowed(project = currentProject()): boolean {
  return !!project && !PRODUCTION_PROJECTS.includes(project);
}

function guard() {
  if (!isMockAllowed()) throw new ProviderError('mock provider is disabled in production', 0, false);
}

const REPLIES: Record<string, string[]> = {
  English: ["That sounds great! Tell me more, what did you enjoy most?", "Love that! How did it go today?", "Nice one! What would you like to try next?"],
  Italian: ['Che bello! Raccontami di più, cosa ti è piaciuto?', 'Fantastico! Com\'è andata oggi?', 'Ottimo! Cosa vorresti provare adesso?'],
  Spanish: ['¡Qué bien! Cuéntame más, ¿qué te gustó?', '¡Genial! ¿Cómo te fue hoy?', '¡Muy bien! ¿Qué te gustaría probar ahora?'],
  French: ['Super ! Raconte-moi, qu\'est-ce qui t\'a plu ?', 'Génial ! Comment ça s\'est passé aujourd\'hui ?', 'Très bien ! Tu veux essayer quoi maintenant ?'],
  German: ['Klingt toll! Erzähl mehr, was hat dir gefallen?', 'Super! Wie war es heute?', 'Prima! Was möchtest du als Nächstes ausprobieren?'],
  'European Portuguese': ['Que bom! Conta-me mais, o que gostaste?', 'Fantástico! Como correu hoje?', 'Ótimo! O que queres experimentar agora?'],
  'Brazilian Portuguese': ['Que legal! Me conta mais, do que você gostou?', 'Demais! Como foi hoje?', 'Ótimo! O que você quer tentar agora?'],
};

let turn = 0;

function lastUser(req: GenerateRequest): string {
  for (let i = req.messages.length - 1; i >= 0; i--) if (req.messages[i].role === 'user') return req.messages[i].content;
  return '';
}

/** JSON answers for the JSON prompts the app uses. */
function mockJson(prompt: string): string {
  const text = (prompt.match(/\(JSON string\): ("(?:[^"\\]|\\.)*")/)?.[1]) ?? '"text"';
  const src = (() => { try { return JSON.parse(text) as string; } catch { return 'text'; } })();
  if (prompt.includes('"facts"')) {
    const cur = prompt.match(/Current memory facts \(JSON\): (\[[\s\S]*?\])\n/)?.[1];
    let facts: string[] = [];
    try { facts = cur ? JSON.parse(cur) : []; } catch { facts = []; }
    return JSON.stringify({ facts: [...facts.slice(0, 18), `[mock] Chatted with the Buddy on ${new Date().toISOString().slice(0, 10)}`] });
  }
  if (prompt.includes('"summary"')) return JSON.stringify({ summary: '[mock] The user and the Buddy had a friendly chat about the Buddy topic.' });
  if (prompt.includes('Suggest exactly 3')) return JSON.stringify({ replies: ['Sounds good!', 'Tell me more', 'Thanks!'], translations: ['Sounds good!', 'Tell me more', 'Thanks!'] });
  if (prompt.includes('grammar and spelling')) return JSON.stringify({ hasErrors: false, corrected: src, explanation: '[mock] No errors found.' });
  if (prompt.includes('idioms, slang')) return JSON.stringify({ hasContext: false });
  if (prompt.includes('word by word')) return JSON.stringify({ words: src.split(/\s+/).slice(0, 20).map((w) => ({ word: w, translation: `[mock] ${w}`, pos: 'word' })) });
  if (prompt.includes('CEFR difficulty')) return JSON.stringify({ level: 'A2' });
  if (prompt.includes('Romanize')) return JSON.stringify({ romanized: src });
  return JSON.stringify({ ok: true, mock: true });
}

export function mockGenerate(req: GenerateRequest): string {
  guard();
  const prompt = `${req.system ?? ''}\n${req.messages.map((m) => m.content).join('\n')}`;
  if (req.json) return mockJson(prompt);
  const lang = req.system?.match(/Always reply in ([A-Za-z ]+?)\./)?.[1] ?? 'English';
  const list = REPLIES[lang] ?? REPLIES.English;
  const reply = list[turn++ % list.length];
  const echo = lastUser(req).slice(0, 40);
  // Check-ins (the GreenGo instruction) get the reply alone; chats echo a little.
  return echo && !echo.startsWith('[GreenGo instruction') ? `${reply} (mock: "${echo}")` : `${reply} (mock)`;
}

export function mockTranslate(texts: string[], target: string): TranslateItem[] {
  guard();
  return texts.map((t) => ({ text: t.trim() ? `[→${target}] ${t}` : t, detectedLanguage: 'en', sameLanguage: !t.trim() }));
}

/** 0.4 s soft 330 Hz tone, 24 kHz mono 16-bit WAV. */
export function mockSpeak(): TtsResult {
  guard();
  const sr = 24000;
  const n = Math.round(sr * 0.4);
  const data = Buffer.alloc(n * 2);
  for (let i = 0; i < n; i++) {
    const env = Math.min(1, i / (sr * 0.02), (n - i) / (sr * 0.08));
    data.writeInt16LE(Math.round(Math.sin((2 * Math.PI * 330 * i) / sr) * env * 6000), i * 2);
  }
  const h = Buffer.alloc(44);
  h.write('RIFF', 0); h.writeUInt32LE(36 + data.length, 4); h.write('WAVE', 8); h.write('fmt ', 12);
  h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22); h.writeUInt32LE(sr, 24);
  h.writeUInt32LE(sr * 2, 28); h.writeUInt16LE(2, 32); h.writeUInt16LE(16, 34); h.write('data', 36); h.writeUInt32LE(data.length, 40);
  return { audio: Buffer.concat([h, data]), contentType: 'audio/wav', extension: 'wav', voice: 'mock:tone', providerId: 'mock' };
}
