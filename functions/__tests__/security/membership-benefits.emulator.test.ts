/**
 * Membership benefits are enforced by the SERVER (audit 2026-10-11).
 *
 * Started from the audit's bypass checks (C:/dev/gg-audit-scripts/
 * zz-benefits-audit.emulator.test.ts), with every "allowed" bypass flipped
 * to DENIED, plus the legitimate flows that must keep working - including the
 * writes the 4.6 / 4.7 apps still make.
 *
 *   P-H1  daily new connections: conversation create vs entitlement_usage
 *   P-H2  Base membership required to send a 1:1 message
 *   P-H3  perk fields on profiles/{uid}: boost, travel, ghost, incognito, promotion
 *   P-H4  active-event cap (M1; at a time: Base 1 / Silver 5 / Gold 10) and group cap (H5)
 *   P-H5  sponsored communities: Platinum business only
 *   H2    support ticket priority is server-owned
 *   H4    free monthly boosts (spendCoins), server-tracked
 *   + the usage triggers (connects / events / groups) and their backstops.
 *
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "npx jest --config jest.security.config.js membership-benefits"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });

import { spendCoins } from '../../src/coins';
import {
  onConversationCreatedCountConnect,
  onGroupWrittenUsage,
  recountEvents,
} from '../../src/entitlements/usage';
import { handleAiAssist } from '../../src/ai/aiGateway';
import { claimFreeChat } from '../../src/entitlements/freeChat';
import { openListingChat } from '../../src/entitlements/listingChat';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const HOUR = 3600 * 1000;
const DAY = 24 * HOUR;

async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  if (!/^(localhost|127\.0\.0\.1)/.test(host)) throw new Error('Refusing: not a local emulator');
  await new Promise<void>((resolve, reject) => {
    const req = http.request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE',
      path: `/emulator/v1/projects/${PROJECT}/databases/(default)/documents` }, (res) => { res.resume(); res.on('end', resolve); });
    req.on('error', reject);
    req.end();
  });
}
function idToken(uid: string): string {
  const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, phone_number: '+351910000000', firebase: { sign_in_provider: 'password' } })}.`;
}
function toValue(v: any): any {
  if (v === null) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, toValue(x)])) } };
}
/** A client write (PATCH = create or update) as `uid`, through the rules. */
async function clientWrite(uid: string, path: string, data: Record<string, any>, mask?: string[]): Promise<number> {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  const q = mask ? '?' + mask.map((m) => `updateMask.fieldPaths=${encodeURIComponent(m)}`).join('&') : '';
  const res = await fetch(`http://${host}/v1/projects/${PROJECT}/databases/(default)/documents/${path}${q}`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, toValue(v)])) }),
  });
  await res.text();
  return res.status;
}
async function clientRead(uid: string, path: string): Promise<number> {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  const res = await fetch(`http://${host}/v1/projects/${PROJECT}/databases/(default)/documents/${path}`, {
    headers: { Authorization: `Bearer ${idToken(uid)}` },
  });
  await res.text();
  return res.status;
}
/** Several creates in ONE commit (rules see the counters as before the batch). */
async function clientBatchCreate(uid: string, docs: { path: string; data: Record<string, any> }[]): Promise<number> {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  const base = `projects/${PROJECT}/databases/(default)/documents`;
  const res = await fetch(`http://${host}/v1/${base}:commit`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ writes: docs.map((d) => ({
      update: { name: `${base}/${d.path}`, fields: Object.fromEntries(Object.entries(d.data).map(([k, v]) => [k, toValue(v)])) },
      currentDocument: { exists: false },
    })) }),
  });
  await res.text();
  return res.status;
}

const call = (fn: any, data: any, uid: string) => (fft.wrap(fn) as any)({ data, auth: { uid, token: {} } });
async function refused(p: Promise<any>): Promise<any> {
  try { await p; } catch (e: any) { return e; }
  throw new Error('expected the call to be refused');
}
let seq = 0;
const rid = () => `req_${Date.now()}_${++seq}_abcdef`;

const future = (ms = 30 * DAY) => TS.fromMillis(Date.now() + ms);
const past = (ms = DAY) => TS.fromMillis(Date.now() - ms);
const dayStart = () => Math.floor(Date.now() / DAY) * DAY;

const FREE = 'free01'; // no paid tier, NO Base membership
const BASE = 'base01'; // Base membership, no paid tier
const SILVER = 'silver01';
const GOLD = 'gold01';
const PLAT = 'plat01';
const BIZ = 'biz01'; // Platinum business
const EXPIRED = 'expired01'; // Gold that ended, no Base

async function seedProfiles() {
  await Promise.all([
    db.doc(`profiles/${FREE}`).set({ userId: FREE, membershipTier: 'FREE', hasBaseMembership: false, isBusiness: false }),
    db.doc(`profiles/${BASE}`).set({ userId: BASE, membershipTier: 'FREE', hasBaseMembership: true, baseMembershipEndDate: future(365 * DAY) }),
    db.doc(`profiles/${SILVER}`).set({ userId: SILVER, membershipTier: 'SILVER', membershipEndDate: future() }),
    db.doc(`profiles/${GOLD}`).set({ userId: GOLD, membershipTier: 'GOLD', membershipEndDate: future() }),
    db.doc(`profiles/${PLAT}`).set({ userId: PLAT, membershipTier: 'PLATINUM', membershipEndDate: future() }),
    db.doc(`profiles/${BIZ}`).set({ userId: BIZ, membershipTier: 'PLATINUM', membershipEndDate: future(), isBusiness: true }),
    db.doc(`profiles/${EXPIRED}`).set({ userId: EXPIRED, membershipTier: 'GOLD', membershipEndDate: past() }),
  ]);
}

