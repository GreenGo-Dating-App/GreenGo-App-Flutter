/**
 * Ticket payments: currency + method rules (pure functions, no emulator).
 */
import {
  checkCharge,
  minimumMinor,
  mpCurrencyForSite,
  stripePaymentMethodTypes,
  toMajor,
  toMinor,
} from '../../src/ticket_payments/currency';
import { isLinkMethod, PROFILE_LINK_METHODS } from '../../src/ticket_payments/config';
import { linkPaymentSnapshot, newPaymentCode, PAYMENT_CODE_RE } from '../../src/ticket_payments/orders';
import { signState, ticketQrPayload, verifyMpSignature, verifyState, verifyTicketQr, seal, unseal } from '../../src/ticket_payments/tokens';
import * as crypto from 'crypto';

describe('minor units', () => {
  test('two-decimal currencies', () => {
    expect(toMinor(19.99, 'usd')).toBe(1999);
    expect(toMinor(25, 'brl')).toBe(2500);
    expect(toMinor(0.1 + 0.2, 'eur')).toBe(30);
    expect(toMajor(2500, 'brl')).toBe(25);
  });
  test('zero-decimal currencies have no cents (JPY, KRW, CLP)', () => {
    expect(toMinor(1500, 'jpy')).toBe(1500);
    expect(toMinor(1500, 'JPY')).toBe(1500);
    expect(toMinor(30000, 'krw')).toBe(30000);
    expect(toMinor(9990, 'clp')).toBe(9990);
    expect(toMajor(9990, 'clp')).toBe(9990);
  });
});

describe('Mercado Pago charges only in the account site currency', () => {
  test('site -> currency', () => {
    expect(mpCurrencyForSite('MLB')).toBe('brl');
    expect(mpCurrencyForSite('MLA')).toBe('ars');
    expect(mpCurrencyForSite('MLM')).toBe('mxn');
    expect(mpCurrencyForSite('MLC')).toBe('clp');
    expect(mpCurrencyForSite('MCO')).toBe('cop');
    expect(mpCurrencyForSite('MPE')).toBe('pen');
    expect(mpCurrencyForSite('MLU')).toBe('uyu');
    expect(mpCurrencyForSite('XXX')).toBeNull();
  });
  test('currency mismatch is rejected with the expected currency', () => {
    expect(checkCharge('mercadopago', 'usd', 2500, 'brl')).toEqual({ ok: false, reason: 'currency_not_supported', expected: 'brl' });
    expect(checkCharge('mercadopago', 'brl', 2500, null)).toEqual({ ok: false, reason: 'currency_not_supported', expected: null });
    expect(checkCharge('mercadopago', 'brl', 2500, 'brl')).toEqual({ ok: true });
  });
});

describe('provider minimum amounts', () => {
  test('Stripe table (0.50 USD/EUR/BRL, 0.30 GBP, 50 JPY)', () => {
    expect(minimumMinor('stripe', 'usd')).toBe(50);
    expect(minimumMinor('stripe', 'gbp')).toBe(30);
    expect(minimumMinor('stripe', 'jpy')).toBe(50);
    expect(checkCharge('stripe', 'usd', 49, null)).toEqual({ ok: false, reason: 'amount_below_minimum', minimum: 50 });
    expect(checkCharge('stripe', 'usd', 50, null)).toEqual({ ok: true });
    expect(checkCharge('stripe', 'jpy', 49, null).ok).toBe(false);
  });
  test('Mercado Pago 1.00 local currency; link mode has no minimum', () => {
    expect(checkCharge('mercadopago', 'brl', 99, 'brl')).toEqual({ ok: false, reason: 'amount_below_minimum', minimum: 100 });
    expect(checkCharge('mercadopago', 'clp', 1, 'clp')).toEqual({ ok: true });
    expect(checkCharge('link', 'xyz', 1, null)).toEqual({ ok: true });
  });
});

