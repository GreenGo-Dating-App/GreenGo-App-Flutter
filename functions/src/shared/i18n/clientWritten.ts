/**
 * Notification docs WRITTEN BY THE APP for another user (super like / Priority
 * Connect, photo like, coin gift, business verified). The app stores a neutral
 * English title/body plus a stable `data.kind` (or `type` + sender field); the
 * reader's app localizes them on screen, and the push relayed by
 * onNotificationCreatedPush is localized here for the recipient.
 *
 * Returns null for any other doc (the caller then uses the stored text).
 */
import { t } from './index';
import type { AppLocale } from './locales';

/** Legacy stand-ins older app versions stored for a missing name. */
const UNKNOWN_NAMES = new Set(['', 'unknown', 'someone', 'unknown user']);

function str(v: unknown): string {
  return typeof v === 'string' ? v.trim() : '';
}

/** [raw] or the localized "Unknown user" when it is missing / a placeholder. */
export function displayUserName(locale: AppLocale, raw: unknown): string {
  const name = str(raw);
  return UNKNOWN_NAMES.has(name.toLowerCase()) ? t(locale, 'srvUnknownUser') : name;
}

export function clientWrittenText(
  locale: AppLocale,
  doc: Record<string, unknown>,
): { title: string; body: string } | null {
  const data = (doc.data && typeof doc.data === 'object'
    ? doc.data
    : {}) as Record<string, unknown>;
  const kind = str(data.kind);
  const type = str(doc.type);

  if (kind === 'business_verified' || data.businessVerified === true) {
    return {
      title: t(locale, 'adminBusinessVerifiedNotificationTitle'),
      body: t(locale, 'adminBusinessVerifiedNotificationBody'),
    };
  }
  if (kind === 'photo_like') {
    const nick = str(data.likerNickname);
    const who = nick ? `@${nick}` : displayUserName(locale, data.likerName ?? doc.actorName);
    return {
      title: t(locale, 'notifNewPhotoLikeTitle'),
      body: t(locale, 'notifLikedYourPhoto', { name: who }),
    };
  }
  if (kind === 'coin_gift') {
    const amount = Number(data.amount);
    return {
      title: t(locale, 'notifCoinsReceivedTitle'),
      body: Number.isFinite(amount) && amount > 0
        ? t(locale, 'srvCoinsReceivedBody', {
          name: displayUserName(locale, data.senderName),
          amount,
        })
        : t(locale, 'notifCoinsReceivedTitle'),
    };
  }
  if (type === 'super_like' && Object.prototype.hasOwnProperty.call(data, 'senderDisplayName')) {
    return {
      title: t(locale, 'youGotSuperLike'),
      body: t(locale, 'superLikedYou', { name: displayUserName(locale, data.senderDisplayName) }),
    };
  }
  return null;
}
