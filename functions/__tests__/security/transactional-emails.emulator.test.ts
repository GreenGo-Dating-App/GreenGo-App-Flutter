/**
 * Transactional emails against the emulators (Firestore + Auth):
 *  - ID verification submitted -> one reviewer email per submission, uid + link only
 *  - ticket order paid -> one buyer email per order (inline QR PNGs)
 *  - participants-list scheduler: 1-hour window, once per listing start
 *  - sendParticipantsList callable: organizer / co-organizer / host only, rate limit
 *  - no Resend key -> nothing sent, nothing thrown
 */
import functionsTest from 'firebase-functions-test';
import * as admin from 'firebase-admin';

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
import { db } from '../../src/shared/utils';
import { emailDeps } from '../../src/emails/sendEmail';
import { emailOnIdVerificationSubmitted } from '../../src/emails/verificationSubmittedEmail';
import { emailTicketsOnOrderPaid, emailBookingQrOnConfirm } from '../../src/emails/ticketEmails';
import { runParticipantListsDue, sendParticipantsList } from '../../src/emails/participantsList';

const TS = admin.firestore.Timestamp;
const auth = admin.auth();
const fetchMock = jest.fn(async (_url: any, _init?: any) => ({ ok: true, status: 200 }));
emailDeps.fetch = fetchMock as any;
const MIN = 60000;
let NOW = Date.UTC(2026, 10, 14, 17, 0);
emailDeps.now = () => NOW;

async function clearAll() {
  const fsHost = process.env.FIRESTORE_EMULATOR_HOST!;
  const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST!;
  for (const h of [fsHost, authHost]) {
    if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(h)) throw new Error('not an emulator');
  }
  const del = (host: string, path: string) => new Promise<void>((res, rej) => {
    const r = require('http').request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE', path,
      headers: { Authorization: 'Bearer owner' } }, (x: any) => { x.resume(); x.on('end', res); });
    r.on('error', rej); r.end();
  });
  await del(fsHost, `/emulator/v1/projects/${process.env.GCLOUD_PROJECT}/databases/(default)/documents`);
  await del(authHost, `/emulator/v1/projects/${process.env.GCLOUD_PROJECT}/accounts`);
}
const written = (fn: any, path: string, before: any, after: any, params: any) =>
  fn.run({
    data: {
      before: before ? fft.firestore.makeDocumentSnapshot(before, path) : { data: () => undefined, exists: false },
      after: after ? fft.firestore.makeDocumentSnapshot(after, path) : { data: () => undefined, exists: false },
    },
    params,
  });
const call = (fn: any, data: any, uid?: string) =>
  (fft.wrap(fn) as any)({ data, auth: uid ? { uid, token: {} } : undefined });
const bodies = () => fetchMock.mock.calls.map((c) => JSON.parse((c[1] as any).body));
const csvOf = (b: any) => Buffer.from(b.attachments[0].content, 'base64').toString('utf8');

async function user(uid: string, email: string, lang = 'en', name = uid) {
  await auth.createUser({ uid, email });
  await db.doc(`users/${uid}`).set({ appLanguage: lang });
  await db.doc(`profiles/${uid}`).set({ displayName: name });
}

beforeEach(async () => {
  await clearAll();
  fetchMock.mockClear();
  NOW = Date.UTC(2026, 10, 14, 17, 0);
  delete process.env.RESEND_API_KEY;
  delete process.env.ADMIN_VERIFICATION_EMAILS;
  await db.doc('app_config/resend_settings').set({ apiKey: 're_test', senderEmail: 'no-reply@greengo.test' });
});
afterAll(() => fft.cleanup());

