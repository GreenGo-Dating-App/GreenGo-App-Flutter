/**
 * Finance — invoices, credit notes, business statements and sales stats.
 * PURE module (no Firestore, no network): settings validation, numbering,
 * the invoice built from a ticket order, tax maths and statement totals live
 * here so they can be unit-tested exhaustively.
 *
 * Owner rules (2026-10-14): GreenGo invoices ONLY its own service fee, and
 * the ticket service fee is owed by the SELLER (the organizer / business),
 * never the buyer. With Stripe Connect direct charges the fee is the
 * application fee GreenGo takes from the seller's connected account, so the
 * customer of every fee invoice is the seller. Buyers receive no finance
 * documents.
 *   - sellerFeeInvoicing 'monthly' (default): one fee invoice per currency per
 *     month (fees of the month minus fees refunded that month; one NFS-e
 *     instead of one per order), e-mailed together with the monthly
 *     STATEMENT (sales paid by buyers, refunds, GreenGo fees, net). A month
 *     whose refunded fees exceed its fees gets a credit note instead.
 *   - 'per_order': one fee invoice per paid ticket order, a credit note when
 *     the order is fully refunded / disputed.
 * A statement is not a tax document; the fee invoice (+ NFS-e in Brazil) is.
 *
 * Jurisdiction switch (finance_config/invoicing.jurisdiction):
 *   'BR'  issuer = Universo Kardasha Ltda. Every invoice is also submitted as
 *         an NFS-e through the configured provider (./nfse.ts). The PDF is
 *         ALWAYS generated; once the NFS-e is authorized the PDF shows its
 *         number + verification code + link, before that it says "NFS-e
 *         pending" (the PDF itself is NOT the fiscal document in Brazil).
 *   'US'  no government e-invoicing: the PDF invoice IS the invoice. Optional
 *         sales tax, always INCLUDED in the fee the buyer already paid.
 * The jurisdiction is snapshotted on each invoice; switching never rewrites
 * already issued documents.
 *
 * Test mode: an invoice is a TEST invoice when the buyer or the organizer is a
 * test user (profiles.isTestUser / tier TEST) or an admin creates it with the
 * "test invoice" action. Test invoices use their own number series (TEST-…),
 * carry a TEST watermark, are submitted ONLY to the NFS-e sandbox
 * (homologação) or the mock provider, never to production, and are excluded
 * from sales stats.
 *
 * ─────────────────────────────────────────────────────────────── DATA MODEL
 * (all collections server-only: the rules' default deny covers them; the admin
 *  panel reads them through the adminFinance callable)
 *
 * finance_config/invoicing        InvoicingSettings (below)
 * server_secrets/invoicing        { focusnfeTokenProducao, focusnfeTokenHomologacao }
 * finance_counters/{series}_{yyyy} { seq }   one transaction per number
 * finance_invoices/{id}           FinanceInvoice; id fee_{orderId} | cn_{orderId}
 *                                 | man_{auto} | test_{auto} | cnm_{invoiceId}
 * finance_statements/{orgId}_{yyyymm}  BusinessStatement
 * finance_order_marks/{orderId}   { paidCounted, reversalCounted } trigger dedupe
 * finance_billing_profiles/{uid}  seller billing details (admin-entered): legalName, taxId, address, email
 * business_stats/{orgId}          lifetime totals per currency
 * business_stats/{orgId}/months/{yyyymm}  month totals per currency (statements)
 * admin_stats_daily/{yyyy-mm-dd}  platform totals per day and currency
 * Storage finance/invoices/{id}.pdf, finance/statements/{id}.pdf
 */

export type Jurisdiction = 'BR' | 'US';
export type NfseProviderId = 'focusnfe' | 'mock';
export type NfseEnvironment = 'homologacao' | 'producao';

export interface BrIssuer {
  legalName: string;
  tradeName: string;
  cnpj: string;
  inscricaoMunicipal: string;
  /** IBGE municipality code, 7 digits. */
  codigoMunicipio: string;
  address: string;
  city: string;
  uf: string;
  cep: string;
  email: string;
  phone: string;
  /** LC 116/2003 service list item, e.g. "01.03" or "10.05". */
  itemListaServico: string;
  codigoTributarioMunicipio: string;
  cnae: string;
  /** ISS rate in percent (2..5). Informational: ISS is included in the fee. */
  aliquotaIss: number;
  issRetido: boolean;
  optanteSimplesNacional: boolean;
  /** Focus NFe / ABRASF regime_especial_tributacao code, '' = none. */
  regimeEspecialTributacao: string;
  /** ABRASF natureza_operacao, '1' = tributação no município. */
  naturezaOperacao: string;
  /** "{title}" / "{kind}" / "{orderId}" are replaced. */
  serviceDescriptionTemplate: string;
  /** Fixed BRL rate per currency for orders not paid in BRL (e.g. { usd: 5.4 }). */
  fxToBrl: Record<string, number>;
}

