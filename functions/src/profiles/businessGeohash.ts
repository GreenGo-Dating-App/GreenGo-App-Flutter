/**
 * `profiles/{uid}.businessGeohash` backfill core (owner rule 2026-10-19:
 * Discover finds businesses by their BUSINESS ADDRESS, not the owner's
 * personal location).
 *
 * The live value is kept by the existing profile triggers
 * (mirrorPrivateProfileFields / syncCoarseFromPrivateProfile, see
 * privateProfile.ts businessGeohashOf); this module only fills in documents
 * written before those triggers knew the field. Used by
 * scripts/backfill-business-geohash.ts.
 *
 * Two passes, each an equality / range query paged by document id cursor
 * (single-field indexes only, no composite):
 *   1. `isBusiness == true`: sets the geohash of every business with a
 *      usable address (and deletes a stale one).
 *   2. `businessGeohash >= ''`: every doc that HAS the field, so a former
 *      business (or one whose address was removed) loses it.
 * Per doc, one transaction re-reads the CURRENT document and writes only
 * `businessGeohash`, only when it differs: re-running is always correct
 * (already-correct docs are read, not written) and a concurrent user edit can
 * never be overwritten with a value computed from a stale page read. Nothing
 * is saved between runs (resume = run again).
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { BUSINESS_GEOHASH_FIELD, businessGeohashOf } from './privateProfile';

export type BusinessGeohashChange = 'set' | 'cleared' | 'unchanged' | 'missing';

/** The update for [pub] (null = nothing to write). */
export function businessGeohashUpdate(pub: Record<string, any> | undefined): Record<string, any> | null {
  if (!pub) return null;
  const want = businessGeohashOf(pub);
  const have = pub[BUSINESS_GEOHASH_FIELD];
  if (want === null) {
    return have === undefined ? null : { [BUSINESS_GEOHASH_FIELD]: admin.firestore.FieldValue.delete() };
  }
  return have === want ? null : { [BUSINESS_GEOHASH_FIELD]: want };
}

/** Transactional per-doc sync of businessGeohash only. */
export async function syncBusinessGeohash(
  uid: string,
  opts: { firestore?: admin.firestore.Firestore; dryRun?: boolean } = {},
): Promise<BusinessGeohashChange> {
  const fs = opts.firestore ?? admin.firestore();
  const ref = fs.collection('profiles').doc(uid);
  return fs.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return 'missing';
    const upd = businessGeohashUpdate(snap.data());
    if (!upd) return 'unchanged';
    if (!opts.dryRun) tx.update(ref, upd);
    return businessGeohashOf(snap.data()) === null ? 'cleared' : 'set';
  });
}

export interface BusinessGeohashBackfillResult {
  scanned: number;
  set: number;
  cleared: number;
  done: boolean;
  dryRun: boolean;
}

export async function runBusinessGeohashBackfill(opts: {
  firestore?: admin.firestore.Firestore;
  pageSize?: number;
  maxPages?: number;
  dryRun?: boolean;
  concurrency?: number;
  onPage?: (pass: 1 | 2, r: BusinessGeohashBackfillResult, lastId: string) => void;
} = {}): Promise<BusinessGeohashBackfillResult> {
  const fs = opts.firestore ?? admin.firestore();
  const pageSize = Math.min(Math.max(opts.pageSize ?? 300, 1), 400);
  const maxPages = opts.maxPages ?? Number.MAX_SAFE_INTEGER;
  const conc = Math.max(1, opts.concurrency ?? 10);
  const res: BusinessGeohashBackfillResult = {
    scanned: 0, set: 0, cleared: 0, done: false, dryRun: opts.dryRun !== false,
  };
  const seen = new Set<string>();
  let pages = 0;

  const passes: Array<[1 | 2, () => admin.firestore.Query]> = [
    [1, () => fs.collection('profiles').where('isBusiness', '==', true)
      .orderBy(admin.firestore.FieldPath.documentId())],
    [2, () => fs.collection('profiles').where(BUSINESS_GEOHASH_FIELD, '>=', '')
      .orderBy(BUSINESS_GEOHASH_FIELD).orderBy(admin.firestore.FieldPath.documentId())],
  ];
  for (const [pass, make] of passes) {
    let cursor: admin.firestore.QueryDocumentSnapshot | null = null;
    for (;;) {
      let q = make().limit(pageSize);
      if (cursor) q = q.startAfter(cursor);
      const snap = await q.select(BUSINESS_GEOHASH_FIELD).get();
      if (snap.empty) break;
      const ids = snap.docs.map((d) => d.id).filter((id) => !seen.has(id));
      for (let i = 0; i < ids.length; i += conc) {
        const out = await Promise.all(ids.slice(i, i + conc).map((id) =>
          syncBusinessGeohash(id, { firestore: fs, dryRun: res.dryRun })));
        for (const r of out) {
          if (r === 'set') res.set++;
          else if (r === 'cleared') res.cleared++;
        }
      }
      ids.forEach((id) => seen.add(id));
      res.scanned += ids.length;
      cursor = snap.docs[snap.docs.length - 1];
      pages++;
      opts.onPage?.(pass, { ...res }, cursor.id);
      if (pages >= maxPages) return res;
      if (snap.size < pageSize) break;
    }
  }
  res.done = true;
  return res;
}
