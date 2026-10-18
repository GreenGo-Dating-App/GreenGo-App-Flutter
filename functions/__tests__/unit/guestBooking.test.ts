/**
 * Guest booking from a shared link (functions/src/guest): identity keys,
 * input validation, listing rules (view / book), capacity, signed tokens,
 * CSRF origin check, routing, HTML escaping of every page, the two-choice
 * landing, guest e-mail decisions, the free-event RSVP transaction (mocked
 * Firestore) and the server i18n table. No network, no emulator.
 */
import {
  GuestBuyer, guestDisplayName, guestKeyFor, guestRecordFields, isGuestKey, normalizeGuestEmail,
} from '../../src/shared/guestIdentity';
import {
  LIMITS, checkSig, cleanName, clientIp, eventSale, eventSeatsLeft, experienceSale, guestBookBlock,
  guestTicketCap, guestViewBlock, intField, isValidGuestEmail, maskGuestEmail, originAllowed, parseGuestInput,
  parseGuestPath, paySig, rateKey, returnSig, signFormToken, verifyFormToken,
} from '../../src/guest/guestModel';
import { GUEST_STRINGS, gt } from '../../src/guest/guestI18n';
import {
  GUEST_SECURITY_HEADERS, renderListingPage, renderMessagePage, renderPayPage, renderRedirectPage,
  renderUnavailablePage, ListingView,
} from '../../src/guest/guestPages';
import {
  GuestError, errorKeyFor, guestDeps, isProviderCheckoutUrl, parseEventChoice, parseSlotChoice,
  registerGuestForFreeEvent,
} from '../../src/guest/guestService';
import {
  becameCancelled, buildGuestNotice, guestBookingNotice, guestOrderNotice,
} from '../../src/guest/guestEmails';
import { formBody } from '../../src/guest';
import { buildEventPreview, renderHtml } from '../../src/share/sharePreviewCore';
import { SUPPORTED_LOCALES } from '../../src/shared/i18n';

const NOW = Date.UTC(2026, 9, 14, 12);
const ts = (ms: number) => ({ toMillis: () => ms });
const KEY = 'k'.repeat(64);
const XSS = '<script>alert(1)</script>"\'&';

const publicEvent = (patch: Record<string, unknown> = {}): Record<string, unknown> => ({
  title: 'Samba night',
  status: 'published',
  visibility: 'public',
  guestsAllowed: true,
  startDate: ts(NOW + 86400000),
  endDate: ts(NOW + 90000000),
  maxAttendees: 10,
  attendeeCount: 3,
  ...patch,
});

// ─────────────────────────────────────────────────────────── identity

describe('guest identity', () => {
  test('guest key: stable per address, case / space insensitive, keyed by the secret', () => {
    const a = guestKeyFor('s1', 'Ana@Example.com ');
    expect(a).toBe(guestKeyFor('s1', 'ana@example.com'));
    expect(a).not.toBe(guestKeyFor('s2', 'ana@example.com'));
    expect(a).not.toBe(guestKeyFor('s1', 'bob@example.com'));
    expect(isGuestKey(a)).toBe(true);
    expect(a).toMatch(/^guest_[0-9a-f]{40}$/);
    expect(a).not.toContain('ana');
  });

  test('a real Firebase Auth uid is never a guest key', () => {
    expect(isGuestKey('AbC123xyzUSERuid0001xyzABCD')).toBe(false);
    expect(isGuestKey('guest_ABC')).toBe(false);
    expect(isGuestKey(`guest_${'0'.repeat(39)}`)).toBe(false);
    expect(isGuestKey(undefined)).toBe(false);
    expect(() => guestKeyFor('', 'a@b.co')).toThrow();
  });

  test('display name and record fields carry names only (no e-mail)', () => {
    expect(guestDisplayName({ firstName: ' Ana ', lastName: 'Souza' })).toBe('Ana Souza');
    expect(guestDisplayName(null)).toBe('');
    const f = guestRecordFields({ firstName: 'Ana', lastName: 'Souza' });
    expect(f).toEqual({ isGuest: true, guest: { firstName: 'Ana', lastName: 'Souza' }, guestName: 'Ana Souza' });
    expect(JSON.stringify(f)).not.toContain('@');
    expect(normalizeGuestEmail(' A@B.CO ')).toBe('a@b.co');
  });
});

