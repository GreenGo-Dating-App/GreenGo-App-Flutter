import * as fs from 'fs';
import * as path from 'path';
import {
  t,
  lt,
  rawText,
  render,
  notifTextFields,
  renderStoredText,
  normalizeLocale,
  formatMessage,
  SUPPORTED_LOCALES,
} from '..';
import { ARB_CATALOG, ARB_KEYS } from '../catalog.generated';
import { EMAIL_SUBJECTS, EMAIL_SUBJECT_KEYS } from '../emailSubjects';
import { emailSubject } from '../email';
import { clientWrittenText, displayUserName } from '../clientWritten';
import { mediaLabel } from '../chatPreview';
import { localeFromUserData } from '../recipientLocale';

const ARB_DIR = path.resolve(__dirname, '../../../../../lib/l10n');
const KEYS_FILE = path.resolve(__dirname, '../serverKeys.json');

describe('normalizeLocale', () => {
  it.each([
    ['en', 'en'], ['EN-us', 'en'], ['de_DE', 'de'], ['it', 'it'], ['fr-CA', 'fr'],
    ['es_419', 'es'], ['pt', 'pt'], ['pt_PT', 'pt'], ['pt_BR', 'pt_BR'], ['pt-br', 'pt_BR'],
    ['ja', 'en'], ['', 'en'], [null, 'en'], [undefined, 'en'], [42, 'en'],
  ])('%p -> %p', (raw, want) => {
    expect(normalizeLocale(raw)).toBe(want);
  });
});

describe('t()', () => {
  it('translates into the recipient locale', () => {
    expect(t('it', 'notifServerTicketReady')).toBe('Il tuo biglietto è pronto');
    expect(t('pt_BR', 'notifServerTicketReady')).toBe('Seu ingresso está pronto');
    expect(t('pt', 'notifServerTicketReady')).toBe('O teu bilhete está pronto');
  });

  it('falls back to English for an unsupported or missing locale', () => {
    expect(t('ja', 'notifServerTicketReady')).toBe('Your ticket is ready');
    expect(t(undefined, 'notifServerTicketReady')).toBe('Your ticket is ready');
  });

  it('returns the key itself for an unknown key (never empty, never throws)', () => {
    expect(t('de', 'noSuchKey' as any)).toBe('noSuchKey');
  });

  it('substitutes params', () => {
    expect(t('en', 'notifServerJoinedYourEvent', { name: 'Jazz Night' })).toBe('joined your event Jazz Night');
    expect(t('de', 'notifServerNewEventIn', { name: 'Rom' })).toBe('Neues Event in Rom');
  });

  it('handles plurals per language (=1 and other)', () => {
    expect(t('en', 'srvGroupMembersLeft', { count: 1 })).toBe('A member left the group');
    expect(t('en', 'srvGroupMembersLeft', { count: 3 })).toBe('3 members left the group');
    expect(t('de', 'srvGroupMembersLeft', { count: 2 })).toBe('2 Mitglieder haben die Gruppe verlassen');
    expect(t('fr', 'srvPaymentsWaitingCount', { count: 1 })).toBe('1 paiement');
    expect(t('fr', 'srvPaymentsWaitingCount', { count: 5 })).toBe('5 paiements');
    expect(t('it', 'srvBundleNamesAndOthers', { names: 'Ana, Bo', count: 4 })).toBe('Ana, Bo e altri 4');
    // numeric strings work too (FCM / Firestore round trips)
    expect(t('en', 'srvSentYouCoins', { amount: '1' as any })).toBe('sent you 1 coin');
  });

  it('handles select (achievement ids)', () => {
    expect(t('en', 'srvAchievementUnlockedTitle', { achievement: 'daily_streak_7' }))
      .toBe('Achievement Unlocked: 7-Day Streak!');
    expect(t('it', 'srvAchievementUnlockedTitle', { achievement: 'unknown_id' }))
      .toBe('Traguardo sbloccato: Nuovo traguardo!');
  });
});

