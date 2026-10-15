/**
 * adminFinance — ONE callable for the admin panel's Sales, Businesses,
 * Invoices and Statements pages (one deploy target instead of ~25; the bundle
 * already exports 270+ functions). `data.action` selects the operation.
 *
 * Roles (shared/adminAuth.ts):
 *   read actions   superAdmin | analyst
 *   write actions  superAdmin (fresh admin 2FA once requireAdmin2fa is on),
 *                  each one audited in admin_audit_log.
 *
 * ticket_orders / bookings / finance_* are not readable by admin clients in
 * the rules (server-only / party-only), so every read goes through here.
 * Every list is cursor-paginated (cursor = last document id) and capped.
 */
import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { AdminRole, requireAdmin } from '../shared/adminAuth';
import {
  FCOL, createDocument, creditDocument, docToInvoice, emailInvoice, getInvoicePdf, isTestUid, loadSettings,
  partyFor, processDocument, refreshNfse, renderAndStorePdf, submitNfse,
} from './invoices';
import {
  FinanceInvoiceDraft, InvoiceLine, Jurisdiction, SettingsError, isValidCnpj, isValidCpf, monthRange,
  normalizeSettings, nfseReadiness, orderTransition, taxFor,
} from './model';
import { applyOrderFinance } from './stats';
import { generateStatement, generateStatementsForMonth, getStatementPdf } from './statements';

const db = () => admin.firestore();
const FINANCE_READ: readonly AdminRole[] = ['superAdmin', 'analyst'];
const FINANCE_WRITE: readonly AdminRole[] = ['superAdmin'];
const MAX_PAGE = 100;

// ─────────────────────────────────────────────────────────────── helpers

/** Firestore values -> JSON (Timestamps as ISO strings). */
export function plain(v: any): any {
  if (v === null || v === undefined) return v ?? null;
  if (v instanceof admin.firestore.Timestamp) return v.toDate().toISOString();
  if (typeof v?.toDate === 'function' && typeof v?.seconds === 'number') return v.toDate().toISOString();
  if (v instanceof Date) return v.toISOString();
  if (Array.isArray(v)) return v.map(plain);
  if (typeof v === 'object') {
    if (v instanceof admin.firestore.DocumentReference) return v.path;
    const out: Record<string, any> = {};
    for (const [k, x] of Object.entries(v)) out[k] = plain(x);
    return out;
  }
  return v;
}

const str = (v: unknown, field: string, max: number, optional = true): string | undefined => {
  if (v === undefined || v === null || v === '') {
    if (optional) return undefined;
    throw new HttpsError('invalid-argument', `${field} is required`);
  }
  if (typeof v !== 'string') throw new HttpsError('invalid-argument', `${field} must be a string`);
  const t = v.trim();
  if (t.length > max) throw new HttpsError('invalid-argument', `${field} too long`);
  if (!optional && !t) throw new HttpsError('invalid-argument', `${field} is required`);
  return t || undefined;
};
const docId = (v: unknown, field: string, optional = true): string | undefined => {
  const t = str(v, field, 200, optional);
  if (t && t.includes('/')) throw new HttpsError('invalid-argument', `${field} is invalid`);
  return t;
};
const pageSizeOf = (v: unknown) => Math.min(MAX_PAGE, Math.max(1, Math.round(Number(v) || 25)));
const isoDay = (v: unknown, field: string): string | undefined => {
  const t = str(v, field, 10);
  if (t && !/^\d{4}-\d{2}-\d{2}$/.test(t)) throw new HttpsError('invalid-argument', `${field} must be YYYY-MM-DD`);
  return t;
};
const month = (v: unknown, field = 'month'): string => {
  const t = str(v, field, 6, false)!;
  try { monthRange(t); } catch { throw new HttpsError('invalid-argument', `${field} must be YYYYMM`); }
  return t;
};

async function page(
  q: FirebaseFirestore.Query,
  col: string,
  cursor: string | undefined,
  size: number,
): Promise<{ docs: FirebaseFirestore.QueryDocumentSnapshot[]; nextCursor: string | null }> {
  let qq = q.limit(size + 1);
  if (cursor) {
    const c = await db().collection(col).doc(cursor).get();
    if (c.exists) qq = qq.startAfter(c);
  }
  const snap = await qq.get();
  const docs = snap.docs.slice(0, size);
  return { docs, nextCursor: snap.docs.length > size ? docs[docs.length - 1].id : null };
}

