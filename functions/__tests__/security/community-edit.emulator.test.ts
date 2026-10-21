/**
 * Community info edit (owner request 2026-10-21: "who created a community can
 * change the community info and featured image"), against the Firestore
 * emulator rules:
 *
 *  1. The CREATOR can edit name / description / type / languages / tags /
 *     city / country / public flag and replace or remove the cover
 *     (imageUrl), with the app's full-doc update shape.
 *  2. A plain member, a stranger and a community ADMIN (role) can NOT change
 *     any of those; admins keep editing rules / resources (also on a legacy
 *     doc that lacks some info fields).
 *  3. Nobody - creator included - can rewrite createdByUserId /
 *     createdByName / createdAt / memberCount through an edit, nor switch
 *     sponsorship on without an active Platinum business.
 *  4. The join/leave counter path and platform admins keep working.
 *  5. syncCommunityNameOnExperiences (functions) refreshes the denormalised
 *     communityName on linked experiences, paged.
 *
 * Run against BOTH firestore.rules and firestore.additive.rules:
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "cd functions && npx jest -i --config jest.security.config.js community-edit"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import { syncCommunityNameOnExperiences } from '../../src/user_experiences/communityRename';

/* eslint-disable @typescript-eslint/no-explicit-any */

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();

function emulatorHost(env: string): string {
  const h = process.env[env]!;
  if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(h)) throw new Error(`Refusing: ${env} is not a local emulator`);
  return h;
}
async function clearAll() {
  const host = emulatorHost('FIRESTORE_EMULATOR_HOST');
  await new Promise<void>((resolve, reject) => {
    const r = http.request({
      host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE',
      path: `/emulator/v1/projects/${PROJECT}/databases/(default)/documents`,
    }, (res) => { res.resume(); res.on('end', resolve); });
    r.on('error', reject);
    r.end();
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
/**
 * A client `update()` as [uid] through the rules: PATCH with an update mask
 * of exactly the given keys, and `currentDocument.exists=true` (update, not
 * create).
 */
async function clientUpdate(uid: string, path: string, data: Record<string, any>): Promise<number> {
  const host = emulatorHost('FIRESTORE_EMULATOR_HOST');
  const q = [
    ...Object.keys(data).map((m) => `updateMask.fieldPaths=${encodeURIComponent(m)}`),
    'currentDocument.exists=true',
  ].join('&');
  const res = await fetch(`http://${host}/v1/projects/${PROJECT}/databases/(default)/documents/${path}?${q}`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, toValue(v)])) }),
  });
  await res.text();
  return res.status;
}

const CREATOR = 'u_creator';
const ADMIN_MEMBER = 'u_comm_admin';
const MEMBER = 'u_member';
const STRANGER = 'u_stranger';
const PLATFORM_ADMIN = 'u_platform_admin';
const C = 'communities/c_edit';
const CREATED_AT = new Date('2026-10-01T10:00:00.123Z');

/** The community doc as the app writes it (CommunityModel.toFirestore). */
function communityDoc(): Record<string, any> {
  return {
    name: 'Old name',
    description: 'An old description of the group',
    type: 'general',
    imageUrl: 'https://example.test/old-cover.jpg',
    createdByUserId: CREATOR,
    createdByName: 'Creator',
    createdAt: CREATED_AT,
    memberCount: 3,
    languages: ['en'],
    tags: ['coffee'],
    isPublic: true,
    city: null,
    country: null,
    lastMessagePreview: null,
    lastActivityAt: null,
    sponsorId: null,
    isSponsored: false,
    pinnedPromo: null,
    rules: null,
    resourceLinks: [],
    searchKeywords: ['old', 'old name', 'coffee'],
  };
}
/** The app's update payload: the whole doc minus the denormalised fields. */
function appUpdate(changes: Record<string, any>): Record<string, any> {
  const d = { ...communityDoc(), ...changes };
  delete d.memberCount;
  delete d.lastMessagePreview;
  delete d.lastActivityAt;
  return d;
}

beforeEach(async () => {
  await clearAll();
  await db.doc(C).set({ ...communityDoc(), createdAt: admin.firestore.Timestamp.fromDate(CREATED_AT) });
  await db.doc(`${C}/members/${CREATOR}`).set({ userId: CREATOR, role: 'owner' });
  await db.doc(`${C}/members/${ADMIN_MEMBER}`).set({ userId: ADMIN_MEMBER, role: 'admin' });
  await db.doc(`${C}/members/${MEMBER}`).set({ userId: MEMBER, role: 'member' });
  for (const u of [CREATOR, ADMIN_MEMBER, MEMBER, STRANGER]) {
    await db.doc(`users/${u}`).set({ role: 'user' });
  }
  await db.doc(`users/${PLATFORM_ADMIN}`).set({ role: 'admin' });
});

