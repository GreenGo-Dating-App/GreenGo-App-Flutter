/**
 * Terms 24.2 a notice email copy + Terms 12.4 trader declaration validation
 * (pure functions; the callables run in
 * __tests__/security/terms-w3.emulator.test.ts).
 */
import * as fs from 'fs';
import * as path from 'path';
import { buildNoticeEmail, formatNoticeDate, noticeKey } from '../../src/legal/termsChangeNotice';
import { NOTICE_COPY, TERMS_NOTICES } from '../../src/legal/termsNoticeCopy';
import { normalizeTrader, publicTraderView } from '../../src/legal/traderDeclaration';
import { SUPPORTED_LOCALES } from '../../src/shared/i18n/locales';

const n530 = TERMS_NOTICES['5.3.0'];
const arb = (l: string) => JSON.parse(fs.readFileSync(path.join(__dirname, '../../../lib/l10n', `app_${l}.arb`), 'utf8'));

describe('terms change notice email', () => {
  test('5.3.0: 30 days after 16 October 2026, the public upcoming URL', () => {
    expect(n530.effectiveDate).toBe('2026-11-16');
    expect(n530.url).toBe('https://greengochat.com/terms-of-service/upcoming');
    const days = (Date.parse('2026-11-16T00:00:00Z') - Date.parse('2026-10-16T00:00:00Z')) / 86400000;
    expect(days).toBeGreaterThanOrEqual(30);
  });

  test('bullets are the app ones (same words in the email and in the app, all 7 languages)', () => {
    const keys = ['Referral', 'CoinGifts', 'Menus', 'Moderation', 'Traders'].map((k) => `legalUpdate530Bullet${k}`);
    for (const l of SUPPORTED_LOCALES) {
      const a = arb(l);
      expect(n530.bullets[l]).toEqual(keys.map((k) => a[k]));
    }
  });

  test.each(SUPPORTED_LOCALES.map((l) => [l]))('%s: subject, date, bullets, link, rights, escaped', (l) => {
    const m = buildNoticeEmail(n530, l, 'ana@example.com');
    expect(m.to).toEqual(['ana@example.com']);
    expect(m.subject).toContain('5.3.0');
    expect(m.subject).toContain(formatNoticeDate(n530, l));
    expect(m.html).toContain(`href="${n530.url}"`);
    expect(m.text).toContain(n530.url);
    expect(m.text).toContain('billing@greengochat.com');
    expect(m.text).toContain('60');
    for (const b of n530.bullets[l]) expect(m.text).toContain(b);
    expect(m.html).not.toMatch(/<script/i);
    expect(NOTICE_COPY[l].rights('X')).toContain('X');
  });

  test('dates in the recipient language', () => {
    expect(formatNoticeDate(n530, 'en')).toBe('16 November 2026');
    expect(formatNoticeDate(n530, 'de')).toBe('16. November 2026');
    expect(formatNoticeDate(n530, 'pt_BR')).toContain('novembro');
  });

  test('one dispatch key per user and version', () => {
    expect(noticeKey('5.3.0', 'u1')).toBe('terms_notice_5.3.0_u1');
    expect(noticeKey('5.3.0', 'u1')).not.toBe(noticeKey('5.4.0', 'u1'));
  });
});

describe('trader declaration validation', () => {
  const valid = {
    isTrader: true,
    name: 'Bar do Zé Srl',
    address: { street: 'Via Roma', number: '1', city: 'Roma', postalCode: '00100', country: 'it' },
    phone: '+39 06 123456',
    email: 'ze@example.com',
    idNumber: 'IT12345678901',
    tradeRegister: 'Registro Imprese Roma',
    tradeRegisterNumber: 'RM-123',
    selfCertified: true,
  };
  const field = (fn: () => unknown) => {
    try {
      fn();
    } catch (e: any) {
      return `${e.field}:${e.code}`;
    }
    return 'ok';
  };

  test('non-trader needs no details', () => {
    expect(normalizeTrader({ isTrader: false, name: 'ignored' })).toMatchObject({ isTrader: false, name: '', address: null });
    expect(publicTraderView(normalizeTrader({ isTrader: false }))).toEqual({ isTrader: false });
  });

  test('answer required', () => {
    expect(field(() => normalizeTrader({}))).toBe('isTrader:required');
  });

  test('trader: all mandatory fields, self-certification, register pairs', () => {
    const d = normalizeTrader(valid);
    expect(d).toMatchObject({ isTrader: true, idNumberSource: 'own', selfCertified: true });
    expect(d.address!.country).toBe('IT');
    expect(field(() => normalizeTrader({ ...valid, name: ' ' }))).toBe('name:required');
    expect(field(() => normalizeTrader({ ...valid, phone: '' }))).toBe('phone:required');
    expect(field(() => normalizeTrader({ ...valid, phone: 'call me' }))).toBe('phone:invalid');
    expect(field(() => normalizeTrader({ ...valid, email: 'nope' }))).toBe('email:invalid');
    expect(field(() => normalizeTrader({ ...valid, address: { ...valid.address, city: '' } }))).toBe('address.city:required');
    expect(field(() => normalizeTrader({ ...valid, idNumber: '' }))).toBe('idNumber:required');
    expect(field(() => normalizeTrader({ ...valid, idNumber: '<script>' }))).toBe('idNumber:invalid');
    expect(field(() => normalizeTrader({ ...valid, selfCertified: false }))).toBe('selfCertified:required');
    expect(field(() => normalizeTrader({ ...valid, tradeRegister: '' }))).toBe('tradeRegister:required');
    expect(field(() => normalizeTrader({ ...valid, tradeRegisterNumber: '' }))).toBe('tradeRegisterNumber:required');
    expect(field(() => normalizeTrader({ ...valid, tradeRegister: '', tradeRegisterNumber: '' }))).toBe('ok');
  });

  test('reuses the invoice details: empty fields + tax id as ID number', () => {
    const billing = {
      legalName: 'Bar do Zé Srl', taxId: 'IT12345678901', email: 'fatture@example.com', phone: '+39 06 1',
      address: { street: 'Via Roma', number: '1', complement: '', district: '', city: 'Roma', region: '', postalCode: '00100', country: 'IT' },
    };
    const d = normalizeTrader({ isTrader: true, useBillingProfile: true, selfCertified: true }, billing);
    expect(d).toMatchObject({ name: 'Bar do Zé Srl', email: 'fatture@example.com', idNumber: 'IT12345678901', idNumberSource: 'billing' });
    // An own value wins over the billing one.
    expect(normalizeTrader({ ...valid, idNumber: '' }, billing).idNumber).toBe('IT12345678901');
  });

  test('an empty ID number keeps the saved one (the client only sees it masked)', () => {
    const prev = { isTrader: true, idNumber: 'AB123456', idNumberSource: 'own' };
    expect(normalizeTrader({ ...valid, idNumber: '' }, null, prev).idNumber).toBe('AB123456');
  });

  test('public view never carries the ID number', () => {
    const v = publicTraderView(normalizeTrader(valid));
    expect(v).toMatchObject({ isTrader: true, name: 'Bar do Zé Srl', email: 'ze@example.com', tradeRegisterNumber: 'RM-123' });
    expect(JSON.stringify(v)).not.toContain('IT12345678901');
    expect(String(v.address)).toContain('Roma');
  });
});
