/**
 * Pure helpers of the verified-phone index (phone_index/{hmac(e164)}).
 *
 * The doc id is HMAC-SHA256(PHONE_INDEX_KEY, e164) so the index never stores
 * a phone number. PHONE_INDEX_KEY (functions env) should be a long random
 * secret; without it the key is derived from the location jitter key under a
 * distinct label (same pattern as privateProfile.preciseJitterKey).
 */
import { createHmac } from 'crypto';
import { jitterKey } from '../profiles/privateProfile';
import { isE164, isPhoneNumberSupported } from '../shared/phoneCountries';

export const PHONE_INDEX = 'phone_index';
export const PHONE_REQUIRED_CODE = 'phone_verification_required';

let warned = false;

export function phoneIndexKey(): string {
  const k = process.env.PHONE_INDEX_KEY;
  if (k && k.length >= 16) return k;
  if (!warned) {
    warned = true;
    console.warn('phoneIndex: PHONE_INDEX_KEY not set; using a key derived from the jitter key');
  }
  return createHmac('sha256', jitterKey()).update('greengo-phone-index-key').digest('hex');
}

/** Doc id of `e164` in phone_index. Throws on a non-E.164 input. */
export function phoneHash(e164: string, key: string = phoneIndexKey()): string {
  if (!isE164(e164)) throw new Error('not_e164');
  return createHmac('sha256', key).update(e164).digest('hex');
}

export type PhoneDecision =
  | { allowed: true }
  | { allowed: false; reason: 'invalid_number' | 'unsupported_country' | 'phone_banned' | 'phone_in_use' };

/**
 * May `uid` verify `e164`? `indexDoc` is phone_index/{hash} (or null).
 * A number remembered from a BANNED (deleted or not) account is refused; a
 * number indexed to another live account is refused (Firebase Auth would
 * also refuse the link with credential-already-in-use).
 */
export function decidePhone(
  uid: string,
  e164: unknown,
  indexDoc: Record<string, unknown> | null | undefined,
): PhoneDecision {
  if (!isE164(e164)) return { allowed: false, reason: 'invalid_number' };
  if (!isPhoneNumberSupported(e164)) return { allowed: false, reason: 'unsupported_country' };
  if (indexDoc) {
    if (indexDoc.banned === true) return { allowed: false, reason: 'phone_banned' };
    if (typeof indexDoc.uid === 'string' && indexDoc.uid !== uid && indexDoc.released !== true) {
      return { allowed: false, reason: 'phone_in_use' };
    }
  }
  return { allowed: true };
}

/** True when an auth token carries a verified phone (the `phone_number` claim). */
export function tokenHasPhone(token: Record<string, unknown> | null | undefined): boolean {
  return !!token && typeof token.phone_number === 'string' && token.phone_number.length > 0;
}
