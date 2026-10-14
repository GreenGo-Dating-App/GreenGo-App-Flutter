/**
 * PURE planning for "plan dropped -> hide listings over the new allowance,
 * plan raised -> restore them" (owner rule 2026-10-14). The I/O lives in
 * entitlements/downgrade.ts; everything here is unit-tested
 * (__tests__/unit/listingDowngrade.test.ts).
 *
 * Allowance = how many ACTIVE events / experiences the owner may have at a
 * time, the same numbers as the creation caps (shared/tierLimits.ts):
 *   no plan 0 · Base 1 · Silver 5 · Gold 10 · Platinum / TEST / admin unlimited.
 *
 * Selection: the most recent (by creation date) visible listings are kept;
 * the rest are hidden. On a raise, hidden listings come back most recent
 * first, up to the free room. A recurring event series is ONE unit (the cap
 * counts a series once), so a series is hidden / restored as a whole.
 *
 * Hidden listings carry `hiddenByDowngrade: true` (server-owned):
 *   events       status -> 'draft' (not in any discovery query or share card)
 *                + preDowngradeStatus (restored on upgrade)
 *   experiences  status -> 'hidden' + moderation {reason: 'plan_downgrade',
 *                previousStatus} - the existing moderation-hide mechanism
 *                (the host can't leave 'hidden'; publish refuses it).
 */
import { EffectiveTier, effectiveTier, hasBaseAccess, isProfileAdmin } from '../shared/effectiveTier';
import { MAX_EVENTS, MAX_EXPERIENCES } from '../shared/tierLimits';
import { isOngoingEvent, millisOf, slotKeyOf } from './eventSlots';

export const DOWNGRADE_REASON = 'plan_downgrade';

export interface ListingAllowance {
  /** null = unlimited. */
  events: number | null;
  experiences: number | null;
}

/** Active listings `profile` may have right now. */
export function listingAllowance(
  profile: Record<string, any> | null | undefined,
  now: Date = new Date(),
): ListingAllowance {
  if (isProfileAdmin(profile)) return { events: null, experiences: null };
  if (!hasBaseAccess(profile, now)) return { events: 0, experiences: 0 };
  const t: EffectiveTier = effectiveTier(profile, now);
  return { events: MAX_EVENTS[t], experiences: MAX_EXPERIENCES[t] };
}

/** Profile fields that decide the allowance (the trigger reacts to these only). */
export const ALLOWANCE_FIELDS = [
  'membershipTier', 'membershipEndDate', 'hasBaseMembership', 'baseMembershipEndDate', 'isAdmin',
] as const;

function comparable(v: unknown): unknown {
  if (v === null || v === undefined) return null;
  if (typeof v === 'object') {
    const o = v as any;
    if (typeof o.toMillis === 'function') return o.toMillis();
    if (v instanceof Date) return v.getTime();
    const secs = o._seconds ?? o.seconds;
    if (typeof secs === 'number') return secs * 1000 + Math.floor((o._nanoseconds ?? o.nanoseconds ?? 0) / 1e6);
    return JSON.stringify(v);
  }
  return v;
}

/** True when any allowance field differs between two profile snapshots. */
export function allowanceFieldsChanged(
  before: Record<string, any> | null | undefined,
  after: Record<string, any> | null | undefined,
): boolean {
  for (const f of ALLOWANCE_FIELDS) {
    if (comparable(before?.[f]) !== comparable(after?.[f])) return true;
  }
  return false;
}

/** One unit of the allowance: an experience, or an event slot (single event / whole series). */
export interface ListingUnit {
  key: string;
  /** Creation time (ms) - the most recent are kept. */
  createdMs: number;
  /** Already hidden by a downgrade. */
  hidden: boolean;
  /**
   * Visible unit: takes a slot now. Hidden unit: would take a slot if
   * restored (e.g. an ended event never needs restoring under a cap).
   */
  active: boolean;
}

export interface ReconcilePlan {
  hide: string[];
  restore: string[];
}

const newestFirst = (a: ListingUnit, b: ListingUnit) => b.createdMs - a.createdMs || (a.key < b.key ? -1 : 1);

/**
 * What to hide / restore so that at most `limit` active units are visible.
 * `limit` null = unlimited: restore everything hidden. Idempotent: planning
 * again on the result returns an empty plan.
 */
export function planListingReconcile(
  units: ListingUnit[],
  limit: number | null,
  opts: { allowRestore?: boolean } = {},
): ReconcilePlan {
  const allowRestore = opts.allowRestore !== false;
  const hidden = units.filter((u) => u.hidden);
  if (limit === null) {
    return { hide: [], restore: allowRestore ? hidden.map((u) => u.key) : [] };
  }
  const cap = Math.max(0, limit);
  const visible = units.filter((u) => !u.hidden && u.active).sort(newestFirst);
  const hide = visible.slice(cap).map((u) => u.key);
  const room = cap - Math.min(visible.length, cap);
  const restore = allowRestore && room > 0
    ? hidden.filter((u) => u.active).sort(newestFirst).slice(0, room).map((u) => u.key)
    : [];
  return { hide, restore };
}