// ─────────────────────────────────────────────────────────── input

describe('guest input validation', () => {
  const ok = { firstName: 'Ana', lastName: "D'Ávila-Souza", email: 'ana@example.com', consent: 'on' };

  test('accepts real names in any script, refuses markup / digits / empties', () => {
    expect(parseGuestInput(ok).ok).toBe(true);
    expect(parseGuestInput({ ...ok, firstName: 'Zoë', lastName: '王' }).ok).toBe(true);
    expect(parseGuestInput({ ...ok, firstName: 'J.', lastName: 'Smith Jr.' }).ok).toBe(true);
    for (const bad of [XSS, '', ' ', 'Ana1', 'a'.repeat(61), '-Ana', 'Ana<b>', 'Ana@x']) {
      const r = parseGuestInput({ ...ok, firstName: bad });
      expect(r.ok).toBe(false);
      if (r.ok === false) expect(r.error).toBe('name');
    }
  });

  test('e-mail and consent are required', () => {
    for (const bad of ['', 'ana', 'ana@', '@x.com', 'ana@x', 'a b@x.com', 'ana@x..com', `${'a'.repeat(250)}@x.com`, '<a@x.com>']) {
      const r = parseGuestInput({ ...ok, email: bad });
      expect(r.ok === false && r.error).toBe('email');
    }
    const r = parseGuestInput({ ...ok, consent: undefined });
    expect(r.ok === false && r.error).toBe('consent');
    expect(isValidGuestEmail('first.last+tag@sub.example.co.uk')).toBe(true);
  });

  test('cleanName strips control and bidi characters, collapses spaces', () => {
    expect(cleanName('  Ana‮ \u0000 Maria  ')).toBe('Ana Maria');
    expect(cleanName(42)).toBe('');
  });

  test('intField and masking', () => {
    expect(intField('3', 1, 10)).toBe(3);
    expect(intField('0', 1, 10)).toBeNull();
    expect(intField('11', 1, 10)).toBeNull();
    expect(intField('1e2', 1, 1000)).toBeNull();
    expect(intField(['1'], 1, 10)).toBeNull();
    expect(maskGuestEmail('ana@example.com')).toBe('a***@example.com');
    expect(maskGuestEmail('nope')).toBe('***');
  });

  test('form body: flat strings only, bounded', () => {
    expect(formBody({ a: 'x' })).toEqual({ a: 'x' });
    expect(formBody({ a: ['x'] })).toBeNull();
    expect(formBody({ a: { $gt: '' } })).toBeNull();
    expect(formBody({ a: 'x'.repeat(601) })).toBeNull();
    expect(formBody(Object.fromEntries(Array.from({ length: 61 }, (_, i) => [`k${i}`, 'v'])))).toBeNull();
    expect(formBody('a=b')).toBeNull();
  });
});

// ─────────────────────────────────────────────────────────── listing rules