export interface NfseSettings {
  enabled: boolean;
  provider: NfseProviderId;
  /** Production invoices only. Test invoices ALWAYS go to homologação / mock. */
  environment: NfseEnvironment;
  /** Send the tomador without CPF/CNPJ when we do not have one (municipality must allow it). */
  allowUnidentifiedTomador: boolean;
}

export interface UsIssuer {
  legalName: string;
  ein: string;
  address: string;
  city: string;
  state: string;
  zip: string;
  email: string;
  phone: string;
  /** Percent, INCLUDED in the fee (0 = no sales tax line). */
  salesTaxRate: number;
  salesTaxLabel: string;
  footerNote: string;
}

export interface NumberingSettings {
  prefix: string;
  creditPrefix: string;
  testPrefix: string;
  padding: number;
}

export interface InvoicingSettings {
  jurisdiction: Jurisdiction;
  autoIssueFeeInvoices: boolean;
  /** 'monthly' = one fee invoice per seller per month (with the statement); 'per_order' = one per order. */
  sellerFeeInvoicing: 'monthly' | 'per_order';
  autoCreditNotes: boolean;
  emailInvoicesToSellers: boolean;
  monthlyStatements: boolean;
  emailStatementsToBusinesses: boolean;
  br: BrIssuer;
  nfse: NfseSettings;
  us: UsIssuer;
  numbering: NumberingSettings;
}

export const DEFAULT_SETTINGS: InvoicingSettings = {
  jurisdiction: 'BR',
  autoIssueFeeInvoices: true,
  sellerFeeInvoicing: 'monthly',
  autoCreditNotes: true,
  emailInvoicesToSellers: true,
  monthlyStatements: true,
  emailStatementsToBusinesses: true,
  br: {
    legalName: 'Universo Kardasha Ltda.',
    tradeName: 'GreenGo',
    cnpj: '40.486.663/0001-82',
    inscricaoMunicipal: '',
    codigoMunicipio: '',
    address: '',
    city: '',
    uf: '',
    cep: '',
    email: 'support@greengochat.com',
    phone: '',
    itemListaServico: '',
    codigoTributarioMunicipio: '',
    cnae: '',
    aliquotaIss: 5,
    issRetido: false,
    optanteSimplesNacional: false,
    regimeEspecialTributacao: '',
    naturezaOperacao: '1',
    serviceDescriptionTemplate: 'Taxa de serviço GreenGo sobre venda de ingressos — {kind}: {title} (pedido {orderId})',
    fxToBrl: {},
  },
  nfse: {
    enabled: true,
    provider: 'mock',
    environment: 'homologacao',
    allowUnidentifiedTomador: true,
  },
  us: {
    legalName: 'GreenGo',
    ein: '',
    address: '',
    city: '',
    state: '',
    zip: '',
    email: 'support@greengochat.com',
    phone: '',
    salesTaxRate: 0,
    salesTaxLabel: 'Sales tax',
    footerNote: '',
  },
  numbering: { prefix: 'GG', creditPrefix: 'GGCN', testPrefix: 'TEST', padding: 6 },
};

export class SettingsError extends Error {
  constructor(public field: string, msg: string) { super(`${field}: ${msg}`); }
}

const s = (v: unknown, field: string, max = 300): string => {
  if (v === undefined || v === null) return '';
  if (typeof v !== 'string') throw new SettingsError(field, 'must be a string');
  const t = v.trim();
  if (t.length > max) throw new SettingsError(field, `max ${max} characters`);
  return t;
};
const b = (v: unknown, fallback: boolean): boolean => (typeof v === 'boolean' ? v : fallback);
const pct = (v: unknown, field: string, fallback: number): number => {
  if (v === undefined || v === null || v === '') return fallback;
  const n = Number(v);
  if (!Number.isFinite(n) || n < 0 || n > 30) throw new SettingsError(field, 'must be a percent between 0 and 30');
  return Math.round(n * 1000) / 1000;
};
const digits = (v: string): string => v.replace(/\D/g, '');