beforeEach(async () => {
  await clearAll();
  await seedProfiles();
});
afterAll(() => fft.cleanup());

// ---------------------------------------------------------------------------
describe('positive controls (unchanged)', () => {
  test('owner cannot self-grant PLATINUM / Base / business', async () => {
    expect(await clientWrite(FREE, `profiles/${FREE}`,
      { membershipTier: 'PLATINUM', membershipEndDate: new Date(Date.now() + 365 * DAY) },
      ['membershipTier', 'membershipEndDate'])).toBe(403);
    expect(await clientWrite(FREE, `profiles/${FREE}`,
      { hasBaseMembership: true, baseMembershipEndDate: new Date(Date.now() + 365 * DAY) },
      ['hasBaseMembership', 'baseMembershipEndDate'])).toBe(403);
    expect(await clientWrite(FREE, `profiles/${FREE}`, { isBusiness: true }, ['isBusiness'])).toBe(403);
  });
});

// ---------------------------------------------------------------------------
describe('P-H3 perk fields on profiles/{uid}', () => {
  test('a FREE owner can no longer grant themselves any perk (audit bypasses -> denied)', async () => {
    expect(await clientWrite(FREE, `profiles/${FREE}`,
      { isBoosted: true, boostExpiry: new Date(Date.now() + DAY) }, ['isBoosted', 'boostExpiry'])).toBe(403);
    expect(await clientWrite(FREE, `profiles/${FREE}`,
      { isTraveler: true, travelerExpiry: new Date(Date.now() + 30 * DAY) }, ['isTraveler', 'travelerExpiry'])).toBe(403);
    expect(await clientWrite(FREE, `profiles/${FREE}`, { isGhostMode: true }, ['isGhostMode'])).toBe(403);
    expect(await clientWrite(FREE, `profiles/${FREE}`,
      { isIncognito: true, incognitoExpiry: new Date(Date.now() + 30 * DAY) }, ['isIncognito', 'incognitoExpiry'])).toBe(403);
    expect(await clientWrite(FREE, `profiles/${FREE}`,
      { businessPromotedUntil: new Date(Date.now() + 30 * DAY) }, ['businessPromotedUntil'])).toBe(403);
    expect(await clientWrite(FREE, `profiles/${FREE}`,
      { travelerPaidUntil: new Date(Date.now() + 30 * DAY) }, ['travelerPaidUntil'])).toBe(403);
  });

  test('two-step trick (extend the end while the flag is off, then flip it) is denied', async () => {
    expect(await clientWrite(FREE, `profiles/${FREE}`,
      { isBoosted: false, boostExpiry: new Date(Date.now() + 365 * DAY) }, ['isBoosted', 'boostExpiry'])).toBe(403);
  });

  test('a profile cannot be (re)created with a perk', async () => {
    expect(await clientWrite('newbie', 'profiles/newbie', { userId: 'newbie', isGhostMode: true })).toBe(403);
    expect(await clientWrite('newbie', 'profiles/newbie',
      { userId: 'newbie', isBoosted: true, boostExpiry: new Date(Date.now() + DAY) })).toBe(403);
    // Old apps send the neutral defaults: still fine.
    expect(await clientWrite('newbie', 'profiles/newbie', {
      userId: 'newbie', isBoosted: false, boostExpiry: null, isIncognito: false, incognitoExpiry: null,
      isGhostMode: false, isTraveler: false, travelerExpiry: null,
    })).toBe(200);
  });

  test('legit: switching a server-granted perk OFF, and re-saving it unchanged', async () => {
    const until = future(30 * 60000);
    await db.doc(`profiles/${SILVER}`).set({ isBoosted: true, boostExpiry: until, isIncognito: true, incognitoExpiry: future(DAY) }, { merge: true });
    // Full profile save of the 4.6/4.7 app: every perk key with its current value.
    expect(await clientWrite(SILVER, `profiles/${SILVER}`,
      { displayName: 'S', isBoosted: true, boostExpiry: until.toDate(), isIncognito: true },
      ['displayName', 'isBoosted', 'boostExpiry', 'isIncognito'])).toBe(200);
    expect(await clientWrite(SILVER, `profiles/${SILVER}`,
      { isIncognito: false, incognitoExpiry: null }, ['isIncognito', 'incognitoExpiry'])).toBe(200);
    expect(await clientWrite(SILVER, `profiles/${SILVER}`, { isBoosted: false }, ['isBoosted'])).toBe(200);
  });

  test('ghost mode: Gold and up only (the 4.6/4.7 app writes it directly)', async () => {
    expect(await clientWrite(GOLD, `profiles/${GOLD}`, { isGhostMode: true }, ['isGhostMode'])).toBe(200);
    expect(await clientWrite(PLAT, `profiles/${PLAT}`, { isGhostMode: true }, ['isGhostMode'])).toBe(200);
    expect(await clientWrite(SILVER, `profiles/${SILVER}`, { isGhostMode: true }, ['isGhostMode'])).toBe(403);
    expect(await clientWrite(EXPIRED, `profiles/${EXPIRED}`, { isGhostMode: true }, ['isGhostMode'])).toBe(403);
    // Turning it off is always allowed.
    await db.doc(`profiles/${EXPIRED}`).set({ isGhostMode: true }, { merge: true });
    expect(await clientWrite(EXPIRED, `profiles/${EXPIRED}`, { isGhostMode: false }, ['isGhostMode'])).toBe(200);
  });

  test('travel mode: within the paid pass (+2h to pick the place), or 24h for Platinum', async () => {
    const m = ['isTraveler', 'travelerExpiry', 'travelerLocation'];
    const loc = { city: 'Rome', country: 'IT' };
    // No pass: denied.
    expect(await clientWrite(SILVER, `profiles/${SILVER}`,
      { isTraveler: true, travelerExpiry: new Date(Date.now() + DAY), travelerLocation: loc }, m)).toBe(403);
    // spendCoins('traveler') wrote the pass.
    await db.doc(`profiles/${SILVER}`).set({ travelerPaidUntil: future(DAY) }, { merge: true });
    expect(await clientWrite(SILVER, `profiles/${SILVER}`,
      { isTraveler: true, travelerExpiry: new Date(Date.now() + DAY + 30 * 60000), travelerLocation: loc }, m)).toBe(200);
    expect(await clientWrite(SILVER, `profiles/${SILVER}`,
      { isTraveler: true, travelerExpiry: new Date(Date.now() + 30 * DAY), travelerLocation: loc }, m)).toBe(403);
    // Platinum: free, 24h at a time.
    expect(await clientWrite(PLAT, `profiles/${PLAT}`,
      { isTraveler: true, travelerExpiry: new Date(Date.now() + DAY), travelerLocation: loc }, m)).toBe(200);
    expect(await clientWrite(PLAT, `profiles/${PLAT}`,
      { isTraveler: true, travelerExpiry: new Date(Date.now() + 3 * DAY), travelerLocation: loc }, m)).toBe(403);
    // Deactivate (the app writes isTraveler false + travelerLocation null).
    expect(await clientWrite(SILVER, `profiles/${SILVER}`,
      { isTraveler: false, travelerLocation: null }, ['isTraveler', 'travelerLocation'])).toBe(200);
  });
});

