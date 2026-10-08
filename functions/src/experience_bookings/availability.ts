/**
 * Experience availability: recurring host schedule computed ON THE FLY
 * (nothing is pre-materialised; only booked/held slots get a counter doc).
 *
 * user_experiences/{id}.availabilityRules = {
 *   timezone: 'America/Sao_Paulo',          // IANA, host's zone
 *   windowStart: '09:00', windowEnd: '20:00',
 *   durationMinutes: 120, bufferMinutes: 0,
 *   startEveryMinutes?: number,             // default duration + buffer
 *   weekdays: [1..7]  (1 = Monday),
 *   dateFrom: 'YYYY-MM-DD', dateTo: 'YYYY-MM-DD' | null,
 *   capacityPerSlot: number,                // seats (per_person) or groups (per_group)
 *   minNoticeHours: 24, maxAdvanceDays: 60,
 * }
 * user_experiences/{id}.availabilityOverrides = {
 *   dayOverrides: { 'YYYY-MM-DD': { closed: true } | { windowStart, windowEnd } | { slots: ['10:00'] } },
 *   removedSlots: ['YYYY-MM-DDTHH:mm'], addedSlots: ['YYYY-MM-DDTHH:mm'],
 * }
 * Precedence per day: closed > explicit slots > window change > generated,
 * then minus removedSlots plus addedSlots. A slot is generated only when
 * start + duration <= windowEnd (09-20, 2 h -> 09, 11, 13, 15, 17; not 19).
 *
 * experience_slot_counters/{experienceId}_{startUtcMs} = { booked, held } is
 * written transactionally by the booking / order code (lazily, on first use).
 * The existing one-off dated slots (user_experiences/{id}/slots) keep working.
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { computeBookingPrice, pricingModeOf, resolveDatePrice } from './model';

export const SLOT_COUNTERS = 'experience_slot_counters';
export const MAX_RANGE_DAYS = 62;
const MIN = 60000;
const DAY = 24 * 60 * MIN;

export interface AvailabilityRules {
  timezone: string;
  windowStart: string;
  windowEnd: string;
  durationMinutes: number;
  bufferMinutes?: number;
  startEveryMinutes?: number;
  weekdays: number[];
  dateFrom?: string | null;
  dateTo?: string | null;
  capacityPerSlot: number;
  minNoticeHours?: number;
  maxAdvanceDays?: number;
}

export interface DayOverride {
  closed?: boolean;
  windowStart?: string;
  windowEnd?: string;
  slots?: string[];
  priceOverride?: number;
}

export interface AvailabilityOverrides {
  dayOverrides?: Record<string, DayOverride>;
  removedSlots?: string[];
  addedSlots?: string[];
}

export interface GeneratedSlot {
  /** Local 'YYYY-MM-DDTHH:mm' in the host zone (stable id). */
  key: string;
  startMs: number;
  endMs: number;
  date: string;
  time: string;
}

const HM = /^([01]\d|2[0-3]):([0-5]\d)$/;
const DATE = /^\d{4}-\d{2}-\d{2}$/;

export function minutesOf(hm: string): number | null {
  const m = HM.exec(hm);
  return m ? Number(m[1]) * 60 + Number(m[2]) : null;
}
const hmOf = (min: number) => `${String(Math.floor(min / 60)).padStart(2, '0')}:${String(min % 60).padStart(2, '0')}`;

/** Wall-clock parts of [ms] in [tz]. */
function parts(ms: number, tz: string) {
  const f = new Intl.DateTimeFormat('en-US', {
    timeZone: tz, hourCycle: 'h23', year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', weekday: 'short',
  }).formatToParts(new Date(ms));
  const g = (t: string) => f.find((p) => p.type === t)?.value ?? '';
  return {
    date: `${g('year')}-${g('month')}-${g('day')}`,
    time: `${g('hour')}:${g('minute')}`,
    weekday: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(g('weekday')) + 1,
  };
}

/**
 * UTC instant of local [date] [time] in [tz]; null when that wall-clock time
 * does not exist (spring-forward gap). Two-pass offset fix handles DST.
 */
