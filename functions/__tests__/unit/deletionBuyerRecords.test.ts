/**
 * auth/deletionBuyerRecords.ts + the 'tickets' task of auth/deletionFollowups.ts
 * (privacy policy 15.2 e: purchase records are kept, but the buyer's name,
 * e-mail and account id are removed and the id is replaced by a code).
 * No network: PathFakeFirestore.
 */

import * as admin from 'firebase-admin';
import { PathFakeFirestore } from '../utils/pathFirestoreFake';
import * as b from '../../src/auth/deletionBuyerRecords';
import * as f from '../../src/auth/deletionFollowups';
import { retentionUidHash } from '../../src/auth/accountDeletion';

const NOW = new Date(Date.UTC(2026, 9, 21, 12, 0, 0));
const DAY = 24 * 3600 * 1000;
const ts = (msv: number) => admin.firestore.Timestamp.fromMillis(msv);
const UID = 'buyerUid0000000000000000001';
const OTHER = 'otherBuyer00000000000000002';
const ORG = 'organizer0000000000000000003';
const GUEST = `guest_${'a'.repeat(40)}`;
const P = retentionUidHash(UID);

let db: PathFakeFirestore;
let closed: string[];
let files: string[];

function deps(over: Partial<b.BuyerRecordsDeps> = {}): b.BuyerRecordsDeps {
  return {
    db: () => db as any,
    now: () => NOW,
    closeOpenOrder: async (id: string) => {
      closed.push(id);
      const o = db.get(`ticket_orders/${id}`);
      if (o) db.seed(`ticket_orders/${id}`, { ...o, status: 'cancelled', cancelReason: 'account_deleted', seatHeld: false });
    },
    deleteFile: async (p: string) => { files.push(p); },
    ...over,
  };
}

function order(id: string, buyerId: string, extra: Record<string, any> = {}) {
  db.seed(`ticket_orders/${id}`, {
    kind: 'event', listingId: 'ev1', buyerId, organizerId: ORG, provider: 'stripe', status: 'paid',
    quantity: 2, unitAmount: 2500, ticketSubtotal: 5000, totalAmount: 5000, feeTotal: 600, hostNet: 4400,
    currency: 'brl', title: 'Samba night', startsAt: ts(NOW.getTime() + 3 * DAY), createdAt: ts(NOW.getTime() - DAY),
    paidAt: ts(NOW.getTime() - DAY), ticketIds: [`${id}_1`, `${id}_2`],
    attendeeNames: [{ firstName: 'Ana', lastName: 'Silva' }, { firstName: 'Bia', lastName: 'Souza' }],
    providerRef: { stripeSessionId: 'cs_1', stripeAccountId: 'acct_1' },
    refund: { status: 'refunded', reason: 'event_cancelled' },
    ...extra,
  });
}

function ticket(id: string, orderId: string, buyerId: string, extra: Record<string, any> = {}) {
  db.seed(`tickets/${id}`, {
    ticketId: id, orderId, buyerId, organizerId: ORG, kind: 'event', listingId: 'ev1', status: 'valid',
    qrPayload: 'signed.qr.token', unitAmount: 2500, currency: 'brl', startsAt: ts(NOW.getTime() + 3 * DAY),
    attendeeName: 'Ana Silva', attendeeFirstName: 'Ana', attendeeLastName: 'Silva', checkedInAt: null,
    ...extra,
  });
}

beforeEach(() => {
  db = new PathFakeFirestore();
  closed = [];
  files = [];
});

describe('pure helpers', () => {
  test('replaceIds swaps values and map keys, keeps everything else', () => {
    const out = b.replaceIds({ a: UID, n: 3, arr: [UID, 'x'], m: { [UID]: 1, k: { v: UID } }, t: ts(1) }, new Set([UID]), 'P');
    expect(out).toEqual({ a: 'P', n: 3, arr: ['P', 'x'], m: { P: 1, k: { v: 'P' } }, t: ts(1) });
  });

  test('a past valid ticket keeps its status, an upcoming one is voided; QR always removed', () => {
    const past = b.pseudonymiseTicket({ buyerId: UID, status: 'valid', qrPayload: 'q', startsAt: ts(NOW.getTime() - 2 * DAY) }, new Set([UID]), P, NOW.getTime());
    expect(past.status).toBe('valid');
    expect(past.qrPayload).toBeUndefined();
    const up = b.pseudonymiseTicket({ buyerId: UID, status: 'valid', qrPayload: 'q', startsAt: ts(NOW.getTime() + DAY) }, new Set([UID]), P, NOW.getTime());
    expect(up.status).toBe('void');
    expect(up.voidReason).toBe('account_deleted');
    const used = b.pseudonymiseTicket({ buyerId: UID, status: 'used', startsAt: ts(NOW.getTime() + DAY) }, new Set([UID]), P, NOW.getTime());
    expect(used.status).toBe('used');
  });

  test('subjects: uid + valid guest keys only', () => {
    expect(b.subjectsOf(UID, { ticketGuestKeys: [GUEST, 'not-a-key', UID] })).toEqual([UID, GUEST]);
    expect(b.subjectsOf(UID, undefined)).toEqual([UID]);
  });
});

