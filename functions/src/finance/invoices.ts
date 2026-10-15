/**
 * Finance invoices — Firestore / Storage / NFS-e side of ./model.ts.
 *
 * Life of a document:
 *   createDocument()  one transaction: idempotent on the document id, takes the
 *                     next number of its series (finance_counters), writes the
 *                     immutable invoice (status 'issued').
 *   processDocument() after the transaction, safe to re-run:
 *                     1. NFS-e submit (BR invoices with nfse.status 'pending')
 *                     2. PDF render -> Storage (ALWAYS, every jurisdiction)
 *                     3. seller e-mail with the PDF (once, email_dispatch claim);
 *                        monthly fee invoices are e-mailed with the statement instead
 *   refreshNfse()     poll the provider; re-renders the PDF on a state change.
 *   creditDocument()  credit note reversing an invoice; the original becomes
 *                     'void' and its authorized NFS-e is cancelled.
 *
 * Numbers are never reused: an issued document is only ever voided by a
 * credit note, never edited or deleted.
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { authEmailOf, escapeHtml, sendEmailOnce } from '../emails/sendEmail';
import { isGuestKey } from '../shared/guestIdentity';
import {
  FinanceInvoiceDraft, InvoicingSettings, Jurisdiction, NfseState, Party,
  counterId, creditNoteFor, formatMoney, formatNumber, initialNfse, seriesFor, settingsFromDoc,
} from './model';
import { NfseConfigError, NfseProvider, NfseTokens, nfseRef, providerFor, tomadorProblem } from './nfse';
import { IssuerSnapshot, renderInvoicePdf } from './pdf';

export const FCOL = {
  config: 'finance_config',
  counters: 'finance_counters',
  invoices: 'finance_invoices',
  statements: 'finance_statements',
  marks: 'finance_order_marks',
  businessStats: 'business_stats',
  daily: 'admin_stats_daily',
  billing: 'finance_billing_profiles',
} as const;

const db = () => admin.firestore();
const ts = (d: Date) => admin.firestore.Timestamp.fromDate(d);

/** Overridable in tests. */
export const financeDeps = {
  now: (): Date => new Date(),
  bucket: () => admin.storage().bucket(),
};

// ─────────────────────────────────────────────────────────────── config

export async function loadSettings(): Promise<InvoicingSettings> {
  const snap = await db().collection(FCOL.config).doc('invoicing').get();
  return settingsFromDoc(snap.data());
}

export async function loadTokens(): Promise<NfseTokens> {
  const d = (await db().collection('server_secrets').doc('invoicing').get()).data() || {};
  return {
    focusnfeTokenProducao: typeof d.focusnfeTokenProducao === 'string' ? d.focusnfeTokenProducao : undefined,
    focusnfeTokenHomologacao: typeof d.focusnfeTokenHomologacao === 'string' ? d.focusnfeTokenHomologacao : undefined,
  };
}

export function issuerSnapshot(st: InvoicingSettings, jur: Jurisdiction): IssuerSnapshot {
  if (jur === 'BR') {
    const b = st.br;
    return {
      legalName: b.legalName, tradeName: b.tradeName, taxIdLabel: 'CNPJ', taxId: b.cnpj,
      extraIds: b.inscricaoMunicipal ? [`Inscrição municipal: ${b.inscricaoMunicipal}`] : [],
      addressLines: [b.address, [b.city, b.uf].filter(Boolean).join(' - '), b.cep ? `CEP ${b.cep}` : ''].filter(Boolean),
      email: b.email, phone: b.phone,
    };
  }
  const u = st.us;
  return {
    legalName: u.legalName, tradeName: 'GreenGo', taxIdLabel: 'EIN', taxId: u.ein,
    addressLines: [u.address, [u.city, u.state, u.zip].filter(Boolean).join(', ')].filter(Boolean),
    email: u.email, phone: u.phone, footerNote: u.footerNote,
  };
}

// ─────────────────────────────────────────────────────────────── parties

