/**
 * Seller billing ("invoice details") — the fiscal customer data of GreenGo's
 * fee invoices / NFS-e (owner rule 2026-10-14: a business account must have a
 * fiscal code or VAT number and everything needed to invoice it, as a private
 * person or as a company).
 *
 * finance_billing_profiles/{uid}   SERVER-ONLY (rules default deny). The owner
 *   reads it MASKED through getMyBillingProfile and writes it through
 *   saveMyBillingProfile; admins read it in full (adminFinance.businessDetail).
 *   {
 *     type 'private' | 'company', country ISO-3166 alpha-2,
 *     legalName, tradeName?, contactPerson? (company),
 *     taxId (normalized), taxIdKind (cpf | cnpj | codice_fiscale | partita_iva |
 *       nif | nie | cif | nipc | steuer_id | spi | vat | ssn | itin | ein | other),
 *     inscricaoMunicipal?, inscricaoEstadual? (BR company),
 *     address { street, number, complement?, district?, city, region?, postalCode, country },
 *     email, phone?, updatedAt, updatedBy, source 'seller' | 'admin'
 *   }
 * Older admin-entered docs may only have { legalName, taxId, address: string, email }.
 *
 * Invoices snapshot the customer when issued, so an edit applies to FUTURE
 * invoices only. US private persons may leave the SSN/ITIN empty (an invoice
 * from a Brazilian issuer does not need it, and it is sensitive).
 */
import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { Party, isValidCnpj, isValidCpf } from './model';

export const BILLING = 'finance_billing_profiles';
const db = () => admin.firestore();

export type BillingType = 'private' | 'company';
export type TaxIdKind =
  | 'cpf' | 'cnpj' | 'codice_fiscale' | 'partita_iva' | 'nif' | 'nie' | 'cif' | 'nipc' | 'steuer_id' | 'spi'
  | 'vat' | 'ssn' | 'itin' | 'ein' | 'other';

export interface BillingAddress {
  street: string; number: string; complement: string; district: string;
  city: string; region: string; postalCode: string; country: string;
}

export interface BillingProfile {
  type: BillingType;
  country: string;
  legalName: string;
  tradeName: string;
  contactPerson: string;
  taxId: string;
  taxIdKind: TaxIdKind | null;
  inscricaoMunicipal: string;
  inscricaoEstadual: string;
  address: BillingAddress;
  email: string;
  phone: string;
}

export class BillingError extends Error {
  constructor(public field: string, public code: 'required' | 'invalid' | 'tooLong', msg?: string) {
    super(msg || `${field}: ${code}`);
  }
}

// ─────────────────────────────────────────────── tax-id validators (pure)

const digits = (v: string) => v.replace(/\D/g, '');
const alnum = (v: string) => v.toUpperCase().replace(/[^A-Z0-9]/g, '');

/** Italian codice fiscale (16 chars, omocodia letters allowed), check character. */
export function isValidCodiceFiscale(v: string): boolean {
  const s = alnum(v);
  if (!/^[A-Z]{6}[0-9LMNPQRSTUV]{2}[ABCDEHLMPRST][0-9LMNPQRSTUV]{2}[A-Z][0-9LMNPQRSTUV]{3}[A-Z]$/.test(s)) return false;
  const odd: Record<string, number> = {
    0: 1, 1: 0, 2: 5, 3: 7, 4: 9, 5: 13, 6: 15, 7: 17, 8: 19, 9: 21, A: 1, B: 0, C: 5, D: 7, E: 9, F: 13, G: 15, H: 17,
    I: 19, J: 21, K: 2, L: 4, M: 18, N: 20, O: 11, P: 3, Q: 6, R: 8, S: 12, T: 14, U: 16, V: 10, W: 22, X: 25, Y: 24, Z: 23,
  };
  let sum = 0;
  for (let i = 0; i < 15; i++) {
    const c = s[i];
    sum += i % 2 === 0 ? odd[c] : (/[0-9]/.test(c) ? Number(c) : c.charCodeAt(0) - 65);
  }
  return String.fromCharCode(65 + (sum % 26)) === s[15];
}

