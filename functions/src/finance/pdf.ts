/**
 * Finance PDFs (pdfkit, built-in Helvetica = Latin-1; other scripts render
 * as '?', see pdfSafe). A PDF exists for EVERY document, in both
 * jurisdictions:
 *   - invoice / credit note: labels in Portuguese for BR, English for US.
 *     BR shows the NFS-e block (authorized number + verification code + link,
 *     or "NFS-e pending"); the PDF is the commercial invoice, the NFS-e is the
 *     fiscal document.
 *   - business monthly statement.
 * Test documents carry a diagonal TEST watermark and a banner.
 */
import PDFDocument from 'pdfkit';
import {
  InvoiceLine, Jurisdiction, NfseState, Party, StatementCurrencyLine, StatementListingLine, TaxInfo, formatMoney, pdfSafe,
} from './model';

export interface IssuerSnapshot {
  legalName: string;
  tradeName?: string;
  taxIdLabel: string;
  taxId: string;
  extraIds?: string[];
  addressLines: string[];
  email?: string;
  phone?: string;
  footerNote?: string;
}

export interface InvoicePdfInput {
  type: 'invoice' | 'credit_note';
  number: string;
  jurisdiction: Jurisdiction;
  isTest: boolean;
  status: 'issued' | 'void';
  issuedAt: Date;
  issuer: IssuerSnapshot;
  customer: Party;
  lines: InvoiceLine[];
  currency: string;
  total: number;
  tax: TaxInfo | null;
  relatedNumber: string | null;
  notes: string;
  nfse: NfseState;
  reference?: string | null;
}

export interface StatementPdfInput {
  number: string;
  month: string;
  isTest: boolean;
  issuedAt: Date;
  issuer: IssuerSnapshot;
  business: Party & { businessName?: string | null };
  lines: StatementCurrencyLine[];
  /** every event / experience that earned money in the month */
  listings?: StatementListingLine[];
  jurisdiction: Jurisdiction;
}

const GREEN = '#1E8E3E';
const DARK = '#1A1A1A';
const MUTED = '#666666';
const LINE = '#DDDDDD';

const L = {
  BR: {
    invoice: 'FATURA DE SERVIÇO', credit: 'NOTA DE CRÉDITO', number: 'Número', date: 'Data de emissão',
    billTo: 'Tomador', issuer: 'Prestador', desc: 'Descrição', qty: 'Qtd.', unit: 'Valor unit.', amount: 'Valor',
    total: 'Total', taxIncl: 'incluído', related: 'Referente à fatura', ref: 'Referência',
    nfse: 'NFS-e', nfseNo: 'NFS-e nº', verif: 'Código de verificação', nfsePending: 'NFS-e em processamento — o documento fiscal será emitido em breve.',
    nfseError: 'NFS-e pendente de revisão', nfseCancelled: 'NFS-e cancelada', nfseEnvTest: 'Ambiente de homologação (sem valor fiscal)',
    voidMark: 'CANCELADA', test: 'DOCUMENTO DE TESTE — SEM VALOR FISCAL',
    statement: 'EXTRATO MENSAL', period: 'Período', business: 'Empresa', currency: 'Moeda', gross: 'Vendas (pagas pelos compradores)',
    fees: 'Taxas de serviço GreenGo (devidas pelo organizador)', refunds: 'Estornos', net: 'Líquido', orders: 'Pedidos', tickets: 'Ingressos',
    byListing: 'Eventos e experiências com vendas', listing: 'Evento / experiência', sales: 'Vendas', fee: 'Taxa GreenGo',
    feeInvoices: 'Fatura(s) de taxas do mês',
    stmtNote: 'Este extrato é informativo e não é um documento fiscal. A taxa de serviço GreenGo é devida pelo organizador e retida da sua conta de pagamentos conectada; o documento fiscal é a fatura de taxas do mês. Taxas do processador de pagamento (Stripe / Mercado Pago) são debitadas diretamente na sua conta conectada.',
    empty: 'Nenhuma venda neste período.',
  },
  US: {
    invoice: 'INVOICE', credit: 'CREDIT NOTE', number: 'Number', date: 'Issue date',
    billTo: 'Bill to', issuer: 'From', desc: 'Description', qty: 'Qty', unit: 'Unit price', amount: 'Amount',
    total: 'Total', taxIncl: 'included', related: 'Credit for invoice', ref: 'Reference',
    nfse: '', nfseNo: '', verif: '', nfsePending: '', nfseError: '', nfseCancelled: '', nfseEnvTest: '',
    voidMark: 'VOID', test: 'TEST DOCUMENT — NOT A REAL INVOICE',
    statement: 'MONTHLY STATEMENT', period: 'Period', business: 'Business', currency: 'Currency', gross: 'Sales (paid by buyers)',
    fees: 'GreenGo service fees (owed by the organizer)', refunds: 'Refunds', net: 'Net', orders: 'Orders', tickets: 'Tickets',
    byListing: 'Events and experiences with sales', listing: 'Event / experience', sales: 'Sales', fee: 'GreenGo fee',
    feeInvoices: "This month's fee invoice(s)",
    stmtNote: "This statement is for information only and is not a tax document. The GreenGo service fee is owed by the organizer and collected from your connected payment account; the tax document is this month's fee invoice. Payment-processor fees (Stripe / Mercado Pago) are debited directly from your connected account.",
    empty: 'No sales in this period.',
  },
};