describe('what a guest may see and book', () => {
  test('events: hidden when private / draft / not yet published / taken down / hidden by downgrade', () => {
    expect(guestViewBlock('e', publicEvent(), NOW)).toBeNull();
    expect(guestViewBlock('e', undefined, NOW)).toBe('not_found');
    expect(guestViewBlock('e', publicEvent({ visibility: 'private' }), NOW)).toBe('hidden');
    expect(guestViewBlock('e', publicEvent({ status: 'draft' }), NOW)).toBe('hidden');
    expect(guestViewBlock('e', publicEvent({ status: 'scheduled', publishAt: ts(NOW + 1000) }), NOW)).toBe('hidden');
    expect(guestViewBlock('e', publicEvent({ hiddenByDowngrade: true }), NOW)).toBe('hidden');
    expect(guestViewBlock('e', publicEvent({ copyrightHold: true }), NOW)).toBe('hidden');
    expect(guestViewBlock('e', publicEvent({ isDeleted: true }), NOW)).toBe('hidden');
    // Absent visibility = public (app default).
    expect(guestViewBlock('e', publicEvent({ visibility: undefined }), NOW)).toBeNull();
  });

  test('events: bookable only with the host switch on, live, and instant / free', () => {
    expect(guestBookBlock('e', publicEvent(), NOW)).toBeNull();
    expect(guestBookBlock('e', publicEvent({ guestsAllowed: false }), NOW)).toBe('guests_not_allowed');
    expect(guestBookBlock('e', publicEvent({ guestsAllowed: 'true' }), NOW)).toBe('guests_not_allowed');
    expect(guestBookBlock('e', publicEvent({ status: 'cancelled' }), NOW)).toBe('not_on_sale');
    expect(guestBookBlock('e', publicEvent({ endDate: ts(NOW - 1) }), NOW)).toBe('ended');
    expect(guestBookBlock('e', publicEvent({ ticketProvider: 'link', price: 10 }), NOW)).toBe('app_only');
    expect(guestBookBlock('e', publicEvent({ price: 10 }), NOW)).toBe('app_only'); // legacy coin price
    expect(guestBookBlock('e', publicEvent({ ticketProvider: 'stripe', price: 10 }), NOW)).toBeNull();
    expect(guestBookBlock('e', publicEvent({ requiresApproval: true }), NOW)).toBe('app_only');
    expect(guestBookBlock('e', publicEvent({ minAge: 18 }), NOW)).toBe('app_only');
    expect(guestBookBlock('e', publicEvent({ visibility: 'private' }), NOW)).toBe('hidden');
  });

  test('experiences and attractions', () => {
    const x = { status: 'published', guestsAllowed: true, isFree: true };
    expect(guestBookBlock('x', x, NOW)).toBeNull();
    expect(guestBookBlock('x', { ...x, status: 'draft' }, NOW)).toBe('hidden');
    expect(guestBookBlock('x', { ...x, hiddenByDowngrade: true }, NOW)).toBe('hidden');
    expect(guestBookBlock('x', { ...x, guestsAllowed: false }, NOW)).toBe('guests_not_allowed');
    const paid = { ...x, isFree: false, paymentMethods: ['online'], paymentProvider: 'stripe' };
    expect(guestBookBlock('x', paid, NOW)).toBeNull();
    expect(guestBookBlock('x', { ...paid, paymentProvider: 'link' }, NOW)).toBe('app_only');
    expect(guestBookBlock('x', { ...paid, paymentMethods: ['cash'] }, NOW)).toBe('app_only');
    expect(experienceSale(paid)).toBe('instant');
    expect(guestViewBlock('a', { status: 'published' }, NOW)).toBeNull();
    expect(guestBookBlock('a', { status: 'published', guestsAllowed: true }, NOW)).toBe('not_on_sale');
    expect(guestViewBlock('a', { status: 'draft' }, NOW)).toBe('hidden');
  });

  test('event sale mode', () => {
    expect(eventSale({})).toBe('free');
    expect(eventSale({ price: 0 })).toBe('free');
    expect(eventSale({ ticketProvider: 'mercadopago' })).toBe('instant');
    expect(eventSale({ ticketProvider: 'link' })).toBe('link');
  });

  test('capacity: seats left count paid seats AND live holds; the order cap respects every limit', () => {
    expect(eventSeatsLeft(publicEvent(), 0)).toBe(7);
    expect(eventSeatsLeft(publicEvent(), 5)).toBe(2);
    expect(eventSeatsLeft(publicEvent(), 50)).toBe(0);
    expect(eventSeatsLeft(publicEvent({ maxAttendees: 0 }), 5)).toBeNull();
    expect(guestTicketCap(publicEvent(), 7)).toBe(4); // default per-buyer limit
    expect(guestTicketCap(publicEvent({ maxTicketsPerUser: 2 }), 7)).toBe(2);
    // Owner rule 2026-10-18: never more than 4 per e-mail per event, whatever the listing says.
    expect(guestTicketCap(publicEvent({ maxTicketsPerUser: null }), 7)).toBe(4);
    expect(guestTicketCap(publicEvent({ maxTicketsPerUser: null }), null)).toBe(Math.min(4, LIMITS.maxTickets));
    expect(guestTicketCap(publicEvent({ maxTicketsPerUser: 10 }), null)).toBe(4);
    expect(guestTicketCap(publicEvent({ maxTicketsPerUser: null }), 3)).toBe(3);
    // Plus-ones never limit a PAID order (every person holds a ticket).
    expect(guestTicketCap(publicEvent({ maxTicketsPerUser: null, guestsAllowedPerAttendee: 1 }), null)).toBe(4);
    expect(guestTicketCap(publicEvent(), 0)).toBe(0);
  });
});

// ─────────────────────────────────────────────────────────── tokens / CSRF / routing