async function audit(uid: string, action: string, details: Record<string, unknown>): Promise<void> {
  try {
    await db().collection('admin_audit_log').add({
      adminId: uid, action: `finance.${action}`, details: plain(details),
      timestamp: admin.firestore.FieldValue.serverTimestamp(), source: 'adminFinance',
    });
  } catch (e) {
    console.warn('[finance] audit failed', (e as Error)?.message);
  }
}

/** uid -> { name, isBusiness, isTest } for list rows (max 100 uids, one getAll). */
async function namesOf(uids: string[]): Promise<Record<string, { name: string; isTest: boolean }>> {
  const ids = [...new Set(uids.filter((u) => u && !u.startsWith('guest_')))].slice(0, 100);
  if (!ids.length) return {};
  const snaps = await db().getAll(...ids.map((u) => db().collection('profiles').doc(u)));
  const out: Record<string, { name: string; isTest: boolean }> = {};
  for (const s of snaps) {
    const d = s.data() || {};
    out[s.id] = {
      name: String(d.businessName || d.displayName || d.nickname || s.id),
      isTest: d.isTestUser === true || String(d.membershipTier || '').toUpperCase() === 'TEST',
    };
  }
  return out;
}

const ORDER_FIELDS = [
  'kind', 'listingId', 'bookingId', 'buyerId', 'organizerId', 'provider', 'mode', 'quantity', 'unitAmount',
  'ticketSubtotal', 'feeTotal', 'feeRuleApplied', 'totalAmount', 'currency', 'status', 'title', 'startsAt',
  'platform', 'createdAt', 'updatedAt', 'paidAt', 'isGuest', 'guestName', 'refund', 'code',
];
const pick = (d: any, fields: string[]) => Object.fromEntries(fields.filter((f) => d?.[f] !== undefined).map((f) => [f, d[f]]));

// ─────────────────────────────────────────────────────────────── reads

async function overview(data: any) {
  const today = new Date().toISOString().slice(0, 10);
  const to = isoDay(data.to, 'to') || today;
  const from = isoDay(data.from, 'from') || new Date(Date.now() - 29 * 86400_000).toISOString().slice(0, 10);
  if ((Date.parse(to) - Date.parse(from)) / 86400_000 > 400) throw new HttpsError('invalid-argument', 'max 400 days');
  const id = admin.firestore.FieldPath.documentId();
  const snap = await db().collection(FCOL.daily).where(id, '>=', from).where(id, '<=', to).get();
  const days = snap.docs.map((d) => ({ date: d.id, ...plain(d.data()) }));
  const totals: Record<string, Record<string, number>> = {};
  for (const d of days) {
    for (const [cur, t] of Object.entries<any>(d.byCurrency || {})) {
      totals[cur] = totals[cur] || {};
      for (const [k, v] of Object.entries<any>(t)) totals[cur][k] = (totals[cur][k] || 0) + (Number(v) || 0);
    }
  }
  const count = async (q: FirebaseFirestore.Query) => (await q.count().get()).data().count;
  const inv = db().collection(FCOL.invoices);
  const [businesses, nfseErrors, nfseReview, nfseProcessing, invoices] = await Promise.all([
    count(db().collection('profiles').where('isBusiness', '==', true)),
    count(inv.where('nfse.status', '==', 'error')),
    count(inv.where('nfse.status', '==', 'needs_review')),
    count(inv.where('nfse.status', '==', 'processing')),
    count(inv.where('isTest', '==', false)),
  ]);
  return { from, to, days, totals, counts: { businesses, invoices, nfseErrors, nfseReview, nfseProcessing } };
}

async function listSales(data: any) {
  let q: FirebaseFirestore.Query = db().collection('ticket_orders');
  const kind = str(data.kind, 'kind', 20);
  const status = str(data.status, 'status', 30);
  const organizerId = docId(data.organizerId, 'organizerId');
  const buyerId = docId(data.buyerId, 'buyerId');
  if (kind) q = q.where('kind', '==', kind);
  if (status) q = q.where('status', '==', status);
  if (organizerId) q = q.where('organizerId', '==', organizerId);
  if (buyerId) q = q.where('buyerId', '==', buyerId);
  const from = isoDay(data.from, 'from');
  const to = isoDay(data.to, 'to');
  if (from) q = q.where('createdAt', '>=', admin.firestore.Timestamp.fromDate(new Date(`${from}T00:00:00Z`)));
  if (to) q = q.where('createdAt', '<', admin.firestore.Timestamp.fromDate(new Date(Date.parse(`${to}T00:00:00Z`) + 86400_000)));
  q = q.orderBy('createdAt', 'desc');
  const { docs, nextCursor } = await page(q, 'ticket_orders', docId(data.cursor, 'cursor'), pageSizeOf(data.pageSize));
  const names = await namesOf(docs.flatMap((d) => [d.data().buyerId, d.data().organizerId]));
  return {
    items: docs.map((d) => {
      const o = d.data();
      return {
        id: d.id, ...plain(pick(o, ORDER_FIELDS)),
        buyerName: o.guestName || names[o.buyerId]?.name || null,
        organizerName: names[o.organizerId]?.name || null,
        isTest: !!(names[o.buyerId]?.isTest || names[o.organizerId]?.isTest),
      };
    }),
    nextCursor,
  };
}

