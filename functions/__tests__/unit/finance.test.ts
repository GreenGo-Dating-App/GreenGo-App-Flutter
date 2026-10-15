/**
 * Finance (pure): settings validation, numbering, fee invoice from an order,
 * included tax, credit notes, NFS-e initial state + Focus NFe payload/parsing,
 * provider HTTP flow (fake fetch), statements and PDF rendering.
 */
import {
  DEFAULT_SETTINGS, InvoicingSettings, SettingsError, creditNoteFor, feeInvoiceFromOrder, formatNumber,
  includedTax, initialNfse, isValidCnpj, isValidCpf, monthRange, normalizeSettings, nfseReadiness,
  listingKey, monthlyFeeDraft, monthlyFeeInvoiceId, orderAmounts, orderTransition, pdfSafe, previousMonthKey,
  seriesFor, statementLines, statementListingLines, toBrlMinor,
} from '../../src/finance/model';
import { brDateTime, focusPayload, nfseDeps, nfseRef, parseFocus, providerFor, tomadorProblem } from '../../src/finance/nfse';
import { renderInvoicePdf, renderStatementPdf } from '../../src/finance/pdf';

const party = { uid: 'u1', name: 'Ana Souza', email: 'ana@example.com', taxId: null, address: null };
const order = {
  kind: 'event', listingId: 'ev1', buyerId: 'u1', organizerId: 'org1', quantity: 2, unitAmount: 5000,
  ticketSubtotal: 10000, feeTotal: 2000, feePerTicket: 1000, totalAmount: 12000, currency: 'brl',
  status: 'paid', title: 'Samba night',
};
const brReady = (): InvoicingSettings => normalizeSettings({
  br: { inscricaoMunicipal: '1234567', codigoMunicipio: '3550308', itemListaServico: '01.03', aliquotaIss: 2 },
});

describe('finance model — settings', () => {
  it('validates CNPJ / CPF check digits', () => {
    expect(isValidCnpj('40.486.663/0001-82')).toBe(true);
    expect(isValidCnpj('40.486.663/0001-83')).toBe(false);
    expect(isValidCnpj('11111111111111')).toBe(false);
    expect(isValidCpf('529.982.247-25')).toBe(true);
    expect(isValidCpf('529.982.247-24')).toBe(false);
  });

  it('defaults to BR, Universo Kardasha, mock NFS-e in homologação', () => {
    const st = normalizeSettings({});
    expect(st.jurisdiction).toBe('BR');
    expect(st.br.cnpj).toBe('40.486.663/0001-82');
    expect(st.nfse).toMatchObject({ provider: 'mock', environment: 'homologacao' });
    expect(st.sellerFeeInvoicing).toBe('monthly');
    expect(normalizeSettings({ sellerFeeInvoicing: 'per_order' }).sellerFeeInvoicing).toBe('per_order');
    expect(normalizeSettings({ sellerFeeInvoicing: 'weird' }).sellerFeeInvoicing).toBe('monthly');
  });

  it('switches to US and keeps BR settings', () => {
    const st = normalizeSettings({ jurisdiction: 'US', us: { salesTaxRate: 8.25, state: 'tx' } });
    expect(st.jurisdiction).toBe('US');
    expect(st.us.state).toBe('TX');
    expect(st.us.salesTaxRate).toBe(8.25);
    expect(st.br.legalName).toBe('Universo Kardasha Ltda.');
  });

  it('rejects bad input', () => {
    expect(() => normalizeSettings({ jurisdiction: 'EU' })).toThrow(SettingsError);
    expect(() => normalizeSettings({ br: { cnpj: '12.345.678/0001-00' } })).toThrow(/CNPJ/);
    expect(() => normalizeSettings({ br: { codigoMunicipio: '123' } })).toThrow(/IBGE/);
    expect(() => normalizeSettings({ nfse: { provider: 'mock', environment: 'producao' } })).toThrow(/mock/);
    expect(() => normalizeSettings({ numbering: { prefix: 'GG', creditPrefix: 'GG' } })).toThrow(/differ/);
    expect(() => normalizeSettings({ us: { salesTaxRate: 50 } })).toThrow(/percent/);
  });

  it('lists what blocks production NFS-e', () => {
    expect(nfseReadiness(normalizeSettings({}))).toEqual(
      expect.arrayContaining(['br.inscricaoMunicipal', 'br.codigoMunicipio', 'br.itemListaServico']));
    expect(nfseReadiness(brReady())).toEqual([]);
  });
});

