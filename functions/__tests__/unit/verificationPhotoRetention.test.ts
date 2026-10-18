/**
 * Privacy Policy 8.3 / 8.4: registration ID photos and business owner ID
 * documents are deleted after the review; only the result is kept. Pure
 * logic + the per-user / sweep code against in-memory Storage + Firestore.
 */
import {
  DAY_MS,
  HOUR_MS,
  classifyBusinessDocument,
  classifyRegistrationPhoto,
  isDue,
  latestFinalAction,
  ownerOfPath,
  pendingReviewExpired,
  referencesToClear,
  registrationReviewRecord,
  storagePathOfRef,
} from '../../src/safety/verificationPhotoRetentionLogic';
import {
  RetentionPorts,
  businessDecisionToProcess,
  processBusinessUser,
  processRegistrationUser,
  emptyStats,
  runVerificationPhotoSweep,
  sweepPrefix,
} from '../../src/safety/verificationPhotoRetention';

const NOW = Date.UTC(2026, 9, 17, 12);
const T = NOW - 2 * HOUR_MS; // decision time

// ─────────────────────────────────────────────── in-memory ports

class Fake implements RetentionPorts {
  objects = new Map<string, number>(); // name -> createdMs
  docs = new Map<string, Record<string, any>>();
  actions: Array<{ targetUserId: string; actionType: string; timestampMs: number; performedBy?: string }> = [];
  failDeletes = new Set<string>();
  deleteCalls: string[] = [];
  logs: string[] = [];
  notified: string[] = [];
  /** Simulates an admin deciding between the sweep's read and its write. */
  raceStatus: string | null = null;

  async updateIfPending(path: string, field: string, patch: Record<string, unknown>, deleteFields: string[] = []) {
    if (this.raceStatus) this.docs.set(path, { ...(this.docs.get(path) ?? {}), [field]: this.raceStatus });
    const d = this.docs.get(path);
    if (!d || d[field] !== 'pending') return false;
    await this.mergeDoc(path, patch, deleteFields);
    return true;
  }
  async notifyBusinessDocumentExpired(uid: string) {
    this.notified.push(uid);
  }

  async listPage(prefix: string, startOffset: string | null, max: number, matchGlob?: string, pageToken?: string | null) {
    let names = [...this.objects.keys()].filter((n) => n.startsWith(prefix)).sort();
    if (matchGlob) {
      const re = new RegExp('^' + matchGlob.replace(/\*\*/g, '§').replace(/\*/g, '[^/]*').replace(/§/g, '.*') + '$');
      names = names.filter((n) => re.test(n));
    }
    if (pageToken) names = names.filter((n) => n > pageToken);
    else if (startOffset) names = names.filter((n) => n >= startOffset);
    const page = names.slice(0, max);
    const done = names.length <= max;
    return {
      objects: page.map((name) => ({ name, createdMs: this.objects.get(name)! })),
      done,
      pageToken: done ? null : page[page.length - 1],
    };
  }
  async deleteObject(name: string) {
    this.deleteCalls.push(name);
    if (this.failDeletes.has(name)) return false;
    this.objects.delete(name);
    return true;
  }
  async readDoc(path: string) {
    const d = this.docs.get(path);
    return d ? { ...d } : null;
  }
  async mergeDoc(path: string, patch: Record<string, unknown>, deleteFields: string[] = []) {
    const d = { ...(this.docs.get(path) ?? {}), ...patch };
    for (const f of deleteFields) delete d[f];
    this.docs.set(path, d);
  }
  async adminActions(uid: string) {
    return this.actions.filter((a) => a.targetUserId === uid);
  }
  timestamp(ms: number) {
    return { ms };
  }
  log(m: string) {
    this.logs.push(m);
  }
}