async function getOrder(data: any) {
  const orderId = docId(data.orderId, 'orderId', false)!;
  const o = (await db().collection('ticket_orders').doc(orderId).get()).data();
  if (!o) throw new HttpsError('not-found', 'order not found');
  const [booking, invoices, mark, tickets] = await Promise.all([
    o.bookingId ? db().collection('bookings').doc(String(o.bookingId)).get() : Promise.resolve(null),
    db().collection(FCOL.invoices).where('source.orderId', '==', orderId).limit(10).get(),
    db().collection(FCOL.marks).doc(orderId).get(),
    db().collection('tickets').where('orderId', '==', orderId).limit(50).get().catch(() => null),
  ]);
  const names = await namesOf([o.buyerId, o.organizerId]);
  return {
    order: { id: orderId, ...plain(pick(o, ORDER_FIELDS)), feeLines: plain(o.feeLines || null) },
    buyerName: o.guestName || names[o.buyerId]?.name || null,
    organizerName: names[o.organizerId]?.name || null,
    booking: booking?.exists ? { id: booking.id, ...plain(pick(booking.data(), [
      'experienceTitle', 'slotStart', 'slotEnd', 'guests', 'status', 'price', 'cancellation', 'checkIn', 'dispute', 'refundDue',
    ])) } : null,
    // Never return the signed QR token.
    tickets: (tickets?.docs || []).map((t) => ({ id: t.id, ...plain(pick(t.data(), ['status', 'checkedInAt', 'typeName', 'seat', 'createdAt'])) })),
    invoices: invoices.docs.map((d) => invoiceRow(d.id, d.data())),
    finance: plain(mark.data() || null),
  };
}

async function listBookings(data: any) {
  let q: FirebaseFirestore.Query = db().collection('bookings');
  const status = str(data.status, 'status', 30);
  const hostId = docId(data.hostId, 'hostId');
  if (status) q = q.where('status', '==', status);
  if (hostId) q = q.where('hostId', '==', hostId);
  q = q.orderBy('createdAt', 'desc');
  const { docs, nextCursor } = await page(q, 'bookings', docId(data.cursor, 'cursor'), pageSizeOf(data.pageSize));
  const names = await namesOf(docs.flatMap((d) => [d.data().guestId, d.data().hostId]));
  return {
    items: docs.map((d) => {
      const b = d.data();
      return {
        id: d.id,
        ...plain(pick(b, ['experienceId', 'experienceTitle', 'slotStart', 'hostId', 'guestId', 'guests', 'status', 'price', 'createdAt', 'guestName', 'isGuest'])),
        paymentMode: b.payment?.mode || null, paymentStatus: b.payment?.status || null,
        guestDisplay: b.guestName || names[b.guestId]?.name || null, hostName: names[b.hostId]?.name || null,
      };
    }),
    nextCursor,
  };
}

async function listBusinesses(data: any) {
  const q = db().collection('profiles').where('isBusiness', '==', true).orderBy(admin.firestore.FieldPath.documentId());
  const { docs, nextCursor } = await page(q, 'profiles', docId(data.cursor, 'cursor'), pageSizeOf(data.pageSize));
  const stats = docs.length ? await db().getAll(...docs.map((d) => db().collection(FCOL.businessStats).doc(d.id))) : [];
  const byId = new Map(stats.map((s) => [s.id, s.data()]));
  return {
    items: docs.map((d) => {
      const p = d.data();
      const s = byId.get(d.id) || {};
      return {
        id: d.id,
        businessName: p.businessName || null, displayName: p.displayName || null, nickname: p.nickname || null,
        photoUrl: p.photoUrls?.[0] || null, membershipTier: p.membershipTier || null,
        membershipEndDate: plain(p.membershipEndDate || null), city: p.location?.city || null, country: p.location?.country || null,
        followersCount: p.followersCount || 0, isTest: p.isTestUser === true || p.membershipTier === 'TEST',
        totals: plain(s.totals || {}), orderCounts: plain(s.orderCounts || {}), lastSaleAt: plain(s.lastSaleAt || null),
        createdAt: plain(p.createdAt || null),
      };
    }),
    nextCursor,
  };
}