describe('signed tokens, origin check and routing', () => {
  test('form token: bound to the listing, min fill time, expiry, tamper-proof', () => {
    const tok = signFormToken(KEY, 'e', 'ev1', NOW, 'nonce12345');
    expect(verifyFormToken(KEY, 'e', 'ev1', tok, NOW + 5000)).toEqual({ ok: true, nonce: 'nonce12345' });
    expect(verifyFormToken(KEY, 'e', 'ev1', tok, NOW + 100)).toEqual({ ok: false, reason: 'too_fast' });
    expect(verifyFormToken(KEY, 'e', 'ev1', tok, NOW + LIMITS.formTtlMs + 1)).toEqual({ ok: false, reason: 'expired' });
    expect(verifyFormToken(KEY, 'e', 'ev2', tok, NOW + 5000)).toEqual({ ok: false, reason: 'invalid' });
    expect(verifyFormToken(KEY, 'x', 'ev1', tok, NOW + 5000)).toEqual({ ok: false, reason: 'invalid' });
    expect(verifyFormToken('other'.repeat(13), 'e', 'ev1', tok, NOW + 5000)).toEqual({ ok: false, reason: 'invalid' });
    const forged = tok.replace(/^\d+/, String(NOW - 10 * 60000));
    expect(verifyFormToken(KEY, 'e', 'ev1', forged, NOW + 5000)).toEqual({ ok: false, reason: 'invalid' });
    expect(verifyFormToken(KEY, 'e', 'ev1', undefined, NOW)).toEqual({ ok: false, reason: 'invalid' });
  });

  test('capabilities for the return page and the pay link', () => {
    expect(checkSig(returnSig(KEY, 'o1'), returnSig(KEY, 'o1'))).toBe(true);
    expect(checkSig(returnSig(KEY, 'o1'), returnSig(KEY, 'o2'))).toBe(false);
    expect(checkSig(paySig(KEY, 'b1'), returnSig(KEY, 'b1'))).toBe(false);
    expect(checkSig(paySig(KEY, 'b1'), undefined)).toBe(false);
  });

  test('origin: our hosts only; Referer fallback when Origin is stripped', () => {
    expect(originAllowed('https://greengo-chat.web.app', undefined)).toBe(true);
    expect(originAllowed('https://evil.example', 'https://greengo-chat.web.app/guest/e/1')).toBe(false);
    expect(originAllowed(undefined, 'https://greengo-chat.web.app/guest/e/1')).toBe(true);
    expect(originAllowed('null', 'https://evil.example/')).toBe(false);
    expect(originAllowed(undefined, undefined)).toBe(false);
    expect(originAllowed('https://fn.example', undefined, ['https://fn.example'])).toBe(true);
  });

  test('routes', () => {
    expect(parseGuestPath('/guest/e/abc_1')).toEqual({ route: 'listing', kind: 'e', id: 'abc_1' });
    expect(parseGuestPath('/x/abc')).toEqual({ route: 'listing', kind: 'x', id: 'abc' });
    expect(parseGuestPath('/guest/a/abc')).toEqual({ route: 'listing', kind: 'a', id: 'abc' });
    expect(parseGuestPath('/guest/done/o1')).toEqual({ route: 'done', id: 'o1' });
    expect(parseGuestPath('/guest/pay/bk_1')).toEqual({ route: 'pay', id: 'bk_1' });
    expect(parseGuestPath('/guest/u/abc')).toBeNull(); // profiles are never a guest page
    expect(parseGuestPath('/guest/c/abc')).toBeNull();
    expect(parseGuestPath('/guest/e/a%2Fb')).toBeNull();
    expect(parseGuestPath('/guest/e/abc/extra')).toBeNull();
    expect(parseGuestPath('/guest/e/%E0%A4%A')).toBeNull();
  });

  test('rate-limit keys are hashed; client IP source order', () => {
    expect(rateKey('email', 'a@b.co')).toMatch(/^[0-9a-f]{40}$/);
    expect(rateKey('email', 'a@b.co')).not.toBe(rateKey('ip', 'a@b.co'));
    expect(clientIp({ 'fastly-client-ip': '1.2.3.4', 'x-forwarded-for': '5.6.7.8' })).toBe('1.2.3.4');
    expect(clientIp({ 'x-forwarded-for': '5.6.7.8, 9.9.9.9' })).toBe('5.6.7.8');
    expect(clientIp({}, '7.7.7.7')).toBe('7.7.7.7');
  });
});

