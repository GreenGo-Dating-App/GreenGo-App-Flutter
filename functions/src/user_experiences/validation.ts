/**
 * User experiences — creation limits + payload validation (PURE).
 *
 * Limits per EFFECTIVE tier (see shared/effectiveTier.ts — an expired Silver
 * counts as FREE). Mirrors `TierEntitlements.maxExperiences` on the client:
 *   FREE 1 · SILVER 5 · GOLD 10 · PLATINUM ∞ · TEST ∞ · admin ∞
 * The count is every experience the host has that is not deleted (drafts +
 * published + hidden).
 */
import type { EffectiveTier } from '../shared/effectiveTier';
import { normalizeCancellation } from './safety';

export const EXPERIENCE_LIMITS: Record<EffectiveTier, number | null> = {
  FREE: 1,
  SILVER: 5,
  GOLD: 10,
  PLATINUM: null,
  TEST: null,
};

/** Max experiences for [tier] (null = unlimited). Admins are unlimited. */
export function maxExperiencesFor(tier: EffectiveTier, isAdmin = false): number | null {
  if (isAdmin) return null;
  // `in` (not `??`): null means UNLIMITED and must not fall back to 0.
  return tier in EXPERIENCE_LIMITS ? EXPERIENCE_LIMITS[tier] : 0;
}

/** Whether a host with [count] experiences may create one more. */
export function canCreateExperience(
  tier: EffectiveTier,
  count: number,
  isAdmin = false,
): boolean {
  const max = maxExperiencesFor(tier, isAdmin);
  return max === null || count < max;
}

export const CATEGORIES = [
  'foodDrink', 'cultureHistory', 'natureOutdoors', 'nightlife',
  'sportsAdventure', 'wellness', 'languageLearning', 'toursWalks',
  'workshopsClasses', 'other',
] as const;

export const PAYMENT_TYPES = ['pix', 'paypal', 'venmo', 'stripe', 'other'] as const;

/** How guests pay the host (outside GreenGo): cash at the meeting, or the link. */
export const PAYMENT_METHODS = ['cash', 'link'] as const;

/**
 * Payment methods of a payload. Missing field (older clients) = ['link'] for
 * paid listings (they always required a link). Unknown values are dropped.
 */
export function paymentMethodsFrom(v: unknown, isFree: boolean): string[] {
  if (isFree) return [];
  if (!Array.isArray(v)) return ['link'];
  return (PAYMENT_METHODS as readonly string[]).filter((m) => v.includes(m));
}

export const LIMITS = {
  titleMin: 5,
  titleMax: 80,
  descriptionMin: 30,
  descriptionMax: 2000,
  maxPhotos: 8,
  includedMax: 20,
  notIncludedMax: 20,
  itemMax: 120,
  durationMin: 15,
  durationMax: 60 * 24 * 14, // two weeks
  groupMax: 500,
  priceMax: 1000000,
  shortTextMax: 500,
  locationMax: 200,
  paymentValueMax: 300,
  languagesMax: 10,
};

function str(v: unknown): string {
  return typeof v === 'string' ? v.trim() : '';
}

function optStr(v: unknown, max: number): string | null {
  const s = str(v);
  return s.length === 0 ? null : s.slice(0, max);
}