/** Valid CNPJ check digits (formatting ignored). */
export function isValidCnpj(v: string): boolean {
  const d = digits(v);
  if (d.length !== 14 || /^(\d)\1+$/.test(d)) return false;
  const calc = (len: number): number => {
    const w = len === 12 ? [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2] : [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const sum = w.reduce((acc, wi, i) => acc + Number(d[i]) * wi, 0);
    const r = sum % 11;
    return r < 2 ? 0 : 11 - r;
  };
  return calc(12) === Number(d[12]) && calc(13) === Number(d[13]);
}

/** Valid CPF check digits (formatting ignored). */
export function isValidCpf(v: string): boolean {
  const d = digits(v);
  if (d.length !== 11 || /^(\d)\1+$/.test(d)) return false;
  const dv = (len: number): number => {
    let sum = 0;
    for (let i = 0; i < len; i++) sum += Number(d[i]) * (len + 1 - i);
    const r = (sum * 10) % 11;
    return r === 10 ? 0 : r;
  };
  return dv(9) === Number(d[9]) && dv(10) === Number(d[10]);
}

/** Stored doc (possibly partial / old) -> complete settings. Never throws. */
export function settingsFromDoc(raw: any): InvoicingSettings {
  try {
    return normalizeSettings(raw || {});
  } catch {
    return { ...DEFAULT_SETTINGS };
  }
}

/** Admin input -> validated settings (throws SettingsError). Missing fields keep the defaults. */
export function normalizeSettings(raw: any): InvoicingSettings {
  const D = DEFAULT_SETTINGS;
  const jur = raw.jurisdiction ?? D.jurisdiction;
  if (jur !== 'BR' && jur !== 'US') throw new SettingsError('jurisdiction', 'must be BR or US');
  const br = raw.br || {};
  const nf = raw.nfse || {};
  const us = raw.us || {};
  const num = raw.numbering || {};

  const cnpj = s(br.cnpj ?? D.br.cnpj, 'br.cnpj', 20);
  if (cnpj && !isValidCnpj(cnpj)) throw new SettingsError('br.cnpj', 'invalid CNPJ');
  const cm = s(br.codigoMunicipio, 'br.codigoMunicipio', 7);
  if (cm && !/^\d{7}$/.test(cm)) throw new SettingsError('br.codigoMunicipio', 'must be the 7-digit IBGE code');
  const fx: Record<string, number> = {};
  if (br.fxToBrl && typeof br.fxToBrl === 'object') {
    for (const [k, v] of Object.entries(br.fxToBrl)) {
      const cur = k.toLowerCase();
      const n = Number(v);
      if (!/^[a-z]{3}$/.test(cur) || !Number.isFinite(n) || n <= 0 || n > 10000) {
        throw new SettingsError('br.fxToBrl', `invalid rate for ${k}`);
      }
      fx[cur] = n;
    }
  }
  const provider = nf.provider ?? D.nfse.provider;
  if (provider !== 'focusnfe' && provider !== 'mock') throw new SettingsError('nfse.provider', 'must be focusnfe or mock');
  const env = nf.environment ?? D.nfse.environment;
  if (env !== 'homologacao' && env !== 'producao') throw new SettingsError('nfse.environment', 'must be homologacao or producao');
  if (provider === 'mock' && env === 'producao') {
    throw new SettingsError('nfse.environment', 'the mock provider cannot be used in production');
  }

  const prefix = (v: unknown, field: string, fallback: string): string => {
    const p = s(v ?? fallback, field, 8).toUpperCase();
    if (!/^[A-Z]{2,8}$/.test(p)) throw new SettingsError(field, '2-8 letters');
    return p;
  };
  const numbering: NumberingSettings = {
    prefix: prefix(num.prefix, 'numbering.prefix', D.numbering.prefix),
    creditPrefix: prefix(num.creditPrefix, 'numbering.creditPrefix', D.numbering.creditPrefix),
    testPrefix: prefix(num.testPrefix, 'numbering.testPrefix', D.numbering.testPrefix),
    padding: Math.min(10, Math.max(4, Math.round(Number(num.padding ?? D.numbering.padding)) || 6)),
  };
  const pfx = new Set([numbering.prefix, numbering.creditPrefix, numbering.testPrefix]);
  if (pfx.size !== 3) throw new SettingsError('numbering', 'the three prefixes must differ');

  return {
    jurisdiction: jur,
    autoIssueFeeInvoices: b(raw.autoIssueFeeInvoices, D.autoIssueFeeInvoices),
    sellerFeeInvoicing: raw.sellerFeeInvoicing === 'per_order' ? 'per_order' : 'monthly',
    autoCreditNotes: b(raw.autoCreditNotes, D.autoCreditNotes),
    emailInvoicesToSellers: b(raw.emailInvoicesToSellers, D.emailInvoicesToSellers),
    monthlyStatements: b(raw.monthlyStatements, D.monthlyStatements),
    emailStatementsToBusinesses: b(raw.emailStatementsToBusinesses, D.emailStatementsToBusinesses),
    br: {
      legalName: s(br.legalName ?? D.br.legalName, 'br.legalName', 150),
      tradeName: s(br.tradeName ?? D.br.tradeName, 'br.tradeName', 150),
      cnpj,
      inscricaoMunicipal: s(br.inscricaoMunicipal, 'br.inscricaoMunicipal', 20),
      codigoMunicipio: cm,
      address: s(br.address, 'br.address', 200),
      city: s(br.city, 'br.city', 80),
      uf: s(br.uf, 'br.uf', 2).toUpperCase(),
      cep: s(br.cep, 'br.cep', 9),
      email: s(br.email ?? D.br.email, 'br.email', 120),
      phone: s(br.phone, 'br.phone', 30),
      itemListaServico: s(br.itemListaServico, 'br.itemListaServico', 10),
      codigoTributarioMunicipio: s(br.codigoTributarioMunicipio, 'br.codigoTributarioMunicipio', 20),
      cnae: s(br.cnae, 'br.cnae', 10),
      aliquotaIss: pct(br.aliquotaIss, 'br.aliquotaIss', D.br.aliquotaIss),
      issRetido: b(br.issRetido, D.br.issRetido),
      optanteSimplesNacional: b(br.optanteSimplesNacional, D.br.optanteSimplesNacional),
      regimeEspecialTributacao: s(br.regimeEspecialTributacao, 'br.regimeEspecialTributacao', 2),
      naturezaOperacao: s(br.naturezaOperacao ?? D.br.naturezaOperacao, 'br.naturezaOperacao', 2) || '1',
      serviceDescriptionTemplate:
        s(br.serviceDescriptionTemplate ?? D.br.serviceDescriptionTemplate, 'br.serviceDescriptionTemplate', 500) ||
        D.br.serviceDescriptionTemplate,
      fxToBrl: fx,
    },
    nfse: {
      enabled: b(nf.enabled, D.nfse.enabled),
      provider,
      environment: env,
      allowUnidentifiedTomador: b(nf.allowUnidentifiedTomador, D.nfse.allowUnidentifiedTomador),
    },
    us: {
      legalName: s(us.legalName ?? D.us.legalName, 'us.legalName', 150),
      ein: s(us.ein, 'us.ein', 12),
      address: s(us.address, 'us.address', 200),
      city: s(us.city, 'us.city', 80),
      state: s(us.state, 'us.state', 2).toUpperCase(),
      zip: s(us.zip, 'us.zip', 10),
      email: s(us.email ?? D.us.email, 'us.email', 120),
      phone: s(us.phone, 'us.phone', 30),
      salesTaxRate: pct(us.salesTaxRate, 'us.salesTaxRate', D.us.salesTaxRate),
      salesTaxLabel: s(us.salesTaxLabel ?? D.us.salesTaxLabel, 'us.salesTaxLabel', 40) || 'Sales tax',
      footerNote: s(us.footerNote, 'us.footerNote', 500),
    },
    numbering,
  };
}

/** What blocks production NFS-e issuing (empty = ready). */
export function nfseReadiness(st: InvoicingSettings): string[] {
  const missing: string[] = [];
  const br = st.br;
  if (!isValidCnpj(br.cnpj)) missing.push('br.cnpj');
  if (!br.inscricaoMunicipal) missing.push('br.inscricaoMunicipal');
  if (!/^\d{7}$/.test(br.codigoMunicipio)) missing.push('br.codigoMunicipio');
  if (!br.itemListaServico) missing.push('br.itemListaServico');
  if (!(br.aliquotaIss > 0)) missing.push('br.aliquotaIss');
  return missing;
}

// ─────────────────────────────────────────────────────────────── numbering

export type InvoiceType = 'invoice' | 'credit_note';

export function seriesFor(st: InvoicingSettings, type: InvoiceType, isTest: boolean): string {
  if (isTest) return type === 'credit_note' ? `${st.numbering.testPrefix}CN` : st.numbering.testPrefix;
  return type === 'credit_note' ? st.numbering.creditPrefix : st.numbering.prefix;
}

/** GG-2026-000123 */
export function formatNumber(series: string, year: number, seq: number, padding: number): string {
  return `${series}-${year}-${String(seq).padStart(padding, '0')}`;
}

export function counterId(series: string, year: number): string {
  return `${series}_${year}`;
}

// ─────────────────────────────────────────────────────────────── documents

export interface Party {
  uid: string | null;
  name: string;
  email: string | null;
  /** CPF / CNPJ (BR) or EIN / SSN-free tax id (US). Optional. */
  taxId: string | null;
  address: string | null;
  isGuest?: boolean;
}

export interface InvoiceLine {
  description: string;
  quantity: number;
  /** minor units */
  unitAmount: number;
  /** minor units */
  amount: number;
}

export interface TaxInfo {
  label: string;
  rate: number;
  /** minor units, INCLUDED in total */
  amount: number;
  included: true;
}

export type NfseStatus =
  | 'not_required' | 'pending' | 'processing' | 'authorized' | 'error' | 'needs_review'
  | 'cancel_pending' | 'cancelled';

export interface NfseState {
  status: NfseStatus;
  provider: NfseProviderId | null;
  environment: NfseEnvironment | null;
  ref: string | null;
  number: string | null;
  verificationCode: string | null;
  url: string | null;
  xmlUrl: string | null;
  error: string | null;
  attempts: number;
  /** BRL minor units actually declared on the NFS-e. */
  valueBrl: number | null;
}

export interface InvoiceSource {
  kind: 'ticket_fee' | 'monthly_fee' | 'manual' | 'test';
  month?: string;
  orders?: number;
  orderId?: string;
  listingKind?: 'event' | 'experience';
  listingId?: string;
  organizerId?: string;
  title?: string;
}

export interface FinanceInvoiceDraft {
  type: InvoiceType;
  jurisdiction: Jurisdiction;
  isTest: boolean;
  source: InvoiceSource;
  customer: Party;
  lines: InvoiceLine[];
  currency: string;
  /** minor units */
  total: number;
  tax: TaxInfo | null;
  relatedInvoiceId: string | null;
  notes: string;
}

/** Tax already contained in [total] at [ratePct]: total - total / (1 + r). */
export function includedTax(total: number, ratePct: number): number {
  if (!(ratePct > 0) || !(total > 0)) return 0;
  return Math.round(total - total / (1 + ratePct / 100));
}

export function taxFor(st: InvoicingSettings, jurisdiction: Jurisdiction, total: number): TaxInfo | null {
  if (jurisdiction === 'BR') {
    // ISS is part of the service price; shown for information (and declared on the NFS-e).
    return st.br.aliquotaIss > 0
      ? { label: 'ISS', rate: st.br.aliquotaIss, amount: Math.round((total * st.br.aliquotaIss) / 100), included: true }
      : null;
  }
  return st.us.salesTaxRate > 0
    ? { label: st.us.salesTaxLabel, rate: st.us.salesTaxRate, amount: includedTax(total, st.us.salesTaxRate), included: true }
    : null;
}

export function fillTemplate(tpl: string, vars: Record<string, string>): string {
  return tpl.replace(/\{(\w+)\}/g, (m, k) => (k in vars ? vars[k] : m));
}

export const SELLER_NOTE: Record<Jurisdiction, string> = {
  BR: 'Taxa de serviço da plataforma GreenGo sobre a venda de ingressos, devida pelo organizador e retida da sua conta de pagamentos conectada.',
  US: 'GreenGo platform service fee on your ticket sales, payable by the organizer and collected as an application fee from your connected payment account.',
};

/**
 * The SELLER's fee invoice for one PAID ticket order ('per_order' mode), or
 * null when there is no fee (free tickets, legacy link orders, zero fee).
 * [customer] is the organizer.
 */
export function feeInvoiceFromOrder(
  st: InvoicingSettings,
  orderId: string,
  o: any,
  customer: Party,
  isTest: boolean,
): FinanceInvoiceDraft | null {
  const fee = Number(o?.feeTotal);
  if (!Number.isFinite(fee) || fee <= 0) return null;
  const currency = String(o.currency || '').toLowerCase();
  if (!/^[a-z]{3}$/.test(currency)) return null;
  const qty = Math.max(1, Math.round(Number(o.quantity) || 1));
  const kind: 'event' | 'experience' = o.kind === 'experience' ? 'experience' : 'event';
  const title = String(o.title || '').slice(0, 200);
  const jur = st.jurisdiction;
  const description = jur === 'BR'
    ? fillTemplate(st.br.serviceDescriptionTemplate, {
      kind: kind === 'event' ? 'evento' : 'experiência', title, orderId,
    })
    : `GreenGo service fee on ticket sales — ${kind}: ${title} (order ${orderId})`;
  const unit = Number.isFinite(Number(o.feePerTicket)) && Number(o.feePerTicket) > 0 && Number(o.feePerTicket) * qty === fee
    ? Number(o.feePerTicket)
    : fee;
  const lineQty = unit === fee ? 1 : qty;
  return {
    type: 'invoice',
    jurisdiction: jur,
    isTest,
    source: { kind: 'ticket_fee', orderId, listingKind: kind, listingId: o.listingId || undefined, organizerId: o.organizerId, title },
    customer,
    lines: [{ description, quantity: lineQty, unitAmount: unit, amount: fee }],
    currency,
    total: fee,
    tax: taxFor(st, jur, fee),
    relatedInvoiceId: null,
    notes: SELLER_NOTE[jur],
  };
}

/**
 * The seller's monthly fee document for one currency ('monthly' mode):
 * GreenGo fees of [month] minus fees refunded in [month]. Null when the net
 * is 0; a CREDIT NOTE draft (negative amounts) when it is negative.
 */
export function monthlyFeeDraft(
  st: InvoicingSettings,
  organizerId: string,
  month: string,
  line: StatementCurrencyLine,
  customer: Party,
  isTest: boolean,
  listings: StatementListingLine[] = [],
): FinanceInvoiceDraft | null {
  const total = line.feesNet;
  if (!total) return null;
  const jur = st.jurisdiction;
  const period = `${month.slice(4)}/${month.slice(0, 4)}`;
  // One line per event / experience the seller earned money from this month.
  const own = listings.filter((l) => l.currency === line.currency);
  const listed = own.reduce((a, l) => a + l.feesNet, 0);
  const invLines: InvoiceLine[] = own.map((l) => ({
    description: listingLineText(l, jur), quantity: 1, unitAmount: l.feesNet, amount: l.feesNet,
  }));
  // Orders counted before per-listing totals existed (or without a listing id).
  if (listed !== total) {
    const rest = total - listed;
    invLines.push({
      description: jur === 'BR'
        ? `Outras vendas de ingressos — ${period}`
        : `Other ticket sales — ${period}`,
      quantity: 1, unitAmount: rest, amount: rest,
    });
  }
  const summary = jur === 'BR'
    ? ` Período ${period}: ${plural(line.orders, 'pedido', 'pedidos')}, ${plural(line.tickets, 'ingresso', 'ingressos')}, vendas ${formatMoney(line.sales, line.currency, 'pt-BR')}.`
    : ` Period ${period}: ${plural(line.orders, 'order', 'orders')}, ${plural(line.tickets, 'ticket', 'tickets')}, sales ${formatMoney(line.sales, line.currency, 'en-US')}.`;
  const refundNote = line.refundedFees
    ? (jur === 'BR'
      ? ` Já deduzidas as taxas estornadas no mês (${formatMoney(line.refundedFees, line.currency, 'pt-BR')}).`
      : ` Net of fees refunded this month (${formatMoney(line.refundedFees, line.currency, 'en-US')}).`)
    : '';
  const tax = taxFor(st, jur, Math.abs(total));
  return {
    type: total > 0 ? 'invoice' : 'credit_note',
    jurisdiction: jur,
    isTest,
    source: { kind: 'monthly_fee', organizerId, month, orders: line.orders },
    customer,
    lines: invLines,
    currency: line.currency,
    total,
    tax: tax ? { ...tax, amount: Math.sign(total) * tax.amount } : null,
    relatedInvoiceId: null,
    notes: SELLER_NOTE[jur] + summary + refundNote,
  };
}

export const monthlyFeeInvoiceId = (organizerId: string, month: string, currency: string, isTest: boolean): string =>
  `${isTest ? 'testfee' : 'mfee'}_${organizerId}_${month}_${currency}`;

/** Credit note fully reversing [inv] (keeps its jurisdiction, currency and test flag). */
export function creditNoteFor(inv: { id: string; jurisdiction: Jurisdiction; isTest: boolean; source: InvoiceSource;
  customer: Party; lines: InvoiceLine[]; currency: string; total: number; tax: TaxInfo | null; number: string }, reason: string): FinanceInvoiceDraft {
  return {
    type: 'credit_note',
    jurisdiction: inv.jurisdiction,
    isTest: inv.isTest,
    source: inv.source,
    customer: inv.customer,
    lines: inv.lines.map((l) => ({ ...l, unitAmount: -l.unitAmount, amount: -l.amount })),
    currency: inv.currency,
    total: -inv.total,
    tax: inv.tax ? { ...inv.tax, amount: -inv.tax.amount } : null,
    relatedInvoiceId: inv.id,
    notes: `${inv.jurisdiction === 'BR' ? 'Estorno da fatura' : 'Credit note for invoice'} ${inv.number}${reason ? ` — ${reason}` : ''}`,
  };
}

/** Initial NFS-e state for a new document. */
export function initialNfse(st: InvoicingSettings, d: FinanceInvoiceDraft): NfseState {
  const base: NfseState = {
    status: 'not_required', provider: null, environment: null, ref: null, number: null,
    verificationCode: null, url: null, xmlUrl: null, error: null, attempts: 0, valueBrl: null,
  };
  // NFS-e: Brazil only, invoices only (a credit note CANCELS the original NFS-e instead).
  if (d.jurisdiction !== 'BR' || d.type !== 'invoice' || !st.nfse.enabled) return base;
  const env: NfseEnvironment = d.isTest ? 'homologacao' : st.nfse.environment;
  const provider: NfseProviderId = d.isTest && st.nfse.provider !== 'focusnfe' ? 'mock' : st.nfse.provider;
  const valueBrl = toBrlMinor(d.total, d.currency, st.br.fxToBrl);
  if (valueBrl === null) {
    return { ...base, status: 'needs_review', provider, environment: env, error: `currency_not_brl:${d.currency}` };
  }
  return { ...base, status: 'pending', provider, environment: env, valueBrl };
}

/** Minor units in [currency] -> BRL centavos, or null when there is no rate. */
export function toBrlMinor(amount: number, currency: string, fx: Record<string, number>): number | null {
  const cur = currency.toLowerCase();
  if (cur === 'brl') return amount;
  const rate = fx[cur];
  if (!(rate > 0)) return null;
  const exp = ZERO_DECIMAL.has(cur) ? 0 : 2;
  return Math.round((amount / 10 ** exp) * rate * 100);
}

const ZERO_DECIMAL = new Set(['bif', 'clp', 'djf', 'gnf', 'jpy', 'kmf', 'krw', 'mga', 'pyg', 'rwf', 'ugx', 'vnd', 'vuv', 'xaf', 'xof', 'xpf']);

export function currencyExponent(currency: string): number {
  return ZERO_DECIMAL.has(currency.toLowerCase()) ? 0 : 2;
}

/** 1234 + 'brl' -> "R$ 12,34"; 1234 + 'usd' -> "$12.34". */
export function formatMoney(minor: number, currency: string, locale?: 'pt-BR' | 'en-US'): string {
  const cur = currency.toUpperCase();
  const major = minor / 10 ** currencyExponent(currency);
  const loc = locale || (cur === 'BRL' ? 'pt-BR' : 'en-US');
  try {
    return new Intl.NumberFormat(loc, { style: 'currency', currency: cur }).format(major);
  } catch {
    return `${cur} ${major.toFixed(currencyExponent(currency))}`;
  }
}

// ─────────────────────────────────────────────────────────────── stats

export interface MoneyTotals {
  /** ticket price the organizers receive (ticketSubtotal) */
  gross: number;
  /** GreenGo service fees (feeTotal) */
  fees: number;
  /** what buyers paid (totalAmount) */
  buyerTotal: number;
  refunds: number;
  refundedFees: number;
  /** totalAmount returned to buyers */
  refundedBuyer: number;
  orders: number;
  tickets: number;
  refundedOrders: number;
}

export interface OrderAmounts { currency: string; gross: number; fees: number; buyerTotal: number; tickets: number }

export function orderAmounts(o: any): OrderAmounts | null {
  const currency = String(o?.currency || '').toLowerCase();
  if (!/^[a-z]{3}$/.test(currency)) return null;
  const n = (v: unknown) => (Number.isFinite(Number(v)) ? Math.round(Number(v)) : 0);
  const fees = n(o.feeTotal);
  const buyerTotal = n(o.totalAmount);
  const gross = o.ticketSubtotal !== undefined && o.ticketSubtotal !== null ? n(o.ticketSubtotal) : Math.max(0, buyerTotal - fees);
  return { currency, gross, fees, buyerTotal, tickets: Math.max(1, n(o.quantity) || 1) };
}

export type OrderTransition = 'paid' | 'reversed' | null;

/** Which money event a ticket_orders write represents (state-based, idempotent with the order mark). */
export function orderTransition(before: any, after: any): OrderTransition {
  const b0 = before?.status;
  const a0 = after?.status;
  if (a0 === 'paid' && b0 !== 'paid') return 'paid';
  if ((a0 === 'refunded' || a0 === 'disputed') && b0 === 'paid') return 'reversed';
  // A paid order deleted / created already reversed is ignored (never seen in prod).
  return null;
}

/** UTC calendar keys. */
export function dayKey(d: Date): string { return d.toISOString().slice(0, 10); }
export function monthKey(d: Date): string { return d.toISOString().slice(0, 7).replace('-', ''); }
export function previousMonthKey(now: Date): string {
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1));
  return monthKey(d);
}
export function monthRange(month: string): { start: Date; end: Date } {
  if (!/^\d{6}$/.test(month)) throw new Error('month must be YYYYMM');
  const y = Number(month.slice(0, 4));
  const m = Number(month.slice(4)) - 1;
  if (m < 0 || m > 11) throw new Error('month must be YYYYMM');
  return { start: new Date(Date.UTC(y, m, 1)), end: new Date(Date.UTC(y, m + 1, 1)) };
}