// ---------------------------------------------------------------------------
describe('P-H1 daily new connections', () => {
  const conv = (from: string, to: string) => ({ userId1: from, userId2: to, matchId: `search_${[from, to].sort().join('_')}` });

  test('over the cap a new conversation is refused, even after resetting usageLimits', async () => {
    await db.doc(`entitlement_usage/${BASE}`).set({ connectDayStartMs: dayStart(), connectCount: 10 });
    // The 4.6/4.7 app's owner-writable counter: resetting it no longer helps.
    const day = new Date().toISOString().slice(0, 10);
    expect(await clientWrite(BASE, `usageLimits/${BASE}/days/${day}`, { connectsCount: 0 })).toBe(200);
    expect(await clientWrite(BASE, 'conversations/c1', conv(BASE, GOLD))).toBe(403);
  });

  test('under the cap / a new day / Platinum: allowed', async () => {
    await db.doc(`entitlement_usage/${BASE}`).set({ connectDayStartMs: dayStart(), connectCount: 9 });
    expect(await clientWrite(BASE, 'conversations/c1', conv(BASE, GOLD))).toBe(200);
    await db.doc(`entitlement_usage/${SILVER}`).set({ connectDayStartMs: dayStart() - DAY, connectCount: 50 });
    expect(await clientWrite(SILVER, 'conversations/c2', conv(SILVER, GOLD))).toBe(200);
    await db.doc(`entitlement_usage/${PLAT}`).set({ connectDayStartMs: dayStart(), connectCount: 5000 });
    expect(await clientWrite(PLAT, 'conversations/c3', conv(PLAT, GOLD))).toBe(200);
    // Expired Gold is FREE: cap 10.
    await db.doc(`entitlement_usage/${EXPIRED}`).set({ connectDayStartMs: dayStart(), connectCount: 10 });
    expect(await clientWrite(EXPIRED, 'conversations/c4', conv(EXPIRED, GOLD))).toBe(403);
  });

  test('the creator must be userId1; support tickets are not connections', async () => {
    expect(await clientWrite(BASE, 'conversations/c1', { userId1: GOLD, userId2: BASE, matchId: 'x' })).toBe(403);
    await db.doc(`entitlement_usage/${BASE}`).set({ connectDayStartMs: dayStart(), connectCount: 10 });
    expect(await clientWrite(BASE, 'conversations/s1',
      { userId1: BASE, userId2: 'support_system', matchId: 'support', conversationType: 'support' })).toBe(200);
  });

  test('trigger counts per UTC day and deletes a conversation over the cap (batch backstop)', async () => {
    const run = (id: string, data: any) => (onConversationCreatedCountConnect as any).run({
      data: fft.firestore.makeDocumentSnapshot(data, `conversations/${id}`), params: { conversationId: id } });
    await db.doc(`entitlement_usage/${BASE}`).set({ connectDayStartMs: dayStart() - DAY, connectCount: 10 });
    for (let i = 0; i < 10; i++) {
      await db.doc(`conversations/k${i}`).set(conv(BASE, `p${i}`));
      await run(`k${i}`, conv(BASE, `p${i}`));
    }
    let u = (await db.doc(`entitlement_usage/${BASE}`).get()).data()!;
    expect(u.connectCount).toBe(10);
    expect(u.connectDayStartMs).toBe(dayStart());
    await db.doc('conversations/k10').set(conv(BASE, 'p10'));
    await run('k10', conv(BASE, 'p10'));
    expect((await db.doc('conversations/k10').get()).exists).toBe(false);
    u = (await db.doc(`entitlement_usage/${BASE}`).get()).data()!;
    expect(u.connectCount).toBe(10);
    // Support tickets are not counted.
    await run('sup', { userId1: BASE, userId2: 'support_system', conversationType: 'support' });
    expect((await db.doc(`entitlement_usage/${BASE}`).get()).data()!.connectCount).toBe(10);
  });
});