function isHttpUrl(v: string): boolean {
  return /^https?:\/\/[^\s/$.?#][^\s]*$/i.test(v);
}

function strList(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  return v.map((x) => str(x)).filter((x) => x.length > 0);
}

function finiteNum(v: unknown): number | null {
  return typeof v === 'number' && Number.isFinite(v) ? v : null;
}

/** Lower-cased search tokens (title, city, country, category), like events. */
export function buildSearchKeywords(parts: Array<string | null | undefined>): string[] {
  const out = new Set<string>();
  for (const p of parts) {
    if (!p) continue;
    // Split on whitespace + ASCII punctuation (keeps accented letters / CJK
    // inside tokens; mirrors the client's keyword builder).
    for (const t of p.toLowerCase().split(/[\s!-/:-@[-`{-~]+/)) {
      if (t.length >= 2) out.add(t);
      if (out.size >= 40) break;
    }
  }
  return Array.from(out);
}

export interface ValidationResult {
  ok: boolean;
  errors: string[];
  /** Client-writable fields, normalised (only meaningful when ok). */
  data: Record<string, unknown>;
}

/**
 * Validates the payload of `createUserExperience`. Only client-owned fields
 * are read; anything server-owned in the payload (ratings, status 'hidden',
 * hostId of someone else, …) is ignored, never copied.
 */
export function validateExperiencePayload(p: Record<string, unknown> | null | undefined): ValidationResult {
  const errors: string[] = [];
  const d = p ?? {};

  const title = str(d.title);
  if (title.length < LIMITS.titleMin || title.length > LIMITS.titleMax) errors.push('title');
  const description = str(d.description);
  if (description.length < LIMITS.descriptionMin || description.length > LIMITS.descriptionMax) {
    errors.push('description');
  }
  const category = str(d.category);
  if (!(CATEGORIES as readonly string[]).includes(category)) errors.push('category');

  const mainPhotoUrl = str(d.mainPhotoUrl);
  if (!isHttpUrl(mainPhotoUrl)) errors.push('mainPhotoUrl');
  const photoUrls = strList(d.photoUrls);
  if (photoUrls.length > LIMITS.maxPhotos || photoUrls.some((u) => !isHttpUrl(u))) {
    errors.push('photoUrls');
  }

  const included = strList(d.included);
  if (included.length < 1 || included.length > LIMITS.includedMax ||
      included.some((i) => i.length > LIMITS.itemMax)) {
    errors.push('included');
  }
  const notIncluded = strList(d.notIncluded);
  if (notIncluded.length > LIMITS.notIncludedMax ||
      notIncluded.some((i) => i.length > LIMITS.itemMax)) {
    errors.push('notIncluded');
  }

  const locationName = str(d.locationName);
  if (locationName.length === 0 || locationName.length > LIMITS.locationMax) {
    errors.push('locationName');
  }
  const lat = finiteNum(d.lat);
  const lng = finiteNum(d.lng);
  const hasCoords = lat !== null && lng !== null &&
    Math.abs(lat) <= 90 && Math.abs(lng) <= 180;
  const geohash = str(d.geohash);

  const durationMinutes = finiteNum(d.durationMinutes);
  if (durationMinutes === null || !Number.isInteger(durationMinutes) ||
      durationMinutes < LIMITS.durationMin || durationMinutes > LIMITS.durationMax) {
    errors.push('durationMinutes');
  }

  const languages = strList(d.languages).slice(0, LIMITS.languagesMax);
  if (languages.length < 1) errors.push('languages');

  const maxGroupSize = finiteNum(d.maxGroupSize);
  if (maxGroupSize === null || !Number.isInteger(maxGroupSize) ||
      maxGroupSize < 1 || maxGroupSize > LIMITS.groupMax) {
    errors.push('maxGroupSize');
  }
  const minRaw = d.minGroupSize === null || d.minGroupSize === undefined
    ? null
    : finiteNum(d.minGroupSize);
  if (d.minGroupSize !== null && d.minGroupSize !== undefined &&
      (minRaw === null || !Number.isInteger(minRaw) || minRaw < 1 ||
       (maxGroupSize !== null && minRaw > maxGroupSize))) {
    errors.push('minGroupSize');
  }

  const isFree = d.isFree === true;
  const price = isFree ? 0 : finiteNum(d.price);
  if (price === null || price < 0 || price > LIMITS.priceMax) errors.push('price');
  const currency = optStr(d.currency, 8);

  // Paid: at least one method (cash at the meeting and/or the online link);
  // the link is required only when 'link' is a method. Free: none.
  const paymentMethods = paymentMethodsFrom(d.paymentMethods, isFree);
  if (!isFree && paymentMethods.length === 0) errors.push('paymentMethods');
  const wantsLink = paymentMethods.includes('link');
  let paymentLink: Record<string, string> | null = null;
  const pl = (d.paymentLink && typeof d.paymentLink === 'object')
    ? (d.paymentLink as Record<string, unknown>)
    : null;
  if (pl && wantsLink) {
    const type = str(pl.type);
    const value = str(pl.value);
    const typeOk = (PAYMENT_TYPES as readonly string[]).includes(type);
    const valueOk = value.length > 0 && value.length <= LIMITS.paymentValueMax &&
      (type === 'pix' || isHttpUrl(value));
    if (typeOk && valueOk) paymentLink = { type, value };
    else errors.push('paymentLink');
  }
  if (wantsLink && !paymentLink && !errors.includes('paymentLink')) errors.push('paymentLink');

  const status = str(d.status) === 'published' ? 'published' : 'draft';
  const city = optStr(d.city, 120);
  const country = optStr(d.country, 120);

  const data: Record<string, unknown> = {
    title,
    description,
    category,
    mainPhotoUrl,
    photoUrls,
    included,
    notIncluded,
    locationName,
    city,
    country,
    lat: hasCoords ? lat : null,
    lng: hasCoords ? lng : null,
    geohash: hasCoords && /^[0-9b-hjkmnp-z]{1,12}$/.test(geohash) ? geohash : null,
    meetingPoint: optStr(d.meetingPoint, LIMITS.shortTextMax),
    durationMinutes,
    languages,
    minGroupSize: minRaw,
    maxGroupSize,
    price: price ?? 0,
    currency: isFree ? null : currency,
    isFree,
    paymentMethods,
    paymentLink,
    availability: optStr(d.availability, LIMITS.shortTextMax),
    // Bookings: true = the host accepts / declines each booking request
    // (experience_bookings snapshots it on every booking).
    requestToBook: true, // mandatory: every booking is a request
    // Fixed policy (flexible | moderate | strict, default moderate) + notes;
    // legacy free text becomes moderate + notes.
    ...normalizeCancellation(d),
    status,
    hostName: optStr(d.hostName, 120),
    hostPhotoUrl: optStr(d.hostPhotoUrl, 1000),
    searchKeywords: buildSearchKeywords([title, city, country, category, locationName]),
  };
  return { ok: errors.length === 0, errors, data };
}
