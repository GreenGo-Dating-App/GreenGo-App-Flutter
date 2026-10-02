/**
 * Path-based in-memory Firestore fake (no network) for the booking tests.
 *
 * Unlike stripeFakes.ts (flat collections, equality only) this supports
 * subcollections (doc().collection()), collectionGroup(), dotted field paths,
 * ==, !=, <, <=, >, >=, in, array-contains filters, orderBy, limit,
 * Timestamp comparison, WriteBatch, recursiveDelete and SERIALISED
 * transactions (Firestore transactions are serialisable, so running them one
 * at a time models concurrent callers). FieldValue.delete() and
 * serverTimestamp() are honoured.
 */

import * as admin from 'firebase-admin';

type Data = Record<string, any>;

const DELETE = admin.firestore.FieldValue.delete();
const SERVER_TS = admin.firestore.FieldValue.serverTimestamp();

function isSentinel(v: any, s: any): boolean {
  return !!v && typeof v === 'object' && typeof v.isEqual === 'function' && v.isEqual(s);
}

function isPlainObject(v: any): boolean {
  return !!v && typeof v === 'object' && !Array.isArray(v) && Object.getPrototypeOf(v) === Object.prototype;
}

function resolveValue(v: any): any {
  if (isSentinel(v, SERVER_TS)) return admin.firestore.Timestamp.now();
  if (Array.isArray(v)) return v.map(resolveValue);
  if (isPlainObject(v)) {
    const o: Data = {};
    for (const [k, x] of Object.entries(v)) if (!isSentinel(x, DELETE)) o[k] = resolveValue(x);
    return o;
  }
  return v;
}

function deepMerge(base: Data, patch: Data): Data {
  const out: Data = { ...base };
  for (const [k, v] of Object.entries(patch)) {
    if (isSentinel(v, DELETE)) delete out[k];
    else if (isPlainObject(v) && isPlainObject(out[k])) out[k] = deepMerge(out[k], v);
    else out[k] = resolveValue(v);
  }
  return out;
}

function setPath(obj: Data, path: string, v: any): void {
  const parts = path.split('.');
  let cur = obj;
  for (let i = 0; i < parts.length - 1; i++) {
    if (!isPlainObject(cur[parts[i]])) cur[parts[i]] = {};
    cur = cur[parts[i]];
  }
  const last = parts[parts.length - 1];
  if (isSentinel(v, DELETE)) delete cur[last];
  else cur[last] = resolveValue(v);
}

function getPath(obj: Data, path: string): any {
  return path.split('.').reduce((o: any, k) => (o === null || o === undefined ? undefined : o[k]), obj);
}

function cmpKey(v: any): any {
  if (v && typeof v.toMillis === 'function') return v.toMillis();
  if (v instanceof Date) return v.getTime();
  return v;
}

function eq(a: any, b: any): boolean {
  return cmpKey(a) === cmpKey(b);
}

class FakeSnap {
  constructor(public ref: FakeDocRef, private readonly d: Data | undefined) {}
  get id() { return this.ref.id; }
  get exists() { return this.d !== undefined; }
  data() { return this.d === undefined ? undefined : JSON.parse(JSON.stringify(this.d), reviveTs); }
  get(field: string) { return this.d === undefined ? undefined : getPath(this.d, field); }
}

/** Keeps Timestamps as Timestamps through the defensive copy in data(). */
function reviveTs(_k: string, v: any) {
  if (v && typeof v === 'object' && typeof v._seconds === 'number' && typeof v._nanoseconds === 'number' &&
      Object.keys(v).length === 2) {
    return new admin.firestore.Timestamp(v._seconds, v._nanoseconds);
  }
  return v;
}