// ---------------------------------------------------------------------------
describe('P-H2 Base membership required to chat', () => {
  beforeEach(async () => {
    for (const u of [FREE, BASE, SILVER, EXPIRED]) {
      await db.doc(`conversations/c_${u}`).set({ userId1: u, userId2: GOLD, matchId: `search_${u}` });
    }
    await db.doc(`conversations/sup_${FREE}`).set({ userId1: FREE, userId2: 'support_system', matchId: 'support', conversationType: 'support' });
  });
  const msg = (u: string) => ({ senderId: u, content: 'hi', type: 'text' });

  test('FREE without Base cannot send (audit bypass -> denied); expired paid tier without Base neither', async () => {
    expect(await clientWrite(FREE, `conversations/c_${FREE}/messages/m1`, msg(FREE))).toBe(403);
    expect(await clientWrite(EXPIRED, `conversations/c_${EXPIRED}/messages/m1`, msg(EXPIRED))).toBe(403);
    // Posing as 'system' outside support does not help.
    expect(await clientWrite(FREE, `conversations/c_${FREE}/messages/m2`, { senderId: 'system', content: 'x', type: 'system' })).toBe(403);
  });

  test('Base, a paid tier and support tickets: allowed', async () => {
    expect(await clientWrite(BASE, `conversations/c_${BASE}/messages/m1`, msg(BASE))).toBe(200);
    expect(await clientWrite(SILVER, `conversations/c_${SILVER}/messages/m1`, msg(SILVER))).toBe(200);
    expect(await clientWrite(GOLD, `conversations/c_${FREE}/messages/m3`, msg(GOLD))).toBe(200);
    expect(await clientWrite(FREE, `conversations/sup_${FREE}/messages/m1`, msg(FREE))).toBe(200);
    expect(await clientWrite(FREE, `conversations/sup_${FREE}/messages/m2`, { senderId: 'system', content: 'Welcome', type: 'system' })).toBe(200);
  });
});

// ---------------------------------------------------------------------------
describe('Buyer <-> organizer chat (2026-10-17): server-verified context.buyer', () => {
  const conv = (from: string, to: string, extra: Record<string, any> = {}) =>
    ({ userId1: from, userId2: to, matchId: `search_${[from, to].sort().join('_')}`, ...extra });
  const msg = (u: string) => ({ senderId: u, content: 'hi', type: 'text' });

  test('a client can never claim buyer on create or update; a plain topic is fine', async () => {
    expect(await clientWrite(BASE, 'conversations/b1',
      conv(BASE, GOLD, { context: { type: 'event', id: 'ev1', buyer: true } }))).toBe(403);
    expect(await clientWrite(BASE, 'conversations/b2',
      conv(BASE, GOLD, { context: { type: 'event', id: 'ev1', title: 'T' } }))).toBe(200);
    expect(await clientWrite(BASE, 'conversations/b2',
      { context: { type: 'event', id: 'ev1', buyer: true } }, ['context'])).toBe(403);
  });

  test('a verified context stays (other fields editable), may be replaced by a plain topic, never forged', async () => {
    await db.doc('conversations/v1').set(conv(GOLD, BASE, { context: { type: 'event', id: 'ev1', buyer: true, buyerId: BASE } }));
    expect(await clientWrite(BASE, 'conversations/v1', { lastMessageAt: new Date() }, ['lastMessageAt'])).toBe(200);
    expect(await clientWrite(BASE, 'conversations/v1',
      { context: { type: 'event', id: 'ev2', buyer: true, buyerId: BASE } }, ['context'])).toBe(403);
    expect(await clientWrite(BASE, 'conversations/v1', { context: { type: 'event', id: 'ev2', title: 'B' } }, ['context'])).toBe(200);
  });

  test('without Base: posting is allowed in a verified buyer chat only (both sides)', async () => {
    await db.doc('conversations/fb').set(conv(FREE, GOLD, { context: { type: 'event', id: 'ev1', buyer: true, buyerId: FREE } }));
    await db.doc('conversations/fp').set(conv(FREE, SILVER, { context: { type: 'event', id: 'ev1' } }));
    expect(await clientWrite(FREE, 'conversations/fb/messages/m1', msg(FREE))).toBe(200);
    expect(await clientWrite(GOLD, 'conversations/fb/messages/m2', msg(GOLD))).toBe(200);
    expect(await clientWrite(FREE, 'conversations/fp/messages/m1', msg(FREE))).toBe(403);
  });

  test('openListingChat: a ticket holder over the daily cap gets the chat; the counter skips it', async () => {
    await db.doc(`entitlement_usage/${FREE}`).set({ connectDayStartMs: dayStart(), connectCount: 10 });
    await db.doc('events/ev1').set({ organizerId: GOLD, latitude: 41.15, longitude: -8.61, title: 'Samba', startDate: future() });
    // Before buying: no write, the client create is refused over the cap.
    const before = await call(openListingChat, { type: 'event', id: 'ev1' }, FREE);
    expect(before.buyer).toBe(false);
    expect(await clientWrite(FREE, 'conversations/x1', conv(FREE, GOLD))).toBe(403);
    // After buying (attendee row written by the payment webhook).
    await db.doc(`events/ev1/attendees/${FREE}`).set({ status: 'going', ticketStatus: 'valid', isApproved: true });
    const r = await call(openListingChat, { type: 'event', id: 'ev1' }, FREE);
    expect(r.buyer).toBe(true);
    const snap = await db.doc(`conversations/${r.conversationId}`).get();
    expect(snap.data()!.context).toMatchObject({ type: 'event', id: 'ev1', buyer: true, buyerId: FREE });
    await (onConversationCreatedCountConnect as any).run({
      data: fft.firestore.makeDocumentSnapshot(snap.data()!, `conversations/${r.conversationId}`),
      params: { conversationId: r.conversationId } });
    expect((await db.doc(`conversations/${r.conversationId}`).get()).exists).toBe(true);
    expect((await db.doc(`entitlement_usage/${FREE}`).get()).data()!.connectCount).toBe(10);
    expect(await clientWrite(FREE, `conversations/${r.conversationId}/messages/m1`, msg(FREE))).toBe(200);
  });
});

