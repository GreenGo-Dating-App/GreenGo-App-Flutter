/**
 * Buyer <-> organizer chat (entitlements/listingChat.ts, 2026-10-17): the
 * server-side buyer exemption, the connect-counter skip and the e-mail link.
 */
jest.mock('firebase-functions/v2/firestore', () => ({
  onDocumentCreated: (_o: any, h: any) => h,
  onDocumentWritten: (_o: any, h: any) => h,
  onDocumentUpdated: (_o: any, h: any) => h,
}));
jest.mock('firebase-functions/v2/https', () => ({
  onCall: (_o: any, h: any) => h,
  onRequest: (_o: any, h: any) => h,
  HttpsError: class extends Error {
    code: string;
    constructor(code: string, message: string) { super(message); this.code = code; }
  },
}));
jest.mock('../../src/shared/firebaseAdmin', () => ({}));
jest.mock('../../src/shared/monitoring', () => ({ monitored: (_n: string, h: any) => h }));
jest.mock('../../src/shared/utils', () => ({ logInfo: jest.fn() }));
jest.mock('../../src/guest/guestKeys', () => ({ guestIdentitySecret: async () => 'test-secret' }));

// ---- tiny in-memory Firestore ----------------------------------------------
const store = new Map<string, Record<string, any>>();
let autoId = 0;
const SERVER_TS = { __serverTimestamp: true };
const DELETE = { __delete: true };
function docRef(path: string): any {
  return {
    id: path.split('/').pop(),
    path,
    get: async () => snap(path),
    collection: (name: string) => colRef(`${path}/${name}`),
  };
}
function snap(path: string): any {
  const d = store.get(path);
  return { id: path.split('/').pop(), ref: docRef(path), exists: !!d, data: () => (d ? { ...d } : undefined) };
}
function colRef(path: string, filters: Array<[string, any]> = [], lim = 1000): any {
  const run = () => {
    const docs = [...store.keys()]
      .filter((k) => k.startsWith(`${path}/`) && !k.slice(path.length + 1).includes('/'))
      .map((k) => snap(k))
      .filter((s) => filters.every(([f, v]) => s.data()[f] === v))
      .slice(0, lim);
    return { docs, size: docs.length, empty: docs.length === 0 };
  };
  return {
    doc: (id?: string) => docRef(`${path}/${id ?? `auto${++autoId}`}`),
    where: (f: string, _op: string, v: any) => colRef(path, [...filters, [f, v]], lim),
    limit: (n: number) => colRef(path, filters, n),
    get: async () => run(),
    __run: run,
  };
}
function applyUpdate(path: string, patch: Record<string, any>) {
  const cur = { ...(store.get(path) || {}) };
  for (const [k, v] of Object.entries(patch)) {
    if (k.includes('.')) {
      const [a, b] = k.split('.');
      const inner = { ...(cur[a] || {}) };
      if (v === DELETE) delete inner[b]; else inner[b] = v;
      cur[a] = inner;
    } else cur[k] = v;
  }
  store.set(path, cur);
}
const fakeDb: any = {
  collection: (name: string) => colRef(name),
  runTransaction: async (fn: any) => fn({
    get: async (q: any) => (q.__run ? q.__run() : q.get()),
    set: (ref: any, data: any) => store.set(ref.path, { ...data }),
    update: (ref: any, data: any) => applyUpdate(ref.path, data),
  }),
};
jest.mock('firebase-admin', () => {
  const Timestamp = {
    fromMillis: (ms: number) => ({ toMillis: () => ms, __ms: ms }),
    now: () => ({ toMillis: () => Date.now(), __ms: Date.now() }),
  };
  const firestore = Object.assign(() => fakeDb, {
    FieldValue: { serverTimestamp: () => SERVER_TS, delete: () => DELETE },
    Timestamp,
    FieldPath: { documentId: () => '__name__' },
  });
  return { firestore, apps: [{}], initializeApp: jest.fn() };
});