// ─────────────────────────────────────────────────────────── pages

const view = (patch: Partial<ListingView> = {}): ListingView => ({
  kind: 'e', id: 'ev1', locale: 'en', title: XSS, description: XSS, imageUrl: 'https://x.example/a.jpg?a=1&b="2"',
  facts: [[XSS, XSS]], seatsLeft: 3, notice: null, error: XSS,
  values: { firstName: XSS, lastName: XSS, email: XSS },
  form: { mode: 'pay', action: '/guest/e/ev1', token: XSS, quantityMax: 2, provider: 'Stripe' },
  ...patch,
});

describe('guest pages (HTML)', () => {
  test('every user-controlled value is escaped; no script at all', () => {
    const html = renderListingPage(view());
    expect(html).not.toContain('<script');
    expect(html).not.toContain(XSS);
    expect(html).toContain('&lt;script&gt;alert(1)&lt;/script&gt;&quot;&#39;&amp;');
    expect(html).toContain('a=1&amp;b=&quot;2&quot;');
    expect(html).toContain('name="firstName"');
    expect(html).toContain('name="email"');
    expect(html).toContain('name="consent"');
    expect(html).toContain('name="website"'); // honeypot
    expect(html).toContain('<option value="2">2</option>');
    expect(html).toContain('3 places left');
    expect(html).toContain('noindex');
  });

  test('read-only when booking is not allowed; attractions get no form', () => {
    const ro = renderListingPage(view({ form: null, error: null, notice: gt('en', 'guest.notice.notAllowed') }));
    expect(ro).not.toContain('<form');
    expect(ro).toContain('Open it in the GreenGo app');
    const a = renderListingPage(view({ kind: 'a', form: null, error: null, seatsLeft: null }));
    expect(a).not.toContain('<form');
    expect(a).toContain('Discover more places');
  });

  test('ticket types, experience slots and party size', () => {
    const t = renderListingPage(view({ form: { mode: 'pay', action: '/a', token: 't', types: [{ id: 'vip', label: 'VIP · €20', max: 2 }] } }));
    expect(t).toContain('name="qty_vip"');
    const x = renderListingPage(view({
      kind: 'x', form: { mode: 'request', action: '/a', token: 't', slots: [{ value: 'r_1', label: 'Sat' }], partyMin: 2, partyMax: 3 },
    }));
    expect(x).toContain('name="slot"');
    expect(x).toContain('<option value="2" selected>2</option>');
    expect(x).not.toContain('<option value="1"');
    expect(x).toContain('Send booking request');
  });

  test('localized (7 languages) and the consent links are real anchors', () => {
    const de = renderListingPage(view({ locale: 'de', error: null }));
    expect(de).toContain('<html lang="de">');
    expect(de).toContain('Als Gast buchen');
    expect(de).toContain('<a href="https://greengochat.com/terms"');
    const ptBR = renderListingPage(view({ locale: 'pt_BR', error: null }));
    expect(ptBR).toContain('<html lang="pt-BR">');
    expect(ptBR).toContain('Sobrenome');
  });

  test('redirect / message / pay / unavailable pages escape too', () => {
    const r = renderRedirectPage('en', 'https://checkout.stripe.com/c/pay/cs_1#a"b');
    expect(r).toContain('url=https://checkout.stripe.com/c/pay/cs_1#a&quot;b');
    expect(r).not.toContain('<script');
    expect(renderMessagePage('en', XSS, XSS)).not.toContain(XSS);
    expect(renderMessagePage('en', 'T', 'M', { refreshSeconds: 5 })).toContain('http-equiv="refresh" content="5"');
    const p = renderPayPage('en', { title: XSS, facts: [], action: '/guest/pay/b1', sig: XSS, provider: 'Stripe' });
    expect(p).not.toContain(XSS);
    expect(renderUnavailablePage('fr')).toContain('Cette page n’est pas disponible');
  });

  test('security headers: CSP without scripts, no framing, never cached', () => {
    expect(GUEST_SECURITY_HEADERS['Content-Security-Policy']).toContain("default-src 'none'");
    expect(GUEST_SECURITY_HEADERS['Content-Security-Policy']).not.toContain('script-src');
    expect(GUEST_SECURITY_HEADERS['Content-Security-Policy']).toContain("frame-ancestors 'none'");
    expect(GUEST_SECURITY_HEADERS['Cache-Control']).toBe('private, no-store');
  });
});