/** Italian partita IVA (11 digits). */
export function isValidPartitaIva(v: string): boolean {
  const d = digits(v.replace(/^IT/i, ''));
  if (!/^\d{11}$/.test(d) || /^0{11}$/.test(d)) return false;
  // Digits 8-10: provincial office code (001-100, 120, 121, 888, 999).
  const office = Number(d.slice(7, 10));
  if (!((office >= 1 && office <= 100) || [120, 121, 888, 999].includes(office))) return false;
  let sum = 0;
  for (let i = 0; i < 10; i++) {
    let n = Number(d[i]);
    if (i % 2 === 1) { n *= 2; if (n > 9) n -= 9; }
    sum += n;
  }
  return (10 - (sum % 10)) % 10 === Number(d[10]);
}

/** Portuguese NIF / NIPC (9 digits, mod 11). */
export function isValidPtNif(v: string): boolean {
  const d = digits(v.replace(/^PT/i, ''));
  if (!/^[125689]\d{8}$/.test(d)) return false;
  let sum = 0;
  for (let i = 0; i < 8; i++) sum += Number(d[i]) * (9 - i);
  const r = sum % 11;
  return (r < 2 ? 0 : 11 - r) === Number(d[8]);
}

const DNI_LETTERS = 'TRWAGMYFPDXBNJZSQVHLCKE';
/** Spanish DNI/NIF (8 digits + letter) or NIE (X/Y/Z + 7 digits + letter). */
export function isValidEsNifNie(v: string): { ok: boolean; kind: 'nif' | 'nie' } {
  const s = alnum(v.replace(/^ES/i, ''));
  if (/^\d{8}[A-Z]$/.test(s)) return { ok: DNI_LETTERS[Number(s.slice(0, 8)) % 23] === s[8], kind: 'nif' };
  if (/^[XYZ]\d{7}[A-Z]$/.test(s)) {
    const n = Number(`${'XYZ'.indexOf(s[0])}${s.slice(1, 8)}`);
    return { ok: DNI_LETTERS[n % 23] === s[8], kind: 'nie' };
  }
  return { ok: false, kind: 'nif' };
}

/** Spanish CIF (company): letter + 7 digits + control digit or letter. */
export function isValidEsCif(v: string): boolean {
  const s = alnum(v.replace(/^ES/i, ''));
  if (!/^[ABCDEFGHJNPQRSUVW]\d{7}[0-9A-J]$/.test(s)) return false;
  let sum = 0;
  for (let i = 1; i <= 7; i++) {
    const n = Number(s[i]);
    if (i % 2 === 0) sum += n;
    else { const x = n * 2; sum += Math.floor(x / 10) + (x % 10); }
  }
  const c = (10 - (sum % 10)) % 10;
  return s[8] === String(c) || s[8] === 'JABCDEFGHI'[c];
}

/** German Steuer-ID (11 digits, ISO 7064 MOD 11,10). */
export function isValidSteuerId(v: string): boolean {
  const d = digits(v);
  if (!/^[1-9]\d{10}$/.test(d)) return false;
  let product = 10;
  for (let i = 0; i < 10; i++) {
    let sum = (Number(d[i]) + product) % 10;
    if (sum === 0) sum = 10;
    product = (sum * 2) % 11;
  }
  let check = 11 - product;
  if (check === 10) check = 0;
  return check === Number(d[10]);
}

/** French numéro fiscal de référence (SPI, 13 digits): last 3 = first 10 mod 511. */
export function isValidFrSpi(v: string): boolean {
  const d = digits(v);
  if (!/^[0-3]\d{12}$/.test(d)) return false;
  let r = 0;
  for (const c of d.slice(0, 10)) r = (r * 10 + Number(c)) % 511;
  return r === Number(d.slice(10));
}

function luhn(d: string): boolean {
  let sum = 0;
  for (let i = 0; i < d.length; i++) {
    let n = Number(d[d.length - 1 - i]);
    if (i % 2 === 1) { n *= 2; if (n > 9) n -= 9; }
    sum += n;
  }
  return sum % 10 === 0;
}

