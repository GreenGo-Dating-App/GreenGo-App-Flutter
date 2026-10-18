/**
 * Privacy Policy 8.3 / 8.4: the registration ID photo and the business owner
 * ID document are deleted after the review; only the result is kept.
 *
 * Real Firestore + Storage emulators:
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "cd functions && npx jest -i --config jest.security.config.js verification-photo-retention"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) {
  admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
}
const fft = functionsTest({ projectId: PROJECT });
const db = admin.firestore();
const bucket = () => admin.storage().bucket();
const TS = admin.firestore.Timestamp;

// eslint-disable-next-line @typescript-eslint/no-var-requires
const req = (p: string): any => require(p);
const badge = () => req('../../src/admin/registrationIdVerified');
const retention = () => req('../../src/safety/verificationPhotoRetention');
const triggers = () => req('../../src/profiles/privateProfileTriggers');

function emulatorDelete(path: string) {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  return new Promise<void>((resolve, reject) => {
    const r = http.request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE', path },
      (res) => { res.resume(); res.on('end', resolve); });
    r.on('error', reject);
    r.end();
  });
}
async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host || !/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) throw new Error('Not a local emulator');
  if (!process.env.FIREBASE_STORAGE_EMULATOR_HOST) throw new Error('Storage emulator required');
  await emulatorDelete(`/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);
  await bucket().deleteFiles({ force: true }).catch(() => undefined);
}
const put = (path: string) => bucket().file(path).save(Buffer.from('jpeg'), { contentType: 'image/jpeg' });
const exists = async (path: string) => (await bucket().file(path).exists())[0];

const created = (fn: any, path: string, data: any, params: any) =>
  fn.run({ data: fft.firestore.makeDocumentSnapshot(data, path), params });
const written = (fn: any, path: string, before: any, after: any, params: any) =>
  fn.run({
    time: new Date().toISOString(),
    data: {
      before: before ? fft.firestore.makeDocumentSnapshot(before, path) : { data: () => undefined, exists: false },
      after: after ? fft.firestore.makeDocumentSnapshot(after, path) : { data: () => undefined, exists: false },
    },
    params,
  });

async function submitted(uid: string, file = `verifications/${uid}/1.jpg`) {
  await put(file);
  await db.doc(`profiles/${uid}`).set({ verificationStatus: 'pending', verificationMethod: 'photo', verificationSubmittedAt: TS.now() });
  await db.doc(`profiles_private/${uid}`).set({ verificationPhotoPath: file, email: `${uid}@x.test` });
  return file;
}

/** What the in-app admin tools / panel write for a decision. */
async function decide(uid: string, status: 'approved' | 'rejected' | 'needsResubmission') {
  const now = TS.now();
  await db.doc(`profiles/${uid}`).update({
    verificationStatus: status, verificationReviewedAt: now, verificationReviewedBy: 'admin1',
  });
  const actionType = { approved: 'verification_approved', rejected: 'verification_rejected', needsResubmission: 'verification_resubmission_requested' }[status];
  const action = { actionType, targetUserId: uid, performedBy: 'admin1', timestamp: TS.fromMillis(now.toMillis() + 5), details: { status, via: 'app' } };
  const ref = await db.collection('admin_actions').add(action);
  await created(badge().onAdminVerificationAction, `admin_actions/${ref.id}`, action, { actionId: ref.id });
}

beforeEach(clearAll);
afterAll(() => fft.cleanup());

describe('registration ID photo', () => {
  test.each(['approved', 'rejected', 'needsResubmission'] as const)('%s -> image deleted, path cleared, result kept', async (status) => {
    const file = await submitted('u1');
    await decide('u1', status);
    expect(await exists(file)).toBe(false);
    const priv = (await db.doc('profiles_private/u1').get()).data()!;
    expect(priv.verificationPhotoPath).toBeUndefined();
    expect(priv.email).toBe('u1@x.test');
    expect(priv.verificationReview).toMatchObject({ verified: status === 'approved', status, reviewedBy: 'admin1', method: 'photo' });
    expect(priv.verificationReview.reviewedAt).toBeInstanceOf(TS);
    const pub = (await db.doc('profiles/u1').get()).data()!;
    expect(pub.verificationStatus).toBe(status);
    if (status === 'approved') expect(pub.isAgeVerified).toBe(true); // badge unaffected
    // the admin reviewer gets "no photo" instead of a broken signed URL
    await expect(triggers().resolveVerificationPhotoUrl('u1', { sign: async () => 'x' }))
      .resolves.toEqual({ url: null, expiresAt: null, source: 'none' });
  });

  test('pending photos (< 7 days) survive the decision of another user and the sweep', async () => {
    const pending = await submitted('p1');
    await submitted('u2');
    await decide('u2', 'approved');
    const far = Date.now() + 6 * 24 * 3600 * 1000; // < 7 days: 8.2(d) expiry not reached
    await retention().runVerificationPhotoSweep(retention().adminPorts(db, bucket()), { nowMs: far });
    expect(await exists(pending)).toBe(true);
    expect((await db.doc('profiles_private/p1').get()).data()!.verificationPhotoPath).toBe(pending);
  });

  test('resubmission: the new photo is kept, the reviewed one is gone; repeat run is a no-op', async () => {
    const old = await submitted('r1');
    await decide('r1', 'needsResubmission');
    const fresh = 'verifications/r1/2.jpg';
    await put(fresh);
    await db.doc('profiles/r1').update({ verificationStatus: 'pending' });
    await db.doc('profiles_private/r1').set({ verificationPhotoPath: fresh }, { merge: true });
    const r = await retention().processRegistrationUser(retention().adminPorts(db, bucket()), 'r1', { nowMs: Date.now(), decidedGraceMs: 0 });
    expect(r).toMatchObject({ deleted: 0, pending: 1 });
    expect(await exists(old)).toBe(false);
    expect(await exists(fresh)).toBe(true);
  });

  test('sweep: a decision recorded without admin_actions is caught after 24 h', async () => {
    const file = await submitted('s1');
    await db.doc('profiles/s1').update({ verificationStatus: 'rejected', verificationReviewedAt: TS.now() });
    const ports = retention().adminPorts(db, bucket());
    await retention().runVerificationPhotoSweep(ports, { nowMs: Date.now() + 3600 * 1000 });
    expect(await exists(file)).toBe(true); // inside the grace period
    await retention().runVerificationPhotoSweep(ports, { nowMs: Date.now() + 25 * 3600 * 1000 });
    expect(await exists(file)).toBe(false);
    expect((await db.doc('profiles_private/s1').get()).data()!.verificationPhotoPath).toBeUndefined();
  });
});

