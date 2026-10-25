import * as fs from 'fs';
import * as path from 'path';
import {
  FOLLOW_STORE_JOBS,
  FollowStoreJob,
  STORE_PLACES,
  applyStoreFieldsPage,
  enqueueFollowStoreJobIfChanged,
  followStoreRound,
  mirrorNeedsStoreFields,
  placeId,
  stampStoreFields,
  storeFieldsOf,
  unplaceDeletedMirror,
} from '../followStores';
import { deleteField, increment, makeDb } from './fakeFirestore';

/* eslint-disable @typescript-eslint/no-explicit-any */

const fv = { increment, delete: deleteField };

const addr = (city: string, country: string, extra: Record<string, unknown> = {}) => ({
  address: `1 Main St, ${city}`, city, country, latitude: 41.9, longitude: 12.5, ...extra,
});

const shop = (over: Record<string, unknown> = {}) => ({
  isBusiness: true,
  displayName: 'Owner Person',
  businessName: 'Café Roma',
  businessCategory: 'Cafe',
  businessAddress: addr('Rome', 'Italy'),
  ...over,
});

function world() {
  const { db, store } = makeDb();
  const follow = (follower: string, followee: string) => {
    store.set(`business_followers/${followee}/followers/${follower}`, { createdAt: 1 });
    store.set(`user_business_following/${follower}/businesses/${followee}`, { createdAt: 1 });
  };
  const mirror = (follower: string, followee: string) =>
    store.get(`user_business_following/${follower}/businesses/${followee}`);
  /** The follower's place facets as {label: n}. */
  const facets = (uid: string) => {
    const out: Record<string, number> = {};
    for (const [k, v] of store.entries()) {
      if (!k.startsWith(`${STORE_PLACES}/${uid}/`)) continue;
      out[k.includes('/cities/') ? `${v.country}/${v.cityLower}` : v.country] = v.n;
    }
    return out;
  };
  return { db, store, follow, mirror, facets };
}

describe('storeFieldsOf', () => {
  it('uses the storefront name, category and the PUBLIC storefront address only', () => {
    expect(storeFieldsOf(shop())).toEqual({
      name: 'cafe roma', category: 'Cafe', country: 'Italy', cityLower: 'rome', city: 'Rome',
    });
    // No businessName → the display name; no usable address → no place
    // (the personal `location` is private and never used).
    expect(storeFieldsOf(shop({
      businessName: '  ', businessAddress: addr('Rome', 'Italy', { latitude: 0, longitude: 0 }),
      location: { city: 'Milan', country: 'Italy' },
    }))).toEqual({ name: 'owner person', category: 'Cafe', country: '', cityLower: '', city: '' });
    // A city without a country is not a place.
    expect(storeFieldsOf(shop({ businessAddress: addr('Rome', '') }))!.cityLower).toBe('');
  });

  it('is null for personal accounts and missing profiles', () => {
    expect(storeFieldsOf({ displayName: 'Ana' })).toBeNull();
    expect(storeFieldsOf(shop({ isBusiness: false }))).toBeNull();
    expect(storeFieldsOf(undefined)).toBeNull();
  });
});

