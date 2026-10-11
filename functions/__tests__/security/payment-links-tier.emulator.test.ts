/**
 * Personal payment links are a Silver / Gold / Platinum perk (owner rule
 * 2026-10-12): "Silver, Gold and Platinum have payment links in Account
 * settings. That is visible only when the tier is Silver, Gold or Platinum."
 *
 *   writes   firestore(.additive).rules paymentLinksWriteOk(): add / change
 *            only with an effective paid tier or TEST; clearing always OK.
 *   reads    the server MOVES the links of a lapsed tier to the owner-only
 *            profiles_private/{uid}.paymentLinksHidden and back on renewal
 *            (functions/src/profiles/paymentLinksVisibility.ts, run by
 *            mirrorPrivateProfileFields + sweepExpiredPaymentLinks).
 *
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "npx jest --config jest.security.config.js payment-links-tier"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });

import {
  handlePaymentLinksProfileWrite,
  needsPaymentLinksSync,
  runPaymentLinksSweep,
  syncPaymentLinksVisibility,
} from '../../src/profiles/paymentLinksVisibility';
import { mirrorPrivateProfileFields } from '../../src/profiles/privateProfileTriggers';

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
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, firebase: { sign_in_provider: 'password' } })}.`;
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
/** A client write (PATCH, masked to `mask`) as `uid`, through the rules. */
async function clientWrite(uid: string, path: string, data: Record<string, any>, mask: string[]): Promise<number> {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  const q = '?' + mask.map((m) => `updateMask.fieldPaths=${encodeURIComponent(m)}`).join('&');
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
/** The app writes every PaymentMethod key (null when unset). */
function appLinks(over: Record<string, string | null>): Record<string, string | null> {
  const keys = ['pix', 'mercadoPago', 'picPay', 'paypal', 'venmo', 'cashApp', 'revolut', 'wise', 'monzo', 'kofi', 'stripe'];
  return { ...Object.fromEntries(keys.map((k) => [k, null])), ...over };
}
const setLinks = (uid: string, links: Record<string, any> | null) =>
  clientWrite(uid, `profiles/${uid}`, links === null ? {} : { paymentLinks: links }, ['paymentLinks']);

const future = (ms = 30 * DAY) => TS.fromMillis(Date.now() + ms);
const past = (ms = DAY) => TS.fromMillis(Date.now() - ms);

const FREE = 'free01';
const BASE = 'base01'; // Base membership only: NOT a paid tier
const SILVER = 'silver01';
const GOLD = 'gold01';
const PLAT = 'plat01';
const TEST = 'test01';
const EXPIRED = 'expired01'; // Gold whose end date passed (job not run yet)
const OTHER = 'other01';
const LINKS = { pix: 'me@pix.example', paypal: 'myname' };

async function seedProfiles() {
  await Promise.all([
    db.doc(`profiles/${FREE}`).set({ userId: FREE, membershipTier: 'FREE' }),
    db.doc(`profiles/${BASE}`).set({ userId: BASE, membershipTier: 'FREE', hasBaseMembership: true, baseMembershipEndDate: future(365 * DAY) }),
    db.doc(`profiles/${SILVER}`).set({ userId: SILVER, membershipTier: 'SILVER', membershipEndDate: future() }),
    db.doc(`profiles/${GOLD}`).set({ userId: GOLD, membershipTier: 'GOLD', membershipEndDate: future() }),
    db.doc(`profiles/${PLAT}`).set({ userId: PLAT, membershipTier: 'PLATINUM', membershipEndDate: future() }),
    db.doc(`profiles/${TEST}`).set({ userId: TEST, membershipTier: 'TEST' }),
    db.doc(`profiles/${EXPIRED}`).set({ userId: EXPIRED, membershipTier: 'GOLD', membershipEndDate: past(), paymentLinks: appLinks(LINKS) }),
    db.doc(`profiles/${OTHER}`).set({ userId: OTHER, membershipTier: 'GOLD', membershipEndDate: future() }),
  ]);
}

beforeEach(async () => {
  await clearAll();
  await seedProfiles();
});
afterAll(() => fft.cleanup());

const pub = async (uid: string) => (await db.doc(`profiles/${uid}`).get()).data() || {};
const priv = async (uid: string) => (await db.doc(`profiles_private/${uid}`).get()).data() || {};

// ---------------------------------------------------------------------------
describe('writes (rules)', () => {
  test('FREE and Base-only users cannot add payment links', async () => {
    expect(await setLinks(FREE, appLinks(LINKS))).toBe(403);
    expect(await setLinks(BASE, appLinks(LINKS))).toBe(403);
    expect(await setLinks(FREE, { pix: 'x@pix.example' })).toBe(403);
  });

  test('Silver, Gold, Platinum and TEST can add and change them', async () => {
    for (const uid of [SILVER, GOLD, PLAT, TEST]) {
      expect(await setLinks(uid, appLinks(LINKS))).toBe(200);
      expect(await setLinks(uid, appLinks({ ...LINKS, wise: 'wisename' }))).toBe(200);
    }
  });

  test('expired tier: cannot add or change, can clear (whole map or one entry)', async () => {
    expect(await setLinks(EXPIRED, appLinks({ ...LINKS, wise: 'new' }))).toBe(403);
    expect(await setLinks(EXPIRED, appLinks({ ...LINKS, pix: 'other@pix.example' }))).toBe(403);
    expect(await setLinks(EXPIRED, appLinks({ pix: LINKS.pix }))).toBe(200); // paypal removed
    expect(await setLinks(EXPIRED, appLinks({}))).toBe(200); // everything null
    expect(await setLinks(EXPIRED, null)).toBe(200); // field deleted
  });

  test('a profile save that carries the stored links unchanged is not refused for a lapsed tier', async () => {
    // Full app payload re-sends the same map: not an add.
    expect(await clientWrite(EXPIRED, `profiles/${EXPIRED}`, { bio: 'hi', paymentLinks: appLinks(LINKS) }, ['bio', 'paymentLinks'])).toBe(200);
    // Legacy stored map without the null keys: still unchanged values.
    await db.doc(`profiles/${EXPIRED}`).update({ paymentLinks: { ...LINKS } });
    expect(await clientWrite(EXPIRED, `profiles/${EXPIRED}`, { bio: 'hey', paymentLinks: appLinks(LINKS) }, ['bio', 'paymentLinks'])).toBe(200);
  });

  test('a client cannot self-grant a tier to unlock links in the same write', async () => {
    expect(await clientWrite(FREE, `profiles/${FREE}`, {
      membershipTier: 'GOLD', membershipEndDate: new Date(Date.now() + 30 * DAY), paymentLinks: appLinks(LINKS),
    }, ['membershipTier', 'membershipEndDate', 'paymentLinks'])).toBe(403);
  });

  test('downgrading to FREE in the same write as adding links is refused', async () => {
    expect(await clientWrite(GOLD, `profiles/${GOLD}`, { membershipTier: 'FREE', paymentLinks: appLinks(LINKS) },
      ['membershipTier', 'paymentLinks'])).toBe(403);
  });

  test('other users can never write someone else\'s links', async () => {
    expect(await clientWrite(OTHER, `profiles/${GOLD}`, { paymentLinks: appLinks(LINKS) }, ['paymentLinks'])).toBe(403);
  });
});

// ---------------------------------------------------------------------------
describe('visibility (server hide / restore)', () => {
  test('hide: lapsed tier -> links moved to profiles_private, public field cleared', async () => {
    expect(await syncPaymentLinksVisibility(EXPIRED)).toBe('hidden');
    const p = await pub(EXPIRED);
    expect(p.paymentLinks).toBeUndefined();
    expect(p.paymentLinksExpireAt).toBeUndefined();
    const v = await priv(EXPIRED);
    expect(v.paymentLinksHidden).toEqual(LINKS); // null entries dropped
    expect(v.paymentLinksHiddenAt).toBeInstanceOf(TS);
  });

  test('idempotent: a second run (and the re-triggered event) are no-ops', async () => {
    expect(await syncPaymentLinksVisibility(EXPIRED)).toBe('hidden');
    expect(await syncPaymentLinksVisibility(EXPIRED)).toBe('noop');
    const after = await pub(EXPIRED);
    expect(needsPaymentLinksSync(after, after)).toBe(false);
    expect(await priv(EXPIRED)).toMatchObject({ paymentLinksHidden: LINKS });
  });

  test('concurrent runs never lose the links', async () => {
    const r = await Promise.all([1, 2, 3, 4].map(() => syncPaymentLinksVisibility(EXPIRED)));
    expect(r.filter((x) => x === 'hidden')).toHaveLength(1);
    expect((await pub(EXPIRED)).paymentLinks).toBeUndefined();
    expect((await priv(EXPIRED)).paymentLinksHidden).toEqual(LINKS);
  });

  test('restore on upgrade: hidden links come back public, hidden copy removed', async () => {
    await syncPaymentLinksVisibility(EXPIRED);
    const end = future(365 * DAY);
    await db.doc(`profiles/${EXPIRED}`).update({ membershipTier: 'PLATINUM', membershipEndDate: end });
    const before = await pub(EXPIRED);
    // The tier change alone is enough for the hook to run.
    expect(needsPaymentLinksSync({ ...before, membershipTier: 'FREE' }, before)).toBe(true);
    expect(await syncPaymentLinksVisibility(EXPIRED)).toBe('restored');
    const p = await pub(EXPIRED);
    expect(p.paymentLinks).toEqual(LINKS);
    expect(p.paymentLinksExpireAt.toMillis()).toBe(end.toMillis());
    const v = await priv(EXPIRED);
    expect(v.paymentLinksHidden).toBeUndefined();
    expect(v.paymentLinksHiddenAt).toBeUndefined();
    expect(await syncPaymentLinksVisibility(EXPIRED)).toBe('noop');
  });

  test('restore keeps links added after the renewal (public wins per provider)', async () => {
    await syncPaymentLinksVisibility(EXPIRED);
    await db.doc(`profiles/${EXPIRED}`).update({
      membershipTier: 'GOLD', membershipEndDate: future(), paymentLinks: { pix: 'new@pix.example' },
    });
    expect(await syncPaymentLinksVisibility(EXPIRED)).toBe('restored');
    expect((await pub(EXPIRED)).paymentLinks).toEqual({ pix: 'new@pix.example', paypal: 'myname' });
  });

  test('expiry marker follows the paid tier; TEST has none', async () => {
    expect(await setLinks(GOLD, appLinks(LINKS))).toBe(200);
    expect(await handlePaymentLinksProfileWrite(GOLD, undefined, await pub(GOLD))).toBe('expiry_updated');
    const g = await pub(GOLD);
    expect(g.paymentLinksExpireAt.toMillis()).toBe(g.membershipEndDate.toMillis());
    // A client tampering with the marker is corrected by the next event.
    await db.doc(`profiles/${GOLD}`).update({ paymentLinksExpireAt: admin.firestore.FieldValue.delete() });
    expect(await handlePaymentLinksProfileWrite(GOLD, g, await pub(GOLD))).toBe('expiry_updated');
    expect((await pub(GOLD)).paymentLinksExpireAt.toMillis()).toBe(g.membershipEndDate.toMillis());
    // Hot-path write (presence): no sync, no read.
    const now = await pub(GOLD);
    expect(needsPaymentLinksSync(now, { ...now, lastSeen: TS.now() })).toBe(false);

    expect(await setLinks(TEST, appLinks(LINKS))).toBe(200);
    const t = await pub(TEST);
    expect(await handlePaymentLinksProfileWrite(TEST, t, t)).toBe('skipped');
    expect(await syncPaymentLinksVisibility(TEST)).toBe('noop');
    expect((await pub(TEST)).paymentLinksExpireAt).toBeUndefined();
  });

  test('scheduled sweep hides every lapsed owner found by the expiry marker, nobody else', async () => {
    for (const uid of [SILVER, GOLD, PLAT]) {
      expect(await setLinks(uid, appLinks(LINKS))).toBe(200);
      await syncPaymentLinksVisibility(uid);
    }
    // Silver and Gold lapse by date; nobody writes their profile.
    await db.doc(`profiles/${SILVER}`).update({ membershipEndDate: past(HOUR), paymentLinksExpireAt: past(HOUR) });
    await db.doc(`profiles/${GOLD}`).update({ membershipEndDate: past(HOUR), paymentLinksExpireAt: past(HOUR) });
    const r = await runPaymentLinksSweep({ pageSize: 1 });
    expect(r).toMatchObject({ hidden: 2, failed: 0 });
    expect((await pub(SILVER)).paymentLinks).toBeUndefined();
    expect((await pub(GOLD)).paymentLinks).toBeUndefined();
    expect((await pub(PLAT)).paymentLinks).toEqual(appLinks(LINKS));
    expect((await priv(SILVER)).paymentLinksHidden).toEqual(LINKS);
    // Queue consumed: a second sweep does nothing.
    expect(await runPaymentLinksSweep()).toMatchObject({ scanned: 0 });
  });

  test('sweep: a renewed owner with a stale marker keeps the links and gets a new marker', async () => {
    expect(await setLinks(SILVER, appLinks(LINKS))).toBe(200);
    await db.doc(`profiles/${SILVER}`).update({ paymentLinksExpireAt: past(HOUR) });
    expect(await runPaymentLinksSweep()).toMatchObject({ hidden: 0, updated: 1 });
    const p = await pub(SILVER);
    expect(p.paymentLinks).toEqual(appLinks(LINKS));
    expect(p.paymentLinksExpireAt.toMillis()).toBe(p.membershipEndDate.toMillis());
  });

  test('the profiles onWrite trigger (mirrorPrivateProfileFields) runs the hook', async () => {
    const snap = (d: Record<string, any>) => ({ exists: true, data: () => d });
    const before = snap({ userId: EXPIRED, membershipTier: 'GOLD', membershipEndDate: future() });
    const after = snap(await pub(EXPIRED));
    await (mirrorPrivateProfileFields as any).run({ data: { before, after }, params: { uid: EXPIRED } });
    expect((await pub(EXPIRED)).paymentLinks).toBeUndefined();
    expect((await priv(EXPIRED)).paymentLinksHidden).toEqual(LINKS);
  });
});

// ---------------------------------------------------------------------------
describe('the hidden copy (profiles_private)', () => {
  beforeEach(async () => {
    await syncPaymentLinksVisibility(EXPIRED);
  });

  test('only the owner can read it; others cannot', async () => {
    expect(await clientRead(EXPIRED, `profiles_private/${EXPIRED}`)).toBe(200);
    expect(await clientRead(OTHER, `profiles_private/${EXPIRED}`)).toBe(403);
    expect(await clientRead(FREE, `profiles_private/${EXPIRED}`)).toBe(403);
  });

  test('the public profile no longer carries the links for other readers', async () => {
    const host = process.env.FIRESTORE_EMULATOR_HOST!;
    const res = await fetch(`http://${host}/v1/projects/${PROJECT}/databases/(default)/documents/profiles/${EXPIRED}`, {
      headers: { Authorization: `Bearer ${idToken(OTHER)}` },
    });
    const body = await res.json() as any;
    expect(res.status).toBe(200);
    expect(body.fields.paymentLinks).toBeUndefined();
  });

  test('the owner can clear it but never add to it or change it', async () => {
    const path = `profiles_private/${EXPIRED}`;
    expect(await clientWrite(EXPIRED, path, { paymentLinksHidden: { ...LINKS, wise: 'x' } }, ['paymentLinksHidden'])).toBe(403);
    expect(await clientWrite(EXPIRED, path, { paymentLinksHidden: { pix: 'changed@pix.example', paypal: LINKS.paypal } }, ['paymentLinksHidden'])).toBe(403);
    expect(await clientWrite(EXPIRED, path, { paymentLinksHidden: { pix: LINKS.pix } }, ['paymentLinksHidden'])).toBe(200);
    expect(await clientWrite(EXPIRED, path, {}, ['paymentLinksHidden'])).toBe(200);
    expect((await priv(EXPIRED)).paymentLinksHidden).toBeUndefined();
  });

  test('nobody else can write it', async () => {
    expect(await clientWrite(OTHER, `profiles_private/${EXPIRED}`, {}, ['paymentLinksHidden'])).toBe(403);
  });

  test('the owner cannot create a private doc carrying hidden links', async () => {
    expect(await clientWrite(FREE, `profiles_private/${FREE}`, { paymentLinksHidden: LINKS }, ['paymentLinksHidden'])).toBe(403);
  });
});

// ---------------------------------------------------------------------------
describe('backfill script (scripts/backfill-payment-links-visibility.ts)', () => {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const { run } = require('../../scripts/backfill-payment-links-visibility');

  test('dry-run reports and writes nothing; --apply hides lapsed and marks paid owners', async () => {
    expect(await setLinks(GOLD, appLinks(LINKS))).toBe(200);
    await db.doc(`profiles/${FREE}`).update({ paymentLinks: { kofi: 'legacyname' } }); // legacy data
    const before = JSON.stringify([await pub(EXPIRED), await pub(GOLD), await pub(FREE)]);

    const dry = await run(db, false, 1);
    expect(dry).toMatchObject({ mode: 'DRY-RUN', profilesWithLinks: 3, hide: 2, setExpiry: 1, keep: 0 });
    expect(JSON.stringify([await pub(EXPIRED), await pub(GOLD), await pub(FREE)])).toBe(before);
    expect((await db.collection('profiles_private').get()).size).toBe(0);

    const applied = await run(db, true, 1);
    expect(applied.applied).toMatchObject({ hidden: 2, expiryUpdated: 1, failed: 0 });
    expect((await pub(FREE)).paymentLinks).toBeUndefined();
    expect((await priv(FREE)).paymentLinksHidden).toEqual({ kofi: 'legacyname' });
    expect((await pub(GOLD)).paymentLinksExpireAt).toBeInstanceOf(TS);
    // Re-run: only the paid owner is still a candidate, nothing to do.
    expect(await run(db, true, 1)).toMatchObject({ profilesWithLinks: 1, hide: 0, setExpiry: 0, keep: 1 });
  });
});
