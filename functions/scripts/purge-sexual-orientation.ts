/**
 * One-off PURGE of the removed sexual-orientation data (legal audit AS-06;
 * closes EU-02 GDPR art. 9, BR-04 LGPD art. 11, US-03 Connecticut/Texas
 * sensitive data, GCC-01 user-safety risk). DRY-RUN BY DEFAULT: pass --apply
 * to write.
 *
 * What it deletes (FieldValue.delete(), nothing else is touched):
 *   profiles/{uid}.sexualOrientation
 *   profiles_private/{uid}.sexualOrientation
 *   users/{uid}.sexualOrientation
 *   users/{uid}.matchPreferences.preferredOrientations   (removed discovery filter)
 *   saved_searches/{uid}/searches/{id}.preferences.preferredOrientations
 *   candidate_pools/{key}.members[].sexualOrientation     (members rewritten)
 *
 * Run it AFTER deploying the functions (candidatePoolPrecompute and
 * mirrorPrivateProfileFields no longer copy the field) and the rules (clients
 * can no longer write a new value), so nothing re-creates what is purged.
 * Re-runnable: profiles / profiles_private / users are read with an indexed
 * `!= null` query, so docs already purged are not even read again;
 * saved searches and candidate pools are small and fully scanned.
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/purge-sexual-orientation.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/purge-sexual-orientation.js [--apply] \
 *     [--page-size 300] [--only profiles,users,...] [--report report.json]
 *
 * The report (stdout, and --report <file>) lists per target: docs scanned,
 * docs that held the data, docs updated, errors, and up to 20 sample ids. It
 * never prints the orientation values themselves.
 */
import * as admin from 'firebase-admin';
import * as fsNode from 'fs';

type Firestore = admin.firestore.Firestore;

/** A query target: docs whose [field] is not null are purged. */
export interface QueryTarget {
  kind: 'query';
  name: string;
  collection: string;
  /** Dotted field path that is deleted. */
  field: string;
}

/** A scanned target (collection group or array rewrite). */
export interface ScanTarget {
  kind: 'scan';
  name: string;
  /** Collection id; with [group] a collection-group scan. */
  collection: string;
  group?: boolean;
}

export const QUERY_TARGETS: QueryTarget[] = [
  { kind: 'query', name: 'profiles', collection: 'profiles', field: 'sexualOrientation' },
  { kind: 'query', name: 'profiles_private', collection: 'profiles_private', field: 'sexualOrientation' },
  { kind: 'query', name: 'users', collection: 'users', field: 'sexualOrientation' },
  { kind: 'query', name: 'users.matchPreferences', collection: 'users', field: 'matchPreferences.preferredOrientations' },
];

export const SCAN_TARGETS: ScanTarget[] = [
  { kind: 'scan', name: 'saved_searches', collection: 'searches', group: true },
  { kind: 'scan', name: 'candidate_pools', collection: 'candidate_pools' },
];

export const TARGET_NAMES = [...QUERY_TARGETS, ...SCAN_TARGETS].map((t) => t.name);

export interface TargetReport {
  target: string;
  scanned: number;
  matched: number;
  updated: number;
  errors: number;
  sampleIds: string[];
}

export interface PurgeReport {
  apply: boolean;
  startedAt: string;
  finishedAt: string;
  targets: TargetReport[];
  totalMatched: number;
  totalUpdated: number;
  totalErrors: number;
}

const SAMPLE_MAX = 20;

/**
 * The update (dotted paths -> delete sentinel) that removes the orientation
 * data from a saved search doc, or null when there is nothing to remove.
 */
export function savedSearchUpdate(data: Record<string, any> | undefined): Record<string, any> | null {
  const prefs = data?.preferences;
  if (!prefs || typeof prefs !== 'object' || !('preferredOrientations' in prefs)) return null;
  return { 'preferences.preferredOrientations': admin.firestore.FieldValue.delete() };
}

/**
 * Pool members without `sexualOrientation`, or null when no member had it.
 * Every other member key is kept as it is.
 */
export function poolMembersWithoutOrientation(data: Record<string, any> | undefined): any[] | null {
  const members = data?.members;
  if (!Array.isArray(members)) return null;
  let changed = false;
  const out = members.map((m) => {
    if (m && typeof m === 'object' && 'sexualOrientation' in m) {
      changed = true;
      const { sexualOrientation: _drop, ...rest } = m;
      return rest;
    }
    return m;
  });
  return changed ? out : null;
}

function emptyReport(name: string): TargetReport {
  return { target: name, scanned: 0, matched: 0, updated: 0, errors: 0, sampleIds: [] };
}

function note(r: TargetReport, path: string) {
  r.matched++;
  if (r.sampleIds.length < SAMPLE_MAX) r.sampleIds.push(path);
}

/** Commits [writes] in one batch; on failure retries one by one (a doc may be gone). */
async function commitAll(
  fs: Firestore,
  writes: Array<{ ref: admin.firestore.DocumentReference; update: Record<string, any> }>,
  r: TargetReport,
  log: (m: string) => void,
) {
  if (!writes.length) return;
  const batch = fs.batch();
  for (const w of writes) batch.update(w.ref, w.update);
  try {
    await batch.commit();
    r.updated += writes.length;
  } catch (e: any) {
    log(`batch failed (${e?.code ?? e?.message ?? e}); retrying ${writes.length} docs one by one`);
    for (const w of writes) {
      try {
        await w.ref.update(w.update);
        r.updated++;
      } catch (e2: any) {
        // NOT_FOUND (5): deleted meanwhile, nothing left to purge.
        if (e2?.code !== 5) {
          r.errors++;
          log(`update failed for ${w.ref.path}: ${e2?.code ?? e2?.message ?? e2}`);
        }
      }
    }
  }
}