export class FakeDocRef {
  constructor(public db: PathFakeFirestore, public path: string) {}
  get id() { return this.path.split('/').pop() as string; }
  get parent() { return new FakeCollection(this.db, this.path.split('/').slice(0, -1).join('/')); }
  collection(name: string) { return new FakeCollection(this.db, `${this.path}/${name}`); }
  async get() { return new FakeSnap(this, this.db.raw(this.path)); }
  async set(data: Data, opts?: { merge?: boolean }) { this.db.setDoc(this.path, data, !!opts?.merge); }
  async update(data: Data) { this.db.updateDoc(this.path, data); }
  async create(data: Data) { this.db.createDoc(this.path, data); }
  async delete() { this.db.remove(this.path); }
}

type Filter = [string, string, any];

class FakeQuery {
  constructor(
    public db: PathFakeFirestore,
    public source: { collection?: string; group?: string },
    protected filters: Filter[] = [],
    protected orders: Array<[string, 'asc' | 'desc']> = [],
    protected max = Infinity,
  ) {}
  where(field: string, op: string, value: any) {
    return new FakeQuery(this.db, this.source, [...this.filters, [field, op, value]], this.orders, this.max);
  }
  orderBy(field: any, dir: 'asc' | 'desc' = 'asc') {
    const f = typeof field === 'string' ? field : '__name__';
    return new FakeQuery(this.db, this.source, this.filters, [...this.orders, [f, dir]], this.max);
  }
  limit(n: number) { return new FakeQuery(this.db, this.source, this.filters, this.orders, n); }
  startAfter() { return this; }
  async get() {
    let rows = this.db.list(this.source).filter(([, d]) => this.filters.every(([f, op, v]) => {
      const x = getPath(d, f);
      switch (op) {
        case '==': return eq(x, v);
        case '!=': return x !== undefined && !eq(x, v);
        case '<': return x !== undefined && cmpKey(x) < cmpKey(v);
        case '<=': return x !== undefined && cmpKey(x) <= cmpKey(v);
        case '>': return x !== undefined && cmpKey(x) > cmpKey(v);
        case '>=': return x !== undefined && cmpKey(x) >= cmpKey(v);
        case 'in': return Array.isArray(v) && v.some((y) => eq(x, y));
        case 'array-contains': return Array.isArray(x) && x.some((y) => eq(y, v));
        default: throw new Error(`unsupported op ${op}`);
      }
    }));
    for (const [f] of this.orders) rows = rows.filter(([, d]) => f === '__name__' || getPath(d, f) !== undefined);
    if (this.orders.length) {
      rows = [...rows].sort((a, b) => {
        for (const [f, dir] of this.orders) {
          const x = f === '__name__' ? a[0] : cmpKey(getPath(a[1], f));
          const y = f === '__name__' ? b[0] : cmpKey(getPath(b[1], f));
          if (x < y) return dir === 'asc' ? -1 : 1;
          if (x > y) return dir === 'asc' ? 1 : -1;
        }
        return 0;
      });
    }
    const docs = rows.slice(0, this.max).map(([p, d]) => new FakeSnap(new FakeDocRef(this.db, p), d));
    return { docs, empty: docs.length === 0, size: docs.length };
  }
}

class FakeCollection extends FakeQuery {
  constructor(db: PathFakeFirestore, public path: string) {
    super(db, { collection: path });
  }
  get id() { return this.path.split('/').pop() as string; }
  doc(id?: string) { return new FakeDocRef(this.db, `${this.path}/${id || this.db.autoId()}`); }
  async add(data: Data) {
    const ref = this.doc();
    await ref.set(data);
    return ref;
  }
}

class FakeWriter {
  protected ops: Array<() => void> = [];
  constructor(protected db: PathFakeFirestore) {}
  set(ref: FakeDocRef, data: Data, opts?: { merge?: boolean }) {
    this.ops.push(() => this.db.setDoc(ref.path, data, !!opts?.merge));
    return this;
  }
  update(ref: FakeDocRef, data: Data) {
    this.ops.push(() => this.db.updateDoc(ref.path, data));
    return this;
  }
  create(ref: FakeDocRef, data: Data) {
    this.ops.push(() => this.db.createDoc(ref.path, data));
    return this;
  }
  delete(ref: FakeDocRef) {
    this.ops.push(() => this.db.remove(ref.path));
    return this;
  }
  applyAll() {
    const ops = this.ops;
    this.ops = [];
    for (const op of ops) op();
  }
}

