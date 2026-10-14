/**
 * Plan drops / raises -> hide / restore listings (owner rule 2026-10-14):
 * the PURE allowance + selection logic of entitlements/listingAllowance.ts.
 */
import * as admin from 'firebase-admin';
import {
  allowanceFieldsChanged,
  eventHidePatch,
  eventRestoreStatus,
  eventUnits,
  experienceHidePatch,
  experienceRestore,
  listingAllowance,
  planListingReconcile,
  ListingUnit,
} from '../../src/entitlements/listingAllowance';
import { isOngoingEvent } from '../../src/entitlements/eventSlots';

const TS = admin.firestore.Timestamp;
const NOW = new Date('2026-10-14T12:00:00Z');
const DAY = 86_400_000;
const future = TS.fromMillis(NOW.getTime() + 30 * DAY);
const past = TS.fromMillis(NOW.getTime() - DAY);

const unit = (key: string, createdMs: number, hidden = false, active = true): ListingUnit =>
  ({ key, createdMs, hidden, active });

describe('listingAllowance', () => {
  test('no plan 0, Base 1, Silver 5, Gold 10, Platinum / TEST / admin unlimited', () => {
    expect(listingAllowance({ membershipTier: 'FREE' }, NOW)).toEqual({ events: 0, experiences: 0 });
    expect(listingAllowance(null, NOW)).toEqual({ events: 0, experiences: 0 });
    expect(listingAllowance({ membershipTier: 'FREE', hasBaseMembership: true, baseMembershipEndDate: future }, NOW))
      .toEqual({ events: 1, experiences: 1 });
    expect(listingAllowance({ membershipTier: 'SILVER', membershipEndDate: future }, NOW)).toEqual({ events: 5, experiences: 5 });
    expect(listingAllowance({ membershipTier: 'GOLD', membershipEndDate: future }, NOW)).toEqual({ events: 10, experiences: 10 });
    expect(listingAllowance({ membershipTier: 'PLATINUM', membershipEndDate: future }, NOW)).toEqual({ events: null, experiences: null });
    expect(listingAllowance({ membershipTier: 'TEST' }, NOW)).toEqual({ events: null, experiences: null });
    expect(listingAllowance({ membershipTier: 'FREE', isAdmin: true }, NOW)).toEqual({ events: null, experiences: null });
  });

  test('an expired paid tier falls back to Base (if active) or no plan', () => {
    expect(listingAllowance({ membershipTier: 'GOLD', membershipEndDate: past }, NOW)).toEqual({ events: 0, experiences: 0 });
    expect(listingAllowance({
      membershipTier: 'GOLD', membershipEndDate: past, hasBaseMembership: true, baseMembershipEndDate: future,
    }, NOW)).toEqual({ events: 1, experiences: 1 });
    expect(listingAllowance({ membershipTier: 'FREE', hasBaseMembership: true, baseMembershipEndDate: past }, NOW))
      .toEqual({ events: 0, experiences: 0 });
  });

  test('the trigger reacts only to the allowance fields', () => {
    const a = { membershipTier: 'GOLD', membershipEndDate: future, displayName: 'x' };
    expect(allowanceFieldsChanged(a, { ...a, displayName: 'y', lastSeen: 1 })).toBe(false);
    expect(allowanceFieldsChanged(a, { ...a, membershipEndDate: TS.fromMillis(future.toMillis()) })).toBe(false);
    expect(allowanceFieldsChanged(a, { ...a, membershipTier: 'FREE' })).toBe(true);
    expect(allowanceFieldsChanged(a, { ...a, membershipEndDate: past })).toBe(true);
    expect(allowanceFieldsChanged({ ...a, hasBaseMembership: true }, { ...a, hasBaseMembership: false })).toBe(true);
    expect(allowanceFieldsChanged(a, { ...a, isAdmin: true })).toBe(true);
  });
});

describe('planListingReconcile', () => {
  const units = [unit('a', 1), unit('b', 5), unit('c', 3), unit('d', 4), unit('e', 2)];

  test('Gold -> Silver: keeps the 5 most recent of 7, hides the 2 oldest', () => {
    const seven = [...units, unit('f', 0), unit('g', 6)];
    expect(planListingReconcile(seven, 5)).toEqual({ hide: ['a', 'f'], restore: [] });
  });

  test('Silver -> Base keeps the newest one; no plan keeps none', () => {
    expect(planListingReconcile(units, 1).hide.sort()).toEqual(['a', 'c', 'd', 'e']);
    expect(planListingReconcile(units, 0).hide.sort()).toEqual(['a', 'b', 'c', 'd', 'e']);
  });

  test('upgrade restores up to the new allowance, most recent first', () => {
    const state = [unit('b', 5), unit('a', 1, true), unit('c', 3, true), unit('d', 4, true), unit('e', 2, true)];
    expect(planListingReconcile(state, 3)).toEqual({ hide: [], restore: ['d', 'c'] });
    expect(planListingReconcile(state, null).restore.sort()).toEqual(['a', 'c', 'd', 'e']);
    // Base -> no plan -> Base: the one visible again is the newest hidden.
    const none = state.map((u) => ({ ...u, hidden: true }));
    expect(planListingReconcile(none, 1)).toEqual({ hide: [], restore: ['b'] });
  });

  test('idempotent: planning on the result is a no-op', () => {
    const first = planListingReconcile(units, 2);
    const after = units.map((u) => ({ ...u, hidden: first.hide.includes(u.key) }));
    expect(planListingReconcile(after, 2)).toEqual({ hide: [], restore: [] });
  });

  test('hidden units that ended are not restored under a cap, but are under unlimited', () => {
    const state = [unit('old', 9, true, false), unit('live', 1, true, true)];
    expect(planListingReconcile(state, 1)).toEqual({ hide: [], restore: ['live'] });
    expect(planListingReconcile(state, null).restore.sort()).toEqual(['live', 'old']);
  });

  test('no restores while banned (allowRestore false), hides still apply', () => {
    const state = [unit('a', 1, true), unit('b', 2), unit('c', 3)];
    expect(planListingReconcile(state, 1, { allowRestore: false })).toEqual({ hide: ['b'], restore: [] });
    expect(planListingReconcile(state, null, { allowRestore: false })).toEqual({ hide: [], restore: [] });
  });
});