describe('formatMessage', () => {
  it('leaves malformed patterns as-is instead of throwing', () => {
    expect(formatMessage('Hello {name', { name: 'x' })).toBe('Hello {name');
    expect(formatMessage('{n, plural, one{a}', { n: 1 })).toBe('{n, plural, one{a}');
  });
  it('renders a missing param as empty', () => {
    expect(formatMessage('Hi {name}!', {})).toBe('Hi !');
  });
  it('uses CLDR categories when no exact branch matches', () => {
    expect(formatMessage('{n, plural, one{one} other{other}}', { n: 1 }, 'en')).toBe('one');
    expect(formatMessage('{n, plural, one{one} other{other}}', { n: 0 }, 'en')).toBe('other');
    // French treats 0 as "one"
    expect(formatMessage('{n, plural, one{one} other{other}}', { n: 0 }, 'fr')).toBe('one');
  });
});

describe('notification doc fields', () => {
  it('stores English fallbacks + keys + merged params', () => {
    const f = notifTextFields(
      lt('notifServerEventBoostLive', { name: 'Gala' }),
      lt('notifServerEventPromoted'),
    );
    expect(f).toEqual({
      title: 'Your event Gala boost is now live',
      message: 'Your event is being promoted in Explore',
      body: 'Your event is being promoted in Explore',
      titleKey: 'notifServerEventBoostLive',
      bodyKey: 'notifServerEventPromoted',
      params: { name: 'Gala' },
    });
  });

  it('never keys raw user content', () => {
    const f = notifTextFields(lt('notifServerTicketReady'), rawText('Jazz Night · 20:00'));
    expect(f.bodyKey).toBeUndefined();
    expect(f.body).toBe('Jazz Night · 20:00');
    expect(f.params).toBeUndefined();
  });

  it('re-renders a stored doc in the recipient language, falling back to stored text', () => {
    const doc = {
      ...notifTextFields(lt('srvMembershipExpiringTitle'), lt('srvMembershipExpiringBody', { tier: 'Gold', days: 1 })),
    };
    expect(renderStoredText('pt_BR', doc)).toEqual({
      title: 'Sua assinatura expira em breve',
      body: 'Sua assinatura Gold expira em 1 dia. Renove agora para manter seus recursos premium!',
    });
    // a key from a newer server version is ignored
    expect(renderStoredText('de', { title: 'T', message: 'M', titleKey: 'futureKey' })).toEqual({ title: 'T', body: 'M' });
    // plain legacy doc
    expect(renderStoredText('de', { title: 'T', body: 'B' })).toEqual({ title: 'T', body: 'B' });
  });

  it('render() accepts plain strings', () => {
    expect(render('de', 'as is')).toBe('as is');
    expect(render('de', lt('srvEvent'))).toBe('Event');
  });
});

describe('recipient locale from a users doc', () => {
  it('prefers appLanguage, then preferredLanguage, then English', () => {
    expect(localeFromUserData({ appLanguage: 'pt_BR', preferredLanguage: 'de' })).toBe('pt_BR');
    expect(localeFromUserData({ preferredLanguage: 'it' })).toBe('it');
    expect(localeFromUserData({ appLanguage: '  ', preferredLanguage: 'fr' })).toBe('fr');
    expect(localeFromUserData({})).toBe('en');
    expect(localeFromUserData(null)).toBe('en');
    expect(localeFromUserData({ appLanguage: 'zz' })).toBe('en');
  });
});

describe('app-written docs relayed by the push trigger', () => {
  it('photo like / coin gift / Priority Connect / business verified', () => {
    expect(clientWrittenText('it', { type: 'photo_like', data: { kind: 'photo_like', likerName: '' } }))
      .toEqual({ title: t('it', 'notifNewPhotoLikeTitle'), body: t('it', 'notifLikedYourPhoto', { name: 'Utente sconosciuto' }) });
    expect(clientWrittenText('en', { data: { kind: 'photo_like', likerNickname: 'ana' } })!.body).toBe('@ana liked your photo');
    expect(clientWrittenText('de', { data: { kind: 'coin_gift', senderName: 'Bo', amount: 5 } })!.body)
      .toBe('Bo hat dir 5 Münzen geschickt!');
    expect(clientWrittenText('es', { type: 'super_like', data: { senderDisplayName: '' } })!.body)
      .toBe(t('es', 'superLikedYou', { name: 'Usuario desconocido' }));
    expect(clientWrittenText('fr', { type: 'system', data: { businessVerified: true } })!.title)
      .toBe(t('fr', 'adminBusinessVerifiedNotificationTitle'));
    expect(clientWrittenText('fr', { type: 'system', data: {} })).toBeNull();
  });

  it('treats legacy placeholders as unknown', () => {
    expect(displayUserName('pt', 'Someone')).toBe('Utilizador desconhecido');
    expect(displayUserName('pt', 'Maria')).toBe('Maria');
  });
});

