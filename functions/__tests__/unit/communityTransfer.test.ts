/**
 * Community ownership transfer (communities/transfer.ts) against an in-memory
 * Firestore: request (fresh sign-in, creator only, active member target, one
 * pending offer, plan cap), respond (accept moves ownership + roles + ends the
 * owner's sponsorship; decline; expiry), cancel and the expiry job.
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { PathFakeFirestore } from '../utils/pathFirestoreFake';
import * as T from '../../src/communities/transfer';

const OWNER = 'u_owner';
const TARGET = 'u_target';
const OTHER = 'u_other';
const C = 'c1';
const CP = `communities/${C}`;
const T0 = Date.UTC(2026, 9, 21, 12, 0, 0);
const DAY = 24 * 60 * 60 * 1000;

let db: PathFakeFirestore;
let now: number;
let sent: Array<{ recipientId: string; type: string; title: any; body: any; data: any }>;
const saved = { ...T.transferDeps };

/** auth_time (seconds) of a sign-in [agoSec] seconds before "now". */
const authAgo = (agoSec: number) => Math.floor(now / 1000) - agoSec;
const fresh = () => authAgo(30);

async function code(p: Promise<unknown>): Promise<string> {
  try {
    await p;
  } catch (e) {
    expect(e).toBeInstanceOf(HttpsError);
    return String((e as HttpsError).details && ((e as HttpsError).details as any).code);
  }
  throw new Error('expected a refusal');
}

function seed(extra: Record<string, any> = {}) {
  db.seed(CP, {
    name: 'Porto Coffee Club',
    createdByUserId: OWNER,
    createdByName: 'Olivia',
    memberCount: 3,
    isSponsored: false,
    sponsorId: null,
    pinnedPromo: null,
    ...extra,
  });
  db.seed(`${CP}/members/${OWNER}`, { userId: OWNER, displayName: 'Olivia', role: 'owner' });
  db.seed(`${CP}/members/${TARGET}`, { userId: TARGET, displayName: 'Tiago', role: 'member' });
  db.seed(`${CP}/members/${OTHER}`, { userId: OTHER, displayName: 'Omar', role: 'admin' });
  for (const u of [OWNER, TARGET, OTHER]) {
    db.seed(`profiles/${u}`, { displayName: u });
    db.seed(`users/${u}`, { accountStatus: 'active' });
  }
}

const request = (uid = OWNER, authTime: unknown = fresh(), to = TARGET) =>
  T.requestCommunityTransfer(uid, authTime, { communityId: C, toUserId: to });

beforeEach(() => {
  db = new PathFakeFirestore();
  now = T0;
  sent = [];
  Object.assign(T.transferDeps, {
    db: () => db as any,
    now: () => new Date(now),
    notify: async (p: any) => { sent.push(p); },
    actor: async (uid: string) => ({ id: uid, name: uid }),
    authUnavailable: async () => false,
    ownedCommunityCap: () => null,
  });
  seed();
});

afterAll(() => Object.assign(T.transferDeps, saved));

