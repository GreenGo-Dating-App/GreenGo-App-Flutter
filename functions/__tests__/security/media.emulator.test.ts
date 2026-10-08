/**
 * Phase 1 / P1-3 (audit H-06 / L-01): getMediaUrl, membership-checked
 * short-lived URLs for private chat / group / support media.
 *
 * Real Firestore + Auth + Storage emulators. Only the V4 URL signing is
 * stubbed (it needs the IAM signBlob API, which the emulator does not have).
 * The Storage RULES themselves are covered by the real-client script
 * media.rules.emulator.js (web SDK against the Storage emulator).
 *
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "npx jest --config jest.security.config.js"
 *
 * The module is required lazily, so against pre-change code (no getMediaUrl)
 * every test here fails.
 */

import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';
import { File } from '@google-cloud/storage';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) {
  admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
}
const fft = functionsTest({ projectId: PROJECT });
const db = admin.firestore();
const bucket = () => admin.storage().bucket();

// eslint-disable-next-line @typescript-eslint/no-var-requires
const maybe = (p: string): any => { try { return require(p); } catch { return {}; } };
const mod = maybe('../../src/media/mediaAccess');

const signSpy = jest.spyOn(File.prototype, 'getSignedUrl')
  .mockImplementation(async function (this: File) { return [`https://signed.example/${this.name}?X-Goog-Expires=900`]; } as any);

function clearFirestore() {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) throw new Error('Not a local emulator');
  return new Promise<void>((resolve, reject) => {
    const req = http.request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE',
      path: `/emulator/v1/projects/${PROJECT}/databases/(default)/documents` }, (res) => { res.resume(); res.on('end', resolve); });
    req.on('error', reject);
    req.end();
  });
}

const A = 'aliceUid000000000000000000001';
const B = 'bobUid00000000000000000000002';
const M = 'malloryUid000000000000000003';
const AGENT = 'agentUid0000000000000000004';
const [LO, HI] = [A, B].sort();

const call = (data: any, uid?: string, token: Record<string, any> = {}) =>
  (fft.wrap(mod.getMediaUrl) as any)({ data, auth: uid ? { uid, token } : undefined });
const put = (path: string) => bucket().file(path).save(Buffer.from('x'), { contentType: 'image/jpeg', resumable: false });
const dlUrl = (path: string) =>
  `https://firebasestorage.googleapis.com/v0/b/${PROJECT}.appspot.com/o/${encodeURIComponent(path)}?alt=media&token=t`;

beforeAll(async () => {
  if (!process.env.FIREBASE_STORAGE_EMULATOR_HOST) throw new Error('Storage emulator required');
  await clearFirestore();
  await db.doc('matches/m1').set({ userId1: A, userId2: B });
  await db.doc('conversations/legacy1').set({ userId1: A, userId2: B });
  await db.doc('groups/g1').set({ participants: [A, B] });
  await db.doc('conversations/sup1').set({ userId1: A, userId2: 'support_system', supportAgentId: AGENT });
  for (const p of ['chat_images/m1/a.jpg', `chat_voice/search_${LO}_${HI}/v.m4a`, 'chat_videos/legacy1/v.mp4',
    'group_media/g1/g.jpg', 'support_attachments/sup1/s.jpg']) await put(p);
});
afterAll(() => { signSpy.mockRestore(); fft.cleanup(); });

describe('getMediaUrl (P1-3)', () => {
  it('LEGIT: 1:1 member gets a short-lived signed URL by path', async () => {
    const before = Date.now();
    const r = await call({ path: 'chat_images/m1/a.jpg' }, B);
    expect(r.url).toContain('chat_images/m1/a.jpg');
    expect(r.expiresAt).toBeGreaterThan(before);
    expect(r.expiresAt).toBeLessThanOrEqual(Date.now() + 15 * 60 * 1000);
    const opts = signSpy.mock.calls[signSpy.mock.calls.length - 1][0] as any;
    expect(opts).toMatchObject({ version: 'v4', action: 'read' });
  });

  it('LEGIT: accepts a legacy tokenized download URL (migration period)', async () => {
    await expect(call({ url: dlUrl('chat_images/m1/a.jpg') }, A)).resolves.toHaveProperty('url');
  });

  it('LEGIT: synthetic search_ key, legacy conversation key, group, support owner + agent, staff', async () => {
    await expect(call({ path: `chat_voice/search_${LO}_${HI}/v.m4a` }, B)).resolves.toHaveProperty('url');
    await expect(call({ path: 'chat_videos/legacy1/v.mp4' }, A)).resolves.toHaveProperty('url');
    await expect(call({ path: 'group_media/g1/g.jpg' }, B)).resolves.toHaveProperty('url');
    await expect(call({ path: 'support_attachments/sup1/s.jpg' }, A)).resolves.toHaveProperty('url');
    await expect(call({ path: 'support_attachments/sup1/s.jpg' }, AGENT)).resolves.toHaveProperty('url');
    await expect(call({ path: 'chat_images/m1/a.jpg' }, 'staff1', { adminRole: 'support' })).resolves.toHaveProperty('url');
  });

  it('ATTACK: non-members are refused for every folder', async () => {
    for (const path of ['chat_images/m1/a.jpg', `chat_voice/search_${LO}_${HI}/v.m4a`, 'chat_videos/legacy1/v.mp4',
      'group_media/g1/g.jpg', 'support_attachments/sup1/s.jpg']) {
      await expect(call({ path }, M)).rejects.toMatchObject({ code: 'permission-denied' });
    }
    await expect(call({ path: 'support_attachments/sup1/s.jpg' }, B)).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(call({ path: 'chat_images/m1/a.jpg' }, M, { adminRole: 'analyst' })).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('ATTACK: unauthenticated, non-chat paths and traversal are refused', async () => {
    await expect(call({ path: 'chat_images/m1/a.jpg' })).rejects.toMatchObject({ code: 'unauthenticated' });
    for (const path of ['verifications/' + A + '/id.jpg', 'id_documents/x.jpg', 'chat_images/m1/../../id_documents/x.jpg',
      'chat_images/m1', 'chat_images/m1/sub/a.jpg', '', 42]) {
      await expect(call({ path }, A)).rejects.toMatchObject({ code: 'invalid-argument' });
    }
  });

  it('member asking for a missing object gets not-found (no URL minted)', async () => {
    const n = signSpy.mock.calls.length;
    await expect(call({ path: 'chat_images/m1/missing.jpg' }, A)).rejects.toMatchObject({ code: 'not-found' });
    expect(signSpy.mock.calls.length).toBe(n);
  });
});