/** EU VAT numbers: country format (VIES patterns) + checksum where implemented. */
const VAT_FORMATS: Record<string, RegExp> = {
  AT: /^ATU\d{8}$/, BE: /^BE[01]\d{9}$/, BG: /^BG\d{9,10}$/, CY: /^CY\d{8}[A-Z]$/, CZ: /^CZ\d{8,10}$/,
  DE: /^DE\d{9}$/, DK: /^DK\d{8}$/, EE: /^EE\d{9}$/, EL: /^EL\d{9}$/, ES: /^ES[A-Z0-9]\d{7}[A-Z0-9]$/,
  FI: /^FI\d{8}$/, FR: /^FR[A-HJ-NP-Z0-9]{2}\d{9}$/, HR: /^HR\d{11}$/, HU: /^HU\d{8}$/,
  IE: /^IE\d{7}[A-W][A-I]?$|^IE\d[A-Z+*]\d{5}[A-W]$/, IT: /^IT\d{11}$/, LT: /^LT(\d{9}|\d{12})$/,
  LU: /^LU\d{8}$/, LV: /^LV\d{11}$/, MT: /^MT\d{8}$/, NL: /^NL\d{9}B\d{2}$/, PL: /^PL\d{10}$/,
  PT: /^PT\d{9}$/, RO: /^RO\d{2,10}$/, SE: /^SE\d{12}$/, SI: /^SI\d{8}$/, SK: /^SK\d{10}$/,
};
export const EU_COUNTRIES = new Set([...Object.keys(VAT_FORMATS).filter((c) => c !== 'EL'), 'GR']);

export function isValidEuVat(v: string, country: string): boolean {
  const cc = country === 'GR' ? 'EL' : country;
  let s = alnum(v);
  if (!s.startsWith(cc)) s = cc + s;
  const re = VAT_FORMATS[cc];
  if (!re || !re.test(s)) return false;
  const body = s.slice(2);
  if (cc === 'IT') return isValidPartitaIva(body);
  if (cc === 'PT') return isValidPtNif(body);
  if (cc === 'ES') return isValidEsCif(body) || isValidEsNifNie(body).ok;
  if (cc === 'FR') {
    const siren = body.slice(2);
    if (!luhn(siren)) return false;
    if (/^\d{2}$/.test(body.slice(0, 2))) return Number(body.slice(0, 2)) === (12 + 3 * (Number(siren) % 97)) % 97;
    return true; // new-style alphanumeric keys
  }
  return true;
}

/** US SSN (no 000/666/9xx area, 00 group, 0000 serial) or ITIN (9xx, group 50-65/70-88/90-92/94-99). */
export function usIndividualKind(v: string): 'ssn' | 'itin' | null {
  const d = digits(v);
  if (!/^\d{9}$/.test(d)) return null;
  const area = Number(d.slice(0, 3));
  const group = Number(d.slice(3, 5));
  const serial = Number(d.slice(5));
  if (d[0] === '9') {
    const ok = (group >= 50 && group <= 65) || (group >= 70 && group <= 88) || (group >= 90 && group <= 92) || group >= 94;
    return ok ? 'itin' : null;
  }
  if (area === 0 || area === 666 || group === 0 || serial === 0) return null;
  return 'ssn';
}

export function isValidEin(v: string): boolean {
  const d = digits(v);
  return /^\d{9}$/.test(d) && !d.startsWith('00');
}

/**
 * Validates [raw] for [country] / [type]. Returns the normalized id + kind, or
 * throws BillingError('taxId', 'invalid'). Countries without a known algorithm
 * accept 3-40 characters of letters, digits, spaces, '.', '-', '/'.
 */
