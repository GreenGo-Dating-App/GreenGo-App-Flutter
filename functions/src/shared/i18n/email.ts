/**
 * Localized subject for a built-in Brevo email template (see emailSubjects.ts).
 */
import { EmailSubjectKey, EMAIL_SUBJECT_KEYS } from './emailSubjects';
import { I18nParams } from './icu';
import { t } from './index';
import type { AppLocale } from './locales';

const KEYS = new Set<string>(EMAIL_SUBJECT_KEYS);

/** Template variables with a localized stand-in when the caller omitted them. */
const LOCALIZED_DEFAULTS: Record<string, Record<string, EmailSubjectKey>> = {
  subscription_started: { planName: 'email.default.premium' },
  achievement_unlocked: { achievementName: 'email.default.achievement' },
  badge_earned: { badgeName: 'email.default.badge' },
  seasonal_event_started: { eventName: 'email.default.seasonalEvent' },
  message_received: { fromName: 'email.default.someone' },
  inactive_14_days: { likesCount: 'email.default.people' },
  new_feature_announcement: { featureName: 'email.default.feature' },
};

/** Language-neutral stand-ins (numbers / symbols). */
const LITERAL_DEFAULTS: Record<string, string | number> = {
  daysRemaining: 3,
  newLevel: '?',
  streakDays: 0,
  newRank: '?',
  xpAmount: 0,
  years: 1,
  invoiceNumber: '',
};

function present(v: unknown): boolean {
  return v !== undefined && v !== null && String(v).trim() !== '';
}

/**
 * Subject of [trigger]'s default template in [locale], or null when the
 * trigger has no catalog entry (the caller keeps the template's own subject).
 */
export function emailSubject(
  locale: AppLocale,
  trigger: string,
  variables: Record<string, unknown>,
): string | null {
  const key = `email.${trigger}`;
  if (!KEYS.has(key)) return null;
  const params: I18nParams = {};
  for (const [k, v] of Object.entries(LITERAL_DEFAULTS)) params[k] = v;
  for (const [k, def] of Object.entries(LOCALIZED_DEFAULTS[trigger] || {})) {
    params[k] = t(locale, def);
  }
  for (const [k, v] of Object.entries(variables || {})) {
    if (present(v) && (typeof v === 'string' || typeof v === 'number')) params[k] = v;
  }
  return t(locale, key as EmailSubjectKey, params);
}