describe('stampStoreFields (follow created)', () => {
  it('stamps the mirror + facets once, never creates docs, skips non-businesses', async () => {
    const w = world();
    w.store.set('profiles/s', shop());
    w.store.set('profiles/p', { displayName: 'Person' });
    w.follow('u', 's');
    w.follow('u', 'p');

    expect(await stampStoreFields(w.db, fv, 's', 'u')).toBe(true);
    expect(w.mirror('u', 's')).toMatchObject({
      storeNameLower: 'cafe roma', storeCategory: 'Cafe', storeCountry: 'Italy', storeCityLower: 'rome',
    });
    expect(w.facets('u')).toEqual({ Italy: 1, 'Italy/rome': 1 });
    const city = w.store.get(`${STORE_PLACES}/u/cities/${placeId('Italy', 'rome')}`);
    expect(city).toEqual({ country: 'Italy', city: 'Rome', cityLower: 'rome', n: 1 });

    // Retried event: no second count.
    expect(await stampStoreFields(w.db, fv, 's', 'u')).toBe(false);
    expect(w.facets('u')).toEqual({ Italy: 1, 'Italy/rome': 1 });

    // A personal account: nothing written (and with the profile passed in,
    // nothing read either).
    expect(await stampStoreFields(w.db, fv, 'p', 'u', { displayName: 'Person' })).toBe(false);
    expect(w.mirror('u', 'p')).toEqual({ createdAt: 1 });

    // Unfollowed meanwhile: the mirror is not re-created.
    expect(await stampStoreFields(w.db, fv, 's', 'gone')).toBe(false);
    expect(w.store.has('user_business_following/gone/businesses/s')).toBe(false);
  });
});

describe('enqueueFollowStoreJobIfChanged', () => {
  it('only enqueues when a store field changes on an existing profile', async () => {
    const w = world();
    const go = (b: any, a: any) => enqueueFollowStoreJobIfChanged(w.db, 's', b, a, () => 9);
    expect(await go(undefined, shop())).toBe(false); // created
    expect(await go(shop(), undefined)).toBe(false); // deleted
    expect(await go(shop({ lastSeen: 1 }), shop({ lastSeen: 2 }))).toBe(false);
    expect(await go({ displayName: 'A' }, { displayName: 'B' })).toBe(false); // not a business
    // Only the city's capitalisation: same filter value, no fan-out.
    expect(await go(shop(), shop({ businessAddress: addr('ROME', 'Italy') }))).toBe(false);
    expect(w.store.has(`${FOLLOW_STORE_JOBS}/s`)).toBe(false);

    expect(await go(shop(), shop({ businessCategory: 'Bar' }))).toBe(true);
    expect(w.store.get(`${FOLLOW_STORE_JOBS}/s`)).toEqual({
      fields: { name: 'cafe roma', category: 'Bar', country: 'Italy', cityLower: 'rome', city: 'Rome' },
      gen: 9, cursor: null, round: 0,
    });
    // Stops being a business → a job that clears the fields.
    expect(await go(shop(), shop({ isBusiness: false }))).toBe(true);
    expect(w.store.get(`${FOLLOW_STORE_JOBS}/s`)!.fields).toBeNull();
  });
});