/** Test user = profiles.isTestUser or tier TEST (same rule as adminToggleTestUser). */
export async function isTestUid(uid: string | null | undefined): Promise<boolean> {
  if (!uid || isGuestKey(uid)) return false;
  const d = (await db().collection('profiles').doc(uid).get()).data();
  return !!d && (d.isTestUser === true || String(d.membershipTier || '').toUpperCase() === 'TEST');
}

export async function partyFor(uid: string | null, fallbackName?: string | null): Promise<Party> {
  if (!uid) return { uid: null, name: fallbackName || 'Customer', email: null, taxId: null, address: null };
  const email = await authEmailOf(uid);
  if (isGuestKey(uid)) {
    return { uid, name: fallbackName || 'Guest', email, taxId: null, address: null, isGuest: true };
  }
  const [ps, bs] = await Promise.all([
    db().collection('profiles').doc(uid).get(),
    db().collection(FCOL.billing).doc(uid).get(),
  ]);
  const p = ps.data() || {};
  // Billing details an admin entered for this seller (legal name, CPF/CNPJ,
  // address, invoice e-mail) win over the public profile.
  const bp = bs.data() || {};
  const s = (v: unknown) => (typeof v === 'string' && v.trim() ? v.trim() : null);
  const name = String(s(bp.legalName) || s(p.businessName) || s(p.displayName) || fallbackName || s(p.nickname) || 'Customer').slice(0, 150);
  const loc = p.location || {};
  const address = s(bp.address) || [loc.city, loc.country].filter((x: unknown) => typeof x === 'string' && x).join(', ') || null;
  return { uid, name, email: s(bp.email) || email, taxId: s(bp.taxId) || s(p.taxId), address };
}

// ─────────────────────────────────────────────────────────────── create

export interface StoredInvoice extends FinanceInvoiceDraft {
  id: string;
  series: string;
  year: number;
  seq: number;
  number: string;
  status: 'issued' | 'void';
  issuer: IssuerSnapshot;
  nfse: NfseState;
  pdf: { path: string | null; version: number; generatedAt: admin.firestore.Timestamp | null };
  emailedAt: admin.firestore.Timestamp | null;
  issuedAt: admin.firestore.Timestamp;
  createdBy: string;
  voidedBy?: string | null;
  creditNoteId?: string | null;
}

export function docToInvoice(id: string, d: any): StoredInvoice {
  return { ...(d as StoredInvoice), id };
}

/** Idempotent: an existing document with [id] is returned unchanged. */
export async function createDocument(
  id: string,
  draft: FinanceInvoiceDraft,
  st: InvoicingSettings,
  createdBy: string,
): Promise<{ invoice: StoredInvoice; created: boolean }> {
  const now = financeDeps.now();
  const year = now.getUTCFullYear();
  const series = seriesFor(st, draft.type, draft.isTest);
  const ref = db().collection(FCOL.invoices).doc(id);
  const cref = db().collection(FCOL.counters).doc(counterId(series, year));
  return db().runTransaction(async (tx) => {
    const existing = await tx.get(ref);
    if (existing.exists) return { invoice: docToInvoice(id, existing.data()), created: false };
    const seq = Number((await tx.get(cref)).data()?.seq || 0) + 1;
    const number = formatNumber(series, year, seq, st.numbering.padding);
    const nfse = initialNfse(st, draft);
    const inv: StoredInvoice = {
      ...draft,
      id, series, year, seq, number,
      status: 'issued',
      issuer: issuerSnapshot(st, draft.jurisdiction),
      nfse: nfse.status === 'pending' ? { ...nfse, ref: nfseRef(id) } : nfse,
      pdf: { path: null, version: 0, generatedAt: null },
      emailedAt: null,
      issuedAt: ts(now),
      createdBy,
      creditNoteId: null,
    };
    tx.set(cref, { series, year, seq, updatedAt: ts(now) }, { merge: true });
    tx.set(ref, { ...inv, createdAt: ts(now), updatedAt: ts(now) });
    return { invoice: inv, created: true };
  });
}