import {
  bookingBuyerSlot, handleOpenListingChat, isBusinessOrganizer, isGoingAttendee, listingChatMatchId,
  listingInfoOf, parseListingChatRequest,
} from '../../src/entitlements/listingChat';
import { isBuyerChatConversation, onConversationCreatedCountConnect } from '../../src/entitlements/usage';
import { buildBookingEmail, buildTicketEmail, emailChatLink, listingChatUrl } from '../../src/emails/ticketEmails';
import { guestKeyFor } from '../../src/shared/guestIdentity';
import { genericPreview, renderHtml, webAppUrl } from '../../src/share/sharePreviewCore';

const BUYER = 'buyerUid000000000000000001';
const ORG = 'organizerUid0000000000001';
const NOW = Date.now();
const DAY = 86_400_000;

beforeEach(() => {
  store.clear();
  autoId = 0;
  store.set(`events/ev1`, { organizerId: ORG, title: 'Samba night', startDate: { toMillis: () => NOW + DAY } });
  store.set(`user_experiences/x1`, { hostId: ORG, title: 'Cooking class' });
  store.set(`profiles/${ORG}`, { userId: ORG, isBusiness: false });
});

describe('pure helpers', () => {
  test('request validation', () => {
    expect(parseListingChatRequest({ type: 'event', id: 'ev1' })).toEqual({ type: 'event', id: 'ev1' });
    for (const bad of [null, {}, { type: 'group', id: 'a' }, { type: 'event', id: 'a/b' }, { type: 'event', id: '' }]) {
      expect(() => parseListingChatRequest(bad)).toThrow();
    }
  });

  test('matchId mirrors the app (sorted personal / directional business)', () => {
    expect(listingChatMatchId('b', 'a', false)).toBe('search_a_b');
    expect(listingChatMatchId('a', 'b', false)).toBe('search_a_b');
    expect(listingChatMatchId('cust', 'owner', true)).toBe('bizsearch_owner_cust');
  });

  test('organizer of events and experiences; business storefront detection', () => {
    expect(listingInfoOf('event', { organizerId: 'o', title: ' T ' })).toEqual({ organizerId: 'o', title: 'T', startMs: null });
    expect(listingInfoOf('experience', { hostId: 'h', title: 'X' })?.organizerId).toBe('h');
    expect(listingInfoOf('event', { title: 'no organizer' })).toBeNull();
    expect(isBusinessOrganizer({ isBusiness: true, businessName: 'Café' })).toBe(true);
    expect(isBusinessOrganizer({ isBusiness: true, businessName: ' ' })).toBe(false);
    expect(isBusinessOrganizer({ isBusiness: false, businessName: 'Café' })).toBe(false);
  });

  test('buyer = going attendee with a valid ticket, or a confirmed / completed booking', () => {
    expect(isGoingAttendee({ status: 'going', ticketStatus: 'valid' })).toBe(true);
    expect(isGoingAttendee({ status: 'going' })).toBe(true); // free RSVP
    expect(isGoingAttendee({ status: 'going', ticketStatus: 'refunded' })).toBe(false);
    expect(isGoingAttendee({ status: 'interested' })).toBe(false);
    expect(isGoingAttendee({ status: 'going', isApproved: false })).toBe(false);
    expect(bookingBuyerSlot([{ status: 'requested' }, { status: 'cancelled_by_guest' }], NOW).buyer).toBe(false);
    const r = bookingBuyerSlot([
      { status: 'completed', slotStart: { toMillis: () => NOW - DAY } },
      { status: 'confirmed', slotStart: { toMillis: () => NOW + 2 * DAY } },
    ], NOW);
    expect(r).toEqual({ buyer: true, startMs: NOW + 2 * DAY });
  });

  test('only a buyer context is skipped by the connect counter', () => {
    expect(isBuyerChatConversation({ context: { buyer: true } })).toBe(true);
    expect(isBuyerChatConversation({ context: { type: 'event' } })).toBe(false);
    expect(isBuyerChatConversation({})).toBe(false);
  });
});