async function businessDetail(data: any) {
  const uid = docId(data.organizerId, 'organizerId', false)!;
  const p = (await db().collection('profiles').doc(uid).get()).data();
  if (!p) throw new HttpsError('not-found', 'profile not found');
  const count = async (q: FirebaseFirestore.Query) => (await q.count().get()).data().count;
  const [stats, months, events, experiences, recentOrders, statements, billing] = await Promise.all([
    db().collection(FCOL.businessStats).doc(uid).get(),
    db().collection(FCOL.businessStats).doc(uid).collection('months')
      .orderBy('month', 'desc').limit(24).get(),
    count(db().collection('events').where('organizerId', '==', uid)),
    count(db().collection('user_experiences').where('hostId', '==', uid)),
    db().collection('ticket_orders').where('organizerId', '==', uid).orderBy('createdAt', 'desc').limit(10).get(),
    db().collection(FCOL.statements).where('organizerId', '==', uid).orderBy('issuedAt', 'desc').limit(24).get(),
    db().collection(FCOL.billing).doc(uid).get(),
  ]);
  return {
    profile: {
      id: uid, ...plain(pick(p, [
        'businessName', 'displayName', 'nickname', 'membershipTier', 'membershipEndDate', 'isBusiness', 'followersCount',
        'businessCategory', 'businessWebsite', 'businessVerified', 'verificationStatus', 'createdAt', 'isTestUser',
      ])),
      photoUrl: p.photoUrls?.[0] || null, city: p.location?.city || null, country: p.location?.country || null,
    },
    stats: plain(stats.data() || null),
    months: months.docs.map((m) => ({ month: m.id, ...plain(m.data()) })),
    counts: { events, experiences },
    recentOrders: recentOrders.docs.map((d) => ({ id: d.id, ...plain(pick(d.data(), ORDER_FIELDS)) })),
    statements: statements.docs.map((d) => statementRow(d.id, d.data())),
    billing: plain(billing.data() || null),
  };
}

function invoiceRow(id: string, d: any) {
  return plain({
    id, type: d.type, number: d.number, series: d.series, status: d.status, jurisdiction: d.jurisdiction,
    isTest: d.isTest, currency: d.currency, total: d.total, tax: d.tax, customer: d.customer, source: d.source,
    nfse: d.nfse, pdf: d.pdf, emailedAt: d.emailedAt, issuedAt: d.issuedAt, relatedInvoiceId: d.relatedInvoiceId,
    creditNoteId: d.creditNoteId || null, lines: d.lines, notes: d.notes, issuer: d.issuer, voidReason: d.voidReason || null,
  });
}

function statementRow(id: string, d: any) {
  return plain({
    id, number: d.number, organizerId: d.organizerId, month: d.month, isTest: d.isTest, jurisdiction: d.jurisdiction,
    business: d.business, lines: d.lines, pdf: d.pdf, emailedAt: d.emailedAt, issuedAt: d.issuedAt,
  });
}

async function listInvoices(data: any) {
  let q: FirebaseFirestore.Query = db().collection(FCOL.invoices);
  const type = str(data.type, 'type', 20);
  const status = str(data.status, 'status', 10);
  const jurisdiction = str(data.jurisdiction, 'jurisdiction', 2);
  const nfseStatus = str(data.nfseStatus, 'nfseStatus', 20);
  const customerUid = docId(data.customerUid, 'customerUid');
  const organizerId = docId(data.organizerId, 'organizerId');
  if (type) q = q.where('type', '==', type);
  if (status) q = q.where('status', '==', status);
  if (jurisdiction) q = q.where('jurisdiction', '==', jurisdiction);
  if (nfseStatus) q = q.where('nfse.status', '==', nfseStatus);
  if (customerUid) q = q.where('customer.uid', '==', customerUid);
  if (organizerId) q = q.where('source.organizerId', '==', organizerId);
  if (data.isTest === true || data.isTest === false) q = q.where('isTest', '==', data.isTest);
  const number = str(data.number, 'number', 40);
  if (number) {
    const s = await db().collection(FCOL.invoices).where('number', '==', number.toUpperCase()).limit(5).get();
    return { items: s.docs.map((d) => invoiceRow(d.id, d.data())), nextCursor: null };
  }
  q = q.orderBy('issuedAt', 'desc');
  const { docs, nextCursor } = await page(q, FCOL.invoices, docId(data.cursor, 'cursor'), pageSizeOf(data.pageSize));
  return { items: docs.map((d) => invoiceRow(d.id, d.data())), nextCursor };
}