// ─────────────────────────────────────────────────────────────── statements

export interface StatementCurrencyLine extends MoneyTotals {
  currency: string;
  /** what buyers paid (= totalAmount: ticket price on seller-pays orders, price + fee on legacy ones) */
  sales: number;
  /** everything returned to buyers (ticket price + fee) */
  refundedTotal: number;
  /** GreenGo fees owed by the seller for the month: fees - refundedFees */
  feesNet: number;
  /** sales - refundedTotal - feesNet: what the seller keeps before the provider's own fees */
  net: number;
}

export function statementLines(byCurrency: Record<string, Partial<MoneyTotals>> | undefined): StatementCurrencyLine[] {
  const out: StatementCurrencyLine[] = [];
  for (const [currency, t] of Object.entries(byCurrency || {})) {
    const n = (v: unknown) => (Number.isFinite(Number(v)) ? Number(v) : 0);
    const line: StatementCurrencyLine = {
      currency,
      gross: n(t.gross), fees: n(t.fees), buyerTotal: n(t.buyerTotal), refunds: n(t.refunds),
      refundedFees: n(t.refundedFees), refundedBuyer: n(t.refundedBuyer), orders: n(t.orders), tickets: n(t.tickets),
      refundedOrders: n(t.refundedOrders),
      sales: 0, refundedTotal: 0, feesNet: 0, net: 0,
    };
    line.sales = line.buyerTotal || line.gross + line.fees;
    // Docs written before refundedBuyer existed: legacy buyer-pays orders (price + fee).
    line.refundedTotal = t.refundedBuyer !== undefined ? line.refundedBuyer : line.refunds + line.refundedFees;
    line.feesNet = line.fees - line.refundedFees;
    line.net = line.sales - line.refundedTotal - line.feesNet;
    if (line.orders || line.refundedOrders) out.push(line);
  }
  return out.sort((a, c) => a.currency.localeCompare(c.currency));
}