// ─────────────────────────────────────────────────────────────── NFS-e

async function providerForInvoice(inv: StoredInvoice, tokens: NfseTokens): Promise<NfseProvider> {
  const n = inv.nfse;
  try {
    return providerFor(n.provider || 'mock', n.environment || 'homologacao', tokens);
  } catch (e) {
    // A TEST invoice never fails for lack of a sandbox token: it falls back to the mock.
    if (e instanceof NfseConfigError && inv.isTest) return providerFor('mock', 'homologacao', tokens);
    throw e;
  }
}

/** Submits a 'pending' NFS-e. Returns the new state (also written). */
export async function submitNfse(inv: StoredInvoice, st: InvoicingSettings, tokens?: NfseTokens): Promise<NfseState> {
  const n = inv.nfse;
  if (n.status !== 'pending' && n.status !== 'error') return n;
  if (n.valueBrl === null || n.valueBrl === undefined) return n;
  const problem = tomadorProblem(inv.customer, st.nfse);
  let next: NfseState;
  if (problem) {
    next = { ...n, status: 'needs_review', error: problem };
  } else {
    try {
      const provider = await providerForInvoice(inv, tokens || (await loadTokens()));
      const res = await provider.submit({
        ref: n.ref || nfseRef(inv.id),
        issuedAt: inv.issuedAt.toDate(),
        issuer: st.br,
        settings: st.nfse,
        customer: inv.customer,
        description: inv.lines.map((l) => l.description).join(' | '),
        valueBrl: n.valueBrl,
      });
      next = applyResult({ ...n, ref: n.ref || nfseRef(inv.id), attempts: (n.attempts || 0) + 1 }, res);
    } catch (e) {
      next = { ...n, status: 'error', error: (e as Error)?.message || String(e), attempts: (n.attempts || 0) + 1 };
    }
  }
  await db().collection(FCOL.invoices).doc(inv.id).set({ nfse: next, updatedAt: ts(financeDeps.now()) }, { merge: true });
  return next;
}

function applyResult(n: NfseState, res: Awaited<ReturnType<NfseProvider['status']>>): NfseState {
  switch (res.state) {
    case 'processing': return { ...n, status: 'processing', error: null };
    case 'authorized': return {
      ...n, status: 'authorized', error: null, number: res.number, verificationCode: res.verificationCode,
      url: res.url, xmlUrl: res.xmlUrl,
    };
    case 'cancelled': return { ...n, status: 'cancelled', error: null };
    case 'error': return { ...n, status: 'error', error: res.error };
  }
}

/** Polls a processing / cancel_pending NFS-e. Re-renders the PDF on change. */
export async function refreshNfse(id: string): Promise<NfseState | null> {
  const snap = await db().collection(FCOL.invoices).doc(id).get();
  if (!snap.exists) return null;
  const inv = docToInvoice(id, snap.data());
  const n = inv.nfse;
  if (!n.ref || !['processing', 'cancel_pending', 'error'].includes(n.status)) return n;
  const provider = await providerForInvoice(inv, await loadTokens());
  const res = await provider.status(n.ref);
  let next = applyResult(n, res);
  // The provider still reports 'autorizado' while a cancellation is pending.
  if (n.status === 'cancel_pending' && next.status === 'authorized') next = { ...next, status: 'cancel_pending' };
  if (n.status === 'error' && res.state === 'error' && /not_found/.test(res.error)) next = { ...n, status: 'pending' };
  if (JSON.stringify(next) !== JSON.stringify(n)) {
    await snap.ref.set({ nfse: next, updatedAt: ts(financeDeps.now()) }, { merge: true });
    await renderAndStorePdf({ ...inv, nfse: next });
  }
  return next;
}