export function validateTaxId(country: string, type: BillingType, raw: string): { taxId: string; kind: TaxIdKind } {
  const v = raw.trim();
  const bad = () => { throw new BillingError('taxId', 'invalid'); };
  switch (country) {
    case 'BR': {
      const d = digits(v);
      if (type === 'private') return isValidCpf(d) ? { taxId: d, kind: 'cpf' } : bad();
      return isValidCnpj(d) ? { taxId: d, kind: 'cnpj' } : bad();
    }
    case 'IT':
      if (type === 'private') return isValidCodiceFiscale(v) ? { taxId: alnum(v), kind: 'codice_fiscale' } : bad();
      return isValidPartitaIva(v) ? { taxId: `IT${digits(v.replace(/^IT/i, ''))}`, kind: 'partita_iva' } : bad();
    case 'PT':
      if (!isValidPtNif(v)) return bad();
      return { taxId: type === 'company' ? `PT${digits(v.replace(/^PT/i, ''))}` : digits(v.replace(/^PT/i, '')), kind: type === 'company' ? 'nipc' : 'nif' };
    case 'ES': {
      if (type === 'company') {
        const s = alnum(v.replace(/^ES/i, ''));
        return isValidEsCif(s) || isValidEsNifNie(s).ok ? { taxId: `ES${s}`, kind: 'cif' } : bad();
      }
      const r = isValidEsNifNie(v);
      return r.ok ? { taxId: alnum(v.replace(/^ES/i, '')), kind: r.kind } : bad();
    }
    case 'DE':
      if (type === 'private') return isValidSteuerId(v) ? { taxId: digits(v), kind: 'steuer_id' } : bad();
      return isValidEuVat(v, 'DE') ? { taxId: `DE${digits(v)}`, kind: 'vat' } : bad();
    case 'FR':
      if (type === 'private') return isValidFrSpi(v) ? { taxId: digits(v), kind: 'spi' } : bad();
      return isValidEuVat(v, 'FR') ? { taxId: (() => { const s = alnum(v); return s.startsWith('FR') ? s : `FR${s}`; })(), kind: 'vat' } : bad();
    case 'US': {
      if (type === 'company') return isValidEin(v) ? { taxId: digits(v), kind: 'ein' } : bad();
      const k = usIndividualKind(v);
      return k ? { taxId: digits(v), kind: k } : bad();
    }
    default: {
      if (type === 'company' && EU_COUNTRIES.has(country)) {
        if (!isValidEuVat(v, country)) return bad();
        const cc = country === 'GR' ? 'EL' : country;
        const s = alnum(v);
        return { taxId: s.startsWith(cc) ? s : cc + s, kind: 'vat' };
      }
      if (!/^[A-Za-z0-9 ./-]{3,40}$/.test(v)) return bad();
      return { taxId: v.toUpperCase(), kind: 'other' };
    }
  }
}

const POSTAL: Record<string, RegExp> = {
  BR: /^\d{5}-?\d{3}$/, US: /^\d{5}(-\d{4})?$/, IT: /^\d{5}$/, ES: /^\d{5}$/, DE: /^\d{5}$/, FR: /^\d{5}$/, PT: /^\d{4}-\d{3}$/,
};

/** US private persons may omit the SSN/ITIN (sensitive; not needed on a Brazilian issuer's invoice). */
export function taxIdOptional(country: string, type: BillingType): boolean {
  return country === 'US' && type === 'private';
}

const str = (v: unknown, field: string, max: number, required: boolean): string => {
  if (v === undefined || v === null || v === '') {
    if (required) throw new BillingError(field, 'required');
    return '';
  }
  if (typeof v !== 'string') throw new BillingError(field, 'invalid');
  const t = v.trim();
  if (!t && required) throw new BillingError(field, 'required');
  if (t.length > max) throw new BillingError(field, 'tooLong');
  return t;
};

/**
 * Input -> validated profile (throws BillingError with the offending field).
 * [keepTaxId]: the stored id, reused when the client sends no new one (the
 * client only ever sees it masked) and the country / type did not change.
 */
