/**
 * Server-side "personal main photo must show a face" rule
 * (src/safety/mainPhotoFaceRule.ts): pure helpers + both entry points
 * against in-memory ports.
 */
import {
  FaceRulePorts,
  applyReorder,
  enforceAfterVerdict,
  enforceOnProfileWrite,
  faceNoticeId,
  faceStatusFromVerdict,
  mainPhotoChanged,
  planMainPhotoCorrection,
  profilePhotoOwner,
  storageObjectFromUrl,
  verdictDocId,
} from '../../src/safety/mainPhotoFaceRule';

const BUCKET = 'greengo-chat.firebasestorage.app';
const UID = 'u1';
const path = (name: string, uid = UID) => `profiles/${uid}/photos/${name}.jpg`;
const url = (name: string, uid = UID) =>
  `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(path(name, uid))}?alt=media&token=t-${name}`;

const FACE = url('face');
const FACE2 = url('face2');
const NOFACE = url('noface');
const NOFACE2 = url('noface2');

class Fake implements FaceRulePorts {
  verdicts = new Map<string, Record<string, any>>();
  /** object path -> faces (missing = object does not exist / unreadable) */
  objects = new Map<string, number>();
  profiles = new Map<string, Record<string, any>>();
  notices = new Map<string, { uid: string; kind: string }>();
  visionCalls: string[] = [];
  profileWrites = 0;

  defaultBucket() { return BUCKET; }
  async readVerdict(docId: string) { return this.verdicts.get(docId) ?? null; }
  async detectFaces(_bucket: string, p: string) {
    this.visionCalls.push(p);
    const n = this.objects.get(p);
    if (n === undefined) throw new Error('No such object');
    return n;
  }
  async saveFaceResult(docId: string, data: Record<string, any>) {
    this.verdicts.set(docId, { ...(this.verdicts.get(docId) ?? {}), ...data });
  }
  async readProfile(uid: string) { return this.profiles.get(uid) ?? null; }
  async updatePhotoUrls(uid: string, mutate: (p: Record<string, any> | null) => string[] | null) {
    const next = mutate(this.profiles.get(uid) ?? null);
    if (!next) return false;
    this.profiles.set(uid, { ...this.profiles.get(uid), photoUrls: next });
    this.profileWrites += 1;
    return true;
  }
  async notify(uid: string, id: string, kind: 'moved' | 'needed') {
    if (!this.notices.has(id)) this.notices.set(id, { uid, kind });
  }

  approved(name: string, hasFace: boolean) {
    this.verdicts.set(verdictDocId(path(name)), {
      status: 'approved', reasons: [], objectPath: path(name), faces: hasFace ? 1 : 0, hasFace,
    });
  }

  /** Simulates the profiles/{uid} trigger, re-firing on its own writes. */
  async write(uid: string, next: Record<string, any>) {
    let before = this.profiles.get(uid);
    this.profiles.set(uid, next);
    let after: Record<string, any> | undefined = next;
    const results: string[] = [];
    for (let i = 0; i < 5; i++) {
      const writesBefore = this.profileWrites;
      results.push(await enforceOnProfileWrite(uid, before, after, this));
      if (this.profileWrites === writesBefore) return results;
      before = after;
      after = this.profiles.get(uid);
    }
    throw new Error(`trigger loop: ${results.join(',')}`);
  }
}

