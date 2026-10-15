/**
 * Finance end-to-end on the emulators (Firestore + Auth + Storage):
 * numbering, idempotent stats, buyer fee invoice + PDF + NFS-e (mock),
 * credit note on refund, TEST series for test users, BR <-> US switch,
 * business monthly statement, adminFinance role checks + pagination.
 *
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "npx jest --config jest.security.config.js finance"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
const fft = functionsTest({ projectId: PROJECT });

import { adminFinance } from '../../src/finance/admin';
import { FCOL, createDocument, loadSettings } from '../../src/finance/invoices';
import { DEFAULT_SETTINGS, feeInvoiceFromOrder, monthKey } from '../../src/finance/model';
import { applyOrderFinance } from '../../src/finance/stats';
import { generateStatement } from '../../src/finance/statements';
import { getMyFinanceDocumentPdf, listMyFinanceDocuments } from '../../src/finance/seller';
import { getMyBillingProfile, saveMyBillingProfile } from '../../src/finance/billing';

const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const YEAR = new Date().getUTCFullYear();

async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) throw new Error('Refusing: not a local emulator');
  await new Promise<void>((resolve, reject) => {
    const req = http.request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE',
      path: `/emulator/v1/projects/${PROJECT}/databases/(default)/documents` }, (res) => { res.resume(); res.on('end', resolve); });
    req.on('error', reject);
    req.end();
  });
}

const call = (data: any, uid: string) => (fft.wrap(adminFinance) as any)({ data, auth: { uid, token: {} } });

const order = (over: Record<string, unknown> = {}) => ({
  kind: 'event', listingId: 'ev1', buyerId: 'buyer1', organizerId: 'org1', quantity: 2, unitAmount: 5000,
  ticketSubtotal: 10000, feeTotal: 2000, feePerTicket: 1000, totalAmount: 12000, currency: 'brl',
  status: 'paid', title: 'Samba night', provider: 'stripe', mode: 'instant',
  createdAt: TS.now(), paidAt: TS.now(), ...over,
});

beforeAll(async () => {
  await clearAll();
  await db.doc('admin_users/boss').set({ role: 'superAdmin' });
  await db.doc('admin_users/ana').set({ role: 'analyst' });
  await db.doc('admin_users/mod').set({ role: 'moderator' });
  await db.doc('profiles/buyer1').set({ displayName: 'Ana Souza', createdAt: TS.now() });
  await db.doc('profiles/org1').set({ displayName: 'José', businessName: 'Bar do Zé', isBusiness: true, createdAt: TS.now() });
  await db.doc('profiles/tester').set({ displayName: 'QA Tester', isTestUser: true, membershipTier: 'TEST', createdAt: TS.now() });
  // Per-order invoicing for the first suites; the statement suite switches to monthly.
  await db.doc('finance_config/invoicing').set({ ...DEFAULT_SETTINGS, sellerFeeInvoicing: 'per_order' });
});

afterAll(() => fft.cleanup());

describe('numbering', () => {
  it('sequential per series and idempotent per document id', async () => {
    const st = await loadSettings();
    const party = { uid: null, name: 'X', email: null, taxId: null, address: null };
    const draft = feeInvoiceFromOrder(st, 'n1', order(), party, false)!;
    const a = await createDocument('num_a', draft, st, 't');
    const again = await createDocument('num_a', draft, st, 't');
    const b = await createDocument('num_b', draft, st, 't');
    expect(again.created).toBe(false);
    expect(again.invoice.number).toBe(a.invoice.number);
    expect(b.invoice.seq).toBe(a.invoice.seq + 1);
    const [x, y] = await Promise.all([
      createDocument('num_c', draft, st, 't'), createDocument('num_d', draft, st, 't'),
    ]);
    expect(new Set([x.invoice.number, y.invoice.number]).size).toBe(2);
  });
});

describe('paid order -> stats + fee invoice', () => {
  it('counts once, issues GG invoice with PDF and mock NFS-e', async () => {
    await db.doc('ticket_orders/o1').set(order());
    const r1 = await applyOrderFinance('o1', order(), 'paid');
    const r2 = await applyOrderFinance('o1', order(), 'paid');
    expect(r1.counted).toBe(true);
    expect(r2.counted).toBe(false);

    const biz = (await db.doc('business_stats/org1').get()).data()!;
    expect(biz.totals.brl).toMatchObject({ gross: 10000, fees: 2000, buyerTotal: 12000, orders: 1, tickets: 2 });
    const month = (await db.doc(`business_stats/org1/months/${monthKey(new Date())}`).get()).data()!;
    expect(month.byCurrency.brl.orders).toBe(1);
    const day = (await db.doc(`admin_stats_daily/${new Date().toISOString().slice(0, 10)}`).get()).data()!;
    expect(day.byKind.event.orders).toBe(1);

    const inv = (await db.doc('finance_invoices/fee_o1').get()).data()!;
    expect(inv.number).toMatch(new RegExp(`^GG-${YEAR}-\\d{6}$`));
    expect(inv.isTest).toBe(false);
    expect(inv.jurisdiction).toBe('BR');
    expect(inv.total).toBe(2000);
    // The fee is owed by the SELLER: the seller is the invoice customer.
    expect(inv.customer.uid).toBe('org1');
    expect(inv.customer.name).toBe('Bar do Zé');
    expect(inv.emailedAt).toBeNull();
    expect(inv.nfse.status).toBe('authorized');
    expect(inv.nfse.environment).toBe('homologacao');
    expect(inv.pdf.path).toBe('finance/invoices/fee_o1.pdf');
    const [buf] = await admin.storage().bucket().file(inv.pdf.path).download();
    expect(buf.subarray(0, 5).toString()).toBe('%PDF-');
  });

  it('refund -> refunds counted once, credit note, original void + NFS-e cancelled', async () => {
    const refunded = order({ status: 'refunded' });
    const r1 = await applyOrderFinance('o1', refunded, 'reversed');
    const r2 = await applyOrderFinance('o1', refunded, 'reversed');
    expect(r1.counted).toBe(true);
    expect(r2.counted).toBe(false);
    expect(r1.creditId).toBe('cn_o1');
    const biz = (await db.doc('business_stats/org1').get()).data()!;
    expect(biz.totals.brl).toMatchObject({ refunds: 10000, refundedFees: 2000, refundedOrders: 1 });
    const orig = (await db.doc('finance_invoices/fee_o1').get()).data()!;
    expect(orig.status).toBe('void');
    expect(orig.nfse.status).toBe('cancelled');
    const cn = (await db.doc('finance_invoices/cn_o1').get()).data()!;
    expect(cn.type).toBe('credit_note');
    expect(cn.number).toMatch(new RegExp(`^GGCN-${YEAR}-`));
    expect(cn.total).toBe(-2000);
    expect(cn.nfse.status).toBe('not_required');
  });

  it('test users: TEST series, never counted in stats', async () => {
    const o = order({ buyerId: 'tester' });
    await db.doc('ticket_orders/o2').set(o);
    const r = await applyOrderFinance('o2', o, 'paid');
    expect(r.isTest).toBe(true);
    const inv = (await db.doc('finance_invoices/fee_o2').get()).data()!;
    expect(inv.number).toMatch(new RegExp(`^TEST-${YEAR}-`));
    expect(inv.pdf.path).toBe('finance/invoices/test/fee_o2.pdf');
    const biz = (await db.doc('business_stats/org1').get()).data()!;
    expect(biz.totals.brl.orders).toBe(1);
  });
});

describe('adminFinance callable', () => {
  it('role checks: moderator refused, analyst reads, only superAdmin writes', async () => {
    await expect(call({ action: 'listInvoices' }, 'mod')).rejects.toThrow(/Requires role/);
    await expect(call({ action: 'listInvoices' }, 'nobody')).rejects.toThrow(/admin/);
    const r = await call({ action: 'listInvoices' }, 'ana');
    expect(r.items.length).toBeGreaterThan(0);
    await expect(call({ action: 'saveSettings', settings: {} }, 'ana')).rejects.toThrow(/Requires role/);
    await expect(call({ action: 'bogus' }, 'boss')).rejects.toThrow(/unknown action/);
  });

  it('cursor pagination on invoices', async () => {
    const p1 = await call({ action: 'listInvoices', pageSize: 2 }, 'ana');
    expect(p1.items).toHaveLength(2);
    expect(p1.nextCursor).toBeTruthy();
    const p2 = await call({ action: 'listInvoices', pageSize: 2, cursor: p1.nextCursor }, 'ana');
    expect(p2.items.map((i: any) => i.id)).not.toContain(p1.items[0].id);
    const only = await call({ action: 'listInvoices', isTest: true }, 'ana');
    expect(only.items.every((i: any) => i.isTest)).toBe(true);
  });

  it('switch to US: next invoice US, no NFS-e; settings validated', async () => {
    await expect(call({ action: 'saveSettings', settings: { jurisdiction: 'XX' } }, 'boss')).rejects.toThrow(/BR or US/);
    await call({ action: 'saveSettings', settings: { ...DEFAULT_SETTINGS, sellerFeeInvoicing: 'per_order', jurisdiction: 'US', us: { ...DEFAULT_SETTINGS.us, salesTaxRate: 8.25 } } }, 'boss');
    const o = order({ currency: 'usd' });
    await db.doc('ticket_orders/o3').set(o);
    await applyOrderFinance('o3', o, 'paid');
    const inv = (await db.doc('finance_invoices/fee_o3').get()).data()!;
    expect(inv.jurisdiction).toBe('US');
    expect(inv.nfse.status).toBe('not_required');
    expect(inv.tax).toMatchObject({ label: 'Sales tax', rate: 8.25 });
    const pdf = await call({ action: 'getInvoicePdf', id: 'fee_o3' }, 'ana');
    expect(Buffer.from(pdf.base64, 'base64').subarray(0, 5).toString()).toBe('%PDF-');
    // Older documents keep their jurisdiction.
    expect((await db.doc('finance_invoices/fee_o1').get()).data()!.jurisdiction).toBe('BR');
    await call({ action: 'saveSettings', settings: { ...DEFAULT_SETTINGS, sellerFeeInvoicing: 'per_order' } }, 'boss');
  });

  it('test invoices only for test users', async () => {
    await expect(call({ action: 'createTestInvoice', userId: 'buyer1', amount: 500 }, 'boss')).rejects.toThrow(/not a test user/);
    const r = await call({ action: 'createTestInvoice', userId: 'tester', amount: 500, currency: 'brl' }, 'boss');
    expect(r.invoice.number).toMatch(/^TEST-/);
    expect(r.invoice.nfse.status).toBe('authorized');
    expect(r.invoice.nfse.environment).toBe('homologacao');
    const logs = await db.collection('admin_audit_log').where('action', '==', 'finance.createTestInvoice').get();
    expect(logs.size).toBe(1);
  });

  it('manual invoice for a test user is forced into the TEST series', async () => {
    const r = await call({ action: 'issueManualInvoice', customerUid: 'tester', currency: 'brl',
      lines: [{ description: 'Promoção', quantity: 1, unitAmount: 1500 }] }, 'boss');
    expect(r.invoice.isTest).toBe(true);
  });

  it('void needs a 15+ char reason and creates a credit note', async () => {
    await expect(call({ action: 'voidInvoice', id: 'fee_o3', reason: 'short' }, 'boss')).rejects.toThrow(/15/);
    const r = await call({ action: 'voidInvoice', id: 'fee_o3', reason: 'Customer charged twice by mistake' }, 'boss');
    expect(r.creditNote.type).toBe('credit_note');
    expect((await db.doc('finance_invoices/fee_o3').get()).data()!.status).toBe('void');
  });

  it('sales list, order detail, businesses, overview, CSV export', async () => {
    const sales = await call({ action: 'listSales', organizerId: 'org1' }, 'ana');
    expect(sales.items.length).toBeGreaterThanOrEqual(3);
    expect(sales.items[0].organizerName).toBe('Bar do Zé');
    const detail = await call({ action: 'getOrder', orderId: 'o1' }, 'ana');
    expect(detail.invoices.map((i: any) => i.id)).toEqual(expect.arrayContaining(['fee_o1']));
    const biz = await call({ action: 'listBusinesses' }, 'ana');
    expect(biz.items.find((b: any) => b.id === 'org1').totals.brl.orders).toBe(1);
    const ov = await call({ action: 'overview' }, 'ana');
    expect(ov.totals.brl.fees).toBe(2000);
    expect(ov.counts.businesses).toBe(1);
    const csv = await call({ action: 'exportInvoicesCsv', month: monthKey(new Date()) }, 'ana');
    expect(csv.csv.split('\n')[0]).toMatch(/^number,type/);
    expect(csv.count).toBeGreaterThan(0);
    expect(csv.csv).not.toMatch(/TEST-/);
  });
});

describe('seller monthly statement + monthly fee invoice', () => {
  it('per-order mode: the statement collects the month\'s invoices of the seller', async () => {
    const s = await generateStatement('org1', monthKey(new Date()), { email: false });
    expect(s!.feeInvoiceIds).toEqual(expect.arrayContaining(['fee_o1', 'cn_o1']));
  });

  it('monthly mode: one fee invoice per currency listing every event that earned money', async () => {
    await db.doc('finance_config/invoicing').set({ ...DEFAULT_SETTINGS, sellerFeeInvoicing: 'monthly' });
    const m = monthKey(new Date());
    const s = await generateStatement('org1', m, { email: false });
    const brl = s!.lines.find((l) => l.currency === 'brl')!;
    expect(brl).toMatchObject({ sales: 12000, refundedTotal: 12000, feesNet: 0, net: 0 });
    const usd = s!.lines.find((l) => l.currency === 'usd')!;
    expect(usd).toMatchObject({ sales: 12000, feesNet: 2000, net: 10000 });
    expect(s!.listings.map((l) => l.title)).toEqual(expect.arrayContaining(['Samba night']));
    // BRL fees fully refunded -> no BRL invoice; USD -> one invoice to the seller.
    expect(s!.feeInvoiceIds).toEqual([`mfee_org1_${m}_usd`]);
    const inv = (await db.doc(`finance_invoices/mfee_org1_${m}_usd`).get()).data()!;
    expect(inv.customer.uid).toBe('org1');
    expect(inv.total).toBe(2000);
    expect(inv.lines[0].description).toContain('Samba night');
    expect(inv.source).toMatchObject({ kind: 'monthly_fee', month: m });
    // Re-running the batch never re-issues (immutable numbers).
    const again = await generateStatement('org1', m, { email: false });
    expect(again!.feeInvoiceIds).toEqual(s!.feeInvoiceIds);
    expect((await db.doc(`finance_invoices/mfee_org1_${m}_usd`).get()).data()!.number).toBe(inv.number);
  });

  it('test seller: TEST statement + TEST fee invoice from months_test', async () => {
    const o = order({ organizerId: 'tester', buyerId: 'buyer1', listingId: 'evT', title: 'QA party' });
    await db.doc('ticket_orders/o9').set(o);
    await applyOrderFinance('o9', o, 'paid');
    const m = monthKey(new Date());
    const s = await generateStatement('tester', m, { email: false });
    expect(s!.isTest).toBe(true);
    expect(s!.number).toMatch(/-T$/);
    const inv = (await db.doc(`finance_invoices/testfee_tester_${m}_brl`).get()).data()!;
    expect(inv.number).toMatch(/^TEST-/);
    expect(inv.lines[0].description).toContain('QA party');
  });

  it('seller callables: only own documents, test docs only for test accounts', async () => {
    const asUser = (fn: any, data: any, uid: string) => (fft.wrap(fn) as any)({ data, auth: { uid, token: {} } });
    const mine = await asUser(listMyFinanceDocuments, { kind: 'invoices' }, 'org1');
    expect(mine.items.length).toBeGreaterThan(0);
    expect(mine.items.every((i: any) => !i.isTest)).toBe(true);
    const st = await asUser(listMyFinanceDocuments, { kind: 'statements' }, 'org1');
    expect(st.items.length).toBeGreaterThan(0);
    const pdf = await asUser(getMyFinanceDocumentPdf, { kind: 'invoice', id: mine.items[0].id }, 'org1');
    expect(Buffer.from(pdf.base64, 'base64').subarray(0, 5).toString()).toBe('%PDF-');
    await expect(asUser(getMyFinanceDocumentPdf, { kind: 'invoice', id: mine.items[0].id }, 'buyer1')).rejects.toThrow(/not found/);
    await expect(asUser(listMyFinanceDocuments, {}, '')).rejects.toThrow();
    const t = await asUser(listMyFinanceDocuments, { kind: 'invoices' }, 'tester');
    expect(t.items.every((i: any) => i.isTest)).toBe(true);
  });

  it('seller billing details (admin-entered) become the invoice customer', async () => {
    await expect(call({ action: 'saveBillingProfile', organizerId: 'org1', taxId: '123' }, 'ana')).rejects.toThrow(/Requires role/);
    await expect(call({ action: 'saveBillingProfile', organizerId: 'org1', taxId: '40.486.663/0001-83' }, 'boss')).rejects.toThrow(/CNPJ/);
    await call({ action: 'saveBillingProfile', organizerId: 'org1', legalName: 'Zé Bar Ltda', taxId: '40.486.663/0001-82', email: 'fiscal@ze.example' }, 'boss');
    const o = order({ currency: 'eur', listingId: 'evB', title: 'Billing test' });
    await db.doc('ticket_orders/o10').set(o);
    await applyOrderFinance('o10', o, 'paid');
    const m = monthKey(new Date());
    await generateStatement('org1', m, { email: false });
    const inv = (await db.doc(`finance_invoices/mfee_org1_${m}_eur`).get()).data()!;
    expect(inv.customer).toMatchObject({ uid: 'org1', name: 'Zé Bar Ltda', taxId: '40.486.663/0001-82', email: 'fiscal@ze.example' });
    const detail = await call({ action: 'businessDetail', organizerId: 'org1' }, 'ana');
    expect(detail.billing.legalName).toBe('Zé Bar Ltda');
  });

  it('seller invoice details: save / masked read / keep tax id / field errors / used on invoices', async () => {
    const asUser = (fn: any, data: any, uid: string) => (fft.wrap(fn) as any)({ data, auth: { uid, token: {} } });
    const form = {
      type: 'company', country: 'BR', legalName: 'Samba Eventos Ltda', tradeName: 'Samba Night', contactPerson: 'Ana',
      taxId: '40.486.663/0001-82', inscricaoMunicipal: '1234567',
      address: { street: 'Rua Augusta', number: '500', district: 'Consolação', city: 'São Paulo', region: 'SP', postalCode: '01305-000' },
      email: 'fiscal@samba.example',
    };
    const empty = await asUser(getMyBillingProfile, {}, 'org2');
    expect(empty).toMatchObject({ profile: null, complete: false });
    await expect(asUser(saveMyBillingProfile, { ...form, taxId: '40.486.663/0001-83' }, 'org2'))
      .rejects.toMatchObject({ code: 'invalid-argument', details: { field: 'taxId', code: 'invalid' } });
    const saved = await asUser(saveMyBillingProfile, form, 'org2');
    expect(saved.complete).toBe(true);
    expect(saved.profile.taxIdMasked).toBe('••••••••0182');
    expect(JSON.stringify(saved)).not.toContain('40486663000182');
    // Edit without re-typing the tax id keeps it.
    const edited = await asUser(saveMyBillingProfile, { ...form, taxId: '', email: 'new@samba.example' }, 'org2');
    expect(edited.profile).toMatchObject({ email: 'new@samba.example', hasTaxId: true });
    expect((await db.doc('finance_billing_profiles/org2').get()).data()!.taxId).toBe('40486663000182');
    await expect(asUser(getMyBillingProfile, {}, '')).rejects.toThrow();
    // The invoice customer comes from the details.
    await db.doc('profiles/org2').set({ displayName: 'Samba', isBusiness: true, createdAt: TS.now() });
    const o = order({ organizerId: 'org2', listingId: 'evS', title: 'Samba night', currency: 'brl' });
    await db.doc('ticket_orders/o11').set(o);
    await applyOrderFinance('o11', o, 'paid');
    const m = monthKey(new Date());
    const s = await generateStatement('org2', m, { email: false });
    expect(s!.billingMissing).toEqual([]);
    const inv = (await db.doc(`finance_invoices/mfee_org2_${m}_brl`).get()).data()!;
    expect(inv.customer).toMatchObject({
      name: 'Samba Eventos Ltda (Samba Night)', taxId: 'CNPJ 40.486.663/0001-82', email: 'new@samba.example',
    });
    expect(inv.customer.address).toContain('Rua Augusta, 500');
  });

  it('legacy: builds from the month totals with a PDF', async () => {
    const s = await generateStatement('org1', monthKey(new Date()), { email: false });
    expect(s!.lines[0]).toMatchObject({ currency: 'brl', gross: 10000, refunds: 10000, net: 0 });
    expect(s!.business.businessName).toBe('Bar do Zé');
    const stored = (await db.collection(FCOL.statements).doc(s!.id).get()).data()!;
    expect(stored.pdf.path).toBe(`finance/statements/${s!.id}.pdf`);
    const r = await call({ action: 'getStatementPdf', id: s!.id }, 'ana');
    expect(r.filename).toMatch(/^ST-/);
    expect(await generateStatement('nobody', monthKey(new Date()))).toBeNull();
  });
});