function registered(f: Fake, uid: string, status: string, extra: Record<string, any> = {}, created = T - DAY_MS) {
  const path = `verifications/${uid}/1.jpg`;
  f.objects.set(path, created);
  f.docs.set(`profiles/${uid}`, {
    verificationStatus: status,
    verificationMethod: 'photo',
    ...(status !== 'pending' ? { verificationReviewedAt: { toMillis: () => T }, verificationReviewedBy: 'admin1' } : {}),
    ...extra,
  });
  f.docs.set(`profiles_private/${uid}`, { verificationPhotoPath: path, email: 'kept@example.com' });
  return path;
}

const now = { nowMs: NOW, decidedGraceMs: 0 };

// ─────────────────────────────────────────────── pure logic

describe('pure logic', () => {
  const st = (status: string | null, refs: string[] = [], reviewed: number | null = T, exists = true) =>
    ({ profileExists: exists, status, reviewedAtMs: reviewed, referencedPaths: refs });
  const o = (name: string, createdMs: number) => ({ name, createdMs });

  it('pending submission is never deleted, whatever its age', () => {
    const obj = o('verifications/u/a.jpg', NOW - 365 * DAY_MS);
    const c = classifyRegistrationPhoto(obj, st('pending', ['verifications/u/a.jpg']));
    expect(c).toBe('pending');
    expect(isDue(c, obj, T, NOW + 1000 * DAY_MS)).toBe(false);
    // pending with no known reference: keep everything
    expect(classifyRegistrationPhoto(o('verifications/u/b.jpg', NOW), st('pending', [], null))).toBe('pending');
  });

  it('approved / rejected / needsResubmission: images up to the decision are decided', () => {
    for (const s of ['approved', 'verified', 'rejected', 'needsResubmission']) {
      expect(classifyRegistrationPhoto(o('x', T - 1), st(s))).toBe('decided');
      expect(classifyRegistrationPhoto(o('x', T + 1), st(s))).toBe('orphan'); // uploaded after the decision
      expect(classifyRegistrationPhoto(o('x', T + 1), st(s, [], null))).toBe('decided'); // decision time unknown
    }
  });

  it('re-submitted after a resubmission request: old image decided, new one pending', () => {
    const s = st('pending', ['verifications/u/new.jpg']);
    expect(classifyRegistrationPhoto(o('verifications/u/old.jpg', T - 1), s)).toBe('decided');
    expect(classifyRegistrationPhoto(o('verifications/u/new.jpg', T + 1), s)).toBe('pending');
    expect(classifyRegistrationPhoto(o('verifications/u/retake.jpg', T + 2), s)).toBe('orphan');
  });

  it('no profile / never submitted -> orphan', () => {
    expect(classifyRegistrationPhoto(o('x', T), st(null, [], null, false))).toBe('orphan');
    expect(classifyRegistrationPhoto(o('x', T), st('notSubmitted', [], null))).toBe('orphan');
  });

  it('grace periods: decided 24 h after the decision, orphan 7 days after upload', () => {
    const obj = o('x', T - DAY_MS);
    expect(isDue('decided', obj, T, T + 23 * HOUR_MS)).toBe(false);
    expect(isDue('decided', obj, T, T + 24 * HOUR_MS)).toBe(true);
    expect(isDue('decided', obj, T, T, { decidedGraceMs: 0 })).toBe(true);
    expect(isDue('orphan', o('y', NOW - 6 * DAY_MS), null, NOW)).toBe(false);
    expect(isDue('orphan', o('y', NOW - 7 * DAY_MS), null, NOW)).toBe(true);
    // unknown creation time is never old enough
    expect(isDue('orphan', o('z', NaN), null, NOW + 1000 * DAY_MS)).toBe(false);
  });

  it('business: pending/unknown kept, decided deleted, missing request orphan', () => {
    const b = (status: string | null, exists = true) => ({ requestExists: exists, status, decidedAtMs: T });
    expect(classifyBusinessDocument(o('d', T - 1), b('pending'))).toBe('pending');
    expect(classifyBusinessDocument(o('d', T - 1), b('needsInfo'))).toBe('pending');
    expect(classifyBusinessDocument(o('d', T - 1), b('approved'))).toBe('decided');
    expect(classifyBusinessDocument(o('d', T - 1), b('rejected'))).toBe('decided');
    expect(classifyBusinessDocument(o('d', T + 1), b('rejected'))).toBe('orphan');
    expect(classifyBusinessDocument(o('d', T), b(null, false))).toBe('orphan');
  });

  it('paths, references, records', () => {
    expect(ownerOfPath('verifications/u1/a.jpg')).toEqual({ uid: 'u1', kind: 'registration' });
    expect(ownerOfPath('profiles/u1/verifications/a.jpg')).toEqual({ uid: 'u1', kind: 'registration' });
    expect(ownerOfPath('business_verification/u1/owner_document.jpg')).toEqual({ uid: 'u1', kind: 'business' });
    expect(ownerOfPath('profiles/u1/photos/a.jpg')).toBeNull();
    expect(storagePathOfRef('https://firebasestorage.googleapis.com/v0/b/b.appspot.com/o/verifications%2Fu%2F1.jpg?alt=media&token=t'))
      .toBe('verifications/u/1.jpg');
    expect(storagePathOfRef('verifications/u/1.jpg')).toBe('verifications/u/1.jpg');
    expect(storagePathOfRef('https://example.com/x.jpg')).toBeNull();
    const del = new Set(['a']);
    expect(referencesToClear({ p: 'a', q: 'b', r: null }, del, new Set(['b']), false)).toEqual(['p']);
    expect(referencesToClear({ p: 'gone' }, new Set(), new Set(), false)).toEqual(['p']); // dangling
    expect(referencesToClear({ p: 'gone' }, new Set(), new Set(), true)).toEqual([]); // pending: untouched
    expect(registrationReviewRecord({ status: 'approved', reviewedAtMs: T, reviewedBy: 'a', method: 'photo' }))
      .toEqual({ verified: true, status: 'approved', reviewedAtMs: T, reviewedBy: 'a', method: 'photo' });
    expect(registrationReviewRecord({ status: 'rejected', reviewedAtMs: T, reviewedBy: 'a', method: null }).verified).toBe(false);
    expect(latestFinalAction([
      { actionType: 'verification_approved', timestampMs: 1, performedBy: 'a' },
      { actionType: 'verification_rejected', timestampMs: 2, performedBy: 'b' },
      { actionType: 'verification_status_set', timestampMs: 3 },
    ])).toEqual({ decision: 'rejected', atMs: 2, by: 'b' });
  });
});