/** Collects the output; call the returned function AFTER drawing to end the document. */
function collect(doc: any): () => Promise<Buffer> {
  const chunks: Buffer[] = [];
  const out = new Promise<Buffer>((resolve, reject) => {
    doc.on('data', (c: Buffer) => chunks.push(c));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
  });
  return () => { doc.end(); return out; };
}

function fmtDate(d: Date, jur: Jurisdiction): string {
  return d.toLocaleDateString(jur === 'BR' ? 'pt-BR' : 'en-US', {
    timeZone: jur === 'BR' ? 'America/Sao_Paulo' : 'UTC', year: 'numeric', month: '2-digit', day: '2-digit',
  });
}

function watermark(doc: any, text: string): void {
  doc.save();
  doc.rotate(-35, { origin: [300, 420] });
  doc.fontSize(90).fillColor('#E53935').opacity(0.12).text(text, 60, 380, { width: 600, align: 'center' });
  doc.restore();
  doc.opacity(1);
}

function header(doc: any, title: string, issuer: IssuerSnapshot): void {
  doc.rect(0, 0, doc.page.width, 6).fill(GREEN);
  doc.fillColor(GREEN).font('Helvetica-Bold').fontSize(22).text(pdfSafe(issuer.tradeName || 'GreenGo'), 50, 40);
  doc.fillColor(DARK).font('Helvetica-Bold').fontSize(16).text(pdfSafe(title), 300, 44, { width: 245, align: 'right' });
  doc.moveTo(50, 80).lineTo(545, 80).strokeColor(LINE).lineWidth(1).stroke();
}

function partyBlock(doc: any, x: number, y: number, label: string, lines: string[]): number {
  doc.fillColor(MUTED).font('Helvetica-Bold').fontSize(8).text(label.toUpperCase(), x, y);
  let yy = y + 12;
  doc.fillColor(DARK).font('Helvetica').fontSize(9.5);
  for (const ln of lines.filter(Boolean)) {
    doc.text(pdfSafe(ln), x, yy, { width: 230 });
    yy = doc.y + 1;
  }
  return yy;
}

function issuerLines(i: IssuerSnapshot): string[] {
  return [
    i.legalName,
    i.taxId ? `${i.taxIdLabel}: ${i.taxId}` : '',
    ...(i.extraIds || []),
    ...i.addressLines,
    i.email || '',
    i.phone || '',
  ];
}