describe('finance model — numbering', () => {
  it('formats and separates series', () => {
    const st = DEFAULT_SETTINGS;
    expect(formatNumber('GG', 2026, 123, 6)).toBe('GG-2026-000123');
    expect(seriesFor(st, 'invoice', false)).toBe('GG');
    expect(seriesFor(st, 'credit_note', false)).toBe('GGCN');
    expect(seriesFor(st, 'invoice', true)).toBe('TEST');
    expect(seriesFor(st, 'credit_note', true)).toBe('TESTCN');
  });
});

describe('finance model — fee invoice', () => {
  it('invoices only the GreenGo fee, per ticket, BR wording + ISS included', () => {
    const d = feeInvoiceFromOrder(brReady(), 'o1', order, party, false)!;
    expect(d.total).toBe(2000);
    expect(d.lines).toEqual([expect.objectContaining({ quantity: 2, unitAmount: 1000, amount: 2000 })]);
    expect(d.lines[0].description).toContain('evento');
    expect(d.lines[0].description).toContain('Samba night');
    expect(d.tax).toEqual({ label: 'ISS', rate: 2, amount: 40, included: true });
    expect(d.source).toMatchObject({ kind: 'ticket_fee', orderId: 'o1', organizerId: 'org1' });
  });

  it('US: English wording, sales tax included in the fee', () => {
    const st = normalizeSettings({ jurisdiction: 'US', us: { salesTaxRate: 10 } });
    const d = feeInvoiceFromOrder(st, 'o1', { ...order, currency: 'usd' }, party, false)!;
    expect(d.lines[0].description).toMatch(/^GreenGo service fee on ticket sales — event/);
    expect(d.notes).toMatch(/payable by the organizer/);
    expect(d.tax!.amount).toBe(includedTax(2000, 10));
    expect(includedTax(1100, 10)).toBe(100);
  });

  it('single line when per-ticket fees differ; null without a fee', () => {
    const d = feeInvoiceFromOrder(brReady(), 'o1', { ...order, feePerTicket: null }, party, false)!;
    expect(d.lines[0]).toMatchObject({ quantity: 1, amount: 2000 });
    expect(feeInvoiceFromOrder(brReady(), 'o1', { ...order, feeTotal: 0 }, party, false)).toBeNull();
    expect(feeInvoiceFromOrder(brReady(), 'o1', { ...order, currency: '' }, party, false)).toBeNull();
  });

  it('credit note mirrors the invoice with negative amounts', () => {
    const d = feeInvoiceFromOrder(brReady(), 'o1', order, party, false)!;
    const cn = creditNoteFor({ ...d, id: 'fee_o1', number: 'GG-2026-000001' }, 'refund');
    expect(cn.type).toBe('credit_note');
    expect(cn.total).toBe(-2000);
    expect(cn.lines[0].amount).toBe(-2000);
    expect(cn.relatedInvoiceId).toBe('fee_o1');
    expect(cn.notes).toContain('GG-2026-000001');
  });
});

describe('finance model — NFS-e state', () => {
  it('BR production invoice -> pending with BRL value', () => {
    const st = normalizeSettings({ ...brReady(), nfse: { provider: 'focusnfe', environment: 'producao' } });
    const n = initialNfse(st, feeInvoiceFromOrder(st, 'o1', order, party, false)!);
    expect(n).toMatchObject({ status: 'pending', provider: 'focusnfe', environment: 'producao', valueBrl: 2000 });
  });

  it('TEST invoices never reach production', () => {
    const st = normalizeSettings({ ...brReady(), nfse: { provider: 'focusnfe', environment: 'producao' } });
    const n = initialNfse(st, feeInvoiceFromOrder(st, 'o1', order, party, true)!);
    expect(n.environment).toBe('homologacao');
  });

  it('US and credit notes need no NFS-e; non-BRL needs a rate', () => {
    const us = normalizeSettings({ jurisdiction: 'US' });
    expect(initialNfse(us, feeInvoiceFromOrder(us, 'o1', order, party, false)!).status).toBe('not_required');
    const br = brReady();
    const d = feeInvoiceFromOrder(br, 'o1', { ...order, currency: 'usd' }, party, false)!;
    expect(initialNfse(br, d)).toMatchObject({ status: 'needs_review', error: 'currency_not_brl:usd' });
    const withFx = normalizeSettings({ ...br, br: { ...br.br, fxToBrl: { USD: 5.5 } } });
    expect(initialNfse(withFx, d)).toMatchObject({ status: 'pending', valueBrl: 11000 });
    expect(toBrlMinor(1000, 'jpy', { jpy: 0.036 })).toBe(3600);
  });
});