describe('requestCommunityTransfer', () => {
  test('creator with a fresh sign-in creates a 7-day offer and notifies the target', async () => {
    const r: any = await request();
    expect(r.success).toBe(true);
    expect(r.expiresAt).toBe(T0 + 7 * DAY);
    const t = db.get(`community_transfers/${C}`)!;
    expect(t.fromUserId).toBe(OWNER);
    expect(t.toUserId).toBe(TARGET);
    expect(t.toName).toBe('Tiago');
    expect(t.status).toBe('pending');
    expect(t.expiresAt.toMillis()).toBe(T0 + 7 * DAY);
    expect(sent).toHaveLength(1);
    expect(sent[0].recipientId).toBe(TARGET);
    expect(sent[0].type).toBe('community_transfer_offer');
    expect(sent[0].title).toEqual({ key: 'srvCommunityTransferOfferTitle' });
    expect(sent[0].data).toMatchObject({ action: 'community_transfer_offer', communityId: C });
    // Nothing changed yet: the target must accept.
    expect(db.get(CP)!.createdByUserId).toBe(OWNER);
    expect(db.get(`${CP}/members/${TARGET}`)!.role).toBe('member');
    expect(db.list({ collection: 'community_audit' }).map(([, d]) => d.action)).toEqual(['requested']);
  });

  test('a stale sign-in (auth_time older than 5 minutes) is refused', async () => {
    expect(await code(request(OWNER, authAgo(5 * 60 + 1)))).toBe('requires_recent_login');
    expect(await code(request(OWNER, null))).toBe('requires_recent_login');
    expect(await code(request(OWNER, 'garbage'))).toBe('requires_recent_login');
    expect(db.get(`community_transfers/${C}`)).toBeUndefined();
    // Exactly at the limit is fine.
    await request(OWNER, authAgo(5 * 60));
    expect(db.get(`community_transfers/${C}`)).toBeDefined();
  });

  test('a non-creator is refused (also a community admin / owner-role member)', async () => {
    expect(await code(request(OTHER, fresh(), TARGET))).toBe('not_creator');
    db.seed(`${CP}/members/${OTHER}`, { userId: OTHER, role: 'owner' });
    expect(await code(request(OTHER, fresh(), TARGET))).toBe('not_creator');
    expect(sent).toHaveLength(0);
  });

  test('the target must be a current, non-banned member', async () => {
    expect(await code(request(OWNER, fresh(), 'u_stranger'))).toBe('target_unavailable'); // no profile
    db.seed('profiles/u_stranger', { displayName: 'S' });
    expect(await code(request(OWNER, fresh(), 'u_stranger'))).toBe('target_not_member');
    db.seed(`${CP}/members/${TARGET}`, { userId: TARGET, role: 'member', isBanned: true });
    expect(await code(request())).toBe('target_not_member');
  });

  test('self, suspended / deleted / disabled / business / blocked targets are refused', async () => {
    expect(await code(request(OWNER, fresh(), OWNER))).toBe('self_transfer');
    db.seed(`users/${TARGET}`, { accountStatus: 'suspended' });
    expect(await code(request())).toBe('target_unavailable');
    db.seed(`users/${TARGET}`, { accountStatus: 'deleted' });
    expect(await code(request())).toBe('target_unavailable');
    db.seed(`users/${TARGET}`, { accountStatus: 'active' });
    T.transferDeps.authUnavailable = async () => true;
    expect(await code(request())).toBe('target_unavailable');
    T.transferDeps.authUnavailable = async () => false;
    db.seed(`profiles/${TARGET}`, { displayName: 'Shop', isBusiness: true });
    expect(await code(request())).toBe('target_unavailable');
    db.seed(`profiles/${TARGET}`, { displayName: 'Tiago' });
    db.seed(`profiles/${TARGET}/blocked_users/${OWNER}`, { at: 1 });
    expect(await code(request())).toBe('target_unavailable');
  });

  test('only one pending offer per community; an expired one is replaced', async () => {
    await request();
    expect(await code(request(OWNER, fresh(), OTHER))).toBe('transfer_pending');
    now = T0 + 7 * DAY + 1;
    const r: any = await request(OWNER, fresh(), OTHER);
    expect(r.success).toBe(true);
    expect(db.get(`community_transfers/${C}`)!.toUserId).toBe(OTHER);
  });

  test('the new owner plan cap (owned communities) is enforced', async () => {
    T.transferDeps.ownedCommunityCap = () => 1;
    db.seed('communities/c_target_own', { name: 'Mine', createdByUserId: TARGET });
    expect(await code(request())).toBe('owner_limit_reached');
    T.transferDeps.ownedCommunityCap = () => 2;
    await request();
    expect(db.get(`community_transfers/${C}`)).toBeDefined();
  });

  test('a missing community / bad input is refused', async () => {
    expect(await code(T.requestCommunityTransfer(OWNER, fresh(), { communityId: 'nope', toUserId: TARGET })))
      .toBe('community_not_found');
    expect(await code(T.requestCommunityTransfer(OWNER, fresh(), { communityId: 'a/b', toUserId: TARGET })))
      .toBe('invalid_argument');
    expect(await code(T.requestCommunityTransfer(OWNER, fresh(), {}))).toBe('invalid_argument');
  });
});