describe('pure helpers', () => {
  test('storageObjectFromUrl parses download / gs / storage.googleapis URLs', () => {
    expect(storageObjectFromUrl(FACE)).toEqual({ bucket: BUCKET, path: path('face') });
    expect(storageObjectFromUrl(`gs://${BUCKET}/${path('a')}`)).toEqual({ bucket: BUCKET, path: path('a') });
    expect(storageObjectFromUrl(`https://storage.googleapis.com/${BUCKET}/${path('a')}`))
      .toEqual({ bucket: BUCKET, path: path('a') });
    expect(storageObjectFromUrl('https://example.com/x.jpg')).toBeNull();
    expect(storageObjectFromUrl('not a url')).toBeNull();
    expect(storageObjectFromUrl(null)).toBeNull();
  });

  test('profilePhotoOwner only matches profiles/{uid}/photos/<file>', () => {
    expect(profilePhotoOwner(path('a'))).toBe(UID);
    expect(profilePhotoOwner('profiles/u1/events/a.jpg')).toBeNull();
    expect(profilePhotoOwner('chat_images/u1/a.jpg')).toBeNull();
  });

  test('faceStatusFromVerdict', () => {
    expect(faceStatusFromVerdict(null)).toBe('unknown');
    expect(faceStatusFromVerdict({ status: 'approved', hasFace: true })).toBe('face');
    expect(faceStatusFromVerdict({ status: 'approved', hasFace: false })).toBe('no_face');
    expect(faceStatusFromVerdict({ status: 'approved', faces: 2 })).toBe('face');
    expect(faceStatusFromVerdict({ status: 'rejected', reasons: ['no_face'] })).toBe('no_face');
    expect(faceStatusFromVerdict({ status: 'rejected', reasons: ['adult'] })).toBe('no_face');
    // Legacy verdict / private photo: no face data recorded.
    expect(faceStatusFromVerdict({ status: 'approved', reasons: [] })).toBe('unknown');
    expect(faceStatusFromVerdict({ status: 'error' })).toBe('unknown');
    // Moderator restore outranks the detector.
    expect(faceStatusFromVerdict({ status: 'approved', moderatorApproved: true, hasFace: false })).toBe('face');
  });

  test('mainPhotoChanged compares slot 0 only', () => {
    expect(mainPhotoChanged({ photoUrls: [FACE, NOFACE] }, { photoUrls: [FACE, NOFACE2] })).toBe(false);
    expect(mainPhotoChanged({ photoUrls: [FACE] }, { photoUrls: [NOFACE, FACE] })).toBe(true);
    expect(mainPhotoChanged(undefined, { photoUrls: [FACE] })).toBe(true);
    expect(mainPhotoChanged({ photoUrls: [] }, { photoUrls: [] })).toBe(false);
  });

  test('applyReorder refuses stale state and business accounts', () => {
    const plan = { faceless: NOFACE, replacement: FACE };
    expect(applyReorder({ photoUrls: [NOFACE, FACE2, FACE] }, plan)).toEqual([FACE, NOFACE, FACE2]);
    expect(applyReorder({ photoUrls: [FACE2, NOFACE, FACE] }, plan)).toBeNull();
    expect(applyReorder({ photoUrls: [NOFACE, FACE2] }, plan)).toBeNull();
    expect(applyReorder({ photoUrls: [NOFACE, FACE], isBusiness: true }, plan)).toBeNull();
    expect(applyReorder(null, plan)).toBeNull();
  });

  test('planMainPhotoCorrection prefers the previous main photo, needs a KNOWN face', async () => {
    const st: Record<string, any> = { [FACE]: 'face', [FACE2]: 'face', [NOFACE]: 'no_face', [NOFACE2]: 'unknown' };
    const statusOf = async (u: string) => st[u];
    expect(await planMainPhotoCorrection([FACE, NOFACE], null, statusOf)).toEqual({ action: 'none' });
    expect(await planMainPhotoCorrection([NOFACE2, NOFACE], null, statusOf)).toEqual({ action: 'none' });
    expect(await planMainPhotoCorrection([NOFACE, FACE, FACE2], FACE2, statusOf))
      .toEqual({ action: 'reorder', faceless: NOFACE, replacement: FACE2 });
    expect(await planMainPhotoCorrection([NOFACE, NOFACE2, FACE], null, statusOf))
      .toEqual({ action: 'reorder', faceless: NOFACE, replacement: FACE });
    expect(await planMainPhotoCorrection([NOFACE, NOFACE2], FACE, statusOf))
      .toEqual({ action: 'notify', faceless: NOFACE });
    expect(await planMainPhotoCorrection([], null, statusOf)).toEqual({ action: 'none' });
  });
});