export function localToUtc(date: string, time: string, tz: string): number | null {
  const [y, mo, d] = date.split('-').map(Number);
  const mins = minutesOf(time);
  if (mins === null) return null;
  const naive = Date.UTC(y, mo - 1, d, Math.floor(mins / 60), mins % 60);
  const offsetAt = (ms: number) => {
    const p = parts(ms, tz);
    const [py, pm, pd] = p.date.split('-').map(Number);
    const pmin = minutesOf(p.time) ?? 0;
    return Date.UTC(py, pm - 1, pd, Math.floor(pmin / 60), pmin % 60) - ms;
  };
  let ms = naive - offsetAt(naive);
  ms = naive - offsetAt(ms);
  const back = parts(ms, tz);
  return back.date === date && back.time === time ? ms : null;
}

export function weekdayOf(date: string): number {
  const [y, m, d] = date.split('-').map(Number);
  const wd = new Date(Date.UTC(y, m - 1, d)).getUTCDay(); // 0 = Sunday
  return wd === 0 ? 7 : wd;
}

function addDays(date: string, n: number): string {
  const [y, m, d] = date.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d) + n * DAY).toISOString().slice(0, 10);
}

/** Start times of one day before removals/additions (precedence rules). */
export function dayTimes(rules: AvailabilityRules, date: string, ov?: DayOverride): string[] {
  if (ov?.closed) return [];
  if (ov?.slots && ov.slots.length) {
    return Array.from(new Set(ov.slots.filter((t) => minutesOf(t) !== null))).sort();
  }
  const isOverrideWindow = !!(ov && (ov.windowStart || ov.windowEnd));
  if (!isOverrideWindow && !rules.weekdays.includes(weekdayOf(date))) return [];
  const ws = minutesOf(ov?.windowStart ?? rules.windowStart);
  const we = minutesOf(ov?.windowEnd ?? rules.windowEnd);
  const dur = Math.round(rules.durationMinutes);
  if (ws === null || we === null || !(dur > 0) || we <= ws) return [];
  const step = Math.round(rules.startEveryMinutes ?? dur + (rules.bufferMinutes ?? 0));
  if (!(step > 0)) return [];
  const out: string[] = [];
  for (let t = ws; t + dur <= we; t += step) out.push(hmOf(t));
  return out;
}

/**
 * Bookable slots between [fromMs, toMs) at [nowMs]: generated + overrides,
 * minus too-soon (minNoticeHours) / too-far (maxAdvanceDays) / outside the
 * dateFrom..dateTo range. Pure.
 */
export function generateSlots(
  rules: AvailabilityRules,
  overrides: AvailabilityOverrides | undefined,
  fromMs: number,
  toMs: number,
  nowMs: number,
): GeneratedSlot[] {
  const tz = rules.timezone || 'UTC';
  const dur = Math.round(rules.durationMinutes) * MIN;
  const notice = (rules.minNoticeHours ?? 24) * 60 * MIN;
  const maxAdv = (rules.maxAdvanceDays ?? 60) * DAY;
  const removed = new Set(overrides?.removedSlots ?? []);
  const added = (overrides?.addedSlots ?? []).filter((k) => /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(k));
  const first = parts(fromMs, tz).date;
  const last = parts(toMs, tz).date;
  const out = new Map<string, GeneratedSlot>();
  const push = (date: string, time: string) => {
    const startMs = localToUtc(date, time, tz);
    if (startMs === null) return;
    out.set(`${date}T${time}`, { key: `${date}T${time}`, startMs, endMs: startMs + dur, date, time });
  };
  for (let date = first, guard = 0; date <= last && guard < 400; date = addDays(date, 1), guard++) {
    if (rules.dateFrom && date < rules.dateFrom) continue;
    if (rules.dateTo && date > rules.dateTo) continue;
    for (const time of dayTimes(rules, date, overrides?.dayOverrides?.[date])) {
      if (!removed.has(`${date}T${time}`)) push(date, time);
    }
  }
  for (const k of added) {
    const [date, time] = k.split('T');
    if (date >= first && date <= last && !overrides?.dayOverrides?.[date]?.closed) push(date, time);
  }
  return Array.from(out.values())
    .filter((s) => s.startMs >= fromMs && s.startMs < toMs)
    .filter((s) => s.startMs >= nowMs + notice && s.startMs <= nowMs + maxAdv)
    .sort((a, b) => a.startMs - b.startMs);
}

/** Two slots of the same host overlap (duration-aware). */
export function overlaps(a: { startMs: number; endMs: number }, b: { startMs: number; endMs: number }): boolean {
  return a.startMs < b.endMs && b.startMs < a.endMs;
}