export function normalizeBilling(raw: any, keep?: { taxId: string; taxIdKind: TaxIdKind | null; country: string; type: BillingType } | null): BillingProfile {
  const type: BillingType = raw?.type === 'company' ? 'company' : raw?.type === 'private' ? 'private' : (() => { throw new BillingError('type', 'required'); })();
  const country = str(raw.country, 'country', 2, true).toUpperCase();
  if (!/^[A-Z]{2}$/.test(country)) throw new BillingError('country', 'invalid');
  const a = raw.address || {};
  const address: BillingAddress = {
    street: str(a.street, 'address.street', 150, true),
    number: str(a.number, 'address.number', 20, country === 'BR'),
    complement: str(a.complement, 'address.complement', 80, false),
    district: str(a.district, 'address.district', 80, country === 'BR'),
    city: str(a.city, 'address.city', 80, true),
    region: str(a.region, 'address.region', 80, ['BR', 'US'].includes(country)),
    postalCode: str(a.postalCode, 'address.postalCode', 12, true).toUpperCase(),
    country,
  };
  if (POSTAL[country] && !POSTAL[country].test(address.postalCode)) throw new BillingError('address.postalCode', 'invalid');
  if (country === 'BR' || country === 'US') {
    address.region = address.region.toUpperCase();
    if (!/^[A-Z]{2}$/.test(address.region)) throw new BillingError('address.region', 'invalid');
  }
  const email = str(raw.email, 'email', 254, true);
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw new BillingError('email', 'invalid');
  const phone = str(raw.phone, 'phone', 30, false);
  if (phone && !/^[+()0-9 .-]{6,30}$/.test(phone)) throw new BillingError('phone', 'invalid');

  const rawTax = str(raw.taxId, 'taxId', 40, false);
  let taxId = '';
  let taxIdKind: TaxIdKind | null = null;
  if (rawTax) {
    ({ taxId, kind: taxIdKind } = validateTaxId(country, type, rawTax));
  } else if (keep?.taxId && keep.country === country && keep.type === type) {
    taxId = keep.taxId;
    taxIdKind = keep.taxIdKind;
  } else if (!taxIdOptional(country, type)) {
    throw new BillingError('taxId', 'required');
  }
  return {
    type, country,
    legalName: str(raw.legalName, 'legalName', 150, true),
    tradeName: type === 'company' ? str(raw.tradeName, 'tradeName', 150, false) : '',
    contactPerson: type === 'company' ? str(raw.contactPerson, 'contactPerson', 120, true) : '',
    taxId, taxIdKind,
    inscricaoMunicipal: country === 'BR' && type === 'company' ? digits(str(raw.inscricaoMunicipal, 'inscricaoMunicipal', 20, false)) : '',
    inscricaoEstadual: country === 'BR' && type === 'company' ? str(raw.inscricaoEstadual, 'inscricaoEstadual', 20, false).toUpperCase() : '',
    address, email, phone,
  };
}

/** "•••••••8225" — only the last 4 characters. */
export function maskTaxId(v: string | null | undefined): string {
  const s = String(v || '');
  if (!s) return '';
  return s.length <= 4 ? '•'.repeat(s.length) : `${'•'.repeat(Math.min(8, s.length - 4))}${s.slice(-4)}`;
}

/** Fields still missing for invoicing (empty = complete). Works on old admin-only docs too. */
export function billingMissing(d: any): string[] {
  if (!d) return ['profile'];
  const missing: string[] = [];
  if (!d.legalName) missing.push('legalName');
  if (!d.email) missing.push('email');
  const structured = d.address && typeof d.address === 'object';
  if (!structured) missing.push('address');
  if (!d.type) missing.push('type');
  if (!d.taxId && !(d.country && d.type && taxIdOptional(d.country, d.type))) missing.push('taxId');
  return missing;
}

export function formatAddress(a: any): string | null {
  if (!a) return null;
  if (typeof a === 'string') return a || null;
  const line1 = [a.street, a.number].filter(Boolean).join(', ');
  const line2 = [a.complement, a.district].filter(Boolean).join(' - ');
  const line3 = [[a.postalCode, a.city].filter(Boolean).join(' '), a.region, a.country].filter(Boolean).join(', ');
  return [line1, line2, line3].filter(Boolean).join(' · ') || null;
}

const TAX_PREFIX: Partial<Record<TaxIdKind, string>> = {
  cpf: 'CPF', cnpj: 'CNPJ', codice_fiscale: 'C.F.', partita_iva: 'P.IVA', nif: 'NIF', nie: 'NIE', cif: 'CIF',
  nipc: 'NIPC', steuer_id: 'Steuer-ID', spi: 'N° fiscal', vat: 'VAT', ssn: 'SSN', itin: 'ITIN', ein: 'EIN',
};

