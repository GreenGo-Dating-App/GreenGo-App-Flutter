/**
 * PURE event-slot helpers shared by the usage counters (usage.ts) and the
 * downgrade planner (listingAllowance.ts). No Firebase imports, so the
 * planners can be unit-tested without mocks.
 */
export function millisOf(v: any): number | null {
  if (v === null || v === undefined) return null;
  if (typeof v.toMillis === 'function') return v.toMillis();
  if (v instanceof Date) return v.getTime();
  if (typeof v === 'number') return v;
  return null;
}

export interface EventLite {
  id: string;
  endMs: number | null;
  seriesId?: string | null;
  status?: string | null;
  /** Hidden by a plan downgrade: does not take a slot. */
  hidden?: boolean;
}

/** Still running: ends in the future, not cancelled / completed, not hidden by a downgrade. */
export function isOngoingEvent(e: EventLite, nowMs: number): boolean {
  if (e.hidden === true) return false;
  if (e.endMs === null || e.endMs <= nowMs) return false;
  return e.status !== 'cancelled' && e.status !== 'completed';
}

/** Slot key: a recurring series is ONE event for the cap. */
export function slotKeyOf(e: Pick<EventLite, 'id' | 'seriesId'>): string {
  return typeof e.seriesId === 'string' && e.seriesId.length > 0 ? `s:${e.seriesId}` : `e:${e.id}`;
}

export interface EventSlots {
  /** slotKey -> latest end (ms) of that slot */
  slots: Map<string, number>;
  /** seriesId -> ongoing occurrences */
  series: Record<string, number>;
}

export function eventSlots(events: EventLite[], nowMs: number, excludeSlot?: string): EventSlots {
  const slots = new Map<string, number>();
  const series: Record<string, number> = {};
  for (const e of events) {
    if (!isOngoingEvent(e, nowMs)) continue;
    const key = slotKeyOf(e);
    if (key === excludeSlot) continue;
    slots.set(key, Math.max(slots.get(key) ?? 0, e.endMs!));
    if (typeof e.seriesId === 'string' && e.seriesId) series[e.seriesId] = (series[e.seriesId] ?? 0) + 1;
  }
  return { slots, series };
}

/** Ascending end times: what the rules index into. */
export function sortedEnds(slots: Map<string, number>): number[] {
  return [...slots.values()].sort((a, b) => a - b);
}