describe('Focus NFe', () => {
  const st = brReady();
  const req = {
    ref: nfseRef('fee_o1'), issuedAt: new Date('2026-10-14T15:00:00Z'), issuer: st.br, settings: st.nfse,
    customer: { ...party, taxId: '529.982.247-25' }, description: 'Taxa de serviço', valueBrl: 2000,
  };

  it('builds the municipal payload', () => {
    const p: any = focusPayload(req);
    expect(p.data_emissao).toBe('2026-10-14T12:00:00-03:00');
    expect(brDateTime(new Date('2026-01-01T02:00:00Z'))).toBe('2025-12-31T23:00:00-03:00');
    expect(p.prestador).toEqual({ cnpj: '40486663000182', inscricao_municipal: '1234567', codigo_municipio: '3550308' });
    expect(p.tomador).toEqual({ razao_social: 'Ana Souza', cpf: '52998224725', email: 'ana@example.com' });
    expect(p.servico).toMatchObject({ aliquota: 2, valor_servicos: 20, item_lista_servico: '01.03', iss_retido: false });
  });

  it('tomador without document only when allowed', () => {
    expect(tomadorProblem(party, { ...st.nfse, allowUnidentifiedTomador: true })).toBeNull();
    expect(tomadorProblem(party, { ...st.nfse, allowUnidentifiedTomador: false })).toBe('tomador_document_missing');
  });

  it('parses provider states', () => {
    expect(parseFocus({ status: 'processando_autorizacao' })).toEqual({ state: 'processing' });
    expect(parseFocus({ status: 'autorizado', numero: '77', codigo_verificacao: 'AB12', url: 'https://x' }))
      .toMatchObject({ state: 'authorized', number: '77', verificationCode: 'AB12', url: 'https://x' });
    expect(parseFocus({ status: 'erro_autorizacao', erros: [{ codigo: 'E1', mensagem: 'CNPJ inválido' }] }))
      .toMatchObject({ state: 'error', error: 'E1 CNPJ inválido' });
  });

  it('HTTP flow: submit -> status -> cancel, basic auth, sandbox host', async () => {
    const calls: any[] = [];
    const replies = [
      { status: 202, body: { status: 'processando_autorizacao' } },
      { status: 200, body: { status: 'autorizado', numero: '9', codigo_verificacao: 'X' } },
      { status: 200, body: { status: 'cancelado' } },
    ];
    const orig = nfseDeps.fetch;
    nfseDeps.fetch = async (url: string, init: any) => {
      calls.push({ url, init });
      const r = replies.shift()!;
      return { ok: r.status < 300, status: r.status, text: async () => JSON.stringify(r.body) };
    };
    try {
      const p = providerFor('focusnfe', 'homologacao', { focusnfeTokenHomologacao: 'tok' });
      expect(await p.submit(req)).toEqual({ state: 'processing' });
      expect(await p.status(req.ref)).toMatchObject({ state: 'authorized', number: '9' });
      expect(await p.cancel(req.ref, 'Pedido estornado pelo cliente')).toEqual({ state: 'cancelled' });
    } finally {
      nfseDeps.fetch = orig;
    }
    expect(calls[0].url).toBe('https://homologacao.focusnfe.com.br/v2/nfse?ref=fee_o1');
    expect(calls[0].init.method).toBe('POST');
    expect(calls[0].init.headers.Authorization).toBe(`Basic ${Buffer.from('tok:').toString('base64')}`);
    expect(calls[2].init.method).toBe('DELETE');
    expect(JSON.parse(calls[2].init.body).justificativa.length).toBeGreaterThanOrEqual(15);
  });

  it('provider errors: retryable 5xx, missing token, mock never in production', async () => {
    const orig = nfseDeps.fetch;
    nfseDeps.fetch = async () => ({ ok: false, status: 503, text: async () => '' });
    try {
      const r = await providerFor('focusnfe', 'producao', { focusnfeTokenProducao: 't' }).submit(req);
      expect(r).toMatchObject({ state: 'error', retryable: true });
    } finally {
      nfseDeps.fetch = orig;
    }
    expect(() => providerFor('focusnfe', 'producao', {})).toThrow(/token/);
    expect(() => providerFor('mock', 'producao', {})).toThrow(/mock/);
    const m = await providerFor('mock', 'homologacao', {}).submit(req);
    expect(m.state).toBe('authorized');
  });
});

