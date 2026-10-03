"use strict";
/**
 * Minimal in-memory Firestore for the follow-graph unit tests — only the
 * surface followCounters.ts / followCleanup.ts use. Not a test file itself.
 */
/* eslint-disable @typescript-eslint/no-explicit-any */
Object.defineProperty(exports, "__esModule", { value: true });
exports.increment = void 0;
exports.makeDb = makeDb;
const INC = Symbol('inc');
const increment = (n) => ({ [INC]: n });
exports.increment = increment;
function makeDb() {
    const store = new Map();
    /** Called after every document delete (simulates a delete trigger). */
    const deleteListeners = [];
    const remove = (path) => {
        const old = store.get(path);
        store.delete(path);
        if (old)
            deleteListeners.forEach((l) => l(path, old));
    };
    const snap = (path) => {
        const data = store.get(path);
        return {
            id: path.split('/').pop(),
            ref: ref(path),
            exists: data !== undefined,
            data: () => (data ? Object.assign({}, data) : undefined),
            get: (f) => data === null || data === void 0 ? void 0 : data[f],
        };
    };
    const applyUpdate = (path, patch) => {
        const cur = store.get(path);
        if (!cur)
            throw new Error(`NOT_FOUND: ${path}`);
        const next = Object.assign({}, cur);
        for (const [k, v] of Object.entries(patch)) {
            next[k] = v && typeof v === 'object' && INC in v ? (Number(next[k]) || 0) + v[INC] : v;
        }
        store.set(path, next);
    };
    const ref = (path) => ({
        path,
        id: path.split('/').pop(),
        collection: (c) => col(`${path}/${c}`),
        get: async () => snap(path),
        set: async (d) => void store.set(path, Object.assign({}, d)),
        create: async (d) => {
            if (store.has(path))
                throw Object.assign(new Error('ALREADY_EXISTS'), { code: 6 });
            store.set(path, Object.assign({}, d));
        },
        update: async (d) => applyUpdate(path, d),
        delete: async () => remove(path),
    });
    const list = (colPath, n) => {
        const depth = colPath.split('/').length + 1;
        const docs = [...store.keys()]
            .filter((k) => k.startsWith(`${colPath}/`) && k.split('/').length === depth)
            .sort()
            .slice(0, n)
            .map(snap);
        return { empty: docs.length === 0, size: docs.length, docs };
    };
    const col = (path) => ({
        doc: (id) => ref(`${path}/${id}`),
        limit: (n) => ({ get: async () => list(path, n) }),
    });
    const db = {
        collection: (c) => col(c),
        getAll: async (...refs) => refs.map((r) => snap(r.path)),
        batch() {
            const writes = [];
            return {
                delete: (r) => void writes.push(() => remove(r.path)),
                update: (r, d) => void writes.push(() => applyUpdate(r.path, d)),
                set: (r, d) => void writes.push(() => store.set(r.path, Object.assign({}, d))),
                commit: async () => {
                    writes.forEach((w) => w());
                },
            };
        },
        async runTransaction(fn) {
            const writes = [];
            const txn = {
                get: async (r) => snap(r.path),
                update: (r, d) => void writes.push(() => applyUpdate(r.path, d)),
                set: (r, d) => void writes.push(() => store.set(r.path, Object.assign({}, d))),
                create: (r, d) => void writes.push(() => store.set(r.path, Object.assign({}, d))),
                delete: (r) => void writes.push(() => remove(r.path)),
            };
            const result = await fn(txn);
            writes.forEach((w) => w());
            return result;
        },
    };
    return { db, store, onDelete: (l) => deleteListeners.push(l) };
}
//# sourceMappingURL=fakeFirestore.js.map