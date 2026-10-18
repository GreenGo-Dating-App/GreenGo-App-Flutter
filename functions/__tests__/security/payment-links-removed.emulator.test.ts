/**
 * Payment links are no longer accepted (owner rule 2026-10-14):
 *
 *   profiles/{uid}.paymentLinks              may only be cleared (any tier);
 *   profiles_private/{uid}.paymentLinksHidden may only be cleared;
 *   user_experiences                          a client may not add a payment
 *     link, cash or the 'link' provider; a legacy listing keeps its stored
 *     values while they stay unchanged (other edits still work).
 * (events: ticket-payments.emulator.test.ts "link mode (LEGACY)".)
 *
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "npx jest --config jest.security.config.js payment-links-removed"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const DAY = 24 * 3600 * 1000;

async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) throw new Error('Refusing: not a local emulator');
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
/** A client PATCH as `uid` (rules apply), masked to `mask`. */
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

const GOLD = 'gold01';
const BIZ = 'biz01';

beforeEach(async () => {
  await clearAll();
  const future = TS.fromMillis(Date.now() + 365 * DAY);
  await db.doc(`profiles/${GOLD}`).set({ displayName: 'Gold', membershipTier: 'GOLD', membershipEndDate: future });
  await db.doc(`profiles/${BIZ}`).set({
    displayName: 'Biz', isBusiness: true, membershipTier: 'PLATINUM', membershipEndDate: future,
    isAgeVerified: true, hostAgreementVersion: 1,
  });
});

describe('profile payment links: clearing only', () => {
  test('no tier may add or change a link; clearing / removing is allowed', async () => {
    expect(await clientWrite(GOLD, `profiles/${GOLD}`, { paymentLinks: { pix: 'me@pix.example' } }, ['paymentLinks'])).toBe(403);
    expect(await clientWrite(BIZ, `profiles/${BIZ}`, { paymentLinks: { paypal: 'https://paypal.me/biz' } }, ['paymentLinks'])).toBe(403);
    // Legacy links (written before the rule) can be cleared or removed.
    await db.doc(`profiles/${GOLD}`).update({ paymentLinks: { pix: 'me@pix.example', paypal: 'https://paypal.me/g' } });
    expect(await clientWrite(GOLD, `profiles/${GOLD}`, { paymentLinks: { pix: 'other@pix.example', paypal: 'https://paypal.me/g' } }, ['paymentLinks'])).toBe(403);
    expect(await clientWrite(GOLD, `profiles/${GOLD}`, { paymentLinks: { pix: '', paypal: 'https://paypal.me/g' } }, ['paymentLinks'])).toBe(200);
    expect(await clientWrite(GOLD, `profiles/${GOLD}`, {}, ['paymentLinks'])).toBe(200);
    expect((await db.doc(`profiles/${GOLD}`).get()).data()!.paymentLinks).toBeUndefined();
  });

  test('profiles_private.paymentLinksHidden: clearing only', async () => {
    await db.doc(`profiles_private/${GOLD}`).set({ paymentLinksHidden: { pix: 'old@pix.example' } });
    expect(await clientWrite(GOLD, `profiles_private/${GOLD}`, { paymentLinksHidden: { pix: 'old@pix.example', wise: 'w' } }, ['paymentLinksHidden'])).toBe(403);
    expect(await clientWrite(GOLD, `profiles_private/${GOLD}`, {}, ['paymentLinksHidden'])).toBe(200);
  });
});

describe('experiences: payment links refused on update', () => {
  const experience = (over: Record<string, any> = {}) => ({
    hostId: BIZ, status: 'draft', title: 'Street food walk',
    description: 'Taste the best pastel and caldo de cana around the old market.',
    category: 'foodDrink', photoUrls: [], included: ['Tastings'], notIncluded: [],
    locationName: 'Mercado Municipal', durationMinutes: 120, languages: ['Portuguese'],
    maxGroupSize: 8, isFree: false, price: 50, currency: 'BRL',
    paymentMethods: ['online'], paymentProvider: 'stripe', ...over,
  });

  test('a client cannot switch a listing to cash / a payment link / the link provider', async () => {
    await db.doc('user_experiences/x1').set(experience());
    const w = (data: Record<string, any>) => clientWrite(BIZ, 'user_experiences/x1', data, Object.keys(data));
    expect(await w({ paymentMethods: ['cash'] })).toBe(403);
    expect(await w({ paymentMethods: ['cash', 'link'], paymentLink: { type: 'pix', value: 'k' } })).toBe(403);
    expect(await w({ paymentProvider: 'link', paymentLinkMethod: 'pix' })).toBe(403);
    expect(await w({ paymentInstructions: 'Pay me at the door' })).toBe(403);
    expect(await w({ paymentLink: { type: 'pix', value: 'k' } })).toBe(403);
    // Allowed: the connected providers, and turning the listing free.
    expect(await w({ paymentProvider: 'mercadopago' })).toBe(200);
    expect(await w({ isFree: true, price: 0, paymentMethods: [], paymentProvider: null })).toBe(200);
  });

  test('a legacy link / cash listing stays editable while its payment fields are unchanged', async () => {
    await db.doc('user_experiences/old').set(experience({
      paymentMethods: ['cash', 'link'], paymentProvider: null, paymentLink: { type: 'paypal', value: 'https://paypal.me/biz' },
    }));
    expect(await clientWrite(BIZ, 'user_experiences/old', { title: 'Old food walk' }, ['title'])).toBe(200);
    // ... and can move to a connected provider (clearing the legacy fields).
    expect(await clientWrite(BIZ, 'user_experiences/old',
      { paymentMethods: ['online'], paymentProvider: 'stripe', paymentLink: null },
      ['paymentMethods', 'paymentProvider', 'paymentLink'])).toBe(200);
  });
});