describe('ID verification submitted', () => {
  const path = 'age_verification_queue/uidVerif123';
  const pending = (ms: number) => ({ userId: 'uidVerif123', status: 'pending', submittedAt: TS.fromMillis(ms), documentType: 'passport', documentBirthYear: 1990 });

  test('one email per submission; exact subject; uid + link only; retries and edits do not resend', async () => {
    await written(emailOnIdVerificationSubmitted, path, null, pending(1000), { uid: 'uidVerif123' });
    await written(emailOnIdVerificationSubmitted, path, null, pending(1000), { uid: 'uidVerif123' }); // retry
    await written(emailOnIdVerificationSubmitted, path, pending(1000), { ...pending(1000), confidence: 0.5 }, { uid: 'uidVerif123' });
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const b = bodies()[0];
    expect(b.subject).toBe('DOCUMENTVERIFICATION FOR USER uidVerif123');
    expect(b.to).toEqual(['greengochat.com@gmail.com']);
    expect(b.html).toContain('https://greengo-chat-admin.web.app/age-verification?user=uidVerif123');
    expect(JSON.stringify(b)).not.toMatch(/1990|passport|attachments/);

    // Re-submission (new submittedAt) after a rejection -> a new email.
    process.env.ADMIN_VERIFICATION_EMAILS = 'rev1@greengo.test,rev2@greengo.test';
    await written(emailOnIdVerificationSubmitted, path, { status: 'rejected' }, pending(2000), { uid: 'uidVerif123' });
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(bodies()[1].to).toEqual(['rev1@greengo.test', 'rev2@greengo.test']);
    // Decision -> no email.
    await written(emailOnIdVerificationSubmitted, path, pending(2000), { status: 'approved' }, { uid: 'uidVerif123' });
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  test('no Resend key: skipped quietly, nothing thrown, claim kept as skipped', async () => {
    await db.doc('app_config/resend_settings').set({});
    await expect(written(emailOnIdVerificationSubmitted, path, null, pending(3000), { uid: 'uidVerif123' })).resolves.not.toThrow();
    expect(fetchMock).not.toHaveBeenCalled();
    expect((await db.doc('email_dispatch/idv_uidVerif123_3000').get()).data()).toMatchObject({ status: 'skipped', reason: 'not_configured' });
  });
});

describe('buyer ticket email', () => {
  async function seedPaidOrder() {
    await user('buyer1', 'buyer1@example.com', 'it');
    await db.doc('events/ev1').set({ title: 'Jazz night', organizerId: 'org1', status: 'published', startDate: TS.fromMillis(NOW + 3 * 86400000), locationName: 'Bar X', city: 'Roma', timeZone: 'Europe/Rome' });
    for (const [i, type] of [[1, 'VIP'], [2, 'General']] as const) {
      await db.doc(`tickets/ord1_${i}`).set({ ticketId: `ord1_${i}`, orderId: 'ord1', status: 'valid', kind: 'event', listingId: 'ev1', buyerId: 'buyer1', qrPayload: `greengo:tk:ord1_${i}.sig${i}`, ticketTypeName: type, code: 'GG-ABC234' });
    }
    return { kind: 'event', listingId: 'ev1', buyerId: 'buyer1', organizerId: 'org1', status: 'paid', ticketIds: ['ord1_1', 'ord1_2'], code: 'GG-ABC234', title: 'Jazz night', quantity: 2 };
  }

  test('paid -> one email in the buyer language with every QR inline; re-delivery does not resend', async () => {
    const after = await seedPaidOrder();
    await written(emailTicketsOnOrderPaid, 'ticket_orders/ord1', { ...after, status: 'pending' }, after, { orderId: 'ord1' });
    await written(emailTicketsOnOrderPaid, 'ticket_orders/ord1', { ...after, status: 'pending' }, after, { orderId: 'ord1' });
    await written(emailTicketsOnOrderPaid, 'ticket_orders/ord1', after, { ...after, updatedAt: 1 }, { orderId: 'ord1' });
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const b = bodies()[0];
    expect(b.to).toEqual(['buyer1@example.com']);
    expect(b.subject).toBe('Il tuo biglietto per Jazz night');
    expect(b.html).toContain('GG-ABC234');
    expect(b.html).toContain('VIP × 1, General × 1');
    expect(b.html).toContain('Bar X, Roma');
    expect(b.html).toContain('(Europe/Rome)');
    expect(b.attachments.map((a: any) => a.content_id)).toEqual(['ticket-qr-1', 'ticket-qr-2']);
    expect(Buffer.from(b.attachments[0].content, 'base64').subarray(1, 4).toString()).toBe('PNG');
    expect(JSON.stringify(b)).not.toContain('sig1');
  });

  test('free / cash experience booking confirmed -> QR email; online booking left to the order email', async () => {
    await user('guest1', 'guest1@example.com', 'en');
    await db.doc('user_experiences/x1').set({ title: 'Food tour', hostId: 'host1', meetingPoint: 'Fountain', availabilityRules: { timezone: 'America/Sao_Paulo' } });
    const base = { experienceId: 'x1', hostId: 'host1', guestId: 'guest1', guests: 3, experienceTitle: 'Food tour', slotStart: TS.fromMillis(NOW + 86400000) };
    await written(emailBookingQrOnConfirm, 'bookings/bk1', { ...base, status: 'requested', payment: { mode: 'cash' } }, { ...base, status: 'confirmed', payment: { mode: 'cash' } }, { bookingId: 'bk1' });
    await written(emailBookingQrOnConfirm, 'bookings/bk1', { ...base, status: 'confirmed', payment: { mode: 'cash' } }, { ...base, status: 'confirmed', payment: { mode: 'cash', hostConfirmedPaidAt: 1 } }, { bookingId: 'bk1' });
    await written(emailBookingQrOnConfirm, 'bookings/bk2', { ...base, status: 'requested', payment: { mode: 'online' } }, { ...base, status: 'confirmed', payment: { mode: 'online' } }, { bookingId: 'bk2' });
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const b = bodies()[0];
    expect(b.subject).toBe('Your ticket for Food tour');
    expect(b.html).toContain('Fountain');
    expect(b.html).toContain('(America/Sao_Paulo)');
    expect(b.attachments).toHaveLength(1);
  });
});

describe('participants list scheduler', () => {
  async function seed() {
    await user('org1', 'org1@example.com', 'de');
    await user('host1', 'host1@example.com', 'en');
    await user('a1', 'a1@example.com', 'en', 'Alice');
    await user('a2', 'a2@example.com', 'en', 'Bob');
    const ev = (id: string, startMs: number, status = 'published') =>
      db.doc(`events/${id}`).set({ title: `Event ${id}`, organizerId: 'org1', status, startDate: TS.fromMillis(startMs) });
    await ev('soon', NOW + 30 * MIN);
    await ev('later', NOW + 90 * MIN);
    await ev('past', NOW - 10 * MIN);
    await ev('cancelled', NOW + 20 * MIN, 'cancelled');
    await ev('empty', NOW + 25 * MIN);
    for (const id of ['soon', 'later', 'past', 'cancelled']) {
      await db.doc(`events/${id}/attendees/a1`).set({ userId: 'a1', userName: 'Alice, "Al"', status: 'going', checkedIn: true });
      await db.doc(`events/${id}/attendees/a2`).set({ userId: 'a2', userName: '=cmd()', status: 'going', ticketCount: 2 });
      await db.doc(`events/${id}/attendees/a3`).set({ userId: 'a3', userName: 'Left', status: 'not_going' });
    }
    await db.doc('tickets/o9_1').set({ ticketId: 'o9_1', orderId: 'o9', code: null, kind: 'event', listingId: 'soon', buyerId: 'a2', status: 'valid', ticketTypeName: 'VIP' });
    await db.doc('tickets/o9_2').set({ ticketId: 'o9_2', orderId: 'o9', code: null, kind: 'event', listingId: 'soon', buyerId: 'a2', status: 'valid', ticketTypeName: 'VIP' });
    await db.doc('user_experiences/x1').set({ title: 'Food tour', hostId: 'host1' });
    const slot = TS.fromMillis(NOW + 40 * MIN);
    await db.doc('bookings/b1').set({ experienceId: 'x1', hostId: 'host1', guestId: 'a1', guests: 2, status: 'confirmed', slotStart: slot, experienceTitle: 'Food tour', payment: { mode: 'cash' } });
    await db.doc('bookings/b2').set({ experienceId: 'x1', hostId: 'host1', guestId: 'a2', guests: 1, status: 'confirmed', slotStart: slot, experienceTitle: 'Food tour', payment: { mode: 'link', hostConfirmedPaidAt: TS.fromMillis(NOW) } });
    await db.doc('bookings/b3').set({ experienceId: 'x1', hostId: 'host1', guestId: 'a2', guests: 1, status: 'cancelled_by_guest', slotStart: slot, experienceTitle: 'Food tour', payment: { mode: 'cash' } });
  }

  test('only listings starting within the hour, once each, CSV escaped + localized', async () => {
    await seed();
    const r1 = await runParticipantListsDue(NOW);
    expect(r1).toEqual({ events: 2, slots: 1, sent: 2 }); // soon (+30) and empty (+25, no list) / slot (+40)
    NOW += 10 * MIN;
    const r2 = await runParticipantListsDue(NOW);
    expect(r2.sent).toBe(0);
    expect(fetchMock).toHaveBeenCalledTimes(2);

    const evMail = bodies().find((b) => b.to[0] === 'org1@example.com');
    const slotMail = bodies().find((b) => b.to[0] === 'host1@example.com');
    expect(evMail.to).toEqual(['org1@example.com']);
    expect(evMail.subject).toBe('Teilnehmerliste: Event soon');
    const csv = csvOf(evMail);
    expect(csv.startsWith('﻿Name,E-Mail,Buchungscode')).toBe(true);
    // Free RSVP (no ticket, never saw the sharing notice): name only, no email.
    expect(csv).toContain('"Alice, ""Al""",,,1,eingecheckt');
    expect(csv).toContain("'=cmd(),a2@example.com,o9,VIP × 2 (2),bezahlt");
    expect(csv).not.toContain('Left');
    expect(evMail.attachments[0].filename).toBe('participants-Event-soon.csv');

    expect(slotMail.subject).toBe('Participants list: Food tour');
    const sc = csvOf(slotMail);
    expect(sc.split('\r\n').filter(Boolean)).toHaveLength(3); // header + 2 confirmed bookings
    expect(sc).toMatch(/Alice,a1@example\.com,[A-Z0-9]{8},2,confirmed/);
    expect(sc).toMatch(/Bob,a2@example\.com,[A-Z0-9]{8},1,paid/);
  });

  test('an event whose list was empty is sent once a participant joins later in the hour', async () => {
    await seed();
    await runParticipantListsDue(NOW);
    const before = fetchMock.mock.calls.length;
    await db.doc('events/empty/attendees/a1').set({ userId: 'a1', userName: 'Alice', status: 'going' });
    NOW += 10 * MIN;
    await runParticipantListsDue(NOW);
    expect(fetchMock.mock.calls.length).toBe(before + 1);
    expect(bodies()[before].subject).toBe('Teilnehmerliste: Event empty');
  });
});

describe('sendParticipantsList callable', () => {
  beforeEach(async () => {
    await user('org1', 'org1@example.com');
    await user('co1', 'co1@example.com');
    await user('stranger', 'stranger@example.com');
    await user('host1', 'host1@example.com');
    await db.doc('events/ev1').set({ title: 'Ev', organizerId: 'org1', coOrganizerIds: ['co1'], status: 'published', startDate: TS.fromMillis(NOW + 86400000) });
    await db.doc('events/ev1/attendees/u1').set({ userId: 'u1', userName: 'U', status: 'going' });
    await db.doc('user_experiences/x1').set({ title: 'Tour', hostId: 'host1' });
    await db.doc('bookings/b1').set({ experienceId: 'x1', hostId: 'host1', guestId: 'u1', guests: 1, status: 'confirmed', slotStart: TS.fromMillis(NOW + 2 * 86400000), payment: { mode: 'free' } });
  });

  test('organizer and co-organizer receive it at their own address; others are refused', async () => {
    await expect(call(sendParticipantsList, { kind: 'event', id: 'ev1' }, 'org1')).resolves.toEqual({ sent: true, count: 1 });
    await expect(call(sendParticipantsList, { kind: 'event', id: 'ev1' }, 'co1')).resolves.toMatchObject({ sent: true });
    await expect(call(sendParticipantsList, { kind: 'event', id: 'ev1' }, 'stranger')).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(call(sendParticipantsList, { kind: 'event', id: 'ev1' })).rejects.toMatchObject({ code: 'unauthenticated' });
    await expect(call(sendParticipantsList, { kind: 'event', id: 'nope' }, 'org1')).rejects.toMatchObject({ code: 'not-found' });
    await expect(call(sendParticipantsList, { kind: 'group', id: 'ev1' }, 'org1')).rejects.toMatchObject({ code: 'invalid-argument' });
    expect(bodies().map((b) => b.to[0])).toEqual(['org1@example.com', 'co1@example.com']);
  });

  test('experience: host only; next slot picked when slotStart is omitted', async () => {
    await expect(call(sendParticipantsList, { kind: 'experience', id: 'x1' }, 'org1')).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(call(sendParticipantsList, { kind: 'experience', id: 'x1' }, 'host1')).resolves.toEqual({ sent: true, count: 1 });
    await expect(call(sendParticipantsList, { kind: 'experience', id: 'x1', slotStart: NOW + 5 * 86400000 }, 'host1'))
      .resolves.toEqual({ sent: true, count: 0 });
  });

  test('rate limit: 1 per 5 minutes per listing; released when sending failed', async () => {
    await call(sendParticipantsList, { kind: 'event', id: 'ev1' }, 'org1');
    await expect(call(sendParticipantsList, { kind: 'event', id: 'ev1' }, 'org1')).rejects.toMatchObject({ code: 'resource-exhausted' });
    NOW += 5 * MIN + 1;
    await expect(call(sendParticipantsList, { kind: 'event', id: 'ev1' }, 'org1')).resolves.toMatchObject({ sent: true });

    await db.doc('app_config/resend_settings').set({});
    NOW += 6 * MIN;
    await expect(call(sendParticipantsList, { kind: 'event', id: 'ev1' }, 'org1')).rejects.toMatchObject({ code: 'unavailable' });
    await db.doc('app_config/resend_settings').set({ apiKey: 're_test' });
    await expect(call(sendParticipantsList, { kind: 'event', id: 'ev1' }, 'org1')).resolves.toMatchObject({ sent: true });
  });
});