// ---------------------------------------------------------------------------
describe('Free chats without Base: 3 people per UTC day (owner rule 2026-10-13)', () => {
  const people = ['p1', 'p2', 'p3', 'p4'];
  beforeEach(async () => {
    for (const p of people) {
      await db.doc(`conversations/f_${p}`).set({ userId1: FREE, userId2: p, matchId: `search_${p}` });
    }
    await db.doc('conversations/grp').set({ userId1: FREE, userId2: 'p1', participants: [FREE, 'p1', 'p2'] });
    await db.doc('conversations/other').set({ userId1: 'p1', userId2: 'p2' });
  });
  const msg = () => ({ senderId: FREE, content: 'hi', type: 'text' });

  test('claim 3 people, then the 4th is refused; re-claiming is free', async () => {
    for (const [i, p] of ['p1', 'p2', 'p3'].entries()) {
      const r = await call(claimFreeChat, { conversationId: `f_${p}` }, FREE);
      expect(r).toMatchObject({ allowed: true, unlimited: false, used: i + 1, limit: 3, added: true });
    }
    expect(await call(claimFreeChat, { conversationId: 'f_p4' }, FREE))
      .toMatchObject({ allowed: false, used: 3 });
    expect(await call(claimFreeChat, { conversationId: 'f_p2' }, FREE))
      .toMatchObject({ allowed: true, added: false, used: 3 });
    const u = (await db.doc(`entitlement_usage/${FREE}`).get()).data()!;
    expect(u.freeChatDayStartMs).toBe(dayStart());
    expect(u.freeChatConvs).toEqual(['f_p1', 'f_p2', 'f_p3']);
  });

  test("groups, support and other people's chats cannot be claimed; members are unlimited", async () => {
    await expect(call(claimFreeChat, { conversationId: 'grp' }, FREE)).rejects.toThrow('base_membership_required');
    await expect(call(claimFreeChat, { conversationId: 'other' }, FREE)).rejects.toThrow('base_membership_required');
    expect(await call(claimFreeChat, { conversationId: 'other' }, BASE)).toMatchObject({ unlimited: true });
    expect((await db.doc(`entitlement_usage/${BASE}`).get()).exists).toBe(false);
  });

  test("rules: posting only in today's claimed conversations", async () => {
    await db.doc(`entitlement_usage/${FREE}`).set({ freeChatDayStartMs: dayStart(), freeChatConvs: ['f_p1', 'f_p2', 'f_p3'] });
    expect(await clientWrite(FREE, 'conversations/f_p1/messages/m1', msg())).toBe(200);
    expect(await clientWrite(FREE, 'conversations/f_p3/messages/m1', msg())).toBe(200);
    expect(await clientWrite(FREE, 'conversations/f_p4/messages/m1', msg())).toBe(403);
    // Yesterday's list does not carry over.
    await db.doc(`entitlement_usage/${FREE}`).set({ freeChatDayStartMs: dayStart() - DAY, freeChatConvs: ['f_p1'] });
    expect(await clientWrite(FREE, 'conversations/f_p1/messages/m2', msg())).toBe(403);
  });

  test('free chats do not unlock joining events', async () => {
    await db.doc(`entitlement_usage/${FREE}`).set({ freeChatDayStartMs: dayStart(), freeChatConvs: ['f_p1'] });
    await db.doc('events/ev1').set({ organizerId: GOLD, latitude: 41.15, longitude: -8.61, title: 'e', price: 0, startDate: future(DAY), endDate: future(2 * DAY) });
    const rsvp = (uid: string) => ({ userId: uid, eventId: 'ev1', status: 'going', checkedIn: false });
    expect(await clientWrite(FREE, `events/ev1/attendees/${FREE}`, rsvp(FREE))).toBe(403);
    // Positive control: the same RSVP with Base goes through.
    expect(await clientWrite(BASE, `events/ev1/attendees/${BASE}`, rsvp(BASE))).toBe(200);
  });
});

