/**
 * Date-of-birth extraction tests.
 *
 * This parser decides whether a real person can publish in Communities, so it
 * is worth more than a smoke test. The cases below are the document layouts
 * GreenGo's users actually carry — the previous implementation accepted only
 * `dd/mm/yyyy` and `yyyy-mm-dd` and would have failed most of them.
 */

import { parseDateOfBirth, ageFrom, MINIMUM_AGE } from '../../src/safety/ageAssurance';

/** Builds a UTC date without the local-timezone trap. */
const utc = (y: number, m: number, d: number) => new Date(Date.UTC(y, m - 1, d));

describe('parseDateOfBirth', () => {
  it('reads an ISO date', () => {
    expect(parseDateOfBirth('Date of Birth 1990-03-14')).toEqual(utc(1990, 3, 14));
  });

  it('reads a day-first slash date', () => {
    expect(parseDateOfBirth('DATE OF BIRTH 14/03/1990')).toEqual(utc(1990, 3, 14));
  });

  it('reads a dotted date (Italian and German ID cards)', () => {
    expect(parseDateOfBirth('Data di nascita 14.03.1990')).toEqual(utc(1990, 3, 14));
  });

  it('reads a hyphenated date', () => {
    expect(parseDateOfBirth('Geburtsdatum 14-03-1990')).toEqual(utc(1990, 3, 14));
  });

  it('reads a month name in several languages', () => {
    expect(parseDateOfBirth('Born 14 MAR 1990')).toEqual(utc(1990, 3, 14));
    expect(parseDateOfBirth('Nascita 14 GEN 1990')).toEqual(utc(1990, 1, 14));
    expect(parseDateOfBirth('Naissance 14 AVR 1990')).toEqual(utc(1990, 4, 14));
  });

  it('reads the machine-readable zone of a passport', () => {
    const mrz = [
      'P<ITAROSSI<<MARIO<<<<<<<<<<<<<<<<<<<<<<<<<<<',
      'YA1234567ITA9003144M3001012<<<<<<<<<<<<<<04',
    ].join('\n');
    expect(parseDateOfBirth(mrz)).toEqual(utc(1990, 3, 14));
  });

  it('prefers the birth date over issue and expiry dates', () => {
    // A card carries three dates. Only one can be decades old.
    const card = [
      'REPUBBLICA ITALIANA',
      'Data di nascita 14.03.1990',
      'Data di rilascio 02.05.2021',
      'Data di scadenza 02.05.2031',
    ].join('\n');
    expect(parseDateOfBirth(card)).toEqual(utc(1990, 3, 14));
  });

  it('rejects an impossible calendar date instead of rolling it over', () => {
    // JS would happily turn 31 February into 3 March.
    expect(parseDateOfBirth('Date of Birth 31/02/1990')).toBeNull();
  });

  it('returns null when there is no plausible birth date', () => {
    expect(parseDateOfBirth('EXPIRES 02/05/2031')).toBeNull();
    expect(parseDateOfBirth('no dates here at all')).toBeNull();
  });

  it('ignores a date that would make the holder impossibly old', () => {
    expect(parseDateOfBirth('Born 14/03/1850')).toBeNull();
  });

  it('resolves a two-digit MRZ year into the past, never the future', () => {
    // '99' must mean 1999, not 2099.
    const mrz = 'YA1234567ITA9903144M3001012<<<<<<<<<<<<<<04';
    const parsed = parseDateOfBirth(mrz);
    expect(parsed?.getUTCFullYear()).toBe(1999);
  });
});

describe('ageFrom', () => {
  it('counts a birthday that has already passed this year', () => {
    expect(ageFrom(utc(1990, 3, 14), utc(2026, 9, 14))).toBe(36);
  });

  it('does not count a birthday still to come this year', () => {
    expect(ageFrom(utc(1990, 12, 14), utc(2026, 9, 14))).toBe(35);
  });

  it('handles the birthday itself', () => {
    expect(ageFrom(utc(1990, 9, 14), utc(2026, 9, 14))).toBe(36);
  });

  it('handles the day before the birthday', () => {
    expect(ageFrom(utc(1990, 9, 15), utc(2026, 9, 14))).toBe(35);
  });

  it('agrees with the minimum-age gate on the exact 18th birthday', () => {
    const eighteenToday = utc(2008, 9, 14);
    expect(ageFrom(eighteenToday, utc(2026, 9, 14))).toBe(MINIMUM_AGE);
    expect(ageFrom(eighteenToday, utc(2026, 9, 14)) >= MINIMUM_AGE).toBe(true);

    const eighteenTomorrow = utc(2008, 9, 15);
    expect(ageFrom(eighteenTomorrow, utc(2026, 9, 14)) >= MINIMUM_AGE).toBe(false);
  });
});
