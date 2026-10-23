/**
 * The AI router: capability -> provider chain (primary + fallbacks) with the
 * capability's context rules, consent gating per provider and usage counters.
 *
 *   generate('text_buddies', {system, messages}, ctx)
 *   translate('translate_chat', texts, 'it', ctx)
 *   speak('tts', {text, language, isMale}, ctx)
 *
 * A provider is skipped when it is disabled, cannot serve the capability, or
 * needs a newer AI-consent notice than the caller accepted
 * (provider.minConsentVersion > ctx.consentVersion). A failed provider hands
 * the remaining work to the next one in the chain.
 */
import { generateWith, translateWith, ttsWith, TranslateOpts } from './adapters';
import { loadConfig } from './config';
import { applyReplyRules } from './rules';
import { recordUsage } from './usage';
import {
  AiConfig, CallContext, Capability, CapabilityRules, GenerateRequest, GenerateResult, ProviderConfig, ProviderError,
  TYPE_KINDS, TranslateResult, TtsRequest, TtsResult, capabilityKind,
} from './types';

export class NoProviderError extends ProviderError {
  constructor(cap: Capability) {
    super(`no provider available for ${cap}`, 0, false);
    this.name = 'NoProviderError';
  }
}

export function eligibleChain(config: AiConfig, cap: Capability, ctx: CallContext): ProviderConfig[] {
  const route = config.routes[cap];
  if (!route?.enabled) return [];
  return route.chain
    .map((id) => config.providers[id])
    .filter((p): p is ProviderConfig => !!p && p.enabled
      && TYPE_KINDS[p.type].includes(capabilityKind(cap))
      && (p.minConsentVersion ?? 0) <= (ctx.consentVersion ?? 0));
}

export async function rulesFor(cap: Capability): Promise<CapabilityRules> {
  return (await loadConfig()).rules[cap] ?? {};
}

const chars = (req: GenerateRequest) =>
  (req.system?.length ?? 0) + req.messages.reduce((n, m) => n + m.content.length, 0);

/** Retries [fn] on transient errors (rules.retries extra attempts). */
async function withRetries<T>(rules: CapabilityRules, fn: () => Promise<T>): Promise<T> {
  const retries = Math.max(0, Math.min(3, rules.retries ?? 0));
  for (let attempt = 0; ; attempt++) {
    try {
      return await fn();
    } catch (e) {
      const transient = !(e instanceof ProviderError) || e.transient;
      if (!transient || attempt >= retries) throw e;
      await new Promise((r) => setTimeout(r, 300 * 2 ** attempt));
    }
  }
}

export interface GenerateOptions {
  /** Skip the reply rules (e.g. JSON answers of text_assist). Default: req.json. */
  rawReply?: boolean;
  /** Rules overrides for this call. */
  rules?: CapabilityRules;
}

export async function generate(
  cap: Capability, req: GenerateRequest, ctx: CallContext, opts: GenerateOptions = {},
): Promise<GenerateResult & { banned: string | null }> {
  const config = await loadConfig();
  const rules = { ...(config.rules[cap] ?? {}), ...(opts.rules ?? {}) };
  const chain = eligibleChain(config, cap, ctx);
  if (!chain.length) throw new NoProviderError(cap);
  let last: unknown = null;
  for (let i = 0; i < chain.length; i++) {
    const p = chain[i];
    const t0 = Date.now();
    try {
      const raw = await withRetries(rules, () => generateWith(p, req, rules));
      recordUsage({ capability: cap, providerId: p.id, model: p.model, items: 1, chars: chars(req), ok: true, fallback: i > 0, latencyMs: Date.now() - t0 });
      if (opts.rawReply ?? req.json) return { text: raw, providerId: p.id, model: p.model ?? '', truncated: 0, banned: null };
      const applied = applyReplyRules(raw, rules);
      if (!applied.text) throw new ProviderError(`${p.id} reply empty after rules`, 0, true);
      return { text: applied.text, providerId: p.id, model: p.model ?? '', truncated: applied.truncated, banned: applied.banned };
    } catch (e: any) {
      last = e;
      recordUsage({ capability: cap, providerId: p.id, model: p.model, items: 0, chars: chars(req), ok: false, fallback: i > 0, latencyMs: Date.now() - t0 });
      console.warn(`ai router: ${cap} via ${p.id} failed: ${e?.message ?? e}`);
    }
  }
  throw last instanceof ProviderError ? last : new ProviderError('all providers failed');
}