describe('chat media labels', () => {
  it('localizes media types and leaves text alone', () => {
    expect(mediaLabel('de', 'image')).toBe(`📷 ${t('de', 'chatPhoto')}`);
    expect(mediaLabel('it', 'voice_note')).toBe(`🎤 ${t('it', 'chatPreviewVoiceMessage')}`);
    expect(mediaLabel('es', 'gif')).toBe('GIF');
    expect(mediaLabel('es', 'text')).toBeNull();
  });
});

describe('email subjects', () => {
  it('localizes with recipient params and localized defaults', () => {
    expect(emailSubject('it', 'welcome', { userName: 'Ana' })).toBe('Benvenuto su GreenGo, Ana!');
    expect(emailSubject('de', 'subscription_trial_ending', { daysRemaining: 1 })).toBe('Deine Testphase endet in 1 Tag');
    expect(emailSubject('de', 'subscription_trial_ending', {})).toBe('Deine Testphase endet in 3 Tagen');
    expect(emailSubject('fr', 'message_received', {})).toBe('Nouveau message de quelqu’un');
    expect(emailSubject('en', 'no_such_trigger', {})).toBeNull();
  });

  it('every subject exists in every locale with the same placeholders', () => {
    for (const key of EMAIL_SUBJECT_KEYS) {
      const enNames = placeholderNames(EMAIL_SUBJECTS.en[key]);
      for (const l of SUPPORTED_LOCALES) {
        expect(EMAIL_SUBJECTS[l][key]).toBeTruthy();
        expect([key, l, placeholderNames(EMAIL_SUBJECTS[l][key])]).toEqual([key, l, enNames]);
      }
    }
  });
});

/** Top-level argument names ({name}, {count, plural, ...}) of an ICU string. */
function placeholderNames(s: string): string[] {
  const names = new Set<string>();
  const re = /\{([A-Za-z_][A-Za-z0-9_]*)\s*[,}]/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(s))) names.add(m[1]);
  return [...names].sort();
}

describe('catalog drift guard (ARB files are the source of truth)', () => {
  const locales = SUPPORTED_LOCALES;
  const arbs: Record<string, Record<string, unknown>> = {};
  beforeAll(() => {
    // Fails (never skips) when the ARB files are missing: this check must be
    // able to fail.
    for (const l of locales) {
      arbs[l] = JSON.parse(fs.readFileSync(path.join(ARB_DIR, `app_${l}.arb`), 'utf8'));
    }
  });

  it('serverKeys.json == generated key list', () => {
    const keys = JSON.parse(fs.readFileSync(KEYS_FILE, 'utf8'));
    expect([...ARB_KEYS].sort()).toEqual([...keys].sort());
    expect(ARB_KEYS.length).toBeGreaterThan(100);
  });

  it('generated catalog matches the ARB text in every locale', () => {
    const drift: string[] = [];
    for (const l of locales) {
      for (const k of ARB_KEYS) {
        if ((ARB_CATALOG as any)[l][k] !== arbs[l][k]) drift.push(`${l}:${k}`);
      }
    }
    expect(drift).toEqual([]); // re-run `node scripts/gen-i18n-catalog.cjs`
  });

  it('every translation uses the same placeholders as English', () => {
    // Ground truth: the @key.placeholders metadata in app_en.arb.
    const uses = (text: string, name: string) =>
      new RegExp(`\{${name}\s*[,}]`).test(text);
    const bad: string[] = [];
    for (const k of ARB_KEYS) {
      const meta = (arbs.en[`@${k}`] as any)?.placeholders ?? {};
      for (const name of Object.keys(meta)) {
        const inEn = uses((ARB_CATALOG as any).en[k], name);
        for (const l of locales) {
          if (uses((ARB_CATALOG as any)[l][k], name) !== inEn) bad.push(`${l}:${k}:${name}`);
        }
      }
    }
    expect(bad).toEqual([]);
  });
});