describe('shared-link landing (two choices)', () => {
  const ev = { title: XSS, status: 'published', visibility: 'public', startDate: ts(NOW + 1e7) };

  test('guest landing: both choices, no automatic redirect', () => {
    const p = { ...buildEventPreview('ev1', ev, NOW, 'it'), guestLanding: true };
    const html = renderHtml(p);
    expect(html).toContain('id="guest"');
    expect(html).toContain('https://greengo-chat.web.app/guest/e/ev1?hl=it');
    expect(html).toContain('Continua come ospite');
    expect(html).toContain('Apri nell’app GreenGo');
    expect(html).toContain('if (true)');
    expect(html).not.toContain(XSS);
  });

  test('without the flag the landing behaves as before', () => {
    const html = renderHtml(buildEventPreview('ev1', ev, NOW, 'en'));
    expect(html).not.toContain('id="guest"');
    expect(html).toContain('id="web"');
    expect(html).toContain('if (false)');
  });
});

// ─────────────────────────────────────────────────────────── service helpers

describe('guest service helpers', () => {
  test('refusal reasons map to guest messages', () => {
    expect(errorKeyFor('sold_out')).toBe('guest.err.soldOut');
    expect(errorKeyFor('ticket_limit_reached')).toBe('guest.err.ticketLimit');
    expect(errorKeyFor('ticket_type_limit_reached')).toBe('guest.err.limit');
    expect(errorKeyFor('attendee_names_required')).toBe('guest.err.attendeeNames');
    expect(errorKeyFor('time_taken')).toBe('guest.err.slot');
    expect(errorKeyFor('organizer_payments_not_ready')).toBe('guest.err.payment');
    expect(errorKeyFor('guest_instant_only')).toBe('guest.err.unavailable');
    expect(errorKeyFor('anything')).toBe('guest.err.unavailable');
  });

  test('only provider-hosted checkout URLs are followed', () => {
    expect(isProviderCheckoutUrl('https://checkout.stripe.com/c/pay/cs_test_1')).toBe(true);
    expect(isProviderCheckoutUrl('https://www.mercadopago.com.br/checkout/v1/redirect?pref_id=1')).toBe(true);
    expect(isProviderCheckoutUrl('https://sandbox.mercadopago.com.ar/checkout')).toBe(true);
    expect(isProviderCheckoutUrl('http://checkout.stripe.com/x')).toBe(false);
    expect(isProviderCheckoutUrl('https://stripe.com.evil.example/x')).toBe(false);
    expect(isProviderCheckoutUrl('javascript:alert(1)')).toBe(false);
    expect(isProviderCheckoutUrl(undefined)).toBe(false);
  });

  test('ticket choice: types or quantity, bounded', () => {
    expect(parseEventChoice({})).toEqual({ quantity: 1 });
    expect(parseEventChoice({ quantity: '3' })).toEqual({ quantity: 3 });
    expect(parseEventChoice({ quantity: '0' })).toBeNull();
    expect(parseEventChoice({ quantity: '99' })).toBeNull();
    expect(parseEventChoice({ qty_vip: '2', qty_std: '0' })).toEqual({ items: [{ typeId: 'vip', qty: 2 }] });
    expect(parseEventChoice({ qty_vip: '6', qty_std: '6' })).toBeNull();
    expect(parseEventChoice({ qty_vip: '-1' })).toBeNull();
  });

  test('slot choice', () => {
    expect(parseSlotChoice('r_1767225600000')).toEqual({ slotId: 'recurring', startAt: 1767225600000 });
    expect(parseSlotChoice('s_slot_1')).toEqual({ slotId: 'slot_1' });
    expect(parseSlotChoice('r_abc')).toBeNull();
    expect(parseSlotChoice('s_../x')).toBeNull();
    expect(parseSlotChoice(undefined)).toBeNull();
  });
});

// ─────────────────────────────────────────────────────────── free RSVP (mocked Firestore)

type Doc = Record<string, any> | undefined;

