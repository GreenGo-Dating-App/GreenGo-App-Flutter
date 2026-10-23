/**
 * Qwen-Audio TTS 3.x (qwen-audio-3.1-tts-flash ...) over the DashScope
 * WebSocket (CosyVoice protocol; these models have no HTTP endpoint):
 *
 *   wss://<host>/api-ws/v1/inference   Authorization: bearer <key>
 *   -> run-task {model, voice, format mp3}   <- task-started
 *   -> continue-task {text}  -> finish-task  <- binary mp3 frames ... task-finished
 *
 * Uses Node 22's built-in WebSocket (undici), which accepts custom headers;
 * no extra dependency. Called only on a cache miss: synthesizeSpeech stores
 * the audio in pronunciation_cache / Storage and every later play reuses it.
 *
 * Voices per language come from provider options.voices
 * ({"it": {"female": "...", "male": "..."}, "default": {...}}); a language
 * without a voice is refused (non-transient) so the next provider speaks it.
 * Defaults (third-party voice list, live-tested 2026-10-23 on Singapore):
 * multilingual longanhuan_v3.1 / xunanchuan_v3.1 for it, de, fr, pt;
 * Abby_v3.1 / Andy_v3.1 for English; Spanish on the multilingual voices
 * (owner request: Spanish on Qwen, not Google).
 */
import { randomUUID } from 'crypto';
import { CapabilityRules, ProviderConfig, ProviderError, TtsRequest, TtsResult } from './types';

export const DEFAULT_AUDIO_VOICES: Record<string, { female: string; male: string }> = {
  en: { female: 'Abby_v3.1', male: 'Andy_v3.1' },
  it: { female: 'longanhuan_v3.1', male: 'xunanchuan_v3.1' },
  de: { female: 'longanhuan_v3.1', male: 'xunanchuan_v3.1' },
  fr: { female: 'longanhuan_v3.1', male: 'xunanchuan_v3.1' },
  // Not in the published voice list; generated fine on 2026-10-23 (owner to confirm by ear).
  es: { female: 'longanhuan_v3.1', male: 'xunanchuan_v3.1' },
  pt: { female: 'longanhuan_v3.1', male: 'xunanchuan_v3.1' },
  ja: { female: 'longanhuan_v3.1', male: 'xunanchuan_v3.1' },
  ko: { female: 'longanhuan_v3.1', male: 'xunanchuan_v3.1' },
  zh: { female: 'longanhuan_v3.1', male: 'xunanchuan_v3.1' },
};

const base = (code: string) => code.trim().toLowerCase().replace(/_/g, '-').split('-')[0];

/** Voice for [language] (options.voices first, then the defaults), or null when none. */
export function audioVoice(p: ProviderConfig, language: string, isMale: boolean): string | null {
  const custom = ((p.options as any)?.voices ?? {}) as Record<string, { female?: string; male?: string }>;
  const lc = language.toLowerCase().replace(/_/g, '-');
  const pick = custom[lc] ?? custom[base(lc)] ?? DEFAULT_AUDIO_VOICES[base(lc)] ?? custom.default;
  if (!pick) return null;
  return (isMale ? pick.male : pick.female) || pick.female || pick.male || null;
}

/** wss URL from the provider's https base (https://dashscope-intl.aliyuncs.com[/...]). */
export function audioWsUrl(baseUrl: string): string {
  const u = new URL(baseUrl);
  if (u.hostname === 'localhost' || u.hostname === '127.0.0.1') return `ws://${u.host}/api-ws/v1/inference`;
  return `wss://${u.host}/api-ws/v1/inference`;
}

