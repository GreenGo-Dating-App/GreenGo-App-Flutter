/**
 * Hash lists that stop known-bad images from being uploaded again.
 *
 *  - `blocked_media_hashes`  images WE removed (NCII takedowns, confirmed
 *    CSAE). Written by the server when content is hidden (provisional, active
 *    while the case is under review) and confirmed or deactivated by the
 *    admin decision. Never client-readable.
 *  - `csam_hash_list`        external lists (NCMEC / industry hash sharing),
 *    loaded by a superAdmin through safetyAdmin{op:'importCsamHashes'}.
 *    Exact algorithms (md5 / sha1 / sha256) are matched by value; perceptual
 *    ones (dhash / phash, our own format) through the band index. PhotoDNA and
 *    PDQ entries can be stored but are NOT matched yet (TODO: PDQ needs a
 *    hasher implementation; PhotoDNA needs Microsoft's licensed library).
 *
 * See perceptualHash.ts for the band scheme.
 */

import * as admin from 'firebase-admin';
import '../../shared/firebaseAdmin';
import { ImageHashes, hashBands, isPerceptualMatch, isLowInformation } from './perceptualHash';

const db = () => admin.firestore();

export const BLOCKED_MEDIA_HASHES = 'blocked_media_hashes';
export const CSAM_HASH_LIST = 'csam_hash_list';

export type BlockKind = 'ncii' | 'csae';

export interface BlockedHashMatch {
  list: typeof BLOCKED_MEDIA_HASHES | typeof CSAM_HASH_LIST;
  id: string;
  kind: BlockKind;
  caseId: string | null;
  how: 'exact' | 'perceptual';
  distance?: { d: number; p: number };
}

/** Bands for both perceptual hashes (16 strings; array-contains-any allows 30). */
export function allBands(h: Pick<ImageHashes, 'dhash' | 'phash'>): string[] {
  return [...hashBands(h.dhash, 'd'), ...hashBands(h.phash, 'p')];
}