function fakeDb(store: Map<string, Doc>) {
  const ref = (path: string): any => ({
    path,
    collection: (c: string) => ({ doc: (id: string) => ref(`${path}/${c}/${id}`) }),
  });
  const writes: Array<[string, string, Doc]> = [];
  const db: any = {
    collection: (c: string) => ({ doc: (id: string) => ref(`${c}/${id}`) }),
    runTransaction: async (fn: (tx: any) => Promise<unknown>) => {
      const staged: Array<[string, string, Doc]> = [];
      const tx = {
        get: async (r: any) => ({ exists: store.get(r.path) !== undefined, data: () => store.get(r.path) }),
        set: (r: any, d: Doc) => staged.push(['set', r.path, d]),
        update: (r: any, d: Doc) => staged.push(['update', r.path, d]),
      };
      const out = await fn(tx);
      for (const w of staged) {
        writes.push(w);
        store.set(w[1], w[0] === 'update' ? { ...(store.get(w[1]) || {}), ...w[2] } : w[2]);
      }
      return out;
    },
  };
  return { db, writes };
}

describe('free event RSVP for a guest (transaction)', () => {
  const realDb = guestDeps.db;
  afterEach(() => { guestDeps.db = realDb; });
  const KEY_G = guestKeyFor('s', 'ana@example.com');
  const input = { firstName: 'Ana', lastName: 'Souza', email: 'ana@example.com' };

  test('takes a seat and writes a guest attendee (name only, no photo, no e-mail)', async () => {
    const store = new Map<string, Doc>([['events/ev1', publicEvent()]]);
    const { db, writes } = fakeDb(store);
    guestDeps.db = () => db;
    await expect(registerGuestForFreeEvent('ev1', KEY_G, input, NOW)).resolves.toBe('registered');
    const att = store.get(`events/ev1/attendees/${KEY_G}`)!;
    expect(att).toMatchObject({ userId: KEY_G, userName: 'Ana Souza', userPhotoUrl: null, status: 'going', isGuest: true, ticketCount: 1 });
    expect(JSON.stringify(att)).not.toContain('@');
    expect(store.get('events/ev1')!.attendeeCount).toBe(4);
    expect(writes).toHaveLength(2);
  });

  test('idempotent: a second submit does not take another seat', async () => {
    const store = new Map<string, Doc>([['events/ev1', publicEvent()]]);
    const { db } = fakeDb(store);
    guestDeps.db = () => db;
    await registerGuestForFreeEvent('ev1', KEY_G, input, NOW);
    await expect(registerGuestForFreeEvent('ev1', KEY_G, input, NOW)).resolves.toBe('already');
    expect(store.get('events/ev1')!.attendeeCount).toBe(4);
  });

  test('stops at capacity and re-checks the host switch inside the transaction', async () => {
    const full = new Map<string, Doc>([['events/ev1', publicEvent({ attendeeCount: 10 })]]);
    guestDeps.db = () => fakeDb(full).db;
    await expect(registerGuestForFreeEvent('ev1', KEY_G, input, NOW)).rejects.toBeInstanceOf(GuestError);
    expect(full.get(`events/ev1/attendees/${KEY_G}`)).toBeUndefined();

    const off = new Map<string, Doc>([['events/ev1', publicEvent({ guestsAllowed: false })]]);
    guestDeps.db = () => fakeDb(off).db;
    await expect(registerGuestForFreeEvent('ev1', KEY_G, input, NOW)).rejects.toMatchObject({ key: 'guest.notice.notAllowed' });

    const paid = new Map<string, Doc>([['events/ev1', publicEvent({ ticketProvider: 'stripe', price: 5 })]]);
    guestDeps.db = () => fakeDb(paid).db;
    await expect(registerGuestForFreeEvent('ev1', KEY_G, input, NOW)).rejects.toBeInstanceOf(GuestError);
    const priv = new Map<string, Doc>([['events/ev1', publicEvent({ visibility: 'private' })]]);
    guestDeps.db = () => fakeDb(priv).db;
    await expect(registerGuestForFreeEvent('ev1', KEY_G, input, NOW)).rejects.toBeInstanceOf(GuestError);
  });
});

// ─────────────────────────────────────────────────────────── e-mails

