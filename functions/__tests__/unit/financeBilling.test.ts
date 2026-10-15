/**
 * Seller invoice details: tax-id checksums per country (vectors cross-checked
 * with python-stdnum), profile normalization, masking, completeness, invoice
 * customer mapping.
 */
import {
  BillingError, billingMissing, billingToPartyFields, displayTaxId, isValidCodiceFiscale, isValidEsCif, isValidEsNifNie,
  isValidEuVat, isValidFrSpi, isValidPartitaIva, isValidPtNif, isValidSteuerId, maskTaxId, normalizeBilling,
  usIndividualKind, validateTaxId,
} from '../../src/finance/billing';

describe('tax-id checksums (python-stdnum vectors)', () => {
  it('Italy', () => {
    expect(isValidCodiceFiscale('RSSMRA85T10A562S')).toBe(true);
    expect(isValidCodiceFiscale('mrtmtt91d08f205j')).toBe(true);
    expect(isValidCodiceFiscale('RSSMRA85T10A562T')).toBe(false);
    expect(isValidPartitaIva('00743110157')).toBe(true);
    expect(isValidPartitaIva('IT01114601006')).toBe(true);
    expect(isValidPartitaIva('12345678903')).toBe(false);
    expect(isValidPartitaIva('00743110158')).toBe(false);
  });
  it('Portugal', () => {
    expect(isValidPtNif('123456789')).toBe(true);
    expect(isValidPtNif('PT501964843')).toBe(true);
    expect(isValidPtNif('999999990')).toBe(true);
    expect(isValidPtNif('123456780')).toBe(false);
  });
  it('Spain', () => {
    expect(isValidEsNifNie('12345678Z')).toEqual({ ok: true, kind: 'nif' });
    expect(isValidEsNifNie('12345678A').ok).toBe(false);
    expect(isValidEsNifNie('X1234567L')).toEqual({ ok: true, kind: 'nie' });
    expect(isValidEsNifNie('Y1234567X').ok).toBe(true);
    expect(isValidEsNifNie('X1234567A').ok).toBe(false);
    expect(isValidEsCif('A58818501')).toBe(true);
    expect(isValidEsCif('B12345674')).toBe(true);
    expect(isValidEsCif('Q2826000H')).toBe(true);
    expect(isValidEsCif('A58818500')).toBe(false);
  });
  it('Germany / France', () => {
    expect(isValidSteuerId('36574261809')).toBe(true);
    expect(isValidSteuerId('86095742719')).toBe(true);
    expect(isValidSteuerId('36574261808')).toBe(false);
    expect(isValidFrSpi('3023217600053')).toBe(true);
    expect(isValidFrSpi('3023217600054')).toBe(false);
    expect(isValidFrSpi('0701987765432')).toBe(false);
    expect(isValidEuVat('FR40303265045', 'FR')).toBe(true);
    expect(isValidEuVat('FR23334175221', 'FR')).toBe(true);
    expect(isValidEuVat('FR40303265046', 'FR')).toBe(false);
  });
  it('EU VAT formats + country checksums', () => {
    expect(isValidEuVat('DE123456789', 'DE')).toBe(true);
    expect(isValidEuVat('123456789', 'DE')).toBe(true);
    expect(isValidEuVat('DE12345678', 'DE')).toBe(false);
    expect(isValidEuVat('IT00743110157', 'IT')).toBe(true);
    expect(isValidEuVat('IT00743110158', 'IT')).toBe(false);
    expect(isValidEuVat('NL123456789B01', 'NL')).toBe(true);
    expect(isValidEuVat('ATU12345678', 'AT')).toBe(true);
    expect(isValidEuVat('EL123456789', 'GR')).toBe(true);
  });
  it('USA', () => {
    expect(usIndividualKind('123-45-6789')).toBe('ssn');
    expect(usIndividualKind('000-12-3456')).toBeNull();
    expect(usIndividualKind('666-12-3456')).toBeNull();
    expect(usIndividualKind('123-00-4567')).toBeNull();
    expect(usIndividualKind('912-70-1234')).toBe('itin');
    expect(usIndividualKind('912-40-1234')).toBeNull();
  });
});

describe('validateTaxId per country and type', () => {
  it('normalizes and names the kind', () => {
    expect(validateTaxId('BR', 'private', '529.982.247-25')).toEqual({ taxId: '52998224725', kind: 'cpf' });
    expect(validateTaxId('BR', 'company', '40.486.663/0001-82')).toEqual({ taxId: '40486663000182', kind: 'cnpj' });
    expect(validateTaxId('IT', 'company', '00743110157')).toEqual({ taxId: 'IT00743110157', kind: 'partita_iva' });
    expect(validateTaxId('ES', 'private', 'x1234567l')).toEqual({ taxId: 'X1234567L', kind: 'nie' });
    expect(validateTaxId('ES', 'company', 'A58818501')).toEqual({ taxId: 'ESA58818501', kind: 'cif' });
    expect(validateTaxId('PT', 'company', '501964843')).toEqual({ taxId: 'PT501964843', kind: 'nipc' });
    expect(validateTaxId('DE', 'private', '36 574 261 809')).toEqual({ taxId: '36574261809', kind: 'steuer_id' });
    expect(validateTaxId('FR', 'company', '40303265045')).toEqual({ taxId: 'FR40303265045', kind: 'vat' });
    expect(validateTaxId('US', 'company', '12-3456789')).toEqual({ taxId: '123456789', kind: 'ein' });
    expect(validateTaxId('NL', 'company', 'NL123456789B01')).toEqual({ taxId: 'NL123456789B01', kind: 'vat' });
    expect(validateTaxId('JP', 'private', 'AB-123 456')).toEqual({ taxId: 'AB-123 456', kind: 'other' });
  });
  it('rejects wrong checksums with field taxId', () => {
    for (const [c, t, v] of [['BR', 'private', '529.982.247-24'], ['BR', 'company', '40.486.663/0001-83'], ['IT', 'private', 'RSSMRA85T10A562T'],
      ['DE', 'private', '36574261808'], ['US', 'private', '000-12-3456'], ['JP', 'private', '!!']] as const) {
      expect(() => validateTaxId(c, t, v)).toThrow(BillingError);
    }
  });
});

