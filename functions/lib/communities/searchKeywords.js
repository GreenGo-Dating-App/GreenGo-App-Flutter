"use strict";
/**
 * Community search keywords (server-side community search).
 *
 * `communities/{id}.searchKeywords` = the normalised PREFIXES of every word of
 * the name, then the city, then the tags ("Café Lisboa" → c, ca, caf, cafe,
 * l, li, …), de-duplicated and capped at 100. The app searches with
 * `isPublic == true && searchKeywords array-contains <longest query word>`
 * ordered by memberCount desc (index: isPublic ASC, searchKeywords CONTAINS,
 * memberCount DESC).
 *
 * MUST stay identical to lib/features/communities/domain/community_search_keywords.dart.
 * Both are checked against test/fixtures/community_search_keywords_vectors.json.
 *
 * Writers:
 *  - the app writes the array on create/update (new clients);
 *  - `onCommunityCreatedSearchKeywords` fills it for docs created WITHOUT it
 *    (old app versions, admin/mock seeding). Deliberately onCreate only — the
 *    community doc is rewritten on every chat message (lastActivityAt), so an
 *    onWrite trigger would fire per message;
 *  - scripts/backfill_community_search_keywords.js (runCommunitySearchKeywordsBackfill)
 *    re-scans the whole collection and fixes missing/stale arrays (renames by
 *    old clients). No saved offset: re-running is always correct.
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
exports.onCommunityCreatedSearchKeywords = exports.MAX_SEARCH_PREFIX_LENGTH = exports.MAX_SEARCH_KEYWORDS = exports.SEARCH_KEYWORDS_FIELD = void 0;
exports.normalizeSearchText = normalizeSearchText;
exports.searchTokens = searchTokens;
exports.buildCommunitySearchKeywords = buildCommunitySearchKeywords;
exports.keywordsForCommunity = keywordsForCommunity;
exports.searchKeywordsStale = searchKeywordsStale;
exports.runCommunitySearchKeywordsBackfill = runCommunitySearchKeywordsBackfill;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
exports.SEARCH_KEYWORDS_FIELD = 'searchKeywords';
exports.MAX_SEARCH_KEYWORDS = 100;
exports.MAX_SEARCH_PREFIX_LENGTH = 15;
/** Explicit accent folding (no NFD) so Dart and Node agree exactly. */
const FOLD_GROUPS = {
    'àáâãäåāăą': 'a',
    'çćĉċč': 'c',
    'ďđð': 'd',
    'èéêëēĕėęě': 'e',
    'ĝğġģ': 'g',
    'ĥħ': 'h',
    'ìíîïĩīĭįı': 'i',
    'ĵ': 'j',
    'ķ': 'k',
    'ĺļľŀł': 'l',
    'ñńņňŉ': 'n',
    'òóôõöøōŏő': 'o',
    'ŕŗř': 'r',
    'śŝşšș': 's',
    'ţťŧț': 't',
    'ùúûüũūŭůűų': 'u',
    'ŵ': 'w',
    'ýÿŷ': 'y',
    'źżž': 'z',
    'ß': 'ss',
    'æ': 'ae',
    'œ': 'oe',
    'þ': 'th',
};
const FOLD = new Map();
for (const [chars, rep] of Object.entries(FOLD_GROUPS)) {
    for (const ch of Array.from(chars))
        FOLD.set(ch, rep);
}
const COMBINING_MARKS = /[̀-ͯ]/g;
// Built at runtime: the `u` flag + \p{} needs ES2018, tsconfig targets ES2017.
const NON_WORD = new RegExp('[^\\p{L}\\p{N}]+', 'u');
function normalizeSearchText(input) {
    var _a;
    if (typeof input !== 'string' || input.length === 0)
        return '';
    const lower = input.toLowerCase().replace(COMBINING_MARKS, '');
    let out = '';
    for (const ch of Array.from(lower))
        out += (_a = FOLD.get(ch)) !== null && _a !== void 0 ? _a : ch;
    return out;
}
function searchTokens(input) {
    return normalizeSearchText(input)
        .split(NON_WORD)
        .filter((t) => t.length > 0);
}
function buildCommunitySearchKeywords(name, city, tags) {
    const out = [];
    const seen = new Set();
    const tagList = Array.isArray(tags) ? tags.filter((t) => typeof t === 'string') : [];
    for (const source of [name, city, ...tagList]) {
        for (const token of searchTokens(source)) {
            const chars = Array.from(token);
            const max = Math.min(chars.length, exports.MAX_SEARCH_PREFIX_LENGTH);
            for (let i = 1; i <= max; i++) {
                const prefix = chars.slice(0, i).join('');
                if (seen.has(prefix))
                    continue;
                seen.add(prefix);
                out.push(prefix);
                if (out.length >= exports.MAX_SEARCH_KEYWORDS)
                    return out;
            }
        }
    }
    return out;
}
/** Keywords for raw community doc data. */
function keywordsForCommunity(data) {
    if (!data)
        return [];
    return buildCommunitySearchKeywords(data.name, data.city, data.tags);
}
function sameArray(a, b) {
    if (!Array.isArray(a) || a.length !== b.length)
        return false;
    for (let i = 0; i < b.length; i++)
        if (a[i] !== b[i])
            return false;
    return true;
}
/** True when the stored array is missing or differs from the computed one. */
function searchKeywordsStale(data) {
    if (!data)
        return false;
    return !sameArray(data[exports.SEARCH_KEYWORDS_FIELD], keywordsForCommunity(data));
}
/**
 * Scans `communities` in document-id order and rewrites only the docs whose
 * keywords are missing/stale. Idempotent; restarting without a cursor is
 * always correct (already-correct docs are read, not written).
 */
