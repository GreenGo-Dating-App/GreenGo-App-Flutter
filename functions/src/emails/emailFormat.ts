/**
 * Formatting helpers for user-facing emails: recipient-locale date/time in the
 * HOST's time zone, places, and a small branded HTML frame.
 */
import { AppLocale, normalizeLocale } from '../shared/i18n';
import { listingTimeZone } from '../experience_bookings/model';
import { escapeHtml } from './sendEmail';

const INTL_LOCALE: Record<AppLocale, string> = {
  en: 'en-GB', de: 'de-DE', es: 'es-ES', fr: 'fr-FR', it: 'it-IT', pt: 'pt-PT', pt_BR: 'pt-BR',
};

export function intlLocale(locale: unknown): string {
  return INTL_LOCALE[normalizeLocale(locale)] || 'en-GB';
}

function validZone(tz: unknown): string | null {
  if (typeof tz !== 'string' || !tz.trim()) return null;
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: tz });
    return tz;
  } catch {
    return null;
  }
}

/** IANA zone of an event / experience doc (host's zone), else 'UTC'. */
export function hostTimeZone(listing: Record<string, unknown> | undefined | null): string {
  if (!listing) return 'UTC';
  const fromModel = listingTimeZone(listing);
  if (fromModel !== 'UTC') return fromModel;
  return validZone(listing.timezone) ?? 'UTC';
}

/**
 * "Saturday, 14 November 2026, 19:30 (Europe/Rome)" in the recipient's
 * language, wall-clock time of the host's zone (the zone is always shown).
 */
export function formatWhen(ms: number | null, timeZone: string, locale: unknown): string {
  if (ms === null || !Number.isFinite(ms)) return '-';
  const tz = validZone(timeZone) ?? 'UTC';
  try {
    const s = new Intl.DateTimeFormat(intlLocale(locale), { dateStyle: 'full', timeStyle: 'short', timeZone: tz })
      .format(new Date(ms));
    return `${s} (${tz})`;
  } catch {
    return `${new Date(ms).toISOString().replace('T', ' ').slice(0, 16)} UTC`;
  }
}

/** First non-empty, de-duplicated text parts joined with ", ". */
export function joinPlace(parts: unknown[]): string | null {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const p of parts) {
    if (typeof p !== 'string') continue;
    const v = p.trim();
    if (!v || seen.has(v.toLowerCase())) continue;
    seen.add(v.toLowerCase());
    out.push(v);
  }
  return out.length ? out.join(', ') : null;
}

export function millis(v: unknown): number | null {
  if (v === null || v === undefined) return null;
  if (typeof v === 'number') return Number.isFinite(v) ? v : null;
  if (typeof (v as any).toMillis === 'function') return (v as any).toMillis();
  if (v instanceof Date) return v.getTime();
  if (typeof v === 'string') {
    const n = Date.parse(v);
    return Number.isFinite(n) ? n : null;
  }
  if (typeof (v as any)._seconds === 'number') return (v as any)._seconds * 1000;
  return null;
}

/** Branded wrapper; [inner] must already be escaped HTML. */
export function emailFrame(inner: string): string {
  return '<div style="font-family:Arial,Helvetica,sans-serif;font-size:15px;line-height:1.5;color:#111;max-width:560px;margin:0 auto">'
    + '<div style="padding:16px 0;border-bottom:3px solid #0F9D58;font-size:20px;font-weight:bold;color:#0F9D58">GreenGo</div>'
    + `<div style="padding:16px 0">${inner}</div>`
    + '</div>';
}

/** <table> of label/value rows (both escaped here). */
export function detailsTable(rows: Array<[string, string | null | undefined]>): string {
  const body = rows
    .filter(([, v]) => v !== null && v !== undefined && String(v).trim() !== '')
    .map(([k, v]) => `<tr><td style="padding:4px 12px 4px 0;color:#555;vertical-align:top;white-space:nowrap">${escapeHtml(k)}</td>`
      + `<td style="padding:4px 0;font-weight:bold">${escapeHtml(v)}</td></tr>`)
    .join('');
  return `<table style="border-collapse:collapse;margin:8px 0 16px">${body}</table>`;
}
