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

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';

export const SEARCH_KEYWORDS_FIELD = 'searchKeywords';
export const MAX_SEARCH_KEYWORDS = 100;
export const MAX_SEARCH_PREFIX_LENGTH = 15;

/** Explicit accent folding (no NFD) so Dart and Node agree exactly. */
const FOLD_GROUPS: Record<string, string> = {
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

const FOLD = new Map<string, string>();
for (const [chars, rep] of Object.entries(FOLD_GROUPS)) {
  for (const ch of Array.from(chars)) FOLD.set(ch, rep);
}

const COMBINING_MARKS = /[̀-ͯ]/g;
// Built at runtime: the `u` flag + \p{} needs ES2018, tsconfig targets ES2017.
const NON_WORD = new RegExp('[^\\p{L}\\p{N}]+', 'u');

export function normalizeSearchText(input: unknown): string {
  if (typeof input !== 'string' || input.length === 0) return '';
  const lower = input.toLowerCase().replace(COMBINING_MARKS, '');
  let out = '';
  for (const ch of Array.from(lower)) out += FOLD.get(ch) ?? ch;
  return out;
}

export function searchTokens(input: unknown): string[] {
  return normalizeSearchText(input)
    .split(NON_WORD)
    .filter((t) => t.length > 0);
}

export function buildCommunitySearchKeywords(
  name: unknown,
  city?: unknown,
  tags?: unknown,
): string[] {
  const out: string[] = [];
  const seen = new Set<string>();
  const tagList = Array.isArray(tags) ? tags.filter((t) => typeof t === 'string') : [];
  for (const source of [name, city, ...tagList]) {
    for (const token of searchTokens(source)) {
      const chars = Array.from(token);
      const max = Math.min(chars.length, MAX_SEARCH_PREFIX_LENGTH);
      for (let i = 1; i <= max; i++) {
        const prefix = chars.slice(0, i).join('');
        if (seen.has(prefix)) continue;
        seen.add(prefix);
        out.push(prefix);
        if (out.length >= MAX_SEARCH_KEYWORDS) return out;
      }
    }
  }
  return out;
}

/** Keywords for raw community doc data. */
export function keywordsForCommunity(data: Record<string, any> | undefined): string[] {
  if (!data) return [];
  return buildCommunitySearchKeywords(data.name, data.city, data.tags);
}

function sameArray(a: unknown, b: string[]): boolean {
  if (!Array.isArray(a) || a.length !== b.length) return false;
  for (let i = 0; i < b.length; i++) if (a[i] !== b[i]) return false;
  return true;
}

/** True when the stored array is missing or differs from the computed one. */
export function searchKeywordsStale(data: Record<string, any> | undefined): boolean {
  if (!data) return false;
  return !sameArray(data[SEARCH_KEYWORDS_FIELD], keywordsForCommunity(data));
}

export interface SearchKeywordsBackfillResult {
  scanned: number;
  updated: number;
  done: boolean;
  /** Continue hint for a run that hit its page/time budget; omit to restart. */
  startAfter: string | null;
  dryRun: boolean;
}

/**
 * Scans `communities` in document-id order and rewrites only the docs whose
 * keywords are missing/stale. Idempotent; restarting without a cursor is
 * always correct (already-correct docs are read, not written).
 */
export async function runCommunitySearchKeywordsBackfill(opts: {
  startAfter?: string | null;
  pageSize?: number;
  maxPages?: number;
  dryRun?: boolean;
  timeBudgetMs?: number;
  firestore?: admin.firestore.Firestore;
}): Promise<SearchKeywordsBackfillResult> {
  const fs = opts.firestore ?? admin.firestore();
  const pageSize = Math.min(Math.max(opts.pageSize ?? 400, 1), 500); // one batch per page
  const maxPages = Math.max(opts.maxPages ?? Number.MAX_SAFE_INTEGER, 1);
  const budget = opts.timeBudgetMs ?? 480_000;
  const dryRun = opts.dryRun === true;
  const started = Date.now();

  let cursor: string | null = opts.startAfter ?? null;
  let scanned = 0;
  let updated = 0;
  let pages = 0;

  for (;;) {
    let q = fs
      .collection('communities')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(pageSize);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.get();
    if (snap.empty) return { scanned, updated, done: true, startAfter: null, dryRun };

    const batch = fs.batch();
    let writes = 0;
    for (const doc of snap.docs) {
      scanned++;
      const data = doc.data();
      if (!searchKeywordsStale(data)) continue;
      batch.update(doc.ref, { [SEARCH_KEYWORDS_FIELD]: keywordsForCommunity(data) });
      writes++;
      updated++;
    }
    if (writes > 0 && !dryRun) await batch.commit();

    cursor = snap.docs[snap.docs.length - 1].id;
    pages++;
    if (snap.size < pageSize) return { scanned, updated, done: true, startAfter: null, dryRun };
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
export const onCommunityCreatedSearchKeywords = onDocumentCreated(
  { document: 'communities/{communityId}', memory: '512MiB' },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    if (!searchKeywordsStale(data)) return;
    await snap.ref.update({ [SEARCH_KEYWORDS_FIELD]: keywordsForCommunity(data) });
  },
);