/** Validates host rules (server side); returns the reason or null. */
export function rulesError(r: any): string | null {
  if (!r || typeof r !== 'object') return 'invalid_rules';
  try { new Intl.DateTimeFormat('en-US', { timeZone: r.timezone }); } catch { return 'invalid_timezone'; }
  if (minutesOf(r.windowStart) === null || minutesOf(r.windowEnd) === null) return 'invalid_window';
  if ((minutesOf(r.windowEnd) as number) <= (minutesOf(r.windowStart) as number)) return 'invalid_window';
  if (!Number.isInteger(r.durationMinutes) || r.durationMinutes < 15 || r.durationMinutes > 24 * 60) return 'invalid_duration';
  if (r.bufferMinutes !== undefined && (!Number.isInteger(r.bufferMinutes) || r.bufferMinutes < 0 || r.bufferMinutes > 600)) return 'invalid_buffer';
  if (r.startEveryMinutes !== undefined && (!Number.isInteger(r.startEveryMinutes) || r.startEveryMinutes < 15)) return 'invalid_step';
  if (!Array.isArray(r.weekdays) || r.weekdays.some((d: unknown) => !Number.isInteger(d) || (d as number) < 1 || (d as number) > 7)) return 'invalid_weekdays';
  if (r.dateFrom != null && !DATE.test(r.dateFrom)) return 'invalid_dates';
  if (r.dateTo != null && !DATE.test(r.dateTo)) return 'invalid_dates';
  if (!Number.isInteger(r.capacityPerSlot) || r.capacityPerSlot < 1 || r.capacityPerSlot > 500) return 'invalid_capacity';
  // Own slots of one day must not overlap (step >= duration).
  const step = r.startEveryMinutes ?? r.durationMinutes + (r.bufferMinutes ?? 0);
  if (step < r.durationMinutes) return 'overlapping_slots';
  return null;
}

function cleanOverride(v: DayOverride): DayOverride {
  const out: DayOverride = {};
  if (v.closed === true) out.closed = true;
  if (typeof v.windowStart === 'string' && minutesOf(v.windowStart) !== null) out.windowStart = v.windowStart;
  if (typeof v.windowEnd === 'string' && minutesOf(v.windowEnd) !== null) out.windowEnd = v.windowEnd;
  if (Array.isArray(v.slots)) out.slots = v.slots.filter((t) => typeof t === 'string' && minutesOf(t) !== null).slice(0, 48);
  if (typeof v.priceOverride === 'number' && Number.isFinite(v.priceOverride) && v.priceOverride > 0) out.priceOverride = v.priceOverride;
  return out;
}

// ─────────────────────────────────────────────────────────── callables

function fail(code: ConstructorParameters<typeof HttpsError>[0], reason: string, extra: Record<string, unknown> = {}): never {
  throw new HttpsError(code, reason, { code: reason, ...extra });
}

const db = () => admin.firestore();

export function counterId(experienceId: string, startMs: number): string {
  return `${experienceId}_${startMs}`;
}