// ─────────────────────────────────────────────── per user (decision path)

describe('registration photo on decision', () => {
  it.each(['approved', 'rejected', 'needsResubmission'])('%s: deletes the image, clears refs, keeps the minimal record', async (status) => {
    const f = new Fake();
    const path = registered(f, 'u', status, {
      verificationPhotoUrl: 'https://firebasestorage.googleapis.com/v0/b/b/o/verifications%2Fu%2F1.jpg?alt=media',
    });
    const r = await processRegistrationUser(f, 'u', { ...now, decisionHint: { atMs: T, by: 'admin1' } });
    expect(r.deleted).toBe(1);
    expect(f.objects.has(path)).toBe(false);
    const priv = f.docs.get('profiles_private/u')!;
    expect(priv.verificationPhotoPath).toBeUndefined();
    expect(priv.email).toBe('kept@example.com');
    expect(priv.verificationReview).toEqual({
      verified: status === 'approved',
      status,
      reviewedAt: { ms: T },
      reviewedBy: 'admin1',
      method: 'photo',
      imageDeletedAt: { ms: NOW },
    });
    const pub = f.docs.get('profiles/u')!;
    expect(pub.verificationPhotoUrl).toBeUndefined();
    // the decision itself stays where the panel and the app read it
    expect(pub.verificationStatus).toBe(status);
    expect(pub.verificationReviewedBy).toBe('admin1');
  });

  it('keeps an image that is pending review', async () => {
    const f = new Fake();
    const path = registered(f, 'p', 'pending', {}, NOW - 300 * DAY_MS);
    const r = await processRegistrationUser(f, 'p', { ...now, decidedGraceMs: 0, orphanGraceMs: 0 });
    expect(r).toMatchObject({ deleted: 0, pending: 1 });
    expect(f.objects.has(path)).toBe(true);
    expect(f.docs.get('profiles_private/p')!.verificationPhotoPath).toBe(path);
    expect(f.deleteCalls).toEqual([]);
  });

  it('re-submission racing the trigger: the new photo is kept, the reviewed one deleted', async () => {
    const f = new Fake();
    const old = registered(f, 'r', 'pending');
    const fresh = 'verifications/r/2.jpg';
    f.objects.set(fresh, T + 60_000);
    f.docs.set('profiles_private/r', { verificationPhotoPath: fresh });
    f.actions.push({ targetUserId: 'r', actionType: 'verification_resubmission_requested', timestampMs: T, performedBy: 'a' });
    await processRegistrationUser(f, 'r', { ...now, decisionHint: { atMs: T } });
    expect(f.objects.has(old)).toBe(false);
    expect(f.objects.has(fresh)).toBe(true);
    expect(f.docs.get('profiles_private/r')!.verificationPhotoPath).toBe(fresh);
    expect(f.docs.get('profiles_private/r')!.verificationReview).toBeUndefined(); // not final any more
  });

  it('is idempotent', async () => {
    const f = new Fake();
    registered(f, 'i', 'approved');
    await processRegistrationUser(f, 'i', now);
    const after = JSON.stringify([...f.docs]);
    f.deleteCalls = [];
    const r2 = await processRegistrationUser(f, 'i', { ...now, nowMs: NOW + 1000 });
    expect(r2).toMatchObject({ objects: 0, deleted: 0, cleared: 0, recordWritten: false });
    expect(f.deleteCalls).toEqual([]);
    expect(JSON.stringify([...f.docs])).toBe(after);
  });

  it('a failed delete keeps the reference so the sweep retries', async () => {
    const f = new Fake();
    const path = registered(f, 'x', 'approved');
    f.failDeletes.add(path);
    const r = await processRegistrationUser(f, 'x', now);
    expect(r).toMatchObject({ deleted: 0, failed: 1 });
    expect(f.docs.get('profiles_private/x')!.verificationPhotoPath).toBe(path);
    f.failDeletes.clear();
    const r2 = await processRegistrationUser(f, 'x', now);
    expect(r2.deleted).toBe(1);
    expect(f.docs.get('profiles_private/x')!.verificationPhotoPath).toBeUndefined();
  });

  it('deletes legacy-prefix photos too (profiles/{uid}/verifications/)', async () => {
    const f = new Fake();
    registered(f, 'l', 'approved');
    f.objects.set('profiles/l/verifications/old.jpg', T - 10 * DAY_MS);
    f.objects.set('profiles/l/photos/public.jpg', T - 10 * DAY_MS);
    await processRegistrationUser(f, 'l', now);
    expect(f.objects.has('profiles/l/verifications/old.jpg')).toBe(false);
    expect(f.objects.has('profiles/l/photos/public.jpg')).toBe(true); // never touches profile photos
  });

  it('dry run deletes and writes nothing', async () => {
    const f = new Fake();
    const path = registered(f, 'd', 'rejected');
    const r = await processRegistrationUser(f, 'd', { ...now, dryRun: true });
    expect(r).toMatchObject({ decided: 1, deleted: 0 });
    expect(f.objects.has(path)).toBe(true);
    expect(f.docs.get('profiles_private/d')!.verificationPhotoPath).toBe(path);
  });
});