type WsLike = {
  binaryType: string;
  onopen: ((ev: any) => void) | null;
  onmessage: ((ev: any) => void) | null;
  onerror: ((ev: any) => void) | null;
  onclose: ((ev: any) => void) | null;
  send(data: string): void;
  close(): void;
};
type WsFactory = (url: string, headers: Record<string, string>) => WsLike;
let factory: WsFactory = (url, headers) => {
  const WS = (globalThis as any).WebSocket;
  if (!WS) throw new ProviderError('qwen_audio_tts: WebSocket not available in this runtime', 0, false);
  return new WS(url, { headers }) as WsLike;
};
/** Test hook. */
export function _setWsFactory(f: WsFactory | null) {
  factory = f ?? ((url, headers) => new (globalThis as any).WebSocket(url, { headers }));
}

export async function qwenAudioTts(p: ProviderConfig, key: string, req: TtsRequest, rules: CapabilityRules): Promise<TtsResult> {
  const voice = audioVoice(p, req.language, req.isMale);
  // No voice for this language (e.g. Spanish): let the next provider speak it.
  if (!voice) throw new ProviderError(`qwen_audio_tts: no voice for ${req.language}`, 0, false);
  const timeoutMs = rules.timeoutMs ?? 30_000;
  const taskId = randomUUID();
  const header = (action: string) => ({ action, task_id: taskId, streaming: 'duplex' });

  const audio = await new Promise<Buffer>((resolve, reject) => {
    const chunks: Buffer[] = [];
    let settled = false;
    let ws: WsLike;
    const finish = (err: ProviderError | null, value?: Buffer) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      try { ws.close(); } catch { /* closed */ }
      if (err) reject(err); else resolve(value!);
    };
    const timer = setTimeout(() => finish(new ProviderError('qwen_audio_tts timeout', 408, true)), timeoutMs);
    try {
      ws = factory(audioWsUrl(p.baseUrl!), { Authorization: `bearer ${key}` });
    } catch (e: any) {
      clearTimeout(timer);
      reject(e instanceof ProviderError ? e : new ProviderError(`qwen_audio_tts connect failed (${e?.name || 'error'})`));
      return;
    }
    ws.binaryType = 'arraybuffer';
    ws.onopen = () => ws.send(JSON.stringify({
      header: header('run-task'),
      payload: {
        task_group: 'audio', task: 'tts', function: 'SpeechSynthesizer', model: p.model,
        parameters: { text_type: 'PlainText', voice, format: 'mp3', sample_rate: 22050, volume: 50, rate: 1, pitch: 1 },
        input: {},
      },
    }));
    ws.onmessage = (ev: any) => {
      if (typeof ev.data !== 'string') {
        chunks.push(Buffer.from(ev.data as ArrayBuffer));
        return;
      }
      let m: any;
      try { m = JSON.parse(ev.data); } catch { return; }
      const event = m?.header?.event;
      if (event === 'task-started') {
        ws.send(JSON.stringify({ header: header('continue-task'), payload: { input: { text: req.text } } }));
        ws.send(JSON.stringify({ header: header('finish-task'), payload: { input: {} } }));
      } else if (event === 'task-finished') {
        const buf = Buffer.concat(chunks);
        finish(buf.length ? null : new ProviderError('qwen_audio_tts: empty audio', 0, true), buf);
      } else if (event === 'task-failed') {
        // Error text is logged by the router; it never contains the key.
        const code = String(m?.header?.error_code ?? '');
        const transient = /Throttling|InternalError|Timeout/i.test(code);
        finish(new ProviderError(`qwen_audio_tts failed ${code}`.trim(), 0, transient));
      }
    };
    ws.onerror = () => finish(new ProviderError('qwen_audio_tts connection error'));
    ws.onclose = (ev: any) => {
      if (!settled) {
        const code = Number(ev?.code) || 0;
        // 4xx-style handshake refusals (bad key) are not worth retrying.
        finish(new ProviderError(`qwen_audio_tts closed ${code}`, code, code !== 1008 && code !== 4001 && code !== 4003));
      }
    };
  });
  return { audio, contentType: 'audio/mpeg', extension: 'mp3', voice: `qwen:${voice}`, providerId: p.id };
}