async function listStatements(data: any) {
  let q: FirebaseFirestore.Query = db().collection(FCOL.statements);
  if (data.month) q = q.where('month', '==', month(data.month));
  const organizerId = docId(data.organizerId, 'organizerId');
  if (organizerId) q = q.where('organizerId', '==', organizerId);
  q = q.orderBy('issuedAt', 'desc');
  const { docs, nextCursor } = await page(q, FCOL.statements, docId(data.cursor, 'cursor'), pageSizeOf(data.pageSize));
  return { items: docs.map((d) => statementRow(d.id, d.data())), nextCursor };
}

async function getSettingsAction() {
  const st = await loadSettings();
  const tok = (await db().collection('server_secrets').doc('invoicing').get()).data() || {};
  return {
    settings: st,
    readiness: nfseReadiness(st),
    tokens: {
      producao: typeof tok.focusnfeTokenProducao === 'string' && tok.focusnfeTokenProducao.length > 0,
      homologacao: typeof tok.focusnfeTokenHomologacao === 'string' && tok.focusnfeTokenHomologacao.length > 0,
    },
  };
}

const csvCell = (v: unknown) => {
  const s = v === null || v === undefined ? '' : String(v);
  const safe = /^[=+\-@\t\r]/.test(s) ? `'${s}` : s; // no spreadsheet formula injection
  return /[",\n;]/.test(safe) ? `"${safe.replace(/"/g, '""')}"` : safe;
};

async function exportInvoicesCsv(data: any) {
  const m = month(data.month);
  const { start, end } = monthRange(m);
  const rows: string[] = [[
    'number', 'type', 'status', 'issuedAt', 'jurisdiction', 'test', 'currency', 'total', 'tax', 'customerName',
    'customerEmail', 'customerTaxId', 'orderId', 'organizerId', 'nfseStatus', 'nfseNumber', 'nfseVerification', 'related',
  ].join(',')];
  let cursor: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  for (let i = 0; i < 100; i++) {
    let q = db().collection(FCOL.invoices)
      .where('issuedAt', '>=', admin.firestore.Timestamp.fromDate(start))
      .where('issuedAt', '<', admin.firestore.Timestamp.fromDate(end))
      .orderBy('issuedAt', 'asc').limit(500);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.get();
    for (const d of snap.docs) {
      const x = d.data();
      if (data.includeTest !== true && x.isTest) continue;
      const exp = ['jpy', 'krw', 'clp', 'vnd'].includes(x.currency) ? 0 : 2;
      rows.push([
        x.number, x.type, x.status, x.issuedAt?.toDate?.().toISOString(), x.jurisdiction, x.isTest ? 'yes' : 'no',
        String(x.currency || '').toUpperCase(), (x.total / 10 ** exp).toFixed(exp), x.tax ? (x.tax.amount / 10 ** exp).toFixed(exp) : '',
        x.customer?.name, x.customer?.email, x.customer?.taxId, x.source?.orderId, x.source?.organizerId,
        x.nfse?.status, x.nfse?.number, x.nfse?.verificationCode, x.relatedInvoiceId,
      ].map(csvCell).join(','));
    }
    if (snap.size < 500) break;
    cursor = snap.docs[snap.docs.length - 1];
  }
  return { filename: `greengo-invoices-${m}.csv`, csv: rows.join('\n'), count: rows.length - 1 };
}

// ─────────────────────────────────────────────────────────────── writes

function linesOf(raw: unknown, currency: string): InvoiceLine[] {
  if (!Array.isArray(raw) || !raw.length || raw.length > 50) throw new HttpsError('invalid-argument', 'lines: 1..50 required');
  void currency;
  return raw.map((l: any, i) => {
    const description = str(l?.description, `lines[${i}].description`, 500, false)!;
    const quantity = Math.round(Number(l?.quantity ?? 1));
    const unitAmount = Math.round(Number(l?.unitAmount));
    if (!(quantity >= 1 && quantity <= 10000)) throw new HttpsError('invalid-argument', `lines[${i}].quantity invalid`);
    if (!(unitAmount > 0 && unitAmount <= 100_000_000)) throw new HttpsError('invalid-argument', `lines[${i}].unitAmount must be > 0 (minor units)`);
    return { description, quantity, unitAmount, amount: quantity * unitAmount };
  });
}

function taxIdOf(v: unknown): string | null {
  const t = str(v, 'taxId', 30);
  if (!t) return null;
  const d = t.replace(/\D/g, '');
  if (d.length === 11 && !isValidCpf(d)) throw new HttpsError('invalid-argument', 'invalid CPF');
  if (d.length === 14 && !isValidCnpj(d)) throw new HttpsError('invalid-argument', 'invalid CNPJ');
  return t;
}

async function issueManual(data: any, by: string, forceTest: boolean) {
  const st = await loadSettings();
  const currency = (str(data.currency, 'currency', 3) || (st.jurisdiction === 'BR' ? 'brl' : 'usd')).toLowerCase();
  if (!/^[a-z]{3}$/.test(currency)) throw new HttpsError('invalid-argument', 'currency must be ISO 4217');
  const jurisdiction: Jurisdiction = data.jurisdiction === 'US' || data.jurisdiction === 'BR' ? data.jurisdiction : st.jurisdiction;
  const customerUid = docId(data.customerUid ?? data.userId, 'customerUid');
  let customer = customerUid ? await partyFor(customerUid) : {
    uid: null, name: str(data.customer?.name, 'customer.name', 150, false)!, email: null, taxId: null, address: null,
  };
  customer = {
    ...customer,
    name: str(data.customer?.name, 'customer.name', 150) || customer.name,
    email: str(data.customer?.email, 'customer.email', 254) || customer.email,
    taxId: taxIdOf(data.customer?.taxId) || customer.taxId,
    address: str(data.customer?.address, 'customer.address', 300) || customer.address,
  };
  let isTest = data.isTest === true || forceTest;
  if (forceTest) {
    if (!customerUid) throw new HttpsError('invalid-argument', 'userId of a TEST user is required');
    if (!(await isTestUid(customerUid))) throw new HttpsError('failed-precondition', 'user is not a test user (toggle it in Users first)');
  } else if (customerUid && (await isTestUid(customerUid))) {
    isTest = true; // a test user never receives a production number
  }
  const lines = forceTest && !data.lines
    ? [{ description: str(data.description, 'description', 500) || (jurisdiction === 'BR' ? 'Taxa de serviço GreenGo (teste)' : 'GreenGo service fee (test)'),
      quantity: 1, unitAmount: Math.round(Number(data.amount) || 990), amount: Math.round(Number(data.amount) || 990) }]
    : linesOf(data.lines, currency);
  if (lines.some((l) => !(l.unitAmount > 0))) throw new HttpsError('invalid-argument', 'amount must be > 0');
  const total = lines.reduce((a, l) => a + l.amount, 0);
  const draft: FinanceInvoiceDraft = {
    type: 'invoice', jurisdiction, isTest,
    source: { kind: forceTest ? 'test' : 'manual' },
    customer, lines, currency, total,
    tax: taxFor({ ...st, jurisdiction }, jurisdiction, total),
    relatedInvoiceId: null,
    notes: str(data.notes, 'notes', 1000) || '',
  };
  const id = `${forceTest ? 'test' : 'man'}_${db().collection(FCOL.invoices).doc().id}`;
  const { invoice } = await createDocument(id, draft, { ...st, jurisdiction }, by);
  const done = await processDocument(invoice.id, { email: data.email === true });
  return { invoice: invoiceRow(invoice.id, (await db().collection(FCOL.invoices).doc(invoice.id).get()).data() || done) };
}

async function loadInvoice(id: string) {
  const snap = await db().collection(FCOL.invoices).doc(id).get();
  if (!snap.exists) throw new HttpsError('not-found', 'invoice not found');
  return docToInvoice(id, snap.data());
}

async function retryNfse(data: any) {
  const id = docId(data.id, 'id', false)!;
  const inv = await loadInvoice(id);
  if (inv.jurisdiction !== 'BR' || inv.type !== 'invoice') throw new HttpsError('failed-precondition', 'not a Brazilian invoice');
  if (!['error', 'needs_review', 'pending'].includes(inv.nfse.status)) {
    throw new HttpsError('failed-precondition', `NFS-e is ${inv.nfse.status}`);
  }
  const patch: Record<string, unknown> = {};
  const taxId = taxIdOf(data.taxId);
  if (taxId) patch['customer'] = { ...inv.customer, taxId };
  let valueBrl = inv.nfse.valueBrl;
  if (data.valueBrl !== undefined) {
    valueBrl = Math.round(Number(data.valueBrl));
    if (!(valueBrl > 0)) throw new HttpsError('invalid-argument', 'valueBrl must be > 0 (centavos)');
  }
  if (valueBrl === null || valueBrl === undefined) throw new HttpsError('failed-precondition', 'valueBrl (centavos) required: order not in BRL');
  const nfse = { ...inv.nfse, status: 'pending' as const, valueBrl, error: null, ref: inv.nfse.ref || id };
  patch['nfse'] = nfse;
  await db().collection(FCOL.invoices).doc(id).set({ ...patch, updatedAt: admin.firestore.Timestamp.now() }, { merge: true });
  const next = await submitNfse({ ...inv, ...(patch as any), nfse }, await loadSettings());
  await renderAndStorePdf({ ...inv, ...(patch as any), nfse: next });
  return { nfse: plain(next) };
}

async function backfillOrders(data: any, by: string) {
  const issueDocuments = data.issueDocuments === true;
  let q: FirebaseFirestore.Query = db().collection('ticket_orders')
    .where('status', 'in', ['paid', 'refunded', 'disputed']).orderBy(admin.firestore.FieldPath.documentId()).limit(100);
  const cursor = docId(data.cursor, 'cursor');
  if (cursor) q = q.startAfter(cursor);
  const snap = await q.get();
  let counted = 0;
  for (const d of snap.docs) {
    const o = d.data();
    const paid = await applyOrderFinance(d.id, { ...o, status: 'paid' }, 'paid', { issueDocuments, actor: by });
    if (paid.counted) counted++;
    if (o.status !== 'paid') await applyOrderFinance(d.id, o, 'reversed', { issueDocuments, actor: by });
  }
  return { processed: snap.size, counted, nextCursor: snap.size === 100 ? snap.docs[snap.size - 1].id : null };
}

// ─────────────────────────────────────────────────────────────── router

type Handler = (data: any, uid: string) => Promise<any>;

const READS: Record<string, Handler> = {
  overview: (d) => overview(d),
  listSales: (d) => listSales(d),
  getOrder: (d) => getOrder(d),
  listBookings: (d) => listBookings(d),
  listBusinesses: (d) => listBusinesses(d),
  businessDetail: (d) => businessDetail(d),
  listInvoices: (d) => listInvoices(d),
  getInvoice: async (d) => invoiceRow(docId(d.id, 'id', false)!, (await loadInvoice(docId(d.id, 'id', false)!))),
  getInvoicePdf: async (d) => {
    const r = await getInvoicePdf(docId(d.id, 'id', false)!);
    if (!r) throw new HttpsError('not-found', 'invoice not found');
    return { filename: `${r.invoice.number}.pdf`, base64: r.buffer.toString('base64') };
  },
  listStatements: (d) => listStatements(d),
  getStatementPdf: async (d) => {
    const r = await getStatementPdf(docId(d.id, 'id', false)!);
    if (!r) throw new HttpsError('not-found', 'statement not found');
    return { filename: `${r.statement.number}.pdf`, base64: r.buffer.toString('base64') };
  },
  getSettings: () => getSettingsAction(),
  exportInvoicesCsv: (d) => exportInvoicesCsv(d),
};

const WRITES: Record<string, Handler> = {
  saveSettings: async (d) => {
    try {
      const st = normalizeSettings(d.settings || {});
      await db().collection(FCOL.config).doc('invoicing').set({ ...st, updatedAt: admin.firestore.Timestamp.now() });
      return { settings: st, readiness: nfseReadiness(st) };
    } catch (e) {
      if (e instanceof SettingsError) throw new HttpsError('invalid-argument', e.message, { field: e.field });
      throw e;
    }
  },
  saveNfseTokens: async (d) => {
    const patch: Record<string, unknown> = { updatedAt: admin.firestore.Timestamp.now() };
    const p = str(d.producao, 'producao', 200);
    const h = str(d.homologacao, 'homologacao', 200);
    if (p !== undefined) patch.focusnfeTokenProducao = p;
    if (h !== undefined) patch.focusnfeTokenHomologacao = h;
    if (d.clearProducao === true) patch.focusnfeTokenProducao = admin.firestore.FieldValue.delete();
    if (d.clearHomologacao === true) patch.focusnfeTokenHomologacao = admin.firestore.FieldValue.delete();
    await db().collection('server_secrets').doc('invoicing').set(patch, { merge: true });
    return (await getSettingsAction()).tokens;
  },
  issueManualInvoice: (d, uid) => issueManual(d, uid, false),
  createTestInvoice: (d, uid) => issueManual(d, uid, true),
  voidInvoice: async (d, uid) => {
    const id = docId(d.id, 'id', false)!;
    const reason = str(d.reason, 'reason', 255, false)!;
    if (reason.length < 15) throw new HttpsError('invalid-argument', 'reason: at least 15 characters (NFS-e cancellation rule)');
    const cn = await creditDocument(id, `cnm_${id}`, reason, uid);
    if (!cn) throw new HttpsError('not-found', 'invoice not found');
    return { creditNote: invoiceRow(cn.id, (await db().collection(FCOL.invoices).doc(cn.id).get()).data()) };
  },
  retryNfse: (d) => retryNfse(d),
  refreshNfse: async (d) => ({ nfse: plain(await refreshNfse(docId(d.id, 'id', false)!)) }),
  regeneratePdf: async (d) => {
    const { path } = await renderAndStorePdf(await loadInvoice(docId(d.id, 'id', false)!));
    return { path };
  },
  emailInvoice: async (d) => {
    const r = await getInvoicePdf(docId(d.id, 'id', false)!);
    if (!r) throw new HttpsError('not-found', 'invoice not found');
    const to = str(d.to, 'to', 254);
    const inv = to ? { ...r.invoice, customer: { ...r.invoice.customer, email: to } } : r.invoice;
    return { result: await emailInvoice(inv, r.buffer, true) };
  },
  generateStatement: async (d) => {
    const s = await generateStatement(docId(d.organizerId, 'organizerId', false)!, month(d.month), { force: true, email: d.email === true });
    return { statement: s ? statementRow(s.id, s) : null };
  },
  generateStatements: async (d) => generateStatementsForMonth(month(d.month), { email: d.email === true }),
  backfillOrders: (d, uid) => backfillOrders(d, uid),
  saveBillingProfile: async (d, uid) => {
    const organizerId = docId(d.organizerId, 'organizerId', false)!;
    const profile = {
      legalName: str(d.legalName, 'legalName', 150) || null,
      taxId: taxIdOf(d.taxId),
      address: str(d.address, 'address', 300) || null,
      email: str(d.email, 'email', 254) || null,
      updatedAt: admin.firestore.Timestamp.now(),
      updatedBy: uid,
    };
    if (profile.email && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(profile.email)) throw new HttpsError('invalid-argument', 'email is invalid');
    await db().collection(FCOL.billing).doc(organizerId).set(profile);
    return { billing: plain(profile) };
  },
  reprocessOrder: async (d, uid) => {
    const orderId = docId(d.orderId, 'orderId', false)!;
    const o = (await db().collection('ticket_orders').doc(orderId).get()).data();
    if (!o) throw new HttpsError('not-found', 'order not found');
    const t = orderTransition({ status: 'pending' }, o.status === 'paid' ? o : { status: 'paid' });
    const r = await applyOrderFinance(orderId, { ...o, status: 'paid' }, t || 'paid', { actor: uid });
    if (o.status === 'refunded' || o.status === 'disputed') await applyOrderFinance(orderId, o, 'reversed', { actor: uid });
    return r;
  },
};

/** Firestore FAILED_PRECONDITION (missing / building index) -> a readable error instead of INTERNAL. */
function readable(e: unknown): never {
  if (e instanceof HttpsError) throw e;
  const err = e as { code?: number | string; message?: string };
  if ((err?.code === 9 || err?.code === 'failed-precondition') && /index/i.test(err?.message || '')) {
    console.error('[finance] index', err.message);
    throw new HttpsError('failed-precondition', 'This filter needs a database index that is still being built. Try again in a few minutes.');
  }
  throw e;
}

export const adminFinance = onCall({ memory: '512MiB', timeoutSeconds: 300 }, async (request) => {
  try {
    return await adminFinanceHandler(request);
  } catch (e) {
    return readable(e);
  }
});

async function adminFinanceHandler(request: { data: any; auth?: any }) {
  const data = request.data || {};
  const action = String(data.action || '');
  if (READS[action]) {
    const who = await requireAdmin(request.auth, FINANCE_READ, { require2fa: false });
    return READS[action](data, who.uid);
  }
  if (WRITES[action]) {
    const who = await requireAdmin(request.auth, FINANCE_WRITE);
    const res = await WRITES[action](data, who.uid);
    const { settings, producao, homologacao, ...safe } = data;
    void settings; void producao; void homologacao;
    await audit(who.uid, action, safe);
    return res;
  }
  throw new HttpsError('invalid-argument', `unknown action: ${action}`);
}