export async function renderInvoicePdf(inv: InvoicePdfInput): Promise<Buffer> {
  const t = L[inv.jurisdiction];
  const doc: any = new PDFDocument({ size: 'A4', margin: 50, info: { Title: `${inv.number}`, Author: inv.issuer.legalName } });
  const finish = collect(doc);
  const money = (m: number) => pdfSafe(formatMoney(m, inv.currency, inv.jurisdiction === 'BR' ? 'pt-BR' : 'en-US'));

  if (inv.isTest) watermark(doc, 'TEST');
  if (inv.status === 'void') watermark(doc, t.voidMark);
  header(doc, inv.type === 'credit_note' ? t.credit : t.invoice, inv.issuer);

  if (inv.isTest) {
    doc.rect(50, 88, 495, 18).fill('#FDECEA');
    doc.fillColor('#B71C1C').font('Helvetica-Bold').fontSize(9).text(pdfSafe(t.test), 50, 93, { width: 495, align: 'center' });
  }

  const metaY = 116;
  doc.fillColor(MUTED).font('Helvetica').fontSize(9);
  doc.text(`${t.number}:`, 350, metaY, { width: 80 });
  doc.text(`${t.date}:`, 350, metaY + 14, { width: 80 });
  doc.fillColor(DARK).font('Helvetica-Bold');
  doc.text(pdfSafe(inv.number), 430, metaY, { width: 115, align: 'right' });
  doc.text(fmtDate(inv.issuedAt, inv.jurisdiction), 430, metaY + 14, { width: 115, align: 'right' });
  let metaEnd = metaY + 28;
  if (inv.relatedNumber) {
    doc.fillColor(MUTED).font('Helvetica').text(`${t.related}:`, 350, metaEnd, { width: 80 });
    doc.fillColor(DARK).font('Helvetica-Bold').text(pdfSafe(inv.relatedNumber), 430, metaEnd, { width: 115, align: 'right' });
    metaEnd += 14;
  }
  if (inv.reference) {
    doc.fillColor(MUTED).font('Helvetica').text(`${t.ref}:`, 350, metaEnd, { width: 80 });
    doc.fillColor(DARK).font('Helvetica-Bold').fontSize(7.5).text(pdfSafe(inv.reference), 410, metaEnd + 1, { width: 135, align: 'right' });
    metaEnd += 14;
  }

  const issuerEnd = partyBlock(doc, 50, metaY, t.issuer, issuerLines(inv.issuer));
  const c = inv.customer;
  const custEnd = partyBlock(doc, 50, Math.max(issuerEnd, metaEnd) + 14, t.billTo, [
    c.name, c.taxId ? `${inv.jurisdiction === 'BR' ? 'CPF/CNPJ' : 'Tax ID'}: ${c.taxId}` : '', c.address || '', c.email || '',
  ]);

  // Lines table (one line per event / experience on monthly fee invoices; breaks across pages)
  let y = custEnd + 20;
  const cols = { desc: 50, qty: 330, unit: 380, amount: 465 };
  const tableHead = () => {
    doc.rect(50, y, 495, 20).fill('#F2F7F3');
    doc.fillColor(DARK).font('Helvetica-Bold').fontSize(9);
    doc.text(t.desc, cols.desc + 6, y + 6);
    doc.text(t.qty, cols.qty, y + 6, { width: 40, align: 'right' });
    doc.text(t.unit, cols.unit, y + 6, { width: 80, align: 'right' });
    doc.text(t.amount, cols.amount, y + 6, { width: 74, align: 'right' });
    y += 26;
    doc.font('Helvetica').fontSize(9.5);
  };
  const newPage = () => {
    doc.addPage();
    if (inv.isTest) watermark(doc, 'TEST');
    if (inv.status === 'void') watermark(doc, t.voidMark);
    doc.fillColor(MUTED).font('Helvetica').fontSize(8).text(pdfSafe(`${inv.number}`), 50, 30, { width: 495, align: 'right' });
    y = 50;
  };
  tableHead();
  for (const ln of inv.lines) {
    doc.font('Helvetica').fontSize(9.5);
    const h = doc.heightOfString(pdfSafe(ln.description), { width: 270 });
    if (y + h > 760) { newPage(); tableHead(); }
    doc.fillColor(DARK).text(pdfSafe(ln.description), cols.desc + 6, y, { width: 270 });
    doc.text(String(ln.quantity), cols.qty, y, { width: 40, align: 'right' });
    doc.text(money(ln.unitAmount), cols.unit, y, { width: 80, align: 'right' });
    doc.text(money(ln.amount), cols.amount, y, { width: 74, align: 'right' });
    y += Math.max(h, 12) + 8;
    doc.moveTo(50, y - 4).lineTo(545, y - 4).strokeColor(LINE).stroke();
  }

  // Totals
  y += 6;
  if (y > 640) newPage();
  if (inv.tax && inv.tax.amount !== 0) {
    doc.fillColor(MUTED).font('Helvetica').fontSize(9)
      .text(pdfSafe(`${inv.tax.label} ${inv.tax.rate}% (${t.taxIncl})`), 330, y, { width: 130, align: 'right' })
      .text(money(inv.tax.amount), cols.amount, y, { width: 74, align: 'right' });
    y += 16;
  }
  doc.rect(330, y - 2, 215, 24).fill(GREEN);
  doc.fillColor('#FFFFFF').font('Helvetica-Bold').fontSize(11)
    .text(t.total, 338, y + 4, { width: 100 })
    .text(money(inv.total), cols.amount - 20, y + 4, { width: 94, align: 'right' });
  y += 40;

  // NFS-e block (Brazil)
  if (inv.jurisdiction === 'BR' && inv.nfse.status !== 'not_required') {
    if (y > 690) newPage();
    const n = inv.nfse;
    doc.rect(50, y, 495, 64).strokeColor(GREEN).lineWidth(1).stroke();
    doc.fillColor(GREEN).font('Helvetica-Bold').fontSize(10).text(t.nfse, 60, y + 8);
    doc.fillColor(DARK).font('Helvetica').fontSize(9);
    if (n.status === 'authorized') {
      doc.text(pdfSafe(`${t.nfseNo} ${n.number || ''}`), 60, y + 24);
      if (n.verificationCode) doc.text(pdfSafe(`${t.verif}: ${n.verificationCode}`), 60, y + 37);
      if (n.url) doc.fillColor('#1565C0').text(pdfSafe(n.url), 260, y + 24, { width: 275, link: n.url, underline: true });
    } else if (n.status === 'cancelled') {
      doc.text(pdfSafe(`${t.nfseCancelled}${n.number ? ` (nº ${n.number})` : ''}`), 60, y + 24);
    } else if (n.status === 'error' || n.status === 'needs_review') {
      doc.text(pdfSafe(t.nfseError), 60, y + 24);
    } else {
      doc.text(pdfSafe(t.nfsePending), 60, y + 24, { width: 470 });
    }
    if (n.environment === 'homologacao') {
      doc.fillColor('#B71C1C').fontSize(8).text(pdfSafe(t.nfseEnvTest), 60, y + 50);
    }
    y += 76;
  }

  if (inv.notes) {
    if (y > 730) newPage();
    doc.fillColor(MUTED).font('Helvetica').fontSize(8.5).text(pdfSafe(inv.notes), 50, y, { width: 495 });
  }
  if (inv.issuer.footerNote) {
    doc.fillColor(MUTED).fontSize(8).text(pdfSafe(inv.issuer.footerNote), 50, 770, { width: 495, align: 'center' });
  }
  return finish();
}

