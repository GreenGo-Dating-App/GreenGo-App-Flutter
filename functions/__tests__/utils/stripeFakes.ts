/**
 * In-memory Firestore + Stripe fakes for the Stripe unit tests (no network).
 *
 * FakeFirestore supports what payments/stripeCore.ts and stripeReconcile.ts
 * use: doc get/set(merge)/update/create/delete, equality + `in` queries with
 * limit, WriteBatch, and SERIALISED transactions (Firestore transactions are
 * serialisable, so running them one at a time models concurrent deliveries).
 * FieldValue.delete() and serverTimestamp() are honoured.
 */

import * as admin from 'firebase-admin';

type Data = Record<string, any>;

const DELETE = admin.firestore.FieldValue.delete();
const SERVER_TS = admin.firestore.FieldValue.serverTimestamp();

function isSentinel(v: any, s: any): boolean {
  return !!v && typeof v === 'object' && typeof v.isEqual === 'function' && v.isEqual(s);
}

function applyWrite(existing: Data | undefined, data: Data, merge: boolean): Data {
  const out: Data = merge && existing ? { ...existing } : {};
  for (const [k, v] of Object.entries(data)) {
    if (isSentinel(v, DELETE)) delete out[k];
    else if (isSentinel(v, SERVER_TS)) out[k] = admin.firestore.Timestamp.now();
    else out[k] = Array.isArray(v) ? [...v] : v;
  }
  return out;
}

class FakeSnap {
  constructor(public ref: FakeDocRef, private readonly d: Data | undefined) {}
  get id() { return this.ref.id; }
  get exists() { return this.d !== undefined; }
  data() { return this.d === undefined ? undefined : { ...this.d }; }
}

export class FakeDocRef {
  constructor(public db: FakeFirestore, public col: string, public id: string) {}
  get path() { return `${this.col}/${this.id}`; }
  async get() { return new FakeSnap(this, this.db.raw(this.col, this.id)); }
  async set(data: Data, opts?: { merge?: boolean }) { this.db.write(this.col, this.id, data, !!opts?.merge); }
  async update(data: Data) {
    if (!this.db.raw(this.col, this.id)) throw new Error(`NOT_FOUND ${this.path}`);
    this.db.write(this.col, this.id, data, true);
  }
  async create(data: Data) {
    if (this.db.raw(this.col, this.id)) throw new Error(`ALREADY_EXISTS ${this.path}`);
    this.db.write(this.col, this.id, data, false);
  }
  async delete() { this.db.remove(this.col, this.id); }
}

class FakeQuery {
  constructor(
    public db: FakeFirestore,
    public col: string,
    protected filters: Array<[string, string, any]> = [],
    protected max = Infinity,
  ) {}
  where(field: string, op: string, value: any) {
    return new FakeQuery(this.db, this.col, [...this.filters, [field, op, value]], this.max);
  }
  limit(n: number) { return new FakeQuery(this.db, this.col, this.filters, n); }
  orderBy() { return this; }
  async get() {
    const docs: FakeSnap[] = [];
    for (const [id, d] of this.db.all(this.col)) {
      const ok = this.filters.every(([f, op, v]) => {
        if (op === '==') return d[f] === v;
        if (op === 'in') return Array.isArray(v) && v.includes(d[f]);
        throw new Error(`unsupported op ${op}`);
      });
      if (ok) docs.push(new FakeSnap(new FakeDocRef(this.db, this.col, id), d));
      if (docs.length >= this.max) break;
    }
    return { docs, empty: docs.length === 0, size: docs.length };
  }
}

class FakeCollection extends FakeQuery {
  doc(id?: string) { return new FakeDocRef(this.db, this.col, id || this.db.autoId()); }
  async add(data: Data) {
    const ref = this.doc();
    await ref.set(data);
    return ref;
  }
}

type Op = () => void;