describe('respondCommunityTransfer', () => {
  test('accept moves ownership, swaps roles, audits and notifies the old owner', async () => {
    await request();
    sent = [];
    const r: any = await T.respondCommunityTransfer(TARGET, { communityId: C, accept: true });
    expect(r).toMatchObject({ success: true, accepted: true, sponsorshipEnded: false });
    const c = db.get(CP)!;
    expect(c.createdByUserId).toBe(TARGET);
    expect(c.createdByName).toBe('Tiago');
    expect(c.previousOwnerId).toBe(OWNER);
    expect(c.memberCount).toBe(3);
    expect(db.get(`${CP}/members/${TARGET}`)!.role).toBe('owner');
    expect(db.get(`${CP}/members/${OWNER}`)!.role).toBe('admin');
    expect(db.get(`${CP}/members/${OTHER}`)!.role).toBe('admin');
    expect(db.get(`community_transfers/${C}`)).toBeUndefined();
    const audit = db.list({ collection: 'community_audit' }).map(([, d]) => d);
    expect(audit.map((a) => a.action)).toEqual(['requested', 'accepted']);
    expect(audit[1]).toMatchObject({ fromUserId: OWNER, toUserId: TARGET, byUserId: TARGET });
    expect(sent).toHaveLength(1);
    expect(sent[0]).toMatchObject({ recipientId: OWNER, type: 'community_transfer_accepted' });
  });

  test("accept ends the old owner's sponsorship (and says so)", async () => {
    seed({ isSponsored: true, sponsorId: OWNER, pinnedPromo: { title: 'Promo', body: 'b' } });
    const req: any = await request();
    expect(req.sponsorshipWillEnd).toBe(true);
    expect(db.get(`community_transfers/${C}`)!.sponsorshipWillEnd).toBe(true);
    const r: any = await T.respondCommunityTransfer(TARGET, { communityId: C, accept: true });
    expect(r.sponsorshipEnded).toBe(true);
    const c = db.get(CP)!;
    expect(c.isSponsored).toBe(false);
    expect(c.sponsorId).toBeNull();
    expect(c.pinnedPromo).toBeNull();
  });

  test("another business's sponsorship is not touched", async () => {
    seed({ isSponsored: true, sponsorId: 'u_biz' });
    await request();
    await T.respondCommunityTransfer(TARGET, { communityId: C, accept: true });
    expect(db.get(CP)!.isSponsored).toBe(true);
    expect(db.get(CP)!.sponsorId).toBe('u_biz');
  });

  test('decline keeps everything and tells the owner', async () => {
    await request();
    sent = [];
    const r: any = await T.respondCommunityTransfer(TARGET, { communityId: C, accept: false });
    expect(r).toMatchObject({ success: true, accepted: false });
    expect(db.get(CP)!.createdByUserId).toBe(OWNER);
    expect(db.get(`${CP}/members/${TARGET}`)!.role).toBe('member');
    expect(db.get(`${CP}/members/${OWNER}`)!.role).toBe('owner');
    expect(db.get(`community_transfers/${C}`)).toBeUndefined();
    expect(sent[0]).toMatchObject({ recipientId: OWNER, type: 'community_transfer_declined' });
  });

  test('only the target can answer; nothing to answer is refused', async () => {
    expect(await code(T.respondCommunityTransfer(TARGET, { communityId: C, accept: true }))).toBe('no_pending_transfer');
    await request();
    expect(await code(T.respondCommunityTransfer(OTHER, { communityId: C, accept: true }))).toBe('no_pending_transfer');
    expect(await code(T.respondCommunityTransfer(OWNER, { communityId: C, accept: true }))).toBe('no_pending_transfer');
    expect(db.get(CP)!.createdByUserId).toBe(OWNER);
    expect(await code(T.respondCommunityTransfer(TARGET, { communityId: C, accept: 'yes' }))).toBe('invalid_argument');
  });

  test('an expired offer cannot be accepted (and is cleared)', async () => {
    await request();
    now = T0 + 7 * DAY;
    expect(await code(T.respondCommunityTransfer(TARGET, { communityId: C, accept: true }))).toBe('transfer_expired');
    expect(db.get(CP)!.createdByUserId).toBe(OWNER);
    expect(db.get(`community_transfers/${C}`)).toBeUndefined();
  });

  test('a target who left meanwhile cannot accept', async () => {
    await request();
    db.remove(`${CP}/members/${TARGET}`);
    expect(await code(T.respondCommunityTransfer(TARGET, { communityId: C, accept: true }))).toBe('no_pending_transfer');
    expect(db.get(CP)!.createdByUserId).toBe(OWNER);
    expect(db.get(`community_transfers/${C}`)).toBeUndefined();
  });

  test('the plan cap is checked again at accept time', async () => {
    await request();
    T.transferDeps.ownedCommunityCap = () => 1;
    db.seed('communities/c_target_own', { name: 'Mine', createdByUserId: TARGET });
    expect(await code(T.respondCommunityTransfer(TARGET, { communityId: C, accept: true }))).toBe('owner_limit_reached');
    expect(db.get(CP)!.createdByUserId).toBe(OWNER);
    expect(db.get(`community_transfers/${C}`)).toBeDefined();
  });

  test('the new owner can transfer it back (fresh sign-in)', async () => {
    await request();
    await T.respondCommunityTransfer(TARGET, { communityId: C, accept: true });
    expect(await code(request())).toBe('not_creator'); // old owner lost the right
    await T.requestCommunityTransfer(TARGET, fresh(), { communityId: C, toUserId: OWNER });
    await T.respondCommunityTransfer(OWNER, { communityId: C, accept: true });
    expect(db.get(CP)!.createdByUserId).toBe(OWNER);
    expect(db.get(`${CP}/members/${OWNER}`)!.role).toBe('owner');
    expect(db.get(`${CP}/members/${TARGET}`)!.role).toBe('admin');
  });
});