describe('followStoreRound (store fan-out)', () => {
  const S = 's';
  async function setup(n: number) {
    const w = world();
    w.store.set(`profiles/${S}`, shop());
    for (let i = 0; i < n; i++) {
      const f = `f${String(i).padStart(3, '0')}`;
      w.follow(f, S);
      await stampStoreFields(w.db, fv, S, f);
    }
    // A follower whose mirror is gone must not get one back.
    w.store.set(`business_followers/${S}/followers/ghost`, { createdAt: 1 });
    return w;
  }

  it('moves every follower\'s mirror and facets to the new place, in bounded pages', async () => {
    const w = await setup(5);
    const next = storeFieldsOf(shop({ businessCategory: 'Bar', businessAddress: addr('Porto', 'Portugal') }));
    const job: FollowStoreJob = { fields: next, gen: 1, cursor: null };
    w.store.set(`${FOLLOW_STORE_JOBS}/${S}`, { ...job });

    const r = await followStoreRound(w.db, fv, S, job, { deadlineMs: Date.now() + 60_000, pageSize: 2 });
    expect(r).toMatchObject({ done: true, superseded: false, updated: 5, scanned: 6 });
    for (let i = 0; i < 5; i++) {
      const f = `f00${i}`;
      expect(w.mirror(f, S)).toMatchObject({ storeCategory: 'Bar', storeCountry: 'Portugal', storeCityLower: 'porto' });
      // The old place's facets reached 0 and were DELETED, not left at 0.
      expect(w.facets(f)).toEqual({ Portugal: 1, 'Portugal/porto': 1 });
    }
    expect(w.store.has(`user_business_following/ghost/businesses/${S}`)).toBe(false);

    // Idempotent: a re-run (retried event) writes nothing and counts nothing.
    const again = await followStoreRound(w.db, fv, S, job, { deadlineMs: Date.now() + 60_000, pageSize: 2 });
    expect(again.updated).toBe(0);
    expect(w.facets('f000')).toEqual({ Portugal: 1, 'Portugal/porto': 1 });
  });

  it('keeps the country facet when only the city changes', async () => {
    const w = await setup(1);
    w.follow('f000', 'other');
    w.store.set('profiles/other', shop({ businessAddress: addr('Rome', 'Italy') }));
    await stampStoreFields(w.db, fv, 'other', 'f000');
    expect(w.facets('f000')).toEqual({ Italy: 2, 'Italy/rome': 2 });

    const job: FollowStoreJob = {
      fields: storeFieldsOf(shop({ businessAddress: addr('Milan', 'Italy') })), gen: 3, cursor: null,
    };
    w.store.set(`${FOLLOW_STORE_JOBS}/${S}`, { ...job });
    await followStoreRound(w.db, fv, S, job, { deadlineMs: Date.now() + 60_000 });
    expect(w.facets('f000')).toEqual({ Italy: 2, 'Italy/rome': 1, 'Italy/milan': 1 });
  });

  it('clears the fields when the account stops being a business', async () => {
    const w = await setup(2);
    const job: FollowStoreJob = { fields: null, gen: 2, cursor: null };
    w.store.set(`${FOLLOW_STORE_JOBS}/${S}`, { ...job });
    const r = await followStoreRound(w.db, fv, S, job, { deadlineMs: Date.now() + 60_000 });
    expect(r.updated).toBe(2);
    expect(w.mirror('f000', S)).toEqual({ createdAt: 1 });
    expect(w.facets('f000')).toEqual({});
  });

  it('stops at the deadline, resumes from the cursor, and stops when superseded', async () => {
    const w = await setup(5);
    const job: FollowStoreJob = { fields: storeFieldsOf(shop({ businessCategory: 'Bar' })), gen: 1, cursor: null };
    w.store.set(`${FOLLOW_STORE_JOBS}/${S}`, { ...job });
    let t = 0;
    let r = await followStoreRound(w.db, fv, S, job, { deadlineMs: 0, pageSize: 2, nowMs: () => ++t });
    expect(r).toMatchObject({ done: false, scanned: 2 }); // one page per round past the deadline
    let rounds = 1;
    while (!r.done) {
      r = await followStoreRound(w.db, fv, S, { ...job, cursor: r.cursor }, {
        deadlineMs: 0, pageSize: 2, nowMs: () => ++t,
      });
      expect(++rounds).toBeLessThan(10);
    }
    for (let i = 0; i < 5; i++) expect(w.mirror(`f00${i}`, S)!.storeCategory).toBe('Bar');

    w.store.set(`${FOLLOW_STORE_JOBS}/${S}`, { ...job, gen: 2 });
    const stale = await followStoreRound(w.db, fv, S, job, { deadlineMs: Date.now() + 60_000 });
    expect(stale).toMatchObject({ done: false, superseded: true, updated: 0 });
  });
});