class FakeBatch extends FakeWriter {
  async commit() { this.applyAll(); }
}

class FakeTx extends FakeWriter {
  private wrote = false;
  async get(target: FakeDocRef | FakeQuery) {
    if (this.ops.length > 0 || this.wrote) throw new Error('Firestore transactions require all reads before writes');
    return target.get();
  }
  set(ref: FakeDocRef, data: Data, opts?: { merge?: boolean }) { this.wrote = true; return super.set(ref, data, opts); }
  update(ref: FakeDocRef, data: Data) { this.wrote = true; return super.update(ref, data); }
  create(ref: FakeDocRef, data: Data) { this.wrote = true; return super.create(ref, data); }
  delete(ref: FakeDocRef) { this.wrote = true; return super.delete(ref); }
}

export class PathFakeFirestore {
  private store = new Map<string, Data>();
  private lock: Promise<void> = Promise.resolve();
  private n = 0;
  transactions = 0;

  autoId() { return `auto_${++this.n}`; }
  collection(path: string) { return new FakeCollection(this, path); }
  collectionGroup(name: string) { return new FakeQuery(this, { group: name }); }
  doc(path: string) { return new FakeDocRef(this, path); }
  batch() { return new FakeBatch(this); }

  async runTransaction<T>(fn: (tx: FakeTx) => Promise<T>): Promise<T> {
    const prev = this.lock;
    let release!: () => void;
    this.lock = new Promise<void>((r) => { release = r; });
    await prev;
    try {
      this.transactions++;
      const tx = new FakeTx(this);
      const result = await fn(tx);
      tx.applyAll();
      return result;
    } finally {
      release();
    }
  }

  async recursiveDelete(ref: FakeCollection | FakeDocRef) {
    const prefix = `${ref.path}/`;
    for (const p of [...this.store.keys()]) if (p === ref.path || p.startsWith(prefix)) this.store.delete(p);
  }

  // ---- internals / raw access ----
  raw(path: string): Data | undefined { return this.store.get(path); }
  list(source: { collection?: string; group?: string }): Array<[string, Data]> {
    const out: Array<[string, Data]> = [];
    for (const [p, d] of this.store) {
      const segs = p.split('/');
      if (source.collection !== undefined) {
        if (segs.slice(0, -1).join('/') === source.collection) out.push([p, d]);
      } else if (segs.length >= 2 && segs[segs.length - 2] === source.group) {
        out.push([p, d]);
      }
    }
    return out;
  }
  setDoc(path: string, data: Data, merge: boolean) {
    const existing = this.store.get(path);
    this.store.set(path, merge && existing ? deepMerge(existing, data) : deepMerge({}, data));
  }
  updateDoc(path: string, data: Data) {
    const existing = this.store.get(path);
    if (!existing) throw new Error(`NOT_FOUND ${path}`);
    const next = JSON.parse(JSON.stringify(existing), reviveTs);
    for (const [k, v] of Object.entries(data)) setPath(next, k, v);
    this.store.set(path, next);
  }
  createDoc(path: string, data: Data) {
    if (this.store.has(path)) throw new Error(`ALREADY_EXISTS ${path}`);
    this.store.set(path, deepMerge({}, data));
  }
  remove(path: string) { this.store.delete(path); }
  seed(path: string, data: Data) { this.setDoc(path, data, false); }
  get(path: string) {
    const d = this.store.get(path);
    return d === undefined ? undefined : JSON.parse(JSON.stringify(d), reviveTs);
  }
  count(collectionPath: string) { return this.list({ collection: collectionPath }).length; }
}