describe('cancelCommunityTransfer + expiry job', () => {
  test('the owner cancels; others cannot', async () => {
    await request();
    expect(await code(T.cancelCommunityTransfer(TARGET, { communityId: C }))).toBe('no_pending_transfer');
    await T.cancelCommunityTransfer(OWNER, { communityId: C });
    expect(db.get(`community_transfers/${C}`)).toBeUndefined();
    expect(await code(T.respondCommunityTransfer(TARGET, { communityId: C, accept: true }))).toBe('no_pending_transfer');
    expect(db.get(CP)!.createdByUserId).toBe(OWNER);
    expect(db.list({ collection: 'community_audit' }).map(([, d]) => d.action)).toEqual(['requested', 'cancelled']);
  });

  test('expireDueTransfers removes only due offers and tells their owners', async () => {
    await request();
    db.seed('communities/c2', { name: 'Two', createdByUserId: OTHER });
    db.seed('communities/c2/members/' + TARGET, { userId: TARGET, role: 'member' });
    now = T0 + 3 * DAY;
    await T.requestCommunityTransfer(OTHER, fresh(), { communityId: 'c2', toUserId: TARGET });
    sent = [];
    now = T0 + 7 * DAY + 1000;
    expect(await T.expireDueTransfers()).toBe(1);
    expect(db.get(`community_transfers/${C}`)).toBeUndefined();
    expect(db.get('community_transfers/c2')).toBeDefined();
    expect(sent).toHaveLength(1);
    expect(sent[0]).toMatchObject({ recipientId: OWNER, type: 'community_transfer_expired' });
    expect(db.get(CP)!.createdByUserId).toBe(OWNER);
  });
});

describe('helpers', () => {
  test('isRecentAuth', () => {
    const at = new Date(T0);
    expect(T.isRecentAuth(T0 / 1000 - 10, at)).toBe(true);
    expect(T.isRecentAuth(T0 / 1000 - 301, at)).toBe(false);
    expect(T.isRecentAuth(null, at)).toBe(false);
  });

  test('sponsoredByOwner', () => {
    expect(T.sponsoredByOwner({ isSponsored: false }, OWNER)).toBe(false);
    expect(T.sponsoredByOwner({ isSponsored: true, sponsorId: OWNER }, OWNER)).toBe(true);
    expect(T.sponsoredByOwner({ isSponsored: true }, OWNER)).toBe(true);
    expect(T.sponsoredByOwner({ pinnedPromo: { title: 'x' } }, OWNER)).toBe(true);
    expect(T.sponsoredByOwner({ isSponsored: true, sponsorId: 'biz' }, OWNER)).toBe(false);
  });

  test('timestamps are Firestore Timestamps', async () => {
    await request();
    expect(db.get(`community_transfers/${C}`)!.createdAt).toBeInstanceOf(admin.firestore.Timestamp);
  });
});
