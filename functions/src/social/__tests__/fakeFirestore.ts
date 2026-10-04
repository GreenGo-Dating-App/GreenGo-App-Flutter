/**
 * Minimal in-memory Firestore for the follow-graph unit tests — only the
 * surface followCounters.ts / followCleanup.ts / attractionRatingAggregate.ts
 * use. Not a test file itself.
 */
/* eslint-disable @typescript-eslint/no-explicit-any */

export type Doc = Record<string, any>;
const INC = Symbol('inc');
export const increment = (n: number) => ({ [INC]: n });

export function makeDb() {
  const store = new Map<string, Doc>();
  /** Called after every document delete (simulates a delete trigger). */
  const deleteListeners: Array<(path: string, old: Doc) => void> = [];

  const remove = (path: string) => {
    const old = store.get(path);
    store.delete(path);
    if (old) deleteListeners.forEach((l) => l(path, old));
  };

  const snap = (path: string): any => {
    const data = store.get(path);
    return {
      id: path.split('/').pop(),
      ref: ref(path),
      exists: data !== undefined,
      data: () => (data ? { ...data } : undefined),
      get: (f: string) => data?.[f],
    };
  };

  const applyUpdate = (path: string, patch: Doc) => {
    const cur = store.get(path);
    if (!cur) throw new Error(`NOT_FOUND: ${path}`);
    const next = { ...cur };
    for (const [k, v] of Object.entries(patch)) {
      next[k] = v && typeof v === 'object' && INC in v ? (Number(next[k]) || 0) + v[INC] : v;
    }
    store.set(path, next);
  };

  /** `set(d)` replaces; `set(d, { merge: true })` shallow-merges. */
  const applySet = (path: string, d: Doc, opts?: { merge?: boolean }) =>
    void store.set(path, opts?.merge ? { ...(store.get(path) ?? {}), ...d } : { ...d });

  const ref = (path: string): any => ({
    path,
    id: path.split('/').pop(),
    collection: (c: string) => col(`${path}/${c}`),
    get: async () => snap(path),
    set: async (d: Doc, opts?: { merge?: boolean }) => applySet(path, d, opts),
    create: async (d: Doc) => {
      if (store.has(path)) throw Object.assign(new Error('ALREADY_EXISTS'), { code: 6 });
      store.set(path, { ...d });
    },
    update: async (d: Doc) => applyUpdate(path, d),
    delete: async () => remove(path),
  });

  const list = (colPath: string, n: number) => {
    const depth = colPath.split('/').length + 1;
    const docs = [...store.keys()]
      .filter((k) => k.startsWith(`${colPath}/`) && k.split('/').length === depth)
      .sort()
      .slice(0, n)
      .map(snap);
    return { empty: docs.length === 0, size: docs.length, docs };
  };

  const col = (path: string): any => ({
    doc: (id: string) => ref(`${path}/${id}`),
    limit: (n: number) => ({ get: async () => list(path, n) }),
  });

  const db: any = {
    collection: (c: string) => col(c),
    getAll: async (...refs: any[]) => refs.map((r) => snap(r.path)),
    batch() {
      const writes: Array<() => void> = [];
      return {
        delete: (r: any) => void writes.push(() => remove(r.path)),
        update: (r: any, d: Doc) => void writes.push(() => applyUpdate(r.path, d)),
        set: (r: any, d: Doc, o?: { merge?: boolean }) =>
          void writes.push(() => applySet(r.path, d, o)),
        commit: async () => {
          writes.forEach((w) => w());
        },
      };
    },
    async runTransaction(fn: (txn: any) => Promise<any>) {
      const writes: Array<() => void> = [];
      const txn = {
        get: async (r: any) => snap(r.path),
        update: (r: any, d: Doc) => void writes.push(() => applyUpdate(r.path, d)),
        set: (r: any, d: Doc, o?: { merge?: boolean }) =>
          void writes.push(() => applySet(r.path, d, o)),
        create: (r: any, d: Doc) => void writes.push(() => store.set(r.path, { ...d })),
        delete: (r: any) => void writes.push(() => remove(r.path)),
      };
      const result = await fn(txn);
      writes.forEach((w) => w());
      return result;
    },
  };
  return { db, store, onDelete: (l: (path: string, old: Doc) => void) => deleteListeners.push(l) };
}