const INFO_EDIT = {
  name: 'New name',
  description: 'A brand new description for everyone',
  type: 'travel_group',
  imageUrl: 'https://example.test/new-cover.jpg',
  languages: ['en', 'pt'],
  tags: ['coffee', 'walks'],
  isPublic: false,
  city: 'Lisbon',
  country: 'Portugal',
  searchKeywords: ['new', 'new name', 'lisbon', 'coffee', 'walks'],
};

describe('creator edits the community info and cover', () => {
  test('full-doc edit of every info field (app update shape) is allowed', async () => {
    expect(await clientUpdate(CREATOR, C, appUpdate(INFO_EDIT))).toBe(200);
    const d = (await db.doc(C).get()).data()!;
    expect(d.name).toBe('New name');
    expect(d.imageUrl).toBe('https://example.test/new-cover.jpg');
    expect(d.city).toBe('Lisbon');
    expect(d.isPublic).toBe(false);
    expect(d.memberCount).toBe(3);
    expect(d.createdByUserId).toBe(CREATOR);
  });

  test('replacing only the cover / removing it is allowed', async () => {
    expect(await clientUpdate(CREATOR, C, { imageUrl: 'https://example.test/other.jpg' })).toBe(200);
    expect(await clientUpdate(CREATOR, C, appUpdate({ imageUrl: null }))).toBe(200);
    expect((await db.doc(C).get()).data()!.imageUrl).toBeNull();
  });

  test('cover position (coverFocalX / coverFocalY / coverZoom) is creator-editable', async () => {
    expect(await clientUpdate(CREATOR, C, appUpdate({ coverFocalX: -0.5, coverFocalY: 0.25, coverZoom: 1.4 }))).toBe(200);
    const d = (await db.doc(C).get()).data()!;
    expect([d.coverFocalX, d.coverFocalY, d.coverZoom]).toEqual([-0.5, 0.25, 1.4]);
    expect(await clientUpdate(CREATOR, C, { coverFocalX: 0.9 })).toBe(200);
  });

  test('a creator who left the community can still edit it', async () => {
    await db.doc(`${C}/members/${CREATOR}`).delete();
    expect(await clientUpdate(CREATOR, C, { name: 'Still mine' })).toBe(200);
  });
});

describe('non-creators cannot edit the info or cover', () => {
  for (const [who, uid] of [['member', MEMBER], ['stranger', STRANGER], ['community admin', ADMIN_MEMBER]] as const) {
    test(`${who}: name / description / cover / type / languages / tags / city / public denied`, async () => {
      expect(await clientUpdate(uid, C, { name: 'Hijacked' })).toBe(403);
      expect(await clientUpdate(uid, C, { description: 'Hijacked description text' })).toBe(403);
      expect(await clientUpdate(uid, C, { imageUrl: 'https://example.test/evil.jpg' })).toBe(403);
      expect(await clientUpdate(uid, C, { imageUrl: null })).toBe(403);
      expect(await clientUpdate(uid, C, { type: 'study_group' })).toBe(403);
      expect(await clientUpdate(uid, C, { languages: ['fr'] })).toBe(403);
      expect(await clientUpdate(uid, C, { tags: ['spam'] })).toBe(403);
      expect(await clientUpdate(uid, C, { city: 'Nowhere' })).toBe(403);
      expect(await clientUpdate(uid, C, { isPublic: false })).toBe(403);
      expect(await clientUpdate(uid, C, appUpdate(INFO_EDIT))).toBe(403);
      expect((await db.doc(C).get()).data()!.name).toBe('Old name');
    });
  }

  for (const [who, uid] of [['member', MEMBER], ['stranger', STRANGER], ['community admin', ADMIN_MEMBER]] as const) {
    test(`${who}: cover position (focal point / zoom) denied`, async () => {
      expect(await clientUpdate(uid, C, { coverFocalX: 0.5 })).toBe(403);
      expect(await clientUpdate(uid, C, { coverFocalY: -1 })).toBe(403);
      expect(await clientUpdate(uid, C, { coverZoom: 2 })).toBe(403);
      expect(await clientUpdate(uid, C, appUpdate({ coverFocalX: 0.3, coverFocalY: 0.3, coverZoom: 1.2 }))).toBe(403);
    });
  }

  test('community admin rules edit with the DEFAULT cover position on a doc without it still works', async () => {
    // The app writes coverFocalX/Y 0 and coverZoom 1 (read defaults) on its
    // full-doc update; a doc that never had them must not count as a change.
    expect(await clientUpdate(ADMIN_MEMBER, C, appUpdate({
      coverFocalX: 0, coverFocalY: 0, coverZoom: 1, rules: 'Be kind',
    }))).toBe(200);
    expect(await clientUpdate(ADMIN_MEMBER, C, appUpdate({
      coverFocalX: 0.0, coverFocalY: 0.0, coverZoom: 1.0, rules: 'Be kinder',
    }))).toBe(200);
  });

  test('community admin still edits rules / resources (app full-doc shape)', async () => {
    expect(await clientUpdate(ADMIN_MEMBER, C, appUpdate({
      rules: 'Be kind',
      resourceLinks: [{ title: 'Guide', url: 'https://example.test/guide' }],
    }))).toBe(200);
    expect((await db.doc(C).get()).data()!.rules).toBe('Be kind');
  });

  test('community admin rules edit on a LEGACY doc missing info fields still works', async () => {
    const legacy = communityDoc();
    delete legacy.languages;
    delete legacy.tags;
    delete legacy.city;
    delete legacy.country;
    delete legacy.isPublic;
    delete legacy.imageUrl;
    delete legacy.searchKeywords;
    await db.doc(C).set({ ...legacy, createdAt: admin.firestore.Timestamp.fromDate(CREATED_AT) });
    // The app fills the read defaults back in on its full-doc write.
    expect(await clientUpdate(ADMIN_MEMBER, C, appUpdate({
      languages: [], tags: [], city: null, country: null, isPublic: true, imageUrl: null,
      searchKeywords: ['old', 'old name'], rules: 'Be kind',
    }))).toBe(200);
  });

  test('a platform admin may still fix a community name', async () => {
    expect(await clientUpdate(PLATFORM_ADMIN, C, { name: 'Moderated name' })).toBe(200);
  });
});