export interface EventSlotGroup<D> {
  /** Ongoing, not hidden: take the slot now. */
  visible: D[];
  /** Hidden by a downgrade. */
  hidden: D[];
  createdMs: number;
  /** A hidden occurrence has not ended (worth restoring under a cap). */
  hiddenActive: boolean;
}

/**
 * Event docs -> allowance units, one per slot (a single event or a whole
 * recurring series). Ended / cancelled / completed visible events take no
 * slot and are left alone. A slot is hidden when none of its occurrences is
 * visible any more.
 */
export function eventUnits<D extends { id: string; data: Record<string, any> }>(
  docs: D[],
  nowMs: number,
): { units: ListingUnit[]; groups: Map<string, EventSlotGroup<D>> } {
  const groups = new Map<string, EventSlotGroup<D>>();
  for (const doc of docs) {
    const d = doc.data;
    const key = slotKeyOf({ id: doc.id, seriesId: typeof d.seriesId === 'string' ? d.seriesId : null });
    const g = groups.get(key) ?? { visible: [], hidden: [], createdMs: 0, hiddenActive: false };
    const endMs = millisOf(d.endDate);
    if (d.hiddenByDowngrade === true) {
      g.hidden.push(doc);
      if (endMs !== null && endMs > nowMs) g.hiddenActive = true;
    } else if (isOngoingEvent({ id: doc.id, endMs, status: typeof d.status === 'string' ? d.status : null }, nowMs)) {
      g.visible.push(doc);
    } else {
      continue;
    }
    g.createdMs = Math.max(g.createdMs, millisOf(d.createdAt) ?? 0);
    groups.set(key, g);
  }
  const units: ListingUnit[] = [];
  for (const [key, g] of groups) {
    const isHidden = g.visible.length === 0;
    units.push({ key, createdMs: g.createdMs, hidden: isHidden, active: isHidden ? g.hiddenActive : true });
  }
  return { units, groups };
}

// ---------------------------------------------------------------------------
// Document patches (field values only; the I/O layer swaps in FieldValues)

/** Statuses an event may go back to. */
const EVENT_RESTORABLE = ['draft', 'scheduled', 'published'];

/** Event patch on hide (null = already hidden). */
export function eventHidePatch(d: Record<string, any>): Record<string, any> | null {
  if (d.hiddenByDowngrade === true) return null;
  const prev = typeof d.status === 'string' && EVENT_RESTORABLE.includes(d.status) ? d.status : 'published';
  return { status: 'draft', hiddenByDowngrade: true, preDowngradeStatus: prev };
}

/** Status an event hidden by a downgrade goes back to (null = not hidden by one). */
export function eventRestoreStatus(d: Record<string, any>): string | null {
  if (d.hiddenByDowngrade !== true) return null;
  return typeof d.preDowngradeStatus === 'string' && EVENT_RESTORABLE.includes(d.preDowngradeStatus)
    ? d.preDowngradeStatus
    : 'published';
}

/** An experience that may be hidden: draft / published, not hidden for any reason. */
export function experienceHideable(d: Record<string, any>): boolean {
  return d.hiddenByDowngrade !== true && (d.status === 'draft' || d.status === 'published');
}

export function experienceHidePatch(d: Record<string, any>): Record<string, any> | null {
  if (!experienceHideable(d)) return null;
  return {
    status: 'hidden',
    hiddenByDowngrade: true,
    moderation: { reason: DOWNGRADE_REASON, previousStatus: d.status === 'published' ? 'published' : 'draft' },
  };
}

/**
 * What restoring a downgrade-hidden experience does:
 *  - 'status': hidden by the downgrade only -> back to its previous status;
 *  - 'flag':   hidden again for another reason since (moderation / admin):
 *              only the downgrade flag is cleared, it stays hidden;
 *  - null:     not hidden by a downgrade.
 */
export function experienceRestore(d: Record<string, any>): { kind: 'status'; status: 'draft' | 'published' } | { kind: 'flag' } | null {
  if (d.hiddenByDowngrade !== true) return null;
  const mod = d.moderation && typeof d.moderation === 'object' ? d.moderation : null;
  if (d.status === 'hidden' && mod?.reason === DOWNGRADE_REASON) {
    return { kind: 'status', status: mod.previousStatus === 'published' ? 'published' : 'draft' };
  }
  return { kind: 'flag' };
}
