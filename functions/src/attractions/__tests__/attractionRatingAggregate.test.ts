import {
  applyRatingEvent,
  averageOf,
  ratingDelta,
  validStars,
  RatingAggregateDeps,
  RATING_EVENT_MARKERS,
} from '../attractionRatingAggregate';

import { makeDb } from '../../social/__tests__/fakeFirestore';

/* eslint-disable @typescript-eslint/no-explicit-any */

const ID = '1234';
const statsPath = `attraction_stats/${ID}`;

function setup(initial?: Record<string, any>) {
  const { db, store } = makeDb();
  if (initial) store.set(statsPath, { ...initial });
  const deps: RatingAggregateDeps = { db, now: () => new Date('2026-10-03T12:00:00Z') };
  const stats = () => store.get(statsPath) ?? {};
  const apply = (evt: string, before: unknown, after: unknown, id = ID) =>
    applyRatingEvent(deps, evt, id, before, after);
  return { deps, store, stats, apply };
}

const dist = (d: Partial<Record<'1' | '2' | '3' | '4' | '5', number>>) => ({
  '1': 0, '2': 0, '3': 0, '4': 0, '5': 0, ...d,
});

describe('helpers', () => {
  it('validStars accepts only ints 1..5', () => {
    expect(validStars(1)).toBe(1);
    expect(validStars(5)).toBe(5);
    expect(validStars(0)).toBeNull();
    expect(validStars(6)).toBeNull();
    expect(validStars(3.5)).toBeNull();
    expect(validStars('4')).toBeNull();
    expect(validStars(undefined)).toBeNull();
  });

  it('ratingDelta: create / update / delete / no-op', () => {
    expect(ratingDelta(undefined, 4)).toEqual({ sum: 4, count: 1, dist: { '4': 1 } });
    expect(ratingDelta(4, 2)).toEqual({ sum: -2, count: 0, dist: { '4': -1, '2': 1 } });
    expect(ratingDelta(3, undefined)).toEqual({ sum: -3, count: -1, dist: { '3': -1 } });
    expect(ratingDelta(5, 5)).toBeNull();
    expect(ratingDelta(undefined, 9)).toBeNull(); // invalid after = nothing
  });

  it('averageOf is 0 when the totals are not sane', () => {
    expect(averageOf(9, 2)).toBe(4.5);
    expect(averageOf(14, 3)).toBe(4.67);
    expect(averageOf(0, 0)).toBe(0);
    expect(averageOf(-2, -1)).toBe(0);
    expect(averageOf(11, 2)).toBe(0); // > 5 per rating
  });
});

describe('applyRatingEvent', () => {
  it('create: first rating creates the aggregate and keeps viewCount', async () => {
    const t = setup({ viewCount: 7 });
    expect(await t.apply('e1', undefined, 4)).toBe(true);
    expect(t.stats()).toMatchObject({
      viewCount: 7,
      ratingSum: 4,
      ratingCount: 1,
      ratingAvg: 4,
      ratingDist: dist({ '4': 1 }),
    });
    expect(t.stats().ratingUpdatedAt).toBeDefined();
  });

  it('create on an attraction never viewed creates the stats doc', async () => {
    const t = setup();
    await t.apply('e1', undefined, 5);
    expect(t.stats()).toMatchObject({ ratingSum: 5, ratingCount: 1, ratingAvg: 5 });
  });

  it('two users rate, one changes stars (delta), one deletes', async () => {
    const t = setup();
    await t.apply('a-create', undefined, 5);
    await t.apply('b-create', undefined, 3);
    expect(t.stats()).toMatchObject({ ratingSum: 8, ratingCount: 2, ratingAvg: 4 });

    // b changes 3 -> 4
    expect(await t.apply('b-update', 3, 4)).toBe(true);
    expect(t.stats()).toMatchObject({
      ratingSum: 9,
      ratingCount: 2,
      ratingAvg: 4.5,
      ratingDist: dist({ '5': 1, '4': 1 }),
    });

    // a deletes
    expect(await t.apply('a-delete', 5, undefined)).toBe(true);
    expect(t.stats()).toMatchObject({
      ratingSum: 4,
      ratingCount: 1,
      ratingAvg: 4,
      ratingDist: dist({ '4': 1 }),
    });

    // b deletes -> back to empty
    await t.apply('b-delete', 4, undefined);
    expect(t.stats()).toMatchObject({ ratingSum: 0, ratingCount: 0, ratingAvg: 0, ratingDist: dist({}) });
  });

  it('a retried event (same id) is applied once', async () => {
    const t = setup();
    expect(await t.apply('evt', undefined, 4)).toBe(true);
    expect(await t.apply('evt', undefined, 4)).toBe(false);
    expect(await t.apply('evt', undefined, 4)).toBe(false);
    expect(t.stats()).toMatchObject({ ratingSum: 4, ratingCount: 1 });
    expect(t.store.has(`${RATING_EVENT_MARKERS}/evt`)).toBe(true);
    expect(t.store.get(`${RATING_EVENT_MARKERS}/evt`).expireAt).toBeInstanceOf(Date);
  });

  it('a retried update and a retried delete each apply once', async () => {
    const t = setup();
    await t.apply('c', undefined, 2);
    await t.apply('u', 2, 5);
    await t.apply('u', 2, 5);
    expect(t.stats()).toMatchObject({ ratingSum: 5, ratingCount: 1, ratingAvg: 5 });
    await t.apply('d', 5, undefined);
    await t.apply('d', 5, undefined);
    expect(t.stats()).toMatchObject({ ratingSum: 0, ratingCount: 0 });
  });

  it('out-of-order delivery converges (delete processed before create)', async () => {
    const t = setup();
    await t.apply('del', 3, undefined); // arrives first
    expect(t.stats()).toMatchObject({ ratingCount: -1, ratingAvg: 0 });
    await t.apply('create', undefined, 3);
    expect(t.stats()).toMatchObject({ ratingSum: 0, ratingCount: 0, ratingAvg: 0, ratingDist: dist({}) });
  });

  it('no-op and invalid writes do not touch the aggregate or claim the event', async () => {
    const t = setup({ viewCount: 1 });
    expect(await t.apply('same', 4, 4)).toBe(false); // only updatedAt changed
    expect(await t.apply('bad', undefined, 7)).toBe(false);
    expect(await t.apply('badid', undefined, 4, 'abc/../x')).toBe(false);
    expect(t.stats()).toEqual({ viewCount: 1 });
    expect(t.store.has(`${RATING_EVENT_MARKERS}/same`)).toBe(false);
  });
});