async function purgeQueryTarget(
  fs: Firestore, t: QueryTarget, apply: boolean, pageSize: number, log: (m: string) => void,
): Promise<TargetReport> {
  const r = emptyReport(t.name);
  let cursor: admin.firestore.QueryDocumentSnapshot | null = null;
  for (;;) {
    // `!= null` matches only docs that hold a (non-null) value; ordered by
    // (field, __name__), so the cursor stays valid while purged docs leave
    // the result set.
    let q = fs.collection(t.collection).where(t.field, '!=', null).limit(pageSize);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.select(t.field).get();
    if (snap.empty) break;
    r.scanned += snap.size;
    const writes = snap.docs.map((d) => {
      note(r, d.ref.path);
      return { ref: d.ref, update: { [t.field]: admin.firestore.FieldValue.delete() } };
    });
    if (apply) await commitAll(fs, writes, r, log);
    cursor = snap.docs[snap.docs.length - 1];
    log(`${t.name}: scanned=${r.scanned} ${apply ? 'purged' : 'would purge'}=${r.matched}`);
    if (snap.size < pageSize) break;
  }
  return r;
}

async function purgeScanTarget(
  fs: Firestore, t: ScanTarget, apply: boolean, pageSize: number, log: (m: string) => void,
): Promise<TargetReport> {
  const r = emptyReport(t.name);
  let cursor: admin.firestore.QueryDocumentSnapshot | null = null;
  const base: admin.firestore.Query = t.group ? fs.collectionGroup(t.collection) : fs.collection(t.collection);
  // Pools are up to ~1 MB each: smaller pages.
  const size = t.name === 'candidate_pools' ? Math.min(pageSize, 20) : pageSize;
  for (;;) {
    let q = base.orderBy(admin.firestore.FieldPath.documentId()).limit(size);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.get();
    if (snap.empty) break;
    r.scanned += snap.size;
    const writes: Array<{ ref: admin.firestore.DocumentReference; update: Record<string, any> }> = [];
    for (const d of snap.docs) {
      let update: Record<string, any> | null = null;
      if (t.name === 'candidate_pools') {
        const members = poolMembersWithoutOrientation(d.data());
        if (members) update = { members };
      } else {
        update = savedSearchUpdate(d.data());
      }
      if (!update) continue;
      note(r, d.ref.path);
      writes.push({ ref: d.ref, update });
    }
    if (apply) {
      // Pool docs are large: commit those one at a time.
      if (t.name === 'candidate_pools') {
        for (const w of writes) await commitAll(fs, [w], r, log);
      } else {
        await commitAll(fs, writes, r, log);
      }
    }
    cursor = snap.docs[snap.docs.length - 1];
    log(`${t.name}: scanned=${r.scanned} ${apply ? 'purged' : 'would purge'}=${r.matched}`);
    if (snap.size < size) break;
  }
  return r;
}

export async function runPurge(
  fs: Firestore,
  opts: { apply?: boolean; pageSize?: number; only?: string[]; log?: (m: string) => void } = {},
): Promise<PurgeReport> {
  const apply = opts.apply === true;
  const pageSize = Math.max(1, Math.min(opts.pageSize ?? 300, 400));
  const log = opts.log ?? (() => undefined);
  const only = opts.only && opts.only.length ? new Set(opts.only) : null;
  const startedAt = new Date().toISOString();
  const targets: TargetReport[] = [];
  for (const t of QUERY_TARGETS) {
    if (only && !only.has(t.name)) continue;
    targets.push(await purgeQueryTarget(fs, t, apply, pageSize, log));
  }
  for (const t of SCAN_TARGETS) {
    if (only && !only.has(t.name)) continue;
    targets.push(await purgeScanTarget(fs, t, apply, pageSize, log));
  }
  const sum = (k: 'matched' | 'updated' | 'errors') => targets.reduce((a, t) => a + t[k], 0);
  return {
    apply,
    startedAt,
    finishedAt: new Date().toISOString(),
    targets,
    totalMatched: sum('matched'),
    totalUpdated: sum('updated'),
    totalErrors: sum('errors'),
  };
}

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

async function main() {
  if (!admin.apps.length) admin.initializeApp();
  const fs = admin.firestore();
  const apply = process.argv.includes('--apply');
  const only = arg('--only')?.split(',').map((s) => s.trim()).filter(Boolean);
  const unknown = (only ?? []).filter((n) => !TARGET_NAMES.includes(n));
  if (unknown.length) throw new Error(`unknown --only target(s): ${unknown.join(', ')} (known: ${TARGET_NAMES.join(', ')})`);
  const report = await runPurge(fs, {
    apply,
    pageSize: Number(arg('--page-size') ?? 300),
    only,
    log: (m) => console.log(m),
  });
  console.log(apply ? 'APPLIED' : '[DRY RUN - pass --apply to write]');
  console.log(JSON.stringify(report, null, 2));
  const out = arg('--report');
  if (out) fsNode.writeFileSync(out, JSON.stringify(report, null, 2));
  if (report.totalErrors) process.exit(2);
}

if (require.main === module) main().catch((e) => { console.error(e); process.exit(1); });