async function cancelNfseOf(inv: StoredInvoice, reason: string): Promise<NfseState> {
  const n = inv.nfse;
  if (!n.ref || (n.status !== 'authorized' && n.status !== 'processing')) {
    // Never authorized: nothing to cancel at the provider.
    return n.status === 'not_required' ? n : { ...n, status: 'cancelled' };
  }
  try {
    const provider = await providerForInvoice(inv, await loadTokens());
    const res = await provider.cancel(n.ref, reason);
    if (res.state === 'cancelled') return { ...n, status: 'cancelled', error: null };
    return { ...n, status: 'cancel_pending', error: res.state === 'error' ? res.error : null };
  } catch (e) {
    return { ...n, status: 'cancel_pending', error: (e as Error)?.message || String(e) };
  }
}

// ─────────────────────────────────────────────────────────────── PDF

export function pdfPath(inv: { id: string; isTest: boolean }): string {
  return `finance/invoices/${inv.isTest ? 'test/' : ''}${inv.id}.pdf`;
}

export async function invoicePdfBuffer(inv: StoredInvoice, relatedNumber: string | null = null): Promise<Buffer> {
  return renderInvoicePdf({
    type: inv.type, number: inv.number, jurisdiction: inv.jurisdiction, isTest: inv.isTest, status: inv.status,
    issuedAt: inv.issuedAt.toDate(), issuer: inv.issuer, customer: inv.customer, lines: inv.lines,
    currency: inv.currency, total: inv.total, tax: inv.tax, relatedNumber, notes: inv.notes, nfse: inv.nfse,
    reference: inv.source?.orderId ? `#${inv.source.orderId}` : null,
  });
}

export async function renderAndStorePdf(inv: StoredInvoice): Promise<{ path: string; buffer: Buffer }> {
  let related: string | null = null;
  if (inv.relatedInvoiceId) {
    related = (await db().collection(FCOL.invoices).doc(inv.relatedInvoiceId).get()).data()?.number || null;
  }
  const buffer = await invoicePdfBuffer(inv, related);
  const path = pdfPath(inv);
  await financeDeps.bucket().file(path).save(buffer, {
    contentType: 'application/pdf', resumable: false,
    metadata: { cacheControl: 'private, max-age=0', metadata: { invoiceId: inv.id, number: inv.number } },
  });
  await db().collection(FCOL.invoices).doc(inv.id).set({
    pdf: { path, version: (inv.pdf?.version || 0) + 1, generatedAt: ts(financeDeps.now()) },
    updatedAt: ts(financeDeps.now()),
  }, { merge: true });
  return { path, buffer };
}

/** Stored PDF bytes, rendering it first when missing. */
export async function getInvoicePdf(id: string): Promise<{ invoice: StoredInvoice; buffer: Buffer } | null> {
  const snap = await db().collection(FCOL.invoices).doc(id).get();
  if (!snap.exists) return null;
  const inv = docToInvoice(id, snap.data());
  if (inv.pdf?.path) {
    try {
      const [buf] = await financeDeps.bucket().file(inv.pdf.path).download();
      return { invoice: inv, buffer: buf };
    } catch {
      // fall through: re-render
    }
  }
  const { buffer } = await renderAndStorePdf(inv);
  return { invoice: inv, buffer };
}

// ─────────────────────────────────────────────────────────────── e-mail

