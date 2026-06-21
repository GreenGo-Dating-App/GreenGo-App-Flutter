/**
 * Function invocation monitoring.
 *
 * A single generic wrapper, `monitored(name, handler)`, is applied to every
 * deployed Cloud Function handler (see scripts/instrument-monitoring.cjs).
 *
 * Behaviour is intentionally inert until a function is *selected* for
 * monitoring from the admin panel. Selection lives in Firestore at
 * `app_config/function_monitoring` ({ enabled: string[] }) and is cached
 * in-memory per instance (refreshed ~60s) so the hot path costs a single
 * `Set.has()` for functions that are not being monitored.
 *
 * For selected functions, each invocation does one best-effort merge write to
 * `function_monitors/{name}` recording last-invoked time, total/success/error
 * counts and the last error. Recording NEVER throws into the wrapped function —
 * monitoring can fail silently but must never break or slow a real function.
 */

import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const CONFIG_DOC = 'app_config/function_monitoring';
const MONITORS_COLLECTION = 'function_monitors';
const CACHE_TTL_MS = 60_000;

let enabledCache: Set<string> = new Set();
let lastFetch = 0;
let inFlight: Promise<void> | null = null;

/**
 * Refresh the cached set of enabled function names from Firestore.
 * Fire-and-forget; failures leave the previous cache in place.
 */
function maybeRefreshEnabled(): void {
  const now = Date.now();
  if (inFlight || now - lastFetch < CACHE_TTL_MS) {
    return;
  }
  lastFetch = now;
  inFlight = db
    .doc(CONFIG_DOC)
    .get()
    .then((snap) => {
      const data = snap.exists ? snap.data() : null;
      const list: unknown = data ? data.enabled : null;
      enabledCache = new Set(Array.isArray(list) ? (list as string[]) : []);
    })
    .catch(() => {
      /* keep previous cache on error */
    })
    .finally(() => {
      inFlight = null;
    });
}

/**
 * Best-effort stats write for a single invocation. Never rejects.
 */
function recordInvocation(
  name: string,
  status: 'success' | 'error',
  durationMs: number,
  errorMessage?: string
): void {
  const update: Record<string, unknown> = {
    name,
    invocationCount: FieldValue.increment(1),
    lastInvokedAt: FieldValue.serverTimestamp(),
    lastStatus: status,
    lastDurationMs: durationMs,
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (status === 'success') {
    update.successCount = FieldValue.increment(1);
  } else {
    update.errorCount = FieldValue.increment(1);
    update.lastError = (errorMessage || 'Unknown error').slice(0, 1000);
    update.lastErrorAt = FieldValue.serverTimestamp();
  }

  db.collection(MONITORS_COLLECTION)
    .doc(name)
    .set(update, { merge: true })
    .catch(() => {
      /* swallow — monitoring must never break the function */
    });
}

/**
 * Wrap a Cloud Function handler so its invocations are recorded when the
 * function is selected for monitoring. Preserves the handler's signature and
 * return value exactly; when the function is not selected the original handler
 * is invoked directly with no added latency or behavioural change.
 */
export function monitored<T extends (...args: any[]) => any>(
  name: string,
  handler: T
): T {
  const wrapped = function (this: unknown, ...args: any[]): any {
    maybeRefreshEnabled();

    if (!enabledCache.has(name)) {
      // Not monitored: pass straight through, preserving sync/async behaviour.
      return handler.apply(this, args);
    }

    const start = Date.now();
    try {
      const result = handler.apply(this, args);
      if (result && typeof result.then === 'function') {
        return result.then(
          (value: unknown) => {
            recordInvocation(name, 'success', Date.now() - start);
            return value;
          },
          (err: any) => {
            recordInvocation(name, 'error', Date.now() - start, err && err.message);
            throw err;
          }
        );
      }
      recordInvocation(name, 'success', Date.now() - start);
      return result;
    } catch (err: any) {
      recordInvocation(name, 'error', Date.now() - start, err && err.message);
      throw err;
    }
  };

  return wrapped as unknown as T;
}