const plural = (n: number, one: string, many: string) => `${n} ${n === 1 ? one : many}`;

/** Per event / experience month totals: business_stats/{org}/months/{m}.byListing.{key}. */
export interface StatementListingLine extends StatementCurrencyLine {
  key: string;
  listingId: string;
  kind: 'event' | 'experience';
  title: string;
}

/** Map key of a listing in byListing (one entry per listing AND currency). */
export function listingKey(kind: string, listingId: string, currency: string): string {
  return `${kind === 'experience' ? 'x' : 'e'}_${String(listingId).replace(/[^A-Za-z0-9_-]/g, '_')}_${currency}`;
}

/** byListing map -> lines with money, biggest sales first. */
export function statementListingLines(byListing: Record<string, any> | undefined): StatementListingLine[] {
  const out: StatementListingLine[] = [];
  for (const [key, t] of Object.entries(byListing || {})) {
    if (!t || typeof t !== 'object' || !/^[a-z]{3}$/.test(String(t.currency || ''))) continue;
    const [line] = statementLines({ [t.currency]: t });
    if (!line) continue;
    out.push({
      ...line, key, listingId: String(t.listingId || ''), kind: t.kind === 'experience' ? 'experience' : 'event',
      title: String(t.title || '').slice(0, 200) || (t.kind === 'experience' ? 'Experience' : 'Event'),
    });
  }
  return out.sort((a, b) => b.sales - a.sales || a.title.localeCompare(b.title));
}

