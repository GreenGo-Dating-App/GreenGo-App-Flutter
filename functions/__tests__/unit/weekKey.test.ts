/**
 * ISO week key — must agree with the Dart implementation on the SAME fixture
 * file (test/unit/gamification/fixtures/iso_week_keys.json at the app root).
 */
import * as fs from 'fs';
import * as path from 'path';
import { isoWeekKey, weeklyXpFields } from '../../src/gamification/weekKey';

interface WeekKeyCase {
  instant: string;
  weekKey: string;
  note?: string;
}

const fixturePath = path.resolve(
  __dirname,
  '../../../test/unit/gamification/fixtures/iso_week_keys.json',
);
const cases: WeekKeyCase[] = JSON.parse(fs.readFileSync(fixturePath, 'utf8')).cases;

describe('isoWeekKey (shared fixtures)', () => {
  it('has fixtures', () => {
    expect(cases.length).toBeGreaterThan(10);
  });

  it.each(cases.map((c) => [c.instant, c.weekKey, c.note ?? '']))(
    '%s -> %s (%s)',
    (instant, weekKey) => {
      expect(isoWeekKey(new Date(instant as string))).toBe(weekKey);
    },
  );

  it('is correct for every day of 2020-2030 (week numbers stay contiguous)', () => {
    let prev = isoWeekKey(new Date(Date.UTC(2019, 11, 30)));
    let daysInWeek = 1;
    for (let t = Date.UTC(2019, 11, 31); t < Date.UTC(2031, 0, 1); t += 86400000) {
      const key = isoWeekKey(new Date(t));
      if (key === prev) {
        daysInWeek++;
      } else {
        expect(daysInWeek).toBe(7);
        expect(new Date(t).getUTCDay()).toBe(1); // new week starts on Monday
        daysInWeek = 1;
        prev = key;
      }
    }
  });
});

describe('weeklyXpFields', () => {
  const now = new Date('2026-10-01T12:00:00Z'); // 2026-W40

  it('starts the counter when there is no doc', () => {
    expect(weeklyXpFields(undefined, 25, now)).toEqual({ weekKey: '2026-W40', weeklyXP: 25 });
  });

  it('increments within the same week', () => {
    expect(weeklyXpFields({ weekKey: '2026-W40', weeklyXP: 100 }, 25, now))
      .toEqual({ weekKey: '2026-W40', weeklyXP: 125 });
  });

  it('resets to the grant amount when the stored week is stale', () => {
    expect(weeklyXpFields({ weekKey: '2026-W39', weeklyXP: 900 }, 25, now))
      .toEqual({ weekKey: '2026-W40', weeklyXP: 25 });
  });

  it('treats a doc without weekly fields as a fresh week', () => {
    expect(weeklyXpFields({}, 7, now)).toEqual({ weekKey: '2026-W40', weeklyXP: 7 });
  });
});