describe('seller monthly fee invoice', () => {
  const byListing = {
    [listingKey('event', 'ev1', 'brl')]: { listingId: 'ev1', kind: 'event', currency: 'brl', title: 'Samba night', gross: 10000, fees: 2000, buyerTotal: 12000, orders: 1, tickets: 2 },
    [listingKey('experience', 'x1', 'brl')]: { listingId: 'x1', kind: 'experience', currency: 'brl', title: 'Favela tour', gross: 30000, fees: 3000, buyerTotal: 33000, orders: 3, tickets: 3, refunds: 10000, refundedFees: 1000, refundedOrders: 1 },
    [listingKey('event', 'ev2', 'usd')]: { listingId: 'ev2', kind: 'event', currency: 'usd', title: 'Jazz', gross: 5000, fees: 900, buyerTotal: 5900, orders: 1, tickets: 1 },
  };
  const byCurrency = {
    brl: { gross: 40000, fees: 5000, buyerTotal: 45000, orders: 4, tickets: 5, refunds: 10000, refundedFees: 1000, refundedOrders: 1 },
    usd: { gross: 5000, fees: 900, buyerTotal: 5900, orders: 1, tickets: 1 },
  };
  const seller = { uid: 'org1', name: 'Bar do Zé', email: 'ze@example.com', taxId: '40.486.663/0001-82', address: null };

  it('lists every event / experience that earned money, per currency', () => {
    const listings = statementListingLines(byListing);
    expect(listings.map((l) => l.title)).toEqual(['Favela tour', 'Samba night', 'Jazz']);
    const brl = statementLines(byCurrency).find((l) => l.currency === 'brl')!;
    expect(brl).toMatchObject({ sales: 45000, refundedTotal: 11000, feesNet: 4000, net: 30000 });
    const d = monthlyFeeDraft(brReady(), 'org1', '202610', brl, seller, false, listings)!;
    expect(d.type).toBe('invoice');
    expect(d.customer.name).toBe('Bar do Zé');
    expect(d.total).toBe(4000);
    expect(d.lines).toHaveLength(2);
    expect(d.lines.map((l) => l.amount)).toEqual([2000, 2000]);
    expect(d.lines[0].description.replace(/\s/g, ' ')).toBe('Experiência: Favela tour — 3 pedidos, 3 ingressos, vendas R$ 330,00, 1 estorno');
    expect(d.lines[1].description).toContain('Evento: Samba night — 1 pedido, 2 ingressos');
    expect(d.lines.reduce((a, l) => a + l.amount, 0)).toBe(d.total);
    expect(d.source).toMatchObject({ kind: 'monthly_fee', organizerId: 'org1', month: '202610' });
    expect(d.notes).toMatch(/devida pelo organizador/);
    expect(monthlyFeeInvoiceId('org1', '202610', 'brl', true)).toBe('testfee_org1_202610_brl');
  });

  it('remainder line when older orders had no per-listing totals; credit note when negative; null at zero', () => {
    const brl = statementLines(byCurrency).find((l) => l.currency === 'brl')!;
    const d = monthlyFeeDraft(brReady(), 'org1', '202610', brl, seller, false, [])!;
    expect(d.lines).toEqual([expect.objectContaining({ amount: 4000, description: 'Outras vendas de ingressos — 10/2026' })]);
    const neg = statementLines({ brl: { refunds: 10000, refundedFees: 1000, refundedOrders: 1 } })[0];
    const cn = monthlyFeeDraft(brReady(), 'org1', '202611', neg, seller, false, [])!;
    expect(cn.type).toBe('credit_note');
    expect(cn.total).toBe(-1000);
    const zero = statementLines({ brl: { orders: 1, refundedOrders: 1, fees: 500, refundedFees: 500 } })[0];
    expect(monthlyFeeDraft(brReady(), 'org1', '202611', zero, seller, false, [])).toBeNull();
  });
});

describe('stats + statements', () => {
  it('detects money transitions', () => {
    expect(orderTransition({ status: 'pending' }, { status: 'paid' })).toBe('paid');
    expect(orderTransition(undefined, { status: 'paid' })).toBe('paid');
    expect(orderTransition({ status: 'paid' }, { status: 'paid' })).toBeNull();
    expect(orderTransition({ status: 'paid' }, { status: 'refunded' })).toBe('reversed');
    expect(orderTransition({ status: 'paid' }, { status: 'disputed' })).toBe('reversed');
    expect(orderTransition({ status: 'pending' }, { status: 'expired' })).toBeNull();
  });

  it('order amounts', () => {
    expect(orderAmounts(order)).toEqual({ currency: 'brl', gross: 10000, fees: 2000, buyerTotal: 12000, tickets: 2 });
    expect(orderAmounts({ ...order, ticketSubtotal: undefined })!.gross).toBe(10000);
    expect(orderAmounts({ currency: 'x' })).toBeNull();
  });

  it('statement lines + month helpers', () => {
    const lines = statementLines({ usd: { gross: 5000, refunds: 1000, orders: 2, tickets: 3, fees: 800 }, brl: { orders: 0 } });
    expect(lines).toEqual([expect.objectContaining({ currency: 'usd', net: 4000 })]);
    expect(previousMonthKey(new Date('2026-01-15T00:00:00Z'))).toBe('202512');
    expect(monthRange('202602').end.toISOString()).toBe('2026-03-01T00:00:00.000Z');
    expect(() => monthRange('202613')).toThrow();
  });
});