export async function translate(
  cap: Capability, texts: string[], target: string, ctx: CallContext, opts: TranslateOpts = {},
): Promise<TranslateResult> {
  const config = await loadConfig();
  const rules = config.rules[cap] ?? {};
  const items: TranslateResult['items'] = texts.map(() => null);
  const providers: TranslateResult['providers'] = texts.map(() => null);
  const chain = eligibleChain(config, cap, ctx);
  for (let i = 0; i < chain.length; i++) {
    const todo = texts.map((_, k) => k).filter((k) => items[k] === null);
    if (!todo.length) break;
    const p = chain[i];
    const batch = todo.map((k) => texts[k]);
    const t0 = Date.now();
    let out: TranslateResult['items'] = [];
    try {
      out = await translateWith(p, batch, target, rules, opts);
    } catch (e: any) {
      console.warn(`ai router: ${cap} via ${p.id} failed: ${e?.message ?? e}`);
    }
    let done = 0;
    todo.forEach((k, j) => {
      if (out[j]) {
        items[k] = out[j];
        providers[k] = p.id;
        done++;
      }
    });
    recordUsage({
      capability: cap, providerId: p.id, model: p.model, items: done,
      chars: batch.reduce((n, s) => n + s.length, 0), ok: done > 0, fallback: i > 0, latencyMs: Date.now() - t0,
    });
  }
  return { items, providers };
}

export async function speak(cap: Capability, req: TtsRequest, ctx: CallContext): Promise<TtsResult> {
  const config = await loadConfig();
  const rules = config.rules[cap] ?? {};
  const chain = eligibleChain(config, cap, ctx);
  if (!chain.length) throw new NoProviderError(cap);
  let last: unknown = null;
  for (let i = 0; i < chain.length; i++) {
    const p = chain[i];
    const t0 = Date.now();
    try {
      const r = await withRetries(rules, () => ttsWith(p, req, rules));
      recordUsage({ capability: cap, providerId: p.id, model: p.model, items: 1, chars: req.text.length, ok: true, fallback: i > 0, latencyMs: Date.now() - t0 });
      return r;
    } catch (e: any) {
      last = e;
      recordUsage({ capability: cap, providerId: p.id, model: p.model, items: 0, chars: req.text.length, ok: false, fallback: i > 0, latencyMs: Date.now() - t0 });
      console.warn(`ai router: ${cap} via ${p.id} failed: ${e?.message ?? e}`);
    }
  }
  throw last instanceof ProviderError ? last : new ProviderError('all providers failed');
}

/**
 * Admin "Test connection": one call straight to [provider] (no chain, no
 * consent gate, no usage counters). Returns the raw output and latency.
 */
export async function testProvider(p: ProviderConfig, cap: Capability, sample: string, target = 'it', system?: string) {
  const rules = (await loadConfig()).rules[cap] ?? {};
  const t0 = Date.now();
  const kind = capabilityKind(cap);
  if (kind === 'translate') {
    const [r] = await translateWith(p, [sample], target, rules, { deadlineMs: 20_000 });
    if (!r) throw new ProviderError('no translation returned');
    return { output: r.text, latencyMs: Date.now() - t0 };
  }
  if (kind === 'tts') {
    const r = await ttsWith(p, { text: sample, language: target, isMale: false }, rules);
    return { output: `${r.audio.length} bytes ${r.contentType} (${r.voice})`, latencyMs: Date.now() - t0 };
  }
  const raw = await generateWith(p, { system, messages: [{ role: 'user', content: sample }] }, rules);
  const applied = applyReplyRules(raw, rules);
  return { output: applied.text, raw, truncated: applied.truncated, banned: applied.banned, latencyMs: Date.now() - t0 };
}