export async function emailInvoice(inv: StoredInvoice, buffer: Buffer, force = false): Promise<string> {
  const to = inv.customer.email;
  if (!to) return 'no_recipient';
  const key = force ? `finance_invoice_${inv.id}_${Date.now()}` : `finance_invoice_${inv.id}`;
  const br = inv.jurisdiction === 'BR';
  const title = inv.type === 'credit_note' ? (br ? 'Nota de crédito' : 'Credit note') : (br ? 'Fatura' : 'Invoice');
  const amount = formatMoney(inv.total, inv.currency);
  const res = await sendEmailOnce(key, async () => ({
    to: [to],
    subject: `${inv.isTest ? '[TEST] ' : ''}GreenGo — ${title} ${inv.number}`,
    html: `<p>${br ? 'Olá' : 'Hello'} ${escapeHtml(inv.customer.name)},</p>
<p>${br ? 'Segue em anexo o documento' : 'Attached is your'} <b>${escapeHtml(title)} ${escapeHtml(inv.number)}</b> (${escapeHtml(amount)}).</p>
<p>${br
    ? 'Refere-se à taxa de serviço da plataforma GreenGo sobre as suas vendas de ingressos, retida da sua conta de pagamentos conectada.'
    : 'It covers the GreenGo platform service fee on your ticket sales, collected from your connected payment account.'}</p>
${inv.nfse.status === 'authorized' && inv.nfse.url ? `<p>NFS-e nº ${escapeHtml(inv.nfse.number)}: <a href="${escapeHtml(inv.nfse.url)}">${escapeHtml(inv.nfse.url)}</a></p>` : ''}
<p>GreenGo</p>`,
    text: `${title} ${inv.number} (${amount})`,
    attachments: [{ filename: `${inv.number}.pdf`, content: buffer, contentType: 'application/pdf' }],
  }), { invoiceId: inv.id });
  if (res !== 'duplicate' && res.sent) {
    await db().collection(FCOL.invoices).doc(inv.id).set({ emailedAt: ts(financeDeps.now()) }, { merge: true });
    return 'sent';
  }
  return res === 'duplicate' ? 'duplicate' : (res.reason || 'not_sent');
}

// ─────────────────────────────────────────────────────────────── pipeline

/** NFS-e -> PDF -> e-mail. Safe to call again (each step is idempotent). */
export async function processDocument(id: string, opts: { email?: boolean } = {}): Promise<StoredInvoice | null> {
  const st = await loadSettings();
  const snap = await db().collection(FCOL.invoices).doc(id).get();
  if (!snap.exists) return null;
  let inv = docToInvoice(id, snap.data());
  if (inv.nfse.status === 'pending') {
    inv = { ...inv, nfse: await submitNfse(inv, st) };
  }
  const { buffer } = await renderAndStorePdf(inv);
  // Sellers get their invoices in the monthly batch (statements.ts); a direct
  // e-mail happens only when a caller asks for it (admin "e-mail" action).
  const wantEmail = opts.email ?? false;
  if (wantEmail && !inv.emailedAt) {
    try { await emailInvoice(inv, buffer); } catch (e) { console.warn('[finance] email', id, (e as Error)?.message); }
  }
  return inv;
}

/**
 * Credit note reversing [invoiceId]; the original becomes 'void' and its
 * NFS-e is cancelled. Idempotent (credit note id = [creditId]).
 */
export async function creditDocument(
  invoiceId: string,
  creditId: string,
  reason: string,
  by: string,
): Promise<StoredInvoice | null> {
  const st = await loadSettings();
  const snap = await db().collection(FCOL.invoices).doc(invoiceId).get();
  if (!snap.exists) return null;
  const orig = docToInvoice(invoiceId, snap.data());
  if (orig.type !== 'invoice') throw new Error('only invoices can be credited');
  if (orig.status === 'void' && orig.creditNoteId) {
    const cn = await db().collection(FCOL.invoices).doc(orig.creditNoteId).get();
    return cn.exists ? docToInvoice(cn.id, cn.data()) : null;
  }
  const { invoice: cn } = await createDocument(creditId, creditNoteFor(orig, reason), st, by);
  const nfse = await cancelNfseOf(orig, reason);
  const voided: StoredInvoice = { ...orig, status: 'void', nfse, creditNoteId: cn.id, voidedBy: by };
  await snap.ref.set({
    status: 'void', nfse, creditNoteId: cn.id, voidedBy: by, voidReason: reason.slice(0, 300),
    voidedAt: ts(financeDeps.now()), updatedAt: ts(financeDeps.now()),
  }, { merge: true });
  await renderAndStorePdf(voided);
  await processDocument(cn.id, { email: false });
  return cn;
}