describe('business owner ID document', () => {
  it('deleted on approve/reject, url cleared, registration details kept', async () => {
    for (const status of ['approved', 'rejected']) {
      const f = new Fake();
      f.objects.set('business_verification/b/owner_document.jpg', T - HOUR_MS);
      f.docs.set('business_verification_requests/b', {
        status, businessName: 'Shop', ownerName: 'Ann', ownerDocumentUrl: 'https://firebasestorage.googleapis.com/v0/b/x/o/business_verification%2Fb%2Fowner_document.jpg',
      });
      const r = await processBusinessUser(f, 'b', { ...now, decisionHint: { atMs: T } });
      expect(r.deleted).toBe(1);
      const d = f.docs.get('business_verification_requests/b')!;
      expect(d.ownerDocumentUrl).toBeUndefined();
      expect(d).toMatchObject({ status, businessName: 'Shop', ownerName: 'Ann', ownerDocumentDeletedAt: { ms: NOW } });
    }
  });

  it('pending request keeps its document', async () => {
    const f = new Fake();
    f.objects.set('business_verification/b/owner_document.jpg', NOW - 90 * DAY_MS);
    f.docs.set('business_verification_requests/b', { status: 'pending', ownerDocumentUrl: 'u' });
    const r = await processBusinessUser(f, 'b', { ...now, orphanGraceMs: 0 });
    expect(r).toMatchObject({ deleted: 0, pending: 1 });
    expect(f.docs.get('business_verification_requests/b')!.ownerDocumentUrl).toBe('u');
  });

  it('trigger filter: acts on a new decision, not on its own clearing write', () => {
    expect(businessDecisionToProcess({ status: 'pending' }, { status: 'approved', ownerDocumentUrl: 'u' })).toBe(true);
    expect(businessDecisionToProcess(null, { status: 'rejected' })).toBe(true);
    expect(businessDecisionToProcess({ status: 'approved', ownerDocumentUrl: 'u' }, { status: 'approved' })).toBe(false);
    expect(businessDecisionToProcess({ status: 'approved' }, { status: 'approved', ownerDocumentUrl: 'u' })).toBe(true);
    expect(businessDecisionToProcess({ status: 'approved' }, { status: 'pending', ownerDocumentUrl: 'u' })).toBe(false);
    expect(businessDecisionToProcess({ status: 'pending' }, undefined)).toBe(false);
  });
});