describe('pseudonymiseBuyerRecords', () => {
  test('orders, tickets, refunds and alerts keep the money fields, lose the buyer identity', async () => {
    order('o1', UID, { receiptPath: 'ticket_receipts/o1/r.jpg' });
    ticket('o1_1', 'o1', UID);
    ticket('o1_2', 'o1', UID, { startsAt: ts(NOW.getTime() - 5 * DAY), status: 'used', checkedInAt: ts(NOW.getTime() - 5 * DAY) });
    db.seed('ticket_refunds/o1', { orderId: 'o1', buyerId: UID, organizerId: ORG, amount: 5000, currency: 'brl', status: 'refunded', isGuest: false });
    db.seed('admin_alerts/ticket_refund_failed_o1', { type: 'ticket_refund_failed', orderId: 'o1', buyerId: UID, amount: 5000 });
    db.seed('ticket_holdings/event_ev1_' + UID, { uid: UID, kind: 'event', listingId: 'ev1', owned: 2, held: 0 });
    db.seed('ticket_holdings/event_ev9_' + UID, { uid: UID, kind: 'event', listingId: 'ev9', owned: 1 });
    db.seed(`events/ev1/attendee_names/${UID}`, { eventId: 'ev1', buyerId: UID, names: [{ firstName: 'Ana' }] });
    order('o2', OTHER);
    db.seed('ticket_holdings/event_ev1_' + OTHER, { uid: OTHER, owned: 2 });

    const r = await b.pseudonymiseBuyerRecords(UID, {}, deps());
    expect(r).toMatchObject({ orders: 1, tickets: 2, ticketsVoided: 1, refunds: 1, alerts: 1, holdingsDeleted: 2, attendeeNamesDeleted: 1, receiptsDeleted: 1, more: false, blocked: 0 });

    const o = db.get('ticket_orders/o1')!;
    expect(o.buyerId).toBe(P);
    expect(o.buyerDeleted).toBe(true);
    expect(o.attendeeNames).toBeNull();
    expect(o.receiptPath).toBeNull();
    // Kept for bookkeeping.
    expect(o).toMatchObject({
      organizerId: ORG, totalAmount: 5000, ticketSubtotal: 5000, feeTotal: 600, hostNet: 4400, currency: 'brl',
      status: 'paid', quantity: 2, listingId: 'ev1', refund: { status: 'refunded', reason: 'event_cancelled' },
      providerRef: { stripeSessionId: 'cs_1', stripeAccountId: 'acct_1' },
    });
    expect(o.paidAt.toMillis()).toBe(NOW.getTime() - DAY);
    expect(files).toEqual(['ticket_receipts/o1/r.jpg']);

    const t1 = db.get('tickets/o1_1')!;
    expect(t1).toMatchObject({ buyerId: P, status: 'void', attendeeName: null, attendeeFirstName: null, attendeeLastName: null, unitAmount: 2500 });
    expect(t1.qrPayload).toBeUndefined();
    const t2 = db.get('tickets/o1_2')!;
    expect(t2.status).toBe('used');
    expect(t2.checkedInAt.toMillis()).toBe(NOW.getTime() - 5 * DAY);

    expect(db.get('ticket_refunds/o1')).toMatchObject({ buyerId: P, amount: 5000, status: 'refunded', buyerDeleted: true });
    expect(db.get('admin_alerts/ticket_refund_failed_o1')).toMatchObject({ buyerId: P, amount: 5000 });
    expect(db.get('ticket_holdings/event_ev1_' + UID)).toBeUndefined();
    expect(db.get('ticket_holdings/event_ev9_' + UID)).toBeUndefined();
    expect(db.get(`events/ev1/attendee_names/${UID}`)).toBeUndefined();

    // Nothing with the uid or the names remains; others untouched.
    const all = JSON.stringify(['ticket_orders', 'tickets', 'ticket_refunds', 'admin_alerts', 'ticket_holdings']
      .flatMap((c) => db.list({ collection: c })).filter(([, d]) => d.buyerId !== OTHER && d.uid !== OTHER));
    expect(all).not.toContain(UID);
    expect(all).not.toMatch(/Ana|Silva|Souza|signed\.qr/);
    expect(db.get('ticket_orders/o2')!.buyerId).toBe(OTHER);
    expect(db.get('ticket_holdings/event_ev1_' + OTHER)).toBeDefined();
  });

  test('the pseudonym is stable per user and equals retention_finance.uidHash', async () => {
    order('o1', UID);
    order('o3', UID, { listingId: 'ev2' });
    await b.pseudonymiseBuyerRecords(UID, {}, deps());
    expect(db.get('ticket_orders/o1')!.buyerId).toBe(db.get('ticket_orders/o3')!.buyerId);
    expect(db.get('ticket_orders/o1')!.buyerId).toBe(retentionUidHash(UID));
    expect(P).toMatch(/^[0-9a-f]{64}$/);
  });

  test('idempotent: a second run changes nothing', async () => {
    order('o1', UID);
    ticket('o1_1', 'o1', UID);
    await b.pseudonymiseBuyerRecords(UID, {}, deps());
    const snapshot = JSON.stringify([db.get('ticket_orders/o1'), db.get('tickets/o1_1')]);
    const r2 = await b.pseudonymiseBuyerRecords(UID, {}, deps());
    expect(r2).toMatchObject({ orders: 0, tickets: 0, refunds: 0, more: false });
    expect(JSON.stringify([db.get('ticket_orders/o1'), db.get('tickets/o1_1')])).toBe(snapshot);
  });

  test('open orders are closed first (seat released), then pseudonymised', async () => {
    order('o1', UID, { status: 'pending', seatHeld: true });
    const r = await b.pseudonymiseBuyerRecords(UID, {}, deps());
    expect(closed).toEqual(['o1']);
    expect(r.openOrdersClosed).toBe(1);
    expect(db.get('ticket_orders/o1')).toMatchObject({ status: 'cancelled', cancelReason: 'account_deleted', buyerId: P });
  });

  test('an order that stays open is left alone and reported as blocked', async () => {
    order('o1', UID, { status: 'pending' });
    const r = await b.pseudonymiseBuyerRecords(UID, {}, deps({ closeOpenOrder: async () => undefined }));
    expect(r.blocked).toBe(1);
    expect(db.get('ticket_orders/o1')!.buyerId).toBe(UID);
  });

  test('bounded: stops after MAX_PAGES pages with more=true, the next run resumes from the source', async () => {
    const n = b.PAGE * b.MAX_PAGES + 5;
    for (let i = 0; i < n; i++) db.seed(`tickets/t${i}`, { buyerId: UID, status: 'used', currency: 'brl', unitAmount: 1 });
    const r1 = await b.pseudonymiseBuyerRecords(UID, {}, deps());
    expect(r1.more).toBe(true);
    expect(r1.tickets).toBe(b.PAGE * b.MAX_PAGES);
    const r2 = await b.pseudonymiseBuyerRecords(UID, {}, deps());
    expect(r2.more).toBe(false);
    expect(r2.tickets).toBe(5);
    expect(db.list({ collection: 'tickets' }).every(([, d]) => d.buyerId === P)).toBe(true);
  });

  test('guest purchases of the verified e-mail: pseudonymised with the account; contact, roster and booking names removed', async () => {
    order('g1', GUEST, { isGuest: true, guest: { firstName: 'Ana', lastName: 'Silva' }, guestName: 'Ana Silva' });
    ticket('g1_1', 'g1', GUEST);
    db.seed(`guest_contacts/${GUEST}`, { email: 'ana@example.com', locale: 'pt' });
    db.seed('events/ev1', { attendeeCount: 5 });
    db.seed(`events/ev1/attendees/${GUEST}`, { userId: GUEST, userName: 'Ana Silva', isGuest: true, status: 'going', guestCount: 0 });
    db.seed(`events/ev1/attendee_names/${GUEST}`, { buyerId: GUEST, names: [] });
    db.seed('bookings/bk1', { guestId: GUEST, hostId: ORG, isGuest: true, guest: { firstName: 'Ana', lastName: 'Silva' }, guestName: 'Ana Silva', price: { amount: 100 } });

    const r = await b.pseudonymiseBuyerRecords(UID, { ticketGuestKeys: [GUEST] }, deps());
    expect(r).toMatchObject({ guestKeys: 1, orders: 1, tickets: 1, guestContactsDeleted: 1, guestAttendeesDeleted: 1, guestBookings: 1 });
    const o = db.get('ticket_orders/g1')!;
    expect(o.buyerId).toBe(P);
    expect(o.guest).toBeUndefined();
    expect(o.guestName).toBeUndefined();
    expect(o.isGuest).toBe(true);
    expect(db.get('tickets/g1_1')!.buyerId).toBe(P);
    expect(db.get(`guest_contacts/${GUEST}`)).toBeUndefined();
    expect(db.get(`events/ev1/attendees/${GUEST}`)).toBeUndefined();
    expect(db.get('events/ev1')!.attendeeCount).toBe(4);
    expect(db.get(`events/ev1/attendee_names/${GUEST}`)).toBeUndefined();
    const bk = db.get('bookings/bk1')!;
    expect(bk).toMatchObject({ guestId: 'deleted_user', hostId: ORG, price: { amount: 100 } });
    expect(bk.guestName).toBeUndefined();
    expect(bk.guest).toBeUndefined();
    const dump = JSON.stringify([...db.list({ collection: 'ticket_orders' }), ...db.list({ collection: 'tickets' }), ...db.list({ collection: 'bookings' })]);
    expect(dump).not.toMatch(new RegExp(`${GUEST}|Ana|Silva|example\\.com`));
  });

  test('guest orders of an e-mail that was NOT linked (no guest key on the follow-up) are untouched', async () => {
    order('g1', GUEST, { isGuest: true, guestName: 'Someone Else' });
    await b.pseudonymiseBuyerRecords(UID, {}, deps());
    expect(db.get('ticket_orders/g1')).toMatchObject({ buyerId: GUEST, guestName: 'Someone Else' });
  });
});