export async function renderStatementPdf(st: StatementPdfInput): Promise<Buffer> {
  const t = L[st.jurisdiction];
  const doc: any = new PDFDocument({ size: 'A4', margin: 50, info: { Title: st.number, Author: st.issuer.legalName } });
  const finish = collect(doc);
  if (st.isTest) watermark(doc, 'TEST');
  header(doc, t.statement, st.issuer);

  const y0 = 100;
  const period = `${st.month.slice(4)}/${st.month.slice(0, 4)}`;
  doc.fillColor(MUTED).font('Helvetica').fontSize(9)
    .text(`${t.number}:`, 350, y0, { width: 80 }).text(`${t.period}:`, 350, y0 + 14, { width: 80 })
    .text(`${t.date}:`, 350, y0 + 28, { width: 80 });
  doc.fillColor(DARK).font('Helvetica-Bold')
    .text(pdfSafe(st.number), 420, y0, { width: 125, align: 'right' })
    .text(period, 420, y0 + 14, { width: 125, align: 'right' })
    .text(fmtDate(st.issuedAt, st.jurisdiction), 420, y0 + 28, { width: 125, align: 'right' });
  const bEnd = partyBlock(doc, 50, y0, t.business, [
    st.business.businessName || st.business.name, st.business.businessName ? st.business.name : '', st.business.email || '',
  ]);

  let y = Math.max(bEnd, y0 + 50) + 24;
  if (!st.lines.length) {
    doc.fillColor(DARK).font('Helvetica').fontSize(10).text(pdfSafe(t.empty), 50, y);
    y += 30;
  }
  for (const ln of st.lines) {
    const money = (m: number) => pdfSafe(formatMoney(m, ln.currency, st.jurisdiction === 'BR' ? 'pt-BR' : 'en-US'));
    doc.rect(50, y, 495, 20).fill('#F2F7F3');
    doc.fillColor(DARK).font('Helvetica-Bold').fontSize(10).text(`${t.currency}: ${ln.currency.toUpperCase()}`, 58, y + 5);
    y += 28;
    if (y > 650) { doc.addPage(); if (st.isTest) watermark(doc, 'TEST'); y = 50; }
    const minus = (v: number) => (v ? `- ${money(v)}` : money(0));
    const rows: Array<[string, string, boolean?]> = [
      [`${t.orders} / ${t.tickets}`, `${ln.orders} / ${ln.tickets}`],
      [t.gross, money(ln.sales)],
      [t.refunds, minus(ln.refundedTotal)],
      [t.fees, minus(ln.feesNet)],
      [t.net, money(ln.net), true],
    ];
    for (const [k, v, bold] of rows) {
      doc.fillColor(bold ? DARK : MUTED).font(bold ? 'Helvetica-Bold' : 'Helvetica').fontSize(9.5)
        .text(pdfSafe(k), 58, y, { width: 300 }).fillColor(DARK).text(v, 380, y, { width: 160, align: 'right' });
      y += 16;
    }
    y += 6;

    // Every event / experience that earned money in this currency.
    const own = (st.listings || []).filter((l) => l.currency === ln.currency);
    if (own.length) {
      const head = () => {
        doc.fillColor(MUTED).font('Helvetica-Bold').fontSize(8)
          .text(pdfSafe(t.listing).toUpperCase(), 58, y, { width: 250 })
          .text(pdfSafe(`${t.orders} / ${t.tickets}`).toUpperCase(), 300, y, { width: 80, align: 'right' })
          .text(pdfSafe(t.sales).toUpperCase(), 385, y, { width: 75, align: 'right' })
          .text(pdfSafe(t.fee).toUpperCase(), 465, y, { width: 75, align: 'right' });
        y += 13;
      };
      doc.fillColor(DARK).font('Helvetica-Bold').fontSize(9.5).text(pdfSafe(t.byListing), 58, y);
      y += 15;
      head();
      for (const l of own) {
        const label = `${l.kind === 'experience' ? (st.jurisdiction === 'BR' ? 'Experiência' : 'Experience') : (st.jurisdiction === 'BR' ? 'Evento' : 'Event')}: ${l.title}`;
        doc.font('Helvetica').fontSize(9);
        const h = doc.heightOfString(pdfSafe(label), { width: 235 });
        if (y + h > 770) { doc.addPage(); if (st.isTest) watermark(doc, 'TEST'); y = 50; head(); }
        doc.fillColor(DARK).font('Helvetica').fontSize(9)
          .text(pdfSafe(label), 58, y, { width: 235 })
          .text(`${l.orders} / ${l.tickets}`, 300, y, { width: 80, align: 'right' })
          .text(money(l.sales), 385, y, { width: 75, align: 'right' })
          .text(money(l.feesNet), 465, y, { width: 75, align: 'right' });
        y += Math.max(h, 11) + 5;
        doc.moveTo(58, y - 3).lineTo(540, y - 3).strokeColor(LINE).lineWidth(0.5).stroke();
      }
    }
    y += 14;
  }
  if (y > 720) { doc.addPage(); if (st.isTest) watermark(doc, 'TEST'); y = 50; }
  doc.fillColor(MUTED).font('Helvetica').fontSize(8.5).text(pdfSafe(t.stmtNote), 50, y + 6, { width: 495 });
  return finish();
}