const brPrivate = {
  type: 'private', country: 'BR', legalName: 'Ana Souza', taxId: '529.982.247-25', email: 'ana@example.com',
  address: { street: 'Av. Paulista', number: '1000', complement: 'ap 12', district: 'Bela Vista', city: 'São Paulo', region: 'sp', postalCode: '01310-100' },
};

describe('normalizeBilling', () => {
  it('private BR', () => {
    const p = normalizeBilling(brPrivate);
    expect(p).toMatchObject({ type: 'private', country: 'BR', taxId: '52998224725', taxIdKind: 'cpf', tradeName: '', contactPerson: '' });
    expect(p.address).toMatchObject({ region: 'SP', country: 'BR', postalCode: '01310-100' });
  });
  it('company BR with registrations + contact person', () => {
    const p = normalizeBilling({ ...brPrivate, type: 'company', legalName: 'Zé Bar Ltda', tradeName: 'Bar do Zé', taxId: '40.486.663/0001-82',
      contactPerson: 'José', inscricaoMunicipal: '1.234.567-8', inscricaoEstadual: 'isento' });
    expect(p).toMatchObject({ taxIdKind: 'cnpj', inscricaoMunicipal: '12345678', inscricaoEstadual: 'ISENTO', contactPerson: 'José' });
  });
  it('field errors', () => {
    const err = (raw: any) => { try { normalizeBilling(raw); return null; } catch (e) { return { field: (e as BillingError).field, code: (e as BillingError).code }; } };
    expect(err({ ...brPrivate, type: undefined })).toEqual({ field: 'type', code: 'required' });
    expect(err({ ...brPrivate, legalName: '' })).toEqual({ field: 'legalName', code: 'required' });
    expect(err({ ...brPrivate, email: 'nope' })).toEqual({ field: 'email', code: 'invalid' });
    expect(err({ ...brPrivate, address: { ...brPrivate.address, postalCode: '123' } })).toEqual({ field: 'address.postalCode', code: 'invalid' });
    expect(err({ ...brPrivate, address: { ...brPrivate.address, district: '' } })).toEqual({ field: 'address.district', code: 'required' });
    expect(err({ ...brPrivate, taxId: '' })).toEqual({ field: 'taxId', code: 'required' });
    expect(err({ ...brPrivate, type: 'company', taxId: '40.486.663/0001-82' })).toEqual({ field: 'contactPerson', code: 'required' });
  });
  it('US private may omit the SSN; company needs the EIN', () => {
    const us = { type: 'private', country: 'US', legalName: 'John Doe', email: 'j@example.com',
      address: { street: '1 Main St', city: 'Austin', region: 'tx', postalCode: '78701' } };
    expect(normalizeBilling(us)).toMatchObject({ taxId: '', taxIdKind: null });
    expect(() => normalizeBilling({ ...us, type: 'company', contactPerson: 'J' })).toThrow(/taxId/);
  });
  it('keeps the stored tax id when the client sends none (it only sees it masked)', () => {
    const keep = { taxId: '52998224725', taxIdKind: 'cpf' as const, country: 'BR', type: 'private' as const };
    expect(normalizeBilling({ ...brPrivate, taxId: '' }, keep).taxId).toBe('52998224725');
    // ...but not across a country / type change
    expect(() => normalizeBilling({ ...brPrivate, taxId: '', type: 'company', contactPerson: 'x' }, keep)).toThrow(/taxId/);
  });
});

describe('masking, completeness, invoice customer', () => {
  it('masks all but the last 4', () => {
    expect(maskTaxId('52998224725')).toBe('•••••••4725');
    expect(maskTaxId('')).toBe('');
  });
  it('completeness', () => {
    expect(billingMissing(null)).toEqual(['profile']);
    expect(billingMissing({ legalName: 'X', taxId: '1', address: 'old string', email: 'a@b.c' })).toEqual(['address', 'type']);
    expect(billingMissing(normalizeBilling(brPrivate))).toEqual([]);
  });
  it('maps to the invoice customer (structured and legacy)', () => {
    const p = normalizeBilling({ ...brPrivate, type: 'company', legalName: 'Zé Bar Ltda', tradeName: 'Bar do Zé', taxId: '40486663000182', contactPerson: 'José' });
    expect(billingToPartyFields(p)).toEqual({
      name: 'Zé Bar Ltda (Bar do Zé)', taxId: 'CNPJ 40.486.663/0001-82',
      address: 'Av. Paulista, 1000 · ap 12 - Bela Vista · 01310-100 São Paulo, SP, BR', email: 'ana@example.com',
    });
    expect(billingToPartyFields({ legalName: 'Old', taxId: '123', address: 'Rua X', email: 'o@x.y' }))
      .toEqual({ name: 'Old', taxId: '123', address: 'Rua X', email: 'o@x.y' });
    expect(displayTaxId('52998224725', 'cpf')).toBe('CPF 529.982.247-25');
  });
});