/** Buyer: slots with remaining capacity for a range (<= 62 days). */
export async function getExperienceAvailability(_uid: string, data: any, nowMs = Date.now()): Promise<Record<string, unknown>> {
  const id = data?.experienceId;
  if (typeof id !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(id)) fail('invalid-argument', 'invalid_experience_id');
  const from = Date.parse(String(data?.from ?? ''));
  const to = Date.parse(String(data?.to ?? ''));
  if (!Number.isFinite(from) || !Number.isFinite(to) || to <= from) fail('invalid-argument', 'invalid_range');
  if (to - from > MAX_RANGE_DAYS * DAY) fail('invalid-argument', 'range_too_long', { maxDays: MAX_RANGE_DAYS });
  const e = (await db().collection('user_experiences').doc(id).get()).data();
  if (!e || e.status !== 'published') fail('not-found', 'experience_not_found');
  const rules = e.availabilityRules as AvailabilityRules | undefined;
  if (!rules || rulesError(rules)) return { timezone: null, slots: [] };
  const slots = generateSlots(rules, e.availabilityOverrides, from, to, nowMs);
  const refs = slots.map((s) => db().collection(SLOT_COUNTERS).doc(counterId(id, s.startMs)));
  const counters = new Map<string, Record<string, any>>();
  for (let i = 0; i < refs.length; i += 300) {
    const chunk = refs.slice(i, i + 300);
    if (!chunk.length) continue;
    const snaps = await db().getAll(...chunk);
    for (const s of snaps) if (s.exists) counters.set(s.id, s.data()!);
  }
  const perGroup = pricingModeOf(e) === 'per_group';
  return {
    timezone: rules.timezone,
    pricingMode: perGroup ? 'per_group' : 'per_person',
    capacityPerSlot: rules.capacityPerSlot,
    slots: slots.map((s) => {
      const c = counters.get(counterId(id, s.startMs));
      const used = (Number(c?.booked) || 0) + (Number(c?.held) || 0);
      // Price of ONE unit (person, or the group) on that date (server rules).
      const p = e.isFree === true ? null : computeBookingPrice(e, 1, s.startMs);
      return {
        key: s.key, start: new Date(s.startMs).toISOString(), end: new Date(s.endMs).toISOString(),
        date: s.date, time: s.time, remaining: Math.max(0, rules.capacityPerSlot - used),
        unitAmount: p && p.ok ? p.price.unitAmount : 0,
        currency: p && p.ok ? p.price.currency : null,
        priceRule: e.isFree === true ? 'base' : resolveDatePrice(e, s.startMs).rule,
      };
    }).filter((s) => s.remaining > 0),
  };
}

/**
 * Host: save rules / overrides. When the change removes slots that already
 * have bookings or holds, nothing is written unless `confirm: true`; the
 * response lists how many are affected.
 */
export async function updateExperienceAvailability(uid: string, data: any, nowMs = Date.now()): Promise<Record<string, unknown>> {
  const id = data?.experienceId;
  if (typeof id !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(id)) fail('invalid-argument', 'invalid_experience_id');
  const ref = db().collection('user_experiences').doc(id);
  const e = (await ref.get()).data();
  if (!e) fail('not-found', 'experience_not_found');
  if (e.hostId !== uid) fail('permission-denied', 'not_host');
  const rules: AvailabilityRules = data?.rules ?? e.availabilityRules;
  const err = rulesError(rules);
  if (err) fail('invalid-argument', err);
  const ov: AvailabilityOverrides = data?.overrides ?? e.availabilityOverrides ?? {};
  // Keep overrides compact: prune past dates.
  const today = new Date(nowMs).toISOString().slice(0, 10);
  const pruned: AvailabilityOverrides = {
    dayOverrides: Object.fromEntries(Object.entries(ov.dayOverrides ?? {})
      .filter(([d, v]) => DATE.test(d) && d >= today && v && typeof v === 'object')
      .map(([d, v]) => [d, cleanOverride(v as DayOverride)])),
    removedSlots: (ov.removedSlots ?? []).filter((k) => k.slice(0, 10) >= today).slice(0, 2000),
    addedSlots: (ov.addedSlots ?? []).filter((k) => k.slice(0, 10) >= today).slice(0, 2000),
  };
  // Slots that carry bookings / holds and would disappear.
  const used = await db().collection(SLOT_COUNTERS)
    .where('experienceId', '==', id).where('startMs', '>=', nowMs).limit(500).get();
  const horizon = nowMs + ((rules.maxAdvanceDays ?? 60) + 1) * DAY;
  const keep = new Set(generateSlots({ ...rules, minNoticeHours: 0 }, pruned, nowMs, horizon, nowMs).map((s) => s.startMs));
  const affected = used.docs.filter((d) => {
    const c = d.data();
    return ((Number(c.booked) || 0) + (Number(c.held) || 0)) > 0 && !keep.has(Number(c.startMs));
  });
  const affectedStarts = affected.map((d) => Number(d.data().startMs));
  if (affected.length && data?.confirm !== true) {
    return { needsConfirm: true, affected: affected.length, affectedStarts };
  }
  await ref.update({ availabilityRules: rules, availabilityOverrides: pruned, updatedAt: admin.firestore.Timestamp.fromMillis(nowMs) });
  // Affected bookings: flagged for the cancel + refund flow (see docs).
  const batch = db().batch();
  for (const d of affected) batch.set(d.ref, { removedByHostAt: admin.firestore.Timestamp.fromMillis(nowMs) }, { merge: true });
  if (affected.length) await batch.commit();
  return { needsConfirm: false, affected: affected.length, affectedStarts };
}