describe("follow-up task 'tickets'", () => {
  function fdeps(over: Partial<b.BuyerRecordsDeps> = {}): f.FollowupDeps {
    return { stripe: () => null, now: () => NOW, db: () => db as any, buyerRecords: () => deps(over) };
  }

  test('pending -> done, counts stored (no ids), guest keys dropped', async () => {
    order('o1', UID);
    db.seed(`deletion_followups/${UID}`, { ticketsStatus: 'pending', tickets: true, ticketGuestKeys: [GUEST] });
    expect(f.isTaskDue(db.get(`deletion_followups/${UID}`), 'tickets', NOW)).toBe(true);
    expect(await f.processTicketsFollowup(UID, fdeps())).toBe('done');
    const d = db.get(`deletion_followups/${UID}`)!;
    expect(d.ticketsStatus).toBe('done');
    expect(d.ticketsResult.orders).toBe(1);
    expect(d.ticketGuestKeys).toBeUndefined();
    expect(db.get('ticket_orders/o1')!.buyerId).toBe(P);
    // Done is final: not picked up again.
    expect(f.isTaskDue(d, 'tickets', NOW)).toBe(false);
  });

  test('bounds hit -> back to pending without counting an attempt', async () => {
    for (let i = 0; i < b.PAGE * b.MAX_PAGES + 1; i++) db.seed(`tickets/t${i}`, { buyerId: UID, status: 'used' });
    db.seed(`deletion_followups/${UID}`, { ticketsStatus: 'pending' });
    expect(await f.processTicketsFollowup(UID, fdeps())).toBe('pending');
    const d = db.get(`deletion_followups/${UID}`)!;
    expect(d.ticketsStatus).toBe('pending');
    expect(d.ticketsAttempts).toBeUndefined();
    expect(await f.processTicketsFollowup(UID, fdeps())).toBe('done');
  });

  test('an order that cannot be closed -> retry with backoff', async () => {
    order('o1', UID, { status: 'pending' });
    db.seed(`deletion_followups/${UID}`, { ticketsStatus: 'pending' });
    expect(await f.processTicketsFollowup(UID, fdeps({ closeOpenOrder: async () => undefined }))).toBe('retry');
    const d = db.get(`deletion_followups/${UID}`)!;
    expect(d.ticketsAttempts).toBe(1);
    expect(String(d.ticketsLastError)).toMatch(/open_orders_pending/);
  });

  test('docs written before the task existed (no ticketsStatus) are not run', () => {
    expect(f.isTaskDue({ stripeStatus: 'done' }, 'tickets', NOW)).toBe(false);
  });
});

describe('organiser views of a deleted buyer / guest', () => {
  test('participants CSV shows the localized "Deleted user"', () => {
    const { buildParticipantsCsv } = require('../../src/emails/participantsList');
    const row = { name: '', email: '', bookingCode: 'GG-1', ticket: '1', status: 'paid', deletedUser: true };
    expect(buildParticipantsCsv('de', [row])).toContain('Gelöschter Nutzer');
    expect(buildParticipantsCsv('en', [row])).toContain('Deleted user');
    expect(buildParticipantsCsv('en', [{ ...row, deletedUser: false, name: 'Ana' }])).not.toContain('Deleted user');
  });
});