/** "Evento: Samba night — 2 pedidos, 4 ingressos, vendas R$ 120,00" */
export function listingLineText(l: StatementListingLine, jur: Jurisdiction): string {
  const money = formatMoney(l.sales, l.currency, jur === 'BR' ? 'pt-BR' : 'en-US');
  const refunded = l.refundedOrders
    ? (jur === 'BR' ? `, ${plural(l.refundedOrders, 'estorno', 'estornos')}` : `, ${plural(l.refundedOrders, 'refund', 'refunds')}`)
    : '';
  return jur === 'BR'
    ? `${l.kind === 'experience' ? 'Experiência' : 'Evento'}: ${l.title} — ${plural(l.orders, 'pedido', 'pedidos')}, ${plural(l.tickets, 'ingresso', 'ingressos')}, vendas ${money}${refunded}`
    : `${l.kind === 'experience' ? 'Experience' : 'Event'}: ${l.title} — ${plural(l.orders, 'order', 'orders')}, ${plural(l.tickets, 'ticket', 'tickets')}, sales ${money}${refunded}`;
}

/** Latin-1 safe text for the built-in PDF fonts (other scripts -> '?'). */
export function pdfSafe(v: unknown): string {
  return String(v ?? '')
    .normalize('NFC')
    .replace(/[‘’]/g, '\'')
    .replace(/[“”]/g, '"')
    .replace(/[–—]/g, '-')
    .replace(/[^\x09\x0A\x0D\x20-\x7E\xA0-\xFF]/g, '?');
}