// ─────────────────────────────────────────────── daily sweep

describe('daily sweep', () => {
  it('applies the grace periods, keeps pending younger than 7 days', async () => {
    const f = new Fake();
    registered(f, 'a1', 'approved'); // decided T, now = T + 2 h -> inside 24 h grace
    registered(f, 'a2', 'approved', { verificationReviewedAt: { toMillis: () => NOW - 3 * DAY_MS } }, NOW - 4 * DAY_MS);
    registered(f, 'p1', 'pending', {}, NOW - 6 * DAY_MS);
    f.objects.set('verifications/gone/1.jpg', NOW - 8 * DAY_MS); // account deleted
    f.objects.set('verifications/new/1.jpg', NOW - 1 * DAY_MS); // onboarding in progress
    f.objects.set('business_verification/b1/owner_document.jpg', NOW - 3 * DAY_MS);
    f.docs.set('business_verification_requests/b1', { status: 'rejected', reviewedAt: { toMillis: () => NOW - 2 * DAY_MS } });

    const { stats, cursors } = await runVerificationPhotoSweep(f, { nowMs: NOW });
    expect([...f.objects.keys()].sort()).toEqual([
      'verifications/a1/1.jpg',
      'verifications/new/1.jpg',
      'verifications/p1/1.jpg',
    ]);
    expect(stats).toMatchObject({ deleted: 3, pending: 1 });
    expect(cursors).toEqual({ 'verifications/': null, 'business_verification/': null });
  });

  it('is bounded and resumable through its cursor', async () => {
    const f = new Fake();
    for (let i = 0; i < 9; i++) registered(f, `u${i}`, 'rejected', { verificationReviewedAt: { toMillis: () => NOW - 2 * DAY_MS } }, NOW - 3 * DAY_MS);
    const run1 = await runVerificationPhotoSweep(f, { nowMs: NOW, pageSize: 2, maxPages: 2 });
    expect(run1.cursors['verifications/']).not.toBeNull();
    let cursors = run1.cursors;
    for (let i = 0; i < 10 && f.objects.size; i++) {
      cursors = (await runVerificationPhotoSweep(f, { nowMs: NOW, pageSize: 2, maxPages: 2, cursors })).cursors;
    }
    expect(f.objects.size).toBe(0);
  });

  it('backfill legacy pass (matchGlob) only touches profiles/{uid}/verifications/', async () => {
    const f = new Fake();
    f.docs.set('profiles/old', { verificationStatus: 'approved', verificationReviewedAt: { toMillis: () => T } });
    f.objects.set('profiles/old/verifications/a.jpg', T - DAY_MS);
    f.objects.set('profiles/old/photos/p.jpg', T - DAY_MS);
    f.objects.set('profiles/old/p.jpg', T - DAY_MS);
    const s = emptyStats();
    const cursor = await sweepPrefix(f, 'profiles/', null,
      { nowMs: NOW, decidedGraceMs: 0, matchGlob: 'profiles/*/verifications/**', pageSize: 1 }, s);
    expect(cursor).toBeNull();
    expect([...f.objects.keys()].sort()).toEqual(['profiles/old/p.jpg', 'profiles/old/photos/p.jpg']);
    expect(s.deleted).toBe(1);
  });
});