describe('enforceOnProfileWrite (profiles/{uid} trigger)', () => {
  let f: Fake;
  beforeEach(() => {
    f = new Fake();
    f.approved('face', true);
    f.approved('face2', true);
    f.approved('noface', false);
    f.approved('noface2', false);
    f.profiles.set(UID, { photoUrls: [FACE, NOFACE] });
  });

  test('personal account: faceless photo moved into slot 0 is reverted, user notified once', async () => {
    const results = await f.write(UID, { photoUrls: [NOFACE, FACE] });
    expect(f.profiles.get(UID)!.photoUrls).toEqual([FACE, NOFACE]);
    expect(results).toEqual(['reordered', 'ok']); // its own write re-fires once and stops
    expect([...f.notices.values()]).toEqual([{ uid: UID, kind: 'moved' }]);
    expect([...f.notices.keys()][0]).toBe(faceNoticeId(UID, NOFACE));
    expect(f.visionCalls).toEqual([]); // fresh verdicts: no extra Vision call
  });

  test('client sent requireFace=false on a new faceless main photo: corrected anyway', async () => {
    // Verdict written by moderateUploadedImage with recordFaces (no rejection).
    f.verdicts.set(verdictDocId(path('new')), { status: 'approved', reasons: [], faces: 0, hasFace: false });
    await f.write(UID, { photoUrls: [url('new'), FACE, NOFACE] });
    expect(f.profiles.get(UID)!.photoUrls).toEqual([FACE, url('new'), NOFACE]);
  });

  test('business account may use a logo', async () => {
    f.profiles.set(UID, { photoUrls: [FACE], isBusiness: true });
    const r = await f.write(UID, { photoUrls: [NOFACE, FACE], isBusiness: true });
    expect(r).toEqual(['skipped']);
    expect(f.profiles.get(UID)!.photoUrls).toEqual([NOFACE, FACE]);
    expect(f.notices.size).toBe(0);
  });

  test('non-main faceless photo is allowed; unrelated writes skip without reads', async () => {
    const readSpy = jest.spyOn(f, 'readVerdict');
    expect(await f.write(UID, { photoUrls: [FACE, NOFACE, NOFACE2] })).toEqual(['skipped']);
    expect(await f.write(UID, { photoUrls: [FACE, NOFACE, NOFACE2], lastSeen: 1 })).toEqual(['skipped']);
    expect(readSpy).not.toHaveBeenCalled();
    expect(f.notices.size).toBe(0);
  });

  test('main photo with a face is accepted', async () => {
    expect(await f.write(UID, { photoUrls: [FACE2, FACE, NOFACE] })).toEqual(['ok']);
    expect(f.profiles.get(UID)!.photoUrls).toEqual([FACE2, FACE, NOFACE]);
  });

  test('no photo with a face: photoUrls untouched (never emptied), notice only, no loop', async () => {
    f.profiles.set(UID, { photoUrls: [NOFACE2] });
    const r = await f.write(UID, { photoUrls: [NOFACE, NOFACE2] });
    expect(r).toEqual(['notified']);
    expect(f.profiles.get(UID)!.photoUrls).toEqual([NOFACE, NOFACE2]);
    expect([...f.notices.values()]).toEqual([{ uid: UID, kind: 'needed' }]);
    // Retry (at-least-once delivery): same notice id, no duplicate.
    await enforceOnProfileWrite(UID, { photoUrls: [NOFACE2] }, { photoUrls: [NOFACE, NOFACE2] }, f);
    expect(f.notices.size).toBe(1);
  });

  test('expired verdict: one on-demand face check, cached on the verdict doc', async () => {
    f.verdicts.delete(verdictDocId(path('old')));
    f.objects.set(path('old'), 0);
    await f.write(UID, { photoUrls: [url('old'), FACE] });
    expect(f.visionCalls).toEqual([path('old')]);
    expect(f.verdicts.get(verdictDocId(path('old')))).toMatchObject({ faces: 0, hasFace: false });
    expect(f.profiles.get(UID)!.photoUrls).toEqual([FACE, url('old')]);
  });

  test('legacy verdict without face data, photo HAS a face: accepted after the check', async () => {
    f.verdicts.set(verdictDocId(path('legacy')), { status: 'approved', reasons: [] });
    f.objects.set(path('legacy'), 2);
    expect(await f.write(UID, { photoUrls: [url('legacy'), NOFACE] })).toEqual(['ok']);
    expect(f.visionCalls).toEqual([path('legacy')]);
  });

  test('external URLs are not judged', async () => {
    expect(await f.write(UID, { photoUrls: ['https://example.com/a.jpg', FACE] })).toEqual(['ok']);
    expect(f.visionCalls).toEqual([]);
  });

  test('replacement must have a KNOWN face (unknown candidates are skipped)', async () => {
    // url('pending') has no verdict and no object yet -> unknown.
    await f.write(UID, { photoUrls: [NOFACE, url('pending'), FACE2] });
    expect(f.profiles.get(UID)!.photoUrls).toEqual([FACE2, NOFACE, url('pending')]);
  });
});

