/**
 * Localized FCM delivery helpers.
 *
 * A push is rendered by the OS, so its text must already be in the
 * RECIPIENT's language when it leaves the server. Fan-outs load users/{uid}
 * for the FCM token anyway; the locale comes from the same doc (appLanguage),
 * so localization adds no reads. Recipients are grouped by locale and each
 * group is sent as its own multicast (chunked at the 500-token FCM limit).
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { AppLocale } from '../shared/i18n';
import { localeFromUserData } from '../shared/i18n/recipientLocale';

const FCM_CHUNK = 500;

export interface PushRecipient {
  token: string;
  locale: AppLocale;
}

/** Token + locale for every loaded users doc that has an FCM token. */
export function pushRecipientsFromUserDocs(
  docs: Array<admin.firestore.DocumentSnapshot | undefined>,
): PushRecipient[] {
  const out: PushRecipient[] = [];
  for (const d of docs) {
    const data = d?.data();
    const token = data?.fcmToken;
    if (typeof token === 'string' && token) {
      out.push({ token, locale: localeFromUserData(data) });
    }
  }
  return out;
}

/** Group recipients by locale (insertion order kept). */
export function groupByLocale(recipients: PushRecipient[]): Map<AppLocale, string[]> {
  const groups = new Map<AppLocale, string[]>();
  for (const r of recipients) {
    const list = groups.get(r.locale);
    if (list) list.push(r.token);
    else groups.set(r.locale, [r.token]);
  }
  return groups;
}

/**
 * Send one multicast per (locale, 500-token chunk). [build] returns the
 * message for a locale (without `tokens`). Best effort: a failed chunk is
 * logged with [label] and never throws.
 */
export async function sendLocalizedMulticast(
  recipients: PushRecipient[],
  build: (locale: AppLocale) => Omit<admin.messaging.MulticastMessage, 'tokens'>,
  label: string,
): Promise<void> {
  for (const [locale, tokens] of groupByLocale(recipients)) {
    const message = build(locale);
    for (let i = 0; i < tokens.length; i += FCM_CHUNK) {
      try {
        await admin.messaging().sendEachForMulticast({
          ...message,
          tokens: tokens.slice(i, i + FCM_CHUNK),
        });
      } catch (e) {
        console.error(`${label}: multicast failed (${locale})`, e);
      }
    }
  }
}