class FakeWriter {
  protected ops: Op[] = [];
  constructor(protected db: FakeFirestore) {}
  set(ref: FakeDocRef, data: Data, opts?: { merge?: boolean }) {
    this.ops.push(() => this.db.write(ref.col, ref.id, data, !!opts?.merge));
    return this;
  }
  update(ref: FakeDocRef, data: Data) {
    this.ops.push(() => {
      if (!this.db.raw(ref.col, ref.id)) throw new Error(`NOT_FOUND ${ref.path}`);
      this.db.write(ref.col, ref.id, data, true);
    });
    return this;
  }
  create(ref: FakeDocRef, data: Data) {
    this.ops.push(() => {
      if (this.db.raw(ref.col, ref.id)) throw new Error(`ALREADY_EXISTS ${ref.path}`);
      this.db.write(ref.col, ref.id, data, false);
    });
    return this;
  }
  delete(ref: FakeDocRef) {
    this.ops.push(() => this.db.remove(ref.col, ref.id));
    return this;
  }
  applyAll() { for (const op of this.ops) op(); this.ops = []; }
}

class FakeBatch extends FakeWriter {
  async commit() { this.applyAll(); }
}

class FakeTx extends FakeWriter {
  async get(target: FakeDocRef | FakeQuery) { return target.get(); }
}

export class FakeFirestore {
  private store = new Map<string, Map<string, Data>>();
  private lock: Promise<void> = Promise.resolve();
  private n = 0;
  transactions = 0;

  autoId() { return `auto_${++this.n}`; }
  collection(name: string) { return new FakeCollection(this, name); }
  doc(path: string) {
    const [c, id] = path.split('/');
    return new FakeDocRef(this, c, id);
  }
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

  // ---- raw access (tests + internals) ----
  raw(col: string, id: string): Data | undefined {
    return this.store.get(col)?.get(id);
  }
  all(col: string): Array<[string, Data]> {
    return [...(this.store.get(col)?.entries() || [])];
  }
  write(col: string, id: string, data: Data, merge: boolean) {
    if (!this.store.has(col)) this.store.set(col, new Map());
    const m = this.store.get(col)!;
    m.set(id, applyWrite(m.get(id), data, merge));
  }
  remove(col: string, id: string) { this.store.get(col)?.delete(id); }
  seed(col: string, id: string, data: Data) { this.write(col, id, data, false); }
  get(col: string, id: string) { return this.raw(col, id); }
  count(col: string) { return this.store.get(col)?.size || 0; }
}

// ---------------------------------------------------------------------------
// Stripe fake
// ---------------------------------------------------------------------------

export interface StripeState {
  customers: Record<string, any>;
  subscriptions: Record<string, any>;
  invoices: Record<string, any>;
  charges: Record<string, any>;
  sessions: Record<string, any>;
  refunds: Record<string, any>;
  disputes: Record<string, any>;
}

export function emptyStripeState(): StripeState {
  return { customers: {}, subscriptions: {}, invoices: {}, charges: {}, sessions: {}, refunds: {}, disputes: {} };
}

const clone = (x: any) => (x === undefined || x === null ? x : JSON.parse(JSON.stringify(x)));

function notFound(kind: string, id: string): Error {
  const e: any = new Error(`No such ${kind}: ${id}`);
  e.statusCode = 404;
  return e;
}

function inCreated(obj: any, created: any): boolean {
  if (!created) return true;
  if (typeof created === 'number') return obj.created === created;
  return (created.gte === undefined || (obj.created ?? 0) >= created.gte);
}

function page(list: any[], params: any) {
  let data = list;
  if (params?.starting_after) {
    const i = data.findIndex((x) => x.id === params.starting_after);
    data = i >= 0 ? data.slice(i + 1) : [];
  }
  const limit = params?.limit ?? 10;
  return { object: 'list', data: data.slice(0, limit), has_more: data.length > limit };
}

