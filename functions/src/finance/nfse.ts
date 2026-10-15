/**
 * NFS-e providers (Brazil). One small interface so the issuer can be swapped:
 *
 *   'focusnfe'  Focus NFe REST API v2, municipal NFS-e (/v2/nfse):
 *                 POST   {base}/v2/nfse?ref=REF   -> 202 processando_autorizacao
 *                 GET    {base}/v2/nfse/REF       -> autorizado | erro_autorizacao | …
 *                 DELETE {base}/v2/nfse/REF       -> cancelado | erro_cancelamento
 *               base = https://homologacao.focusnfe.com.br (sandbox) or
 *               https://api.focusnfe.com.br (production); HTTP Basic, token as
 *               user, empty password. Tokens live in server_secrets/invoicing
 *               (written by the adminFinance callable, never returned).
 *   'mock'      no network. Authorizes immediately with a deterministic fake
 *               number. Test invoices and setups without a contract use it; it
 *               is refused in production by settings validation.
 *
 * Authorization is asynchronous: submit() returns 'processing'; the
 * pollNfseStatus scheduler (and the admin "refresh" action) call status().
 *
 * NOTE (accountant check): municipalities that moved to the national NFS-e
 * standard (Emissor Nacional) use Focus' /v2/nfsen endpoint and a different
 * payload. Add a 'focusnfe_nacional' provider here if the issuer's city is on
 * the national standard; the rest of the module does not change.
 */
import * as crypto from 'crypto';
import { BrIssuer, NfseEnvironment, NfseProviderId, NfseSettings, Party, isValidCnpj, isValidCpf } from './model';

export interface NfseRequest {
  ref: string;
  issuedAt: Date;
  issuer: BrIssuer;
  settings: NfseSettings;
  customer: Party;
  description: string;
  /** BRL centavos */
  valueBrl: number;
}

export type NfseResult =
  | { state: 'processing' }
  | { state: 'authorized'; number: string; verificationCode: string | null; url: string | null; xmlUrl: string | null }
  | { state: 'error'; error: string; retryable: boolean }
  | { state: 'cancelled' };

export interface NfseProvider {
  submit(req: NfseRequest): Promise<NfseResult>;
  status(ref: string): Promise<NfseResult>;
  cancel(ref: string, reason: string): Promise<NfseResult>;
}

export interface NfseTokens {
  focusnfeTokenProducao?: string;
  focusnfeTokenHomologacao?: string;
}

/** Overridable in tests. */
export const nfseDeps = {
  fetch: (url: string, init: any): Promise<{ ok: boolean; status: number; text(): Promise<string> }> =>
    (globalThis as any).fetch(url, init),
};

/** Focus `ref`: letters, digits, '-' and '_' only. */
export function nfseRef(invoiceId: string): string {
  return invoiceId.replace(/[^A-Za-z0-9_-]/g, '_').slice(0, 60);
}

const onlyDigits = (v: string | null | undefined): string => String(v || '').replace(/\D/g, '');

/** ISO date with the Brasília offset (-03:00), as Focus expects. */
export function brDateTime(d: Date): string {
  const t = new Date(d.getTime() - 3 * 3600_000);
  return `${t.toISOString().slice(0, 19)}-03:00`;
}

/** The Focus NFe municipal payload (pure; unit-tested). */
export function focusPayload(req: NfseRequest): Record<string, unknown> {
  const br = req.issuer;
  const tomador: Record<string, unknown> = {
    razao_social: (req.customer.name || 'Consumidor').slice(0, 115),
  };
  const doc = onlyDigits(req.customer.taxId);
  if (doc.length === 11 && isValidCpf(doc)) tomador.cpf = doc;
  else if (doc.length === 14 && isValidCnpj(doc)) tomador.cnpj = doc;
  if (req.customer.email) tomador.email = req.customer.email;

  const servico: Record<string, unknown> = {
    aliquota: br.aliquotaIss,
    discriminacao: req.description.slice(0, 2000),
    iss_retido: br.issRetido,
    item_lista_servico: br.itemListaServico,
    valor_servicos: Math.round(req.valueBrl) / 100,
  };
  if (br.codigoTributarioMunicipio) servico.codigo_tributario_municipio = br.codigoTributarioMunicipio;
  if (br.cnae) servico.codigo_cnae = onlyDigits(br.cnae);

  const body: Record<string, unknown> = {
    data_emissao: brDateTime(req.issuedAt),
    natureza_operacao: br.naturezaOperacao || '1',
    optante_simples_nacional: br.optanteSimplesNacional,
    prestador: {
      cnpj: onlyDigits(br.cnpj),
      inscricao_municipal: onlyDigits(br.inscricaoMunicipal) || br.inscricaoMunicipal,
      codigo_municipio: br.codigoMunicipio,
    },
    tomador,
    servico,
  };
  if (br.regimeEspecialTributacao) body.regime_especial_tributacao = br.regimeEspecialTributacao;
  return body;
}

/** Tomador must be identified unless the settings allow an unidentified one. */
export function tomadorProblem(customer: Party, settings: NfseSettings): string | null {
  const doc = onlyDigits(customer.taxId);
  const ok = (doc.length === 11 && isValidCpf(doc)) || (doc.length === 14 && isValidCnpj(doc));
  if (ok || settings.allowUnidentifiedTomador) return null;
  return 'tomador_document_missing';
}

