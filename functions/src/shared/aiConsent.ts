/**
 * AI-processing consent (the user's "AI services" switch in Profile > Account
 * settings). Single source of truth: `consents/{uid}.ai_processing`, written
 * only by the `recordConsent` callable (append-only `events` history keeps
 * every grant / withdrawal with its timestamp for GDPR / LGPD audits).
 *
 *  - requireAiConsent      strict: an ACCEPTED record is required. Used by
 *                          every callable that sends user / chat text to an
 *                          AI provider (Gemini, Cloud TTS, Cloud Translation,
 *                          the free Google Translate endpoint).
 *  - hasWithdrawnAiConsent true only when the user explicitly switched AI
 *                          services OFF.
 *  - hasSupportAiConsent   strict, version-aware: an ACCEPTED record of at
 *                          least AI_SUPPORT_CONSENT_MIN_VERSION (the notice
 *                          that names Anthropic). Used by the support
 *                          assistant (Claude): without it the chat is handed
 *                          to a human agent (legal audit 2026-10).
 *
 * Safety / moderation screening is NOT gated here: it is not optional.
 */
import * as admin from 'firebase-admin';
import './firebaseAdmin';
import { HttpsError } from 'firebase-functions/v2/https';
import { AppError } from './utils';

export const CONSENTS = 'consents';
export const AI_CONSENT_TYPE = 'ai_processing';
/** Oldest consent-text version the server accepts for AI calls. */
export const AI_CONSENT_MIN_VERSION = 1;
/**
 * Oldest notice version that names Anthropic (support assistant). Version 1
 * named only Google, so a v1 acceptance covers Google features but NOT the
 * Claude-powered support assistant.
 */
export const AI_SUPPORT_CONSENT_MIN_VERSION = 2;

export type AiConsentState = 'granted' | 'withdrawn' | 'none';

export async function getAiConsentState(uid: string): Promise<AiConsentState> {
  const snap = await admin.firestore().collection(CONSENTS).doc(uid).get();
  const c = snap.data()?.[AI_CONSENT_TYPE];
  if (!c || typeof c !== 'object') return 'none';
  if (c.accepted === false) return 'withdrawn';
  if (c.accepted === true && Number(c.version) >= AI_CONSENT_MIN_VERSION) return 'granted';
  return 'none';
}

export function aiConsentRequiredError(): AppError {
  return new AppError(
    'AI_CONSENT_REQUIRED',
    'AI services are turned off for this account. Turn them on in Profile > Account settings.',
    403,
    { reason: 'AI_CONSENT_REQUIRED' },
  );
}

/** The caller must have ACCEPTED the AI-processing notice (server record). */
export async function requireAiConsent(uid: string): Promise<void> {
  if ((await getAiConsentState(uid)) !== 'granted') throw aiConsentRequiredError();
}

/**
 * Explicit, current consent for the support assistant: accepted AND a notice
 * version that names Anthropic. Never-asked, withdrawn and version-1 records
 * all return false.
 */
export async function hasSupportAiConsent(uid: string): Promise<boolean> {
  const snap = await admin.firestore().collection(CONSENTS).doc(uid).get();
  const c = snap.data()?.[AI_CONSENT_TYPE];
  return !!c && typeof c === 'object' && c.accepted === true
    && Number(c.version) >= AI_SUPPORT_CONSENT_MIN_VERSION;
}

/** True when the user explicitly turned AI services off. */
export async function hasWithdrawnAiConsent(uid: string): Promise<boolean> {
  return (await getAiConsentState(uid)) === 'withdrawn';
}

// ---------------------------------------------------------------------------
// Machine translation of PUBLIC content (Apple 5.1.2(i), App Review 2026-10-22)
// ---------------------------------------------------------------------------
//
// translateTexts and translateCommunityTips send text to Google's translation
// service on cache misses. They run on behalf of the VIEWER (the person who
// wants to read the text in their language), so the VIEWER's account-level
// AI consent is required: the same `consents/{uid}.ai_processing` record the
// chat translation, read-aloud and support assistant use (one choice per
// account, one switch in Settings). The text's author published it to be read
// by others (Terms: public content may be shown translated); the author's
// choice is not consulted. Without the viewer's consent the callable refuses
// the whole request (failed-precondition, details.code AI_CONSENT_REQUIRED),
// even for texts already in the shared store: the app reads stored
// translations straight from Firestore, so the callable is only ever asked for
// misses, and a refusal keeps the rule simple ("no consent, no translation
// call").
//
// The state is cached per function instance for a short time, and ONLY when
// granted, so a grant takes effect at once and a withdrawal within
// TRANSLATION_CONSENT_TTL_MS.

export const TRANSLATION_CONSENT_TTL_MS = 60_000;
const grantedUntil = new Map<string, number>();

/** For tests. */
export function clearTranslationConsentCache(): void {
  grantedUntil.clear();
}

/**
 * Throws HttpsError('failed-precondition', ..., { code: 'AI_CONSENT_REQUIRED',
 * reason: 'consent-required' }) unless [uid] accepted the AI-processing
 * notice. The app's isAiConsentRequiredError() recognises details.code.
 */
export async function requireTranslationConsent(
  uid: string,
  now: () => number = Date.now,
): Promise<void> {
  const until = grantedUntil.get(uid);
  if (until !== undefined && until > now()) return;
  const state = await getAiConsentState(uid);
  if (state === 'granted') {
    if (grantedUntil.size > 5000) grantedUntil.clear(); // bounded memory
    grantedUntil.set(uid, now() + TRANSLATION_CONSENT_TTL_MS);
    return;
  }
  grantedUntil.delete(uid);
  throw new HttpsError(
    'failed-precondition',
    'Automatic translation needs your permission to send text to Google. Turn on AI services in Settings.',
    { code: 'AI_CONSENT_REQUIRED', reason: 'consent-required', state },
  );
}
