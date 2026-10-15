/**
 * Seller monthly statements + monthly seller fee invoices. Built from
 * business_stats/{org}/months/{yyyymm} (or months_test for test orders),
 * incremented per order by ./stats.ts, so generating thousands of statements
 * never scans ticket_orders.
 *
 * The GreenGo ticket service fee is owed by the SELLER. In 'monthly' mode
 * (settings.sellerFeeInvoicing) each statement run also issues, per currency,
 * the seller's fee invoice for the month (fees minus fees refunded that month;
 * a credit note when negative). Statement + fee invoice(s) go out in ONE
 * e-mail to the seller.
 *
 * finance_statements/{organizerId}_{yyyymm}[_test]
 *   number ST-{yyyymm}-{ORG6}[-T], organizerId, month, isTest, jurisdiction,
 *   business { name, businessName, email }, lines StatementCurrencyLine[],
 *   listings StatementListingLine[] (each event / experience with money),
 *   feeInvoiceIds [], pdf { path, version, generatedAt }, emailedAt, issuedAt
 * Regenerating a month refreshes the totals and keeps the number; an
 * already issued fee invoice for that month is never re-issued (immutable).
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { EmailAttachment, escapeHtml, sendEmailOnce } from '../emails/sendEmail';
import {
  FCOL, StoredInvoice, createDocument, docToInvoice, financeDeps, getInvoicePdf, isTestUid, issuerSnapshot,
  loadSettings, partyFor, processDocument,
} from './invoices';
import {
  InvoicingSettings, StatementCurrencyLine, StatementListingLine, formatMoney, monthRange, monthlyFeeDraft,
  monthlyFeeInvoiceId, statementLines, statementListingLines,
} from './model';
import { renderStatementPdf } from './pdf';

const db = () => admin.firestore();
const ts = (d: Date) => admin.firestore.Timestamp.fromDate(d);

export const statementId = (organizerId: string, month: string, test = false) => `${organizerId}_${month}${test ? '_test' : ''}`;
export const statementNumber = (organizerId: string, month: string, test = false) =>
  `ST-${month}-${organizerId.replace(/[^A-Za-z0-9]/g, '').slice(0, 6).toUpperCase()}${test ? '-T' : ''}`;

export interface StoredStatement {
  id: string;
  number: string;
  organizerId: string;
  month: string;
  isTest: boolean;
  jurisdiction: 'BR' | 'US';
  business: { name: string; businessName: string | null; email: string | null };
  lines: StatementCurrencyLine[];
  /** every event / experience that earned money in the month */
  listings: StatementListingLine[];
  feeInvoiceIds: string[];
  pdf: { path: string | null; version: number; generatedAt: admin.firestore.Timestamp | null };
  emailedAt: admin.firestore.Timestamp | null;
  issuedAt: admin.firestore.Timestamp;
}

export function statementPdfPath(s: { id: string; isTest: boolean }): string {
  return `finance/statements/${s.isTest ? 'test/' : ''}${s.id}.pdf`;
}

async function renderStatement(s: StoredStatement, st: InvoicingSettings): Promise<Buffer> {
  return renderStatementPdf({
    number: s.number, month: s.month, isTest: s.isTest, issuedAt: s.issuedAt.toDate(),
    issuer: issuerSnapshot(st, s.jurisdiction),
    business: { uid: s.organizerId, name: s.business.name, businessName: s.business.businessName, email: s.business.email, taxId: null, address: null },
    lines: s.lines, listings: s.listings || [], jurisdiction: s.jurisdiction,
  });
}

/** Issues (idempotently) the month's seller fee invoice per currency. */
async function issueMonthlyFeeInvoices(
  s: StoredStatement,
  st: InvoicingSettings,
): Promise<StoredInvoice[]> {
  const seller = await partyFor(s.organizerId);
  const out: StoredInvoice[] = [];
  for (const line of s.lines) {
    const id = monthlyFeeInvoiceId(s.organizerId, s.month, line.currency, s.isTest);
    const existing = await db().collection(FCOL.invoices).doc(id).get();
    if (existing.exists) { out.push(docToInvoice(id, existing.data())); continue; }
    const draft = monthlyFeeDraft(st, s.organizerId, s.month, line, seller, s.isTest, s.listings);
    if (!draft) continue;
    const { invoice } = await createDocument(id, draft, st, 'system');
    // E-mailed together with the statement below, not on its own.
    out.push((await processDocument(invoice.id, { email: false })) || invoice);
  }
  return out;
}