describe('eventUnits', () => {
  const ev = (id: string, data: Record<string, any>) => ({ id, data });
  const nowMs = NOW.getTime();
  const t = (ms: number) => TS.fromMillis(nowMs + ms);

  test('a series is one unit, ended / cancelled events take no slot, hidden ones are hidden units', () => {
    const { units, groups } = eventUnits([
      ev('s1', { seriesId: 'S', endDate: t(DAY), createdAt: t(-5 * DAY), status: 'published' }),
      ev('s2', { seriesId: 'S', endDate: t(8 * DAY), createdAt: t(-5 * DAY), status: 'published' }),
      ev('one', { endDate: t(DAY), createdAt: t(-DAY), status: 'published' }),
      ev('ended', { endDate: t(-DAY), createdAt: t(-2 * DAY), status: 'published' }),
      ev('cancel', { endDate: t(DAY), createdAt: t(-2 * DAY), status: 'cancelled' }),
      ev('hid', { endDate: t(DAY), createdAt: t(-3 * DAY), status: 'draft', hiddenByDowngrade: true }),
      ev('hidOld', { endDate: t(-DAY), createdAt: t(-9 * DAY), status: 'draft', hiddenByDowngrade: true }),
    ], nowMs);
    const byKey = Object.fromEntries(units.map((u) => [u.key, u]));
    expect(Object.keys(byKey).sort()).toEqual(['e:hid', 'e:hidOld', 'e:one', 's:S']);
    expect(byKey['s:S']).toMatchObject({ hidden: false, active: true });
    expect(groups.get('s:S')!.visible.map((d) => d.id)).toEqual(['s1', 's2']);
    expect(byKey['e:hid']).toMatchObject({ hidden: true, active: true });
    expect(byKey['e:hidOld']).toMatchObject({ hidden: true, active: false });
    // Base keeps the newest active slot ('one', created a day ago).
    expect(planListingReconcile(units, 1)).toEqual({ hide: ['s:S'], restore: [] });
  });

  test('hidden events take no slot in the cap counter', () => {
    expect(isOngoingEvent({ id: 'x', endMs: nowMs + DAY, status: 'draft', hidden: true }, nowMs)).toBe(false);
    expect(isOngoingEvent({ id: 'x', endMs: nowMs + DAY, status: 'draft' }, nowMs)).toBe(true);
  });
});

describe('patches', () => {
  test('event hide -> draft + flag + previous status; restore -> previous status', () => {
    expect(eventHidePatch({ status: 'published' })).toEqual({ status: 'draft', hiddenByDowngrade: true, preDowngradeStatus: 'published' });
    expect(eventHidePatch({ status: 'scheduled' })!.preDowngradeStatus).toBe('scheduled');
    expect(eventHidePatch({ status: 'draft', hiddenByDowngrade: true })).toBeNull();
    expect(eventRestoreStatus({ status: 'draft', hiddenByDowngrade: true, preDowngradeStatus: 'scheduled' })).toBe('scheduled');
    expect(eventRestoreStatus({ status: 'draft', hiddenByDowngrade: true, preDowngradeStatus: 'weird' })).toBe('published');
    expect(eventRestoreStatus({ status: 'published' })).toBeNull();
  });

  test('experience hide reuses the moderation-hide; other hides are never touched', () => {
    expect(experienceHidePatch({ status: 'published' })).toEqual({
      status: 'hidden', hiddenByDowngrade: true, moderation: { reason: 'plan_downgrade', previousStatus: 'published' },
    });
    expect(experienceHidePatch({ status: 'draft' })!.moderation.previousStatus).toBe('draft');
    expect(experienceHidePatch({ status: 'hidden', moderation: { reason: 'reports' } })).toBeNull();
    expect(experienceRestore({ status: 'hidden', hiddenByDowngrade: true, moderation: { reason: 'plan_downgrade', previousStatus: 'published' } }))
      .toEqual({ kind: 'status', status: 'published' });
    // Hidden again by an admin in the meantime: only the flag goes.
    expect(experienceRestore({ status: 'hidden', hiddenByDowngrade: true, moderation: { reason: 'admin' } })).toEqual({ kind: 'flag' });
    expect(experienceRestore({ status: 'published' })).toBeNull();
  });
});