describe('protected fields cannot change through an edit', () => {
  for (const [who, uid] of [['creator', CREATOR], ['community admin', ADMIN_MEMBER]] as const) {
    test(`${who}: createdByUserId / createdByName / createdAt / memberCount denied`, async () => {
      expect(await clientUpdate(uid, C, { createdByUserId: STRANGER })).toBe(403);
      expect(await clientUpdate(uid, C, appUpdate({ createdByUserId: uid === CREATOR ? STRANGER : uid }))).toBe(403);
      expect(await clientUpdate(uid, C, { createdByName: 'Someone else' })).toBe(403);
      expect(await clientUpdate(uid, C, { createdAt: new Date('2020-01-01T00:00:00Z') })).toBe(403);
      expect(await clientUpdate(uid, C, { name: 'New name', memberCount: 999 })).toBe(403);
      const d = (await db.doc(C).get()).data()!;
      expect(d.createdByUserId).toBe(CREATOR);
      expect(d.memberCount).toBe(3);
    });
  }

  test('creator cannot switch sponsorship on without an active Platinum business', async () => {
    expect(await clientUpdate(CREATOR, C, appUpdate({ ...INFO_EDIT, isSponsored: true, sponsorId: CREATOR }))).toBe(403);
    expect(await clientUpdate(CREATOR, C, { pinnedPromo: { title: 'Buy', body: 'now' } })).toBe(403);
  });

  test('the join/leave counter path keeps working for a member', async () => {
    expect(await clientUpdate(MEMBER, C, { memberCount: 4 })).toBe(200);
    expect(await clientUpdate(MEMBER, C, { lastMessagePreview: 'hi', lastActivityAt: new Date() })).toBe(200);
  });
});

describe('rename sync of linked experiences (functions)', () => {
  test('pages through every linked experience and skips unlinked ones', async () => {
    for (let i = 0; i < 7; i++) {
      await db.doc(`user_experiences/x${i}`).set({ communityId: 'c_edit', communityName: 'Old name', title: `t${i}` });
    }
    await db.doc('user_experiences/other').set({ communityId: 'c_other', communityName: 'Other' });
    await db.doc('user_experiences/x3').update({ communityName: 'New name' }); // already current

    const n = await syncCommunityNameOnExperiences(db, 'c_edit', 'New name', 3);
    expect(n).toBe(6);
    for (let i = 0; i < 7; i++) {
      expect((await db.doc(`user_experiences/x${i}`).get()).data()!.communityName).toBe('New name');
    }
    expect((await db.doc('user_experiences/other').get()).data()!.communityName).toBe('Other');

    // Idempotent: a retried delivery rewrites nothing.
    expect(await syncCommunityNameOnExperiences(db, 'c_edit', 'New name', 3)).toBe(0);
  });
});