/** Adds (or re-activates) the hashes of an image we removed. Doc id = sha256: one row per exact image. */
export async function addBlockedHash(p: {
  hashes: ImageHashes;
  kind: BlockKind;
  caseId: string;
  provisional: boolean;
  sourcePath: string | null;
}): Promise<string> {
  const id = `${p.kind}_${p.hashes.sha256}`;
  await db().collection(BLOCKED_MEDIA_HASHES).doc(id).set({
    kind: p.kind,
    caseId: p.caseId,
    caseIds: admin.firestore.FieldValue.arrayUnion(p.caseId),
    dhash: p.hashes.dhash,
    phash: p.hashes.phash,
    sha256: p.hashes.sha256,
    md5: p.hashes.md5,
    bands: isLowInformation(p.hashes.dhash) ? [] : allBands(p.hashes),
    active: true,
    provisional: p.provisional,
    // The object path only (no URL token, no user data).
    sourcePath: p.sourcePath,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  return id;
}

/** Activates/deactivates every blocked hash of a case (restore = false, confirm = true). */
export async function setCaseHashesActive(caseId: string, active: boolean): Promise<number> {
  const snap = await db().collection(BLOCKED_MEDIA_HASHES).where('caseIds', 'array-contains', caseId).limit(500).get();
  if (snap.empty) return 0;
  const batch = db().batch();
  snap.docs.forEach((d) => batch.update(d.ref, {
    active,
    provisional: false,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }));
  await batch.commit();
  return snap.size;
}

/** Our own removed images (NCII and confirmed CSAE). */
export async function findBlockedMatch(h: ImageHashes): Promise<BlockedHashMatch | null> {
  const col = db().collection(BLOCKED_MEDIA_HASHES);
  const exact = await col.where('sha256', '==', h.sha256).limit(5).get();
  for (const d of exact.docs) {
    if (d.data().active === true) {
      return { list: BLOCKED_MEDIA_HASHES, id: d.id, kind: d.data().kind, caseId: d.data().caseId ?? null, how: 'exact' };
    }
  }
  if (isLowInformation(h.dhash)) return null;
  const cands = await col.where('bands', 'array-contains-any', allBands(h)).limit(200).get();
  let best: BlockedHashMatch | null = null;
  for (const d of cands.docs) {
    const x = d.data();
    if (x.active !== true) continue;
    const m = isPerceptualMatch(h, { dhash: x.dhash, phash: x.phash });
    if (m.match && (!best || (m.distance.d + m.distance.p) < ((best.distance?.d ?? 99) + (best.distance?.p ?? 99)))) {
      best = { list: BLOCKED_MEDIA_HASHES, id: d.id, kind: x.kind, caseId: x.caseId ?? null, how: 'perceptual', distance: m.distance };
    }
  }
  return best;
}

export const CSAM_ALGORITHMS = ['md5', 'sha1', 'sha256', 'dhash', 'phash', 'pdq', 'photodna'] as const;
export type CsamAlgorithm = typeof CSAM_ALGORITHMS[number];
const HEX_LEN: Partial<Record<CsamAlgorithm, number>> = { md5: 32, sha1: 40, sha256: 64, dhash: 16, phash: 16, pdq: 64 };

/** Validates and normalises one imported hash-list entry; null when invalid. */
export function normaliseCsamEntry(e: any): { algorithm: CsamAlgorithm; hash: string; source: string } | null {
  const algorithm = String(e?.algorithm || '').toLowerCase() as CsamAlgorithm;
  if (!CSAM_ALGORITHMS.includes(algorithm)) return null;
  const hash = String(e?.hash || '').trim().toLowerCase();
  const len = HEX_LEN[algorithm];
  if (len ? !new RegExp(`^[0-9a-f]{${len}}$`).test(hash) : !/^[A-Za-z0-9+/=_-]{8,2048}$/.test(hash)) return null;
  const source = String(e?.source || 'unspecified').slice(0, 80);
  return { algorithm, hash, source };
}

/** External CSAM lists. Exact algorithms by value; dhash/phash entries by band + distance. */
export async function findCsamMatch(h: ImageHashes): Promise<BlockedHashMatch | null> {
  const col = db().collection(CSAM_HASH_LIST);
  const exact = await col.where('hash', 'in', [h.md5, h.sha1, h.sha256]).limit(5).get();
  for (const d of exact.docs) {
    if (d.data().active !== false) {
      return { list: CSAM_HASH_LIST, id: d.id, kind: 'csae', caseId: null, how: 'exact' };
    }
  }
  if (isLowInformation(h.dhash)) return null;
  const cands = await col.where('bands', 'array-contains-any', allBands(h)).limit(200).get();
  for (const d of cands.docs) {
    const x = d.data();
    if (x.active === false) continue;
    // A list entry carries ONE perceptual hash; compare like with like.
    const dist = x.algorithm === 'dhash'
      ? isPerceptualMatch(h, { dhash: x.hash, phash: h.phash })
      : isPerceptualMatch(h, { dhash: h.dhash, phash: x.hash });
    if (dist.match) return { list: CSAM_HASH_LIST, id: d.id, kind: 'csae', caseId: null, how: 'perceptual', distance: dist.distance };
  }
  return null;
}

/** Stores normalised entries (doc id = algorithm_hash: re-imports are idempotent). */
export async function importCsamEntries(entries: unknown[], addedBy: string): Promise<{ added: number; rejected: number }> {
  let added = 0;
  let rejected = 0;
  let batch = db().batch();
  let n = 0;
  for (const raw of entries) {
    const e = normaliseCsamEntry(raw);
    if (!e) { rejected++; continue; }
    const bands = e.algorithm === 'dhash' ? hashBands(e.hash, 'd') : e.algorithm === 'phash' ? hashBands(e.hash, 'p') : [];
    batch.set(db().collection(CSAM_HASH_LIST).doc(`${e.algorithm}_${e.hash.slice(0, 200).replace(/[/]/g, '_')}`), {
      algorithm: e.algorithm,
      hash: e.hash,
      bands,
      source: e.source,
      active: true,
      addedBy,
      addedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    added++;
    if (++n === 400) { await batch.commit(); batch = db().batch(); n = 0; }
  }
  if (n) await batch.commit();
  return { added, rejected };
}
