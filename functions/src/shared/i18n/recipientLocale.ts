/**
 * Recipient language resolution for server-rendered texts (pushes, emails).
 *
 * Where the app language lives:
 *   1. users/{uid}.appLanguage - written by the app (>= this release) next to
 *      the FCM token on every token registration and whenever the user
 *      changes language. The push senders already read users/{uid} for the
 *      token, so this costs NO extra read.
 *   2. userSettings/{uid}.language - written by every app version when the
 *      user explicitly picks a language in Settings (one extra read; only
 *      done on single-recipient paths, only when (1) is missing).
 *   3. users/{uid}.preferredLanguage - legacy/translation preference.
 *   4. English.
 *
 * Fan-outs (thousands of recipients) use [localeFromUserData] on the user docs
 * they already load for tokens - no per-recipient extra reads.
 */
import * as admin from 'firebase-admin';
import '../firebaseAdmin';
import { AppLocale, DEFAULT_LOCALE, normalizeLocale } from './locales';

const db = () => admin.firestore();

function nonEmpty(v: unknown): v is string {
  return typeof v === 'string' && v.trim().length > 0;
}

/** True when the users doc carries the app language explicitly. */
export function hasAppLanguage(userData: Record<string, unknown> | undefined | null): boolean {
  return !!userData && nonEmpty(userData.appLanguage);
}

/**
 * Locale from an already-loaded users/{uid} doc. Synchronous, no reads:
 * appLanguage, then preferredLanguage, then English.
 */
export function localeFromUserData(
  userData: Record<string, unknown> | undefined | null,
): AppLocale {
  if (!userData) return DEFAULT_LOCALE;
  if (nonEmpty(userData.appLanguage)) return normalizeLocale(userData.appLanguage);
  if (nonEmpty(userData.preferredLanguage)) return normalizeLocale(userData.preferredLanguage);
  return DEFAULT_LOCALE;
}

/**
 * Per-invocation cache: create one per trigger run / callable call so a
 * recipient that appears several times is resolved once. Never shared across
 * invocations (a user may change language between runs).
 */
export class LocaleCache {
  private readonly byUid = new Map<string, Promise<AppLocale>>();

  /** Seed from a users doc the caller already read (no extra read later). */
  seed(uid: string, userData: Record<string, unknown> | undefined | null): void {
    if (!uid || this.byUid.has(uid)) return;
    if (hasAppLanguage(userData)) {
      this.byUid.set(uid, Promise.resolve(localeFromUserData(userData)));
    }
  }

  get(uid: string, userData?: Record<string, unknown> | null): Promise<AppLocale> {
    let p = this.byUid.get(uid);
    if (!p) {
      p = resolveLocaleUncached(uid, userData);
      this.byUid.set(uid, p);
    }
    return p;
  }
}

async function resolveLocaleUncached(
  uid: string,
  userData?: Record<string, unknown> | null,
): Promise<AppLocale> {
  if (!uid) return DEFAULT_LOCALE;
  try {
    let data = userData;
    if (data === undefined) {
      data = (await db().collection('users').doc(uid).get()).data() || null;
    }
    if (hasAppLanguage(data)) return localeFromUserData(data);
    const settings = (await db().collection('userSettings').doc(uid).get()).data();
    if (settings && nonEmpty(settings.language)) return normalizeLocale(settings.language);
    return localeFromUserData(data);
  } catch {
    return DEFAULT_LOCALE;
  }
}

/**
 * Resolve ONE recipient's locale. Pass [userData] when the caller already
 * loaded users/{uid} (saves the read), and a [cache] inside loops.
 */
export function resolveLocale(
  uid: string,
  opts: { userData?: Record<string, unknown> | null; cache?: LocaleCache } = {},
): Promise<AppLocale> {
  if (opts.cache) return opts.cache.get(uid, opts.userData);
  return resolveLocaleUncached(uid, opts.userData);
}

/**
 * Batched resolution for many recipients whose users docs are NOT loaded yet:
 * getAll in chunks of 300 (users, then userSettings only for the uids missing
 * appLanguage). Returns uid -> locale (English on any error).
 */
export async function resolveLocales(uids: string[]): Promise<Map<string, AppLocale>> {
  const out = new Map<string, AppLocale>();
  const unique = [...new Set(uids.filter(Boolean))];
  const CHUNK = 300;
  const missing: string[] = [];
  for (let i = 0; i < unique.length; i += CHUNK) {
    const slice = unique.slice(i, i + CHUNK);
    try {
      const snaps = await db().getAll(...slice.map((u) => db().collection('users').doc(u)));
      snaps.forEach((s, idx) => {
        const data = s.data();
        out.set(slice[idx], localeFromUserData(data));
        if (!hasAppLanguage(data)) missing.push(slice[idx]);
      });
    } catch {
      slice.forEach((u) => out.set(u, DEFAULT_LOCALE));
    }
  }
  for (let i = 0; i < missing.length; i += CHUNK) {
    const slice = missing.slice(i, i + CHUNK);
    try {
      const snaps = await db().getAll(...slice.map((u) => db().collection('userSettings').doc(u)));
      snaps.forEach((s, idx) => {
        const lang = s.data()?.language;
        if (nonEmpty(lang)) out.set(slice[idx], normalizeLocale(lang));
      });
    } catch {
      // keep what users/{uid} gave us
    }
  }
  return out;
}
