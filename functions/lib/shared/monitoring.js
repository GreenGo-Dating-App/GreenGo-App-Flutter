"use strict";
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
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.monitored = monitored;
const admin = __importStar(require("firebase-admin"));
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const CONFIG_DOC = 'app_config/function_monitoring';
const MONITORS_COLLECTION = 'function_monitors';
const CACHE_TTL_MS = 60000;
let enabledCache = new Set();
let lastFetch = 0;
let inFlight = null;
/**
 * Refresh the cached set of enabled function names from Firestore.
 * Fire-and-forget; failures leave the previous cache in place.
 */
function maybeRefreshEnabled() {
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
        const list = data ? data.enabled : null;
        enabledCache = new Set(Array.isArray(list) ? list : []);
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
function recordInvocation(name, status, durationMs, errorMessage) {
    const update = {
        name,
        invocationCount: FieldValue.increment(1),
        lastInvokedAt: FieldValue.serverTimestamp(),
        lastStatus: status,
        lastDurationMs: durationMs,
        updatedAt: FieldValue.serverTimestamp(),
    };
    if (status === 'success') {
        update.successCount = FieldValue.increment(1);
    }
    else {
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
function monitored(name, handler) {
    const wrapped = function (...args) {
        maybeRefreshEnabled();
        if (!enabledCache.has(name)) {
            // Not monitored: pass straight through, preserving sync/async behaviour.
            return handler.apply(this, args);
        }
        const start = Date.now();
        try {
            const result = handler.apply(this, args);
            if (result && typeof result.then === 'function') {
                return result.then((value) => {
                    recordInvocation(name, 'success', Date.now() - start);
                    return value;
                }, (err) => {
                    recordInvocation(name, 'error', Date.now() - start, err && err.message);
                    throw err;
                });
            }
            recordInvocation(name, 'success', Date.now() - start);
            return result;
        }
        catch (err) {
            recordInvocation(name, 'error', Date.now() - start, err && err.message);
            throw err;
        }
    };
    return wrapped;
}
//# sourceMappingURL=monitoring.js.map