// ---------------------------------------------------------------------------
describe('No plan: cannot create events (owner rule 2026-10-13)', () => {
  const ev = (uid: string) => ({
    organizerId: uid, latitude: 41.15, longitude: -8.61, title: 'e', price: 0,
    startDate: new Date(Date.now() + DAY), endDate: new Date(Date.now() + DAY + 2 * HOUR),
  });

  test('no plan or an expired tier: denied; Base and a paid tier: allowed', async () => {
    expect(await clientWrite(FREE, 'events/n1', ev(FREE))).toBe(403);
    expect(await clientWrite(EXPIRED, 'events/n2', ev(EXPIRED))).toBe(403);
    expect(await clientWrite(BASE, 'events/n3', ev(BASE))).toBe(200);
    expect(await clientWrite(SILVER, 'events/n4', ev(SILVER))).toBe(200);
  });

  test('editing and deleting an existing event still work without a plan', async () => {
    await db.doc('events/old').set({ ...ev(FREE), status: 'published' });
    expect(await clientWrite(FREE, 'events/old', { title: 'renamed' }, ['title'])).toBe(200);
  });

  test('backstop: a create by a no-plan organizer is deleted; Base keeps its event', async () => {
    await db.doc('events/x1').set({ ...ev(FREE), status: 'published', startDate: future(DAY), endDate: future(DAY + 2 * HOUR) });
    expect(await recountEvents(FREE, { id: 'x1', data: (await db.doc('events/x1').get()).data()! })).toBe('deleted');
    expect((await db.doc('events/x1').get()).exists).toBe(false);
    await db.doc('events/x2').set({ ...ev(BASE), status: 'published', startDate: future(DAY), endDate: future(DAY + 2 * HOUR) });
    expect(await recountEvents(BASE, { id: 'x2', data: (await db.doc('events/x2').get()).data()! })).toBe('ok');
    expect((await db.doc('events/x2').get()).exists).toBe(true);
  });
});

// ---------------------------------------------------------------------------
describe('P-H4 / M1 active-event cap (at a time: Base 1, Silver 5, Gold 10, Platinum unlimited)', () => {
  const ev = (uid: string, extra: any = {}) => ({
    organizerId: uid, latitude: 41.15, longitude: -8.61, title: 'e', price: 0,
    startDate: new Date(Date.now() + DAY), endDate: new Date(Date.now() + DAY + 2 * HOUR), ...extra,
  });

  test('over the cap: denied (audit "3 events" bypass); no end date: denied', async () => {
    await db.doc(`entitlement_usage/${BASE}`).set({ eventActiveEnds: [Date.now() + DAY] });
    expect(await clientWrite(BASE, 'events/e1', ev(BASE))).toBe(403);
    expect(await clientWrite(SILVER, 'events/e2', { organizerId: SILVER, latitude: 41.15, longitude: -8.61, title: 'x', price: 0 })).toBe(403);
    await db.doc(`entitlement_usage/${SILVER}`).set({ eventActiveEnds: [1, 2, 3, 4, 5].map((i) => Date.now() + i * HOUR) });
    expect(await clientWrite(SILVER, 'events/e3', ev(SILVER))).toBe(403);
    await db.doc(`entitlement_usage/${GOLD}`).set({ eventActiveEnds: Array.from({ length: 10 }, (_, i) => Date.now() + (i + 1) * HOUR) });
    expect(await clientWrite(GOLD, 'events/e4', ev(GOLD))).toBe(403);
  });

  test('the retired paid extra-event credit no longer lets a create past the cap', async () => {
    await db.doc(`entitlement_usage/${BASE}`).set({
      eventActiveEnds: [Date.now() + DAY], eventExtraCredits: 3, eventExtraUsed: 0,
    });
    expect(await clientWrite(BASE, 'events/x1', ev(BASE))).toBe(403);
  });

  test('ended events do not count (M1), a series occurrence passes, Platinum is unlimited', async () => {
    await db.doc(`entitlement_usage/${BASE}`).set({ eventActiveEnds: [Date.now() - HOUR] });
    expect(await clientWrite(BASE, 'events/e1', ev(BASE))).toBe(200);
    await db.doc(`entitlement_usage/${SILVER}`).set({
      eventActiveEnds: [Date.now() - HOUR, Date.now() + HOUR, Date.now() + DAY, Date.now() + 2 * DAY, Date.now() + 3 * DAY],
    });
    expect(await clientWrite(SILVER, 'events/e2', ev(SILVER))).toBe(200);
    await db.doc(`entitlement_usage/${GOLD}`).set({
      eventActiveEnds: Array.from({ length: 10 }, (_, i) => Date.now() + (i + 1) * DAY), eventActiveSeries: { ser1: 3 },
    });
    expect(await clientWrite(GOLD, 'events/e3', ev(GOLD, { seriesId: 'ser1' }))).toBe(200);
    expect(await clientWrite(GOLD, 'events/e4', ev(GOLD, { seriesId: 'other' }))).toBe(403);
    await db.doc(`entitlement_usage/${PLAT}`).set({ eventActiveEnds: Array.from({ length: 50 }, (_, i) => Date.now() + (i + 1) * DAY) });
    expect(await clientWrite(PLAT, 'events/e5', ev(PLAT))).toBe(200);
  });

  test('recount: series = one slot, hidden events free their slot, over-cap create deleted (batch backstop)', async () => {
    const mk = async (id: string, data: any) => { await db.doc(`events/${id}`).set(data); return { id, data }; };
    const base = (extra: any = {}) => ({
      organizerId: SILVER, latitude: 41.15, longitude: -8.61, status: 'published',
      startDate: future(DAY), endDate: future(DAY + 2 * HOUR), ...extra,
    });
    // Silver: 4 single events + a 4-occurrence series = 5 slots (cap 5).
    for (const id of ['a', 'b', 'c', 'h']) await recountEvents(SILVER, await mk(id, base({ endDate: future(2 * DAY) })));
    for (let i = 0; i < 4; i++) await recountEvents(SILVER, await mk(`s${i}`, base({ seriesId: 'ser', endDate: future((i + 1) * 7 * DAY) })));
    let u = (await db.doc(`entitlement_usage/${SILVER}`).get()).data()!;
    expect(u.eventActiveCount).toBe(5);
    expect(u.eventActiveSeries).toEqual({ ser: 4 });
    expect(u.eventActiveEnds).toHaveLength(5);
    // An ended and a cancelled event never count.
    await recountEvents(SILVER, await mk('old', base({ endDate: past(HOUR) })));
    await recountEvents(SILVER, await mk('can', base({ status: 'cancelled' })));
    expect((await db.doc('events/can').get()).exists).toBe(true);
    // 6th slot: deleted again (a leftover paid credit no longer helps).
    await db.doc(`entitlement_usage/${SILVER}`).set({ eventExtraCredits: 1 }, { merge: true });
    expect(await recountEvents(SILVER, await mk('d', base()))).toBe('deleted');
    expect((await db.doc('events/d').get()).exists).toBe(false);
    // An event hidden by a plan downgrade frees its slot.
    await db.doc('events/h').set({ status: 'draft', hiddenByDowngrade: true, preDowngradeStatus: 'published' }, { merge: true });
    await recountEvents(SILVER);
    expect(await recountEvents(SILVER, await mk('e', base()))).toBe('ok');
    u = (await db.doc(`entitlement_usage/${SILVER}`).get()).data()!;
    expect(u.eventActiveCount).toBe(5);
  });
});