describe('openListingChat (server-side buyer exemption)', () => {
  test('before buying: no write, buyer false (the app uses the normal capped flow)', async () => {
    const r: any = await handleOpenListingChat(BUYER, {}, { type: 'event', id: 'ev1' });
    expect(r.buyer).toBe(false);
    expect(r.organizerId).toBe(ORG);
    expect(r.matchId).toBe(listingChatMatchId(BUYER, ORG, false));
    expect(r.context).toMatchObject({ type: 'event', id: 'ev1', title: 'Samba night', startAt: NOW + DAY });
    expect(r.context.buyer).toBeUndefined();
    expect([...store.keys()].some((k) => k.startsWith('conversations/'))).toBe(false);
  });

  test('ticket holder: conversation created server-side with a verified buyer context', async () => {
    store.set(`events/ev1/attendees/${BUYER}`, { status: 'going', ticketStatus: 'valid' });
    const r: any = await handleOpenListingChat(BUYER, {}, { type: 'event', id: 'ev1' });
    expect(r.buyer).toBe(true);
    const conv = store.get(`conversations/${r.conversationId}`)!;
    expect(conv).toMatchObject({ userId1: BUYER, userId2: ORG, matchId: r.matchId, conversationType: 'search' });
    expect(conv.context).toMatchObject({ type: 'event', id: 'ev1', buyer: true, buyerId: BUYER });
  });

  test('existing conversation: context updated to the latest topic, same conversation (history kept)', async () => {
    const matchId = listingChatMatchId(BUYER, ORG, false);
    store.set('conversations/old', { matchId, userId1: ORG, userId2: BUYER, context: { type: 'event', id: 'other' }, deletedFor: { [BUYER]: 1 } });
    store.set('bookings/b1', { guestId: BUYER, experienceId: 'x1', status: 'confirmed', slotStart: { toMillis: () => NOW + DAY } });
    const r: any = await handleOpenListingChat(BUYER, {}, { type: 'experience', id: 'x1' });
    expect(r).toMatchObject({ buyer: true, conversationId: 'old' });
    const conv = store.get('conversations/old')!;
    expect(conv.context).toMatchObject({ type: 'experience', id: 'x1', title: 'Cooking class', buyer: true });
    expect(conv.deletedFor[BUYER]).toBeUndefined();
    expect([...store.keys()].filter((k) => k.startsWith('conversations/'))).toEqual(['conversations/old']);
  });

  test('a requested (not confirmed) booking is not a buyer', async () => {
    store.set('bookings/b1', { guestId: BUYER, experienceId: 'x1', status: 'requested' });
    const r: any = await handleOpenListingChat(BUYER, {}, { type: 'experience', id: 'x1' });
    expect(r.buyer).toBe(false);
  });

  test('business organizer -> business inquiry conversation', async () => {
    store.set(`profiles/${ORG}`, { isBusiness: true, businessName: 'Bar Samba' });
    store.set(`events/ev1/attendees/${BUYER}`, { status: 'going' });
    const r: any = await handleOpenListingChat(BUYER, {}, { type: 'event', id: 'ev1' });
    expect(r.businessInquiry).toBe(true);
    expect(r.matchId).toBe(`bizsearch_${ORG}_${BUYER}`);
    expect(store.get(`conversations/${r.conversationId}`)!.businessInquiry).toBe(true);
  });

  test('guest purchase with the same VERIFIED e-mail counts; unverified does not', async () => {
    const key = guestKeyFor('test-secret', 'Ana@Example.com');
    store.set(`events/ev1/attendees/${key}`, { status: 'going', isGuest: true });
    const unverified: any = await handleOpenListingChat(BUYER, { email: 'ana@example.com', email_verified: false }, { type: 'event', id: 'ev1' });
    expect(unverified.buyer).toBe(false);
    const verified: any = await handleOpenListingChat(BUYER, { email: 'ana@example.com', email_verified: true }, { type: 'event', id: 'ev1' });
    expect(verified.buyer).toBe(true);
  });

  test('organizer of the listing, blocked pairs and missing listings are refused', async () => {
    await expect(handleOpenListingChat(ORG, {}, { type: 'event', id: 'ev1' })).rejects.toMatchObject({ code: 'failed-precondition' });
    store.set(`block_index/${ORG}_${BUYER}`, {});
    await expect(handleOpenListingChat(BUYER, {}, { type: 'event', id: 'ev1' })).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(handleOpenListingChat(BUYER, {}, { type: 'event', id: 'nope' })).rejects.toMatchObject({ code: 'not-found' });
  });

  test('the connect counter skips a buyer conversation and counts a normal one', async () => {
    store.set(`profiles/${BUYER}`, { membershipTier: 'FREE' });
    const ev = (data: any) => ({ data: { id: 'c', data: () => data, ref: { delete: jest.fn() } } });
    await (onConversationCreatedCountConnect as any)(ev({ userId1: BUYER, userId2: ORG, context: { buyer: true } }));
    expect(store.get(`entitlement_usage/${BUYER}`)).toBeUndefined();
    await (onConversationCreatedCountConnect as any)(ev({ userId1: BUYER, userId2: ORG }));
    expect(store.get(`entitlement_usage/${BUYER}`)?.connectCount).toBe(1);
  });
});