export function makeFakeStripe(state: StripeState) {
  const calls: Record<string, any[]> = { cancel: [] };

  const invoiceWith = (id: string, expand: string[] = []) => {
    const inv = clone(state.invoices[id]);
    if (!inv) throw notFound('invoice', id);
    if (expand.includes('charge') && typeof inv.charge === 'string') inv.charge = clone(state.charges[inv.charge]) ?? inv.charge;
    return inv;
  };

  const subWith = (id: string, expand: string[] = []) => {
    const sub = clone(state.subscriptions[id]);
    if (!sub) throw notFound('subscription', id);
    if (expand.some((e) => e.startsWith('latest_invoice')) && typeof sub.latest_invoice === 'string') {
      sub.latest_invoice = invoiceWith(sub.latest_invoice, expand.includes('latest_invoice.charge') ? ['charge'] : []);
    }
    if (expand.includes('customer') && typeof sub.customer === 'string') sub.customer = clone(state.customers[sub.customer]) ?? sub.customer;
    return sub;
  };

  const stripe: any = {
    calls,
    customers: {
      retrieve: async (id: string) => {
        const c = clone(state.customers[id]);
        if (!c) throw notFound('customer', id);
        return c;
      },
      create: async (params: any) => {
        const id = `cus_new_${Object.keys(state.customers).length + 1}`;
        state.customers[id] = { id, ...params };
        return clone(state.customers[id]);
      },
    },
    subscriptions: {
      retrieve: async (id: string, p?: any) => subWith(id, p?.expand || []),
      list: async (p: any) => {
        const expand = (p?.expand || []).map((e: string) => e.replace(/^data\./, ''));
        const all = Object.values(state.subscriptions)
          .filter((s: any) => !p?.customer || s.customer === p.customer)
          .map((s: any) => subWith(s.id, expand));
        return page(all, p);
      },
      cancel: async (id: string, p?: any) => {
        calls.cancel.push({ id, params: p });
        if (state.subscriptions[id]) state.subscriptions[id].status = 'canceled';
        return clone(state.subscriptions[id]);
      },
    },
    invoices: {
      retrieve: async (id: string, p?: any) => invoiceWith(id, p?.expand || []),
      list: async (p: any) => {
        const expand = (p?.expand || []).map((e: string) => e.replace(/^data\./, ''));
        const all = Object.values(state.invoices)
          .filter((i: any) => (!p?.subscription || i.subscription === p.subscription)
            && (!p?.status || i.status === p.status) && inCreated(i, p?.created))
          .map((i: any) => invoiceWith(i.id, expand));
        return page(all, p);
      },
    },
    charges: {
      retrieve: async (id: string, p?: any) => {
        const ch = clone(state.charges[id]);
        if (!ch) throw notFound('charge', id);
        if ((p?.expand || []).includes('invoice') && typeof ch.invoice === 'string') ch.invoice = invoiceWith(ch.invoice);
        return ch;
      },
      list: async (p: any) => {
        const expand = (p?.expand || []).map((e: string) => e.replace(/^data\./, ''));
        const all = Object.values(state.charges).filter((c: any) => inCreated(c, p?.created)).map((c: any) => {
          const ch = clone(c);
          if (expand.includes('invoice') && typeof ch.invoice === 'string') ch.invoice = invoiceWith(ch.invoice);
          if (expand.includes('customer') && typeof ch.customer === 'string') ch.customer = clone(state.customers[ch.customer]) ?? ch.customer;
          return ch;
        });
        return page(all, p);
      },
    },
    checkout: {
      sessions: {
        retrieve: async (id: string) => {
          const s = clone(state.sessions[id]);
          if (!s) throw notFound('checkout session', id);
          return s;
        },
        list: async (p: any) => {
          const all = Object.values(state.sessions)
            .filter((s: any) => (!p?.payment_intent || s.payment_intent === p.payment_intent) && inCreated(s, p?.created))
            .map(clone);
          return page(all, p);
        },
      },
    },
    refunds: { list: async (p: any) => page(Object.values(state.refunds).filter((r: any) => inCreated(r, p?.created)).map(clone), p) },
    disputes: { list: async (p: any) => page(Object.values(state.disputes).filter((d: any) => inCreated(d, p?.created)).map(clone), p) },
  };
  return stripe;
}

/** Minimal Express-like response recorder. */
export function fakeRes() {
  const res: any = {
    statusCode: 200,
    body: undefined as any,
    status(c: number) { this.statusCode = c; return this; },
    send(b?: any) { this.body = b; return this; },
    json(b?: any) { this.body = b; return this; },
  };
  return res;
}