describe('business owner ID document', () => {
  const path = 'business_verification/b1/owner_document.jpg';
  test('pending kept; decision deletes the document and keeps the registration details', async () => {
    await put(path);
    const pending = { status: 'pending', businessName: 'Shop', ownerName: 'Ann', ownerDocumentUrl: 'https://firebasestorage.googleapis.com/v0/b/x/o/business_verification%2Fb1%2Fowner_document.jpg' };
    await db.doc('business_verification_requests/b1').set(pending);
    const fn = retention().onBusinessVerificationDecided;
    await written(fn, 'business_verification_requests/b1', null, pending, { uid: 'b1' });
    expect(await exists(path)).toBe(true);

    const decided = { ...pending, status: 'approved' };
    await db.doc('business_verification_requests/b1').set(decided);
    await written(fn, 'business_verification_requests/b1', pending, decided, { uid: 'b1' });
    expect(await exists(path)).toBe(false);
    const d = (await db.doc('business_verification_requests/b1').get()).data()!;
    expect(d.ownerDocumentUrl).toBeUndefined();
    expect(d).toMatchObject({ status: 'approved', businessName: 'Shop', ownerName: 'Ann' });
    expect(d.ownerDocumentDeletedAt).toBeInstanceOf(TS);
  });
});

describe('Privacy Policy 8.2(d): pending review older than 7 days', () => {
  const DAY = 24 * 3600 * 1000;

  test('registration: image deleted, status needsResubmission/reviewExpired, leaves the admin queue', async () => {
    const file = await submitted('x1');
    const ports = retention().adminPorts(db, bucket());
    await retention().runVerificationPhotoSweep(ports, { nowMs: Date.now() + 6 * DAY });
    expect(await exists(file)).toBe(true);
    const { stats } = await retention().runVerificationPhotoSweep(ports, { nowMs: Date.now() + 7 * DAY + 60_000 });
    expect(stats.expiredSubmissions).toBe(1);
    expect(await exists(file)).toBe(false);
    const pub = (await db.doc('profiles/x1').get()).data()!;
    expect(pub.verificationStatus).toBe('needsResubmission');
    expect(pub.verificationRejectionReason).toBe('reviewExpired');
    const priv = (await db.doc('profiles_private/x1').get()).data()!;
    expect(priv.verificationPhotoPath).toBeUndefined();
    expect(priv.verificationReview).toMatchObject({ verified: false, status: 'expired', reviewedBy: 'system' });
    // the in-app admin queue query (verificationStatus == 'pending') no longer returns it
    const queue = await db.collection('profiles').where('verificationStatus', '==', 'pending').get();
    expect(queue.docs.map((d) => d.id)).not.toContain('x1');
  });

  test('business: document deleted, request expired, owner gets an in-app notification', async () => {
    const path = 'business_verification/bx/owner_document.jpg';
    await put(path);
    await db.doc('business_verification_requests/bx').set({
      status: 'pending', businessName: 'Shop', phoneVerified: true, submittedAt: TS.now(),
      ownerDocumentUrl: 'https://firebasestorage.googleapis.com/v0/b/x/o/business_verification%2Fbx%2Fowner_document.jpg?alt=media',
    });
    await db.doc('business_verification_requests/nodoc').set({ status: 'pending', phoneVerified: true, submittedAt: TS.now() });
    const ports = retention().adminPorts(db, bucket());
    await retention().runVerificationPhotoSweep(ports, { nowMs: Date.now() + 8 * DAY });
    expect(await exists(path)).toBe(false);
    const d = (await db.doc('business_verification_requests/bx').get()).data()!;
    expect(d).toMatchObject({ status: 'expired', expiredReason: 'documentExpired', businessName: 'Shop' });
    expect(d.ownerDocumentUrl).toBeUndefined();
    const notes = await db.collection('notifications').where('userId', '==', 'bx').get();
    expect(notes.size).toBe(1);
    expect(notes.docs[0].get('bodyKey')).toBe('srvBusinessDocumentExpired');
    // without a document (now optional) the request stays pending
    expect((await db.doc('business_verification_requests/nodoc').get()).get('status')).toBe('pending');
  });
});