async function runCommunitySearchKeywordsBackfill(opts) {
    var _a, _b, _c, _d, _e;
    const fs = (_a = opts.firestore) !== null && _a !== void 0 ? _a : admin.firestore();
    const pageSize = Math.min(Math.max((_b = opts.pageSize) !== null && _b !== void 0 ? _b : 400, 1), 500); // one batch per page
    const maxPages = Math.max((_c = opts.maxPages) !== null && _c !== void 0 ? _c : Number.MAX_SAFE_INTEGER, 1);
    const budget = (_d = opts.timeBudgetMs) !== null && _d !== void 0 ? _d : 480000;
    const dryRun = opts.dryRun === true;
    const started = Date.now();
    let cursor = (_e = opts.startAfter) !== null && _e !== void 0 ? _e : null;
    let scanned = 0;
    let updated = 0;
    let pages = 0;
    for (;;) {
        let q = fs
            .collection('communities')
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(pageSize);
        if (cursor)
            q = q.startAfter(cursor);
        const snap = await q.get();
        if (snap.empty)
            return { scanned, updated, done: true, startAfter: null, dryRun };
        const batch = fs.batch();
        let writes = 0;
        for (const doc of snap.docs) {
            scanned++;
            const data = doc.data();
            if (!searchKeywordsStale(data))
                continue;
            batch.update(doc.ref, { [exports.SEARCH_KEYWORDS_FIELD]: keywordsForCommunity(data) });
            writes++;
            updated++;
        }
        if (writes > 0 && !dryRun)
            await batch.commit();
        cursor = snap.docs[snap.docs.length - 1].id;
        pages++;
        if (snap.size < pageSize)
            return { scanned, updated, done: true, startAfter: null, dryRun };
        if (pages >= maxPages || Date.now() - started > budget) {
            return { scanned, updated, done: false, startAfter: cursor, dryRun };
        }
    }
}
/**
 * Fills `searchKeywords` on communities created without it (old clients,
 * seeding). No-op (no write) when the creating client already wrote the
 * correct array — the common case once new app versions roll out.
 */
exports.onCommunityCreatedSearchKeywords = (0, firestore_1.onDocumentCreated)({ document: 'communities/{communityId}', memory: '512MiB' }, async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    if (!searchKeywordsStale(data))
        return;
    await snap.ref.update({ [exports.SEARCH_KEYWORDS_FIELD]: keywordsForCommunity(data) });
});
//# sourceMappingURL=searchKeywords.js.map