// ---------------------------------------------------------------------------
describe('H5 / P-H4 group cap', () => {
  const grp = (uid: string) => ({ participants: [uid, GOLD], roles: { [uid]: 'admin', [GOLD]: 'member' }, createdBy: uid });

  test('free plan: 1 group; Silver+: unlimited; createdBy must be the creator', async () => {
    expect(await clientWrite(BASE, 'groups/g1', grp(BASE))).toBe(200);
    await db.doc(`entitlement_usage/${BASE}`).set({ groupsCreated: 1 });
    expect(await clientWrite(BASE, 'groups/g2', grp(BASE))).toBe(403);
    await db.doc(`entitlement_usage/${SILVER}`).set({ groupsCreated: 40 });
    expect(await clientWrite(SILVER, 'groups/g3', grp(SILVER))).toBe(200);
    expect(await clientWrite(BASE, 'groups/g4', { ...grp(BASE), createdBy: GOLD })).toBe(403);
    expect(await clientWrite(BASE, 'groups/g5', { participants: [BASE], roles: { [BASE]: 'admin' } })).toBe(403);
  });

  test('a batch of groups passes the rules once, and the trigger deletes the extra ones', async () => {
    const docs = [0, 1, 2].map((i) => ({ path: `groups/b${i}`, data: grp(FREE) }));
    expect(await clientBatchCreate(FREE, docs)).toBe(200);
    for (let i = 0; i < 3; i++) {
      const snap = await db.doc(`groups/b${i}`).get();
      if (!snap.exists) continue;
      await (onGroupWrittenUsage as any).run({
        data: { before: { exists: false, data: () => undefined }, after: snap },
        params: { groupId: `b${i}` },
      });
    }
    const left = await db.collection('groups').where('createdBy', '==', FREE).get();
    expect(left.size).toBe(1);
    expect((await db.doc(`entitlement_usage/${FREE}`).get()).data()!.groupsCreated).toBe(1);
  });

  test('the owner reads the server counter (what the app shows instead of the denied count())', async () => {
    await db.doc(`entitlement_usage/${BASE}`).set({ groupsCreated: 1 });
    expect(await clientRead(BASE, `entitlement_usage/${BASE}`)).toBe(200);
    expect(await clientRead(GOLD, `entitlement_usage/${BASE}`)).toBe(403);
    expect(await clientWrite(BASE, `entitlement_usage/${BASE}`, { groupsCreated: 0 })).toBe(403);
    expect(await clientWrite(BASE, `entitlement_usage/${BASE}`, { connectCount: 0 }, ['connectCount'])).toBe(403);
  });
});

// ---------------------------------------------------------------------------
describe('P-H5 sponsored communities', () => {
  test('only an active Platinum business may create or turn on a sponsorship', async () => {
    expect(await clientWrite(FREE, 'communities/c_1',
      { createdByUserId: FREE, name: 'x', isSponsored: true, pinnedPromo: { title: 'buy' } })).toBe(403);
    expect(await clientWrite(PLAT, 'communities/c_2', { createdByUserId: PLAT, name: 'x', isSponsored: true })).toBe(403);
    expect(await clientWrite(BIZ, 'communities/c_3',
      { createdByUserId: BIZ, name: 'x', isSponsored: true, sponsorId: BIZ, pinnedPromo: { title: 'buy' } })).toBe(200);
    expect(await clientWrite(FREE, 'communities/c_4', { createdByUserId: FREE, name: 'plain', isSponsored: false, pinnedPromo: null })).toBe(200);
    // The creator (a mod) cannot later switch it on without business...
    expect(await clientWrite(FREE, 'communities/c_4', { isSponsored: true }, ['isSponsored'])).toBe(403);
    // ...but ordinary edits and switching a sponsorship off stay open.
    expect(await clientWrite(FREE, 'communities/c_4', { name: 'renamed' }, ['name'])).toBe(200);
    await db.doc('communities/c_5').set({ createdByUserId: FREE, name: 'legacy', isSponsored: true });
    expect(await clientWrite(FREE, 'communities/c_5', { isSponsored: false }, ['isSponsored'])).toBe(200);
  });
});