describe('email "Ask the organizer" / "Message the host" link', () => {
  test('members get the listing universal link with ?chat=1', () => {
    expect(listingChatUrl('event', 'ev1', false)).toBe('https://greengo-chat.web.app/e/ev1?chat=1');
    expect(listingChatUrl('experience', 'x1', false)).toBe('https://greengo-chat.web.app/x/x1?chat=1');
    const c = emailChatLink('en', 'event', 'ev1', BUYER)!;
    expect(c).toEqual({ url: 'https://greengo-chat.web.app/e/ev1?chat=1', label: 'Ask the organizer', hint: null });
    expect(emailChatLink('en', 'experience', 'x1', BUYER)!.label).toBe('Message the host');
    expect(emailChatLink('en', 'event', 'a/b', BUYER)).toBeNull();
  });

  test('guests get the web app hand-off and the free-account invite', () => {
    const key = guestKeyFor('s', 'g@example.com');
    const c = emailChatLink('en', 'event', 'ev1', key)!;
    expect(c.url).toBe(`https://greengo-chat.web.app/?link=${encodeURIComponent('/e/ev1?chat=1')}`);
    expect(c.hint).toBe('Create a free account to message the organizer.');
    expect(emailChatLink('pt_BR', 'experience', 'x1', key)!.hint).toBe('Crie uma conta grátis para mandar mensagem ao anfitrião.');
  });

  test('ticket email carries the button in HTML and text; absent without a link', () => {
    const base = {
      locale: 'en', to: 'a@b.c', title: 'Samba', when: 'Fri', where: null, ticketType: null, partySize: null,
      bookingCode: 'GG-1', qrs: [],
    };
    const withLink = buildTicketEmail({ ...base, chat: emailChatLink('en', 'event', 'ev1', BUYER) });
    expect(withLink.html).toContain('href="https://greengo-chat.web.app/e/ev1?chat=1"');
    expect(withLink.html).toContain('Ask the organizer');
    expect(withLink.text).toContain('Ask the organizer: https://greengo-chat.web.app/e/ev1?chat=1');
    const without = buildTicketEmail(base);
    expect(without.html).not.toContain('chat=1');
  });

  test('booking emails: the guest gets the host link, the host never does', () => {
    const m = {
      locale: 'en', to: 'a@b.c', title: 'Cooking', when: 'Sat', where: null, partySize: 2,
      guestName: 'Ana', respondBy: null, payHint: null, chat: emailChatLink('en', 'experience', 'x1', BUYER),
    };
    expect(buildBookingEmail({ ...m, kind: 'request_guest' }).html).toContain('/x/x1?chat=1');
    expect(buildBookingEmail({ ...m, kind: 'confirmed_host' }).html).not.toContain('chat=1');
  });
});

test('share page keeps ?chat=1 on the app and web hand-offs (events / experiences only)', () => {
  expect(webAppUrl('e', 'ev1', true)).toBe(`https://greengo-chat.web.app/?link=${encodeURIComponent('/e/ev1?chat=1')}`);
  const html = renderHtml(genericPreview('e', 'ev1'), true);
  expect(html).toContain(encodeURIComponent('/e/ev1?chat=1'));
  expect(html).toContain('greengo://e/ev1?chat=1');
  expect(renderHtml(genericPreview('e', 'ev1'))).not.toContain('chat=1');
  expect(renderHtml(genericPreview('u', 'u1'), true)).not.toContain('chat=1');
});
