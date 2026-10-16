/**
 * Trader declaration (Terms 12.4, EU Digital Services Act art. 30).
 *
 * Hosts / sellers of Experiences and event tickets say whether they act as a
 * TRADER (as part of their trade, business or profession). Traders give their
 * name, address, phone, email, an ID / registration number, the trade register
 * and number (if registered), and self-certify that they offer only products
 * and services that comply with the law.
 *
 *   trader_declarations/{uid}  SERVER-ONLY (like finance_billing_profiles):
 *     no client access; the owner reads it MASKED through
 *     getMyTraderDeclaration and writes it through saveMyTraderDeclaration;
 *     admins read it (rules: isAdmin / isAdminPanelUser).
 *     { isTrader, name, address {street, number, complement, district, city,
 *       region, postalCode, country}, phone, email, idNumber, idNumberSource
 *       'own' | 'billing', tradeRegister, tradeRegisterNumber, selfCertified,
 *       selfCertifiedAt, declaredAt, updatedAt, version }
 *
 *   trader_public/{uid}  what guests see (rules: signed-in get, no writes):
 *     { isTrader: true, name, address (one line), phone, email, tradeRegister,
 *       tradeRegisterNumber, updatedAt }  or  { isTrader: false, updatedAt }.
 *     The ID number is never public.
 *
 * Reuse of the invoice details (finance_billing_profiles): a business that
 * already filled them in can leave name / address / email / phone / ID number
 * empty and set useBillingProfile: the server copies them from the billing
 * profile (the tax id never travels to the client).
 */
import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { BILLING, BillingError, formatAddress, maskTaxId } from '../finance/billing';

export const TRADER = 'trader_declarations';
export const TRADER_PUBLIC = 'trader_public';
export const TRADER_DECLARATION_VERSION = 1;
const db = () => admin.firestore();

export interface TraderAddress {
  street: string; number: string; complement: string; district: string;
  city: string; region: string; postalCode: string; country: string;
}