test('Stripe Pix only for BRL on a Brazilian account', () => {
  expect(stripePaymentMethodTypes('brl', 'BR')).toEqual(['card', 'pix']);
  expect(stripePaymentMethodTypes('brl', 'US')).toEqual(['card']);
  expect(stripePaymentMethodTypes('usd', 'BR')).toEqual(['card']);
});

describe('manual (link) methods', () => {
  test('pasted Stripe / Mercado Pago links are never manual options', () => {
    expect(isLinkMethod('stripe')).toBe(false);
    expect(isLinkMethod('mercadoPago')).toBe(false);
    expect(PROFILE_LINK_METHODS).not.toContain('stripe');
    expect(PROFILE_LINK_METHODS).not.toContain('mercadoPago');
    for (const m of ['pix', 'picPay', 'paypal', 'venmo', 'cashApp', 'revolut', 'wise', 'monzo', 'kofi', 'cash', 'bankTransfer']) {
      expect(isLinkMethod(m)).toBe(true);
    }
  });
  test('snapshot comes from the organizer profile; bank transfer needs instructions', () => {
    const prof = { paymentLinks: { pix: 'k@pix', stripe: 'https://buy.stripe.com/x' } };
    expect(linkPaymentSnapshot('pix', prof, null)).toEqual({ method: 'pix', value: 'k@pix', instructions: null });
    expect(linkPaymentSnapshot('stripe', prof, null)).toBeNull();
    expect(linkPaymentSnapshot('paypal', prof, null)).toBeNull();
    expect(linkPaymentSnapshot('cash', prof, null)).toEqual({ method: 'cash', value: null, instructions: null });
    expect(linkPaymentSnapshot('bankTransfer', prof, null)).toBeNull();
    expect(linkPaymentSnapshot('bankTransfer', prof, 'IBAN X')).toEqual({ method: 'bankTransfer', value: null, instructions: 'IBAN X' });
  });
  test('payment codes are GG- + 6 unambiguous characters', () => {
    for (let i = 0; i < 200; i++) {
      const c = newPaymentCode();
      expect(c).toMatch(PAYMENT_CODE_RE);
      expect(c.slice(3)).not.toMatch(/[01ILOU]/);
    }
  });
});

describe('tokens', () => {
  const key = 'k'.repeat(40);
  test('ticket QR verifies only with the key and the exact id', () => {
    const qr = ticketQrPayload(key, 'order1');
    expect(verifyTicketQr(key, qr)).toBe('order1');
    expect(verifyTicketQr('x'.repeat(40), qr)).toBeNull();
    expect(verifyTicketQr(key, qr.replace('order1', 'order2'))).toBeNull();
    expect(verifyTicketQr(key, 'greengo:ev:e:u:ABCDEFGH')).toBeNull();
  });
  test('OAuth state expires and is bound to the uid', () => {
    const s = signState(key, 'u1', 1000, 60000);
    expect(verifyState(key, s, 2000)).toBe('u1');
    expect(verifyState(key, s, 62000)).toBeNull();
    expect(verifyState(key, s.replace('u1', 'u2'), 2000)).toBeNull();
  });
  test('MP x-signature', () => {
    const secret = 's3cret';
    const manifest = 'id:123;request-id:r1;ts:99;';
    const v1 = crypto.createHmac('sha256', secret).update(manifest).digest('hex');
    expect(verifyMpSignature(secret, `ts=99,v1=${v1}`, 'r1', '123')).toBe(true);
    expect(verifyMpSignature(secret, `ts=99,v1=${v1}`, 'r1', '124')).toBe(false);
    expect(verifyMpSignature('other', `ts=99,v1=${v1}`, 'r1', '123')).toBe(false);
  });
  test('sealed MP tokens round-trip and are not plaintext', () => {
    const sealed = seal('APP_USR-123', '', key);
    expect(sealed).not.toContain('APP_USR');
    expect(unseal(sealed, '', key)).toBe('APP_USR-123');
    expect(() => unseal(sealed, '', 'z'.repeat(40))).toThrow();
  });
});