/** Pretty tax id for documents ("CPF 529.982.247-25", "CNPJ 40.486.663/0001-82", "VAT DE123…"). */
export function displayTaxId(taxId: string, kind: TaxIdKind | null | undefined): string {
  if (!taxId) return '';
  let v = taxId;
  if (kind === 'cpf' && /^\d{11}$/.test(v)) v = `${v.slice(0, 3)}.${v.slice(3, 6)}.${v.slice(6, 9)}-${v.slice(9)}`;
  if (kind === 'cnpj' && /^\d{14}$/.test(v)) v = `${v.slice(0, 2)}.${v.slice(2, 5)}.${v.slice(5, 8)}/${v.slice(8, 12)}-${v.slice(12)}`;
  if (kind === 'ein' && /^\d{9}$/.test(v)) v = `${v.slice(0, 2)}-${v.slice(2)}`;
  const p = kind ? TAX_PREFIX[kind] : undefined;
  return p ? `${p} ${v}` : v;
}

/** Billing profile doc -> invoice customer fields (structured or legacy admin doc). */
export function billingToPartyFields(bp: any): Partial<Party> {
  if (!bp) return {};
  const s = (v: unknown) => (typeof v === 'string' && v.trim() ? v.trim() : null);
  const company = bp.type === 'company';
  const name = s(bp.legalName);
  return {
    name: name ? (company && s(bp.tradeName) && s(bp.tradeName) !== name ? `${name} (${s(bp.tradeName)})` : name) : undefined,
    taxId: s(bp.taxId) ? (bp.taxIdKind ? displayTaxId(bp.taxId, bp.taxIdKind) : s(bp.taxId)) : null,
    address: formatAddress(bp.address),
    email: s(bp.email),
  };
}

/** For a checkout gate (ticket_payments), if the owner wants one: true once invoicing data is complete. */
export async function billingProfileComplete(uid: string): Promise<boolean> {
  const d = (await db().collection(BILLING).doc(uid).get()).data();
  return billingMissing(d).length === 0;
}

function maskedView(d: any) {
  if (!d) return null;
  return {
    type: d.type || null, country: d.country || null, legalName: d.legalName || '', tradeName: d.tradeName || '',
    contactPerson: d.contactPerson || '', taxIdMasked: maskTaxId(d.taxId), taxIdKind: d.taxIdKind || null,
    hasTaxId: !!d.taxId, inscricaoMunicipal: d.inscricaoMunicipal || '', inscricaoEstadual: d.inscricaoEstadual || '',
    address: d.address && typeof d.address === 'object' ? d.address : null, email: d.email || '', phone: d.phone || '',
    updatedAt: d.updatedAt?.toDate?.().toISOString() || null,
  };
}

export async function saveBillingProfile(uid: string, raw: any, by: string, source: 'seller' | 'admin'): Promise<any> {
  const ref = db().collection(BILLING).doc(uid);
  const prev = (await ref.get()).data();
  const keep = prev?.taxId ? { taxId: prev.taxId, taxIdKind: prev.taxIdKind || null, country: prev.country, type: prev.type } : null;
  let profile: BillingProfile;
  try {
    profile = normalizeBilling(raw || {}, keep);
  } catch (e) {
    if (e instanceof BillingError) throw new HttpsError('invalid-argument', e.message, { field: e.field, code: e.code });
    throw e;
  }
  await ref.set({ ...profile, updatedAt: admin.firestore.Timestamp.now(), updatedBy: by, source });
  return profile;
}

// ─────────────────────────────────────────────── seller callables

export const getMyBillingProfile = onCall({ memory: '512MiB', timeoutSeconds: 30 }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first');
  const d = (await db().collection(BILLING).doc(uid).get()).data();
  return { profile: maskedView(d), missing: billingMissing(d), complete: billingMissing(d).length === 0 };
});

export const saveMyBillingProfile = onCall({ memory: '512MiB', timeoutSeconds: 30 }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first');
  await saveBillingProfile(uid, request.data || {}, uid, 'seller');
  const d = (await db().collection(BILLING).doc(uid).get()).data();
  return { profile: maskedView(d), missing: billingMissing(d), complete: billingMissing(d).length === 0 };
});