describe('race: photoUrls[0] set before / after the moderation verdict', () => {
  let f: Fake;
  beforeEach(() => {
    f = new Fake();
    f.approved('face', true);
    f.profiles.set(UID, { photoUrls: [FACE] });
  });

  test('profile first (no verdict, object not there yet), verdict second -> corrected by enforceAfterVerdict', async () => {
    const NEW = url('new');
    // 1. Modified client writes the URL before the upload was moderated.
    expect(await f.write(UID, { photoUrls: [NEW, FACE] })).toEqual(['ok']); // undecidable yet
    expect(f.profiles.get(UID)!.photoUrls).toEqual([NEW, FACE]);
    // 2. moderateUploadedImage writes the verdict, then calls the rule.
    const verdict = { status: 'approved', reasons: [], faces: 0, hasFace: false };
    f.verdicts.set(verdictDocId(path('new')), verdict);
    expect(await enforceAfterVerdict(path('new'), verdict, f)).toBe('reordered');
    expect(f.profiles.get(UID)!.photoUrls).toEqual([FACE, NEW]);
    // The trigger fired by that correction sees a face in slot 0 and stops.
    expect(await enforceOnProfileWrite(UID, { photoUrls: [NEW, FACE] }, f.profiles.get(UID), f)).toBe('ok');
    expect(f.notices.size).toBe(1);
  });

  test('verdict first, profile second -> corrected by the profile trigger; enforceAfterVerdict was a no-op', async () => {
    const NEW = url('new');
    const verdict = { status: 'approved', reasons: [], faces: 0, hasFace: false };
    f.verdicts.set(verdictDocId(path('new')), verdict);
    expect(await enforceAfterVerdict(path('new'), verdict, f)).toBe('skipped'); // not the main photo yet
    await f.write(UID, { photoUrls: [NEW, FACE] });
    expect(f.profiles.get(UID)!.photoUrls).toEqual([FACE, NEW]);
    expect(f.notices.size).toBe(1);
  });

  test('both entry points firing for the same photo notify once', async () => {
    const NEW = url('new');
    const verdict = { status: 'approved', reasons: [], faces: 0, hasFace: false };
    f.verdicts.set(verdictDocId(path('new')), verdict);
    f.profiles.set(UID, { photoUrls: [NEW, FACE] });
    await enforceAfterVerdict(path('new'), verdict, f);
    await enforceOnProfileWrite(UID, { photoUrls: [FACE] }, { photoUrls: [NEW, FACE] }, f);
    expect(f.profiles.get(UID)!.photoUrls).toEqual([FACE, NEW]);
    expect(f.notices.size).toBe(1);
  });

  test('enforceAfterVerdict ignores faces, business accounts, non-main and non-photo paths', async () => {
    const NEW = url('new');
    f.profiles.set(UID, { photoUrls: [NEW, FACE] });
    expect(await enforceAfterVerdict(path('new'), { status: 'approved', hasFace: true }, f)).toBe('skipped');
    expect(await enforceAfterVerdict('profiles/u1/events/new.jpg', { status: 'approved', hasFace: false }, f)).toBe('skipped');
    expect(await enforceAfterVerdict(path('face'), { status: 'approved', hasFace: false }, f)).toBe('skipped');
    f.profiles.set(UID, { photoUrls: [NEW, FACE], isBusiness: true });
    expect(await enforceAfterVerdict(path('new'), { status: 'approved', hasFace: false }, f)).toBe('skipped');
    expect(f.profiles.get(UID)!.photoUrls).toEqual([NEW, FACE]);
  });

  test('concurrent user edit between plan and write is not clobbered', async () => {
    const NEW = url('new');
    f.verdicts.set(verdictDocId(path('new')), { status: 'approved', hasFace: false });
    f.profiles.set(UID, { photoUrls: [NEW, FACE] });
    const orig = f.updatePhotoUrls.bind(f);
    f.updatePhotoUrls = async (uid, mutate) => {
      f.profiles.set(uid, { photoUrls: [FACE] }); // user removed the photo meanwhile
      return orig(uid, mutate);
    };
    expect(await enforceOnProfileWrite(UID, { photoUrls: [FACE] }, { photoUrls: [NEW, FACE] }, f)).toBe('stale');
    expect(f.profiles.get(UID)!.photoUrls).toEqual([FACE]);
    expect(f.notices.size).toBe(0);
  });
});