describe('PDF', () => {
  const isPdf = (b: Buffer) => b.subarray(0, 5).toString() === '%PDF-' && b.length > 1500;
  const base = {
    type: 'invoice' as const, number: 'GG-2026-000001', jurisdiction: 'BR' as const, isTest: false, status: 'issued' as const,
    issuedAt: new Date('2026-10-14T12:00:00Z'),
    issuer: { legalName: 'Universo Kardasha Ltda.', tradeName: 'GreenGo', taxIdLabel: 'CNPJ', taxId: '40.486.663/0001-82', addressLines: ['São Paulo - SP'] },
    customer: party, lines: [{ description: 'Taxa de serviço — evento: Samba night', quantity: 2, unitAmount: 1000, amount: 2000 }],
    currency: 'brl', total: 2000, tax: { label: 'ISS', rate: 2, amount: 40, included: true as const }, relatedNumber: null,
    notes: 'nota', reference: '#o1',
    nfse: { status: 'authorized' as const, provider: 'mock' as const, environment: 'homologacao' as const, ref: 'fee_o1', number: '77',
      verificationCode: 'AB12', url: 'https://nfse.example/77', xmlUrl: null, error: null, attempts: 1, valueBrl: 2000 },
  };

  it('renders BR, US, TEST, void and credit-note invoices', async () => {
    expect(isPdf(await renderInvoicePdf(base))).toBe(true);
    expect(isPdf(await renderInvoicePdf({ ...base, jurisdiction: 'US', currency: 'usd', tax: null,
      nfse: { ...base.nfse, status: 'not_required' } }))).toBe(true);
    expect(isPdf(await renderInvoicePdf({ ...base, isTest: true, nfse: { ...base.nfse, status: 'processing' } }))).toBe(true);
    expect(isPdf(await renderInvoicePdf({ ...base, status: 'void', nfse: { ...base.nfse, status: 'cancelled' } }))).toBe(true);
    expect(isPdf(await renderInvoicePdf({ ...base, type: 'credit_note', total: -2000, relatedNumber: 'GG-2026-000001',
      lines: [{ ...base.lines[0], unitAmount: -1000, amount: -2000 }] }))).toBe(true);
  });

  it('renders a statement (with and without sales)', async () => {
    const st = {
      number: 'ST-202610-ORG1', month: '202610', isTest: false, issuedAt: new Date(), issuer: base.issuer,
      business: { ...party, businessName: 'Bar do Zé' }, jurisdiction: 'BR' as const,
      lines: statementLines({ brl: { gross: 10000, fees: 2000, orders: 1, tickets: 2 } }),
      listings: statementListingLines({ a: { listingId: 'ev1', kind: 'event', currency: 'brl', title: 'Samba', gross: 10000, fees: 2000, orders: 1, tickets: 2 } }),
    };
    expect(isPdf(await renderStatementPdf(st))).toBe(true);
    // 120 listings: breaks across pages without throwing.
    const many: Record<string, any> = {};
    for (let i = 0; i < 120; i++) many[`k${i}`] = { listingId: `e${i}`, kind: 'event', currency: 'brl', title: `Event number ${i} with a long title`, gross: 1000, fees: 100, orders: 1, tickets: 1 };
    expect(isPdf(await renderStatementPdf({ ...st, listings: statementListingLines(many) }))).toBe(true);
    const lines = statementListingLines(many).map((l) => ({ description: l.title, quantity: 1, unitAmount: 100, amount: 100 }));
    expect(isPdf(await renderInvoicePdf({ ...base, lines, total: 12000 }))).toBe(true);
    expect(isPdf(await renderStatementPdf({ ...st, lines: [], jurisdiction: 'US' }))).toBe(true);
  });

  it('pdfSafe keeps Latin-1 and replaces the rest', () => {
    expect(pdfSafe('São — “ok” 東京')).toBe('São - "ok" ??');
  });
});
