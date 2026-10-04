"use strict";
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
exports.translateTexts = void 0;
exports.sharedTranslationId = sharedTranslationId;
/**
 * translateTexts — shared, persistent translations for PUBLIC content
 * (event / attraction / experience text). Each (target language, text) pair is
 * translated ONCE and stored in `translations/{id}`; every later viewer reads
 * the stored copy instead of translating again.
 *
 *   id = sha256(`${target}\u0000${text}`) hex — computed identically by the
 *   app (TranslationService.sharedTranslationId), so clients read hits
 *   directly from Firestore and only call this function for misses.
 *
 * Only this function writes translations (rules: get for signed-in users, no
 * list, no client writes), so nobody can plant a fake translation. The doc
 * stores the translated text, never the original. Private chat text never
 * goes through here.
 *
 * Guard rails: signed-in only, ≤ 50 texts per call, ≤ 5,000 chars each, and a
 * per-user daily quota of misses (cache hits are free).
 *
 * Misses are translated with the FREE Google endpoint (./freeTranslate), at
 * most 4 requests in flight, retried with backoff. If the endpoint rate-limits
 * (429) or fails, the untranslated texts come back as '' (same response shape
 * as always), are not stored, and the app falls back to translating them on
 * the device. No dependency on the paid Cloud Translation API.
 */
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const crypto = __importStar(require("crypto"));
require("../shared/firebaseAdmin");
const freeTranslate_1 = require("./freeTranslate");
const db = admin.firestore();
const MAX_TEXTS = 50;
const MAX_CHARS = 5000;
const DAILY_MISS_QUOTA = 1500;
/** Must match TranslationService.normalizeLanguage targets used by the app. */
const TARGET_RE = /^[a-z]{2}(-[A-Z]{2})?$/;
function sharedTranslationId(target, text) {
    return crypto.createHash('sha256').update(`${target}\u0000${text}`, 'utf8').digest('hex');
}
exports.translateTexts = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 60 }, async (request) => {
    var _a, _b, _c;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required');
    const target = typeof ((_b = request.data) === null || _b === void 0 ? void 0 : _b.target) === 'string' ? request.data.target : '';
    if (!TARGET_RE.test(target))
        throw new https_1.HttpsError('invalid-argument', 'Bad target');
    const raw = Array.isArray((_c = request.data) === null || _c === void 0 ? void 0 : _c.texts) ? request.data.texts : [];
    const texts = raw
        .filter((t) => typeof t === 'string' && t.trim().length > 0)
        .slice(0, MAX_TEXTS)
        .map((t) => t.slice(0, MAX_CHARS));
    if (texts.length === 0)
        return { translations: [] };
    const unique = [...new Set(texts)];
    const refs = unique.map((t) => db.collection('translations').doc(sharedTranslationId(target, t)));
    const snaps = await db.getAll(...refs);
    const result = new Map();
    const misses = [];
    snaps.forEach((s, i) => {
        var _a;
        const v = s.exists ? (_a = s.data()) === null || _a === void 0 ? void 0 : _a.translated : undefined;
        if (v)
            result.set(unique[i], v);
        else
            misses.push(unique[i]);
    });
    if (misses.length > 0) {
        // Per-user daily quota on translated misses.
        const day = new Date().toISOString().slice(0, 10).replace(/-/g, '');
        const quotaRef = db.collection('translation_quota').doc(`${uid}_${day}`);
        const allowed = await db.runTransaction(async (tx) => {
            var _a;
            const q = await tx.get(quotaRef);
            const used = ((_a = q.data()) === null || _a === void 0 ? void 0 : _a.count) || 0;
            if (used + misses.length > DAILY_MISS_QUOTA)
                return false;
            tx.set(quotaRef, {
                count: used + misses.length,
                uid,
                expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + 3 * 864e5),
            }, { merge: true });
            return true;
        });
        if (allowed) {
            const out = await (0, freeTranslate_1.freeTranslateMany)(misses, target, {
                concurrency: 4,
                timeoutMs: 6000,
                // Well inside the app's 30s callable timeout.
                deadlineMs: 20000,
            });
            const batch = db.batch();
            let writes = 0;
            misses.forEach((text, i) => {
                var _a, _b;
                const translated = ((_a = out[i]) === null || _a === void 0 ? void 0 : _a.text) || '';
                if (!translated)
                    return;
                result.set(text, translated);
                batch.set(db.collection('translations').doc(sharedTranslationId(target, text)), {
                    target,
                    translated,
                    source: ((_b = out[i]) === null || _b === void 0 ? void 0 : _b.detectedLanguage) || null,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                writes++;
            });
            if (writes > 0)
                await batch.commit();
        }
    }
    // Same order as the request; '' = not translated (caller keeps original).
    return { translations: texts.map((t) => { var _a; return (_a = result.get(t)) !== null && _a !== void 0 ? _a : ''; }) };
});
//# sourceMappingURL=sharedTranslations.js.map