describe('unplaceDeletedMirror (unfollow)', () => {
  it('decrements exactly once per event, deletes facets at 0, ignores non-store mirrors', async () => {
    const w = world();
    w.store.set('profiles/a', shop());
    w.store.set('profiles/b', shop({ businessName: 'Bar B' }));
    w.follow('u', 'a');
    w.follow('u', 'b');
    await stampStoreFields(w.db, fv, 'a', 'u');
    await stampStoreFields(w.db, fv, 'b', 'u');
    expect(w.facets('u')).toEqual({ Italy: 2, 'Italy/rome': 2 });

    const oldA = w.mirror('u', 'a');
    expect(await unplaceDeletedMirror(w.db, fv, 'ev1', 'u', 'a', oldA)).toBe(true);
    expect(await unplaceDeletedMirror(w.db, fv, 'ev1', 'u', 'a', oldA)).toBe(false); // retry
    expect(w.facets('u')).toEqual({ Italy: 1, 'Italy/rome': 1 });

    expect(await unplaceDeletedMirror(w.db, fv, 'ev2', 'u', 'b', w.mirror('u', 'b'))).toBe(true);
    expect(w.facets('u')).toEqual({});
    // A mirror without a place (personal account / no address): no-op.
    expect(await unplaceDeletedMirror(w.db, fv, 'ev3', 'u', 'p', { createdAt: 1 })).toBe(false);
  });
});

describe('applyStoreFieldsPage (backfill)', () => {
  it('fills legacy mirrors, counts each follower\'s places once, idempotent', async () => {
    const w = world();
    const s1 = shop();
    const s2 = shop({ businessName: 'Pub', businessCategory: 'Bar' });
    w.follow('u', 's1');
    w.follow('u', 's2');
    w.follow('u', 'p');
    const rows = [
      { followerId: 'u', followeeId: 's1', followee: s1 },
      { followerId: 'u', followeeId: 's2', followee: s2 },
      { followerId: 'u', followeeId: 'p', followee: { displayName: 'Person' } },
      { followerId: 'u', followeeId: 'gone', followee: null },
    ];
    expect(mirrorNeedsStoreFields(w.mirror('u', 's1'), s1)).toBe(true);
    expect(mirrorNeedsStoreFields(w.mirror('u', 'p'), { displayName: 'Person' })).toBe(false);
    expect(await applyStoreFieldsPage(w.db, fv, rows)).toBe(2);
    expect(w.facets('u')).toEqual({ Italy: 2, 'Italy/rome': 2 });
    expect(w.mirror('u', 's2')!.storeNameLower).toBe('pub');
    expect(await applyStoreFieldsPage(w.db, fv, rows)).toBe(0);
    expect(w.facets('u')).toEqual({ Italy: 2, 'Italy/rome': 2 });
  });
});

describe('rules keep the store fields server-only', () => {
  it.each(['firestore.rules', 'firestore.additive.rules'])('%s', (file) => {
    const rules = fs.readFileSync(path.join(__dirname, '../../../../', file), 'utf8');
    const mirror = rules.slice(rules.indexOf('match /user_business_following/{userId}/businesses/{businessId}'));
    const create = mirror.slice(0, mirror.indexOf('allow delete'));
    for (const f of ['storeNameLower', 'storeCategory', 'storeCountry', 'storeCityLower']) {
      expect(create).toContain(`'${f}'`);
    }
    expect(rules).toMatch(new RegExp(
      'match /user_store_places/\\{userId\\}/\\{facet\\}/\\{placeId\\} \\{\\s*' +
      'allow read: if isOwner\\(userId\\)[^\\n]*\\n\\s*allow write: if false;'));
    expect(rules).not.toContain('match /follow_store_jobs');
  });
});

describe('backfill-store-fields project guard', () => {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const { resolveProject } = require('../../../scripts/backfill-store-fields');
  it('needs --project, matching env, and --production for prod', () => {
    expect(resolveProject(['node', 's'], {})).toEqual({ refuse: '--project <id> is required' });
    expect(resolveProject(['--project', '--apply'], {})).toHaveProperty('refuse');
    expect(resolveProject(['--project', 'greengo-chat-test'], {})).toEqual({ project: 'greengo-chat-test' });
    expect(resolveProject(['--project', 'greengo-chat-test'], { GCLOUD_PROJECT: 'greengo-chat' }))
      .toHaveProperty('refuse');
    expect(resolveProject(['--project', 'greengo-chat'], {})).toHaveProperty('refuse');
    expect(resolveProject(['--project', 'greengo-chat', '--production'], {})).toEqual({ project: 'greengo-chat' });
  });
});