describe('guest e-mails', () => {
  const G = guestKeyFor('s', 'a@b.co');
  test('booking notices: accepted online request -> pay link; declined / cancelled', () => {
    const base = { isGuest: true, guestId: G, payment: { mode: 'online', status: 'unpaid' } };
    expect(guestBookingNotice({ ...base, status: 'requested' }, { ...base, status: 'confirmed' })).toBe('pay_now');
    expect(guestBookingNotice({ ...base, status: 'requested' }, { ...base, status: 'declined' })).toBe('declined');
    expect(guestBookingNotice({ ...base, status: 'requested' }, { ...base, status: 'expired' })).toBe('declined');
    expect(guestBookingNotice({ ...base, status: 'confirmed' }, { ...base, status: 'cancelled_by_host' })).toBe('cancelled');
    expect(guestBookingNotice({ ...base, status: 'confirmed' }, { ...base, status: 'confirmed', x: 1 })).toBeNull();
    const free = { ...base, payment: { mode: 'free' } };
    expect(guestBookingNotice({ ...free, status: 'requested' }, { ...free, status: 'confirmed' })).toBeNull(); // QR e-mail covers it
    expect(guestBookingNotice({ status: 'requested' }, { status: 'confirmed', guestId: 'uid', payment: base.payment })).toBeNull();
  });

  test('order notices and event cancellation', () => {
    const o = { isGuest: true, buyerId: G };
    expect(guestOrderNotice({ ...o, status: 'paid' }, { ...o, status: 'refunded' })).toBe('refunded');
    expect(guestOrderNotice({ ...o, status: 'paid' }, { ...o, status: 'disputed' })).toBe('refunded');
    expect(guestOrderNotice({ ...o, status: 'pending' }, { ...o, status: 'paid' })).toBeNull();
    expect(guestOrderNotice({ status: 'paid', buyerId: 'uid' }, { status: 'refunded', buyerId: 'uid' })).toBeNull();
    expect(becameCancelled({ status: 'published' }, { status: 'cancelled' })).toBe(true);
    expect(becameCancelled({ status: 'cancelled' }, { status: 'cancelled' })).toBe(false);
  });

  test('notice e-mail: escaped, localized, pay link only on our host', () => {
    const m = buildGuestNotice({
      kind: 'pay_now', locale: 'es', to: 'a@b.co', title: XSS, when: 'x', where: null,
      payUrl: 'https://greengo-chat.web.app/guest/pay/bk_1?t=abc&hl=es',
    });
    expect(m.subject).toContain('Aceptada');
    expect(m.html).not.toContain(XSS);
    expect(m.html).toContain('href="https://greengo-chat.web.app/guest/pay/bk_1?t=abc&amp;hl=es"');
    const evil = buildGuestNotice({ kind: 'pay_now', locale: 'en', to: 'a@b.co', title: 'T', when: null, where: null, payUrl: 'https://evil.example/guest/pay/x' });
    expect(evil.html).not.toContain('evil.example');
    const c = buildGuestNotice({ kind: 'cancelled', locale: 'fr', to: 'a@b.co', title: 'T', when: null, where: null });
    expect(c.subject).toBe('Votre réservation pour T a été annulée');
  });
});

// ─────────────────────────────────────────────────────────── i18n table

describe('guest i18n table', () => {
  test('every key has a non-empty string in all 7 app languages', () => {
    for (const [key, row] of Object.entries(GUEST_STRINGS)) {
      for (const loc of SUPPORTED_LOCALES) {
        expect(typeof (row as any)[loc]).toBe('string');
        expect(((row as any)[loc] as string).trim().length).toBeGreaterThan(0);
        // Same {placeholders} in every language.
        const ph = (s: string) => (s.match(/\{(\w+)\}/g) || []).sort().join(',');
        expect(`${key}:${loc}:${ph((row as any)[loc])}`).toBe(`${key}:${loc}:${ph((row as any).en)}`);
      }
    }
    expect(SUPPORTED_LOCALES).toHaveLength(7);
  });

  test('plurals and unknown locales', () => {
    expect(gt('en', 'guest.page.placesLeft', { count: 1 })).toBe('1 place left');
    expect(gt('en', 'guest.page.placesLeft', { count: 5 })).toBe('5 places left');
    expect(gt('pt_BR', 'guest.page.placesLeft', { count: 2 })).toBe('Restam 2 vagas');
    expect(gt('xx', 'guest.page.soldOut')).toBe('Sold out');
  });
});

// Type-only check: the checkout hook signature guests use.
const _buyer: GuestBuyer = { firstName: 'A', lastName: 'B', returnUrl: (r, o) => `${r}${o}` };
void _buyer;
