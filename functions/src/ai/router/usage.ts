/**
 * Per-day usage counters per capability and provider (admin "Usage & cost"
 * tab; owner wants to see how many translations each model makes).
 *
 *   ai_usage_stats/{yyyymmdd}_{shard}   (server-only)
 *     c.<capability>.<providerId>.{calls, items, chars, errors, fallbacks, latencyMs}
 *     models.<providerId> = model id at the time
 *
 * 20 random shards per day so heavy traffic never hits one document's write
 * limit; the admin callable sums the shards. Writes are fire-and-forget:
 * monitoring must never fail or slow a user request noticeably.
 */
import * as admin from 'firebase-admin';
import '../../shared/firebaseAdmin';
import { Capability } from './types';

export const AI_USAGE_STATS = 'ai_usage_stats';
export const USAGE_SHARDS = 20;

export interface UsageEvent {
  capability: Capability;
  providerId: string;
  model?: string;
  /** Texts translated / replies generated / audio clips. */
  items: number;
  /** Characters sent to the provider. */
  chars: number;
  ok: boolean;
  /** This provider served the call because an earlier one failed. */
  fallback: boolean;
  latencyMs: number;
}

export const dayKey = (d = new Date()) => d.toISOString().slice(0, 10).replace(/-/g, '');

let sink: ((e: UsageEvent) => void) | null = null;
/** Test hook: capture events instead of writing them. */
export function _setUsageSink(s: ((e: UsageEvent) => void) | null) { sink = s; }

export function recordUsage(e: UsageEvent): void {
  if (sink) {
    sink(e);
    return;
  }
  try {
    const inc = admin.firestore.FieldValue.increment;
    const shard = Math.floor(Math.random() * USAGE_SHARDS);
    const day = dayKey();
    const stats: Record<string, unknown> = {
      calls: inc(1),
      items: inc(e.ok ? e.items : 0),
      chars: inc(e.chars),
      errors: inc(e.ok ? 0 : 1),
      fallbacks: inc(e.fallback && e.ok ? 1 : 0),
      latencyMs: inc(Math.max(0, Math.round(e.latencyMs))),
    };
    admin.firestore().collection(AI_USAGE_STATS).doc(`${day}_${shard}`).set({
      day,
      c: { [e.capability]: { [e.providerId]: stats } },
      ...(e.model ? { models: { [e.providerId]: e.model } } : {}),
      expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + 400 * 864e5),
    }, { merge: true }).catch(() => undefined);
  } catch {
    /* monitoring only */
  }
}