/** Seller documents issued in [month] (per-order mode), max 200. */
async function documentsIssuedInMonth(organizerId: string, month: string, test: boolean): Promise<StoredInvoice[]> {
  const { start, end } = monthRange(month);
  const snap = await db().collection(FCOL.invoices)
    .where('customer.uid', '==', organizerId)
    .where('issuedAt', '>=', ts(start)).where('issuedAt', '<', ts(end))
    .orderBy('issuedAt', 'asc').limit(200).get();
  return snap.docs.map((d) => docToInvoice(d.id, d.data())).filter((i) => i.isTest === test);
}

/**
 * Builds (or rebuilds) one statement + PDF (+ monthly fee invoices). Null when
 * the month has no activity and [force] is false. [test] reads months_test.
 */
export async function generateStatement(
  organizerId: string,
  month: string,
  opts: { force?: boolean; email?: boolean; settings?: InvoicingSettings; test?: boolean } = {},
): Promise<StoredStatement | null> {
  monthRange(month); // validates
  const st = opts.settings || (await loadSettings());
  const sellerIsTest = await isTestUid(organizerId);
  const test = opts.test === true || sellerIsTest;
  const sub = opts.test === true ? 'months_test' : 'months';
  const m = (await db().collection(FCOL.businessStats).doc(organizerId).collection(sub).doc(month).get()).data();
  // A test seller's own orders are all test orders: they live in months_test.
  const mt = sellerIsTest && opts.test !== true
    ? (await db().collection(FCOL.businessStats).doc(organizerId).collection('months_test').doc(month).get()).data()
    : null;
  const lines = statementLines((mt || m)?.byCurrency);
  const listings = statementListingLines((mt || m)?.byListing);
  if (!lines.length && !opts.force) return null;

  const p = (await db().collection('profiles').doc(organizerId).get()).data() || {};
  const seller = await partyFor(organizerId);
  const id = statementId(organizerId, month, test);
  const ref = db().collection(FCOL.statements).doc(id);
  const prev = (await ref.get()).data();
  const now = financeDeps.now();
  const s: StoredStatement = {
    id,
    number: statementNumber(organizerId, month, test),
    organizerId,
    month,
    isTest: test,
    jurisdiction: st.jurisdiction,
    business: {
      name: String(p.displayName || p.nickname || seller.name || 'Business').slice(0, 150),
      businessName: typeof p.businessName === 'string' && p.businessName ? p.businessName.slice(0, 150) : null,
      email: seller.email,
    },
    lines,
    listings,
    feeInvoiceIds: prev?.feeInvoiceIds || [],
    pdf: prev?.pdf || { path: null, version: 0, generatedAt: null },
    emailedAt: prev?.emailedAt || null,
    issuedAt: ts(now),
  };

  let feeInvoices: StoredInvoice[] = [];
  if (st.sellerFeeInvoicing === 'monthly' && st.autoIssueFeeInvoices) {
    feeInvoices = await issueMonthlyFeeInvoices(s, st);
  } else {
    // 'per_order': every fee invoice / credit note issued to the seller this month.
    feeInvoices = await documentsIssuedInMonth(organizerId, month, test);
  }
  s.feeInvoiceIds = feeInvoices.map((i) => i.id);

  const buffer = await renderStatement(s, st);
  const path = statementPdfPath(s);
  await financeDeps.bucket().file(path).save(buffer, { contentType: 'application/pdf', resumable: false });
  s.pdf = { path, version: (s.pdf?.version || 0) + 1, generatedAt: ts(now) };
  await ref.set({ ...s, createdAt: prev?.createdAt || ts(now), updatedAt: ts(now) });

  const wantEmail = opts.email ?? st.emailStatementsToBusinesses;
  if (wantEmail && !s.emailedAt && s.business.email && lines.length) {
    const attachments: EmailAttachment[] = [{ filename: `${s.number}.pdf`, content: buffer, contentType: 'application/pdf' }];
    for (const inv of feeInvoices) {
      const r = await getInvoicePdf(inv.id);
      if (r) attachments.push({ filename: `${r.invoice.number}.pdf`, content: r.buffer, contentType: 'application/pdf' });
    }
    const br = s.jurisdiction === 'BR';
    const period = `${month.slice(4)}/${month.slice(0, 4)}`;
    const rows = lines.map((l) => {
      const f = (v: number) => escapeHtml(formatMoney(v, l.currency));
      return br
        ? `<li>${l.currency.toUpperCase()}: vendas ${f(l.sales)} · estornos ${f(l.refundedTotal)} · taxas GreenGo ${f(l.feesNet)} · <b>líquido ${f(l.net)}</b></li>`
        : `<li>${l.currency.toUpperCase()}: sales ${f(l.sales)} · refunds ${f(l.refundedTotal)} · GreenGo fees ${f(l.feesNet)} · <b>net ${f(l.net)}</b></li>`;
    }).join('');
    const invList = feeInvoices.map((i) => `${escapeHtml(i.number)} (${escapeHtml(formatMoney(i.total, i.currency))})`).join(', ');
    const res = await sendEmailOnce(`finance_statement_${id}`, async () => ({
      to: [s.business.email!],
      subject: `${s.isTest ? '[TEST] ' : ''}GreenGo — ${br ? 'Extrato mensal e fatura de taxas' : 'Monthly statement and fee invoice'} ${period}`,
      html: `<p>${br ? 'Olá' : 'Hello'} ${escapeHtml(s.business.businessName || s.business.name)},</p>
<p>${br ? `Segue o seu extrato de vendas de ingressos de ${period}:` : `Here is your ticket sales statement for ${period}:`}</p><ul>${rows}</ul>
${invList ? `<p>${br
    ? `A taxa de serviço da plataforma GreenGo é devida pelo organizador e retida da sua conta de pagamentos conectada. Fatura${feeInvoices.length > 1 ? 's' : ''} do mês em anexo: ${invList}.`
    : `The GreenGo platform service fee is owed by the organizer and collected from your connected payment account. This month's fee invoice${feeInvoices.length > 1 ? 's are' : ' is'} attached: ${invList}.`}</p>` : ''}
<p>GreenGo</p>`,
      text: `${br ? 'Extrato' : 'Statement'} ${period}. ${lines.map((l) => `${l.currency.toUpperCase()} net ${formatMoney(l.net, l.currency)}`).join(' · ')}`,
      attachments,
    }), { statementId: id });
    if (res !== 'duplicate' && res.sent) {
      const t = ts(financeDeps.now());
      s.emailedAt = t;
      await ref.set({ emailedAt: t }, { merge: true });
      for (const inv of feeInvoices) {
        await db().collection(FCOL.invoices).doc(inv.id).set({ emailedAt: t }, { merge: true });
      }
    }
  }
  return s;
}