// ─────────────────────────────────────────────── 8.2(d): 7 days pending max

describe('pending review older than 7 days (Privacy Policy 8.2(d))', () => {
  it('registration: deleted whatever the outcome, user asked to resubmit, queue item leaves pending', async () => {
    const f = new Fake();
    const path = registered(f, 'e1', 'pending', {
      verificationPhotoUrl: 'https://firebasestorage.googleapis.com/v0/b/b/o/verifications%2Fe1%2F1.jpg?alt=media',
    }, NOW - 8 * DAY_MS);
    const keep = registered(f, 'e2', 'pending', {}, NOW - 6 * DAY_MS);
    const { stats } = await runVerificationPhotoSweep(f, { nowMs: NOW });
    expect(f.objects.has(path)).toBe(false);
    expect(f.objects.has(keep)).toBe(true);
    const pub = f.docs.get('profiles/e1')!;
    expect(pub).toMatchObject({
      verificationStatus: 'needsResubmission', verificationRejectionReason: 'reviewExpired', verificationExpiredAt: { ms: NOW },
    });
    expect(pub.verificationPhotoUrl).toBeUndefined();
    const priv = f.docs.get('profiles_private/e1')!;
    expect(priv.verificationPhotoPath).toBeUndefined();
    expect(priv.verificationReview).toEqual({
      verified: false, status: 'expired', reviewedAt: null, reviewedBy: 'system', method: 'photo', imageDeletedAt: { ms: NOW },
    });
    expect(f.docs.get('profiles/e2')!.verificationStatus).toBe('pending');
    expect(stats).toMatchObject({ expired: 1, expiredSubmissions: 1 });
  });

  it('exactly 7 days expires, unknown upload time falls back to the submission time', () => {
    expect(pendingReviewExpired({ name: 'x', createdMs: NOW - 7 * DAY_MS }, NOW)).toBe(true);
    expect(pendingReviewExpired({ name: 'x', createdMs: NOW - 7 * DAY_MS + 1 }, NOW)).toBe(false);
    expect(pendingReviewExpired({ name: 'x', createdMs: NaN }, NOW, undefined, NOW - 8 * DAY_MS)).toBe(true);
    expect(pendingReviewExpired({ name: 'x', createdMs: NaN }, NOW)).toBe(false);
  });

  it('the decision path never expires (no option = pending kept)', async () => {
    const f = new Fake();
    const path = registered(f, 'd1', 'pending', {}, NOW - 30 * DAY_MS);
    await processRegistrationUser(f, 'd1', { nowMs: NOW, decidedGraceMs: 0 });
    expect(f.objects.has(path)).toBe(true);
  });

  it('an admin deciding at the same moment wins: nothing is expired', async () => {
    const f = new Fake();
    const path = registered(f, 'race', 'pending', {}, NOW - 9 * DAY_MS);
    f.raceStatus = 'approved';
    const r = await processRegistrationUser(f, 'race', { nowMs: NOW, expirePendingAfterMs: 7 * DAY_MS });
    expect(r).toMatchObject({ expired: 0, expiredSubmission: false });
    expect(f.objects.has(path)).toBe(true); // the approval trigger deletes it
    expect(f.docs.get('profiles/race')!.verificationRejectionReason).toBeUndefined();
  });

  it('dry run counts the expiry without changing anything', async () => {
    const f = new Fake();
    const path = registered(f, 'dr', 'pending', {}, NOW - 9 * DAY_MS);
    const { stats } = await runVerificationPhotoSweep(f, { nowMs: NOW, dryRun: true });
    expect(stats.expired).toBe(1);
    expect(f.objects.has(path)).toBe(true);
    expect(f.docs.get('profiles/dr')!.verificationStatus).toBe('pending');
  });

  it('business: document deleted, request expired, owner notified once', async () => {
    const f = new Fake();
    f.objects.set('business_verification/b/owner_document.jpg', NOW - 8 * DAY_MS);
    f.docs.set('business_verification_requests/b', {
      status: 'pending', businessName: 'Shop', phoneVerified: true,
      ownerDocumentUrl: 'https://firebasestorage.googleapis.com/v0/b/x/o/business_verification%2Fb%2Fowner_document.jpg?alt=media',
    });
    await runVerificationPhotoSweep(f, { nowMs: NOW });
    expect(f.objects.size).toBe(0);
    const d = f.docs.get('business_verification_requests/b')!;
    expect(d.ownerDocumentUrl).toBeUndefined();
    expect(d).toMatchObject({ status: 'expired', expiredReason: 'documentExpired', businessName: 'Shop', expiredAt: { ms: NOW } });
    expect(f.notified).toEqual(['b']);
    await runVerificationPhotoSweep(f, { nowMs: NOW + DAY_MS });
    expect(f.notified).toEqual(['b']);
    // the expiry write re-fires onBusinessVerificationDecided: a no-op (nothing left)
    expect(businessDecisionToProcess({ status: 'pending' }, { status: 'expired' })).toBe(true);
    expect((await processBusinessUser(f, 'b', { nowMs: NOW, decidedGraceMs: 0 })).recordWritten).toBe(false);
  });

  it('business: the document is optional - a request without one is never expired', async () => {
    const f = new Fake();
    f.docs.set('business_verification_requests/n', {
      status: 'pending', phoneVerified: true, submittedAt: { toMillis: () => NOW - 30 * DAY_MS },
    });
    f.objects.set('business_verification/n/owner_document.jpg', NOW - 8 * DAY_MS); // uploaded, never attached
    await runVerificationPhotoSweep(f, { nowMs: NOW });
    expect(f.docs.get('business_verification_requests/n')!.status).toBe('pending');
    expect(f.objects.size).toBe(0); // the stray upload was not under review
    expect(f.notified).toEqual([]);
    const g = new Fake();
    g.docs.set('business_verification_requests/z', { status: 'pending' });
    const r = await processBusinessUser(g, 'z', { nowMs: NOW, expirePendingAfterMs: 7 * DAY_MS });
    expect(r).toMatchObject({ objects: 0, expired: 0 });
    expect(g.docs.get('business_verification_requests/z')!.status).toBe('pending');
  });

  it('business: pending document younger than 7 days is kept', async () => {
    const f = new Fake();
    f.objects.set('business_verification/k/owner_document.jpg', NOW - 6 * DAY_MS);
    f.docs.set('business_verification_requests/k', { status: 'pending', ownerDocumentUrl: 'business_verification/k/owner_document.jpg' });
    await runVerificationPhotoSweep(f, { nowMs: NOW });
    expect(f.objects.size).toBe(1);
    expect(f.docs.get('business_verification_requests/k')!.status).toBe('pending');
  });
});