// ---------------------------------------------------------------------------
describe('H2 priority support', () => {
  const ticket = (uid: string, extra: any = {}) => ({ userId: uid, subject: 's', status: 'open', priority: 'normal', ...extra });

  test('a user opens tickets as normal and can never raise the priority', async () => {
    expect(await clientWrite(FREE, 'support_chats/t1', ticket(FREE))).toBe(200);
    expect(await clientWrite(FREE, 'support_chats/t2', ticket(FREE, { priority: 'high' }))).toBe(403);
    expect(await clientWrite(FREE, 'support_chats/t3', ticket(FREE, { priorityRank: 9 }))).toBe(403);
    expect(await clientWrite(FREE, 'support_chats/t1', { priority: 'urgent' }, ['priority'])).toBe(403);
    expect(await clientWrite(FREE, 'support_chats/t1', { priorityRank: 3 }, ['priorityRank'])).toBe(403);
    // The 4.6/4.7 app's merge of the last message still works.
    expect(await clientWrite(FREE, 'support_chats/t1', { lastMessage: 'Hi!', lastMessageBy: 'user' }, ['lastMessage', 'lastMessageBy'])).toBe(200);
  });
});

// ---------------------------------------------------------------------------
describe('H4 free monthly boosts (spendCoins)', () => {
  const seedCoins = (uid: string, n: number) => db.doc(`coinBalances/${uid}`).set({
    userId: uid, totalCoins: n, spentCoins: 0,
    coinBatches: [{ batchId: 'b', initialCoins: n, remainingCoins: n, source: 'reward', acquiredDate: past(10 * DAY) }],
  });
  const coins = async (uid: string) => (await db.doc(`coinBalances/${uid}`).get()).data()?.totalCoins ?? 0;

  test('Silver: the first boost of the month is free, the next costs 50 coins', async () => {
    await seedCoins(SILVER, 100);
    const a = await call(spendCoins, { featureId: 'boost', requestId: rid() }, SILVER);
    expect(a.charged).toBe(0);
    expect(a.freeBoost).toBe(true);
    expect(a.freeBoostsLeft).toBe(0);
    expect((await db.doc(`profiles/${SILVER}`).get()).data()!.isBoosted).toBe(true);
    const b = await call(spendCoins, { featureId: 'boost', requestId: rid() }, SILVER);
    expect(b.charged).toBe(50);
    expect(b.freeBoost).toBe(false);
    expect(await coins(SILVER)).toBe(50);
  });

  test('Gold gets 4, the allowance resets with the month, a retry does not use a second one', async () => {
    await seedCoins(GOLD, 0);
    const id = rid();
    await call(spendCoins, { featureId: 'boost', requestId: id }, GOLD);
    await call(spendCoins, { featureId: 'boost', requestId: id }, GOLD); // retried
    let u = (await db.doc(`entitlement_usage/${GOLD}`).get()).data()!;
    expect(u.boostsUsed).toBe(1);
    for (let i = 0; i < 3; i++) await call(spendCoins, { featureId: 'boost', requestId: rid() }, GOLD);
    const e = await refused(call(spendCoins, { featureId: 'boost', requestId: rid() }, GOLD));
    expect(e.details.reason).toBe('insufficient-coins');
    // Last month's usage does not count.
    await db.doc(`entitlement_usage/${GOLD}`).set({ boostMonth: '2000-01', boostsUsed: 4 }, { merge: true });
    const r = await call(spendCoins, { featureId: 'boost', requestId: rid() }, GOLD);
    expect(r.charged).toBe(0);
    u = (await db.doc(`entitlement_usage/${GOLD}`).get()).data()!;
    expect(u.boostsUsed).toBe(1);
  });

  test('free plan / expired tier: boost and travel refused (tier-required); promotion needs a business', async () => {
    await seedCoins(FREE, 1000);
    await seedCoins(EXPIRED, 1000);
    await seedCoins(PLAT, 1000);
    for (const [uid, f] of [[FREE, 'boost'], [EXPIRED, 'boost'], [FREE, 'traveler']] as const) {
      const e = await refused(call(spendCoins, { featureId: f, requestId: rid() }, uid));
      expect(e.details.reason).toBe('tier-required');
    }
    const e = await refused(call(spendCoins, { featureId: 'business_promotion', requestId: rid(), option: 7 }, PLAT));
    expect(e.details.reason).toBe('business-required');
    expect(await coins(FREE)).toBe(1000);
    expect(await coins(PLAT)).toBe(1000);
    // Platinum travels free.
    const t = await call(spendCoins, { featureId: 'traveler', requestId: rid() }, PLAT);
    expect(t.charged).toBe(0);
  });

  test('extra_event is retired: refused before any charge, no credit recorded', async () => {
    await seedCoins(SILVER, 100);
    const e = await refused(call(spendCoins, { featureId: 'extra_event', requestId: rid() }, SILVER));
    expect(String(e.message)).toMatch(/feature-retired/);
    expect((await db.doc(`entitlement_usage/${SILVER}`).get()).data()?.eventExtraCredits).toBeUndefined();
    expect(await coins(SILVER)).toBe(100);
  });
});

// ---------------------------------------------------------------------------
describe('M6 smart replies / word breakdown need Silver+', () => {
  test('a free account is refused before any AI call', async () => {
    await db.doc(`consents/${FREE}`).set({ ai_processing: { accepted: true, version: 2 } });
    const req = (uid: string, task: string) => handleAiAssist({ auth: { uid }, data: { task, text: 'ciao', language: 'it' } });
    for (const task of ['smartReplies', 'wordBreakdown']) {
      const e = await refused(req(FREE, task));
      expect(e.code).toBe('TIER_REQUIRED');
    }
  });
});