export async function getStatementPdf(id: string): Promise<{ statement: StoredStatement; buffer: Buffer } | null> {
  const snap = await db().collection(FCOL.statements).doc(id).get();
  if (!snap.exists) return null;
  const s = { ...(snap.data() as StoredStatement), id };
  if (s.pdf?.path) {
    try {
      const [buf] = await financeDeps.bucket().file(s.pdf.path).download();
      return { statement: s, buffer: buf };
    } catch {
      // re-render below
    }
  }
  const buffer = await renderStatement(s, await loadSettings());
  return { statement: s, buffer };
}

/**
 * Every organizer with activity in [month]: collection-group query on
 * months.month / months_test.month (single-field collection-group indexes in
 * firestore.indexes.json), paged by document so it scales to any number of sellers.
 */
export async function generateStatementsForMonth(
  month: string,
  opts: { email?: boolean; pageSize?: number; maxPages?: number } = {},
): Promise<{ generated: number; skipped: number }> {
  const st = await loadSettings();
  let generated = 0;
  let skipped = 0;
  for (const group of ['months', 'months_test'] as const) {
    let cursor: FirebaseFirestore.QueryDocumentSnapshot | null = null;
    for (let page = 0; page < (opts.maxPages ?? 1000); page++) {
      let q = db().collectionGroup(group).where('month', '==', month).limit(opts.pageSize ?? 200);
      if (cursor) q = q.startAfter(cursor);
      const snap = await q.get();
      if (snap.empty) break;
      for (const d of snap.docs) {
        const orgId = d.ref.parent.parent?.id;
        if (!orgId) { skipped++; continue; }
        try {
          const s = await generateStatement(orgId, month, { settings: st, email: opts.email, test: group === 'months_test' });
          if (s) generated++; else skipped++;
        } catch (e) {
          skipped++;
          console.error('[finance] statement', orgId, month, group, (e as Error)?.message);
        }
      }
      cursor = snap.docs[snap.docs.length - 1];
      if (snap.size < (opts.pageSize ?? 200)) break;
    }
  }
  return { generated, skipped };
}