/** Focus JSON -> NfseResult. */
export function parseFocus(json: any): NfseResult {
  const st = String(json?.status || '');
  if (st === 'autorizado') {
    return {
      state: 'authorized',
      number: String(json.numero ?? json.numero_nfse ?? ''),
      verificationCode: json.codigo_verificacao ? String(json.codigo_verificacao) : null,
      url: json.url ? String(json.url) : (json.url_danfse ? String(json.url_danfse) : null),
      xmlUrl: json.caminho_xml_nota_fiscal ? String(json.caminho_xml_nota_fiscal) : null,
    };
  }
  if (st === 'processando_autorizacao') return { state: 'processing' };
  if (st === 'cancelado') return { state: 'cancelled' };
  const errs = Array.isArray(json?.erros) ? json.erros.map((e: any) => `${e.codigo || ''} ${e.mensagem || ''}`.trim()) : [];
  const msg = errs.join('; ') || String(json?.mensagem || json?.codigo || st || 'unknown_error');
  return { state: 'error', error: msg.slice(0, 1000), retryable: false };
}

export function focusBase(env: NfseEnvironment): string {
  return env === 'producao' ? 'https://api.focusnfe.com.br' : 'https://homologacao.focusnfe.com.br';
}

class FocusNfeProvider implements NfseProvider {
  constructor(private env: NfseEnvironment, private token: string) {}

  private async call(method: string, path: string, body?: unknown): Promise<{ status: number; json: any }> {
    const auth = Buffer.from(`${this.token}:`).toString('base64');
    let res;
    try {
      res = await nfseDeps.fetch(`${focusBase(this.env)}${path}`, {
        method,
        headers: { 'Authorization': `Basic ${auth}`, 'Content-Type': 'application/json' },
        body: body === undefined ? undefined : JSON.stringify(body),
      });
    } catch (e) {
      return { status: 0, json: { mensagem: `network: ${(e as Error)?.message || e}` } };
    }
    const text = await res.text();
    let json: any = {};
    try { json = text ? JSON.parse(text) : {}; } catch { json = { mensagem: text.slice(0, 300) }; }
    return { status: res.status, json };
  }

  async submit(req: NfseRequest): Promise<NfseResult> {
    const r = await this.call('POST', `/v2/nfse?ref=${encodeURIComponent(req.ref)}`, focusPayload(req));
    if (r.status === 202 || r.status === 201 || r.status === 200) {
      const p = parseFocus(r.json);
      return p.state === 'error' && !r.json?.status ? { state: 'processing' } : p;
    }
    // Same ref sent before (retry after a timeout): ask for its state instead.
    if (r.status === 422 && /already|ja_processad|já|em_processamento|nfe_autorizada/i.test(JSON.stringify(r.json))) {
      return this.status(req.ref);
    }
    const retryable = r.status === 0 || r.status === 429 || r.status >= 500;
    const p = parseFocus(r.json);
    return { state: 'error', error: `HTTP ${r.status}: ${p.state === 'error' ? p.error : 'unexpected'}`, retryable };
  }

  async status(ref: string): Promise<NfseResult> {
    const r = await this.call('GET', `/v2/nfse/${encodeURIComponent(ref)}`);
    if (r.status === 0 || r.status === 429 || r.status >= 500) {
      return { state: 'error', error: `HTTP ${r.status}`, retryable: true };
    }
    if (r.status === 404) return { state: 'error', error: 'not_found', retryable: false };
    return parseFocus(r.json);
  }

  async cancel(ref: string, reason: string): Promise<NfseResult> {
    const justificativa = (reason || 'Cancelamento por estorno do pedido').padEnd(15, '.').slice(0, 255);
    const r = await this.call('DELETE', `/v2/nfse/${encodeURIComponent(ref)}`, { justificativa });
    if (r.status === 0 || r.status === 429 || r.status >= 500) {
      return { state: 'error', error: `HTTP ${r.status}`, retryable: true };
    }
    const st = String(r.json?.status || '');
    if (st === 'cancelado') return { state: 'cancelled' };
    const p = parseFocus(r.json);
    return p.state === 'error' ? p : { state: 'error', error: `cancel: ${st || r.status}`, retryable: false };
  }
}

class MockNfseProvider implements NfseProvider {
  async submit(req: NfseRequest): Promise<NfseResult> {
    return this.authorized(req.ref);
  }
  async status(ref: string): Promise<NfseResult> {
    return this.authorized(ref);
  }
  async cancel(): Promise<NfseResult> {
    return { state: 'cancelled' };
  }
  private authorized(ref: string): NfseResult {
    const h = crypto.createHash('sha256').update(ref).digest('hex');
    return {
      state: 'authorized',
      number: `SIM-${parseInt(h.slice(0, 8), 16) % 1_000_000}`,
      verificationCode: h.slice(8, 16).toUpperCase(),
      url: null,
      xmlUrl: null,
    };
  }
}

export class NfseConfigError extends Error {}

export function providerFor(id: NfseProviderId, env: NfseEnvironment, tokens: NfseTokens): NfseProvider {
  if (id === 'mock') {
    if (env === 'producao') throw new NfseConfigError('mock provider cannot issue production NFS-e');
    return new MockNfseProvider();
  }
  const token = env === 'producao' ? tokens.focusnfeTokenProducao : tokens.focusnfeTokenHomologacao;
  if (!token) throw new NfseConfigError(`missing Focus NFe ${env} token`);
  return new FocusNfeProvider(env, token);
}