export interface TraderDeclaration {
  isTrader: boolean;
  name: string;
  address: TraderAddress | null;
  phone: string;
  email: string;
  idNumber: string;
  idNumberSource: 'own' | 'billing' | null;
  tradeRegister: string;
  tradeRegisterNumber: string;
  selfCertified: boolean;
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

function normalizeAddress(a: any): TraderAddress {
  const country = str(a?.country, 'address.country', 2, true).toUpperCase();
  if (!/^[A-Z]{2}$/.test(country)) throw new BillingError('address.country', 'invalid');
  return {
    street: str(a?.street, 'address.street', 150, true),
    number: str(a?.number, 'address.number', 20, false),
    complement: str(a?.complement, 'address.complement', 80, false),
    district: str(a?.district, 'address.district', 80, false),
    city: str(a?.city, 'address.city', 80, true),
    region: str(a?.region, 'address.region', 80, false),
    postalCode: str(a?.postalCode, 'address.postalCode', 12, true).toUpperCase(),
    country,
  };
}

/**
 * Input -> validated declaration (throws BillingError with the field).
 * [billing]: the seller's finance_billing_profiles doc, used for every empty
 * field when raw.useBillingProfile is true (and for an empty ID number always).
 * [prev]: the stored declaration; an empty ID number keeps the saved one.
 */
export function normalizeTrader(
  raw: any,
  billing?: Record<string, any> | null,
  prev?: Record<string, any> | null,
): TraderDeclaration {
  if (typeof raw?.isTrader !== 'boolean') throw new BillingError('isTrader', 'required');
  if (!raw.isTrader) {
    return {
      isTrader: false, name: '', address: null, phone: '', email: '', idNumber: '', idNumberSource: null,
      tradeRegister: '', tradeRegisterNumber: '', selfCertified: false,
    };
  }
  const fromBilling = raw.useBillingProfile === true && !!billing;
  const pick = (v: unknown, b: unknown) => (typeof v === 'string' && v.trim() ? v : (fromBilling ? b : v));
  const billingAddress = billing?.address && typeof billing.address === 'object' ? billing.address : null;
  const rawAddress = raw.address && typeof raw.address === 'object' && Object.values(raw.address).some((x) => typeof x === 'string' && x.trim())
    ? raw.address
    : (fromBilling ? billingAddress : raw.address);

  const name = str(pick(raw.name, billing?.legalName), 'name', 150, true);
  const address = normalizeAddress(rawAddress || {});
  const email = str(pick(raw.email, billing?.email), 'email', 254, true);
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw new BillingError('email', 'invalid');
  const phone = str(pick(raw.phone, billing?.phone), 'phone', 30, true);
  if (!/^[+()0-9 .-]{6,30}$/.test(phone)) throw new BillingError('phone', 'invalid');

  let idNumber = str(raw.idNumber, 'idNumber', 40, false);
  let idNumberSource: 'own' | 'billing' = 'own';
  if (!idNumber && prev?.isTrader === true && typeof prev.idNumber === 'string' && prev.idNumber
      && (prev.idNumberSource !== 'billing' || prev.idNumber === billing?.taxId)) {
    // The client only ever sees it masked: an empty field keeps the saved one.
    idNumber = prev.idNumber;
    idNumberSource = prev.idNumberSource === 'billing' ? 'billing' : 'own';
  } else if (!idNumber) {
    const t = typeof billing?.taxId === 'string' ? billing.taxId.trim() : '';
    if (!t) throw new BillingError('idNumber', 'required');
    idNumber = t;
    idNumberSource = 'billing';
  } else if (!/^[A-Za-z0-9 ./-]{3,40}$/.test(idNumber)) {
    throw new BillingError('idNumber', 'invalid');
  }

  const tradeRegister = str(raw.tradeRegister, 'tradeRegister', 120, false);
  const tradeRegisterNumber = str(raw.tradeRegisterNumber, 'tradeRegisterNumber', 60, false);
  if (tradeRegisterNumber && !tradeRegister) throw new BillingError('tradeRegister', 'required');
  if (tradeRegister && !tradeRegisterNumber) throw new BillingError('tradeRegisterNumber', 'required');
  if (raw.selfCertified !== true) throw new BillingError('selfCertified', 'required');

  return {
    isTrader: true, name, address, phone, email, idNumber, idNumberSource,
    tradeRegister, tradeRegisterNumber, selfCertified: true,
  };
}

/** What guests see (never the ID number). */
export function publicTraderView(d: TraderDeclaration): Record<string, unknown> {
  if (!d.isTrader) return { isTrader: false };
  return {
    isTrader: true,
    name: d.name,
    address: formatAddress(d.address),
    phone: d.phone,
    email: d.email,
    tradeRegister: d.tradeRegister || null,
    tradeRegisterNumber: d.tradeRegisterNumber || null,
  };
}

function ownerView(d: Record<string, any> | undefined) {
  if (!d) return null;
  return {
    isTrader: d.isTrader === true,
    name: d.name || '',
    address: d.address && typeof d.address === 'object' ? d.address : null,
    phone: d.phone || '',
    email: d.email || '',
    idNumberMasked: maskTaxId(d.idNumber),
    idNumberSource: d.idNumberSource || null,
    tradeRegister: d.tradeRegister || '',
    tradeRegisterNumber: d.tradeRegisterNumber || '',
    selfCertified: d.selfCertified === true,
    updatedAt: d.updatedAt?.toDate?.().toISOString() || null,
  };
}

function billingPrefill(b: Record<string, any> | undefined) {
  if (!b) return null;
  return {
    legalName: b.legalName || '',
    address: b.address && typeof b.address === 'object' ? b.address : null,
    email: b.email || '',
    phone: b.phone || '',
    hasTaxId: !!b.taxId,
    taxIdMasked: maskTaxId(b.taxId),
  };
}

export async function saveTraderDeclaration(uid: string, raw: any): Promise<TraderDeclaration> {
  const ref = db().collection(TRADER).doc(uid);
  const [prev, billing] = await Promise.all([
    ref.get(),
    db().collection(BILLING).doc(uid).get(),
  ]);
  let decl: TraderDeclaration;
  try {
    decl = normalizeTrader(raw || {}, billing.data() || null, prev.data() || null);
  } catch (e) {
    if (e instanceof BillingError) throw new HttpsError('invalid-argument', e.message, { field: e.field, code: e.code });
    throw e;
  }
  const now = admin.firestore.Timestamp.now();
  const batch = db().batch();
  batch.set(ref, {
    ...decl,
    selfCertifiedAt: decl.selfCertified ? now : null,
    declaredAt: prev.get('declaredAt') || now,
    updatedAt: now,
    version: TRADER_DECLARATION_VERSION,
  });
  batch.set(db().collection(TRADER_PUBLIC).doc(uid), { ...publicTraderView(decl), updatedAt: now });
  await batch.commit();
  return decl;
}

export const getMyTraderDeclaration = onCall({ memory: '512MiB', timeoutSeconds: 30 }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first');
  const [d, b] = await Promise.all([
    db().collection(TRADER).doc(uid).get(),
    db().collection(BILLING).doc(uid).get(),
  ]);
  return { declaration: ownerView(d.data()), billing: billingPrefill(b.data()) };
});

export const saveMyTraderDeclaration = onCall({ memory: '512MiB', timeoutSeconds: 30 }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first');
  await saveTraderDeclaration(uid, request.data || {});
  const d = await db().collection(TRADER).doc(uid).get();
  return { declaration: ownerView(d.data()) };
});
